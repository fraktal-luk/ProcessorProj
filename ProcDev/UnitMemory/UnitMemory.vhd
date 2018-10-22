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
			
		inputC: in SchedulerEntrySlot;
		inputE: in SchedulerEntrySlot;			

		--execAcceptingC: out std_logic;
		--execAcceptingE: out std_logic; -- Store data
			
		acceptingNewSQ: out std_logic;
		acceptingNewLQ: out std_logic;
		prevSendingToSQ: in std_logic;
		prevSendingToLQ: in std_logic;
		dataNewToSQ: in StageDataMulti;
		dataNewToLQ: in StageDataMulti;			

		outputC: out InstructionSlot;
		outputE: out InstructionSlot;
		outputOpPreC: out InstructionState;
		outputM2C: out InstructionState;

		whichAcceptedCQ: in std_logic_vector(0 to 3);

		memLoadReady: in std_logic;
		memLoadValue: in Mword;
		memLoadAddress: out Mword;
		memLoadAllow: out std_logic;

		sysLoadAllow: out std_logic;
		sysLoadVal: in Mword;
		
		committing: in std_logic;
		--groupCtrNext: in InsTag;
		groupCtrInc: in InsTag;
	
		--sbAcceptingIn: in std_logic;
		dataOutSQ: out StageDataMulti;

			sbSending: in std_logic;
			blockDLQ: in std_logic;

		lateEventSignal: in std_logic;	
		execOrIntEventSignalIn: in std_logic;
		execCausing: in InstructionState;
		
			cacheFillInput: in InstructionSlot;
		
		sendingFromDLQOut: out std_logic;
		dlqAcceptingOut: out std_logic;
		dlqAlmostFullOut: out std_logic;
		
			sqCommittedOutput: out InstructionSlot;
			sqCommittedEmpty: out std_logic
	);
end UnitMemory;


architecture Behavioral of UnitMemory is
	signal eventSignal: std_logic := '0';	
	
	signal addressUnitSendingSig: std_logic := '0';
	
	signal dataOutSQV: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

	signal dataToMemPipe: InstructionState := DEFAULT_INSTRUCTION_STATE;
	signal sendingToMemPipe: std_logic := '0';
	signal acceptingMem1: std_logic := '0';
		
	signal dlqAccepting, dlqAlmostFull, sendingToDLQ, sendingFromDLQ: std_logic := '0';
	signal dataToDLQ: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	
	signal lsResultData, execResultData, dataFromDLQ: InstructionState := DEFAULT_INSTRUCTION_STATE;
	signal stageDataMultiDLQ: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	
	signal execAcceptingCSig, execAcceptingESig: std_logic := '0';		
	signal acceptingLS, sendingFromSysReg: std_logic := '0';	
	signal addressingData: InstructionState := DEFAULT_INSTRUCTION_STATE;

	signal lqSelectedDataWithErr: InstructionState := DEFAULT_INSTRUCTION_STATE;
	
	signal sendingMem0, sendingMem1, sendingAGU: std_logic := '0';
	
	signal sendingAddressToSQSig, storeAddressWrSig, storeValueWrSig, sendingAddressing,
			 sendingAddressingForLoad, sendingAddressingForMfc,
			 sendingAddressingForStore, sendingAddressingForMtc: std_logic := '0';
	signal storeAddressDataSig, storeValueDataSig: InstructionState := DEFAULT_INSTRUCTION_STATE;
	signal sqSelectedOutput, lqSelectedOutput, lmqSelectedOutput: InstructionSlot := DEFAULT_INSTRUCTION_SLOT;
	
	signal stageDataToMem1a, dataAfterMemA, stageDataOutMem0a, inputDataLoadUnitA, inputDataC2,
				stageDataOutAGU2: InstructionSlotArray(0 to 0) := (others => DEFAULT_INSTRUCTION_SLOT);
				
		signal sendingFromDLQDelay: std_logic := '0';
		signal dataFromDLQDelay: InstructionState := DEFAULT_INSTRUCTION_STATE;
		
		constant USE_PRECISE_LS_TRAP: boolean := false;
begin
	eventSignal <= execOrIntEventSignalIn;	

	inputDataC2(0) <= (inputC.full or sendingFromDLQ,
								calcEffectiveAddress(inputC.ins, inputC.state, sendingFromDLQ, dataFromDLQ));

	STAGE_AGU: entity work.GenericStageMulti(Behavioral)
	generic map(
		COMPARE_TAG => '1'
	)
	port map(
		clk => clk, reset => reset, en => en,

		prevSending => inputC.full or sendingFromDLQ,
		nextAccepting => acceptingLS,
		
		stageDataIn2 => inputDataC2,
		acceptingOut => execAcceptingCSig,
		sendingOut => sendingAGU,
		stageDataOut2 => stageDataOutAGU2,
		
		execEventSignal => eventSignal,
		lateEventSignal => lateEventSignal,
		execCausing => execCausing
	);

	SUBPIPE_E: block begin end block; -- Block empty

	outputE <= (inputE.full, inputE.ins);

	dataToMemPipe <= stageDataOutAGU2(0).ins;
	sendingToMemPipe <= sendingAGU;

	-- CAREFUL, At this point probably "completed" bits must be cleared, because they will be set (or not)
	--						based on the success or failure of translation and cache access
	inputDataLoadUnitA(0) <= (sendingToMemPipe, setDataCompleted(setAddressCompleted(dataToMemPipe, '0'), '0'));

	STAGE_MEM0: entity work.GenericStageMulti(Behavioral)
	generic map(
		COMPARE_TAG => '1'
	)
	port map(
		clk => clk, reset => reset, en => en,
		
		prevSending => sendingAGU,
		nextAccepting => acceptingMem1, -- Also needs free slot in LMQ in case of miss!
		stageDataIn2 => inputDataLoadUnitA,
		acceptingOut => acceptingLS,
		sendingOut => sendingMem0,
		stageDataOut2 => stageDataOutMem0a,
		
		execEventSignal => eventSignal,
		lateEventSignal => lateEventSignal,					
		execCausing => execCausing		
	);

	sendingAddressing <= sendingMem0; -- After translation
	addressingData	<= stageDataOutMem0a(0).ins;
	
	-- TEMP: setting address always completed (simulating TLB always hitting)
	stageDataToMem1a(0) <= (sendingMem0, setAddressCompleted(stageDataOutMem0a(0).ins, '1'));
	
	STAGE_MEM1: entity work.GenericStageMulti(Behavioral)
	generic map(
		COMPARE_TAG => '1'
	)
	port map(
		clk => clk, reset => reset, en => en,
		
		prevSending => sendingMem0,
		nextAccepting => whichAcceptedCQ(2),
		
		stageDataIn2 => stageDataToMem1a,
		acceptingOut => acceptingMem1,
		sendingOut => sendingMem1,
		stageDataOut2 => dataAfterMemA,
		
		execEventSignal => eventSignal,
		lateEventSignal => lateEventSignal,
		execCausing => execCausing				
	);

	-- CAREFUL: when miss (incl. forwarding miss), no 'completed' signal.
	addressUnitSendingSig <= (sendingMem1 and not sendingToDLQ)
								 or (bool2std(USE_PRECISE_LS_TRAP) and lqSelectedOutput.full);
																									--??? -- because load exc to ROB
	outputC <= (addressUnitSendingSig, clearTempControlInfoSimple(execResultData));
	outputOpPreC <= stageDataOutMem0a(0).ins;-- DEFAULT_INS_STATE; -- CAREFUL: Don't show this because not supported
	outputM2C <= stageDataOutAGU2(0).ins;

		lsResultData <= getLSResultData(dataAfterMemA(0).ins, memLoadReady, memLoadValue,
										sendingFromSysReg, sysLoadVal, sqSelectedOutput.full, sqSelectedOutput.ins);

		PRECISE_LS_TRAP: if USE_PRECISE_LS_TRAP generate
			execResultData <= lqSelectedDataWithErr when lqSelectedOutput.full = '1' else lsResultData;
			lqSelectedDataWithErr <= setLoadException(lqSelectedOutput.ins, '1');
		end generate;
			
		IMPRECISE_LS_TRAP: if not USE_PRECISE_LS_TRAP generate
			execResultData <= setLoadException(lsResultData, lqSelectedOutput.full);
		end generate;
	
		-- Sending to Delayed Load Queue: when load/store miss or selected from LQ (going to ROB)
		sendingToDLQ <= getSendingToDLQ(sendingMem1, bool2std(USE_PRECISE_LS_TRAP) and lqSelectedOutput.full,
										lsResultData); 
		dataToDLQ <= makeSDM((0 => (sendingToDLQ, lsResultData)));

------------------------------------------------------------------------------------------------
		sendingAddressingForLoad <= sendingAddressing and isLoad(addressingData);		
		sendingAddressingForMfc <= sendingAddressing and isSysRegRead(addressingData);		
		sendingAddressingForStore <= sendingAddressing and isStore(addressingData);
		sendingAddressingForMtc <= sendingAddressing and isSysRegWrite(addressingData);
			
		sendingAddressToSQSig <= sendingAddressingForStore or sendingAddressingForMtc;

		-- SQ inputs
		storeAddressWrSig <= sendingAddressToSQSig;
		storeValueWrSig <= inputE.full;

		-- SQ inputs
		storeAddressDataSig <= addressingData; -- Mem unit interface
		storeValueDataSig <= setInsResult(inputE.ins, inputE.state.argValues.arg0); -- Mem unit interface		

			STORE_QUEUE: entity work.MemoryUnit(Behavioral)
			generic map(
				QUEUE_SIZE => SQ_SIZE,
				MODE => store
			)
			port map(
				clk => clk, reset => reset, en => en,
				
				acceptingOut => acceptingNewSQ,
					acceptingBr => open,
				prevSending => prevSendingToSQ,
					prevSendingBr => '0',
				dataIn => dataNewToSQ,
					dataInBr => DEFAULT_STAGE_DATA_MULTI,				

				storeAddressInput => (storeAddressWrSig, storeAddressDataSig),
				storeValueInput => (storeValueWrSig, storeValueDataSig),
				compareAddressInput => (sendingAddressingForLoad or sendingAddressingForMfc, DEFAULT_INS_STATE),
					
				selectedDataOutput => sqSelectedOutput,

				committing => committing,
				groupCtrInc => groupCtrInc,
						
				lateEventSignal => lateEventSignal,	
				execEventSignal => eventSignal,
				execCausing => execCausing,
				
				nextAccepting => sbSending,--'1',
				
				sendingSQOut => open,
					dataOutV => dataOutSQV,
					
					committedOutput => sqCommittedOutput,
					committedEmpty => sqCommittedEmpty
			);

			MEM_LOAD_QUEUE: entity work.MemoryUnit(Behavioral)
			generic map(
				QUEUE_SIZE => LQ_SIZE,
				MODE => load
			)											
			port map(
				clk => clk, reset => reset, en => en,
				
				acceptingOut => acceptingNewLQ,
					acceptingBr => open,
				prevSending => prevSendingToLQ,
					prevSendingBr => '0',
				dataIn => dataNewToLQ,
					dataInBr => DEFAULT_STAGE_DATA_MULTI,				

				storeAddressInput => (sendingAddressingForLoad or sendingAddressingForMfc, addressingData),
				storeValueInput => (sendingAddressingForLoad or sendingAddressingForMfc, DEFAULT_INS_STATE),
				compareAddressInput => (storeAddressWrSig, DEFAULT_INS_STATE),
					
				selectedDataOutput => lqSelectedOutput,
			
					committing => committing,
					groupCtrInc => groupCtrInc,

					lateEventSignal => lateEventSignal,
				execEventSignal => eventSignal,
				execCausing => execCausing,

				nextAccepting => '1',

				sendingSQOut => open,
					dataOutV => open,
					
					committedOutput => open,
					committedEmpty => open
			);

			DELAYED_LOAD_QUEUE: entity work.MemoryUnit(LoadMissQueue)
			generic map(
				QUEUE_SIZE => LMQ_SIZE,
				CLEAR_COMPLETED => false
			)
			port map(
				clk => clk, reset => reset, en => en,
				
				acceptingOut => dlqAccepting,
					acceptingBr => open,
				prevSending => sendingToDLQ,
					prevSendingBr => '0',
				dataIn => dataToDLQ,
					dataInBr => DEFAULT_STAGE_DATA_MULTI,				
				
					storeAddressInput => ('0', DEFAULT_INSTRUCTION_STATE),
					storeValueInput => cacheFillInput,
					compareAddressInput => ('0', DEFAULT_INSTRUCTION_STATE),
					
					selectedDataOutput => open,
		
					committing => committing,
					groupCtrInc => (others => '0'),
					
					lateEventSignal => lateEventSignal,
				execEventSignal => eventSignal,
				execCausing => execCausing,
				
				nextAccepting => not blockDLQ,			
				sendingSQOut => sendingFromDLQ,
					dataOutV => stageDataMultiDLQ,
					
					almostFull => dlqAlmostFull,
					
					committedOutput => open,
					committedEmpty => open
			);
			
			dataFromDLQ <= stageDataMultiDLQ.data(0);

			TMP_REG: process(clk) -- TODO: move the delayed signal to sys reg block
			begin
				if rising_edge(clk) then
					sendingFromSysReg <= sendingAddressingForMfc;
					
					sendingFromDLQDelay <= sendingFromDLQ;
					dataFromDLQDelay <= dataFromDLQ;
				end if;
			end process;

			--execAcceptingC <= execAcceptingCSig;
			--execAcceptingE <= '1';
			
			-- Mem interface
			memLoadAddress <= addressingData.target;
			memLoadAllow <= sendingAddressingForLoad;
			sysLoadAllow <= sendingAddressingForMfc;	 
				 
			dataOutSQ <= dataOutSQV;
			
			dlqAcceptingOut <= dlqAccepting;
			dlqAlmostFullOut <= dlqAlmostFull;
			
			sendingFromDLQOut <= sendingFromDLQ;			
end Behavioral;
