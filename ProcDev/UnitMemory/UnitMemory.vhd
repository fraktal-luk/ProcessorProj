----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:06:40 02/12/2017 
-- Design Name: 
-- Module Name:    UnitMemory - Behavioral 
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

--use work.CommonRouting.all;
use work.TEMP_DEV.all;

use work.ProcLogicExec.all;


entity UnitMemory is
	port(
		clk : in  STD_LOGIC;
		reset : in  STD_LOGIC;
		en : in  STD_LOGIC;	

		sendingIQC: in std_logic;
		sendingIQE: in std_logic; -- Store data

		dataIQC: in InstructionState;
		dataIQE: in InstructionState;	-- Store data			

		execAcceptingC: out std_logic;
		execAcceptingE: out std_logic; -- Store data
			
		acceptingNewSQ: out std_logic;
		acceptingNewLQ: out std_logic;
		prevSendingToSQ: in std_logic;
		prevSendingToLQ: in std_logic;
		dataNewToSQ: in StageDataMulti;
		dataNewToLQ: in StageDataMulti;			

		outputC: out InstructionSlot;
		outputE: out InstructionSlot;
		outputOpPreC: out InstructionState;

		whichAcceptedCQ: in std_logic_vector(0 to 3);

			memLoadReady: in std_logic;
			memLoadValue: in Mword;
			memLoadAddress: out Mword;
			memStoreAddress: out Mword;
			memLoadAllow: out std_logic;
			memStoreAllow: out std_logic;
			memStoreValue: out Mword;
			
			sysRegDataIn: in InstructionState;
			sysRegSendingIn: in std_logic;
			
			committing: in std_logic;
			groupCtrNext: in SmallNumber;
			groupCtrInc: in SmallNumber;
			
		execOrIntEventSignalIn: in std_logic;
		execOrIntCausingIn: in InstructionState			
	);
end UnitMemory;


architecture Behavioral of UnitMemory is
	signal inputDataLoadUnit, outputDataLoadUnit: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;	
	signal eventSignal: std_logic := '0';	
	signal activeCausing: InstructionState := defaultInstructionState;
	
	signal loadUnitSendingSig: std_logic := '0';
	
	signal sendingOutSQ: std_logic  := '0';
	signal dataOutSQ: InstructionState := DEFAULT_INSTRUCTION_STATE;
	
	signal sendingToDLQ, sendingFromDLQ, loadResultSending, isLoad: std_logic := '0';
	signal dataToDLQ: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	
	signal stageDataAfterCache, loadResultData, dataFromDLQ:
					InstructionState := defaultInstructionState;
	signal sendingMem0, sendingMem1: std_logic := '0';

	signal sendingFromSysReg: std_logic := '0';
	signal sysRegReadData: InstructionState := defaultInstructionState;
	
	signal dlqAccepting: std_logic := '1';
	
		signal inputDataC, outputDataC: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
		signal acceptingLS, acceptingLU: std_logic := '0';

	signal execAcceptingCSig, execAcceptingESig: std_logic := '0';	
	
	signal addressingData: InstructionState := DEFAULT_INSTRUCTION_STATE;
	signal sendingAddressingSig: std_logic := '0';	
	
		signal sendingToLoadUnitSig, sendingAddressToSQSig,
				 storeAddressWrSig, storeValueWrSig: std_logic := '0';
		signal dataToLoadUnitSig, storeAddressDataSig, storeValueDataSig: InstructionState
					:= DEFAULT_INSTRUCTION_STATE;
----------------	
	signal ch0, ch1, ch2, ch3, ch4, ch5, ch6, ch7: std_logic := '0';
begin
		eventSignal <= execOrIntEventSignalIn;	
		activeCausing <= execOrIntCausingIn;

			inputDataC.data(0) <= dataIQC;
			inputDataC.fullMask(0) <= sendingIQC;

			SUBPIPE_C: block
				signal inputData, outputData: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
				
				signal stageDataOutAGU: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
				signal sendingAGU: std_logic := '0';
					
				signal stageDataOutMem0, stageDataOutMem1: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
				signal acceptingMem0, acceptingMem1,
						 sendingMem0, sendingMem1: std_logic := '0';
			begin
				STAGE_AGU: entity work.SimpleAlu(BehavioralAGU)
				port map(
					clk => clk, reset => reset, en => en,
					
					prevSending => sendingIQC,
					nextAccepting => acceptingLS,
					
					stageDataIn => inputDataC, 
					acceptingOut => execAcceptingCSig,
					sendingOut => sendingAGU,
					stageDataOut => stageDataOutAGU,
					
					execEventSignal => eventSignal,
					execCausing => activeCausing,
					lockCommand => '0',
					
					stageEventsOut => open
				);
			
				addressingData <= stageDataOutAGU.data(0);
				sendingAddressingSig <= sendingAGU;		-- TODO: erase "Sig" when sendingAddressing input is out		
			end block;
				
			-- Store data unit.
			SUBPIPE_E: block
				signal inputData, outputData: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
			begin
				inputData.data(0) <= dataIQE;
				inputData.fullMask(0) <= sendingIQE;
			end block;

			inputDataLoadUnit.data(0) <= dataToLoadUnitSig;
			inputDataLoadUnit.fullMask(0) <= sendingAddressingSig;
			
					outputE.ins <= dataIQE;
					outputE.full <= sendingIQE;
						
			SUBPIPE_LOAD_UNIT: block
				signal inputData, outputData: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
			
				signal dataM: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;				

				signal stageDataOutMem0, stageDataOutMem1: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
				signal acceptingMem0, acceptingMem1: std_logic := '0';
			begin
				STAGE_MEM0: entity work.GenericStageMulti(SingleTagged)
				port map(
					clk => clk, reset => reset, en => en,
					
					prevSending => sendingAddressingSig,
					nextAccepting => acceptingMem1 --, -- CAREFUL: should depend on loadUnit accepting? (below:)
																and dlqAccepting, -- need free slot in LMQ in case of miss!
					stageDataIn => inputDataLoadUnit,
					acceptingOut => acceptingLS,
					sendingOut => sendingMem0,
					stageDataOut => stageDataOutMem0,
					
					execEventSignal => eventSignal,
					execCausing => activeCausing,
					lockCommand => '0',
					
					stageEventsOut => open					
				);
				
				dataM.data(0) <= loadResultData;
				dataM.fullMask(0) <= loadResultSending;
				
				STAGE_MEM1: entity work.GenericStageMulti(SingleTagged)
				port map(
					clk => clk, reset => reset, en => en,
					
					prevSending => loadResultSending,--sendingMem0,
					nextAccepting => whichAcceptedCQ(2),
					
					stageDataIn => dataM, 
					acceptingOut => acceptingMem1,
					sendingOut => loadUnitSendingSig,
					stageDataOut => outputData,
					
					execEventSignal => eventSignal,
					execCausing => activeCausing,
					lockCommand => '0',
					
					stageEventsOut => open					
				);

				stageDataAfterCache <= setExecState(stageDataOutMem0.data(0), memLoadValue, '0', "0000");

					outputC.ins <= clearTempControlInfoSimple(outputData.data(0));
					outputC.full <= loadUnitSendingSig;
					
					outputOpPreC <= stageDataOutMem0.data(0);
			end block;		
		
		sendingToLoadUnitSig <= sendingAddressingSig when addressingData.operation.func = load else '0';
		sendingAddressToSQSig <= sendingAddressingSig when addressingData.operation.func = store else '0';
				
		dataToLoadUnitSig <= addressingData;
								
		-- SQ inputs
		storeAddressWrSig <= sendingAddressToSQSig;
		storeValueWrSig <= sendingIQE;
				
		-- SQ inputs
		storeAddressDataSig <= addressingData; -- Mem unit interface
		storeValueDataSig <= dataIQE; -- Mem unit interface		

			STORE_QUEUE: entity work.MemoryUnit(Behavioral)
			generic map(
				QUEUE_SIZE => SQ_SIZE
			)
			port map(
				clk => clk,
				reset => reset,
				en => en,
				
					acceptingOut => acceptingNewSQ,
					prevSending => prevSendingToSQ,
					dataIn => dataNewToSQ,
				
				storeAddressWr => storeAddressWrSig,
				storeValueWr => storeValueWrSig,

				storeAddressDataIn => storeAddressDataSig,
				storeValueDataIn => storeValueDataSig,
				
					committing => committing,
					groupCtrNext => groupCtrNext,
						groupCtrInc => groupCtrInc,
						
				execEventSignal => eventSignal,
				execCausing => activeCausing,
				
				nextAccepting => '1',
				
				--acceptingOutSQ => execAcceptingESig,
				sendingSQOut => sendingOutSQ, -- OUTPUT
				dataOutSQ => dataOutSQ -- OUTPUT
			);

			MEM_LOAD_QUEUE: entity --work.LoadQueue(Behavioral)
											work.MemoryUnit(Behavioral)
			generic map(
				QUEUE_SIZE => LQ_SIZE
			)											
			port map(
				clk => clk,
				reset => reset,
				en => en,
				
					acceptingOut => acceptingNewLQ,
					prevSending => prevSendingToLQ,
					dataIn => dataNewToLQ,
				
				storeAddressWr => sendingToLoadUnitSig, --?
				storeValueWr => '0', --!!

				storeAddressDataIn => dataToLoadUnitSig, --?
				storeValueDataIn => DEFAULT_INSTRUCTION_STATE,--!!

					committing => committing,
					groupCtrNext => groupCtrNext,
						groupCtrInc => groupCtrInc,

				execEventSignal => eventSignal,
				execCausing => activeCausing,

				nextAccepting => '1',

				--acceptingOutSQ => open,--acceptingLoadUnitOut, -- ! dont do multiple drivers!
				sendingSQOut => open,--sendingOutLQ, --??
				dataOutSQ => open--dataOutLQ--?? 
			);

			-- Sending to Delayed Load Queue: when load miss or load and sending from sys reg
			sendingFromSysReg <= sysRegSendingIn;
			sysRegReadData <= sysRegDataIn;
			
			isLoad <= '1' when stageDataAfterCache.operation.func = load else '0';
			
			sendingToDLQ <= sendingMem0 and isLoad
								and (not memLoadReady or (memLoadReady and sendingFromSysReg));
			dataToDLQ.data(0) <= stageDataAfterCache;
			dataToDLQ.fullMask(0) <= sendingToDLQ;

			DELAYED_LOAD_QUEUE: entity work.LoadMissQueue(Behavioral)
			generic map(
				QUEUE_SIZE => LMQ_SIZE,
				CLEAR_COMPLETED => false
			)
			port map(
				clk => clk,
				reset => reset,
				en => en,
				
					acceptingOut => dlqAccepting,
					prevSending => sendingToDLQ, -- TODO: memLoadReady and higher prio going to "load result"
					dataIn => dataToDLQ,--TODO: data from cache
				
				storeAddressWr => '0',
				storeValueWr => '0',

				storeAddressDataIn => DEFAULT_INSTRUCTION_STATE,
				storeValueDataIn => DEFAULT_INSTRUCTION_STATE,

					committing => committing,
					groupCtrNext => groupCtrNext,
					
				execEventSignal => eventSignal,
				execCausing => activeCausing,
				
				nextAccepting => not sendingFromSysReg,
				
				acceptingOutSQ => open, -- TODO
				sendingSQOut => sendingFromDLQ,
				dataOutSQ => dataFromDLQ
			);


				execAcceptingC <= execAcceptingCSig;
				execAcceptingE <= '1'; --???  -- execAcceptingESig;

			loadResultSending <= sendingFromSysReg or sendingFromDLQ 
						or (sendingMem0);-- and memLoadReady);
					-- CAREFUL, TODO: ^ memLoadReady needed to ack that not a miss? But would block when a store!
			loadResultData <=
					  sysRegReadData when sendingFromSysReg = '1'
				else dataFromDLQ when sendingFromDLQ = '1'
				else stageDataAfterCache;

				-- Mem interface
				memStoreAddress <= dataOutSQ.argValues.arg1;
				memStoreValue <= dataOutSQ.argValues.arg2;
		
				memLoadAddress <= dataToLoadUnitSig.result; -- in LoadUnit
		
				memLoadAllow <= sendingToLoadUnitSig;
				memStoreAllow <= sendingOutSQ;
			
end Behavioral;

