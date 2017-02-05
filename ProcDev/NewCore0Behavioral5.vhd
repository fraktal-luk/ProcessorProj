
-- CAREFUL! If partial kill occurs, we have to check if any slot of the stage remains alive,
--				and if no one, then generate killAll signal for that stage! 

architecture Behavioral5 of NewCore0 is	
	signal resetSig, enSig: std_logic := '0';				
				
	signal pcDataSig: InstructionState := DEFAULT_INSTRUCTION_STATE;
	signal pcSendingSig: std_logic := '0';
				
	signal frontDataLastLiving: StageDataMulti;
	signal frontLastSending: std_logic := '0';		
	signal renameAccepting: std_logic := '0';

	signal acceptingOutFront: std_logic := '0';
	signal stage0Events: StageMultiEventInfo;
		
	-- for Front
	signal killVec: std_logic_vector(0 to N_EVENT_AREAS-1) := (others => '0');	

	signal renamedDataLiving, stageDataCommittedOut: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;				
	signal renamedSending: std_logic := '0';			
		
	-- CAREFUL, TODO: make this robust for changes in renaming details!
	signal readyRegs, readyRegsSig, readyRegsPrev: std_logic_vector(0 to N_PHYSICAL_REGS-1)
		:= (0 to 31 => '1', others=>'0'); -- p0-p31 are initially mapped to logical regs and ready
		
	signal dataToA, dataToB, dataToC, dataToD, dataToE: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;						

	signal acceptingA, acceptingB, acceptingC, acceptingD, acceptingE: SmallNumber := (others=>'0');
		signal acceptingVecA, acceptingVecB, acceptingVecC, acceptingVecD, acceptingVecE:
				std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
	signal prevSendingA, prevSendingB, prevSendingC, prevSendingD, prevSendingE: SmallNumber := (others=>'0');
	
	signal iqAccepts: std_logic := '0';	
		
	signal dataOutIQA, dataOutIQB, dataOutIQC, dataOutIQD, dataOutIQE: InstructionState
																	:= defaultInstructionState;	
	signal sendingSchedA, sendingSchedB, sendingSchedC, sendingSchedD, sendingSchedE: std_logic := '0';
	
	-- Physical register interface
	signal regsSelA, regsSelB, regsSelC, regsSelD, regsSelE, regsSelCE: PhysNameArray(0 to 2)
					:= (others => (others => '0'));
	signal regValsA, regValsB, regValsC, regValsD, regValsE, regValsCE: MwordArray(0 to 2)
							:= (others => (others => '0'));
	signal regsAllowA, regsAllowB, regsAllowC, regsAllowD, regsAllowE, regsAllowCE: std_logic := '0';

	signal execAcceptingA, execAcceptingB, execAcceptingC, execAcceptingD, execAcceptingE: std_logic := '0'; 
	
	-- forw network
	signal resultTags: PhysNameArray(0 to N_RES_TAGS-1) := (others=>(others=>'0'));
	signal nextResultTags: PhysNameArray(0 to N_NEXT_RES_TAGS-1) := (others=>(others=>'0'));
	signal resultVals: MwordArray(0 to N_RES_TAGS-1) := (others=>(others=>'0'));	
	-- writtenTags indicate registers written to GPR file in last cycle, so they can be read from there
	--		rather than from forw. network, but readyRegFlags are not available in the 1st cycle after WB.
	signal writtenTags: PhysNameArray(0 to PIPE_WIDTH-1) := (others => (others => '0'));
	
	
	signal execEnds, execEnds2: InstructionStateArray(0 to 3);
	signal execPreEnds: InstructionStateArray(0 to 3); -- For 'nextResultTags'
	signal execSending, execSending2: std_logic_vector(0 to 3);
	
	-- Mem interface
	signal memLoadAddress, memStoreAddress, memLoadValue, memStoreValue: Mword := (others => '0');
	signal memStoreAllow, memLoadAllow, memLoadReady: std_logic := '0';
		
	-- Sys reg interface	
	signal sysRegReadSel, sysRegWriteSel: slv5 := (others => '0');
	signal sysRegReadValue, sysRegWriteValue: Mword := (others => '0');
	
	-- evt
	signal execEventSignal, intSig, execOrIntEventSignal: std_logic := '0';						
	-- This will take the value of operation that causes jump or exception
	signal execCausing, intCausing, execOrIntCausing: InstructionState := defaultInstructionState;																			

	-- Hidden to some degree, but may be useful for sth
	signal renameCtrSig, renameCtrNextSig, commitCtrSig, commitCtrNextSig: SmallNumber := (others=>'0');
	signal commitGroupCtrSig, commitGroupCtrNextSig: SmallNumber := (others => '0');
												
	-- ROB interface	
	signal robSending, robAccepting: std_logic := '0';
	signal dataOutROB: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;					

	-- back end interfaces
	signal selectedToCQ, whichAcceptedCQ: std_logic_vector(0 to 3) := (others=>'0');	
	signal anySendingFromCQ: std_logic := '0';
	
	signal dataCQOut: StageDataCommitQueue
										:= (fullMask=>(others=>'0'), data=>(others=>defaultInstructionState));	
	signal cqDataLivingOut: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

	signal cqPhysDestMask: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
	signal cqPhysicalDests: PhysNameArray(0 to PIPE_WIDTH-1) := (others => (others => '0'));
	signal cqInstructionResults: MwordArray(0 to PIPE_WIDTH-1) := (others => (others => '0'));

	signal rfWriteVec: std_logic_vector(0 to 3) := (others => '0');
	signal rfSelectWrite: PhysNameArray(0 to 3) := (others => (others => '0'));
	signal rfWriteValues: MwordArray(0 to 3) := (others => (others => '0'));
	
	signal stageDataAfterCQ: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;	
				
		signal newPhysDests: PhysNameArray(0 to PIPE_WIDTH-1) := (others => (others => '0'));
		signal newPhysDestPointer: SmallNumber := (others => '0');
		signal newPhysSources: PhysNameArray(0 to 3*PIPE_WIDTH-1) := (others => (others => '0'));
			
		signal committedSending: std_logic := '0';
		signal committedDataOut: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
		signal renameLockEnd: std_logic := '0';

	signal readyRegFlags, readyRegFlagsV: std_logic_vector(0 to 3*PIPE_WIDTH-1) := (others => '0');
			
		signal readyRegFlags_2: std_logic_vector(0 to 3*PIPE_WIDTH-1) := (others => '0');
		signal readyRegFlagsNext, readyRegFlagsNextV: std_logic_vector(0 to 3*PIPE_WIDTH-1) := (others => '0');					
						
	-- CAREFUL: this is used to turn off dependence on iqAccepts
	constant	OMIT_IQ_ACCEPTS: std_logic := '0';			
				
	constant HAS_RESET: std_logic := '0';
	constant HAS_EN: std_logic := '0';
begin
	resetSig <= reset and HAS_RESET;
	enSig <= en or not HAS_EN;
	
	intSig <= '0'; -- CAREFUL!
	
	SEQUENCING_PART: entity work.UnitSequencer(Behavioral)
	port map (
		clk => clk, reset => resetSig, en => enSig,

		sysRegReadSel => sysRegReadSel,
		sysRegReadValue => sysRegReadValue,	
		sysRegWriteSel => sysRegWriteSel,
		sysRegWriteValue => sysRegWriteValue,

		-- Icache interface
		iadr => iadr,
		iadrvalid => iadrvalid,		

		frontAccepting => acceptingOutFront,
		pcDataLiving => pcDataSig,
		pcSending => pcSendingSig,

		stage0EventInfo => stage0Events, -- from front
					
		intSignal => int0,
		execEventSignal => execEventSignal,
		execCausing => execCausing,
		
		execOrIntEventSignalOut => execOrIntEventSignal,
		execOrIntCausingOut => execOrIntCausing,
		killVecOut => killVec,
				
		renameAccepting => renameAccepting, -- to frontend
		frontLastSending => frontLastSending,
		frontDataLastLiving => frontDataLastLiving,

		sendingFromROB => robSending,	
		robDataLiving => dataOutROB,
				
		-- Interface with IQ
				-- CAREFUL: iqAccepts is needed here, but must be faster (based on 'full' instead of 'living')
		iqAccepts => robAccepting and (iqAccepts or OMIT_IQ_ACCEPTS),
		renamedDataLiving => renamedDataLiving, -- !!!
		renamedSending => renamedSending,
				
		commitGroupCtrOut => commitGroupCtrSig,
		commitGroupCtrNextOut => commitGroupCtrNextSig,

			committedSending => committedSending,
			committedDataOut => committedDataOut,
			renameLockEndOut => renameLockEnd,

			newPhysDestsIn => newPhysDests,
			newPhysDestPointerIn => newPhysDestPointer,
			newPhysSourcesIn => newPhysSources,

				readyRegFlagsNextV => readyRegFlagsNextV,

		start => int1	
	);
	
		
	FRONT_PART: entity work.UnitFront(Behavioral)
	port map(
		clk => clk, reset => resetSig, en => enSig,
		iin => iin,
			ivalid => ivalid,
		renameAccepting => renameAccepting,
					
			pcDataLiving => pcDataSig,
			pcSending => pcSendingSig,
			
			frontAccepting => acceptingOutFront,
	
			stage0EventsOut => stage0Events,
	
			killVector => killVec,
			
		dataLastLiving => frontDataLastLiving,
		lastSending => frontLastSending
	);

	
	ISSUE_ROUTING: entity work.SubunitIssueRouting(Behavioral)
	port map(
		renamedDataLiving => renamedDataLiving,
		
		acceptingA => acceptingA,
		acceptingB => acceptingB,
		acceptingC => acceptingC,
		acceptingD => acceptingD,
		acceptingE => acceptingE, --num2flow(1),		
		
			acceptingVecA => acceptingVecA,
			acceptingVecB => acceptingVecB,
			acceptingVecC => acceptingVecC,
			acceptingVecD => acceptingVecD,
			acceptingVecE => acceptingVecE,
		
		renamedSendingIn => renamedSending,
		
		renamedSendingOut => open, -- DEPREC??
		iqAccepts => iqAccepts,
		
		sendingA => prevSendingA,
		sendingB => prevSendingB,
		sendingC => prevSendingC,
		sendingD => prevSendingD,
		sendingE => prevSendingE,		
		
		dataOutA => dataToA,
		dataOutB => dataToB,
		dataOutC => dataToC,
		dataOutD => dataToD,
		dataOutE => dataToE
	);


	IQ_A: entity work.UnitIQ
	generic map(
		IQ_SIZE => IQ_A_SIZE
	)
	port map(
		clk => clk, reset => resetSig, en => enSig,

		writtenTags => writtenTags,		
		resultTags => resultTags,
		nextResultTags => nextResultTags,
		resultVals => resultVals,

		prevSending => prevSendingA,
		prevSendingOK => renamedSending,
		
		nextAccepting => execAcceptingA,
		
		newData => dataToA,		
		
		execCausing => execOrIntCausing,
		execEventSignal => execOrIntEventSignal,
			
			readyRegFlags => readyRegFlags,
			
			regsForDispatch => regsSelA,
			regReadAllow => regsAllowA,
			
			regValues => regValsA,
			
		accepting => acceptingA,
			acceptingVec => acceptingVecA,
		dataOutIQ => dataOutIQA,
			sendingOut => sendingSchedA
	);
	
	IQ_B: entity work.UnitIQ
	generic map(
		IQ_SIZE => IQ_B_SIZE
	)
	port map(
		clk => clk, reset => resetSig, en => enSig,
		
		writtenTags => writtenTags,		
		resultTags => resultTags,
		nextResultTags => nextResultTags,
		resultVals => resultVals,
				
		prevSending => prevSendingB,
		prevSendingOK => renamedSending,
		
		nextAccepting => execAcceptingB,	
		
		newData => dataToB,		
		
		execCausing => execOrIntCausing,
		execEventSignal => execOrIntEventSignal,
		
			readyRegFlags => readyRegFlags,		
		
			regsForDispatch => regsSelB,
			regReadAllow => regsAllowB,
			
			regValues => regValsB,
			
		accepting => acceptingB,
			acceptingVec => acceptingVecB,		
		dataOutIQ => dataOutIQB,
			sendingOut => sendingSchedB
	);
	
		
	IQ_C: entity work.UnitIQ
	generic map(
		IQ_SIZE => IQ_C_SIZE
	)
	port map(
		clk => clk, reset => resetSig, en => enSig,

		writtenTags => writtenTags,		
		resultTags => resultTags,
		nextResultTags => nextResultTags,
		resultVals => resultVals,
				
		prevSending => prevSendingC,
		prevSendingOK => renamedSending,
		
		nextAccepting => execAcceptingC,
		
		newData => dataToC,			
		
		execCausing => execOrIntCausing,
		execEventSignal => execOrIntEventSignal,
		
			readyRegFlags => readyRegFlags,
		
			regsForDispatch => regsSelC,
			regReadAllow => regsAllowC,
			
			regValues => regValsC,
			
		accepting => acceptingC,
			acceptingVec => acceptingVecC,		
		dataOutIQ => dataOutIQC,
			sendingOut => sendingSchedC
	);					
	
	IQ_D: entity work.UnitIQ
	generic map(
		IQ_SIZE => IQ_D_SIZE
	)
	port map(
		clk => clk, reset => resetSig, en => enSig,
		
		writtenTags => writtenTags,
		resultTags => resultTags,
		nextResultTags => nextResultTags,
		resultVals => resultVals,
				
		prevSending => prevSendingD,
		prevSendingOK => renamedSending,
		
		nextAccepting => execAcceptingD,
		
		newData => dataToD,		
		
		execCausing => execOrIntCausing,
		execEventSignal => execOrIntEventSignal,

			readyRegFlags => readyRegFlags,
		
			regsForDispatch => regsSelD,
			regReadAllow => regsAllowD,

			regValues => regValsD,
			
		accepting => acceptingD,
			acceptingVec => acceptingVecD,		
		dataOutIQ => dataOutIQD,
			sendingOut => sendingSchedD
	);	


	IQ_E: entity work.UnitIQ
	generic map(
		IQ_SIZE => IQ_E_SIZE
	)
	port map(
		clk => clk, reset => resetSig, en => enSig,
		
		writtenTags => writtenTags,
		resultTags => resultTags,
		nextResultTags => nextResultTags,
		resultVals => resultVals,
				
		prevSending => prevSendingE,
		prevSendingOK => renamedSending,
		
		nextAccepting => execAcceptingE,
		
		newData => dataToE,
		
		execCausing => execOrIntCausing,
		execEventSignal => execOrIntEventSignal,

			readyRegFlags => readyRegFlags,
		
			regsForDispatch => regsSelE,
			regReadAllow => regsAllowE,

			regValues => regValsE,
			
		accepting => acceptingE,
			acceptingVec => acceptingVecE,		
		dataOutIQ => dataOutIQE,
			sendingOut => sendingSchedE
	);	
															
	EXEC_BLOCK: entity work.UnitExec(Implem)
	port map(
		clk => clk, reset => resetSig, en => enSig,

		sendingIQA => sendingSchedA,
		sendingIQB => sendingSchedB,
		sendingIQC => sendingSchedC,
		sendingIQD => sendingSchedD,
		sendingIQE => sendingSchedE,

		whichAcceptedCQ => whichAcceptedCQ,
		dataIQA => dataOutIQA,
		dataIQB => dataOutIQB,
		dataIQC => dataOutIQC,
		dataIQD => dataOutIQD,
		dataIQE => dataOutIQE,

		memLoadReady => memLoadReady,
		memLoadValue => memLoadValue,

		memLoadAddress => memLoadAddress,
		memStoreAddress => memStoreAddress,
		memLoadAllow => memLoadAllow,
		memStoreAllow => memStoreAllow,
		memStoreValue => memStoreValue,
			
		sysRegSelect => sysRegReadSel,
		sysRegIn => sysRegReadValue,
		sysRegWriteSelOut => sysRegWriteSel,
		sysRegWriteValueOut => sysRegWriteValue,

		execAcceptingA => execAcceptingA,
		execAcceptingB => execAcceptingB,				
		execAcceptingC => execAcceptingC,
		execAcceptingD => execAcceptingD,
		execAcceptingE => execAcceptingE,
		
			selectedToCQ => open, --selectedToCQ,
		execSending => execSending,
		execSending2 => execSending2,
		
		execEvent => execEventSignal,
		execCausingOut => execCausing,
				
		execOrIntEventSignalIn => execOrIntEventSignal,
		execOrIntCausingIn => execOrIntCausing,
			
		execPreEnds => execPreEnds,
		execEnds => execEnds,
		execEnds2 => execEnds2
	);	


	COMMIT_QUEUE: entity work.TestCQPart0(Implem)
	port map(
		clk => clk, reset => resetSig, en => enSig,
		
		execEventSignal => execOrIntEventSignal,
		execCausing => execOrIntCausing,
		
		inputInstructions => execEnds,
		selectedToCQ => selectedToCQ,
		whichAcceptedCQ => whichAcceptedCQ,
		cqWhichSend => execSending,				
		anySending => anySendingFromCQ,
		cqOut => cqDataLivingOut,
		dataCQOut => dataCQOut -- CAREFUL: must remain, because used by forwarding network!
	);
		

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

					sendingToCommit => robSending, --sendingToCommit,
					stageDataToCommit => dataOutROB, --stageDataToCommit,
					physCommitDests_TMP => (others => (others => '0')), -- CAREFUL: useless input?
					
					prevNewPhysDests => open,
					newPhysSources => newPhysSources,	-- TO SEQ
					
					prevStablePhysDests => physStable,  -- FOR MAPPING (to FREE LIST)
					stablePhysSources => open,
					
						sendingToWrite => anySendingFromCQ,
						stageDataToWrite => cqDataLivingOut,

							stageDataToWritePre => cqDataLivingOut, -- TEMP!
						
						readyRegFlagsNext => --open --
													readyRegFlagsNextV
				);

			LAST_COMMITTED_SYNCHRONOUS: process(clk) 	
			begin
				if rising_edge(clk) then
					if resetSig = '1' then
					elsif enSig = '1' then
						physStableDelayed <= work.ProcLogicRenaming.getStableDestsParallel(dataOutROB, physStable);					
					end if;
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
				takeAllow => frontLastSending or renameLockEnd,	-- FROM SEQ
				stageDataToReserve => frontDataLastLiving,
				
				newPhysDests => newPhysDests,			-- TO SEQ
				newPhysDestPointer => newPhysDestPointer, -- TO SEQ

				sendingToRelease => committedSending,  -- FROM SEQ
				stageDataToRelease => committedDataOut,  -- FROM SEQ
				
				physStableDelayed => physStableDelayed -- FOR MAPPING (from MAP)
			);		


			INT_READY_TABLE: entity work.ReadyRegisterTable(Behavioral)
			port map(
				clk => clk, reset => resetSig, en => enSig, 
				
				sendingToReserve => frontLastSending,
				stageDataToReserve => frontDataLastLiving,
					
				newPhysDests => newPhysDests,	-- FOR MAPPING
				stageDataReserved => renamedDataLiving, --stageDataOutRename,
				
				sendingToWrite => anySendingFromCQ,
				stageDataToWrite => cqDataLivingOut,
				
				readyRegFlagsNext => readyRegFlagsNext -- FOR IQs
			);

			READY_REGS_SYNCHRONOUS: process(clk) 	
			begin
				if rising_edge(clk) then
					--if resetSig = '1' then					
					--elsif enSig = '1' then		
						--	report std_logic'image(readyRegFlags_2(0)) & std_logic'image(readyRegFlagsNext(0));
						readyRegFlags_2 <= readyRegFlagsNext;
						--	readyRegFlagsV <= readyRegFlagsNextV;
					--end if;
				end if;
			end process;

			readyRegFlags <= readyRegFlags_2;
			
--				INT_READY_TABLE_V: entity work.ReadyRegTableV(Behavioral)
--				port map(
--					clk => clk, reset => resetSig, en => enSig, 
--					
--					sendingToReserve => frontLastSending,
--					stageDataToReserve => frontDataLastLiving,
--						
--					--newPhysDests => newPhysDests,	-- FOR MAPPING
--					--stageDataReserved => renamedDataLiving, --stageDataOutRename,
--					
--					sendingToWrite => anySendingFromCQ,
--					stageDataToWrite => cqDataLivingOut,
--					
--					readyRegFlagsNext => readyRegFlagsNextV -- FOR IQs
--				);			
		end block;
		
		
		
		
		-- CAREFUL! This stage is needed to keep result tags 1 for cycle when writing to reg file,
		--				so that "black hole" of inivisible readiness doesn't occur
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
			
		cqPhysDestMask <= getPhysicalDestMask(cqDataLivingOut);
		cqPhysicalDests <= getPhysicalDests(cqDataLivingOut);
		cqInstructionResults <= getInstructionResults(cqDataLivingOut);
		
			
			regsSelCE(0 to 1) <= regsSelC(0 to 1);
			regsSelCE(2) <= regsSelE(2);
			regsAllowCE <= regsAllowC or regsAllowE;
			regValsC <= regValsCE;
			regValsE <= regValsCE;
		
		TEMP_REG_FILE_INPUTS: for i in 0 to PIPE_WIDTH-1 generate
			rfWriteVec(i) <= cqPhysDestMask(i); -- cqDataLivingOut.data(i);
			rfSelectWrite(i) <= cqPhysicalDests(i); -- anySendingFromCQ and cqDataLivingOut.fullMask(i);
			rfWriteValues(i) <= cqInstructionResults(i);
		end generate;		
		
		GPR_FILE_DISPATCH: entity work.RegisterFile0 (Behavioral)
																	--(Implem)
		generic map(WIDTH => 4,
						WRITE_WIDTH => PIPE_WIDTH)
		port map(
			clk => clk, reset => resetSig, en => enSig,

				readAllowT0 => regsAllowA,
				readAllowT1 => regsAllowB,
				readAllowT2 => regsAllowCE,
				readAllowT3 => regsAllowD,
				
			writeAllow => anySendingFromCQ,
			writeVec => rfWriteVec,
			selectWrite => rfSelectWrite,
									-- ^ NOTE: unneeded writing isn't harmful anyway
			writeValues => rfWriteValues,
			
			selectRead(0 to 2) => regsSelA,
			selectRead(3 to 5) => regsSelB,
			selectRead(6 to 8) => regsSelCE,
			selectRead(9 to 11) => regsSelD,
			
			readValues(0 to 2) => regValsA,
			readValues(3 to 5) => regValsB,
			readValues(6 to 8) => regValsCE,						
			readValues(9 to 11) => regValsD			
		);
	
	
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
		
		sendingOut => robSending, 
		outputData => dataOutROB		
	);
	
	writtenTags <= getWrittenTags(stageDataAfterCQ);
	resultTags <= getResultTags(
				execEnds, dataCQOut, dataOutIQA, dataOutIQB, dataOutIQC, dataOutIQD,	stageDataAfterCQ);
	nextResultTags <= getNextResultTags(execPreEnds, dataOutIQA, dataOutIQB, dataOutIQC, dataOutIQD);
	resultVals <= getResultValues(execEnds, dataCQOut, stageDataAfterCQ);
	
	dadr <= memLoadAddress;
	doutadr <= memStoreAddress;
		dadrvalid <= memLoadAllow or memStoreAllow; -- DEPREC?
	dread <= memLoadAllow;
	dwrite <= memStoreAllow;
	dout <= memStoreValue;
		drw <= memStoreAllow; -- DEPREC?
	memLoadValue <= din;
	memLoadReady <= dvalid;

end Behavioral5;

