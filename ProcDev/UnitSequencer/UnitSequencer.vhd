----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:06:59 04/24/2016 
-- Design Name: 
-- Module Name:    UnitFront - Behavioral 
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

use work.GeneralPipeDev.all;

use work.TEMP_DEV.all;

use work.ProcComponents.all;

use work.ProcLogicFront.all;
use work.ProcLogicRenaming.all;

use work.ProcLogicSequence.all;


entity UnitSequencer is
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
		
		-- Icache interface (in parallel with front pipe)
		iadr: out Mword;	-- Probably can be extracted from pcDataLiving
		iadrvalid: out std_logic; -- Seems redundant - equal to pcSending
		
		-- System reg interface
		sysRegReadSel: in slv5;
		sysRegReadValue: out Mword;
	
		-- Event/state interface						
		intSignal: in std_logic;
		execEventSignal: in std_logic;
		execCausing: in InstructionState;		
		stage0EventInfo: in StageMultiEventInfo;	
		
		execOrIntEventSignalOut: out std_logic;
		execOrIntCausingOut: out InstructionState;
			
			lateEventOut: out std_logic;
		
		--killVecOut: out std_logic_vector(0 to N_EVENT_AREAS-1);

		-- Interface PC <-> front pipe
		frontAccepting: in std_logic;
		pcSending: out std_logic;		
		pcDataLiving: out InstructionState;
		
		-- Interface Rename <-> Front 	
		frontDataLastLiving: in StageDataMulti;
		frontLastSending: in std_logic;		
		renameAccepting: out std_logic;		
		
		-- Interface from Rename with IQ	
		iqAccepts: in std_logic;
		renamedDataLiving: out StageDataMulti;
		renamedSending: out std_logic;

		-- Interface with ROB
		commitAccepting: out std_logic;
		robDataLiving: in StageDataMulti;
		sendingFromROB: in std_logic;
		
			sendingFromBQ: in std_logic;
				dataFromBQV: in StageDataMulti;
		
				sendingFromSB: in std_logic;
				dataFromSB: in InstructionState;
					sbEmpty: in std_logic;
					sbSending: in std_logic;
		
					sysStoreAllow: in std_logic;
					sysStoreAddress: in slv5; 
					sysStoreValue: in Mword;		
		
			committing: out std_logic;
		
		-- Counter outputs
		commitGroupCtrOut: out SmallNumber;
		commitGroupCtrNextOut: out SmallNumber;
		
		commitGroupCtrIncOut: out SmallNumber;
		
			committedSending: out std_logic;
			committedDataOut: out StageDataMulti;
		
			renameLockEndOut: out std_logic;
		
			newPhysDestsIn: in PhysNameArray(0 to PIPE_WIDTH-1);
			newPhysDestPointerIn: in SmallNumber;
			newPhysSourcesIn: in PhysNameArray(0 to 3*PIPE_WIDTH-1);
		
		     readyRegFlagsNextV: in std_logic_vector(0 to 3*PIPE_WIDTH-1);
		
		start: in std_logic	
	);
end UnitSequencer;

-- TODO: add feature for invalid fetch: when (not ivalid), cancel fetched instruction and 
--			jump back to repeat fetching (or cause exception etc)
architecture Behavioral of UnitSequencer is
	signal resetSig, enSig: std_logic := '0';							

	constant PC_INC: Mword := (ALIGN_BITS => '1', others => '0');	
	signal pcBase, pcNext: Mword := (others => '0');

	signal stageDataToPC, stageDataOutPC, stageDataToPC_C: InstructionState := DEFAULT_INSTRUCTION_STATE;

	signal sendingToPC, sendingOutPC, acceptingOutPC: std_logic := '0';
		
	signal generalEvents: GeneralEventInfo;

	signal excLinkInfo, intLinkInfo, newTargetInfo: InstructionBasicInfo := defaultBasicInfo;
	signal excInfoUpdate, intInfoUpdate: std_logic := '0';
		
	signal sysRegWriteAllow: std_logic := '0';
	signal currentStateSig: Mword := (others => '0');

	signal execOrIntEventSignal: std_logic := '0';
	signal execOrIntCausing, interruptCause: InstructionState := defaultInstructionState;

	signal stageDataOutRename: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	signal sendingOutRename, acceptingOutRename: std_logic:= '0';

	signal sendingToCommit, sendingOutCommit, acceptingOutCommit: std_logic := '0';
	signal stageDataToCommit, stageDataOutCommit: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;						

	signal newPhysDests: PhysNameArray(0 to PIPE_WIDTH-1) := (others=>(others=>'0'));
	signal newPhysDestPointer: SmallNumber := (others => '0');

	signal newPhysSources: PhysNameArray(0 to 3*PIPE_WIDTH-1) := (others=>(others=>'0'));							
	signal newGprTags: SmallNumberArray(0 to PIPE_WIDTH-1) := (others=>(others=>'0'));	

	signal newNumberTags: SmallNumberArray(0 to PIPE_WIDTH-1) := (others=>(others=>'0'));
	signal renameCtr, renameCtrNext, commitCtr, commitCtrNext: SmallNumber := (others => '1');
	signal renameGroupCtr, renameGroupCtrNext, commitGroupCtr, commitGroupCtrNext: SmallNumber :=
																						INITIAL_GROUP_TAG;
		signal commitGroupCtrInc: SmallNumber := (others => '0');
	
	signal effectiveMask: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
	
	signal fetchLockRequest, fetchLockCommit, fetchLockState: std_logic := '0';
	signal renameLockCommand, renameLockRelease, renameLockState, renameLockEnd: std_logic := '0';	
				
	signal dataToLastEffective, dataFromLastEffective: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;	
		signal insToLastEffective: InstructionState := DEFAULT_INSTRUCTION_STATE;	

	signal eiEvents: StageMultiEventInfo;
							
				signal TMP_targetIns: InstructionState := DEFAULT_INSTRUCTION_STATE;
			
				signal TMP_phase0, TMP_phase2: std_logic := '0';
			
			signal ch0, ch1: std_logic := '0';
				
	constant HAS_RESET_SEQ: std_logic := '0';
	constant HAS_EN_SEQ: std_logic := '0';			
begin	 
	resetSig <= reset and HAS_RESET_SEQ;
	enSig <= en or not HAS_EN_SEQ;

	pcBase <= stageDataOutPC.basicInfo.ip and i2slv(-PIPE_WIDTH*4, MWORD_SIZE); -- Clearing low bits

		pcNext <= addMwordBasic(pcBase, PC_INC);
		
		TMP_phase0 <= eiEvents.causing.controlInfo.phase0;
		TMP_phase2 <= eiEvents.causing.controlInfo.phase2;

	EVENTS: block
	begin	
		generalEvents <= NEW_generalEvents(
											stageDataOutPC,
												TMP_phase0,--eiEvents.eventOccured, 
											eiEvents.causing,
											execEventSignal, execCausing,
											stage0EventInfo.eventOccured, stage0EventInfo.causing,
											pcNext
										);

			lateEventOut <= TMP_phase0;
		execOrIntEventSignal <= execEventSignal or TMP_phase0;
		execOrIntCausing <= eiEvents.causing when TMP_phase0 = '1' else execCausing;
		
		execOrIntEventSignalOut <= execOrIntEventSignal;	-- $MODULE_OUT
		execOrIntCausingOut <= execOrIntCausing; -- $MODULE_OUT
	end block;

			stageDataToPC <= newPCData(
											stageDataOutPC,
											TMP_phase2,
											eiEvents.causing,
											execEventSignal, execCausing,
											stage0EventInfo.eventOccured, stage0EventInfo.causing,
											pcNext
										);

	-- CAREFUL: prevSending normally means that 'full' bit inside will be set, but
	--				when en = '0' this won't happen.
	--				To be fully correct, prevSending should not be '1' when receiving prevented.			
	sendingToPC <= acceptingOutPC and (sendingOutPC
												or (generalEvents.eventOccured and not generalEvents.killPC) or TMP_phase2);

	newTargetInfo <= stageDataToPC.basicInfo;

	excInfoUpdate <= eiEvents.causing.controlInfo.phase1 and eiEvents.causing.controlInfo.hasException;
	intInfoUpdate <= eiEvents.causing.controlInfo.phase1 and eiEvents.causing.controlInfo.hasInterrupt;
	
	excLinkInfo <= getLinkInfoNormal(eiEvents.causing);
	intLinkInfo <= getLinkInfoSuper(eiEvents.causing);		

	PC_STAGE: block
		signal tmpPcIn, tmpPcOut: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
		signal newSysLevel, newIntLevel: SmallNumber := (others => '0');
	begin		
		tmpPcIn.fullMask(0) <= sendingToPC;
		tmpPcIn.data(0) <= stageDataToPC;

		SUBUNIT_PC: entity work.GenericStageMulti(Behavioral) port map(
			clk => clk, reset => resetSig, en => enSig,
					
			prevSending => sendingToPC,

			nextAccepting => frontAccepting and not fetchLockState,
			stageDataIn => tmpPcIn,
			
			acceptingOut => acceptingOutPC,
			sendingOut => sendingOutPC,
			stageDataOut => tmpPcOut,
			
			execEventSignal => generalEvents.affectedVec(0),
			execCausing => DEFAULT_INSTRUCTION_STATE,
			lockCommand => '0'		
		);			
		
		newSysLevel <= currentStateSig(15 downto 8) when PROPAGATE_MODE else (others => '0');
		newIntLevel <= currentStateSig(7 downto 0) when PROPAGATE_MODE else (others => '0');
		
		stageDataOutPC.basicInfo <=
						  (ip => tmpPcOut.data(0).basicInfo.ip,
							systemLevel => newSysLevel,
							intLevel => newIntLevel);
	end block;


	SYS_REGS: block
		signal sysRegArray: MwordArray(0 to 31) := (0 => PROCESSOR_ID, others => (others => '0'));	

		alias currentState is sysRegArray(1);
		
		alias linkRegExc is sysRegArray(2);
		alias linkRegInt is sysRegArray(3);
		
		alias savedStateExc is sysRegArray(4);
		alias savedStateInt is sysRegArray(5);

		signal srWriteSel: slv5 := (others => '0');
		signal srWriteVal: Mword := (others => '0');
	begin
		sysRegWriteAllow <= sysStoreAllow;									
		srWriteSel <= sysStoreAddress;
		srWriteVal <= sysStoreValue;
	
		CLOCKED: process(clk)
		begin					
			if rising_edge(clk) then
				-- Reading sys regs
				sysRegReadValue <= sysRegArray(slv2u(sysRegReadSel));			
			
					-- CAREFUL: writing to currentState BEFORE normal sys reg write gives priority to the latter;
					--				otherwise explicit setting of currentState wouldn't work.
					--				So maybe other sys regs should have it done the same way, not conversely? 
					--				In any case, the requirement is that younger instructions must take effect later
					--				and override earlier content.

					-- Write from system write instruction
					if sysRegWriteAllow = '1' then
						sysRegArray(slv2u(srWriteSel)) <= srWriteVal;
					end if;

					-- Writing specialized fields on events
					if eiEvents.causing.controlInfo.phase1 = '1' then
						currentState <= X"0000" & TMP_targetIns.basicInfo.systemLevel & TMP_targetIns.basicInfo.intLevel;
					end if;
					
					-- NOTE: writing to link registers after sys reg writing gives priority to the former,
					--			but committing a sysMtc shouldn't happen in parallel with any control event
					-- Writing exc status registers
					if excInfoUpdate = '1' then
						linkRegExc <= excLinkInfo.ip;
						savedStateExc <= X"0000" & excLinkInfo.systemLevel & excLinkInfo.intLevel;
					end if;
					
					-- Writing int status registers
					if intInfoUpdate = '1' then
						linkRegInt <= intLinkInfo.ip;
						savedStateInt <= X"0000" & intLinkInfo.systemLevel & intLinkInfo.intLevel;
					end if;
					
					-- Enforcing content of read-only registers
					sysRegArray(0) <= PROCESSOR_ID;
					
					-- Only some number of system regs exists		
					for i in 6 to 31 loop
						sysRegArray(i) <= (others => '0');
					end loop;				
			end if;	
		end process;
		
		currentStateSig <= currentState;
	end block;


	iadr <= stageDataOutPC.basicInfo.ip and i2slv(-PIPE_WIDTH*4, MWORD_SIZE); -- Clearing low bits				
	iadrvalid <= sendingOutPC;
	
	pcDataLiving <= stageDataOutPC;
	pcSending <= sendingOutPC;	

	-- Rename stage
	RENAMING: block
		-- INPUT: newPhysSources, newPhysDests
		signal stageDataRenameIn: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;		
		signal reserveSelSig, takeVec: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0' );
		signal nToTake: integer := 0;
	begin
		-- CAREFUL, TODO: selection of changes in rename table and free list movement.
		--						Taking from list is performed in RegisterFreeList, must have the same mask!
		reserveSelSig <= getDestMask(frontDataLastLiving); 
		takeVec <= findWhichTakeReg(frontDataLastLiving); -- REG ALLOC

			nToTake <= countOnes(takeVec);

		GEN_TAGS: for i in 0 to PIPE_WIDTH-1 generate	
			-- CAREFUL, TODO: here GPR tags are selected
			newNumberTags(i) <= i2slv(binFlowNum(renameCtr) + i + 1, SMALL_NUMBER_SIZE);										
			newGprTags(i) <= 
									i2slv((slv2u(newPhysDestPointer) + nToTake) mod FREE_LIST_SIZE, SMALL_NUMBER_SIZE)
										when FREE_LIST_COARSE_REWIND = '1'
							else	i2slv((slv2u(newPhysDestPointer) + i + 1) mod FREE_LIST_SIZE, SMALL_NUMBER_SIZE);
		end generate;
	
		stageDataRenameIn <= 
			TMP_handleSpecial(
				setArgStatus(
					baptizeAll(
						renameRegs2(
							frontDataLastLiving, takeVec, reserveSelSig, newPhysSources, newPhysDests
						),
						newNumberTags, renameGroupCtrNext, newGprTags
					),
					readyRegFlagsNextV
				)	
			);
	
		SUBUNIT_RENAME: entity work.GenericStageMulti(Renaming)
		port map(
			clk => clk, reset => resetSig, en => enSig,
			
			-- Interface with front
			prevSending => frontLastSending,	
			stageDataIn => stageDataRenameIn, --readyRegFlagsV),
			acceptingOut => acceptingOutRename,
			
			-- Interface with IQ
			nextAccepting => iqAccepts,
			sendingOut => sendingOutRename,
			stageDataOut => stageDataOutRename,
			
			-- Event interface
			execEventSignal => execOrIntEventSignal,
			execCausing => execOrIntCausing,
			lockCommand => renameLockState		
		);
	end block;
				
		RENAME_SEQ_SYNCHRONOUS: process(clk) 	
		begin
			if rising_edge(clk) then
				-- Lock when exec part causes event
				if execOrIntEventSignal = '1' then -- CAREFUL
					renameLockState <= '1';	
				elsif renameLockRelease = '1' then
					renameLockState <= '0';
				end if;					
			end if;	
		end process;
			
		-- Re-allow renaming when everything from rename/exec is committed - reg map will be well defined now
		renameLockRelease <= '1' when commitGroupCtr = renameGroupCtr else '0';
			-- CAREFUL, CHECK: when the counters are equal, renaming can be resumed, but renameLockRelease
			-- 					 takes effect in next cycle, so before tha cycle renaming is still stopped.
			--						 Should compare to commitCtrNext instead?
			--						 But remember that rewinding GPR map needs a cycle, and before it happens,
			--						 renaming can't be done! So this delay may be caused by this problem.

		renameLockEnd <= renameLockState and renameLockRelease;

		commitGroupCtrInc <= i2slv(slv2u(commitGroupCtr) + PIPE_WIDTH, SMALL_NUMBER_SIZE);

	COMMON_STATE: block
	begin
		renameGroupCtrNext <= nextCtr(renameGroupCtr, execOrIntEventSignal,
												execOrIntCausing.groupTag and i2slv(-PIPE_WIDTH, SMALL_NUMBER_SIZE),
												frontLastSending, ALL_FULL);
		renameCtrNext <= nextCtr(renameCtr, execOrIntEventSignal, execOrIntCausing.numberTag,
										 frontLastSending, frontDataLastLiving.fullMask);

		commitGroupCtrNext <= nextCtr(commitGroupCtr, '0', (others => '0'), sendingToCommit, ALL_FULL);
		commitCtrNext <= nextCtr(commitCtr, '0', (others => '0'), sendingToCommit, effectiveMask);

		effectiveMask <= getEffectiveMask(stageDataToCommit);
			
		PIPE_SYNCHRONOUS: process(clk) 	
		begin
			if rising_edge(clk) then
				renameCtr <= renameCtrNext;
				commitCtr <= commitCtrNext;					
				renameGroupCtr <= renameGroupCtrNext;
				commitGroupCtr <= commitGroupCtrNext;
			end if;
		end process;	
	end block;

	sendingToCommit <= sendingFromROB;
	committing <= sendingFromROB;

	-- Commit stage: in order again				
	SUBUNIT_COMMIT: entity work.GenericStageMulti(Behavioral)
	port map(
		clk => clk, reset => resetSig, en => enSig,
		
		-- Interface with CQ
		prevSending => sendingToCommit,
		stageDataIn => stageDataToCommit,
		acceptingOut => open, -- unused but don't remove
		
		-- Interface with hypothetical further stage
		nextAccepting => '1',
		sendingOut => sendingOutCommit,
		stageDataOut => stageDataOutCommit,
		
		-- Event interface
		execEventSignal => '0', -- CAREFUL: committed cannot be killed!
		execCausing => execOrIntCausing,		

		lockCommand => '0'
	);

			-- Tracking of target:
			--			'target' field of last effective will hold the address of next instruction
			--			to commit after lastEffective; it will be known with certainty because lastEffective is 
			--			already committed. 
			--			When committing a taken branch -> fill with target from BQ output
			--			When committing normal op -> increment by length of the op 
			--			
			--			The 'target' field will be used to update return address for exc/int
			stageDataToCommit <= recreateGroup(robDataLiving, dataFromBQV, dataFromLastEffective.data(0).target);
			insToLastEffective <= getLastEffective(stageDataToCommit);		
				
				TMP_targetIns <= getLatePCData('1', eiEvents.causing);
											
				interruptCause.controlInfo.hasInterrupt <= intSignal;
				interruptCause.controlInfo.hasReset <= start;
				interruptCause.target <= TMP_targetIns.basicInfo.ip;

			dataToLastEffective.fullMask(0) <= sendingToCommit;
			dataToLastEffective.data(0) <= insToLastEffective;

			LAST_EFFECTIVE_SLOT: entity work.GenericStageMulti(LastEffective)
			port map(
				clk => clk, reset => resetSig, en => enSig,
				
				-- Interface with CQ
				prevSending => sendingToCommit,
				stageDataIn => dataToLastEffective,-- TMPpre_lastEffective,
				acceptingOut => open, -- unused but don't remove
				
				-- Interface with hypothetical further stage
				nextAccepting => '1',
				sendingOut => open,
				stageDataOut => dataFromLastEffective,--TMP_lastEffective,
				
				-- Event interface
				execEventSignal => '0', -- CAREFUL: committed cannot be killed!
				execCausing => interruptCause,		

				lockCommand => not sbEmpty,

				stageEventsOut => eiEvents
			);
			
	renameAccepting <= acceptingOutRename;
	renamedDataLiving <= stageDataOutRename;
	renamedSending <= sendingOutRename;
	
	commitGroupCtrOut <= commitGroupCtr;
	commitGroupCtrNextOut <= commitGroupCtrNext;

	commitGroupCtrIncOut <= commitGroupCtrInc;

		newPhysDests <= newPhysDestsIn;
		newPhysDestPointer <= newPhysDestPointerIn;
		newPhysSources <= newPhysSourcesIn;

		renameLockEndOut <= renameLockEnd;

		commitAccepting <= '1';

		committedSending <= sendingOutCommit;
		committedDataOut <= stageDataOutCommit;
end Behavioral;

