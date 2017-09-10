
-- CAREFUL! If partial kill occurs, we have to check if any slot of the stage remains alive,
--				and if no one, then generate killAll signal for that stage! 

architecture Behavioral5 of NewCore0 is	
	signal resetSig, enSig: std_logic := '0';				
				
	signal pcDataSig: InstructionState := DEFAULT_INSTRUCTION_STATE;
	signal pcSendingSig: std_logic := '0';

	signal acceptingOutFront: std_logic := '0';
	signal stage0Events: StageMultiEventInfo;
	
	signal frontDataLastLiving: StageDataMulti;
	signal frontLastSending, renameAccepting: std_logic := '0';

---------------------------------
	signal renamedDataLiving: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;	-- INPUT			
	signal renamedSending, -- INPUT
				iqAccepts: std_logic := '0'; -- OUTPUT

	-- Sys reg interface	
	signal sysRegReadSel: slv5 := (others => '0'); -- OUTPUT  -- Doesn't need to be a port of OOO part
	signal sysRegReadValue: Mword := (others => '0'); -- INPUT

	-- Mem interface
	signal memLoadAddress, memLoadValue: Mword := (others => '0');  -- OUTPUT, INPUT
	signal memLoadAllow, memLoadReady: std_logic := '0';  -- OUTPUT, INPUT

	-- evt
	signal execEventSignal, lateEventSignal: std_logic := '0';	-- OUTPUT/SIG, INPUT 	
	signal execCausing: InstructionState := defaultInstructionState; -- OUTPUT/SIG

	-- Hidden to some degree, but may be useful for sth
	signal commitGroupCtrSig, commitGroupCtrNextSig: SmallNumber := (others => '0'); -- INPUT
	signal commitGroupCtrIncSig: SmallNumber := (others => '0');	-- INPUT
												
	-- ROB interface	
	signal robSending: std_logic := '0';		-- OUTPUT
	signal dataOutROB: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;		-- OUTPUT

		signal sbAccepting: std_logic := '0';	-- INPUT
		signal commitAccepting: std_logic := '0'; -- INPUT

		signal dataOutBQV: StageDataMulti := DEFAULT_STAGE_DATA_MULTI; -- OUTPUT
		signal dataOutSQ: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;	-- OUTPUT
-------------------------------------------------------

	signal execOrIntCausing: InstructionState := defaultInstructionState;
	signal execOrIntEventSignal: std_logic := '0';

		signal newPhysDests: PhysNameArray(0 to PIPE_WIDTH-1) := (others => (others => '0'));
		signal newPhysDestPointer: SmallNumber := (others => '0');
		signal newPhysSources: PhysNameArray(0 to 3*PIPE_WIDTH-1) := (others => (others => '0'));


		signal committingSig: std_logic := '0';	-- !! Just a copy of robSending
			
		signal committedSending, renameLockEnd: std_logic := '0';
		signal committedDataOut: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

			signal sbEmpty, sbSending: std_logic := '0';
			signal dataFromSB: InstructionState := DEFAULT_INSTRUCTION_STATE;
			signal sbAcceptingV: std_logic_vector(0 to 3) := (others => '0');				
			signal sbMaskOut: std_logic_vector(0 to 0) := (others => '0');
			signal sbDataOut: InstructionStateArray(0 to 0) := (others => DEFAULT_INSTRUCTION_STATE);	
			signal sbFullMask: std_logic_vector(0 to SB_SIZE-1) := (others => '0');

		signal sysStoreAllow: std_logic := '0';
		signal sysStoreAddress: slv5 := (others => '0'); 
		signal sysStoreValue: Mword := (others => '0');
		
		signal memStoreAddress, memStoreValue: Mword := (others => '0');
		signal memStoreAllow: std_logic := '0';
			
	constant HAS_RESET: std_logic := '0';
	constant HAS_EN: std_logic := '0';
begin
	resetSig <= reset and HAS_RESET;
	enSig <= en or not HAS_EN;
	
	SEQUENCING_PART: entity work.UnitSequencer(Behavioral)
	port map (
		clk => clk, reset => resetSig, en => enSig,
		
		-- sys reg interface
		sysRegReadSel => sysRegReadSel,
		sysRegReadValue => sysRegReadValue,	
			 sysStoreAllow => sysStoreAllow,
			 sysStoreAddress => sysStoreAddress,
			 sysStoreValue => sysStoreValue,

		-- Icache interface
		iadr => iadr,
		iadrvalid => iadrvalid,		
		
		-- to front pipe
		frontAccepting => acceptingOutFront,
		pcDataLiving => pcDataSig,
		pcSending => pcSendingSig,

		-- Events in
		intSignal => int0,
		start => int1,		
		execEventSignal => execEventSignal,
		execCausing => execCausing,
		stage0EventInfo => stage0Events, -- from front
		-- Events out
		execOrIntEventSignalOut => execOrIntEventSignal,
		execOrIntCausingOut => execOrIntCausing,
		lateEventOut => lateEventSignal,
		-- Data from front pipe interface		
		renameAccepting => renameAccepting, -- to frontend
		frontLastSending => frontLastSending,
		frontDataLastLiving => frontDataLastLiving,

		-- Interface from register mapping
		newPhysDestsIn => newPhysDests,
		newPhysDestPointerIn => newPhysDestPointer,
		newPhysSourcesIn => newPhysSources,

		-- Interface with IQ
		iqAccepts => iqAccepts,
		renamedDataLiving => renamedDataLiving, -- !!!
		renamedSending => renamedSending,
		
		-- Interface from ROB
		commitAccepting => commitAccepting,
		sendingFromROB => robSending,	
		robDataLiving => dataOutROB,
		committing => committingSig,

		---
		--sendingFromBQ => sendingFromBQ,
		dataFromBQV => dataOutBQV,

		sbSending => sbSending,
		dataFromSB => dataFromSB,
		sbEmpty => sbEmpty,

		-- Interface from committed stage
		committedSending => committedSending,
		committedDataOut => committedDataOut,
		renameLockEndOut => renameLockEnd,
				
		commitGroupCtrOut => commitGroupCtrSig,
		commitGroupCtrNextOut => commitGroupCtrNextSig,	
		commitGroupCtrIncOut => commitGroupCtrIncSig
	);
		
	FRONT_PART: entity work.UnitFront(Behavioral)
	port map(
		clk => clk, reset => resetSig, en => enSig,
		
		iin => iin,
		ivalid => ivalid,
					
		pcDataLiving => pcDataSig,
		pcSending => pcSendingSig,	
		frontAccepting => acceptingOutFront,

		renameAccepting => renameAccepting,			
		dataLastLiving => frontDataLastLiving,
		lastSending => frontLastSending,
		
		stage0EventsOut => stage0Events,
		execEventSignal => execEventSignal,
		lateEventSignal => lateEventSignal		
	);


	--------------------------------
	--- Out of order domain
		
	
	OUTER_OOO_AREA: block
			signal cqMaskOut: std_logic_vector(0 to INTEGER_WRITE_WIDTH-1) := (others => '0');
			signal cqDataOut: InstructionStateArray(0 to INTEGER_WRITE_WIDTH-1)
					:= (others => DEFAULT_INSTRUCTION_STATE);
			signal readyRegFlags: std_logic_vector(0 to 3*PIPE_WIDTH-1) := (others => '0');		
			signal readyRegFlagsNext: std_logic_vector(0 to 3*PIPE_WIDTH-1) := (others => '0');					
	begin

		OOO_BOX: entity work.OutOfOrderBox(Behavioral)
		port map(
				  clk => clk, reset => resetSig, en => enSig,
				  
				  renamedDataLiving => renamedDataLiving,--: in StageDataMulti;	-- INPUT			
				  renamedSending => renamedSending,--: in std_logic;
				  
				  iqAccepts => open,--: out std_logic; -- OUTPUT

		-- Sys reg interface	
				  sysRegReadSel => open,--: out slv5; -- OUTPUT  -- Doesn't need to be a port of OOO part
				  sysRegReadValue => sysRegReadValue,--: in Mword; -- INPUT

		-- Mem interface
				  memLoadAddressOut => open,--: out Mword;
				  memLoadValue => memLoadValue,--: in Mword;
				  memLoadAllow => open,--: out std_logic;
				  memLoadReady => memLoadReady,--: in std_logic;

		-- evt
				 execEventSignalOut => open,--: out std_logic; -- OUTPUT/SIG
				 lateEventSignal => lateEventSignal,--: in std_logic;
				 execCausingOut => open,--: out InstructionState;

		-- Hidden to some degree, but may be useful for sth
				commitGroupCtrSig => commitGroupCtrSig,--: in SmallNumber;
				commitGroupCtrNextSig => commitGroupCtrNextSig,--: in SmallNumber; -- INPUT
				commitGroupCtrIncSig => commitGroupCtrIncSig,--: in SmallNumber;	-- INPUT
													
		-- ROB interface	
				robSendingOut => open,--: out std_logic;		-- OUTPUT
				dataOutROB => open,--: out StageDataMulti;		-- OUTPUT

				sbAccepting => sbAccepting,--: in std_logic;	-- INPUT
				commitAccepting => commitAccepting,--: in std_logic; -- INPUT

				dataOutBQV => open,--: out StageDataMulti; -- OUTPUT
				dataOutSQ => open, --: out StageDataMulti -- OUTPUT		
				
				readyRegFlags => readyRegFlags,
				
				cqMaskOut => open,
				cqDataOut => open			
		);


		INNER_OOO_AREA: block
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
				
		begin
			
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

					
		
			IQ_A: entity work.UnitIQ
			generic map(
				IQ_SIZE => IQ_A_SIZE
			)
			port map(
				clk => clk, reset => resetSig, en => enSig,

				acceptingVec => acceptingVecA,

				prevSendingOK => renamedSending,
				newData => dataToA,

				fni => fni,
				
				readyRegFlags => readyRegFlags,
				regsForDispatch => regsSelA,
				regValues => regValsA,
					
				nextAccepting => execAcceptingA,			
				dataOutIQ => dataOutIQA,
				sendingOut => sendingSchedA,
					
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

				acceptingVec => acceptingVecB,		
				
				prevSendingOK => renamedSending,
				newData => dataToB,		

				fni => fni,	
						
				readyRegFlags => readyRegFlags,		
				regsForDispatch => regsSelB,
				regValues => regValsB,
				
				nextAccepting => execAcceptingB,	
				dataOutIQ => dataOutIQB,
				sendingOut => sendingSchedB,		
				
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

				acceptingVec => acceptingVecC,		

				prevSendingOK => renamedSending,
				newData => dataToC,			

				fni => fni,
						
				readyRegFlags => readyRegFlags,
				regsForDispatch => regsSelC,
				regValues => regValsC,
					
				nextAccepting => execAcceptingC,
				dataOutIQ => dataOutIQC,
				sendingOut => sendingSchedC,		
				
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

				acceptingVec => acceptingVecD,		

				prevSendingOK => renamedSending,
				newData => dataToD,

				fni => fni,
						
				readyRegFlags => readyRegFlags,
				
				regsForDispatch => regsSelD,
				regValues => regValsD,
					
				nextAccepting => execAcceptingD,
				dataOutIQ => dataOutIQD,
				sendingOut => sendingSchedD,		
				
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

				acceptingVec => acceptingVecE,		
				prevSendingOK => renamedSending,
				newData => dataToE,

				nextAccepting => execAcceptingE,
				dataOutIQ => dataOutIQE,
				sendingOut => sendingSchedE,
						
				fni => fni,	
						
				readyRegFlags => readyRegFlags, -- bits generated for input group
				
				-- Interface for reading registers
				regsForDispatch => regsSelE,
				regValues => regValsE,		
				
				execCausing => execCausing,
					lateEventSignal => lateEventSignal,
				execEventSignal => execEventSignal
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
					cqMaskOut => cqMaskOut,
					cqDataOut => cqDataOut,
						bufferMaskOut => cqBufferMask,
						bufferDataOut => cqBufferData
			);
				
					cqDataLivingOut.fullMask(0) <= cqMaskOut(0);
					cqDataLivingOut.data(0) <= cqDataOut(0);

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

					rfWriteVec(0 to INTEGER_WRITE_WIDTH-1) <= getArrayDestMask(cqDataOut, cqMaskOut);
					rfSelectWrite(0 to INTEGER_WRITE_WIDTH-1) <= getArrayPhysicalDests(cqDataOut);
					rfWriteValues(0 to INTEGER_WRITE_WIDTH-1) <= getArrayResults(cqDataOut);
				
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
		--end block;

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
		end block;


				INT_READY_TABLE: entity work.ReadyRegisterTable(Behavioral)
				generic map(
					WRITE_WIDTH => INTEGER_WRITE_WIDTH
				)
				port map(
					clk => clk, reset => resetSig, en => enSig, 
					
					sendingToReserve => frontLastSending,
					stageDataToReserve => frontDataLastLiving,
						
					newPhysDests => newPhysDests,	-- FOR MAPPING
					stageDataReserved => renamedDataLiving, --stageDataOutRename,
					
						writingMask => cqMaskOut,
						writingData => cqDataOut,
					readyRegFlagsNext => readyRegFlagsNext -- FOR IQs
				);

				READY_REGS_SYNCHRONOUS: process(clk) 	
				begin
					if rising_edge(clk) then
						readyRegFlags <= readyRegFlagsNext;
					end if;
				end process;

			
		INT_REG_MAPPING: block
			signal physStable, physStableDelayed: PhysNameArray(0 to PIPE_WIDTH-1) := (others=>(others=>'0'));
		begin
					INT_MAPPER: entity work.RegisterMappingUnit(Behavioral)
					port map(
						clk => clk,
						reset => resetSig,
						en => enSig,
						
						rewind => renameLockEnd,	-- FROM SEQ
						causingInstruction => DEFAULT_INSTRUCTION_STATE,
						
						sendingToReserve => frontLastSending,
						stageDataToReserve => frontDataLastLiving,
						newPhysDests => newPhysDests,	-- MAPPING (from FREE LIST)

						sendingToCommit => robSending,
						stageDataToCommit => dataOutROB,
						physCommitDests_TMP => (others => (others => '0')), -- CAREFUL: useless input?
						
						prevNewPhysDests => open,
						newPhysSources => newPhysSources,	-- TO SEQ
						
						prevStablePhysDests => physStable,  -- FOR MAPPING (to FREE LIST)
						stablePhysSources => open							
					);

				LAST_COMMITTED_SYNCHRONOUS: process(clk) 	
				begin
					if rising_edge(clk) then
						-- CAREFUL! When writing the same virtual reg multiple times, to get a vector to put on FreeList,
						-- 			we either A) bypass phys dests to next instructions instead of reading stable map, 
						--				or B) don't bypass but select to put the phys dests for all but the last writing op,
						--				and that last one returns the stable map entry.
						--				Option A means that below we substitute relevant phys names, and B means that
						--				we don't, and handle overridden dests by seleciton bits in RegisterFreeList.
						physStableDelayed <= work.ProcLogicRenaming.getStableDestsParallel(dataOutROB, physStable);					
					end if;
				end process;
		
				INT_FREE_LIST: entity work.RegisterFreeList(Behavioral)
				port map(
					clk => clk,
					reset => resetSig,
					en => enSig,
					
					rewind => execOrIntEventSignal,
					causingInstruction => execOrIntCausing,
					
					sendingToReserve => frontLastSending, 
					takeAllow => frontLastSending,	-- FROM SEQ
						auxTakeAllow => renameLockEnd,
					stageDataToReserve => frontDataLastLiving,
					
					newPhysDests => newPhysDests,			-- TO SEQ
					newPhysDestPointer => newPhysDestPointer, -- TO SEQ

					sendingToRelease => committedSending,  -- FROM SEQ
					stageDataToRelease => committedDataOut,  -- FROM SEQ
					
					physStableDelayed => physStableDelayed -- FOR MAPPING (from MAP)
				);		

			end block;
	
	end block; -- OUTER_OOO


					sbAccepting <= sbAcceptingV(0);

					STORE_BUFFER: entity work.TestCQPart0(WriteBuffer)
					generic map(
						INPUT_WIDTH => PIPE_WIDTH,
						QUEUE_SIZE => SB_SIZE,
						OUTPUT_SIZE => 1
					)
					port map(
						clk => clk, reset => reset, en => en,
						
						whichAcceptedCQ => sbAcceptingV,
						maskIn => dataOutSQ.fullMask,
						dataIn => dataOutSQ.data,
						
						bufferMaskOut => sbFullMask,
						bufferDataOut => open,
						
						anySending => sbSending,
						cqMaskOut => sbMaskOut,
						cqDataOut => sbDataOut,
						
						execEventSignal => '0',
						execCausing => DEFAULT_INSTRUCTION_STATE
					);

				sbEmpty <= not sbFullMask(0);
				dataFromSB <= sbDataOut(0);

				memStoreAddress <= sbDataOut(0).argValues.arg1;
				memStoreValue <= sbDataOut(0).argValues.arg2;
				memStoreAllow <= sbSending when sbDataOut(0).operation = (Memory, store) else '0';
				
				sysStoreAllow <= sbSending when sbDataOut(0).operation = (System, sysMTC) 
							 else '0'; 
				sysStoreAddress <= sbDataOut(0).argValues.arg1(4 downto 0);
				sysStoreValue <= sbDataOut(0).argValues.arg2;				


	dadr <= memLoadAddress;
	doutadr <= memStoreAddress;
	dread <= memLoadAllow;
	dwrite <= memStoreAllow;
	dout <= memStoreValue;
	memLoadValue <= din;
	memLoadReady <= dvalid;

end Behavioral5;

