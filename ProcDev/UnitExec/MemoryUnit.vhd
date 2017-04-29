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
		groupCtrInc: in SmallNumber;

		execEventSignal: in std_logic;
		execCausing: in InstructionState;
		
		nextAccepting: in std_logic;		
		sendingSQOut: out std_logic;
		dataOutSQ: out InstructionState
	);
end MemoryUnit;


architecture Behavioral of MemoryUnit is
	constant zeroMask: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');

	signal sendingSQ: std_logic := '0';							

	signal content, contentNext, contentUpdated:
					InstructionSlotArray(0 to QUEUE_SIZE-1) := (others => DEFAULT_INSTRUCTION_SLOT);
	signal contentData, contentDataNext: InstructionStateArray(0 to QUEUE_SIZE-1)
																			:= (others => DEFAULT_INSTRUCTION_STATE);
	signal fullMask, livingMask, killMask, contentMaskNext, matchingA, matchingD,
								matchingShA, matchingShD: std_logic_vector(0 to QUEUE_SIZE-1) := (others => '0'); 
	signal sqOutData: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

	signal bufferDrive: FlowDriveBuffer := (killAll => '0', lockAccept => '0', lockSend => '0',
																others=>(others=>'0'));
	signal bufferResponse: FlowResponseBuffer := (others=>(others=>'0'));
begin				
		fullMask <= extractFullMask(content);
		livingMask <= fullMask and not killMask;
							
		matchingA <= findMatching(content, storeAddressDataIn); --dataA);
		matchingD <= findMatching(content, storeValueDataIn); -- dataD);
							
		matchingShA <= queueMaskNext(matchingA, zeroMask,
																 binFlowNum(bufferResponse.full),
																 countOnes(sqOutData.fullMask),
																 prevSending);																

		matchingShD <= queueMaskNext(matchingD, zeroMask,
																 binFlowNum(bufferResponse.full),
																 countOnes(sqOutData.fullMask),
																 prevSending);
			
		contentDataNext <= storeQueueNext(extractData(content), fullMask,
																 dataIn.data, dataIn.fullMask,
																 binFlowNum(bufferResponse.full),
																 countOnes(sqOutData.fullMask),
																 prevSending,
																 storeAddressDataIn, --dataA
																 storeValueDataIn,--dataD,
																 storeAddressWr, storeValueWr,
																 matchingShA, matchingShD,
																 CLEAR_COMPLETED);

		contentMaskNext <= queueMaskNext(livingMask, dataIn.fullMask,
																 binFlowNum(bufferResponse.living),
																 countOnes(sqOutData.fullMask),
																 prevSending);
		contentUpdated <= makeSlotArray(contentDataNext, contentMaskNext);		
		contentNext <= contentUpdated;
		
			sqOutData <= findCommittingSQ(extractData(content), livingMask, groupCtrInc, committing);
					
			sendingSQ <= isNonzero(sqOutData.fullMask);
			dataOutSQ <= sqOutData.data(0); -- CAREFUL, TEMP!
			
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
					
			SLOT_BUFF: entity work.BufferPipeLogic(Behavioral)
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

	bufferDrive.prevSending <=num2flow(countOnes(dataIn.fullMask)) when prevSending = '1' else (others => '0');
	bufferDrive.kill <= num2flow(countOnes(killMask));
	bufferDrive.nextAccepting <= num2flow(countOnes(sqOutData.fullMask));
					
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
					
	acceptingOut <= not fullMask(QUEUE_SIZE-PIPE_WIDTH); -- when last slot free					
	sendingSQOut <= sendingSQ;
end Behavioral;

