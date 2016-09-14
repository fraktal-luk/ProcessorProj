
-- CAREFUL! If partial kill occurs, we have to check if any slot of the stage remains alive,
--				and if no one, then generate killAll signal for that stage! 

architecture Behavioral5 of NewCore0 is	
	signal resetSig, enSig: std_logic := '0';				
				

	signal pcDataSig: StageDataPC :=	DEFAULT_DATA_PC;
	signal pcSendingSig: std_logic := '0';

				
	signal frontDataLastLiving: StageDataMulti;
	signal frontLastSending: std_logic := '0';		
	signal renameAccepting: std_logic := '0';


		signal acceptingOutFront: std_logic := '0';
		signal stage0Events: StageMultiEventInfo;
		
		-- for Front
		signal killVec: std_logic_vector(0 to N_EVENT_AREAS-1) := (others => '0');	
		
	signal fetchLockCommand: std_logic := '0';


	signal renamedDataLiving, stageDataCommittedOut: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;				
	signal renamedSending: std_logic := '0';			
	
	
	-- For storing prev reg tags that triggered reg file reading		
	signal renamedDataPrev: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	
	
	-- CAREFUL, TODO: make this robust for changes in renaming details!
	signal readyRegs, readyRegsSig, readyRegsPrev: std_logic_vector(0 to N_PHYSICAL_REGS-1)
		:= (0 to 31 => '1', others=>'0'); -- p0-p31 are initially mapped to logical regs and ready
	
	signal readyRegFlags, readyRegFlagsNext: std_logic_vector(0 to 3*PIPE_WIDTH-1) := (others => '0');
	
	
	
	signal dataToA, dataToB, dataToC, dataToD: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;						

	signal acceptingA, prevSendingA: SmallNumber := (others=>'0');									
	signal acceptingB, prevSendingB: SmallNumber := (others=>'0');	
	signal acceptingC, prevSendingC: SmallNumber := (others=>'0');	
	signal acceptingD, prevSendingD: SmallNumber := (others=>'0');	
	
	signal iqAccepts: std_logic := '0';	
		
	-- TODO: change to simple bit interface?
	signal flowResponseOutIQA: FlowResponseSimple := (others=>'0');
	signal dataOutIQA: InstructionState := defaultInstructionState;	
			
	signal flowResponseOutIQB: FlowResponseSimple := (others=>'0');
	signal dataOutIQB: InstructionState := defaultInstructionState;

	signal flowResponseOutIQC: FlowResponseSimple := (others=>'0');
	signal dataOutIQC: InstructionState := defaultInstructionState;
	
	signal flowResponseOutIQD: FlowResponseSimple := (others=>'0');
	signal dataOutIQD: InstructionState := defaultInstructionState;		
	
	signal sendingSchedA, sendingSchedB, sendingSchedC, sendingSchedD: std_logic := '0';
	

		-- Physical register interface
		signal regsSelA, regsSelB, regsSelC, regsSelD: PhysNameArray(0 to 2) := (others => (others => '0'));
		signal regValsA, regValsB, regValsC, regValsD: MwordArray(0 to 2) := (others => (others => '0'));
		signal regsAllowA, regsAllowB, regsAllowC, regsAllowD: std_logic := '0';


	signal execAcceptingA, execAcceptingB, execAcceptingC, execAcceptingD: std_logic := '0'; 

		-- Mem interface
		signal memAddress, memLoadValue, memStoreValue: Mword := (others => '0');
		signal memStoreAllow, memLoadAllow, memLoadReady: std_logic := '0';
		
		-- Sys reg interface	
		signal sysRegReadSel: slv5 := (others => '0');
		signal sysRegValue: Mword := (others => '0');
		signal sysRegWriteAllow: std_logic := '0';
		-- CAREFUL: *E names are from temporary register in exec block, without "E" from commiting (alternative)
		signal sysRegWriteSel, sysRegWriteSelE: slv5 := (others => '0');
		signal sysRegWriteValue, sysRegWriteValueE: Mword := (others => '0');

	signal execEnds: InstructionStateArray(0 to 3);
	signal execPreEnds: InstructionStateArray(0 to 3); -- For 'nextResultTags'

	
	-- forw network
	signal resultTags: PhysNameArray(0 to N_RES_TAGS-1) := (others=>(others=>'0'));
	signal nextResultTags: PhysNameArray(0 to N_NEXT_RES_TAGS-1) := (others=>(others=>'0'));
	signal resultVals: MwordArray(0 to N_RES_TAGS-1) := (others=>(others=>'0'));	
	-- writtenTags indicate registers written to GPR file in last cycle, so they can be read from there
	--		rather than from forw. network, but readyRegFlags are not available in the 1st cycle after WB.
	signal writtenTags: PhysNameArray(0 to PIPE_WIDTH-1) := (others => (others => '0'));
	
	
	-- evt
	signal execEventSignal, execOrIntEventSignal: std_logic := '0';						
	-- This will take the value of operation that causes jump or exception
	signal execCausing, execOrIntCausing: InstructionState := defaultInstructionState;																			
	signal intSig: std_logic := '0';
	signal intCausing: InstructionState := defaultInstructionState;


	-- Hidden to some degree, but may be useful for sth
	signal renameCtrSig, renameCtrNextSig, commitCtrSig, commitCtrNextSig: SmallNumber := (others=>'0');
	signal commitGroupCtrSig, commitGroupCtrNextSig: SmallNumber := (others => '0');
					
					
			-- TODO: to remove
			signal TEMP_completed: std_logic_vector(0 to 3) := (others => '0');
			signal TEMP_results: InstructionStateArray(0 to 3) := (others => defaultInstructionState);
		
		
	-- ROB interface	
	signal robSending, robAccepting: std_logic := '0';
	signal dataOutROB: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;					

	-- back end interfaces
	signal selectedToCQ, whichAcceptedCQ: std_logic_vector(0 to 3) := (others=>'0');	
	signal cqWhichSend: std_logic_vector(0 to 3);
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
		
		--		signal ch0, ch1, ch2, ch3: std_logic := '0'; -- TEST, remove
				
	constant HAS_RESET: std_logic := '1';
	constant HAS_EN: std_logic := '1';				
begin
	resetSig <= reset and HAS_RESET;
	enSig <= en or not HAS_EN;
	
	intSig <= int0;
	
	SEQUENCING_PART: entity work.UnitSequencer(Behavioral)
	port map (
		clk => clk, reset => resetSig, en => enSig,

		sysRegReadSel => sysRegReadSel,
		sysRegReadValue => sysRegValue,	
		sysRegWriteSel => sysRegWriteSelE,
		sysRegWriteValue => sysRegWriteValueE,

		-- Icache interface
		iadr => iadr,
		iadrvalid => iadrvalid,		

		frontAccepting => acceptingOutFront,
		pcDataLiving => pcDataSig,
		pcSending => pcSendingSig,

		stage0EventInfo => stage0Events, -- from front
					
		intSignal => intSig,
		execEventSignal => execEventSignal,
		execCausing => execCausing,
		frontEventSigOut => open, -- frontEventSig,
		
			execOrIntEventSignalOut => execOrIntEventSignal,
			intCausingOut => intCausing,
			execOrIntCausingOut => execOrIntCausing,
		killVecOut => killVec,
				
		renameAccepting => renameAccepting, -- to frontend
		frontLastSending => frontLastSending,
		frontDataLastLiving => frontDataLastLiving,
		
		anySendingFromCQ => anySendingFromCQ,		
		cqDataLiving => cqDataLivingOut,				
		
		sendingFromROB => robSending,	
		robDataLiving => dataOutROB,
		
			fetchLockCommandOut => fetchLockCommand, -- This is associated with the front dependency
		
		-- Interface with IQ
		iqAccepts => iqAccepts and robAccepting,	
		renamedDataLiving => renamedDataLiving, -- !!!
		renamedSending => renamedSending,
				
			readyRegFlagsOut => readyRegFlags,
		commitCtrNextOut => commitCtrNextSig,
		commitGroupCtrOut => commitGroupCtrSig,
		commitGroupCtrNextOut => commitGroupCtrNextSig						
	);
	
	
	
	FRONT_PART: entity work.UnitFront(Behavioral)
	port map(
		clk => clk, reset => resetSig, en => enSig,
		iin => iin,
			ivalid => ivalid,
		renameAccepting => renameAccepting,
		fetchLockCommand => fetchLockCommand,					
					
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
		renamedSendingIn => renamedSending,
		
		renamedSendingOut => open, -- DEPREC??
		iqAccepts => iqAccepts,
		prevSendingA => prevSendingA,
		prevSendingB => prevSendingB,
		prevSendingC => prevSendingC,
		prevSendingD => prevSendingD,		
		dataOutA => dataToA,
		dataOutB => dataToB,
		dataOutC => dataToC,
		dataOutD => dataToD
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
		intSignal => intSig,	
			
			readyRegFlags => readyRegFlags,
			
			regsForDispatch => regsSelA,
			regReadAllow => regsAllowA,
			
			regValues => regValsA,
			
		accepting => acceptingA,
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
		intSignal => intSig,	
		
			readyRegFlags => readyRegFlags,		
		
			regsForDispatch => regsSelB,
			regReadAllow => regsAllowB,
			
			regValues => regValsB,
			
		accepting => acceptingB,
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
		intSignal => intSig,	
		
			readyRegFlags => readyRegFlags,
		
			regsForDispatch => regsSelC,
			regReadAllow => regsAllowC,
			
			regValues => regValsC,
			
		accepting => acceptingC,
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
		intSignal => intSig,	

			readyRegFlags => readyRegFlags,
		
			regsForDispatch => regsSelD,
			regReadAllow => regsAllowD,

			regValues => regValsD,
			
		accepting => acceptingD,
		dataOutIQ => dataOutIQD,
			sendingOut => sendingSchedD
	);	
															
	EXEC_BLOCK: entity work.UnitExec(Behavioral) port map(
		clk => clk, reset => resetSig, en => enSig,
			sendingIQA => sendingSchedA,
			sendingIQB => sendingSchedB,
			sendingIQC => sendingSchedC,
			sendingIQD => sendingSchedD,			
		whichAcceptedCQ => whichAcceptedCQ,
		dataIQA => dataOutIQA,
		dataIQB => dataOutIQB,
		dataIQC => dataOutIQC,
		dataIQD => dataOutIQD,			
		intSig => intSig,
		intCausingIn => intCausing,
		
			memLoadReady => memLoadReady,
			memLoadValue => memLoadValue,
		-- Output
			memAddress => memAddress,
			memLoadAllow => memLoadAllow,
			memStoreAllow => memStoreAllow,
			memStoreValue => memStoreValue,
			
			sysRegSelect => sysRegReadSel,
			sysRegIn => sysRegValue,
				sysRegWriteSelOut => sysRegWriteSelE,
				sysRegWriteValueOut => sysRegWriteValueE,
		execAcceptingA => execAcceptingA,
		execAcceptingB => execAcceptingB,				
		execAcceptingC => execAcceptingC,
		execAcceptingD => execAcceptingD,
		
		selectedToCQ => selectedToCQ,
		cqWhichSend => cqWhichSend,
		
		execEvent => execEventSignal,
		execCausingOut => execCausing,
				
			execOrIntEventSignalIn => execOrIntEventSignal,
			execOrIntCausingIn => execOrIntCausing,
			
		execPreEnds => execPreEnds,
		execEnds => execEnds
	);	
	
	
	COMMIT_QUEUE: entity work.TestCQPart0(Behavioral2) port map(
		clk => clk, reset => resetSig, en => enSig,
		
		intSignal => intSig,
		execEventSignal => execOrIntEventSignal,
		execCausing => execOrIntCausing,
		
		commitCtrNext => commitCtrNextSig,

		inputInstructions => execEnds,
		selectedToCQ => selectedToCQ,
		whichAcceptedCQ => whichAcceptedCQ,
		cqWhichSend => cqWhichSend,				
		anySending => anySendingFromCQ,
		cqOut => cqDataLivingOut,
		dataCQOut => dataCQOut -- CAREFUL: must remain, because used by forwarding network!
	);
		
		
		-- CAREFUL! This stage is needed to keep result tags 1 for cycle when writing to reg file,
		--				so that "black hole" of inivisible readiness doesn't occur
		AFTER_CQ: entity work.SubunitCommit port map(
			clk => clk, reset => resetSig, en => enSig,
			
			prevSending => anySendingFromCQ,
			nextAccepting => '1',
			execEventSignal => '0',
			execCausing => execCausing,
			stageDataIn => cqDataLivingOut,
			acceptingOut => open,
			sendingOut => open,
			stageDataOut => stageDataAfterCQ,
			
			
			lastCommittedOut => open,
			lastCommittedNextOut => open
		);
			
		cqPhysDestMask <= getPhysicalDestMask(cqDataLivingOut);
		cqPhysicalDests <= getPhysicalDests(cqDataLivingOut);
		cqInstructionResults <= getInstructionResults(cqDataLivingOut);
		
		TEMP_REG_FILE_INPUTS: for i in 0 to PIPE_WIDTH-1 generate
			rfWriteVec(i) <= cqPhysDestMask(i); -- cqDataLivingOut.data(i);
			rfSelectWrite(i) <= cqPhysicalDests(i); -- anySendingFromCQ and cqDataLivingOut.fullMask(i);
			rfWriteValues(i) <= cqInstructionResults(i);
		end generate;		
		
		GPR_FILE_DISPATCH: entity work.RegisterFile0(Behavioral)
		generic map(WIDTH => 4,
						WRITE_WIDTH => PIPE_WIDTH)
		port map(
			clk => clk, reset => resetSig, en => enSig,

				readAllowT0 => regsAllowA,
				readAllowT1 => regsAllowB,
				readAllowT2 => regsAllowC,
				readAllowT3 => regsAllowD,
				
			writeAllow => anySendingFromCQ,
			writeVec => rfWriteVec,
			selectWrite => rfSelectWrite,
									-- ^ NOTE: unneeded writing isn't harmful anyway
			writeValues => rfWriteValues,
			
			selectRead(0 to 2) => regsSelA,
			selectRead(3 to 5) => regsSelB,
			selectRead(6 to 8) => regsSelC,
			selectRead(9 to 11) => regsSelD,
			
			readValues(0 to 2) => regValsA,
			readValues(3 to 5) => regValsB,
			readValues(6 to 8) => regValsC,						
			readValues(9 to 11) => regValsD			
		);

	
	process (clk)
	begin
		if rising_edge(clk) then
			if resetSig = '1' then		
				
			elsif enSig = '1' then

			end if;
		end if;
	end process;
	
		--TEMP_COMPLETING: for i in 0 to PIPE_WIDTH-1 generate
		--	TEMP_results(i) <= cqDataLivingOut.data(i);
		--	TEMP_completed(i) <= anySendingFromCQ and cqDataLivingOut.fullMask(i);
		--end generate;	
	
	REORDER_BUFFER: entity work.ReorderBuffer port map(
		clk => clk, reset => resetSig, en => enSig,
		
		intSignal => '0',
		execEventSignal => execOrIntEventSignal,
		execCausing => execOrIntCausing,
		
		commitCtrNext => commitCtrNextSig,
		commitGroupCtr => commitGroupCtrSig,
		commitGroupCtrNext => commitGroupCtrNextSig,
			execEnds => execEnds,
			execReady => cqWhichSend,
		
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
	
	dadr <= memAddress;
	dadrvalid <= memLoadAllow or memStoreAllow;
	dout <= memStoreValue;
	drw <= memStoreAllow;
	memLoadValue <= din;
	memLoadReady <= dvalid;
	
end Behavioral5;

