
-- CAREFUL! If partial kill occurs, we have to check if any slot of the stage remains alive,
--				and if no one, then generate killAll signal for that stage! 

architecture Behavioral5 of NewCore0 is	
	signal resetSig, enabled: std_logic := '0';				

	-- $OUTPUT REN
	signal renamedDataLiving: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

			-- TEST												
			signal stageData1New_2: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;											
															
	-- $output FRONT
	signal frontDataLastLiving: StageDataMulti;
	-- $output FRONT
	signal frontLastSending: std_logic := '0';		
	-- $input FRONT
	signal renameAccepting: std_logic := '0';
				
		signal cqDataLivingOut: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
		
	signal srcVecA, srcVecB, srcVecC, srcVecD: std_logic_vector(0 to PIPE_WIDTH-1);
	signal issueRouteVec: IntArray(0 to PIPE_WIDTH-1);

	signal dataToA, dataToB, dataToC, dataToD: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;						
	signal nToA, nToB, nToC, nToD: natural := 0;
			
	-- This looks like unused		
	signal flowDriveAPost, flowDriveBPost, flowDriveCPost, flowDriveDPost: FlowDriveSimple
					:= (others=>'0');
	signal flowResponseBPost, flowResponseCPost, flowResponseDPost: FlowResponseSimple
					:= (others=>'0');		

	-- This isn't in IQ part! It's after Exec
	signal flowResponseAPost: FlowResponseSimple := (others=>'0');
								
			signal acceptingB, prevSendingB: SmallNumber := (others=>'0');	
			signal acceptingC, prevSendingC: SmallNumber := (others=>'0');	
			signal acceptingD, prevSendingD: SmallNumber := (others=>'0');	
					
			signal iqAcceptingB, iqAcceptingC, iqAcceptingD: std_logic := '0';	
			signal iqAccepts: std_logic := '0';	
	-- A
	signal acceptingA, prevSendingA: SmallNumber := (others=>'0');	
	signal iqAcceptingA: std_logic := '0';	
		
		signal flowResponseOutIQA: FlowResponseSimple := (others=>'0');
		signal dataOutIQA: InstructionState := defaultInstructionState;	
				
		signal flowResponseOutIQB: FlowResponseSimple := (others=>'0');
		signal dataOutIQB: InstructionState := defaultInstructionState;

		signal flowResponseOutIQC: FlowResponseSimple := (others=>'0');
		signal dataOutIQC: InstructionState := defaultInstructionState;
		
		signal flowResponseOutIQD: FlowResponseSimple := (others=>'0');
		signal dataOutIQD: InstructionState := defaultInstructionState;		

	------------
	
		-- This will serve for automation of sequence connections
		signal execPrevResponses, execNextResponses: ExecResponseTable := (others=>(others=>'0'));
			signal execPrevResponses2, execNextResponses2: ExecResponseTable := (others=>(others=>'0'));
		
	signal execDrives: ExecDriveTable := (others=>(others=>'0')); 
	signal execResponses: ExecResponseTable := (others=>(others=>'0'));
	
	signal execData, execDataUpdated: ExecDataTable := (others=>defaultInstructionState);
	signal execDataNext: ExecDataTable := (others=>defaultInstructionState);
	signal execDataNew: ExecDataTable := (others=>defaultInstructionState);	

	signal readyExecA: std_logic;	
	signal readyExecB: std_logic;	
	signal readyExecC: std_logic;		
	signal readyExecD: std_logic;	
	
	signal execEnds: InstructionStateArray(0 to 3);
	
	signal selectedToCQ, whichAcceptedCQ: std_logic_vector(0 to 3) := (others=>'0');	
	signal cqWhichSend: std_logic_vector(0 to 3);	
	signal whichSendingFromCQ: std_logic_vector(0 to PIPE_WIDTH-1) := (others=>'0');		
	signal dataCQOut: StageDataCommitQueue
								:= (fullMask=>(others=>'0'), data=>(others=>defaultInstructionState));		
												
		-- FRONT?
		signal fetchLockCommand: std_logic := '0'; 
		signal fetchLockRequest: std_logic := '0';
		
		
		signal partialKillMask1: std_logic_vector(0 to PIPE_WIDTH-1) := (others=>'0');
									
		signal execEventSignal: std_logic := '0';						
		-- This will take the value of operation that causes jump or exception
		signal execCausing: InstructionState := defaultInstructionState;
							
		signal regPortTags, regPortTagsNext, regPortSelect: PhysNameArray(0 to 11) 
									:= (others=> (others=>'0')); 
									
		signal tmpPN0, tmpPN1, tmpPN2: PhysName := (others=>'0');

		-- DEPREC? $OUTPUT REN?	
		signal ra: std_logic_vector(0 to 31) := (others=>'0');
		-- $OUPUT REN
		signal readyRegs, readyRegsSig: std_logic_vector(0 to N_PHYSICAL_REGS-1) := (others=>'0');
			
		signal resultTags, nextResultTags: PhysNameArray(0 to N_RES_TAGS-1) := (others=>(others=>'0'));
			signal dummyVals: MwordArray(0 to N_RES_TAGS-1) := (others=>(others=>'0'));	

		signal lastCommitted, lastCommittedNext: InstructionState := defaultInstructionState;
		signal intSig: std_logic := '0';

		signal renameCtrSig, renameCtrNextSig, commitCtrSig, commitCtrNextSig: SmallNumber := (others=>'0');		
begin
	resetSig <= reset;
	enabled <= en;
	
		intSig <= int0;
	
	--NEW_FRONT: if true generate
		FRONT_PART_TEST: entity work.TestFrontPart0
		port map(
			clk => clk, reset => reset, en => en,
			iin => iin,
			renameAccepting => renameAccepting,
			execEventSignal => execEventSignal,
			execCausing => execCausing,
			fetchLockCommand => fetchLockCommand,
						
			intSignal => intSig,
						
			iadr => iadr, --open,
			iadrvalid => iadrvalid, -- open,
			dataLastLiving => frontDataLastLiving, --open,
			lastSending => frontLastSending, -- open,
			fetchLockRequest => fetchLockRequest --open
		);
	--end generate;	
	------ Front pipe ends here.

	-- Rename stage and register state management	
		NEW_RENAMING: entity work.TestRenamingCircuit0 port map(
			clk => clk, reset => resetSig, en => en,
			
			iqAccepts => iqAccepts,
			execEventSignal => execEventSignal,
			execCausing => execCausing,
			
			frontDataLastLiving => frontDataLastLiving, --: in StageDataMulti;
			frontLastSending => frontLastSending, --: in std_logic;
			
			cqDataLiving => cqDataLivingOut, --: in StageDataMulti;
			whichSendingFromCQ => whichSendingFromCQ, --: in std_logic_vector(0 to 3);
			
			accepting => --open, 
						renameAccepting, -- to frontend
			renamedDataLiving => --open,
									renamedDataLiving,
				ra => open, --: out std_logic_vector(0 to 31);
			readyRegs => --open,
							readyRegsSig, 			
			commitCtrNextOut => --open 
									commitCtrNextSig,
			lastCommittedOut => lastCommitted,
			lastCommittedNextOut => lastCommittedNext	
		);
	
		cqDataLivingOut.fullMask <= whichSendingFromCQ;
		cqDataLivingOut.data <= -- ??(some may be killed? careful)
											dataCQOut.data(0 to PIPE_WIDTH-1);	
			
		-- Routing to queues
		ROUTE_VEC_GEN: for i in 0 to PIPE_WIDTH-1 generate
			issueRouteVec(i) <= unit2queue(renamedDataLiving.data(i).operation.unit);
		end generate;
	
		srcVecA <= findByNumber(issueRouteVec, 0) and renamedDataLiving.fullMask;
		srcVecB <= findByNumber(issueRouteVec, 1) and renamedDataLiving.fullMask;
		srcVecC <= findByNumber(issueRouteVec, 2) and renamedDataLiving.fullMask;
		srcVecD <= findByNumber(issueRouteVec, 3) and renamedDataLiving.fullMask;
					
		-- This seems much less effective (bigger area): 			
--				srcVecA <=(	findByExecUnit(stagedata1Living.data, ALU)
--							or	findByExecUnit(stagedata1Living.data, Divide))
--							and stageData1Living.fullMask;
--				srcVecB <=(	findByExecUnit(stagedata1Living.data, MAC))
--							and stageData1Living.fullMask;	    			
--				srcVecC <=(	findByExecUnit(stagedata1Living.data, Memory))
--							and stageData1Living.fullMask;	    			
--				srcVecD <=(	findByExecUnit(stagedata1Living.data, Jump)
--							or	findByExecUnit(stagedata1Living.data, System))
--							and stageData1Living.fullMask;
					
		-- New concept for IQ routing.  {renamedData, srcVec*} -> (StageDataMulti){A,B,C,D}
			-- Based on "push left" of each destination type, generating "New" StageDataMulti data for each one
			-- dataToA <= [func](stageData1Living, srcVecA); -- s.d.1.l includes fullMask!	
		
			dataToA <= routeToIQ(renamedDataLiving, srcVecA);
			dataToB <= routeToIQ(renamedDataLiving, srcVecB);
			dataToC <= routeToIQ(renamedDataLiving, srcVecC);
			dataToD <= routeToIQ(renamedDataLiving, srcVecD);
		
				nToA	<= countOnes(dataToA.fullMask);
				iqAcceptingA <= '1' when --nToA <= binFlowNum(acceptingA) else '0';
												 PIPE_WIDTH <= binFlowNum(acceptingA) else '0';	
												 -- CAREFUL! Above simpler but restrictive
				prevSendingA <= num2flow(nToA, false) when iqAccepts = '1' else (others=>'0');		
				
				nToB	<= countOnes(dataToB.fullMask);
				iqAcceptingB <= '1' when --nToB <= binFlowNum(acceptingB) else '0';
												 PIPE_WIDTH <= binFlowNum(acceptingB) else '0';														
				prevSendingB <= num2flow(nToB, false) when iqAccepts = '1' else (others=>'0');

				nToC	<= countOnes(dataToC.fullMask);
				iqAcceptingC <= '1' when --nToC <= binFlowNum(acceptingC) else '0';
												 PIPE_WIDTH <= binFlowNum(acceptingC) else '0';					
				prevSendingC <= num2flow(nToC, false) when iqAccepts = '1' else (others=>'0');

				nToD	<= countOnes(dataToD.fullMask);
				iqAcceptingD <= '1' when --nToD <= binFlowNum(acceptingD) else '0';
												 PIPE_WIDTH <= binFlowNum(acceptingD) else '0';					
				prevSendingD <= num2flow(nToD, false) when iqAccepts = '1' else (others=>'0');				
				
				iqAccepts <= iqAcceptingA and iqAcceptingB and iqAcceptingC and iqAcceptingD;
				
				
	IQ_A: entity work.TestIQ0
	generic map(
		IQ_SIZE => IQ_A_SIZE
	)
	port map(
		clk => clk, reset => reset, en => en,
		
		resultTags => resultTags, --: in PhysNameArray(0 to N_RES_TAGS-1);
		nextResultTags => nextResultTags, --: in PhysNameArray(0 to N_RES_TAGS-1);
		dummyVals => dummyVals, --: in MwordArray(0 to N_RES_TAGS-1);
		readyRegs => readyRegsSig,--: in std_logic_vector(0 to N_PHYSICAL_REGS-1);		
		
			ra => ra, -- TEMP!
		
		prevSendingA => prevSendingA, --: in SmallNumber; --std_logic;
		prevSendingOK => iqAccepts,--: in std_logic;
		
		nextAccepting => execResponses(ExecA0).accepting,--: in std_logic; -- from exec	
		
		newData => dataToA,--: in StageDataMulti; -- dataToA ??			
		
		execCausing => execCausing, --: in InstructionState;
		execEventSignal => execEventSignal,--: in std_logic;
		
			tmpPN0 => tmpPN0,
			tmpPN1 => tmpPN1,
			tmpPN2 => tmpPN2,
		
		acceptingA => acceptingA, -- open, --: out SmallNumber;
		dataOutIQA => dataOutIQA,-- open ,--: out InstructionState;
		flowResponseOutIQA => flowResponseOutIQA --open --: out flowResponseSimple --std_logic		
	);
	
	
	IQ_B: entity work.TestIQ0
	generic map(
		IQ_SIZE => IQ_B_SIZE
	)
	port map(
		clk => clk, reset => reset, en => en,
		
		resultTags => resultTags, --: in PhysNameArray(0 to N_RES_TAGS-1);
		nextResultTags => nextResultTags, --: in PhysNameArray(0 to N_RES_TAGS-1);
		dummyVals => dummyVals, --: in MwordArray(0 to N_RES_TAGS-1);
		readyRegs => readyRegsSig,--: in std_logic_vector(0 to N_PHYSICAL_REGS-1);		
		
			ra => ra, -- TEMP!
		
		prevSendingA => prevSendingB, --: in SmallNumber; --std_logic;
		prevSendingOK => iqAccepts,--: in std_logic;
		
		nextAccepting => execResponses(ExecB0).accepting,--: in std_logic; -- from exec	
		
		newData => dataToB,--: in StageDataMulti; -- dataToA ??			
		
		execCausing => execCausing, --: in InstructionState;
		execEventSignal => execEventSignal,--: in std_logic;
		
			tmpPN0 => open, --tmpPN0,
			tmpPN1 => open, --tmpPN1,
			tmpPN2 => open, --tmpPN2,
		
		acceptingA => acceptingB, -- open, --: out SmallNumber;
		dataOutIQA => dataOutIQB,-- open ,--: out InstructionState;
		flowResponseOutIQA => flowResponseOutIQB --open --: out flowResponseSimple --std_logic		
	);
	
		
	IQ_C: entity work.TestIQ0
	generic map(
		IQ_SIZE => IQ_C_SIZE
	)
	port map(
		clk => clk, reset => reset, en => en,
		
		resultTags => resultTags, --: in PhysNameArray(0 to N_RES_TAGS-1);
		nextResultTags => nextResultTags, --: in PhysNameArray(0 to N_RES_TAGS-1);
		dummyVals => dummyVals, --: in MwordArray(0 to N_RES_TAGS-1);
		readyRegs => readyRegsSig,--: in std_logic_vector(0 to N_PHYSICAL_REGS-1);		
		
			ra => ra, -- TEMP!
		
		prevSendingA => prevSendingC, --: in SmallNumber; --std_logic;
		prevSendingOK => iqAccepts,--: in std_logic;
		
		nextAccepting => execResponses(ExecC0).accepting,--: in std_logic; -- from exec	
		
		newData => dataToC,--: in StageDataMulti; -- dataToA ??			
		
		execCausing => execCausing, --: in InstructionState;
		execEventSignal => execEventSignal,--: in std_logic;
		
			tmpPN0 => open, --tmpPN0,
			tmpPN1 => open, --tmpPN1,
			tmpPN2 => open, --tmpPN2,
		
		acceptingA => acceptingC, -- open, --: out SmallNumber;
		dataOutIQA => dataOutIQC,-- open ,--: out InstructionState;
		flowResponseOutIQA => flowResponseOutIQC --open --: out flowResponseSimple --std_logic		
	);					
	
	IQ_D: entity work.TestIQ0
	generic map(
		IQ_SIZE => IQ_D_SIZE
	)
	port map(
		clk => clk, reset => reset, en => en,
		
		resultTags => resultTags, --: in PhysNameArray(0 to N_RES_TAGS-1);
		nextResultTags => nextResultTags, --: in PhysNameArray(0 to N_RES_TAGS-1);
		dummyVals => dummyVals, --: in MwordArray(0 to N_RES_TAGS-1);
		readyRegs => readyRegsSig,--: in std_logic_vector(0 to N_PHYSICAL_REGS-1);		
		
			ra => ra, -- TEMP!
		
		prevSendingA => prevSendingD, --: in SmallNumber; --std_logic;
		prevSendingOK => iqAccepts,--: in std_logic;
		
		nextAccepting => execResponses(ExecD0).accepting,--: in std_logic; -- from exec	
		
		newData => dataToD,--: in StageDataMulti; -- dataToA ??			
		
		execCausing => execCausing, --: in InstructionState;
		execEventSignal => execEventSignal,--: in std_logic;
		
			tmpPN0 => open, --tmpPN0,
			tmpPN1 => open, --tmpPN1,
			tmpPN2 => open, --tmpPN2,
		
		acceptingA => acceptingD, -- open, --: out SmallNumber;
		dataOutIQA => dataOutIQD,-- open ,--: out InstructionState;
		flowResponseOutIQA => flowResponseOutIQD --open --: out flowResponseSimple --std_logic		
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
								
	EXEC_DRIVE_ASSIGN: for s in ExecStages'left to ExecStages'right generate
		execDrives(s).prevSending <= execPrevResponses(s).sending;
		execDrives(s).nextAccepting <= execNextResponses(s).accepting;				
	end generate;				

--------------------------------------------------------------------------------
	-----------------------------------------------------------------------------------------------------
	-- Exec events:
		-- TEMP
		-- TODO: change names so that events from int are not confused with actual exec!
		execEventSignal <=
					'1'
						when   intSig = '1'
							or	(execData(ExecD0).controlInfo.execEvent and execResponses(ExecD0).isNew) = '1'
			else	'0';				
		-- TEMP	
		-- TODO: can chcnge to lastCommittedNext and spare those instructions in CQ, but need to fix CQ killing
		execCausing <= 
								lastCommitted when intSig = '1'
						-- lastCommittedNext when intSig = '1' -- NOTE: for sparing "almost committed"		
						else	execData(ExecD0) when execEventSignal = '1' 
						else	defaultInstructionState; 	
		
	----------------------------------------------------------------------------------	

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

		-----------------------------------------------------------						
																	
		-- Automatic exec data passing
		EXEC_DATA_NEXT: for s in ExecStages'left to ExecStages'right generate
			-- CAREFUL: using *Updated variety, cause Dispatch stages may need completing args when stalled!
			execDataNext(s) <= stageSimpleNext(execDataUpdated(s), execDataNew(s),
					execResponses(s).living, execResponses(s).sending, execDrives(s).prevSending);	
		end generate;
			
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

		readyExecA <= execResponses(ExecA0).living;
		readyExecB <= execResponses(ExecB2).living;
		readyExecC <= execResponses(ExecC2).living;
		readyExecD <= execResponses(ExecD0).living;	
	
		flowResponseAPost.accepting <= whichAcceptedCQ(0);
		flowResponseBPost.accepting <= whichAcceptedCQ(1);
		flowResponseCPost.accepting <= whichAcceptedCQ(2);
		flowResponseDPost.accepting <= whichAcceptedCQ(3);	
	
		selectedToCQ <= (0 => readyExecA, 1 => readyExecB, 2=> readyExecC, 3=> readyExecD, others=>'0');

		cqWhichSend <= (	0 =>	execResponses(ExecA0).sending, 1 => execResponses(ExecB2).sending,
								2 => execResponses(ExecC2).sending,	3 => 	execResponses(ExecD0).sending,
								others=>'0');
		execEnds <= (0=> execData(ExecA0), 1=> execData(ExecB2), 2=> execData(ExecC2), 3=>execData(ExecD0),
						others=> defaultInstructionState);
		
	COMMIT_QUEUE: entity work.TestCQPart0 port map(
		clk => clk, reset => reset, en => en,
		
		intSignal => intSig,
		execEventSignal => execEventSignal,
		execCausing => execCausing,
		
		commitCtrNext => commitCtrNextSig,
		inputInstructions => execEnds,
		selectedToCQ => selectedToCQ,
		whichAcceptedCQ => whichAcceptedCQ,-- open,
		cqWhichSend => cqWhichSend,
		
		whichSendingFromCQOut => whichSendingFromCQ,-- open,
		dataCQOut => dataCQOut -- open
	);
				
	-- Result forwarding sketch
	-- CAREFUL, TODO: make sure that killed instructions not considered for tags! (If it be a real problem)
		resultTags <= TEMP_getResultTags(execData, dataCQOut, -- stageDataCQ,
										dataOutIQA, dataOutIQB, dataOutIQC, dataOutIQD); --, newlyReadRegs);
																						--defaultInstructionState);
		nextResultTags <= TEMP_getNextResultTags(execData,	dataOutIQA, dataOutIQB,	dataOutIQC, dataOutIQD);
																												--defaultInstructionState);	
																		-- What'll be ready in next cycle				
								
	execDataUpdated <= getExecDataUpdated(execData,	dataOutIQA, dataOutIQB, dataOutIQC, dataOutIQD);											
											
	execDataNew <= (		ExecA0 => dataOutIQA,
								ExecB0 => dataOutIQB,
								ExecB1 => execDataUpdated(ExecB0), ExecB2 => execDataUpdated(ExecB1),
								ExecC0 => dataOutIQC,
								ExecC1 => execDataUpdated(ExecC0), ExecC2 => execDataUpdated(ExecC1),
								ExecD0 => basicBranch(dataOutIQD),
							others => defaultInstructionState);
			-- CAREFUL! Here we must somehow include actual exec operations!				
			--execDataNew <= getExecDataNew(execDataUpdated, dataASel, dataBSel, dataCSel, dataDSel);											
	execPrevResponses <= getExecPrevResponses(execResponses,
									flowResponseOutIQA, flowResponseOutIQB, flowResponseOutIQC, flowResponseOutIQD);
				-- NOTE: above, *Pre would be replaced	with flowResponseDispatchA/B/C/D	- ONGOING			
	execNextResponses <= getExecNextResponses(execResponses,
										flowResponseAPost, flowResponseBPost, flowResponseCPost, flowResponseDPost);

		EXEC_SYNCHRONOUS: process(clk) 	
		begin
			if rising_edge(clk) then
				if resetSig = '1' then
					
				elsif enabled = '1' then	
					execData <= execDataNext;					
				end if;
			end if;
		end process;										
	-------------------------------------------------------------------------------------------------

		oaux <= execCausing.bits; 
end Behavioral5;

