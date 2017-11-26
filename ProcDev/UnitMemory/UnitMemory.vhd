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

use work.TEMP_DEV.all;

use work.ProcLogicExec.all;
use work.ProcLogicMemory.all;

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
			memLoadAllow: out std_logic;

			sysLoadAllow: out std_logic;
			sysLoadVal: in Mword;
			
			committing: in std_logic;
			groupCtrNext: in SmallNumber;
			groupCtrInc: in SmallNumber;
		
			sbAcceptingIn: in std_logic;
			dataOutSQ: out StageDataMulti;

		lateEventSignal: in std_logic;	
		execOrIntEventSignalIn: in std_logic;
			execCausing: in InstructionState
	);
end UnitMemory;


architecture Behavioral of UnitMemory is
	signal inputDataLoadUnit: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	signal eventSignal: std_logic := '0';	
	
	signal loadUnitSendingSig: std_logic := '0';
	
	signal sendingOutSQ: std_logic  := '0';
	signal dataOutSQV: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

	signal dlqAccepting: std_logic := '1';	
	signal sendingToDLQ, sendingFromDLQ, loadResultSending: std_logic := '0';
	signal dataToDLQ: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	
	signal stageDataAfterCache, stageDataAfterSysRegs, loadResultData, dataFromDLQ:
					InstructionState := DEFAULT_INSTRUCTION_STATE;
		signal stageDataMultiDLQ: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
					
	signal sendingMem0, sendingAfterRead: std_logic := '0';
		signal dataAfterRead: InstructionState := DEFAULT_INSTRUCTION_STATE;
	
	signal execAcceptingCSig, execAcceptingESig: std_logic := '0';	
	signal inputDataC: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	
	signal acceptingLS: std_logic := '0';
	signal sendingFromSysReg: std_logic := '0';	
	signal addressingData: InstructionState := DEFAULT_INSTRUCTION_STATE;
	signal sendingAddressingSig: std_logic := '0';	
	
		signal effectiveAddressData: InstructionState := DEFAULT_INSTRUCTION_STATE;
		signal effectiveAddressSending: std_logic := '0';
	
	signal sendingAddressToSQSig,
				 storeAddressWrSig, storeValueWrSig,
				 sendingAddressing,
				 sendingAddressingForLoad, sendingAddressingForMfc,
				 sendingAddressingForStore, sendingAddressingForMtc: std_logic := '0';
	signal storeAddressDataSig, storeValueDataSig: InstructionState := DEFAULT_INSTRUCTION_STATE;
	signal storeForwardData, stageDataAfterForward: InstructionState := DEFAULT_INSTRUCTION_STATE;
	signal storeForwardSending, storeForwardSendingDelay: std_logic := '0'; 
begin
		eventSignal <= execOrIntEventSignalIn;	

		inputDataC.data(0) <=			
				 setInsResult(dataIQC, addMwordFaster(dataIQC.argValues.arg0, dataIQC.argValues.arg1));
	
			inputDataC.fullMask(0) <= sendingIQC;

			SUBPIPE_C: block
				signal stageDataOutAGU: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
				signal sendingAGU: std_logic := '0';
			begin
				STAGE_AGU: entity work.GenericStageMulti(SingleTagged)
				port map(
					clk => clk, reset => reset, en => en,
					
					prevSending => sendingIQC,
					nextAccepting => acceptingLS,
					
					stageDataIn => inputDataC, 
					acceptingOut => execAcceptingCSig,
					sendingOut => sendingAGU,
					stageDataOut => stageDataOutAGU,
					
					execEventSignal => eventSignal,
					lateEventSignal => lateEventSignal,
					execCausing => execCausing,
					lockCommand => '0',
					
					stageEventsOut => open
				);
			
				effectiveAddressData <= stageDataOutAGU.data(0);
				effectiveAddressSending <= sendingAGU;	
			end block;
				
		--	block empty
		SUBPIPE_E: block
		begin
		end block;

		outputE <= (sendingIQE, dataIQE);

			addressingData <= effectiveAddressData;
			sendingAddressingSig <= effectiveAddressSending;
				sendingAddressing <= effectiveAddressSending;

		-- CAREFUL: Here we could inject form DLQ when needed
		inputDataLoadUnit.data(0) <= effectiveAddressData;
		inputDataLoadUnit.fullMask(0) <= effectiveAddressSending;		

		SUBPIPE_LOAD_UNIT: block
			signal dataM, outputData, stageDataOutMem0: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;			
			signal acceptingMem1: std_logic := '0';
		begin
				STAGE_MEM0: entity work.GenericStageMulti(SingleTagged)
				port map(
					clk => clk, reset => reset, en => en,
					
					prevSending => effectiveAddressSending,
					nextAccepting => acceptingMem1 --, -- CAREFUL: should depend on loadUnit accepting? (below:)
																and dlqAccepting, -- need free slot in LMQ in case of miss!
					stageDataIn => inputDataLoadUnit,
					acceptingOut => acceptingLS,
					sendingOut => sendingMem0,
					stageDataOut => stageDataOutMem0,
					
					execEventSignal => eventSignal,
					lateEventSignal => lateEventSignal,					
					execCausing => execCausing,
					lockCommand => '0',
					
					stageEventsOut => open					
				);

					sendingAfterRead <= sendingMem0; -- TEMP!
					dataAfterRead <= stageDataOutMem0.data(0);

			stageDataAfterForward <= setInsResult(dataAfterRead, storeForwardData.argValues.arg2);
			stageDataAfterCache <= setInsResult(setDataCompleted(dataAfterRead, memLoadReady),
															memLoadValue);
			stageDataAfterSysRegs <= setInsResult(setDataCompleted(dataAfterRead, sendingFromSysReg),
															  sysLoadVal);
			
				dataM.data(0) <= loadResultData;
				dataM.fullMask(0) <= loadResultSending;
				
				STAGE_MEM1: entity work.GenericStageMulti(SingleTagged)
				port map(
					clk => clk, reset => reset, en => en,
					
					prevSending => loadResultSending,
					nextAccepting => whichAcceptedCQ(2),
					
					stageDataIn => dataM, 
					acceptingOut => acceptingMem1,
					sendingOut => loadUnitSendingSig,
					stageDataOut => outputData,
					
					execEventSignal => eventSignal,
					lateEventSignal => lateEventSignal,
					execCausing => execCausing,
					lockCommand => '0',
					
					stageEventsOut => open					
				);

			outputC <= (loadUnitSendingSig, clearTempControlInfoSimple(outputData.data(0)));

			outputOpPreC <= stageDataOutMem0.data(0);
		end block;

		sendingAddressingForLoad <= sendingAddressing and isLoad(addressingData);		
		sendingAddressingForMfc <= sendingAddressing and isSysRegRead(addressingData);
			
		sendingAddressingForStore <= sendingAddressing and isStore(addressingData);
		sendingAddressingForMtc <= sendingAddressing and isSysRegWrite(addressingData);
			
		sendingAddressToSQSig <= sendingAddressingForStore or sendingAddressingForMtc;	


			loadResultSending <= (sendingFromSysReg or sendingFromDLQ or memLoadReady
																							or storeForwardSendingDelay)
										or (sendingAfterRead and isStore(loadResultData)); 
											-- CAREFUL: this is for stores, loadResultSig sh. be renamed
					-- CAREFUL, TODO: ^ memLoadReady needed to ack that not a miss? But would block when a store!
					
			loadResultData <= -- TODO: as with DLQ sending, what prios?
					  stageDataAfterSysRegs when sendingFromSysReg = '1'
				else dataFromDLQ when sendingFromDLQ = '1'
				else stageDataAfterForward when storeForwardSendingDelay = '1'
				else stageDataAfterCache;


	
		-- SQ inputs
		storeAddressWrSig <= sendingAddressToSQSig;
		storeValueWrSig <= sendingIQE;
				
		-- SQ inputs
		storeAddressDataSig <= addressingData; -- Mem unit interface
		storeValueDataSig <= dataIQE; -- Mem unit interface		

			STORE_QUEUE: entity work.MemoryUnit(Behavioral)
			generic map(
				QUEUE_SIZE => SQ_SIZE,
				MODE => store
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
				
					compareAddressDataIn => addressingData,
					compareAddressReady => sendingAddressingForLoad or sendingAddressingForMfc,

					selectedDataOut => storeForwardData,
					selectedSending => storeForwardSending,
				
					committing => committing,
					groupCtrInc => groupCtrInc,
						
					lateEventSignal => lateEventSignal,	
				execEventSignal => eventSignal,
				execCausing => execCausing,
				
				nextAccepting => '1',
				
				sendingSQOut => sendingOutSQ,
					dataOutV => dataOutSQV
			);

			MEM_LOAD_QUEUE: entity work.MemoryUnit(Behavioral)
			generic map(
				QUEUE_SIZE => LQ_SIZE,
				MODE => load
			)											
			port map(
				clk => clk,
				reset => reset,
				en => en,
				
					acceptingOut => acceptingNewLQ,
					prevSending => prevSendingToLQ,
					dataIn => dataNewToLQ,
				
				storeAddressWr => sendingAddressingForLoad or sendingAddressingForMfc,
				storeValueWr => sendingAddressingForLoad or sendingAddressingForMfc,

				storeAddressDataIn => addressingData, --?
				storeValueDataIn => DEFAULT_INSTRUCTION_STATE,

					compareAddressDataIn => storeAddressDataSig,
					compareAddressReady => storeAddressWrSig,

					selectedDataOut => open,
					selectedSending => open,
					
					committing => committing,
					groupCtrInc => groupCtrInc,

					lateEventSignal => lateEventSignal,
				execEventSignal => eventSignal,
				execCausing => execCausing,

				nextAccepting => '1',

				sendingSQOut => open,
					dataOutV => open
			);
			-- TODO: utilize info about store address hit in LoadQueue to squash the incorrect load.


			-- Sending to Delayed Load Queue: when load miss or load and sending from sys reg
			sendingToDLQ <= 		sendingAfterRead -- TODO: synonymous with "load/mfc sending" but may change
								 and (isLoad(loadResultData) or isSysRegRead(loadResultData)) -- not store!
								 and not getDataCompleted(loadResultData); -- When missed
								 
			dataToDLQ.data(0) <= stageDataAfterCache;
			dataToDLQ.fullMask(0) <= sendingToDLQ;

			DELAYED_LOAD_QUEUE: entity work.--LoadMissQueue(Behavioral)
														MemoryUnit(LoadMissQueue)
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

					compareAddressDataIn => DEFAULT_INSTRUCTION_STATE,
					compareAddressReady => '0',

					selectedDataOut => open,
					selectedSending => open,
			
					committing => committing,
					groupCtrInc => (others => '0'),
					
					lateEventSignal => lateEventSignal,
				execEventSignal => eventSignal,
				execCausing => execCausing,
				
				nextAccepting => '1',--not sendingFromSysReg, -- TODO: when should it be allowed to send?
																			 --		 Priorities!
				
				sendingSQOut => sendingFromDLQ,
					dataOutV => stageDataMultiDLQ
			);
				dataFromDLQ <= stageDataMultiDLQ.data(0);
			
			execAcceptingC <= execAcceptingCSig;
			execAcceptingE <= '1'; --???  -- execAcceptingESig;

			TMP_REG: process(clk)
			begin
				if rising_edge(clk) then
					sendingFromSysReg <= sendingAddressingForMfc;
					storeForwardSendingDelay <= storeForwardSending;						
				end if;
			end process;

				-- Mem interface
				memLoadAddress <= addressingData.result; -- in LoadUnit
				memLoadAllow <= sendingAddressingForLoad;
				sysLoadAllow <= sendingAddressingForMfc;	 
				 
			dataOutSQ <= dataOutSQV;
end Behavioral;
