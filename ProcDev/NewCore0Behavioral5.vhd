
-- CAREFUL! If partial kill occurs, we have to check if any slot of the stage remains alive,
--				and if no one, then generate killAll signal for that stage! 

architecture Behavioral5 of NewCore0 is	
	signal resetSig, enSig: std_logic := '0';				
				
	signal pcDataSig: InstructionState := DEFAULT_INSTRUCTION_STATE;
	signal pcSendingSig: std_logic := '0';

	signal frontDataLastLiving: StageDataMulti;
	signal frontLastSending, renameAccepting: std_logic := '0';

	signal acceptingOutFront: std_logic := '0';
	signal stage0Events: StageMultiEventInfo;
		
	-- for Front
	signal killVec: std_logic_vector(0 to N_EVENT_AREAS-1) := (others => '0');	

	signal renamedDataLiving, stageDataCommittedOut: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;				
	signal renamedSending, iqAccepts: std_logic := '0';			
		
	-- CAREFUL, TODO: make this robust for changes in renaming details!
	signal readyRegs, readyRegsSig, readyRegsPrev: std_logic_vector(0 to N_PHYSICAL_REGS-1)
		:= (0 to 31 => '1', others=>'0'); -- p0-p31 are initially mapped to logical regs and ready
		
	signal dataToA, dataToB, dataToC, dataToD, dataToE: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;						

	signal acceptingVecA, acceptingVecB, acceptingVecC, acceptingVecD, acceptingVecE:
				std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
	
	signal compactedToSQ, compactedToLQ, compactedToBQ: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
		signal cc0, cc1: std_logic := '0';

	signal dataOutIQA, dataOutIQB, dataOutIQC, dataOutIQD, dataOutIQE: InstructionState
																	:= defaultInstructionState;	
	signal sendingSchedA, sendingSchedB, sendingSchedC, sendingSchedD, sendingSchedE: std_logic := '0';
	
	-- Physical register interface
	signal regsSelA, regsSelB, regsSelC, regsSelD, regsSelE, regsSelCE: PhysNameArray(0 to 2)
					:= (others => (others => '0'));
	signal regValsA, regValsB, regValsC, regValsD, regValsE, regValsCE: MwordArray(0 to 2)
							:= (others => (others => '0'));
	signal regsAllowA, regsAllowB, regsAllowC, regsAllowD, regsAllowE, regsAllowCE,
			execAcceptingA, execAcceptingB, execAcceptingC, execAcceptingD, execAcceptingE: std_logic := '0'; 
	
	-- forw network
	-- writtenTags indicate registers written to GPR file in last cycle, so they can be read from there
	--		rather than from forw. network, but readyRegFlags are not available in the 1st cycle after WB.
	signal writtenTags: PhysNameArray(0 to PIPE_WIDTH-1) := (others => (others => '0'));

	signal fni: ForwardingInfo := DEFAULT_FORWARDING_INFO;

	signal execEnds, execEnds2: InstructionStateArray(0 to 3) := (others => DEFAULT_INSTRUCTION_STATE);
	signal execPreEnds: InstructionStateArray(0 to 3) := (others => DEFAULT_INSTRUCTION_STATE);
	signal execSending, execSending2: std_logic_vector(0 to 3) := (others => '0');

	-- Mem interface
	signal memLoadAddress, memStoreAddress, memLoadValue, memStoreValue: Mword := (others => '0');
	signal memStoreAllow, memLoadAllow, memLoadReady: std_logic := '0';
		
	-- Sys reg interface	
	signal sysRegReadSel: slv5 := (others => '0');
	signal sysRegReadValue: Mword := (others => '0');
	
	-- evt
	signal execEventSignal, execOrIntEventSignal: std_logic := '0';					
	-- This will take the value of operation that causes jump or exception
	signal execCausing, execOrIntCausing: InstructionState := defaultInstructionState;																		

	-- Hidden to some degree, but may be useful for sth
	signal renameCtrSig, renameCtrNextSig, commitCtrSig, commitCtrNextSig: SmallNumber := (others=>'0');
	signal commitGroupCtrSig, commitGroupCtrNextSig: SmallNumber := (others => '0');
	signal commitGroupCtrIncSig: SmallNumber := (others => '0');
												
	-- ROB interface	
	signal robSending, robAccepting: std_logic := '0';
	signal dataOutROB: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;					

		signal sbAccepting, sbEmpty, sbSending: std_logic := '0';
			signal dataFromSB: InstructionState := DEFAULT_INSTRUCTION_STATE;
			
		signal commitAccepting: std_logic := '0';
		signal committingSig: std_logic := '0';

		signal acceptingNewSQ, acceptingNewLQ, acceptingNewBQ: std_logic := '0';
		signal sendingQueueE: std_logic := '0';

			signal sendingFromBQ: std_logic := '0';
			signal dataOutBQ: InstructionState := DEFAULT_INSTRUCTION_STATE;
			signal dataOutBQV: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

	-- back end interfaces
	signal whichAcceptedCQ: std_logic_vector(0 to 3) := (others=>'0');	
	signal anySendingFromCQ: std_logic := '0';
	
		signal cqBufferMask: std_logic_vector(0 to CQ_SIZE-1) := (others => '0');
		signal cqBufferData: InstructionStateArray(0 to CQ_SIZE-1) := (others => DEFAULT_INSTRUCTION_STATE);
	signal cqDataLivingOut: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

		signal cqMaskOut: std_logic_vector(0 to INTEGER_WRITE_WIDTH-1) := (others => '0');
		signal cqDataOut: InstructionStateArray(0 to INTEGER_WRITE_WIDTH-1) := (others => DEFAULT_INSTRUCTION_STATE);

	signal rfWriteVec: std_logic_vector(0 to 3) := (others => '0');
	signal rfSelectWrite: PhysNameArray(0 to 3) := (others => (others => '0'));
	signal rfWriteValues: MwordArray(0 to 3) := (others => (others => '0'));
	
	signal stageDataAfterCQ: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;	
				
		signal newPhysDests: PhysNameArray(0 to PIPE_WIDTH-1) := (others => (others => '0'));
		signal newPhysDestPointer: SmallNumber := (others => '0');
		signal newPhysSources: PhysNameArray(0 to 3*PIPE_WIDTH-1) := (others => (others => '0'));
			
		signal committedSending, renameLockEnd: std_logic := '0';
		signal committedDataOut: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

	signal readyRegFlags, readyRegFlagsV: std_logic_vector(0 to 3*PIPE_WIDTH-1) := (others => '0');
			
		signal readyRegFlags_2: std_logic_vector(0 to 3*PIPE_WIDTH-1) := (others => '0');
		signal readyRegFlagsNext, readyRegFlagsNextV: std_logic_vector(0 to 3*PIPE_WIDTH-1) := (others => '0');					
						
		signal sysRegData: InstructionState := DEFAULT_INSTRUCTION_STATE;
		signal sysRegSending: std_logic := '0';
						
	signal outputA, outputB, outputC, outputD, outputE: InstructionSlot := DEFAULT_INSTRUCTION_SLOT;
	signal outputOpPreB, outputOpPreC: InstructionState := DEFAULT_INSTRUCTION_STATE;

		signal sysStoreAllow: std_logic := '0';
		signal sysStoreAddress: slv5 := (others => '0'); 
		signal sysStoreValue: Mword := (others => '0');
			
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
		killVecOut => killVec,
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

		-- Signal about ready regs (version with virtual ready bits!)
		readyRegFlagsNextV => readyRegFlagsNextV,
		
		-- Interface from ROB
		commitAccepting => commitAccepting,
		sendingFromROB => robSending,	
		robDataLiving => dataOutROB,
		committing => committingSig,

		---
		sendingFromBQ => sendingFromBQ,
			dataFromBQV => dataOutBQV,
		dataFromBQ => dataOutBQ,

				sendingFromSB => '0',
				dataFromSB => dataFromSB,
					sbEmpty => sbEmpty,
				sbSending => sbSending,

			 sysStoreAllow => sysStoreAllow,
			 sysStoreAddress => sysStoreAddress,
			 sysStoreValue => sysStoreValue,

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
		killVector => killVec		
	);
	
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
		regReadAllow => regsAllowA,	
		regValues => regValsA,
			
		nextAccepting => execAcceptingA,			
		dataOutIQ => dataOutIQA,
		sendingOut => sendingSchedA,
			
		execCausing => execOrIntCausing,
		execEventSignal => execOrIntEventSignal			
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
		regReadAllow => regsAllowB,
		regValues => regValsB,
		
		nextAccepting => execAcceptingB,	
		dataOutIQ => dataOutIQB,
		sendingOut => sendingSchedB,		
		
		execCausing => execOrIntCausing,
		execEventSignal => execOrIntEventSignal
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
		regReadAllow => regsAllowC,	
		regValues => regValsC,
			
		nextAccepting => execAcceptingC,
		dataOutIQ => dataOutIQC,
		sendingOut => sendingSchedC,		
		
		execCausing => execOrIntCausing,
		execEventSignal => execOrIntEventSignal
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
		regReadAllow => regsAllowD,
		regValues => regValsD,
			
		nextAccepting => execAcceptingD,
		dataOutIQ => dataOutIQD,
		sendingOut => sendingSchedD,		
		
		execCausing => execOrIntCausing,
		execEventSignal => execOrIntEventSignal
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
		regReadAllow => regsAllowE, -- TODO: change to individual for each port
		regValues => regValsE,		
		
		execCausing => execOrIntCausing,
		execEventSignal => execOrIntEventSignal
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
			
		sysRegSelect => sysRegReadSel,
		sysRegIn => sysRegReadValue,
		--sysRegWriteSelOut => sysRegWriteSel,
		--sysRegWriteValueOut => sysRegWriteValue,

		sysRegDataOut => sysRegData,
		sysRegSending => sysRegSending,
		
		whichAcceptedCQ => whichAcceptedCQ,
		
		acceptingNewBQ => acceptingNewBQ,
		sendingOutBQ => sendingFromBQ,
			dataOutBQV => dataOutBQV,
		dataOutBQ => dataOutBQ,
		prevSendingToBQ => renamedSending,
		dataNewToBQ => compactedToBQ,
			
		committing => committingSig,
			
		groupCtrNext => commitGroupCtrNextSig,
		groupCtrInc => commitGroupCtrIncSig,
		
		execEvent => execEventSignal,
		execCausingOut => execCausing,
				
		execOrIntEventSignalIn => execOrIntEventSignal,
		execOrIntCausingIn => execOrIntCausing
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

			memLoadReady => memLoadReady,
			memLoadValue => memLoadValue,
			
			memLoadAddress => memLoadAddress,
			memStoreAddress => memStoreAddress,
			memLoadAllow => memLoadAllow,
			memStoreAllow => memStoreAllow,
			memStoreValue => memStoreValue,

				sysStoreAllow => sysStoreAllow,
				sysStoreAddress => sysStoreAddress,
				sysStoreValue => sysStoreValue,

			sysRegDataIn => sysRegData,
			sysRegSendingIn => sysRegSending,

			committing => committingSig,
			groupCtrNext => commitGroupCtrNextSig,
			
			groupCtrInc => commitGroupCtrIncSig,

				sbAccepting => sbAccepting,
					sbEmpty => sbEmpty,
					sbSendingOut => sbSending,
					dataFromSB => dataFromSB,
				
				dataBQV => dataOutBQV,
					
			execOrIntEventSignalIn => execOrIntEventSignal,
			execOrIntCausingIn => execOrIntCausing
		);

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
		
		execEventSignal => execOrIntEventSignal,
		execCausing => execOrIntCausing,
		
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
					stablePhysSources => open,
						
					readyRegFlagsNext => readyRegFlagsNextV
				);

			LAST_COMMITTED_SYNCHRONOUS: process(clk) 	
			begin
				if rising_edge(clk) then
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
					readyRegFlags_2 <= readyRegFlagsNext;
					--	readyRegFlagsV <= readyRegFlagsNextV;
				end if;
			end process;

			readyRegFlags <= readyRegFlags_2;		
		end block;
	
		-- CAREFUL! This stage is needed to keep result tags 1 for cycle when writing to reg file,
		--				so that "black hole" of invisible readiness doesn't occur
		AFTER_CQ: entity work.GenericStageMulti(Behavioral) port map(
			clk => clk, reset => resetSig, en => enSig,
			
			prevSending => anySendingFromCQ,
			nextAccepting => '1',
			execEventSignal => '0',
			execCausing => execCausing,
			stageDataIn => cqDataLivingOut,
			acceptingOut => open,
			sendingOut => open,
			stageDataOut => stageDataAfterCQ,
			
			lockCommand => '0'			
		);
			
		-- Int register block
			regsSelCE(0 to 1) <= regsSelC(0 to 1);
			regsSelCE(2) <= regsSelE(2);
			regsAllowCE <= regsAllowC or regsAllowE;
				regValsC(0 to 1) <= regValsCE(0 to 1);
				regValsE(2) <= regValsCE(2);	

			rfWriteVec(0 to INTEGER_WRITE_WIDTH-1) <= getArrayDestMask(cqDataOut, cqMaskOut);
			rfSelectWrite(0 to INTEGER_WRITE_WIDTH-1) <= getArrayPhysicalDests(cqDataOut);
			rfWriteValues(0 to INTEGER_WRITE_WIDTH-1) <= getArrayResults(cqDataOut);
		
		GPR_FILE_DISPATCH: entity work.RegisterFile0 (Behavioral)
																	--(Implem)
		generic map(WIDTH => 4, WRITE_WIDTH => INTEGER_WRITE_WIDTH)
		port map(
			clk => clk, reset => resetSig, en => enSig,
				
			writeAllow => --anySendingFromCQ,
								'1',
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
	
	REORDER_BUFFER: entity work.ReorderBuffer --(Behavioral) 
															(Implem)
	port map(
		clk => clk, reset => resetSig, en => enSig,
		
		intSignal => '0',
		execEventSignal => execOrIntEventSignal,
		execCausing => execOrIntCausing,
		
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
	
	
	WRITTEN_TAG_GEN: if CQ_SINGLE_OUTPUT generate
		writtenTags <= getWrittenTags(stageDataAfterCQ);
	end generate;
	
		fni.writtenTags <= writtenTags;
		fni.resultTags <= getResultTags(execEnds, cqBufferData, dataOutIQA, dataOutIQB, dataOutIQC, dataOutIQD,
																											DEFAULT_STAGE_DATA_MULTI);
		fni.nextResultTags <= getNextResultTags(execPreEnds, dataOutIQA, dataOutIQB, dataOutIQC, dataOutIQD);
		fni.resultValues <= getResultValues(execEnds, cqBufferData, DEFAULT_STAGE_DATA_MULTI);
	
	dadr <= memLoadAddress;
	doutadr <= memStoreAddress;
	dread <= memLoadAllow;
	dwrite <= memStoreAllow;
	dout <= memStoreValue;
	memLoadValue <= din;
	memLoadReady <= dvalid;

end Behavioral5;

