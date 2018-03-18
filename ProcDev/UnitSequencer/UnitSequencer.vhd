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
use work.ProcHelpers.all;

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
		iadr: out Mword;	-- REDUNDANT: Probably can be extracted from pcDataLiving
		iadrvalid: out std_logic; -- REDUNDANT - equal to pcSending
		
		-- System reg interface
		sysRegReadSel: in slv5;
		sysRegReadValue: out Mword;
	
		-- Event/state interface						
		intSignal: in std_logic;
		execEventSignal: in std_logic;
		execCausing: in InstructionState;		
		
			frontEventSignal: in std_logic;
			frontCausing: in InstructionState;
		
		execOrIntEventSignalOut: out std_logic;
		execOrIntCausingOut: out InstructionState;	
			lateEventOut: out std_logic;
			lateEventSetPC: out std_logic;
			lateCausing : out InstructionState;
		
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
		
				dataFromBQV: in StageDataMulti;
		
				dataFromSB: in InstructionState;
					sbEmpty: in std_logic;
					sbSending: in std_logic;
		
					sysStoreAllow: in std_logic;
					sysStoreAddress: in slv5; 
					sysStoreValue: in Mword;		
		
			committing: out std_logic;
		
		-- Counter outputs
		commitGroupCtrOut: out InsTag;
		commitGroupCtrNextOut: out InsTag;
		
		commitGroupCtrIncOut: out InsTag;
		
			committedSending: out std_logic;
			committedDataOut: out StageDataMulti;
		
			renameLockEndOut: out std_logic;
		
			newPhysDestsIn: in PhysNameArray(0 to PIPE_WIDTH-1);
			newPhysDestPointerIn: in SmallNumber;
			newPhysSourcesIn: in PhysNameArray(0 to 3*PIPE_WIDTH-1);
		
		start: in std_logic	-- TODO: change to reset interrupt
	);
end UnitSequencer;


architecture Behavioral of UnitSequencer is
	signal resetSig, enSig: std_logic := '0';							

	signal pcBase, pcNext: Mword := (others => '0');

	signal stageDataToPC, stageDataOutPC: InstructionState := DEFAULT_INSTRUCTION_STATE;
	signal sendingToPC, sendingOutPC, acceptingOutPC: std_logic := '0';

	signal tmpPcIn, tmpPcOut: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

	signal excLinkInfo, intLinkInfo: InstructionBasicInfo := defaultBasicInfo;
	signal excInfoUpdate, intInfoUpdate: std_logic := '0';

	signal execOrIntEventSignal: std_logic := '0';
	signal execOrIntCausing, interruptCause: InstructionState := defaultInstructionState;

	signal stageDataRenameIn: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;		

	signal stageDataOutRename: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	signal sendingOutRename, acceptingOutRename: std_logic:= '0';

	signal sendingToCommit, sendingOutCommit, acceptingOutCommit: std_logic := '0';
	signal stageDataToCommit, stageDataOutCommit: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;						

	signal renameCtr, renameCtrNext, commitCtr, commitCtrNext: InsTag := (others => '1');
	signal renameGroupCtr, renameGroupCtrNext, commitGroupCtr, commitGroupCtrNext: InsTag :=
																						INITIAL_GROUP_TAG;
	signal commitGroupCtrInc: InsTag := (others => '0');
	
	signal effectiveMask: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
	
	signal fetchLockRequest, fetchLockCommit, fetchLockState: std_logic := '0';
	signal renameLockCommand, renameLockRelease, renameLockState, renameLockEnd: std_logic := '0';	
				
	signal dataToLastEffective, dataFromLastEffective: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;	
	signal insToLastEffective: InstructionState := DEFAULT_INSTRUCTION_STATE;	

	signal eiEvents: StageMultiEventInfo;
							
	signal TMP_targetIns: InstructionState := DEFAULT_INSTRUCTION_STATE;		
	signal TMP_phase0, TMP_phase2: std_logic := '0';
			
	signal gE_eventOccurred, gE_killPC, ch0, ch1: std_logic := '0';
	
	constant HAS_RESET_SEQ: std_logic := '0';
	constant HAS_EN_SEQ: std_logic := '0';
begin	 
	resetSig <= reset and HAS_RESET_SEQ;
	enSig <= en or not HAS_EN_SEQ;
		
	TMP_phase0 <= eiEvents.causing.controlInfo.phase0;
	TMP_phase2 <= eiEvents.causing.controlInfo.phase2;

	EVENTS: block
	begin	
			gE_killPC <= TMP_phase0;
			gE_eventOccurred <= TMP_phase0 or execEventSignal or frontEventSignal;

			lateEventOut <= TMP_phase0;
			lateEventSetPC <= TMP_phase2;
		execOrIntEventSignal <= TMP_phase0 or execEventSignal;
		execOrIntCausing <= eiEvents.causing when TMP_phase0 = '1' else execCausing;
		lateCausing <= eiEvents.causing;

		execOrIntEventSignalOut <= execOrIntEventSignal;	-- $MODULE_OUT
		execOrIntCausingOut <= execOrIntCausing; -- $MODULE_OUT
	end block;

	pcBase <= stageDataOutPC.basicInfo.ip and i2slv(-PIPE_WIDTH*4, MWORD_SIZE); -- Clearing low bits
	pcNext <= getNextPC(stageDataOutPC.basicInfo.ip, (others => '0'), '0');

	stageDataToPC <= newPCData(TMP_phase2, eiEvents.causing,
										execEventSignal, execCausing,
										frontEventSignal, frontCausing,
										pcNext);

	-- CAREFUL: prevSending normally means that 'full' bit inside will be set, but
	--				when en = '0' this won't happen.
	--				To be fully correct, prevSending should not be '1' when receiving prevented.			
	sendingToPC <= acceptingOutPC and 
					  (sendingOutPC or (gE_eventOccurred and not gE_killPC)
										or (TMP_phase2 and not isHalt(eiEvents.causing)));
										-- CAREFUL: Because of the above, PC is not updated in phase2 of halt instruction,
										--				so the PC of a halted logical processor is not defined.

		tmpPcIn <= makeSDM((0 => (sendingToPC, stageDataToPC)));

		SUBUNIT_PC: entity work.GenericStageMulti(Behavioral) port map(
			clk => clk, reset => resetSig, en => enSig,
					
			prevSending => sendingToPC,

			nextAccepting => frontAccepting and not fetchLockState,
			stageDataIn => tmpPcIn,
			
			acceptingOut => acceptingOutPC,
			sendingOut => sendingOutPC,
			stageDataOut => tmpPcOut,
			
			execEventSignal => gE_eventOccurred,
			lateEventSignal => TMP_phase0,
			execCausing => DEFAULT_INSTRUCTION_STATE,
			lockCommand => '0'		
		);			

		stageDataOutPC.basicInfo.ip <= tmpPcOut.data(0).basicInfo.ip;
		stageDataOutPC.target <= pcNext; -- CAREFUL: Attaching next address from line predictor. Correct?

	-- TODO: signals for updating sys regs can be moved to sys reg block
	excInfoUpdate <= eiEvents.causing.controlInfo.phase1 and eiEvents.causing.controlInfo.hasException;
	intInfoUpdate <= eiEvents.causing.controlInfo.phase1 and eiEvents.causing.controlInfo.hasInterrupt;
	
	excLinkInfo <= getLinkInfoNormal(eiEvents.causing);
	intLinkInfo <= getLinkInfoSuper(eiEvents.causing);		
	----------------------------------------------------------------------
	
	SYS_REGS: block
		signal sysRegArray: MwordArray(0 to 31) := (0 => PROCESSOR_ID, others => (others => '0'));	

		alias currentState is sysRegArray(1);
		alias linkRegExc is sysRegArray(2);
		alias linkRegInt is sysRegArray(3);
		alias savedStateExc is sysRegArray(4);
		alias savedStateInt is sysRegArray(5);
	begin
		CLOCKED: process(clk)
		begin					
			if rising_edge(clk) then
				-- Reading sys regs
				sysRegReadValue <= sysRegArray(slv2u(sysRegReadSel));			

				-- Write from system write instruction
				if sysStoreAllow = '1' then
					sysRegArray(slv2u(sysStoreAddress)) <= sysStoreValue;
				end if;

				-- Writing specialized fields on events
				if eiEvents.causing.controlInfo.phase1 = '1' then
					currentState <= X"0000" & TMP_targetIns.basicInfo.systemLevel & TMP_targetIns.basicInfo.intLevel;
					currentState(15 downto 10) <= (others => '0');
					currentState(7 downto 2) <= (others => '0');
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
		
--		currentStateSig <= currentState;
		
		TMP_targetIns <= getLatePCData('1', eiEvents.causing,
													linkRegExc, linkRegInt,
													savedStateExc, savedStateInt); -- Here, because needs sys regs
	end block;

	iadr <= pcBase; -- Clearing low bits				
	iadrvalid <= sendingOutPC;
	
	pcDataLiving <= stageDataOutPC;
	pcSending <= sendingOutPC;	

	-- Rename stage
		stageDataRenameIn <= renameGroup(frontDataLastLiving, newPhysSourcesIn, newPhysDestsIn, renameCtr,
															renameGroupCtrNext, newPhysDestPointerIn);
	
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
			lateEventSignal => TMP_phase0,		
			execCausing => execOrIntCausing,
			lockCommand => renameLockState		
		);
--	end block;

	COMMON_STATE: block
	begin
		renameGroupCtrNext <= nextCtr(renameGroupCtr, execOrIntEventSignal,
												execOrIntCausing.tags.renameIndex and i2slv(-PIPE_WIDTH, TAG_SIZE),
												frontLastSending, ALL_FULL);
		renameCtrNext <= nextCtr(renameCtr, execOrIntEventSignal, execOrIntCausing.tags.renameSeq,
										 frontLastSending, frontDataLastLiving.fullMask);
		commitGroupCtrNext <= nextCtr(commitGroupCtr, '0', (others => '0'), sendingToCommit, ALL_FULL);
		commitCtrNext <= nextCtr(commitCtr, '0', (others => '0'), sendingToCommit, effectiveMask);

		commitGroupCtrInc <= i2slv(slv2u(commitGroupCtr) + PIPE_WIDTH, TAG_SIZE);

		-- Re-allow renaming when everything from rename/exec is committed - reg map will be well defined now
		renameLockRelease <= '1' when commitGroupCtr = renameGroupCtr else '0';
			-- CAREFUL, CHECK: when the counters are equal, renaming can be resumed, but renameLockRelease
			-- 					 takes effect in next cycle, so before tha cycle renaming is still stopped.
			--						 Should compare to commitCtrNext instead?
			--						 But remember that rewinding GPR map needs a cycle, and before it happens,
			--						 renaming can't be done! So this delay may be caused by this problem.

		renameLockEnd <= renameLockState and renameLockRelease;

		effectiveMask <= getEffectiveMask(stageDataToCommit);
			
		COMMON_SYNCHRONOUS: process(clk) 	
		begin
			if rising_edge(clk) then
				renameCtr <= renameCtrNext;
				commitCtr <= commitCtrNext;					
				renameGroupCtr <= renameGroupCtrNext;
				commitGroupCtr <= commitGroupCtrNext;

				-- Lock when exec part causes event
				if execOrIntEventSignal = '1' then -- CAREFUL
					renameLockState <= '1';	
				elsif renameLockRelease = '1' then
					renameLockState <= '0';
				end if;					
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
		lateEventSignal => '0',	
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
		dataToLastEffective <= makeSDM((0 => (sendingToCommit, insToLastEffective)));

		interruptCause <= makeInterruptCause(TMP_targetIns, intSignal, start);

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
				lateEventSignal => '0',	
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

		renameLockEndOut <= renameLockEnd;
		commitAccepting <= '1';
		committedSending <= sendingOutCommit;
		committedDataOut <= stageDataOutCommit;
end Behavioral;

