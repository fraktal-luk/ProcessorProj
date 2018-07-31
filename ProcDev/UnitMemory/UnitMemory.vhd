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
		--groupCtrNext: in InsTag;
		groupCtrInc: in InsTag;
	
		--sbAcceptingIn: in std_logic;
		dataOutSQ: out StageDataMulti;

			sbSending: in std_logic;

		lateEventSignal: in std_logic;	
		execOrIntEventSignalIn: in std_logic;
		execCausing: in InstructionState;
		
			cacheFillInput: in InstructionSlot;
		
			sqCommittedOutput: out InstructionSlot;
			sqCommittedEmpty: out std_logic
	);
end UnitMemory;


architecture Behavioral of UnitMemory is
	signal eventSignal: std_logic := '0';	
	
	signal addressUnitSendingSig: std_logic := '0';
	
	signal dataOutSQV: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

	signal stageDataOutAGU, dataAfterMem: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

	signal inputDataLoadUnit: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	signal dataToMemPipe: InstructionState := DEFAULT_INSTRUCTION_STATE;
	signal sendingToMemPipe: std_logic := '0';
	signal stageDataOutMem0, stageDataToMem1: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;			
	signal acceptingMem1: std_logic := '0';
		
	signal dlqAccepting, sendingToDLQ, sendingFromDLQ: std_logic := '0';
	signal dataToDLQ: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	
	signal lsResultData, execResultData, dataFromDLQ: InstructionState := DEFAULT_INSTRUCTION_STATE;
	signal stageDataMultiDLQ: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
					
	signal sendingAfterRead: std_logic := '0';
	signal dataAfterRead: InstructionState := DEFAULT_INSTRUCTION_STATE;
	
	signal execAcceptingCSig, execAcceptingESig: std_logic := '0';	
	signal inputDataC: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	
	signal acceptingLS, sendingFromSysReg: std_logic := '0';	
	signal addressingData: InstructionState := DEFAULT_INSTRUCTION_STATE;

	signal lqSelectedDataWithErr: InstructionState := DEFAULT_INSTRUCTION_STATE;
	
	signal sendingAddressToSQSig, storeAddressWrSig, storeValueWrSig, sendingAddressing,
			 sendingAddressingForLoad, sendingAddressingForMfc,
			 sendingAddressingForStore, sendingAddressingForMtc: std_logic := '0';
	signal storeAddressDataSig, storeValueDataSig: InstructionState := DEFAULT_INSTRUCTION_STATE;
	signal sqSelectedOutput, lqSelectedOutput, lmqSelectedOutput: InstructionSlot := DEFAULT_INSTRUCTION_SLOT;
begin
	eventSignal <= execOrIntEventSignalIn;	

	inputDataC <= makeSDM((0 => (inputC.full, calcEffectiveAddress(inputC.ins, inputC.state))));

	STAGE_AGU: entity work.GenericStageMulti(Behavioral)
	generic map(
		COMPARE_TAG => '1'
	)
	port map(
		clk => clk, reset => reset, en => en,
		
		prevSending => inputC.full,
		nextAccepting => acceptingLS and not sendingFromDLQ,
		
		stageDataIn => inputDataC, 
		acceptingOut => execAcceptingCSig,
		sendingOut => open,--sendingAGU,
		stageDataOut => stageDataOutAGU,
		
		execEventSignal => eventSignal,
		lateEventSignal => lateEventSignal,
		execCausing => execCausing,
		lockCommand => '0'
		
		--stageEventsOut => open
	);

	SUBPIPE_E: block begin end block; -- Block empty

	outputE <= (inputE.full, inputE.ins);

	dataToMemPipe <= dataFromDLQ when sendingFromDLQ = '1' else stageDataOutAGU.data(0);
	sendingToMemPipe <= stageDataOutAGU.fullMask(0) or sendingFromDLQ;
	-- CAREFUL, At this point probably "completed" bits must be cleared, because they will be set (or not)
	--						based on the success or failure of translation and cache access

	inputDataLoadUnit <= makeSDM((0 => (sendingToMemPipe, 
														setDataCompleted(setAddressCompleted(dataToMemPipe, '0'), '0')
													))
											);

	STAGE_MEM0: entity work.GenericStageMulti(Behavioral)
	generic map(
		COMPARE_TAG => '1'
	)
	port map(
		clk => clk, reset => reset, en => en,
		
		prevSending => stageDataOutAGU.fullMask(0) or sendingFromDLQ,
		nextAccepting => acceptingMem1 and dlqAccepting, -- needs free slot in LMQ in case of miss!
		stageDataIn => inputDataLoadUnit,
		acceptingOut => acceptingLS,
		sendingOut => open,--sendingMem0,
		stageDataOut => stageDataOutMem0,
		
		execEventSignal => eventSignal,
		lateEventSignal => lateEventSignal,					
		execCausing => execCausing,
		lockCommand => '0'
		
		--stageEventsOut => open					
	);

	-- CAREFUL, TODO: after mem0 set "addressCompleted" according to success or failure of translation?

	sendingAddressing <= stageDataOutMem0.fullMask(0); -- After translation
	addressingData	<= stageDataOutMem0.data(0);
	
	-- TEMP: setting address always completed (simulating TLB always hitting)
	stageDataToMem1 <= makeSDM( (0 =>  (stageDataOutMem0.fullMask(0), setAddressCompleted(stageDataOutMem0.data(0), '1'))) );
	
	STAGE_MEM1: entity work.GenericStageMulti(Behavioral)
	generic map(
		COMPARE_TAG => '1'
	)
	port map(
		clk => clk, reset => reset, en => en,
		
		prevSending => '0',--sendingMem0,
		nextAccepting => whichAcceptedCQ(2),
		
		stageDataIn => stageDataToMem1,--dataM, 
		acceptingOut => acceptingMem1,
		sendingOut => open,--sendingMem1,
		stageDataOut => dataAfterMem,
		
		execEventSignal => eventSignal,
		lateEventSignal => lateEventSignal,
		execCausing => execCausing,
		lockCommand => '0'
		
		--stageEventsOut => open					
	);

	-- CAREFUL: when miss (incl. forwarding miss), no 'completed' signal.
	addressUnitSendingSig <= (dataAfterMem.fullMask(0) and not sendingToDLQ) or lqSelectedOutput.full;
																									--??? -- because load exc to ROB
	outputC <= (addressUnitSendingSig, clearTempControlInfoSimple(execResultData));
	outputOpPreC <= DEFAULT_INS_STATE; -- CAREFUL: Don't show this because not supported

		-- CAREFUL, TODO: if mem subpipe can be locked, then memLoadReady will expire while the
		--						corresponding load is stalled, and it will go to LMQ. In such case
		--						it has to be clear that the load has status "ready for reexec" because
		--						the cache location won't be refiled as it is already full!
		--						So there would be a need to distinguish "missed" from "not received"
		--						as the latter would go to LMQ as "ready" from the start.
		--						OFC it is simpler never to stall the mem subpipe.
		lsResultData <= getLSResultData(dataAfterMem.data(0), memLoadReady, memLoadValue,
										sendingFromSysReg, sysLoadVal, sqSelectedOutput.full, sqSelectedOutput.ins);
		execResultData <= lqSelectedDataWithErr when lqSelectedOutput.full = '1' else lsResultData;
	
		lqSelectedDataWithErr <= setLoadException(lqSelectedOutput.ins);
	
		-- Sending to Delayed Load Queue: when load/store miss or selected from LQ (going to ROB)
		sendingToDLQ <= getSendingToDLQ(dataAfterMem.fullMask(0), lqSelectedOutput.full, lsResultData); 
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
		storeValueDataSig <= setInsResult(inputE.ins, inputE.ins.argValues.arg2); -- Mem unit interface		

			STORE_QUEUE: entity work.MemoryUnit(Behavioral)
			generic map(
				QUEUE_SIZE => SQ_SIZE,
				MODE => store
			)
			port map(
				clk => clk, reset => reset, en => en,
				
				acceptingOut => acceptingNewSQ,
				prevSending => prevSendingToSQ,
				dataIn => dataNewToSQ,

				storeAddressInput => (storeAddressWrSig, storeAddressDataSig),
				storeValueInput => (storeValueWrSig, storeValueDataSig),
				compareAddressInput => (sendingAddressingForLoad or sendingAddressingForMfc, addressingData),
					
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
				prevSending => prevSendingToLQ,
				dataIn => dataNewToLQ,

				storeAddressInput => (sendingAddressingForLoad or sendingAddressingForMfc, addressingData),
				storeValueInput => (sendingAddressingForLoad or sendingAddressingForMfc, DEFAULT_INS_STATE),
				compareAddressInput => (storeAddressWrSig, storeAddressDataSig),
					
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
				prevSending => sendingToDLQ,
				dataIn => dataToDLQ,
				
					storeAddressInput => ('0', DEFAULT_INSTRUCTION_STATE),
					storeValueInput => cacheFillInput,--('0', DEFAULT_INSTRUCTION_STATE),
					compareAddressInput => ('0', DEFAULT_INSTRUCTION_STATE),
					
					selectedDataOutput => lmqSelectedOutput,
		
					committing => committing,
					groupCtrInc => (others => '0'),
					
					lateEventSignal => lateEventSignal,
				execEventSignal => eventSignal,
				execCausing => execCausing,
				
				nextAccepting => acceptingLS, -- TODO: when should it be allowed to send? Priorities!				
				sendingSQOut => sendingFromDLQ,
					dataOutV => stageDataMultiDLQ,
					
					committedOutput => open,
					committedEmpty => open
			);
			
			dataFromDLQ <= stageDataMultiDLQ.data(0);

			TMP_REG: process(clk) -- TODO: move the delayed signal to sys reg block
			begin
				if rising_edge(clk) then
					sendingFromSysReg <= sendingAddressingForMfc;
				end if;
			end process;

			execAcceptingC <= execAcceptingCSig;
			execAcceptingE <= '1';
			
			-- Mem interface
			memLoadAddress <= addressingData.target;
			memLoadAllow <= sendingAddressingForLoad;
			sysLoadAllow <= sendingAddressingForMfc;	 
				 
			dataOutSQ <= dataOutSQV;
end Behavioral;
