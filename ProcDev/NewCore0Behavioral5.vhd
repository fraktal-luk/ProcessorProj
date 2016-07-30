
-- CAREFUL! If partial kill occurs, we have to check if any slot of the stage remains alive,
--				and if no one, then generate killAll signal for that stage! 

architecture Behavioral5 of NewCore0 is	
	signal resetSig, enSig: std_logic := '0';				
															
	signal frontDataLastLiving: StageDataMulti;
	signal frontLastSending: std_logic := '0';		
	signal renameAccepting: std_logic := '0';

	signal renamedDataLiving, stageDataCommittedOut: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;				
	signal renamedSending: std_logic := '0';			
	
	signal readyRegs, readyRegsSig, readyRegsPrev: std_logic_vector(0 to N_PHYSICAL_REGS-1)
		:= (0 to 31 => '1', others=>'0'); -- p0-p31 are initially mapped to logical regs and ready
	
	-- CAREFUL: feature not yet implemented
	signal fetchLockCommand: std_logic := '0';
	signal fetchLockRequest: std_logic := '0'; 
	--
	
	signal dataToA, dataToB, dataToC, dataToD: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;						

	signal acceptingA, prevSendingA: SmallNumber := (others=>'0');									
	signal acceptingB, prevSendingB: SmallNumber := (others=>'0');	
	signal acceptingC, prevSendingC: SmallNumber := (others=>'0');	
	signal acceptingD, prevSendingD: SmallNumber := (others=>'0');	
	
	signal iqAccepts: std_logic := '0';	
	
	signal flowResponseOutIQA: FlowResponseSimple := (others=>'0');
	signal dataOutIQA: InstructionState := defaultInstructionState;	
			
	signal flowResponseOutIQB: FlowResponseSimple := (others=>'0');
	signal dataOutIQB: InstructionState := defaultInstructionState;

	signal flowResponseOutIQC: FlowResponseSimple := (others=>'0');
	signal dataOutIQC: InstructionState := defaultInstructionState;
	
	signal flowResponseOutIQD: FlowResponseSimple := (others=>'0');
	signal dataOutIQD: InstructionState := defaultInstructionState;		
	
	signal readyExecA, readyExecB, readyExecC, readyExecD: std_logic := '0';		
	
	signal execAcceptingA, execAcceptingB, execAcceptingC, execAcceptingD: std_logic := '0'; 
	
	signal execEnds: InstructionStateArray(0 to 3);
	signal execPreEnds: InstructionStateArray(0 to 3); -- For 'nextResultTags'
					
	-- This looks like unused		
	--signal flowDriveAPost, flowDriveBPost, flowDriveCPost, flowDriveDPost: FlowDriveSimple
	--				:= (others=>'0');
	-- This isn't in IQ part! It's after Exec
	--signal flowResponseAPost: FlowResponseSimple := (others=>'0');					
	--signal flowResponseBPost, flowResponseCPost, flowResponseDPost: FlowResponseSimple
	--				:= (others=>'0');		
	
	signal selectedToCQ, whichAcceptedCQ: std_logic_vector(0 to 3) := (others=>'0');	
	signal cqWhichSend: std_logic_vector(0 to 3);
	signal anySendingFromCQ: std_logic := '0';
	
	signal dataCQOut: StageDataCommitQueue
								:= (fullMask=>(others=>'0'), data=>(others=>defaultInstructionState));	
	signal cqDataLivingOut: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
				
	signal execEventSignal: std_logic := '0';						
	-- This will take the value of operation that causes jump or exception
	signal execCausing: InstructionState := defaultInstructionState;
							
	--signal regPortTags, regPortTagsNext, regPortSelect: PhysNameArray(0 to 11) 
	--								:= (others=> (others=>'0')); 
											
	-- For storing prev reg tags that triggered reg file reading		
	signal renamedDataPrev: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	signal regValues: MwordArray(0 to 3*PIPE_WIDTH-1) := (others => (others => '0'));

	signal resultTags: PhysNameArray(0 to N_RES_TAGS-1) := (others=>(others=>'0'));
	signal nextResultTags: PhysNameArray(0 to N_NEXT_RES_TAGS-1) := (others=>(others=>'0'));
		signal resultVals: MwordArray(0 to N_RES_TAGS-1) := (others=>(others=>'0'));	

	signal lastCommitted, lastCommittedNext: InstructionState := defaultInstructionState;
	signal intSig: std_logic := '0';


	signal renameCtrSig, renameCtrNextSig, commitCtrSig, commitCtrNextSig: SmallNumber := (others=>'0');
	
	constant HAS_RESET: std_logic := '1';
	constant HAS_EN: std_logic := '1';
	
		signal memAddress, memLoadValue, memStoreValue: Mword := (others => '0');
		signal memStoreAllow, memLoadAllow, memLoadReady: std_logic := '0';
		
		signal ilrSig, elrSig: Mword := (others => '0'); -- DEPREC
		signal frontEventSig: std_logic := '0';
		
		signal sysRegReadSel: slv5 := (others => '0');
		signal sysRegValue: Mword := (others => '0');
		signal sysRegWriteAllow: std_logic := '0';
		signal sysRegWriteSel: slv5 := (others => '0');
		signal sysRegWriteValue: Mword := (others => '0');
		
		signal intCausing: InstructionState := defaultInstructionState;
begin
	resetSig <= reset and HAS_RESET;
	enSig <= en or not HAS_EN;
	
	intSig <= int0;
	
	FRONT_PART: entity work.UnitFront(Behavioral)
	port map(
		clk => clk, reset => resetSig, en => enSig,
		iin => iin,
			ivalid => ivalid,
		renameAccepting => renameAccepting,
		execEventSignal => execEventSignal,
		execCausing => execCausing,
		fetchLockCommand => fetchLockCommand,
					
		intSignal => intSig,
		intCausing => intCausing,
			sysRegReadSel => sysRegReadSel,
			sysRegReadValue => sysRegValue,	
			sysRegWriteAllow => sysRegWriteAllow,
			sysRegWriteSel => sysRegWriteSel,
			sysRegWriteValue => sysRegWriteValue,					
		iadr => iadr,
		iadrvalid => iadrvalid,
		dataLastLiving => frontDataLastLiving,
		lastSending => frontLastSending,
		fetchLockRequest => fetchLockRequest,
			frontEventSig => frontEventSig
		--ilrOut => ilrSig,
		--elrOut => elrSig
	);

	-- Rename stage and register state management	
	RENAMING_PART: entity work.UnitReorder(Behavioral) port map( --work.TestRenamingCircuit0 port map(
		clk => clk, reset => resetSig, en => enSig,
		
		iqAccepts => iqAccepts,
		
		execEventSignal => execEventSignal,
		execCausing => execCausing,
				
		frontDataLastLiving => frontDataLastLiving,
		frontLastSending => frontLastSending,
		
			-- CAREFUL: front info input is for fetchLock handling.
			--				It creates an inconvenient dependency on front part.
			fetchLockRequest => fetchLockRequest,
			frontEventSig => frontEventSig,
		
		cqDataLiving => cqDataLivingOut,
		
		anySendingFromCQ => anySendingFromCQ,
			fetchLockCommand => fetchLockCommand, -- This is associated with the front dependency
		
			sysRegWriteAllow => sysRegWriteAllow,
			sysRegWriteSel => sysRegWriteSel,
			sysRegWriteValue => sysRegWriteValue,
		
		accepting => renameAccepting, -- to frontend
		renamedDataLiving => renamedDataLiving,
		renamedSending => renamedSending,
		
		readyRegs => readyRegsSig, 			
		commitCtrNextOut => commitCtrNextSig,
		
		stageDataCommittedOut => stageDataCommittedOut,
		lastCommittedOut => lastCommitted,
		lastCommittedNextOut => lastCommittedNext	
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
		
		resultTags => resultTags,
		nextResultTags => nextResultTags,
		resultVals => resultVals,
		readyRegs => readyRegsSig,				

		prevSending => prevSendingA,
		prevSendingOK => renamedSending,
		
		nextAccepting => execAcceptingA,
		
		newData => dataToA,		
		
		execCausing => execCausing,
		execEventSignal => execEventSignal,
			
			regsForDispatch => open,
		accepting => acceptingA,
		dataOutIQ => dataOutIQA,
		flowResponseOutIQ => flowResponseOutIQA		
	);
	
	IQ_B: entity work.UnitIQ
	generic map(
		IQ_SIZE => IQ_B_SIZE
	)
	port map(
		clk => clk, reset => resetSig, en => enSig,
		
		resultTags => resultTags,
		nextResultTags => nextResultTags,
		resultVals => resultVals,
		readyRegs => readyRegsSig,		
				
		prevSending => prevSendingB,
		prevSendingOK => renamedSending,
		
		nextAccepting => execAcceptingB,	
		
		newData => dataToB,		
		
		execCausing => execCausing,
		execEventSignal => execEventSignal,
		
			regsForDispatch => open,
		accepting => acceptingB,
		dataOutIQ => dataOutIQB,
		flowResponseOutIQ => flowResponseOutIQB	
	);
	
		
	IQ_C: entity work.UnitIQ
	generic map(
		IQ_SIZE => IQ_C_SIZE
	)
	port map(
		clk => clk, reset => resetSig, en => enSig,
		
		resultTags => resultTags,
		nextResultTags => nextResultTags,
		resultVals => resultVals,
		readyRegs => readyRegsSig,	
				
		prevSending => prevSendingC,
		prevSendingOK => renamedSending,
		
		nextAccepting => execAcceptingC,
		
		newData => dataToC,			
		
		execCausing => execCausing,
		execEventSignal => execEventSignal,
		
			regsForDispatch => open,
		accepting => acceptingC,
		dataOutIQ => dataOutIQC,
		flowResponseOutIQ => flowResponseOutIQC		
	);					
	
	IQ_D: entity work.UnitIQ
	generic map(
		IQ_SIZE => IQ_D_SIZE
	)
	port map(
		clk => clk, reset => resetSig, en => enSig,
		
		resultTags => resultTags,
		nextResultTags => nextResultTags,
		resultVals => resultVals,
		readyRegs => readyRegsSig,		
				
		prevSending => prevSendingD,
		prevSendingOK => renamedSending,
		
		nextAccepting => execAcceptingD,
		
		newData => dataToD,		
		
		execCausing => execCausing,
		execEventSignal => execEventSignal,
		
			regsForDispatch => open,
		accepting => acceptingD,
		dataOutIQ => dataOutIQD,
		flowResponseOutIQ => flowResponseOutIQD		
	);	
														
			-- CAREFUL!  						
--					REG_READ_CONFIRM: for i in regPortTags'range generate
--						regPortTagsNext(i) <= regPortSelect(i) when regPortOK(i) = '1'			
--												else (others=>'0');			
--					end generate;		
--					
--					regPortSelect(0) <= dataASel(0).physicalArgs.s0;
--					regPortSelect(1) <= dataASel(1).physicalArgs.s1;
--					regPortSelect(2) <= dataASel(2).physicalArgs.s2;
--					
--					regPortOK(0) <= 

	
	EXEC_BLOCK: entity work.UnitExec(Behavioral) port map(
		clk => clk, reset => resetSig, en => enSig,
		
		flowResponseIQA => flowResponseOutIQA,
		flowResponseIQB => flowResponseOutIQB,
		flowResponseIQC => flowResponseOutIQC,
		flowResponseIQD => flowResponseOutIQD,
		whichAcceptedCQ => whichAcceptedCQ,
		dataIQA => dataOutIQA,
		dataIQB => dataOutIQB,
		dataIQC => dataOutIQC,
		dataIQD => dataOutIQD,			
		intSig => intSig,
		lastCommitted => lastCommitted,
		lastCommittedNext => lastCommittedNext,		
		
			memLoadReady => memLoadReady,
			memLoadValue => memLoadValue,
		-- Output
			memAddress => memAddress,
			memLoadAllow => memLoadAllow,
			memStoreAllow => memStoreAllow,
			memStoreValue => memStoreValue,
			
			-- This should be cut out, and int/exc return left to PC/CR part.
			--ilrIn => ilrSig,
			--elrIn => elrSig,

				sysRegSelect => sysRegReadSel,
				sysRegIn => sysRegValue,

		execAcceptingA => execAcceptingA,
		execAcceptingB => execAcceptingB,				
		execAcceptingC => execAcceptingC,
		execAcceptingD => execAcceptingD,
		
		selectedToCQ => selectedToCQ,
		cqWhichSend => cqWhichSend,
		execEventSignalOut => execEventSignal,
		execCausingOut => execCausing,
		intCausingOut => intCausing,
		execPreEnds => execPreEnds,
		execEnds => execEnds
	);
	
	-- 	
	COMMIT_QUEUE: entity work.TestCQPart0 port map(
		clk => clk, reset => resetSig, en => enSig,
		
		intSignal => intSig,
		execEventSignal => execEventSignal,
		execCausing => execCausing,
		
		commitCtrNext => commitCtrNextSig,
		inputInstructions => execEnds,
		selectedToCQ => selectedToCQ,
		whichAcceptedCQ => whichAcceptedCQ,
		cqWhichSend => cqWhichSend,				
		anySending => anySendingFromCQ,
		cqOut => cqDataLivingOut,
		dataCQOut => dataCQOut -- CAREFUL: must remain, because used by forwarding network!
	);
		
	GPR_FILE: entity work.RegisterFile0(Behavioral)
	generic map(WIDTH => PIPE_WIDTH)
	port map(
		clk => clk, reset => resetSig, en => enSig,

		writeAllow => anySendingFromCQ,
		writeVec => getPhysicalDestMask(cqDataLivingOut),
		selectWrite => getPhysicalDests(cqDataLivingOut), 
								-- ^ NOTE: unneeded writing isn't harmful anyway
		writeValues => getInstructionResults(cqDataLivingOut),

		selectRead => getPhysicalArgs(renamedDataLiving),
		readValues => regValues		
	);
		
		
	---------------------------------
	-- Result forwarding sketch
	-- CAREFUL: make sure that killed instructions not considered for tags! (If it be a real problem)
	
	process (clk)
	begin
		if rising_edge(clk) then
			if resetSig = '1' then		
				
			elsif enSig = '1' then
				-- NOTE: this may be developed to connect to CommitQueue into unified reorder buffer 
				renamedDataPrev <= renamedDataLiving;
				readyRegsPrev <= readyRegsSig;
			end if;
		end if;
	end process;
	
	resultTags <= getResultTags(
				execEnds, dataCQOut, dataOutIQA, dataOutIQB, dataOutIQC, dataOutIQD,
				renamedDataPrev,
				readyRegsPrev, -- CAREFUL! Prev, cause reading takes a cycle!
				stageDataCommittedOut);
	nextResultTags <= getNextResultTags(		-- What'll be ready in next cycle
											execPreEnds, dataOutIQA, dataOutIQB,	dataOutIQC, dataOutIQD);
	resultVals <= getResultValues(execEnds, dataCQOut, stageDataCommittedOut, regValues);										
	
	dadr <= memAddress;
	dadrvalid <= memLoadAllow or memStoreAllow;
	dout <= memStoreValue;
	drw <= memStoreAllow;
	memLoadValue <= din;
	memLoadReady <= dvalid;
	
	oaux <= execCausing.bits; 
end Behavioral5;

