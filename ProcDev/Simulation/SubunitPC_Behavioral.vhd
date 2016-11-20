
architecture Behavioral of SubunitPC is	
	signal flowDrivePC: FlowDriveSimple := (others=>'0');
	signal flowResponsePC: FlowResponseSimple := (others=>'0');
	
	signal targetInfo: InstructionBasicInfo := defaultBasicInfo;
	signal targetPC: Mword := INITIAL_PC; --(others => '0');
	
	signal pcNext: Mword := (others => '0');
	signal pcBase: Mword := (others => '0'); 
	constant pcInc: Mword := (ALIGN_BITS => '1', others => '0');
	
	signal causingNext: Mword := (others => '0');
	signal causingPC: Mword := (others => '0');
	signal causingInc: Mword := (others => '0');

	signal committingNext: Mword := (others => '0');
	signal committingPC: Mword := (others => '0');
	signal committingInc: Mword := (others => '0');
	
	signal sysRegArray: MwordArray(0 to 31) := (0 => PROCESSOR_ID, others => (others => '0'));	
	
	alias linkRegExc is sysRegArray(2);
	alias linkRegInt is sysRegArray(3);
	
	alias savedStateExc is sysRegArray(4);
	alias savedStateInt is sysRegArray(5);	
	
	alias currentState is sysRegArray(1);
			
	signal full, fullNext, living, killed, accepting, remaining, sending, receiving: std_logic := '0';
		
	signal stageData, stageDataNext, stageDataNew: InstructionState := DEFAULT_INSTRUCTION_STATE;		
begin	
	committingPC <= lastCommittedNextIn.basicInfo.ip;
	committingInc <= getAddressIncrement(lastCommittedNextIn);
	
	causingPC <= frontEvents.causing.basicInfo.ip;
	causingInc <= getAddressIncrement(frontEvents.causing);
	 
	 
		committingNext <= addMword(committingPC, committingInc);
		causingNext <= addMword(causingPC, causingInc);
		pcBase <= stageData.basicInfo.ip and i2slv(-PIPE_WIDTH*4, MWORD_SIZE);
			
		pcNext <= addMword(pcBase, pcInc);
		
	stageDataNew <= newPCData(stageData, frontEvents, pcNext, causingNext);--, linkInfoExc, linkInfoInt);
	stageDataNext <= stageSimpleNext(stageData, stageDataNew,
											flowResponsePC.living, flowResponsePC.sending, flowDrivePC.prevSending);

	FRONT_CLOCKED: process(clk)
		variable linkInfoExcVar, linkInfoIntVar: InstructionBasicInfo := defaultBasicInfo;	
		variable targetInfoVar: InstructionBasicInfo := defaultBasicInfo;
	begin					
		if rising_edge(clk) then
			if reset = '1' then

			elsif en = '1' then
			
				--	full <= fullNext;
			
				-- CAREFUL: writing to currentState BEFORE normal sys reg write gives priority to the latter;
				--				otherwise explicit setting of currentState wouln't work.
				--				So maybe other sys regs should have it done the same way, not conversely? 
				--				In any case, the requirement is that younger instructions must take effect later
				--				and override earlier content. 	
				targetInfoVar := stageDataNext.basicInfo;
				targetPC <= targetInfoVar.ip;
				currentState <= X"0000" & targetInfoVar.systemLevel & targetInfoVar.intLevel;
				
				if sysRegWriteAllow = '1' then
					sysRegArray(slv2u(sysRegWriteSel)) <= sysRegWriteValue;
				end if;
				
				-- NOTE: writing to link registers after sys reg writing gives priority to the former,
				--			but committing a sysMtc shouldn't happen in parallel with any control event
				if committingIn = '1' and lastCommittedNextIn.controlInfo.hasException = '1' then
						linkInfoExcVar := getLinkInfoNormal(lastCommittedNextIn, committingNext);
						linkRegExc <= linkInfoExcVar.ip;
						savedStateExc <= X"0000" & linkInfoExcVar.systemLevel & linkInfoExcVar.intLevel;						
						
				elsif	(frontEvents.eventOccured and frontEvents.causing.controlInfo.newInterrupt) = '1' then
					linkInfoIntVar := getLinkInfoSuper(frontEvents.causing, causingNext);
					linkRegInt <= --getSuperTargetAddress(frontEvents.causing, causingNext);
										linkInfoIntVar.ip;
					savedStateInt <= X"0000" & linkInfoIntVar.systemLevel & linkInfoIntVar.intLevel;						
				end if;
				
				sysRegArray(0) <= PROCESSOR_ID;
				
				-- Only some number of system regs exists		
				for i in 6 to 31 loop
					sysRegArray(i) <= (others => '0');
				end loop;

				logSimple(stageData, flowResponsePC);
			end if;					
		end if;
	end process;

	SIMPLE_SLOT_LOGIC_PC: SimplePipeLogic port map(
		clk => clk, reset => reset, en => en,
		flowDrive => flowDrivePC,
		flowResponse => flowResponsePC
	);		

		stageData.basicInfo <= targetInfo; -- To have regular representation as InstructionState

		targetInfo <= (ip => targetPC,
							systemLevel => currentState(15 downto 8),
							intLevel => currentState(7 downto 0));		
			
	flowDrivePC.prevSending <= flowResponsePC.accepting; -- CAREFUL! This way it never gets hungry
	flowDrivePC.nextAccepting <= nextAccepting;	

	flowDrivePC.kill <= frontEvents.affectedVec(0);		
	flowDrivePC.lockSend <= lockSendCommand;

	stageDataOut <= stageData;
	acceptingOut <= flowResponsePC.accepting; -- Used anywhere?
	sendingOut <= flowResponsePC.sending;
		
	sysRegReadValue <= sysRegArray(slv2u(sysRegReadSel));							
end Behavioral;

