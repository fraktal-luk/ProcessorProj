----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:57:56 12/11/2016 
-- Design Name: 
-- Module Name:    MemoryUnit - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


use work.ProcBasicDefs.all;
use work.Helpers.all;

use work.ProcInstructionsNew.all;

use work.NewPipelineData.all;

use work.GeneralPipeDev.all;

use work.TEMP_DEV.all;

use work.ProcComponents.all;

use work.ProcLogicFront.all;

use work.ProcLogicExec.all;
use work.ProcLogicMemory.all;

use work.BasicCheck.all;


entity MemoryUnit is
	generic(
		QUEUE_SIZE: integer := 4;
		CLEAR_COMPLETED: boolean := true
	);
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;

			acceptingOut: out std_logic;
			prevSending: in std_logic;
			dataIn: in StageDataMulti;

		storeAddressWr: in std_logic;
		storeValueWr: in std_logic;

		storeAddressDataIn: in InstructionState;
		storeValueDataIn: in InstructionState;

			committing: in std_logic;
			groupCtrNext: in SmallNumber;

		execEventSignal: in std_logic;
		execCausing: in InstructionState;
		
		nextAccepting: in std_logic;
		
		acceptingOutSQ: out std_logic;
		sendingSQOut: out std_logic;
		dataOutSQ: out InstructionState
	);
end MemoryUnit;



architecture Behavioral of MemoryUnit is
	constant zeroMask: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');

	signal wrAddress, wrData, sendingSQ: std_logic := '0';
	signal dataA, dataD: InstructionState := DEFAULT_INSTRUCTION_STATE;
							
	signal fullMask, livingMask, killMask: std_logic_vector(0 to QUEUE_SIZE-1) := (others => '0');

	signal content, contentNext, contentUpdated:
					InstructionSlotArray(0 to QUEUE_SIZE-1) := (others => DEFAULT_INSTRUCTION_SLOT);
	signal contentData: InstructionStateArray(0 to QUEUE_SIZE-1)
																			:= (others => DEFAULT_INSTRUCTION_STATE);
	signal contentDataNext: InstructionStateArray(0 to QUEUE_SIZE-1)
																			:= (others => DEFAULT_INSTRUCTION_STATE);
	signal contentMaskNext, matchingA, matchingD,
								matchingShA, matchingShD: std_logic_vector(0 to QUEUE_SIZE-1) := (others => '0'); 
	signal sqOutData, sqOutData_2: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;


	signal bufferDrive: FlowDriveBuffer := (killAll => '0', lockAccept => '0', lockSend => '0',
																others=>(others=>'0'));
	signal bufferResponse: FlowResponseBuffer := (others=>(others=>'0'));
begin				
		fullMask <= extractFullMask(content);
		livingMask <= fullMask and not killMask;
							
		matchingA <= findMatching(content, dataA);
		matchingD <= findMatching(content, dataD);
							
		matchingShA <= queueMaskNext(matchingA, zeroMask,
																 binFlowNum(bufferResponse.living),
																 --binFlowNum(bufferResponse.sending),
																	countOnes(sqOutData.fullMask),
																 prevSending);																

		matchingShD <= queueMaskNext(matchingD, zeroMask,
																 binFlowNum(bufferResponse.living),
																 --binFlowNum(bufferResponse.sending),
																	countOnes(sqOutData.fullMask),
																 prevSending);
			
		contentDataNext <= storeQueueNext(extractData(content), livingMask,
																 dataIn.data, dataIn.fullMask,
																 binFlowNum(bufferResponse.living),
																 --binFlowNum(bufferResponse.sending),
																	countOnes(sqOutData.fullMask),
																 prevSending,
																 dataA, dataD, wrAddress, wrData,
																 matchingShA, matchingShD,
																 CLEAR_COMPLETED);

		contentMaskNext <= queueMaskNext(livingMask, dataIn.fullMask,
																 binFlowNum(bufferResponse.living),
																 --binFlowNum(bufferResponse.sending),
																	countOnes(sqOutData.fullMask),
																 prevSending);
		contentUpdated <= makeSlotArray(contentDataNext, contentMaskNext);		
		contentNext <= contentUpdated;
		
		--sqOutData_2 <= findReadySQ(extractData(content), livingMask, nextAccepting);
		sqOutData	<= findCommittingSQ(extractData(content), livingMask, groupCtrNext);
				
			wrAddress <= storeAddressWr;
			wrData <= storeValueWr;
		
			dataA <= storeAddressDataIn;
			dataD <= storeValueDataIn;
					
			acceptingOutSQ <= '1'; -- TEMP!						
			sendingSQ <= isNonzero(sqOutData.fullMask);
			dataOutSQ <= sqOutData.data(0); -- CAREFUL, TEMP!
							
			--fullMask <= extractFullMask(content); -- DUPLICATE!
			
			contentData <= extractData(content);
			
			process (clk)
			begin
				if rising_edge(clk) then			
					content <= contentNext;
					
					logBuffer(contentData, fullMask, livingMask, bufferResponse);	
					-- NOTE: below has no info about flow constraints. It just checks data against
					--			flow numbers, while the validity of those numbers is checked by slot logic
					checkBuffer(extractData(content), fullMask, extractData(contentNext),
																				extractFullMask(contentNext),
										bufferDrive, bufferResponse);
				end if;
			end process;
					
			SLOT_HBUFF: entity work.BufferPipeLogic(Behavioral)
																	--BehavioralDirect)
			generic map(
				CAPACITY => QUEUE_SIZE, -- PIPE_WIDTH*2*2
				MAX_OUTPUT => PIPE_WIDTH,
				MAX_INPUT => PIPE_WIDTH
			)		
			port map(
				clk => clk, reset => reset, en => en,
				flowDrive => bufferDrive,
				flowResponse => bufferResponse
			);						

			bufferDrive.prevSending <= 
							num2flow(countOnes(dataIn.fullMask)) when prevSending = '1' else (others => '0');
			bufferDrive.kill <= num2flow(countOnes(killMask));
			bufferDrive.nextAccepting <= num2flow(countOnes(sqOutData.fullMask));
			acceptingOut <= --'1' when binFlowNum(bufferResponse.living) >= PIPE_WIDTH else '0';
								 --not isNonzero(livingMask(QUEUE_SIZE-PIPE_WIDTH to QUEUE_SIZE-1));		
								 not livingMask(QUEUE_SIZE-PIPE_WIDTH);
					
					KILLERS: for i in 0 to QUEUE_SIZE-1 generate
						signal before: std_logic;
						signal a, b: std_logic_vector(7 downto 0);
					begin
						a <= execCausing.groupTag;
						b <= content(i).ins.groupTag;
						IQ_KILLER: entity work.CompareBefore8 port map(
							inA =>  a,
							inB =>  b,
							outC => before
						);		
						killMask(i) <= killByTag(before, execEventSignal, '0') -- before and execEventSignal
												and fullMask(i);									
					end generate;
	sendingSQOut <= sendingSQ;
end Behavioral;

