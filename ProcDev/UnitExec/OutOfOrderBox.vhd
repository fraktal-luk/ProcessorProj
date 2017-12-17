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


entity OutOfOrderBox is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           en : in  STD_LOGIC;
			  		  
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
			commitGroupCtrSig: in SmallNumber;
			commitGroupCtrNextSig: in SmallNumber; -- INPUT
		   commitGroupCtrIncSig: in SmallNumber;	-- INPUT
												
	-- ROB interface	
			robSendingOut: out std_logic;		-- OUTPUT
			dataOutROB: out StageDataMulti;		-- OUTPUT

			sbAccepting: in std_logic;	-- INPUT
			commitAccepting: in std_logic; -- INPUT

			dataOutBQV: out StageDataMulti; -- OUTPUT
			dataOutSQ: out StageDataMulti; -- OUTPUT			  
			
				readyRegFlags: in std_logic_vector(0 to 3*PIPE_WIDTH-1);		
	
				cqOutput: out InstructionSlotArray(0 to INTEGER_WRITE_WIDTH-1)
			  );
end OutOfOrderBox;


architecture Behavioral of OutOfOrderBox is
	signal resetSig, enSig: std_logic := '0';

	signal execEventSignal: std_logic := '0';
	signal execCausing: InstructionState := defaultInstructionState; -- OUTPUT/SIG

	signal robSending: std_logic := '0';

	signal memLoadAddress: Mword := (others => '0');
	
	--signal dataToA, dataToB, dataToC, dataToD, dataToE: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;	
	-------------------
	signal acceptingVecA, acceptingVecB, acceptingVecC, acceptingVecD, acceptingVecE:
				std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
	signal queueSendingA, queueSendingB, queueSendingC, queueSendingD, queueSendingE: std_logic := '0';
	signal queueDataA, queueDataB, queueDataC, queueDataD, queueDataE:
					InstructionState := DEFAULT_INSTRUCTION_STATE;
	-----------------
	signal sendingSchedA, sendingSchedB, sendingSchedC, sendingSchedD, sendingSchedE,
			execAcceptingA, execAcceptingB, execAcceptingC, execAcceptingD, execAcceptingE: std_logic := '0';
	signal dataOutIQA, dataOutIQB, dataOutIQC, dataOutIQD, dataOutIQE: InstructionState
																	:= DEFAULT_INSTRUCTION_STATE;
	---------------

	
	
	signal compactedToSQ, compactedToLQ, compactedToBQ: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

	signal acceptingNewSQ, acceptingNewLQ, acceptingNewBQ: std_logic := '0';
	signal robAccepting: std_logic := '0';	


	
	-- Physical register interface
	signal regsSelA, regsSelB, regsSelC, regsSelD, regsSelE, regsSelCE: PhysNameArray(0 to 2)
					:= (others => (others => '0'));
	signal regValsA, regValsB, regValsC, regValsD, regValsE, regValsCE: MwordArray(0 to 2)
							:= (others => (others => '0'));
		
	signal fni: ForwardingInfo := DEFAULT_FORWARDING_INFO;

	signal stageDataAfterCQ: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

	signal outputA, outputB, outputC, outputD, outputE: InstructionSlot := DEFAULT_INSTRUCTION_SLOT;
	signal outputOpPreB, outputOpPreC: InstructionState := DEFAULT_INSTRUCTION_STATE;

	signal execEnds, execEnds2: InstructionStateArray(0 to 3) := (others => DEFAULT_INSTRUCTION_STATE);
	signal execPreEnds: InstructionStateArray(0 to 3) := (others => DEFAULT_INSTRUCTION_STATE);
	signal execSending, execSending2: std_logic_vector(0 to 3) := (others => '0');

	-- back end interfaces
	signal whichAcceptedCQ: std_logic_vector(0 to 3) := (others=>'0');	
	signal anySendingFromCQ: std_logic := '0';
	signal cqDataLivingOut: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

	signal cqOutputSig: InstructionSlotArray(0 to INTEGER_WRITE_WIDTH-1)
						:= (others => DEFAULT_INSTRUCTION_SLOT);
	signal cqBufferOutputSig: InstructionSlotArray(0 to CQ_SIZE-1) := (others => DEFAULT_INSTRUCTION_SLOT);
	
	signal issueAcceptingA, issueAcceptingB, issueAcceptingC, issueAcceptingD, issueAcceptingE:
					std_logic := '0';				
	signal execOutputs1, execOutputs2, execOutputsPre: InstructionSlotArray(0 to 3)
			:= (others => DEFAULT_INSTRUCTION_SLOT);

	type SLVA is array (integer range <>) of std_logic_vector(0 to PIPE_WIDTH-1);
	signal iqAcceptingVecArr: SLVA(0 to 4) := (others => (others => '0'));
	
	signal issueAcceptingArr, queueSendingArr, sendingSchedArr, execAcceptingArr:
				std_logic_vector(0 to 4) := (others => '0');
	signal queueDataArr, schedDataArr: InstructionStateArray(0 to 4)
					:= (others => DEFAULT_INSTRUCTION_STATE);
	signal iqOutputArr, schedOutputArr: InstructionSlotArray(0 to 4) := (others => DEFAULT_INSTRUCTION_SLOT);
	signal dataToQueuesArr: StageDataMultiArray(0 to 4) := (others => DEFAULT_STAGE_DATA_MULTI);
	signal regValsArr: MwordArray(0 to 3*5-1) := (others => (others => '0'));
	

	type IssueView is record
		acceptingVecA, acceptingVecB, acceptingVecC, acceptingVecD, acceptingVecE:
													std_logic_vector(0 to PIPE_WIDTH-1);
		queueSendingA, queueSendingB, queueSendingC, queueSendingD, queueSendingE: std_logic;
		queueDataA, queueDataB, queueDataC, queueDataD, queueDataE: InstructionState;
		---
		issueAcceptingA, issueAcceptingB, issueAcceptingC, issueAcceptingD, issueAcceptingE: std_logic;
		sendingSchedA, sendingSchedB, sendingSchedC, sendingSchedD, sendingSchedE,
			execAcceptingA, execAcceptingB, execAcceptingC, execAcceptingD, execAcceptingE: std_logic;
		dataOutSchedA, dataOutSchedB, dataOutSchedC, dataOutSchedD, dataOutSchedE: InstructionState;		
	end record;

	constant DEFAULT_ISSUE_VIEW: IssueView := (
		acceptingVecA => (others => '0'), 
		acceptingVecB => (others => '0'), 
		acceptingVecC => (others => '0'), 
		acceptingVecD => (others => '0'), 
		acceptingVecE => (others => '0'),
		queueSendingA => '0',
		queueSendingB => '0',
		queueSendingC => '0',
		queueSendingD => '0',
		queueSendingE => '0',
		queueDataA => DEFAULT_INSTRUCTION_STATE,
		queueDataB => DEFAULT_INSTRUCTION_STATE,
		queueDataC => DEFAULT_INSTRUCTION_STATE,
		queueDataD => DEFAULT_INSTRUCTION_STATE,
		queueDataE => DEFAULT_INSTRUCTION_STATE,
		sendingSchedA => '0',
		sendingSchedB => '0',
		sendingSchedC => '0',
		sendingSchedD => '0',
		sendingSchedE => '0',
		issueAcceptingA => '0',
		issueAcceptingB => '0',
		issueAcceptingC => '0',
		issueAcceptingD => '0',
		issueAcceptingE => '0',
		execAcceptingA => '0',
		execAcceptingB => '0',
		execAcceptingC => '0',
		execAcceptingD => '0',
		execAcceptingE => '0',
		dataOutSchedA => DEFAULT_INSTRUCTION_STATE,
		dataOutSchedB => DEFAULT_INSTRUCTION_STATE,
		dataOutSchedC => DEFAULT_INSTRUCTION_STATE,
		dataOutSchedD => DEFAULT_INSTRUCTION_STATE,
		dataOutSchedE => DEFAULT_INSTRUCTION_STATE		
	);
	
	signal theIssueView: IssueView := DEFAULT_ISSUE_VIEW;
	
	function getIssueView(iqOutputArr, schedOutputArr: InstructionSlotArray;
								 iqAcceptingVecArr: SLVA;
								 issueAcceptingArr, execAcceptingArr: std_logic_vector)
	return IssueView is
		variable res: IssueView := DEFAULT_ISSUE_VIEW;
		variable queueSendingArr, schedSendingArr: std_logic_vector(0 to 5-1) := (others => '0');
		variable queueDataArr, schedDataArr: InstructionStateArray(0 to 5-1)
								:= (others => DEFAULT_INSTRUCTION_STATE);
	begin
			queueSendingArr := extractFullMask(iqOutputArr); -- For viewing
			queueDataArr := extractData(iqOutputArr); -- For viewing
		
		res.queueSendingA := queueSendingArr(0);
		res.queueSendingB := queueSendingArr(1);
		res.queueSendingC := queueSendingArr(2);
		res.queueSendingD := queueSendingArr(3);
		res.queueSendingE := queueSendingArr(4);
		
		res.queueDataA := queueDataArr(0);
		res.queueDataB := queueDataArr(1);
		res.queueDataC := queueDataArr(2);
		res.queueDataD := queueDataArr(3);
		res.queueDataE := queueDataArr(4);
		
		res.acceptingVecA := iqAcceptingVecArr(0);
		res.acceptingVecB := iqAcceptingVecArr(1);
		res.acceptingVecC := iqAcceptingVecArr(2);
		res.acceptingVecD := iqAcceptingVecArr(3);
		res.acceptingVecE := iqAcceptingVecArr(4);

			schedSendingArr := extractFullMask(schedOutputArr); -- Only for viewing
			schedDataArr := extractData(schedOutputArr); -- Only for viewing

			res.issueAcceptingA := issueAcceptingArr(0);
			res.issueAcceptingB := issueAcceptingArr(1);
			res.issueAcceptingC := issueAcceptingArr(2);
			res.issueAcceptingD := issueAcceptingArr(3);
			res.issueAcceptingE := issueAcceptingArr(4);

			res.execAcceptingA := execAcceptingArr(0);
			res.execAcceptingB := execAcceptingArr(1);
			res.execAcceptingC := execAcceptingArr(2);
			res.execAcceptingD := execAcceptingArr(3);
			res.execAcceptingE := execAcceptingArr(4);
		
			res.dataOutSchedA := schedDataArr(0);
			res.dataOutSchedB := schedDataArr(1);
			res.dataOutSchedC := schedDataArr(2);
			res.dataOutSchedD := schedDataArr(3);
			res.dataOutSchedE := schedDataArr(4);
			
			-- Not used
			res.sendingSchedA := schedSendingArr(0);
			res.sendingSchedB := schedSendingArr(1);
			res.sendingSchedC := schedSendingArr(2);
			res.sendingSchedD := schedSendingArr(3);
			res.sendingSchedE := schedSendingArr(4);		
		
		return res;
	end function;

begin		
	resetSig <= reset;
	enSig <= en;
		
	theIssueView <= getIssueView(iqOutputArr, schedOutputArr,
								 iqAcceptingVecArr,
								 issueAcceptingArr, execAcceptingArr);
		
			ISSUE_ROUTING: entity work.SubunitIssueRouting(Behavioral)
			port map(
				renamedDataLiving => renamedDataLiving,

				acceptingVecA => iqAcceptingVecArr(0),
				acceptingVecB => iqAcceptingVecArr(1),
				acceptingVecC => iqAcceptingVecArr(2),
				acceptingVecD => iqAcceptingVecArr(3),
				acceptingVecE => iqAcceptingVecArr(4),

				acceptingROB => robAccepting,
				acceptingSQ => acceptingNewSQ,
				acceptingLQ => acceptingNewLQ,
				acceptingBQ => acceptingNewBQ,

				renamedSendingIn => renamedSending,
				
				renamedSendingOut => open, -- DEPREC??
				iqAccepts => iqAccepts,		
				
				dataOutA => dataToQueuesArr(0),--dataToA,
				dataOutB => dataToQueuesArr(1),--dataToB,
				dataOutC => dataToQueuesArr(2),--dataToC,
				dataOutD => dataToQueuesArr(3),--dataToD,
				dataOutE => dataToQueuesArr(4),--dataToE,
				
				dataOutSQ => compactedToSQ,
				dataOutLQ => compactedToLQ,
				dataOutBQ => compactedToBQ
			);

		--dataToQueuesArr <= (dataToA, dataToB, dataToC, dataToD, dataToE);
		ISSUE_QUEUES: for letter in 'A' to 'E' generate
			constant i: integer := character'pos(letter) - character'pos('A');
		begin
		
			IQUEUE: entity work.UnitIQ
			generic map(
				IQ_SIZE => IQ_SIZES(i)
			)
			port map(
				clk => clk, reset => resetSig, en => enSig,

				acceptingVec => iqAcceptingVecArr(i),
				prevSendingOK => renamedSending,
				newData => dataToQueuesArr(i),
				fni => fni,
				readyRegFlags => readyRegFlags,
				issueAccepting => issueAcceptingArr(i),
				execCausing => execCausing,
				lateEventSignal => lateEventSignal,
				execEventSignal => execEventSignal,
				queueOutput => iqOutputArr(i)
			);
		end generate;
			
			queueSendingArr <= extractFullMask(iqOutputArr); -- For viewing
			queueDataArr <= extractData(iqOutputArr); -- For viewing
		
		-- Not used, for viewing
		queueSendingA <= queueSendingArr(0);
		queueSendingB <= queueSendingArr(1);
		queueSendingC <= queueSendingArr(2);
		queueSendingD <= queueSendingArr(3);
		queueSendingE <= queueSendingArr(4);
		
		-- Not used
		queueDataA <= queueDataArr(0);
		queueDataB <= queueDataArr(1);
		queueDataC <= queueDataArr(2);
		queueDataD <= queueDataArr(3);
		queueDataE <= queueDataArr(4);
		
		-- Not used
		acceptingVecA <= iqAcceptingVecArr(0);
		acceptingVecB <= iqAcceptingVecArr(1);
		acceptingVecC <= iqAcceptingVecArr(2);
		acceptingVecD <= iqAcceptingVecArr(3);
		acceptingVecE <= iqAcceptingVecArr(4);

			sendingSchedArr <= extractFullMask(schedOutputArr); -- Only for viewing
			schedDataArr <= extractData(schedOutputArr); -- Only for viewing

			-- Unused, only for viewing purpose
			issueAcceptingA <= issueAcceptingArr(0);
			issueAcceptingB <= issueAcceptingArr(1);
			issueAcceptingC <= issueAcceptingArr(2);
			issueAcceptingD <= issueAcceptingArr(3);
			issueAcceptingE <= issueAcceptingArr(4);
			
			-- No used
			dataOutIQA <= schedDataArr(0);
			dataOutIQB <= schedDataArr(1);
			dataOutIQC <= schedDataArr(2);
			dataOutIQD <= schedDataArr(3);
			dataOutIQE <= schedDataArr(4);
			
			-- Not used
			sendingSchedA <= sendingSchedArr(0);
			sendingSchedB <= sendingSchedArr(1);
			sendingSchedC <= sendingSchedArr(2);
			sendingSchedD <= sendingSchedArr(3);
			sendingSchedE <= sendingSchedArr(4);


		EXEC_AREA: block
			constant USE_IMM_VEC: std_logic_vector(0 to 4) := "10110";
		begin
			regsSelA <= getPhysicalSources(iqOutputArr(0).ins);
			regsSelB <= getPhysicalSources(iqOutputArr(1).ins);
			regsSelC <= getPhysicalSources(iqOutputArr(2).ins);
			regsSelD <= getPhysicalSources(iqOutputArr(3).ins);
			regsSelE <= getPhysicalSources(iqOutputArr(4).ins);

			regValsArr <= regValsA & regValsB & regValsC & regValsD & regValsE;
			execAcceptingArr <= (execAcceptingA, execAcceptingB, execAcceptingC,
											execAcceptingD, execAcceptingE);

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
					input => iqOutputArr(i),
					nextAccepting => execAcceptingArr(i),--
					execEventSignal => execEventSignal,
					lateEventSignal => lateEventSignal,
					execCausing => execCausing,
					resultTags => fni.resultTags,
					resultVals => fni.resultValues,
					regValues => regValsArr(3*i to 3*i + 2),--
					acceptingOut => issueAcceptingArr(i),
					output => schedOutputArr(i)
				);			
			end generate;
			
			EXEC_BLOCK: entity work.UnitExec(Implem)
			port map(
				clk => clk, reset => resetSig, en => enSig,

				execAcceptingA => execAcceptingA,
				execAcceptingB => execAcceptingB,				
				execAcceptingD => execAcceptingD,

				inputA => --(sendingSchedA, dataOutIQA),
								schedOutputArr(0),
				inputB => --(sendingSchedB, dataOutIQB),
								schedOutputArr(1),
				inputD => --(sendingSchedD, dataOutIQD),
								schedOutputArr(3),
				
				outputA => outputA,
				outputB => outputB,
				outputD => outputD,
					
				outputOpPreB => outputOpPreB,

				whichAcceptedCQ => whichAcceptedCQ,
				
				acceptingNewBQ => acceptingNewBQ,
				dataOutBQV => dataOutBQV,
				prevSendingToBQ => renamedSending,
				dataNewToBQ => compactedToBQ,
					
				committing => robSending,
					
				groupCtrNext => commitGroupCtrNextSig,
				groupCtrInc => commitGroupCtrIncSig,
				
				execEvent => execEventSignal,
				execCausingOut => execCausing,
						
				lateEventSignal => lateEventSignal,
				execOrIntEventSignalIn => execEventSignal
			);	

				NEW_MEM_UNIT: entity work.UnitMemory(Behavioral)
				port map(
					clk => clk, reset => reset, en => en,

					execAcceptingC => execAcceptingC,
					execAcceptingE => execAcceptingE,

					inputC => --(sendingSchedC, dataOutIQC),
								schedOutputArr(2),
					inputE => --(sendingSchedE, dataOutIQE),
								schedOutputArr(4),

					acceptingNewSQ => acceptingNewSQ,
					acceptingNewLQ => acceptingNewLQ,
					prevSendingToSQ => renamedSending,
					prevSendingToLQ => renamedSending,
					dataNewToSQ => compactedToSQ,
					dataNewToLQ => compactedToLQ,

					outputC => outputC,
					outputE => outputE,
						
					outputOpPreC => outputOpPreC,

					whichAcceptedCQ => whichAcceptedCQ,
					
					memLoadAddress => memLoadAddress,
					memLoadAllow => memLoadAllow,
					memLoadReady => memLoadReady,
					memLoadValue => memLoadValue,

					sysLoadAllow => open,
					sysLoadVal => sysRegReadValue,

					committing => robSending,
					groupCtrNext => commitGroupCtrNextSig,				
					groupCtrInc => commitGroupCtrIncSig,
						
						sbAcceptingIn => sbAccepting,
						dataOutSQ => dataOutSQ,
											
					lateEventSignal => lateEventSignal,	
					execOrIntEventSignalIn => execEventSignal,
					execCausing => execCausing
				);

						sysRegReadSel <= memLoadAddress(4 downto 0);

					execSending <= getExecSending(outputA, outputB, outputC, outputD, outputE);
					execSending2 <= getExecSending2(outputA, outputB, outputC, outputD, outputE);
					execEnds <= getExecEnds(outputA, outputB, outputC, outputD, outputE);
					execEnds2 <= getExecEnds2(outputA, outputB, outputC, outputD, outputE);
					execPreEnds <= getExecPreEnds(outputOpPreB, outputOpPreC);

		execOutputs1 <= (0 => outputA, 1 => outputB, 2 => outputC, others => DEFAULT_INSTRUCTION_SLOT);
		execOutputs2 <= (		2 => outputE, 3 => outputD, others => DEFAULT_INSTRUCTION_SLOT); -- (-,-,E,D)! 
		execOutputsPre <= (0 => ('0', outputOpPreB), 1 => ('0', outputOpPreC),
																				others => DEFAULT_INSTRUCTION_SLOT);
			COMMIT_QUEUE: entity work.TestCQPart0(Implem)
			generic map(
				INPUT_WIDTH => 3,
				QUEUE_SIZE => CQ_SIZE,
				OUTPUT_SIZE => INTEGER_WRITE_WIDTH
			)
			port map(
				clk => clk, reset => resetSig, en => enSig,
				
				execEventSignal => '0',
				execCausing => DEFAULT_INSTRUCTION_STATE,

				input => execOutputs1(0 to 2),
				
				whichAcceptedCQ => whichAcceptedCQ,
				anySending => open,--anySendingFromCQ,
				cqOutput => cqOutputSig,
				bufferOutput => cqBufferOutputSig
			);

				anySendingFromCQ <= cqOutputSig(0).full; -- CAREFUL, only used for SINGLE_OUTPUT
			cqDataLivingOut.fullMask(0) <= cqOutputSig(0).full;--cqMaskSig(0);
			cqDataLivingOut.data(0) <= cqOutputSig(0).ins;--cqDataSig(0);

				-- CAREFUL! This stage is needed to keep result tags 1 for cycle when writing to reg file,
				--				so that "black hole" of invisible readiness doesn't occur
				AFTER_CQ: entity work.GenericStageMulti(Behavioral) port map(
					clk => clk, reset => resetSig, en => enSig,
					
					prevSending => anySendingFromCQ,
					nextAccepting => '1',
					execEventSignal => '0',
						lateEventSignal => '0',
					execCausing => execCausing,
					stageDataIn => cqDataLivingOut,
					acceptingOut => open,
					sendingOut => open,
					stageDataOut => stageDataAfterCQ,
					
					lockCommand => '0'			
				);

	-- writtenTags indicate registers written to GPR file in last cycle, so they can be read from there
	--		rather than from forw. network, but readyRegFlags are not available in the 1st cycle after WB.		
	fni.writtenTags <=
					getPhysicalDests(stageDataAfterCQ) when CQ_SINGLE_OUTPUT else (others => (others => '0'));
	fni.resultTags <= getResultTags(execEnds, extractData(cqBufferOutputSig),
										--schedOutputArr,
										--dataOutIQA, dataOutIQB, dataOutIQC, dataOutIQD, 
										DEFAULT_STAGE_DATA_MULTI
										);
	fni.nextResultTags <= getNextResultTags(execPreEnds,
										schedOutputArr
										--dataOutIQA, dataOutIQB, dataOutIQC, dataOutIQD
										);
	fni.resultValues <= getResultValues(execEnds, extractData(cqBufferOutputSig), DEFAULT_STAGE_DATA_MULTI);
					
				-- Int register block
					regsSelCE(0 to 1) <= regsSelC(0 to 1);
					regsSelCE(2) <= regsSelE(2);
					regValsC(0 to 1) <= regValsCE(0 to 1);
					regValsE(2) <= regValsCE(2);	
	
				GPR_FILE_DISPATCH: entity work.RegisterFile0 (Behavioral)
				generic map(WIDTH => 4, WRITE_WIDTH => INTEGER_WRITE_WIDTH)
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
				------------------------------
		end block;

			REORDER_BUFFER: entity work.ReorderBuffer(Implem)
			port map(
				clk => clk, reset => resetSig, en => enSig,
				
				lateEventSignal => lateEventSignal,
				execEventSignal => execEventSignal,
				execCausing => execCausing,
				
				commitGroupCtr => commitGroupCtrSig,
				commitGroupCtrNext => commitGroupCtrNextSig,

				execEndSigs1 => execOutputs1,
				execEndSigs2 => execOutputs2,
				
				inputData => renamedDataLiving,
				prevSending => renamedSending,
				acceptingOut => robAccepting,
				
				nextAccepting => commitAccepting and sbAccepting,
				sendingOut => robSending, 
				outputData => dataOutROB		
			);

	execEventSignalOut <= execEventSignal;
	execCausingOut <= execCausing;

	robSendingOut <= robSending;
	memLoadAddressOut <= memLoadAddress;

	cqOutput <= cqOutputSig;
end Behavioral;
