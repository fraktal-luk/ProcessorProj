
use work.SimLogicExec.all;

architecture Behavioral of UnitExec is
		signal resetSig, enSig: std_logic := '0';
			signal	execEventSignal, eventSignal: std_logic := '0';
			signal	execCausing, intCausing: InstructionState := defaultInstructionState;
			signal	activeCausing: InstructionState := defaultInstructionState;
			
			signal readyExecA, readyExecB, readyExecC, readyExecD: std_logic := '0';
			
		-- Internal signals
		signal execPrevResponses, execNextResponses: ExecResponseTable := (others=>(others=>'0'));
		
		signal execDrives: ExecDriveTable := (others=>(others=>'0')); 
		signal execResponses: ExecResponseTable := (others=>(others=>'0'));
		
		signal execData: ExecDataTable := (others=>defaultInstructionState);		
		signal execDataNext: ExecDataTable := (others=>defaultInstructionState);
		signal execDataNew: ExecDataTable := (others=>defaultInstructionState);	

		signal branchTarget, branchLink: Mword := (others => '0');
		signal aguAddress: Mword := (others => '0');
				signal btc: std_logic := '0';
				
	-- This isn't in IQ part! It's after Exec
	signal flowResponseAPost: FlowResponseSimple := (others=>'0');					
	signal flowResponseBPost, flowResponseCPost, flowResponseDPost: FlowResponseSimple
					:= (others=>'0');
	
	signal aluAOut, aguCOut: InstructionState := defaultInstructionState;
	signal lsOut: InstructionState := defaultInstructionState;
	signal branchOut: InstructionState := defaultInstructionState;
	signal macOut: InstructionState := defaultInstructionState;
	
	signal sysRegValue: Mword := (others => '0');
	signal sysRegReadSel, sysRegWriteSel: slv5 := (others => '0');
	
	signal sysRegWriteValueStore: Mword := (others => '0');
	signal sysRegWriteSelStore: slv5 := (others => '0');
	
		signal sysRegWriteValueNew: Mword := (others => '0');
		signal sysRegWriteSelNew: slv5 := (others => '0');	
		-- Enables writing to temp buffer for system registers
		signal sysRegBuffUpdate: std_logic := '0';
	
	signal execEndsSig: InstructionStateArray(0 to 3) := (others => defaultInstructionState);
	signal execReadyVec: std_logic_vector(0 to 3) := (others => '0');
		signal execTags, execOrder: SmallNumberArray(0 to 3) := (others => (others => '0'));
		signal unsorted, sorted: InstructionResultArray(0 to 3) := (others => DEFAULT_INSTRUCTION_RESULT);
		
		signal flowResponseSendingA, flowResponseSendingB, flowResponseSendingC, flowResponseSendingD:
						FlowResponseSimple := (others=>'0');
						
	constant HAS_RESET_EXEC: std_logic := '1';
	constant HAS_EN_EXEC: std_logic := '1';						
begin		
		resetSig <= reset and HAS_RESET_EXEC;
		enSig <= en or not HAS_EN_EXEC; 

		flowResponseSendingA.sending <= sendingIQA;
		flowResponseSendingB.sending <= sendingIQB;
		flowResponseSendingC.sending <= sendingIQC;
		flowResponseSendingD.sending <= sendingIQD;			

		EXEC_DRIVE_ASSIGN: for s in ExecStages'left to ExecStages'right generate
			execDrives(s).prevSending <= execPrevResponses(s).sending;
			execDrives(s).nextAccepting <= execNextResponses(s).accepting;				
		end generate;
		

		execPrevResponses <= getExecPrevResponses(execResponses,
					flowResponseSendingA, flowResponseSendingB, flowResponseSendingC, flowResponseSendingD);
		execNextResponses <= getExecNextResponses(execResponses,
											flowResponseAPost, flowResponseBPost, flowResponseCPost, flowResponseDPost);
		
		execDataNew <= (	ExecA0 => aluAOut,	
								ExecB0 => dataIQB,
								ExecB1 => execData(ExecB0), ExecB2 => macOut,
								ExecC0 => aguCOut,	
								ExecC1 => execData(ExecC0), ExecC2 => lsOut,
								ExecD0 => branchOut,
								others => defaultInstructionState);

		-- Automatic exec data passing
		EXEC_DATA_NEXT: for s in ExecStages'left to ExecStages'right generate
			execDataNext(s) <= stageSimpleNext(execData(s), execDataNew(s),
					execResponses(s).living, execResponses(s).sending, execDrives(s).prevSending);	
		end generate;
			
		EXEC_SYNCHRONOUS: process(clk) 	
		begin
			if rising_edge(clk) then
				if resetSig = '1' then
					
				elsif enSig = '1' then	
					execData <= execDataNext;

					if sysRegBuffUpdate = '1' then
						sysRegWriteValueStore <= --dataIQD.argValues.arg0;
															sysRegWriteValueNew;
						sysRegWriteSelStore <= --dataIQD.constantArgs.c0;
															sysRegWriteSelNew;
					end if;
				end if;
			end if;
		end process;	

		-- Stage logic for all exec stages
		EXEC_LOGIC_SLOTS: for s in ExecStages'left to ExecStages'right generate
			EXEC_SIMPLE_SLOT_LOGIC: SimplePipeLogic port map(
					clk => clk,
					reset => resetSig,
					en => enSig,
					flowDrive => execDrives(s),
					flowResponse => execResponses(s)
				);		
		end generate;	


		-- Specific logic 
		
			-- System reg addressing
			sysRegReadSel <= dataIQD.constantArgs.c1;  -- TEMP?		
			sysRegValue <= sysRegIn;

			sysRegWriteValueNew <= dataIQD.argValues.arg0;
			sysRegWriteSelNew <= dataIQD.constantArgs.c0;

			sysRegBuffUpdate <= '1' when	 execDrives(ExecD0).prevSending = '1'
												and dataIQD.operation.unit = System
												and dataIQD.operation.func = sysMtc
								else '0';
								
		aluAOut <= performALU(dataIQA);
		
			macOut <= execLogicXor(execData(ExecB1)); -- TEMP!
		
		aguAddress <= addWord(dataIQC.basicInfo.ip, dataIQC.constantArgs.imm);
		aguCOut <= 
			setExecState(dataIQC, aguAddress, '0', "0000");

		branchTarget <= addWord(dataIQD.basicInfo.ip, dataIQD.constantArgs.imm);		
		branchLink <= addWord(dataIQD.basicInfo.ip, getAddressIncrement(dataIQD));
		branchOut <= basicBranch(setInstructionTarget(dataIQD, branchTarget), sysRegValue, branchLink);
				
		lsOut <= setExecState(execData(ExecC1), memLoadValue, '0', "0000");
		
-------------------------------------------------------------------------------------------------
	-- Event selection
										
		execEventSignal <= (execData(ExecD0).controlInfo.newEvent and execResponses(ExecD0).isNew);
	
		-- NOTE: alternatively,here would be lastCommittedNext, and instructions in CQ certain to be committed in
		--			nearest cycle would be spared from killing (CAREFUL: needed collaboration from CQ killer)
		intCausing <= intCausingIn;
		execCausing <= execData(ExecD0);
		
		eventSignal <= execOrIntEventSignalIn;	
		activeCausing <= execOrIntCausingIn;	
				
		-- CAREFUL! In all automatic blocks for exec, remember about correct range of stages!
		EXEC_KILL: for s in ExecStages'left to ExecStages'right generate
			signal before: std_logic;
			signal a, b: std_logic_vector(7 downto 0);
		begin
			a <= activeCausing.numberTag; -- CAREFUL: if separated execEvent/interrupt, use execCausing,
													--				and don't use tags from intCausing
			b <= execData(s).numberTag;
						
			before <= tagBefore(a, b);		
			execDrives(s).kill <= killByTag(before, eventSignal, intSig); -- before and eventSignal;
												--	execEventSignal) or intSig;
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
	
		execAcceptingA <= execResponses(ExecA0).accepting;
		execAcceptingB <= execResponses(ExecB0).accepting;
		execAcceptingC <= execResponses(ExecC0).accepting;
		execAcceptingD <= execResponses(ExecD0).accepting;	
	
		execReadyVec <= (0 => readyExecA, 1 => readyExecB, 2 => readyExecC, 3 => readyExecD, others=>'0');
		selectedToCQ <= execReadyVec;
		
		cqWhichSend <= (0 => execResponses(ExecA0).sending, 1 => execResponses(ExecB2).sending,
							 2 => execResponses(ExecC2).sending, 3 =>	execResponses(ExecD0).sending,
								others=>'0');
		execEndsSig <= (	0=> clearTempControlInfoSimple(execData(ExecA0)),
							1=> clearTempControlInfoSimple(execData(ExecB2)),
							2=> clearTempControlInfoSimple(execData(ExecC2)),
							3=> clearTempControlInfoSimple(execData(ExecD0)),
						others=> defaultInstructionState);
		execEnds <= execEndsSig;				


					execTags <= -- CAREFUL: using groupTag or numberTag
					(	execEndsSig(0).numberTag, execEndsSig(1).numberTag,
						execEndsSig(2).numberTag, execEndsSig(3).numberTag);						
			
		execPreEnds <= (1=> execData(ExecB1), 2=> execData(ExecC1),
						others=> defaultInstructionState);											
				
	execEvent <= execEventSignal;
	execCausingOut <= execCausing;

		memAddress <= execData(ExecC0).result;
		memStoreValue <= execData(ExecC0).argValues.arg2;

		sysRegSelect <= sysRegReadSel;
			
		sysRegWriteSelOut <= sysRegWriteSelStore;
		sysRegWriteValueOut <= sysRegWriteValueStore;
		
		-- TODO: is this correct? What about 'sending'?
		--			Don't allow multiple requests for the same transfer! Use 'isNew' flag to prevent it
		--			when stall happens?
		memLoadAllow <= execResponses(ExecC0).full when execData(ExecC0).operation.func = load else '0';
		memStoreAllow <= execResponses(ExecC0).full when execData(ExecC0).operation.func = store else '0';		
end Behavioral;

