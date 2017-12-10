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
			
			inputC: in InstructionSlot;
			inputE: in InstructionSlot;
			
--		sendingIQC: in std_logic;
--		sendingIQE: in std_logic; -- Store data
--
--		dataIQC: in InstructionState;
--		dataIQE: in InstructionState;	-- Store data			

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
	
	signal addressUnitSendingSig: std_logic := '0';
	
	signal sendingOutSQ: std_logic  := '0';
	signal dataOutSQV: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

	signal dlqAccepting: std_logic := '1';	
	signal sendingToDLQ, sendingFromDLQ: std_logic := '0';
	signal dataToDLQ: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	
	signal stageDataAfterCache, stageDataAfterSysRegs, lsResultData, execResultData, dataFromDLQ:
					InstructionState := DEFAULT_INSTRUCTION_STATE;
		signal stageDataMultiDLQ: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
					
	signal sendingMem0, sendingMem1, sendingAfterTranslation, sendingAfterRead: std_logic := '0';
		signal dataAfterTranslation, dataAfterRead: InstructionState := DEFAULT_INSTRUCTION_STATE;
	
	signal execAcceptingCSig, execAcceptingESig: std_logic := '0';	
	signal inputDataC: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	
	signal acceptingLS: std_logic := '0';
	signal sendingFromSysReg: std_logic := '0';	
	signal addressingData: InstructionState := DEFAULT_INSTRUCTION_STATE;
	
		signal effectiveAddressData: InstructionState := DEFAULT_INSTRUCTION_STATE;
		signal effectiveAddressSending: std_logic := '0';
	
	signal lqSelectedData, lqSelectedDataWithErr,
					 lqSelectedDataWithErrDelay: InstructionState := DEFAULT_INSTRUCTION_STATE;
	signal lqSelectedSending, lqSelectedSendingDelay: std_logic := '0';
	
	signal sendingAddressToSQSig,
				 storeAddressWrSig, storeValueWrSig,
				 sendingAddressing,
				 sendingAddressingForLoad, sendingAddressingForMfc,
				 sendingAddressingForStore, sendingAddressingForMtc: std_logic := '0';
	signal storeAddressDataSig, storeValueDataSig: InstructionState := DEFAULT_INSTRUCTION_STATE;
	signal storeForwardData, storeForwardDataDelay,
				stageDataAfterForward: InstructionState := DEFAULT_INSTRUCTION_STATE;
	signal storeForwardSending, storeForwardSendingDelay: std_logic := '0';

		signal sendingIQC: std_logic := '0';
		signal sendingIQE: std_logic := '0'; -- Store data

		signal dataIQC: InstructionState := DEFAULT_INSTRUCTION_STATE;
		signal dataIQE: InstructionState := DEFAULT_INSTRUCTION_STATE;	-- Store data

	function TMP_setLoadException(ins: InstructionState) return InstructionState is
		variable res: InstructionState := ins;
	begin
		res.controlInfo.hasException := '1';
		return res;
	end function;
	
	function TMP_lsResultData(ins: InstructionState;
									  memLoadReady: std_logic; memLoadValue: Mword;
									  sysLoadReady: std_logic; sysLoadValue: Mword;
									  storeForwardSending: std_logic; storeForwardIns: InstructionState
										) return InstructionState is
		variable res: InstructionState := ins;
	begin
		-- TODO: remember about miss/hit status and reason of miss if relevant!
		if storeForwardSending = '1' then
			res := setDataCompleted(res, getDataCompleted(storeForwardIns));
			res := setInsResult(res, storeForwardIns.argValues.arg2);
		elsif isSysRegRead(res) = '1' then
			res := setDataCompleted(res, sysLoadReady);
			res := setInsResult(res, sysLoadValue);		
		elsif isLoad(res) = '1' then 
			res := setDataCompleted(res, memLoadReady);
			res := setInsResult(res, memLoadValue);
		else -- is store or sys reg write?
			--res := setDataCompleted(res, '1'); -- ?
			--res := setAddressCompleted(res, '1'); -- ?
		end if;
		
		return res;
	end function;
	
		signal ch0, ch1, ch2: std_logic := '0';
begin
		eventSignal <= execOrIntEventSignalIn;	

			sendingIQC <= inputC.full;
			sendingIQE <= inputE.full;
			
			dataIQC <= inputC.ins;
			dataIQE <= inputE.ins;

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

			addressingData <= dataAfterTranslation;
			sendingAddressing <= sendingAfterTranslation;

		-- CAREFUL: Here we could inject form DLQ when needed
		inputDataLoadUnit.data(0) <= dataFromDLQ when sendingFromDLQ = '1'
										else effectiveAddressData;
		inputDataLoadUnit.fullMask(0) <= effectiveAddressSending or sendingFromDLQ;		

		SUBPIPE_LOAD_UNIT: block
			signal dataM, dataN, outputData, stageDataOutMem0: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;			
			signal acceptingMem1: std_logic := '0';
		begin
				STAGE_MEM0: entity work.GenericStageMulti(SingleTagged)
				port map(
					clk => clk, reset => reset, en => en,
					
					prevSending => effectiveAddressSending or sendingFromDLQ,
					nextAccepting => acceptingMem1 and dlqAccepting, -- needs free slot in LMQ in case of miss!
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

					sendingAfterTranslation <= sendingMem0;
					dataAfterTranslation <= stageDataOutMem0.data(0);

				dataM <= stageDataOutMem0;
				
				STAGE_MEM1: entity work.GenericStageMulti(SingleTagged)
				port map(
					clk => clk, reset => reset, en => en,
					
					prevSending => sendingMem0,
					nextAccepting => whichAcceptedCQ(2),
					
					stageDataIn => dataM, 
					acceptingOut => acceptingMem1,
					sendingOut => sendingMem1,
					stageDataOut => dataN,
					
					execEventSignal => eventSignal,
					lateEventSignal => lateEventSignal,
					execCausing => execCausing,
					lockCommand => '0',
					
					stageEventsOut => open					
				);

					sendingAfterRead <= sendingMem1; -- TEMP!
					dataAfterRead <= dataN.data(0);

					-- CAREFUL: when miss (incl. forwarding miss), no 'completed' signal.
					--				
					addressUnitSendingSig <= (sendingAfterRead and (not sendingToDLQ))
												 or lqSelectedSendingDelay; --??? -- because load exc to ROB
										
					outputData.data(0) <= execResultData;
					outputData.fullMask(0) <= '0';-- UNUSED

			outputC <= (addressUnitSendingSig, clearTempControlInfoSimple(outputData.data(0)));

			outputOpPreC <= stageDataOutMem0.data(0);
		end block;

		sendingAddressingForLoad <= sendingAddressing and isLoad(addressingData);		
		sendingAddressingForMfc <= sendingAddressing and isSysRegRead(addressingData);
			
		sendingAddressingForStore <= sendingAddressing and isStore(addressingData);
		sendingAddressingForMtc <= sendingAddressing and isSysRegWrite(addressingData);
			
		sendingAddressToSQSig <= sendingAddressingForStore or sendingAddressingForMtc;	

		-- CAREFUL, TODO: if mem subpipe can be locked, then memLoadReady will expire while the
		--						corresponding load is stalled, and it will go to LMQ. In such case
		--						it has to be clear that the load has status "ready for reexec" because
		--						the cache location won't be refiled as it is already full!
		--						So there would be a need to distinguish "missed" from "not received"
		--						as the latter would go to LMQ as "ready" from the start.
		--						OFC it is simpler never to stall the mem subpipe.
		stageDataAfterCache <= setInsResult(setDataCompleted(dataAfterRead, memLoadReady), memLoadValue);
		stageDataAfterSysRegs <= setInsResult(setDataCompleted(dataAfterRead, sendingFromSysReg), sysLoadVal);
		stageDataAfterForward <= setInsResult(setDataCompleted(dataAfterRead, 
																				 getDataCompleted(storeForwardDataDelay)),
														  storeForwardDataDelay.argValues.arg2);

			lsResultData <= TMP_lsResultData(dataAfterRead, memLoadReady, memLoadValue,
																		sendingFromSysReg, sysLoadVal,
																		storeForwardSendingDelay, storeForwardDataDelay);

		execResultData <= lqSelectedDataWithErrDelay when lqSelectedSendingDelay = '1'
						else	lsResultData;
	
		lqSelectedDataWithErr <= TMP_setLoadException(lqSelectedData);
	
			-- Sending to Delayed Load Queue: when load miss or load and sending from sys reg
			sendingToDLQ <= (		sendingAfterRead
								 and (isLoad(lsResultData) or isSysRegRead(lsResultData))
								 and not getDataCompleted(lsResultData))  -- When missed etc.
							or  lqSelectedSending; -- When store hits younger load and must get off the way
								 
			dataToDLQ.data(0) <= lsResultData; -- CAREFUL: when older store hit after younger load,
																	--	 		giving here the store address op.
																	--			Selection from LQ will go forward instead,
																	--			to write err signal to ROB
			dataToDLQ.fullMask(0) <= sendingToDLQ;

------------------------------------------------------------------------------------------------
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

					selectedDataOut => lqSelectedData,
					selectedSending => lqSelectedSending,
					
					committing => committing,
					groupCtrInc => groupCtrInc,

					lateEventSignal => lateEventSignal,
				execEventSignal => eventSignal,
				execCausing => execCausing,

				nextAccepting => '1',

				sendingSQOut => open,
					dataOutV => open
			);

			DELAYED_LOAD_QUEUE: entity work.MemoryUnit(LoadMissQueue)
			generic map(
				QUEUE_SIZE => LMQ_SIZE,
				CLEAR_COMPLETED => false
			)
			port map(
				clk => clk,
				reset => reset,
				en => en,
				
					acceptingOut => dlqAccepting,
					prevSending => sendingToDLQ,
					dataIn => dataToDLQ,
				
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
				
				nextAccepting => '1', -- TODO: when should it be allowed to send?
											 --		 Priorities!				
				sendingSQOut => sendingFromDLQ,
					dataOutV => stageDataMultiDLQ
			);
			
			dataFromDLQ <= stageDataMultiDLQ.data(0);

			TMP_REG: process(clk)
			begin
				if rising_edge(clk) then
					sendingFromSysReg <= sendingAddressingForMfc;
					
					storeForwardDataDelay <= storeForwardData;
					storeForwardSendingDelay <= storeForwardSending;

					lqSelectedSendingDelay <= lqSelectedSending;
					lqSelectedDataWithErrDelay <= lqSelectedDataWithErr;
				end if;
			end process;


			execAcceptingC <= execAcceptingCSig;
			execAcceptingE <= '1'; --???  -- execAcceptingESig;
			
				-- Mem interface
				memLoadAddress <= addressingData.result; -- in LoadUnit
				memLoadAllow <= sendingAddressingForLoad;
				sysLoadAllow <= sendingAddressingForMfc;	 
				 
			dataOutSQ <= dataOutSQV;
end Behavioral;
