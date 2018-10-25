----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:01:07 09/07/2017 
-- Design Name: 
-- Module Name:    OutOfOrderBox - Behavioral 
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

use work.TEMP_DEV.all;
use work.GeneralPipeDev.all;

use work.ProcComponents.all;

use work.Viewing.all;


entity OutOfOrderBox is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           en : in  STD_LOGIC;
			  		  
			  bpAccepting: out std_logic;
			  bpSending: in std_logic;
			  bpData: in StageDataMulti;
					  
			  renamedDataLiving: in StageDataMulti;	-- INPUT			
			  renamedSending: in std_logic;
			  
			  iqAccepts: out std_logic; -- OUTPUT

	-- Sys reg interface	
			  sysRegReadSel: out slv5; -- OUTPUT  -- Doesn't need to be a port of OOO part
			  sysRegReadValue: in Mword; -- INPUT

	-- Mem interface
	        memLoadAddressOut: out Mword;
			  memLoadValue: in Mword;
			  memLoadAllow: out std_logic;
			  memLoadReady: in std_logic;

	-- evt
			  execEventSignalOut: out std_logic; -- OUTPUT/SIG
			  lateEventSignal: in std_logic;
			  execCausingOut: out InstructionState;

	-- Hidden to some degree, but may be useful for sth
			  commitGroupCtrSig: in InsTag;
		     commitGroupCtrIncSig: in InsTag;	-- INPUT
												
	-- ROB interface	
			  robSendingOut: out std_logic;		-- OUTPUT
			  dataOutROB: out StageDataMulti;		-- OUTPUT

			  commitAccepting: in std_logic; -- INPUT
			  sbSending: in std_logic;

			  cacheFillInput: in InstructionSlot;

			  dataOutBQV: out StageDataMulti; -- OUTPUT
			  dataOutSQ: out StageDataMulti; -- OUTPUT			  
			
			  readyRegFlags: in std_logic_vector(0 to 3*PIPE_WIDTH-1);		
	
			  cqOutput: out InstructionSlotArray(0 to 0);
				
			  sqCommittedOutput: out InstructionSlot;
			  sqCommittedEmpty: out std_logic
			  );
end OutOfOrderBox;


architecture Behavioral of OutOfOrderBox is
	signal resetSig, enSig: std_logic := '0';

	signal execEventSignal: std_logic := '0';
	signal execCausing: InstructionState := defaultInstructionState; -- OUTPUT/SIG

	signal robSending: std_logic := '0';
	signal memLoadAddress: Mword := (others => '0');

	--signal execAcceptingA, execAcceptingB, execAcceptingC, execAcceptingD, execAcceptingE: std_logic := '0';
	signal compactedToSQ, compactedToLQ, compactedToBQ: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

	signal acceptingNewSQ, acceptingNewLQ, acceptingNewBQ: std_logic := '0';
	signal robAccepting: std_logic := '0';	

	-- Physical register interface
	signal regsSelA, regsSelB, regsSelC, regsSelD, regsSelE, regsSelCE: PhysNameArray(0 to 2)
					:= (others => (others => '0'));
	signal regValsA, regValsB, regValsC, regValsD, regValsE, regValsCE: MwordArray(0 to 2)
					:= (others => (others => '0'));	
	signal fni: ForwardingInfo := DEFAULT_FORWARDING_INFO;
	signal fniNew: ForwardingInfoNew := DEFAULT_FORWARDING_INFO_NEW;

	signal outputA, outputB, outputC, outputD, outputE: InstructionSlot := DEFAULT_INSTRUCTION_SLOT;
	signal outputOpPreB, outputOpPreC, outputM2B, outputM2C: InstructionState := DEFAULT_INSTRUCTION_STATE;

	-- back end interfaces
	--signal whichAcceptedCQ: std_logic_vector(0 to 3) := (others=>'0');	
	--signal anySendingFromCQ: std_logic := '0';

	signal cqOutputSig: InstructionSlotArray(0 to 0) := (others => DEFAULT_INS_SLOT);
	signal cqBufferOutputSig: InstructionSlotArray(0 to CQ_SIZE-1) := (others => DEFAULT_INSTRUCTION_SLOT);
		
	signal execOutputs1, execOutputs2, execOutputsPre: InstructionSlotArray(0 to 3) := (others => DEFAULT_INS_SLOT);
	signal execOutputsDelayed: InstructionSlotArray(0 to 2) := (others => DEFAULT_INS_SLOT);

	signal iqAcceptingVecArr: SLVA(0 to 4) := (others => (others => '0'));	
	signal iqAcceptingArr: std_logic_vector(0 to 4) := (others => '0');
	signal iqSending, issueAcceptingArr, execAcceptingArr, iqReadyArr: std_logic_vector(0 to 4) := (others => '0');
	signal queueDataArr, schedDataArr: InstructionStateArray(0 to 4) := (others => DEFAULT_INS_STATE);
	signal iqOutputArr, schedOutputArr: SchedulerEntrySlotArray(0 to 4) := (others => DEFAULT_SCH_ENTRY_SLOT);
	signal dataToQueuesArr: StageDataMultiArray(0 to 4) := (others => DEFAULT_STAGE_DATA_MULTI);
	signal regValsArr: MwordArray(0 to 3*5-1) := (others => (others => '0'));
	
	signal cqDataLivingOut2, stageDataAfterCQ2: InstructionSlotArray(0 to 0) := (others => DEFAULT_INSTRUCTION_SLOT);
	signal sendingFromDLQ: std_logic := '0';
	
	signal blockA, blockBC, blockC: std_logic := '0';
	signal dlqAccepting, dlqAlmostFull: std_logic := '0';
	
	type SchArray2D is array (integer range <>) of SchedulerEntrySlotArray(0 to PIPE_WIDTH-1);
	signal schArrays: SchArray2D(0 to 4) := (others => (others => DEFAULT_SCH_ENTRY_SLOT));
	
	signal theIssueView: IssueView := DEFAULT_ISSUE_VIEW;
begin		
	resetSig <= reset;
	enSig <= en;

	theIssueView <= getIssueView(iqOutputArr, schedOutputArr, iqAcceptingVecArr, issueAcceptingArr, execAcceptingArr);

	ISSUE_ROUTING: entity work.SubunitIssueRouting(Behavioral)
	port map(
		renamedDataLiving => renamedDataLiving,
		
		readyRegFlags => readyRegFlags,
		fni => fni,
		
		acceptingVecA => iqAcceptingVecArr(0),
		acceptingVecB => iqAcceptingVecArr(1),
		acceptingVecC => iqAcceptingVecArr(2),
		--acceptingVecD => (others => '1'),--iqAcceptingVecArr(3),
		acceptingVecE => iqAcceptingVecArr(4),
		
		acceptingA => iqAcceptingArr(0),
		acceptingB => iqAcceptingArr(1),
		acceptingC => iqAcceptingArr(2),
		acceptingE => iqAcceptingArr(4),
		
		acceptingROB => robAccepting,
		acceptingSQ => acceptingNewSQ,
		acceptingLQ => acceptingNewLQ,
		acceptingBQ => acceptingNewBQ,

		renamedSendingIn => renamedSending,
		
		renamedSendingOut => open, -- DEPREC??
		iqAccepts => iqAccepts,		
		
		--dataOutA => dataToQueuesArr(0),--dataToA,
		--dataOutB => dataToQueuesArr(1),--dataToB,
		--dataOutC => dataToQueuesArr(2),--dataToC,
		--dataOutD => --dataToQueuesArr(3),--dataToD,
		--dataOutE => dataToQueuesArr(4),--dataToE,
		
			arrOutA => schArrays(0),
			arrOutB => schArrays(1),
			arrOutC => schArrays(2),
			arrOutE => schArrays(4),

		dataOutSQ => compactedToSQ,
		dataOutLQ => compactedToLQ,
		dataOutBQ => compactedToBQ
	);

	ISSUE_QUEUES: for letter in 'A' to 'E' generate
		constant i: integer := character'pos(letter) - character'pos('A');
	begin
	
		IQUEUE: entity work.SubunitIQBuffer(Implem)--UnitIQ
		generic map(
			IQ_SIZE => IQ_SIZES(i)
		)
		port map(
			clk => clk, reset => resetSig, en => enSig,

			acceptingVec => open,--iqAcceptingVecArr(i),
			acceptingOut => iqAcceptingArr(i),
			prevSendingOK => renamedSending,
			--newData => dataToQueuesArr(i),
				newArr => schArrays(i),
			fni => fni,
			readyRegFlags => readyRegFlags,
			nextAccepting => issueAcceptingArr(i),
			execCausing => execCausing,
			lateEventSignal => lateEventSignal,
			execEventSignal => execEventSignal,
			anyReady => iqReadyArr(i),
			schedulerOut => iqOutputArr(i),
			sending => iqSending(i)
		);
	end generate;

	EXEC_AREA: block
		constant USE_IMM_VEC: std_logic_vector(0 to 4) := "10110";
	begin
		regsSelA <= getPhysicalSources(iqOutputArr(0).ins);
		regsSelB <= getPhysicalSources(iqOutputArr(1).ins);
		regsSelC <= getPhysicalSources(iqOutputArr(2).ins);
		--regsSelD <= getPhysicalSources(iqOutputArr(3).ins);
		regsSelE <= getPhysicalSources(iqOutputArr(4).ins);

		regValsArr <= regValsA & regValsB & regValsC & regValsD & regValsE;
		execAcceptingArr <= --(execAcceptingA, execAcceptingB, execAcceptingC,	execAcceptingD, execAcceptingE);
									(others => '1');--

		ISSUE_STAGES: for letter in 'A' to 'E' generate
			constant i: integer := character'pos(letter) - character'pos('A');
			constant usesImm: boolean := (USE_IMM_VEC(i) = '1');
		begin
			SCHED_STAGE: entity work.SubunitDispatch(Alternative)
			generic map(
				USE_IMM => usesImm
			)
			port map(
				clk => clk, reset => resetSig, en => enSig,
				prevSending => iqSending(i),
				input => iqOutputArr(i),
				nextAccepting => execAcceptingArr(i),--
				execEventSignal => execEventSignal,
				lateEventSignal => lateEventSignal,
				execCausing => execCausing,
				resultTags => fni.resultTags,
				resultVals => fni.resultValues,
				regValues => regValsArr(3*i to 3*i + 2),--
				acceptingOut => open,--issueAcceptingArr(i),
				output => schedOutputArr(i)
			);			
		end generate;
		
		issueAcceptingArr <= (not blockA, not blockBC, not blockC, '0', '1');
		
		ISSUE_COUNTERS: block
			signal issueA, issueB, issueC: std_logic := '0';
			signal schedB, schedC, e0B, e0C, e1B, e1C, wasBlockedA, dlqFilling: std_logic := '0';
		begin
			issueA <= iqSending(0);
			issueB <= iqSending(1);
			issueC <= iqSending(2);
			
			process(clk)
			begin
				if rising_edge(clk) then
					schedB <= issueB;
					schedC <= issueC;
				
					e0B <= schedB;
					e0C <= schedC;
					e1B <= e0B;
					e1C <= e0C;
					
					  dlqFilling <= issueC and schedC and e0C;
					
					wasBlockedA <= blockA and iqReadyArr(0);
				end if;
			end process;
			
			-- 
			blockA <= e0B or e1C;
			-- e0B and e0C;
			blockBC <= (schedB and schedC) or wasBlockedA;
			blockC <= blockBC or sendingFromDLQ or not dlqAccepting 
															--or (dlqAlmostFull and (schedC and e0C and e1C));
															or (dlqAlmostFull and dlqFilling);
		end block;

		EXEC_BLOCK: entity work.UnitExec(Implem)
		port map(
			clk => clk, reset => resetSig, en => enSig,

			inputA => schedOutputArr(0),
			inputB => schedOutputArr(1),
			inputD => DEFAULT_SCH_ENTRY_SLOT,--schedOutputArr(3),
			
			outputA => outputA,
			outputB => outputB,
			outputD => outputD,
				
			outputOpPreB => outputOpPreB,
			outputM2B => outputM2B,

			whichAcceptedCQ => (others => '1'),--whichAcceptedCQ,
			
			bpAccepting => bpAccepting,
			bpSending => bpSending,
			bpData => bpData,
			
			acceptingNewBQ => acceptingNewBQ,
			dataOutBQV => dataOutBQV,
			prevSendingToBQ => renamedSending,
			dataNewToBQ => compactedToBQ,
				
			committing => robSending,					
			groupCtrInc => commitGroupCtrIncSig,

			execEvent => execEventSignal,
			execCausingOut => execCausing,
					
			lateEventSignal => lateEventSignal,
			execOrIntEventSignalIn => execEventSignal
		);	

		NEW_MEM_UNIT: entity work.UnitMemory(Behavioral)
		port map(
			clk => clk, reset => reset, en => en,

			inputC => schedOutputArr(2),
			inputE => schedOutputArr(4),

			acceptingNewSQ => acceptingNewSQ,
			acceptingNewLQ => acceptingNewLQ,
			prevSendingToSQ => renamedSending,
			prevSendingToLQ => renamedSending,
			dataNewToSQ => compactedToSQ,
			dataNewToLQ => compactedToLQ,

			outputC => outputC,
			outputE => outputE,
				
			outputOpPreC => outputOpPreC,
			outputM2C => outputM2C,

			whichAcceptedCQ => (others => '1'),--whichAcceptedCQ,
			
			memLoadAddress => memLoadAddress,
			memLoadAllow => memLoadAllow,
			memLoadReady => memLoadReady,
			memLoadValue => memLoadValue,

			sysLoadAllow => open,
			sysLoadVal => sysRegReadValue,

			committing => robSending,
			groupCtrInc => commitGroupCtrIncSig,
				
			dataOutSQ => dataOutSQ,

			sbSending => sbSending,
			blockDLQ => blockBC,
									
			lateEventSignal => lateEventSignal,	
			execOrIntEventSignalIn => execEventSignal,
			execCausing => execCausing,
			
			cacheFillInput => cacheFillInput,
			
			sendingFromDLQOut => sendingFromDLQ,
			
			dlqAcceptingOut => dlqAccepting,
			dlqAlmostFullOut => dlqAlmostFull,
			
			sqCommittedOutput => sqCommittedOutput,
			sqCommittedEmpty => sqCommittedEmpty
		);

		sysRegReadSel <= memLoadAddress(4 downto 0);

		execOutputs1 <= (0 => outputA, 1 => outputB, 2 => outputC, others => DEFAULT_INSTRUCTION_SLOT);
		execOutputs2 <= (		2 => outputE, 3 => outputD, others => DEFAULT_INSTRUCTION_SLOT); -- (-,-,E,D)!
		execOutputsPre <= (1 => ('0', outputOpPreB), 2 => --('0', outputOpPreC),	others => DEFAULT_INSTRUCTION_SLOT);
																			('0', outputOpPreC),	others => DEFAULT_INSTRUCTION_SLOT);


			RESULTS_D0: entity work.GenericStageMulti(Behavioral)
			generic map(
				WIDTH => 1
			)
			port map(
				clk => clk, reset => resetSig, en => enSig,
				
				prevSending => execOutputs1(0).full,
				nextAccepting => '1',
				execEventSignal => '0',
				lateEventSignal => '0',
				execCausing => DEFAULT_INSTRUCTION_STATE,--execCausing,
				stageDataIn2 => execOutputs1(0 to 0),
				acceptingOut => open,
				sendingOut => open,
				stageDataOut2 => execOutputsDelayed(0 to 0)		
			);

			RESULTS_D1: entity work.GenericStageMulti(Behavioral)
			generic map(
				WIDTH => 1
			)
			port map(
				clk => clk, reset => resetSig, en => enSig,
				
				prevSending => execOutputs1(1).full,
				nextAccepting => '1',
				execEventSignal => '0',
				lateEventSignal => '0',
				execCausing => DEFAULT_INSTRUCTION_STATE,--execCausing,
				stageDataIn2 => execOutputs1(1 to 1),
				acceptingOut => open,
				sendingOut => open,
				stageDataOut2 => execOutputsDelayed(1 to 1)		
			);
			
			RESULTS_D2: entity work.GenericStageMulti(Behavioral)
			generic map(
				WIDTH => 1
			)
			port map(
				clk => clk, reset => resetSig, en => enSig,
				
				prevSending => execOutputs1(2).full,
				nextAccepting => '1',
				execEventSignal => '0',
				lateEventSignal => '0',
				execCausing => DEFAULT_INSTRUCTION_STATE,--execCausing,
				stageDataIn2 => execOutputs1(2 to 2),
				acceptingOut => open,
				sendingOut => open,
				stageDataOut2 => execOutputsDelayed(2 to 2)
			);


		COMMIT_QUEUE: entity work.TestCQPart0(Implem2)
		generic map(
			INPUT_WIDTH => 3,
			QUEUE_SIZE => 2,
			OUTPUT_SIZE => 1
		)
		port map(
			clk => clk, reset => resetSig, en => enSig,
		
			execEventSignal => '0',
			execCausing => DEFAULT_INSTRUCTION_STATE,
			input => execOutputs1(0 to 2),

			whichAcceptedCQ => open,--whichAcceptedCQ,
			anySending => open,
			cqOutput => cqOutputSig,
			bufferOutput => cqBufferOutputSig
		);

		cqDataLivingOut2(0) <= (cqOutputSig(0).full, cqOutputSig(0).ins);

			-- CAREFUL! This stage is needed to keep result tags 1 for cycle when writing to reg file,
			--				so that "black hole" of invisible readiness doesn't occur
			AFTER_CQ: entity work.GenericStageMulti(Behavioral) port map(
				clk => clk, reset => resetSig, en => enSig,
				
				prevSending => cqOutputSig(0).full,
				nextAccepting => '1',
				execEventSignal => '0',
				lateEventSignal => '0',
				execCausing => DEFAULT_INSTRUCTION_STATE,--execCausing,
				stageDataIn2 => cqDataLivingOut2,
				acceptingOut => open,
				sendingOut => open,
				stageDataOut2 => stageDataAfterCQ2		
			);

		-- writtenTags indicate registers written to GPR file in last cycle, so they can be read from there
		--		rather than from forw. network, but readyRegFlags are not available in the 1st cycle after WB.
		--fni.writtenTags <= getPhysicalDests(makeSDM(stageDataAfterCQ2));
		fni.resultTags <= getResultTags(execOutputs1, cqBufferOutputSig, DEFAULT_STAGE_DATA_MULTI);
		fni.nextResultTags <= getNextResultTags(execOutputsPre, schedOutputArr);
		fni.nextTagsM2 <= ((others => '0'), outputM2B.physicalArgSpec.dest, --(others => '0'));
																									outputOpPreC.physicalArgSpec.dest);
		fni.resultValues <= getResultValues(execOutputs1, cqBufferOutputSig, DEFAULT_STAGE_DATA_MULTI);
				fni.tags0 <= fniNew.tags0;
				fni.tags1 <= fniNew.tags1;
		
		fniNew.tagsM2 <= ((others => '0'), outputM2B.physicalArgSpec.dest, outputOpPreC.physicalArgSpec.dest);
		fniNew.tagsM1 <= (schedOutputArr(0).ins.physicalArgSpec.dest, 
									execOutputsPre(1).ins.physicalArgSpec.dest, execOutputsPre(2).ins.physicalArgSpec.dest);
		fniNew.tags0 <= (execOutputs1(0).ins.physicalArgSpec.dest,
									execOutputs1(1).ins.physicalArgSpec.dest, execOutputs1(2).ins.physicalArgSpec.dest);
		fniNew.tags1 <= (execOutputsDelayed(0).ins.physicalArgSpec.dest,
									execOutputsDelayed(1).ins.physicalArgSpec.dest, execOutputsDelayed(2).ins.physicalArgSpec.dest);
		fniNew.values0 <= getResults(execOutputs1);
		fniNew.values1 <= getResults(execOutputsDelayed);

		
		-- Int register block
		regsSelCE(0 to 1) <= regsSelC(0 to 1);
		regsSelCE(2) <= regsSelE(0);
		regValsC(0 to 1) <= regValsCE(0 to 1);
		regValsE(0) <= regValsCE(2);	

		GPR_FILE_DISPATCH: entity work.RegisterFile0 (Behavioral)
		generic map(WIDTH => 4, WRITE_WIDTH => 1)
		port map(
			clk => clk, reset => resetSig, en => enSig,
				
			writeAllow => '1',
			writeInput => cqOutputSig,

			readAllowVec => (others => '1'), -- TEMP!
			
			selectRead(0 to 2) => regsSelA,
			selectRead(3 to 5) => regsSelB,
			selectRead(6 to 8) => regsSelCE,
			selectRead(9 to 11) => regsSelD,
			
			readValues(0 to 2) => regValsA,
			readValues(3 to 5) => regValsB,
			readValues(6 to 8) => regValsCE,						
			readValues(9 to 11) => regValsD			
		);
	end block;

	REORDER_BUFFER: entity work.ReorderBuffer(Implem)
	port map(
		clk => clk, reset => resetSig, en => enSig,
		
		lateEventSignal => lateEventSignal,
		execEventSignal => execEventSignal,
		execCausing => execCausing,
		
		commitGroupCtr => commitGroupCtrSig,

		execEndSigs1 => execOutputs1,
		execEndSigs2 => execOutputs2,
		
		inputData => renamedDataLiving,
		prevSending => renamedSending,
		acceptingOut => robAccepting,
		
		nextAccepting => commitAccepting,
		sendingOut => robSending, 
		outputData => dataOutROB		
	);

	execEventSignalOut <= execEventSignal;
	execCausingOut <= execCausing;

	robSendingOut <= robSending;
	memLoadAddressOut <= memLoadAddress;

	cqOutput <= cqOutputSig;
end Behavioral;
