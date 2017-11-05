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
			
				cqMaskOut: out std_logic_vector(0 to INTEGER_WRITE_WIDTH-1);
				cqDataOut: out InstructionStateArray(0 to INTEGER_WRITE_WIDTH-1)			
			  
			  );
end OutOfOrderBox;



architecture Behavioral of OutOfOrderBox is
	signal execEventSignal: std_logic := '0';
	signal execCausing: InstructionState := defaultInstructionState; -- OUTPUT/SIG

	signal robSending: std_logic := '0';

	signal memLoadAddress: Mword := (others => '0');
	
	signal resetSig, enSig: std_logic := '0';

			signal dataToA, dataToB, dataToC, dataToD, dataToE: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;						
			signal acceptingVecA, acceptingVecB, acceptingVecC, acceptingVecD, acceptingVecE:
						std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
			signal compactedToSQ, compactedToLQ, compactedToBQ: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

			signal acceptingNewSQ, acceptingNewLQ, acceptingNewBQ: std_logic := '0';
			signal robAccepting: std_logic := '0';
				
		
			signal dataOutIQA, dataOutIQB, dataOutIQC, dataOutIQD, dataOutIQE: InstructionState
																			:= defaultInstructionState;	
			signal sendingSchedA, sendingSchedB, sendingSchedC, sendingSchedD, sendingSchedE,
					execAcceptingA, execAcceptingB, execAcceptingC, execAcceptingD, execAcceptingE: std_logic := '0';
						
			-- Physical register interface
			signal regsSelA, regsSelB, regsSelC, regsSelD, regsSelE, regsSelCE: PhysNameArray(0 to 2)
							:= (others => (others => '0'));
			signal regValsA, regValsB, regValsC, regValsD, regValsE, regValsCE: MwordArray(0 to 2)
									:= (others => (others => '0'));
				
			signal fni: ForwardingInfo := DEFAULT_FORWARDING_INFO;

			signal rfWriteVec: std_logic_vector(0 to 3) := (others => '0');
			signal rfSelectWrite: PhysNameArray(0 to 3) := (others => (others => '0'));
			signal rfWriteValues: MwordArray(0 to 3) := (others => (others => '0'));
	
			signal stageDataAfterCQ: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;


			-- writtenTags indicate registers written to GPR file in last cycle, so they can be read from there
			--		rather than from forw. network, but readyRegFlags are not available in the 1st cycle after WB.
			signal writtenTags: PhysNameArray(0 to PIPE_WIDTH-1) := (others => (others => '0'));

			signal outputA, outputB, outputC, outputD, outputE: InstructionSlot := DEFAULT_INSTRUCTION_SLOT;
			signal outputOpPreB, outputOpPreC: InstructionState := DEFAULT_INSTRUCTION_STATE;

			signal execEnds, execEnds2: InstructionStateArray(0 to 3) := (others => DEFAULT_INSTRUCTION_STATE);
			signal execPreEnds: InstructionStateArray(0 to 3) := (others => DEFAULT_INSTRUCTION_STATE);
			signal execSending, execSending2: std_logic_vector(0 to 3) := (others => '0');
		
			-- back end interfaces
			signal whichAcceptedCQ: std_logic_vector(0 to 3) := (others=>'0');	
			signal anySendingFromCQ: std_logic := '0';
	
			signal cqBufferMask: std_logic_vector(0 to CQ_SIZE-1) := (others => '0');
			signal cqBufferData: InstructionStateArray(0 to CQ_SIZE-1) := (others => DEFAULT_INSTRUCTION_STATE);
			signal cqDataLivingOut: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

			signal	cqMaskSig: std_logic_vector(0 to INTEGER_WRITE_WIDTH-1) := (others => '0');
			signal	cqDataSig: InstructionStateArray(0 to INTEGER_WRITE_WIDTH-1)
											:= (others => DEFAULT_INSTRUCTION_STATE);
			
				signal queueDataA, queueDataB, queueDataC, queueDataD, queueDataE:
								InstructionState := DEFAULT_INSTRUCTION_STATE;
				signal queueSendingA, queueSendingB, queueSendingC, queueSendingD, queueSendingE:
								std_logic := '0';
				signal issueAcceptingA, issueAcceptingB, issueAcceptingC, issueAcceptingD, issueAcceptingE:
								std_logic := '0';
								
			type SLVA is array (integer range <>) of std_logic_vector(0 to PIPE_WIDTH-1);
			signal iqAcceptingVecArr: SLVA(0 to 4) := (others => (others => '0'));
			
			signal issueAcceptingArr, queueSendingArr: std_logic_vector(0 to 4) := (others => '0');
			signal queueDataArr: InstructionStateArray(0 to 4)
											:= (others => DEFAULT_INSTRUCTION_STATE);
			signal dataToQueuesArr: StageDataMultiArray(0 to 4)
											:= (others => DEFAULT_STAGE_DATA_MULTI);			
		begin
		
	resetSig <= reset;
	enSig <= en;
		
			ISSUE_ROUTING: entity work.SubunitIssueRouting(Behavioral)
			port map(
				renamedDataLiving => renamedDataLiving,

				acceptingVecA => acceptingVecA,
				acceptingVecB => acceptingVecB,
				acceptingVecC => acceptingVecC,
				acceptingVecD => acceptingVecD,
				acceptingVecE => acceptingVecE,

				acceptingROB => robAccepting,
				acceptingSQ => acceptingNewSQ,
				acceptingLQ => acceptingNewLQ,
				acceptingBQ => acceptingNewBQ,

				renamedSendingIn => renamedSending,
				
				renamedSendingOut => open, -- DEPREC??
				iqAccepts => iqAccepts,		
				
				dataOutA => dataToA,
				dataOutB => dataToB,
				dataOutC => dataToC,
				dataOutD => dataToD,
				dataOutE => dataToE,
				
				dataOutSQ => compactedToSQ,
				dataOutLQ => compactedToLQ,
				dataOutBQ => compactedToBQ
			);


		dataToQueuesArr <= (dataToA, dataToB, dataToC, dataToD, dataToE);
		issueAcceptingArr <= (issueAcceptingA, issueAcceptingB, issueAcceptingC,
											issueAcceptingD, issueAcceptingE); -- TMP!
		
		ISSUE_QUEUES: for letter in 'A' to 'E' generate
			constant i: integer := character'pos(letter) - character'pos('A');
			signal qq: std_logic := '0'; -- REMOVE
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

					issueAccepting => issueAcceptingArr(i), --
					queueSendingOut => queueSendingArr(i),
					queueDataOut => queueDataArr(i),
			
				execCausing => execCausing,
					lateEventSignal => lateEventSignal,
				execEventSignal => execEventSignal			
			);
		end generate;
		
		queueSendingA <= queueSendingArr(0);
		queueSendingB <= queueSendingArr(1);
		queueSendingC <= queueSendingArr(2);
		queueSendingD <= queueSendingArr(3);
		queueSendingE <= queueSendingArr(4);
		
		queueDataA <= queueDataArr(0);
		queueDataB <= queueDataArr(1);
		queueDataC <= queueDataArr(2);
		queueDataD <= queueDataArr(3);
		queueDataE <= queueDataArr(4);
		
		acceptingVecA <= iqAcceptingVecArr(0);
		acceptingVecB <= iqAcceptingVecArr(1);
		acceptingVecC <= iqAcceptingVecArr(2);
		acceptingVecD <= iqAcceptingVecArr(3);
		acceptingVecE <= iqAcceptingVecArr(4);
		
		
			IQ_A: entity work.UnitIQ
			generic map(
				IQ_SIZE => IQ_A_SIZE
			)
			port map(
				clk => clk, reset => resetSig, en => enSig,

				acceptingVec => open,--acceptingVecA,

				prevSendingOK => renamedSending,
				newData => dataToA,

				fni => fni,
				
				readyRegFlags => readyRegFlags,

					issueAccepting => issueAcceptingA, --
					queueSendingOut => open,--queueSendingA,
					queueDataOut => open,--queueDataA,
			
				execCausing => execCausing,
					lateEventSignal => lateEventSignal,
				execEventSignal => execEventSignal			
			);
		
			IQ_B: entity work.UnitIQ
			generic map(
				IQ_SIZE => IQ_B_SIZE
			)
			port map(
				clk => clk, reset => resetSig, en => enSig,

				acceptingVec => open,--acceptingVecB,		
				
				prevSendingOK => renamedSending,
				newData => dataToB,		

				fni => fni,	
						
				readyRegFlags => readyRegFlags,		

					issueAccepting => issueAcceptingB,
					queueSendingOut => open,--queueSendingB,
					queueDataOut => open,--queueDataB,

				execCausing => execCausing,
					lateEventSignal => lateEventSignal,
				execEventSignal => execEventSignal
			);
			
			IQ_C: entity work.UnitIQ
			generic map(
				IQ_SIZE => IQ_C_SIZE
			)
			port map(
				clk => clk, reset => resetSig, en => enSig,

				acceptingVec => open,--acceptingVecC,		

				prevSendingOK => renamedSending,
				newData => dataToC,			

				fni => fni,
						
				readyRegFlags => readyRegFlags,

					issueAccepting => issueAcceptingC,
					queueSendingOut => open,--queueSendingC,
					queueDataOut => open,--queueDataC,
	
				execCausing => execCausing,
					lateEventSignal => lateEventSignal,
				execEventSignal => execEventSignal
			);					
			
			IQ_D: entity work.UnitIQ
			generic map(
				IQ_SIZE => IQ_D_SIZE
			)
			port map(
				clk => clk, reset => resetSig, en => enSig,

				acceptingVec => open,--acceptingVecD,		

				prevSendingOK => renamedSending,
				newData => dataToD,

				fni => fni,
						
				readyRegFlags => readyRegFlags,

					issueAccepting => issueAcceptingD,
					queueSendingOut => open,--queueSendingD,
					queueDataOut => open,--queueDataD,

				execCausing => execCausing,
					lateEventSignal => lateEventSignal,
				execEventSignal => execEventSignal
			);	
		
			IQ_E: entity work.UnitIQ
			generic map(
				IQ_SIZE => IQ_E_SIZE
			)
			port map(
				clk => clk, reset => resetSig, en => enSig,

				acceptingVec => open,--acceptingVecE,		
				prevSendingOK => renamedSending,
				newData => dataToE,
				
				fni => fni,	
						
				readyRegFlags => readyRegFlags, -- bits generated for input group

					issueAccepting => issueAcceptingE,
					queueSendingOut => open,--queueSendingE,
					queueDataOut => open,--queueDataE,

				execCausing => execCausing,
					lateEventSignal => lateEventSignal,
				execEventSignal => execEventSignal
			);	


		EXEC_AREA: block
		begin
				regsSelA <= getPhysicalSources(queueDataA);
				regsSelB <= getPhysicalSources(queueDataB);
				regsSelC <= getPhysicalSources(queueDataC);
				regsSelD <= getPhysicalSources(queueDataD);
				regsSelE <= getPhysicalSources(queueDataE);

			ISSUE_A: entity work.SubunitDispatch(Alternative)	
			port map(
				clk => clk, reset => resetSig, en => enSig,
				prevSending => queueSendingA,
				nextAccepting => execAcceptingA,
				execEventSignal => execEventSignal,
				lateEventSignal => lateEventSignal,
				execCausing => execCausing,
				resultTags => fni.resultTags,
				resultVals => fni.resultValues,
				regValues => regValsA,
				stageDataIn => queueDataA,		
				acceptingOut => issueAcceptingA,
				sendingOut => sendingSchedA,
				stageDataOut => dataOutIQA
			);
			
			ISSUE_B: entity work.SubunitDispatch(Alternative)
			generic map(
				USE_IMM => false
			)
			port map(
				clk => clk, reset => resetSig, en => enSig,
				prevSending => queueSendingB,
				nextAccepting => execAcceptingB,
				execEventSignal => execEventSignal,
				lateEventSignal => lateEventSignal,
				execCausing => execCausing,
				resultTags => fni.resultTags,
				resultVals => fni.resultValues,
				regValues => regValsB,
				stageDataIn => queueDataB,		
				acceptingOut => issueAcceptingB,
				sendingOut => sendingSchedB,
				stageDataOut => dataOutIQB
			);

			ISSUE_C: entity work.SubunitDispatch(Alternative)	
			port map(
				clk => clk, reset => resetSig, en => enSig,
				prevSending => queueSendingC,
				nextAccepting => execAcceptingC,
				execEventSignal => execEventSignal,
				lateEventSignal => lateEventSignal,
				execCausing => execCausing,
				resultTags => fni.resultTags,
				resultVals => fni.resultValues,
				regValues => regValsC,
				stageDataIn => queueDataC,		
				acceptingOut => issueAcceptingC,
				sendingOut => sendingSchedC,
				stageDataOut => dataOutIQC
			);
			
			ISSUE_D: entity work.SubunitDispatch(Alternative)	
			port map(
				clk => clk, reset => resetSig, en => enSig,
				prevSending => queueSendingD,
				nextAccepting => execAcceptingD,
				execEventSignal => execEventSignal,
				lateEventSignal => lateEventSignal,
				execCausing => execCausing,
				resultTags => fni.resultTags,
				resultVals => fni.resultValues,
				regValues => regValsD,
				stageDataIn => queueDataD,		
				acceptingOut => issueAcceptingD,
				sendingOut => sendingSchedD,
				stageDataOut => dataOutIQD
			);
			
			ISSUE_E: entity work.SubunitDispatch(Alternative)
			generic map(
				USE_IMM => false
			)
			port map(
				clk => clk, reset => resetSig, en => enSig,
				prevSending => queueSendingE,
				nextAccepting => execAcceptingE,
				execEventSignal => execEventSignal,
				lateEventSignal => lateEventSignal,
				execCausing => execCausing,
				resultTags => fni.resultTags,
				resultVals => fni.resultValues,
				regValues => regValsE,
				stageDataIn => queueDataE,		
				acceptingOut => issueAcceptingE,
				sendingOut => sendingSchedE,
				stageDataOut => dataOutIQE
			);

			
			EXEC_BLOCK: entity work.UnitExec(Implem)
			port map(
				clk => clk, reset => resetSig, en => enSig,

				execAcceptingA => execAcceptingA,
				execAcceptingB => execAcceptingB,				
				execAcceptingD => execAcceptingD,

				sendingIQA => sendingSchedA,
				sendingIQB => sendingSchedB,
				sendingIQD => sendingSchedD,

				dataIQA => dataOutIQA,
				dataIQB => dataOutIQB,
				dataIQD => dataOutIQD,
				
				outputA => outputA,
				outputB => outputB,
				outputD => outputD,
					
				outputOpPreB => outputOpPreB,

				whichAcceptedCQ => whichAcceptedCQ,
				
				acceptingNewBQ => acceptingNewBQ,
				--sendingOutBQ => sendingFromBQ,
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
					
					sendingIQC => sendingSchedC,
					sendingIQE => sendingSchedE,

					dataIQC => dataOutIQC,
					dataIQE => dataOutIQE,
					-------------

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
				
					maskIn => execSending(0 to 2),
					dataIn => execEnds(0 to 2),
				
				whichAcceptedCQ => whichAcceptedCQ,
				anySending => anySendingFromCQ,
					cqMaskOut => cqMaskSig,
					cqDataOut => cqDataSig,
						bufferMaskOut => cqBufferMask,
						bufferDataOut => cqBufferData
			);
				
					cqDataLivingOut.fullMask(0) <= cqMaskSig(0);
					cqDataLivingOut.data(0) <= cqDataSig(0);

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
		
			writtenTags <= getPhysicalDests(stageDataAfterCQ) when CQ_SINGLE_OUTPUT else (others => (others => '0'));
			
				fni.writtenTags <= writtenTags;
				fni.resultTags <= getResultTags(execEnds, cqBufferData, dataOutIQA, dataOutIQB, dataOutIQC, dataOutIQD,
																													DEFAULT_STAGE_DATA_MULTI);
				fni.nextResultTags <= getNextResultTags(execPreEnds, dataOutIQA, dataOutIQB, dataOutIQC, dataOutIQD);
				fni.resultValues <= getResultValues(execEnds, cqBufferData, DEFAULT_STAGE_DATA_MULTI);
					
				-- Int register block
					regsSelCE(0 to 1) <= regsSelC(0 to 1);
					regsSelCE(2) <= regsSelE(2);
					regValsC(0 to 1) <= regValsCE(0 to 1);
					regValsE(2) <= regValsCE(2);	

					rfWriteVec(0 to INTEGER_WRITE_WIDTH-1) <= getArrayDestMask(cqDataSig, cqMaskSig);
					rfSelectWrite(0 to INTEGER_WRITE_WIDTH-1) <= getArrayPhysicalDests(cqDataSig);
					rfWriteValues(0 to INTEGER_WRITE_WIDTH-1) <= getArrayResults(cqDataSig);
				
				GPR_FILE_DISPATCH: entity work.RegisterFile0 (Behavioral)
				generic map(WIDTH => 4, WRITE_WIDTH => INTEGER_WRITE_WIDTH)
				port map(
					clk => clk, reset => resetSig, en => enSig,
						
					writeAllow => '1',
					writeVec => rfWriteVec,
					selectWrite => rfSelectWrite, -- NOTE: unneeded writing isn't harmful anyway
					writeValues => rfWriteValues,
					
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
					
				execEnds => execEnds,
				execReady => execSending,
				
				execEnds2 => execEnds2,
				execReady2 => execSending2,
				
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
	
	cqMaskOut <= cqMaskSig;
	cqDataOut <= cqDataSig;

end Behavioral;
