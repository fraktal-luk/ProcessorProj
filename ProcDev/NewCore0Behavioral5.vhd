
-- CAREFUL! If partial kill occurs, we have to check if any slot of the stage remains alive,
--				and if no one, then generate killAll signal for that stage! 

architecture Behavioral5 of NewCore0 is	
	signal resetSig, enabled: std_logic := '0';				
															
	signal frontDataLastLiving: StageDataMulti;
	signal frontLastSending: std_logic := '0';		
	signal renameAccepting: std_logic := '0';

	signal renamedDataLiving: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;				
	signal renamedSending: std_logic := '0';			
	
	signal readyRegs, readyRegsSig: std_logic_vector(0 to N_PHYSICAL_REGS-1) := (others=>'0');
	signal fetchLockCommand: std_logic := '0'; 
	signal fetchLockRequest: std_logic := '0';
		
	signal partialKillMask1: std_logic_vector(0 to PIPE_WIDTH-1) := (others=>'0');	

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
	
	signal readyExecA: std_logic;	
	signal readyExecB: std_logic;	
	signal readyExecC: std_logic;		
	signal readyExecD: std_logic;	
	
	signal execAcceptingA, execAcceptingB, execAcceptingC, execAcceptingD: std_logic := '0'; 
	
	signal execEnds: InstructionStateArray(0 to 3);
	signal execPreEnds: InstructionStateArray(0 to 3); -- For 'nextResultTags'
					
	-- This looks like unused		
	signal flowDriveAPost, flowDriveBPost, flowDriveCPost, flowDriveDPost: FlowDriveSimple
					:= (others=>'0');
	-- This isn't in IQ part! It's after Exec
	signal flowResponseAPost: FlowResponseSimple := (others=>'0');					
	signal flowResponseBPost, flowResponseCPost, flowResponseDPost: FlowResponseSimple
					:= (others=>'0');		
	
	signal selectedToCQ, whichAcceptedCQ: std_logic_vector(0 to 3) := (others=>'0');	
	signal cqWhichSend: std_logic_vector(0 to 3);	
	signal whichSendingFromCQ: std_logic_vector(0 to PIPE_WIDTH-1) := (others=>'0');		
	signal dataCQOut: StageDataCommitQueue
								:= (fullMask=>(others=>'0'), data=>(others=>defaultInstructionState));	
	signal cqDataLivingOut: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	-- REDUNDANT						
	signal cqOut: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
										
	signal execEventSignal: std_logic := '0';						
	-- This will take the value of operation that causes jump or exception
	signal execCausing: InstructionState := defaultInstructionState;
							
	signal regPortTags, regPortTagsNext, regPortSelect: PhysNameArray(0 to 11) 
									:= (others=> (others=>'0')); 
									
		signal tmpPN0, tmpPN1, tmpPN2: PhysName := (others=>'0');

	-- DEPREC? $OUTPUT REN?	
	signal ra: std_logic_vector(0 to 31) := (others=>'0');

	signal resultTags, nextResultTags: PhysNameArray(0 to N_RES_TAGS-1) := (others=>(others=>'0'));
		signal dummyVals: MwordArray(0 to N_RES_TAGS-1) := (others=>(others=>'0'));	

	signal lastCommitted, lastCommittedNext: InstructionState := defaultInstructionState;
	signal intSig: std_logic := '0';

	signal renameCtrSig, renameCtrNextSig, commitCtrSig, commitCtrNextSig: SmallNumber := (others=>'0');		
begin
	resetSig <= reset;
	enabled <= en;
	
	intSig <= int0;
	
	FRONT_PART: entity work.TestFrontPart0(Behavioral2)
	port map(
		clk => clk, reset => resetSig, en => en,
		iin => iin,
		renameAccepting => renameAccepting,
		execEventSignal => execEventSignal,
		execCausing => execCausing,
		fetchLockCommand => fetchLockCommand,
					
		intSignal => intSig,
					
		iadr => iadr,
		iadrvalid => iadrvalid,
		dataLastLiving => frontDataLastLiving,
		lastSending => frontLastSending,
		fetchLockRequest => fetchLockRequest
	);
	------ Front pipe ends here.

	-- Rename stage and register state management	
	RENAMING_PART: entity work.TestRenamingCircuit0 port map(
		clk => clk, reset => resetSig, en => en,
		
		iqAccepts => iqAccepts,
		execEventSignal => execEventSignal,
		execCausing => execCausing,
		
		frontDataLastLiving => frontDataLastLiving,
		frontLastSending => frontLastSending,
		
		cqDataLiving => cqDataLivingOut,
		-- TODO: remove input below, because doubling 'fullMask' of input 'cqDataLiving'
		whichSendingFromCQ => whichSendingFromCQ,
		
		accepting => renameAccepting, -- to frontend
		renamedDataLiving => renamedDataLiving,
		renamedSending => renamedSending,
		
			ra => open,
		readyRegs => readyRegsSig, 			
		commitCtrNextOut => commitCtrNextSig,
		lastCommittedOut => lastCommitted,
		lastCommittedNextOut => lastCommittedNext	
	);
			
	IQ_ROUTING: block
		signal srcVecA, srcVecB, srcVecC, srcVecD: std_logic_vector(0 to PIPE_WIDTH-1);
		signal issueRouteVec: IntArray(0 to PIPE_WIDTH-1);
		signal nToA, nToB, nToC, nToD: natural := 0;	
		signal iqAcceptingA: std_logic := '0';						
		signal iqAcceptingB, iqAcceptingC, iqAcceptingD: std_logic := '0';		
	begin	
		-- Routing to queues
		ROUTE_VEC_GEN: for i in 0 to PIPE_WIDTH-1 generate
			issueRouteVec(i) <= unit2queue(renamedDataLiving.data(i).operation.unit);
		end generate;
		
	-- New concept for IQ routing.  {renamedData, srcVec*} -> (StageDataMulti){A,B,C,D}
	-- Based on "push left" of each destination type, generating "New" StageDataMulti data for each one
	-- dataToA <= [func](stageData1Living, srcVecA); -- s.d.1.l includes fullMask!	
	
	-- Selection of flow into IQ's
		srcVecA <= findByNumber(issueRouteVec, 0) and renamedDataLiving.fullMask;
		srcVecB <= findByNumber(issueRouteVec, 1) and renamedDataLiving.fullMask;
		srcVecC <= findByNumber(issueRouteVec, 2) and renamedDataLiving.fullMask;
		srcVecD <= findByNumber(issueRouteVec, 3) and renamedDataLiving.fullMask;
												
		dataToA <= routeToIQ(renamedDataLiving, srcVecA);
		dataToB <= routeToIQ(renamedDataLiving, srcVecB);
		dataToC <= routeToIQ(renamedDataLiving, srcVecC);
		dataToD <= routeToIQ(renamedDataLiving, srcVecD);
	
		nToA	<= countOnes(dataToA.fullMask);
		iqAcceptingA <= '1' when PIPE_WIDTH <= binFlowNum(acceptingA) else '0';	
		prevSendingA <= num2flow(nToA, false) when renamedSending = '1' else (others=>'0');		
			
		nToB	<= countOnes(dataToB.fullMask);
		iqAcceptingB <= '1' when PIPE_WIDTH <= binFlowNum(acceptingB) else '0';														
		prevSendingB <= num2flow(nToB, false) when renamedSending = '1' else (others=>'0');

		nToC	<= countOnes(dataToC.fullMask);
		iqAcceptingC <= '1' when PIPE_WIDTH <= binFlowNum(acceptingC) else '0';					
		prevSendingC <= num2flow(nToC, false) when renamedSending = '1' else (others=>'0');

		nToD	<= countOnes(dataToD.fullMask);
		iqAcceptingD <= '1' when PIPE_WIDTH <= binFlowNum(acceptingD) else '0';					
		prevSendingD <= num2flow(nToD, false) when renamedSending = '1' else (others=>'0');				
			
		iqAccepts <= iqAcceptingA and iqAcceptingB and iqAcceptingC and iqAcceptingD;
	end block;	
		
	IQ_A: entity work.TestIQ0
	generic map(
		IQ_SIZE => IQ_A_SIZE
	)
	port map(
		clk => clk, reset => resetSig, en => en,
		
		resultTags => resultTags,
		nextResultTags => nextResultTags,
		dummyVals => dummyVals,
		readyRegs => readyRegsSig,				
			ra => ra, -- TEMP!		
		prevSending => prevSendingA,
		prevSendingOK => renamedSending,
		
		nextAccepting => execAcceptingA,
		
		newData => dataToA,		
		
		execCausing => execCausing,
		execEventSignal => execEventSignal,
			tmpPN0 => tmpPN0,
			tmpPN1 => tmpPN1,
			tmpPN2 => tmpPN2,		
		accepting => acceptingA,
		dataOutIQ => dataOutIQA,
		flowResponseOutIQ => flowResponseOutIQA		
	);
	
	IQ_B: entity work.TestIQ0
	generic map(
		IQ_SIZE => IQ_B_SIZE
	)
	port map(
		clk => clk, reset => resetSig, en => en,
		
		resultTags => resultTags,
		nextResultTags => nextResultTags,
		dummyVals => dummyVals,
		readyRegs => readyRegsSig,		
		
			ra => ra, -- TEMP!
		
		prevSending => prevSendingB,
		prevSendingOK => renamedSending,
		
		nextAccepting => execAcceptingB,	
		
		newData => dataToB,		
		
		execCausing => execCausing,
		execEventSignal => execEventSignal,
		
			tmpPN0 => open, --tmpPN0,
			tmpPN1 => open, --tmpPN1,
			tmpPN2 => open, --tmpPN2,
		
		accepting => acceptingB,
		dataOutIQ => dataOutIQB,
		flowResponseOutIQ => flowResponseOutIQB	
	);
	
		
	IQ_C: entity work.TestIQ0
	generic map(
		IQ_SIZE => IQ_C_SIZE
	)
	port map(
		clk => clk, reset => resetSig, en => en,
		
		resultTags => resultTags,
		nextResultTags => nextResultTags,
		dummyVals => dummyVals,
		readyRegs => readyRegsSig,	
		
			ra => ra, -- TEMP!
		
		prevSending => prevSendingC,
		prevSendingOK => renamedSending,
		
		nextAccepting => execAcceptingC,
		
		newData => dataToC,			
		
		execCausing => execCausing,
		execEventSignal => execEventSignal,
		
			tmpPN0 => open, --tmpPN0,
			tmpPN1 => open, --tmpPN1,
			tmpPN2 => open, --tmpPN2,
		
		accepting => acceptingC,
		dataOutIQ => dataOutIQC,
		flowResponseOutIQ => flowResponseOutIQC		
	);					
	
	IQ_D: entity work.TestIQ0
	generic map(
		IQ_SIZE => IQ_D_SIZE
	)
	port map(
		clk => clk, reset => resetSig, en => en,
		
		resultTags => resultTags,
		nextResultTags => nextResultTags,
		dummyVals => dummyVals,
		readyRegs => readyRegsSig,		
		
			ra => ra, -- TEMP!
		
		prevSending => prevSendingD,
		prevSendingOK => renamedSending,
		
		nextAccepting => execAcceptingD,
		
		newData => dataToD,		
		
		execCausing => execCausing,
		execEventSignal => execEventSignal,
		
			tmpPN0 => open, --tmpPN0,
			tmpPN1 => open, --tmpPN1,
			tmpPN2 => open, --tmpPN2,
		
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
		
	-- Exec part	
	EXEC_PART: block
		-- This will serve for automation of sequence connections
		signal execPrevResponses, execNextResponses: ExecResponseTable := (others=>(others=>'0'));
		
		signal execDrives: ExecDriveTable := (others=>(others=>'0')); 
		signal execResponses: ExecResponseTable := (others=>(others=>'0'));
		
		signal execData: ExecDataTable := (others=>defaultInstructionState);		
		signal execDataNext: ExecDataTable := (others=>defaultInstructionState);
		signal execDataNew: ExecDataTable := (others=>defaultInstructionState);		
	begin
		execAcceptingA <= execResponses(ExecA0).accepting;
		execAcceptingB <= execResponses(ExecB0).accepting;
		execAcceptingC <= execResponses(ExecC0).accepting;
		execAcceptingD <= execResponses(ExecD0).accepting;
		
		execPrevResponses <= getExecPrevResponses(execResponses,
										flowResponseOutIQA, flowResponseOutIQB, flowResponseOutIQC, flowResponseOutIQD);
		execNextResponses <= getExecNextResponses(execResponses,
											flowResponseAPost, flowResponseBPost, flowResponseCPost, flowResponseDPost);
			
		EXEC_DRIVE_ASSIGN: for s in ExecStages'left to ExecStages'right generate
			execDrives(s).prevSending <= execPrevResponses(s).sending;
			execDrives(s).nextAccepting <= execNextResponses(s).accepting;				
		end generate;				
			
		execDataNew <= (	ExecA0 => dataOutIQA,
								ExecB0 => dataOutIQB,
								ExecB1 => execData(ExecB0), ExecB2 => execData(ExecB1),
								ExecC0 => dataOutIQC,
								ExecC1 => execData(ExecC0), ExecC2 => execData(ExecC1),
								ExecD0 => basicBranch(dataOutIQD),
								others => defaultInstructionState);
			-- CAREFUL! Here we must somehow include actual exec operations!				
			--execDataNew <= getExecDataNew(execDataUpdated, dataASel, dataBSel, dataCSel, dataDSel);											
		
		-- Automatic exec data passing
		EXEC_DATA_NEXT: for s in ExecStages'left to ExecStages'right generate
			execDataNext(s) <= stageSimpleNext(execData(s), execDataNew(s),
					execResponses(s).living, execResponses(s).sending, execDrives(s).prevSending);	
		end generate;
			
		EXEC_SYNCHRONOUS: process(clk) 	
		begin
			if rising_edge(clk) then
				if resetSig = '1' then
					
				elsif enabled = '1' then	
					execData <= execDataNext;					
				end if;
			end if;
		end process;	

		-- Stage logic for all exec stages
		EXEC_LOGIC_SLOTS: for s in ExecStages'left to ExecStages'right generate
			EXEC_SIMPLE_SLOT_LOGIC: SimplePipeLogic port map(
					clk => clk,
					reset => resetSig,
					en => en,
					flowDrive => execDrives(s),
					flowResponse => execResponses(s)
				);		
		end generate;		
-------------------------------------------------------------------------------------------------
	-- Event selection
	
	-- Exec/int events:
		execEventSignal <= '1' when  intSig = '1'
									or	(execData(ExecD0).controlInfo.execEvent and execResponses(ExecD0).isNew) = '1'
						else	'0';				
	
		-- TODO: can chcnge to lastCommittedNext and spare those instructions in CQ, but need to fix CQ killing
		execCausing <= 	lastCommitted when intSig = '1'
						-- lastCommittedNext when intSig = '1' -- NOTE: for sparing "almost committed"		
						else	execData(ExecD0) when execEventSignal = '1' 
						else	defaultInstructionState;  -- CHECK: maybe this option not needed, simpler without it?	
				
		-- CAREFUL! In all automatic blocks for exec, remember about correct range of stages!
		EXEC_KILL: for s in ExecStages'left to ExecStages'right generate
			signal before: std_logic;
			signal a, b: std_logic_vector(7 downto 0);
		begin
			a <= execCausing.numberTag;
			b <= execData(s).numberTag;
			EXEC_KILLER: entity work.CompareBefore8 port map(
				inA => a, 
				inB => b, 
				outC => before
			);		
			execDrives(s).kill <= before and execEventSignal; 	
		end generate;
	
		-- Interface between exec and CQ
		readyExecA <= execResponses(ExecA0).living;
		readyExecB <= execResponses(ExecB2).living;
		readyExecC <= execResponses(ExecC2).living;
		readyExecD <= execResponses(ExecD0).living;	
	
		flowResponseAPost.accepting <= whichAcceptedCQ(0);
		flowResponseBPost.accepting <= whichAcceptedCQ(1);
		flowResponseCPost.accepting <= whichAcceptedCQ(2);
		flowResponseDPost.accepting <= whichAcceptedCQ(3);	
	
		selectedToCQ <= (0 => readyExecA, 1 => readyExecB, 2 => readyExecC, 3 => readyExecD, others=>'0');
		cqWhichSend <= (0 => execResponses(ExecA0).sending, 1 => execResponses(ExecB2).sending,
							 2 => execResponses(ExecC2).sending, 3 =>	execResponses(ExecD0).sending,
								others=>'0');
		execEnds <= (0=> execData(ExecA0), 1=> execData(ExecB2), 2=> execData(ExecC2), 3=>execData(ExecD0),
						others=> defaultInstructionState);
		execPreEnds <= (1=> execData(ExecB1), 2=> execData(ExecC1),
						others=> defaultInstructionState);										
	end block;	
	
	-- 	
	COMMIT_QUEUE: entity work.TestCQPart0 port map(
		clk => clk, reset => resetSig, en => en,
		
		intSignal => intSig,
		execEventSignal => execEventSignal,
		execCausing => execCausing,
		
		commitCtrNext => commitCtrNextSig,
		inputInstructions => execEnds,
		selectedToCQ => selectedToCQ,
		whichAcceptedCQ => whichAcceptedCQ,
		cqWhichSend => cqWhichSend,
		
		whichSendingFromCQOut => whichSendingFromCQ,
			cqOut => cqOut,
			dataCQOut => dataCQOut -- CAREFUL: must remain, because used by forwarding network!
	);
	
	cqDataLivingOut <= cqOut;									
	
	---------------------------------
	-- Result forwarding sketch
	-- CAREFUL: make sure that killed instructions not considered for tags! (If it be a real problem)
	resultTags <= TEMP_getResultTags(
				execEnds, dataCQOut, dataOutIQA, dataOutIQB, dataOutIQC, dataOutIQD); --, newlyReadRegs);
	nextResultTags <= TEMP_getNextResultTags(		-- What'll be ready in next cycle
											execPreEnds, dataOutIQA, dataOutIQB,	dataOutIQC, dataOutIQD);
																					
	oaux <= execCausing.bits; 
end Behavioral5;

