----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:39:00 03/19/2017 
-- Design Name: 
-- Module Name:    LoadMissQueue - Behavioral 
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

--entity LoadMissQueue is
--	generic(
--		QUEUE_SIZE: integer := 4;
--		CLEAR_COMPLETED: boolean := true
--	);
--	port(
--		clk: in std_logic;
--		reset: in std_logic;
--		en: in std_logic;
--
--		acceptingOut: out std_logic;
--		prevSending: in std_logic;
--		dataIn: in StageDataMulti;
--
--		storeAddressWr: in std_logic;
--		storeValueWr: in std_logic;
--
--		storeAddressDataIn: in InstructionState;
--		storeValueDataIn: in InstructionState;
--
--			compareAddressDataIn: in InstructionState;
--			compareAddressReady: in std_logic;
--
--			selectedDataOut: out InstructionState;
--			selectedSending: out std_logic;
--
--		committing: in std_logic;
--		groupCtrInc: in SmallNumber; -- CAREFUL: differs from MemoryUnit
--
--		lateEventSignal: in std_logic;
--		execEventSignal: in std_logic;
--		execCausing: in InstructionState;
--		
--		nextAccepting: in std_logic;	
--		sendingSQOut: out std_logic;
--			dataOutV: out StageDataMulti
--	);
--end LoadMissQueue;


architecture LoadMissQueue of MemoryUnit is--LoadMissQueue is
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
				matchingShA, matchingShD, firstReadyVec, sendingVec
				: std_logic_vector(0 to QUEUE_SIZE-1) := (others => '0');

	signal bufferDrive: FlowDriveBuffer := (killAll => '0', lockAccept => '0', lockSend => '0',
																others=>(others=>'0'));
	signal bufferResponse: FlowResponseBuffer := (others=>(others=>'0'));	
begin				
		fullMask <= extractFullMask(content);
		livingMask <= fullMask and not killMask;
							
		matchingA <= findMatching(content, dataA);
		matchingD <= findMatching(content, dataD);
							
		sendingVec <= firstReadyVec when nextAccepting = '1' else (others => '0');					
							
		matchingShA <= lmMaskNext(matchingA, zeroMask,
																 binFlowNum(bufferResponse.living),
																 --binFlowNum(bufferResponse.sending),
																 sendingVec,
																 prevSending);																
		matchingShD <= lmMaskNext(matchingD, zeroMask,
																 binFlowNum(bufferResponse.living),
																 --binFlowNum(bufferResponse.sending),
																 sendingVec,
																 prevSending);
		
		-- TODO: enable sending from any slot! And preserve mem address (when enqueueing, don't clear it!)
		--			Add vector with position of first ready
		contentDataNext <= lmQueueNext(extractData(content), livingMask,
																 dataIn.data, dataIn.fullMask,
																 binFlowNum(bufferResponse.living),
																 --binFlowNum(bufferResponse.sending),
																	sendingVec,
																 prevSending,
																 dataA, dataD, wrAddress, wrData,
																 matchingShA, matchingShD,
																 CLEAR_COMPLETED);
		contentMaskNext <= lmMaskNext(livingMask, dataIn.fullMask,
																 binFlowNum(bufferResponse.living),
																 --binFlowNum(bufferResponse.sending),
																 sendingVec,
																 prevSending);
		contentUpdated <= makeSlotArray(contentDataNext, contentMaskNext);		
		contentNext <= contentUpdated;
		
			firstReadyVec <= findFirstFilled(extractData(content), livingMask, nextAccepting);
				
			wrAddress <= storeAddressWr;
			wrData <= storeValueWr;
		
			dataA <= storeAddressDataIn;
			dataD <= storeValueDataIn;
					
			sendingSQ <= isNonzero(firstReadyVec);
				dataOutV.fullMask(0) <= sendingSq;
				dataOutV.data(0) <= chooseIns(extractData(content), firstReadyVec);

			contentData <= extractData(content);
								
			process (clk)
			begin
				if rising_edge(clk) then			
					content <= contentNext;
					
					--logBuffer(contentData, fullMask, livingMask, bufferResponse);	
					-- NOTE: below has no info about flow constraints. It just checks data against
					--			flow numbers, while the validity of those numbers is checked by slot logic
					checkBuffer(extractData(content), fullMask, extractData(contentNext),
																				extractFullMask(contentNext),
										bufferDrive, bufferResponse);					
				end if;
			end process;
					
			SLOT_BUFF: entity work.BufferPipeLogic(BehavioralDirect)
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
			bufferDrive.nextAccepting <= num2flow(1) when sendingSq = '1' else num2flow(0);
			acceptingOut <= not fullMask(QUEUE_SIZE-PIPE_WIDTH);
				

			killMask <=	getKillMask(extractData(content), fullMask,
											execCausing, execEventSignal, lateEventSignal);
		
	sendingSQOut <= sendingSQ;
end LoadMissQueue;

