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
	
		sysRegWriteSel: in slv5;
		sysRegWriteValue: in Mword;		
	
		-- Event/state interface						
		intSignal: in std_logic;
		execEventSignal: in std_logic;
		execCausing: in InstructionState;		
		stage0EventInfo: in StageMultiEventInfo;	
		
		execOrIntEventSignalOut: out std_logic;
		execOrIntCausingOut: out InstructionState;
		
		killVecOut: out std_logic_vector(0 to N_EVENT_AREAS-1);

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
			dataFromBQ: in InstructionState;
		
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
	signal pcBase, pcNext, causingNext: Mword := (others => '0');

	signal stageDataToPC, stageDataOutPC, stageDataToPC_C: InstructionState := DEFAULT_INSTRUCTION_STATE;

	signal sendingToPC, sendingOutPC, acceptingOutPC: std_logic := '0';
		
	signal generalEvents, newGeneralEvents: GeneralEventInfo;

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

		signal stageDataToCommit_2, stageDataOutCommit_2: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;				

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
		signal insToLastEffective_2: InstructionState := DEFAULT_INSTRUCTION_STATE;	

				signal sendingLateEvent: std_logic := '0';
				signal dataFromLateEvent: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

	signal eiEvents, lateEvents: StageMultiEventInfo;
			
		signal newEffectiveTarget: Mword := (others => '0'); -- DEPREC

				signal TMP_writeEventTarget, TMP_waitForEmptySB: std_logic := '0'; -- DEPREC
				
				signal TMP_targetIns: InstructionState := DEFAULT_INSTRUCTION_STATE;
			
			signal ch0, ch1: std_logic := '0';
				
	constant HAS_RESET_SEQ: std_logic := '1';
	constant HAS_EN_SEQ: std_logic := '1';			
begin	 
	resetSig <= reset and HAS_RESET_SEQ;
	enSig <= en or not HAS_EN_SEQ;

	CAUSING_ADDER: entity work.IntegerAdder
	port map(
		inA => generalEvents.causing.basicInfo.ip,
		inB => getAddressIncrement(generalEvents.causing),
		output => causingNext
	);
		
	pcBase <= stageDataOutPC.basicInfo.ip and i2slv(-PIPE_WIDTH*4, MWORD_SIZE); -- Clearing low bits

	SEQ_ADDER: entity work.IntegerAdder
	port map(
		inA => pcBase,
		inB => PC_INC,
		output => pcNext
	);

	EVENTS: block
		-- $INPUT: 
		--		stage0EventInfo, execEventSignal, execCausing, eiEvents
		-- $OUTPUT:
		-- 	execOrIntCausing, execOrIntEventSignal, killVecOut, generalEvents,

			signal committingSync, committingRet: std_logic := '0';			
	begin	
			killVecOut(6) <= eiEvents.eventOccured;
			killVecOut(5) <= execOrIntEventSignal;
			killVecOut(0 to 4) <= newGeneralEvents.affectedVec;

		generalEvents <= newGeneralEvents;
			newGeneralEvents <= NEW_generalEvents(
											stageDataOutPC,
											eiEvents.eventOccured, eiEvents.causing,
											execEventSignal, execCausing,
											stage0EventInfo.eventOccured, stage0EventInfo.causing,
											pcNext, causingNext
										);

		execOrIntEventSignal <= execEventSignal or eiEvents.eventOccured;
		execOrIntCausing <= eiEvents.causing when eiEvents.eventOccured = '1' else execCausing;
		
		execOrIntEventSignalOut <= execOrIntEventSignal;	-- $MODULE_OUT
		execOrIntCausingOut <= execOrIntCausing; -- $MODULE_OUT
		
			committingSync <= sbSending when dataFromSB.operation = (System, sysSync) else '0';
			committingRet <= sbSending when 
				(dataFromSB.operation = (System, sysRetI) or dataFromSB.operation = (System, sysRetE)) else '0';
	end block;

			stageDataToPC <= newPCData(
											stageDataOutPC,
											eiEvents.eventOccured, eiEvents.causing,
											execEventSignal, execCausing,
											stage0EventInfo.eventOccured, stage0EventInfo.causing,
											pcNext, causingNext
										);
									--newGeneralEvents.newStagePC;					

	-- CAREFUL: prevSending normally means that 'full' bit inside will be set, but
	--				when en = '0' this won't happen.
	--				To be fully correct, prevSending should not be '1' when receiving prevented.			
	sendingToPC <= acceptingOutPC and (sendingOutPC
												or (generalEvents.eventOccured and not generalEvents.killPC));

	newTargetInfo <= stageDataToPC.basicInfo;

	excInfoUpdate <= eiEvents.causing.controlInfo.phase1 and eiEvents.causing.controlInfo.hasException;
	intInfoUpdate <= eiEvents.causing.controlInfo.phase1 and eiEvents.causing.controlInfo.hasInterrupt;
	
	excLinkInfo <= getLinkInfoNormal(eiEvents.causing, causingNext);
	intLinkInfo <= getLinkInfoSuper(eiEvents.causing, causingNext);		

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
					-- CAREFUL: writing to currentState BEFORE normal sys reg write gives priority to the latter;
					--				otherwise explicit setting of currentState wouldn't work.
					--				So maybe other sys regs should have it done the same way, not conversely? 
					--				In any case, the requirement is that younger instructions must take effect later
					--				and override earlier content.

					-- Write currentState (control flow may be just changing it)					
					if sendingToPC = '1' then
						currentState <= X"0000" & newTargetInfo.systemLevel & newTargetInfo.intLevel;						
					end if;
					
					-- Write from system write instruction
					if sysRegWriteAllow = '1' then
						sysRegArray(slv2u(srWriteSel)) <= srWriteVal;
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
		sysRegReadValue <= sysRegArray(slv2u(sysRegReadSel));							
	end block;

	
	fetchLockRequest <= generalEvents.eventOccured and generalEvents.causing.controlInfo.newFetchLock;

		FRONT_SEQ_SYNCHRONOUS: process(clk) 	
		begin
			if rising_edge(clk) then
				if fetchLockRequest = '1' then
					fetchLockState <= '1';
				elsif (fetchLockCommit or generalEvents.eventOccured) = '1' then
					fetchLockState <= '0';
				end if;				
			end if;	
		end process;

	fetchLockCommit <= fetchLockCommitting(stageDataToCommit, effectiveMask);

	iadr <= stageDataOutPC.basicInfo.ip and i2slv(-PIPE_WIDTH*4, MWORD_SIZE); -- Clearing low bits				
	iadrvalid <= sendingOutPC;
	
	pcDataLiving <= stageDataOutPC;
	pcSending <= sendingOutPC;	

	-- Rename stage
	RENAMING: block
		-- INPUT: newPhysSources, newPhysDests
		signal stageDataRenameIn: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;		
		signal reserveSelSig, takeVec: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0' );
	begin	
		reserveSelSig <= getDestMask(frontDataLastLiving);
		takeVec <= (others => '1') when ALLOC_REGS_ALWAYS
				else frontDataLastLiving.fullMask;		

		GEN_TAGS: for i in 0 to PIPE_WIDTH-1 generate	
			newNumberTags(i) <= i2slv(binFlowNum(renameCtr) + i + 1, SMALL_NUMBER_SIZE);											
			newGprTags(i) <= i2slv((slv2u(newPhysDestPointer) + i) mod FREE_LIST_SIZE, SMALL_NUMBER_SIZE);
		end generate;
	
		stageDataRenameIn <= 
			setArgStatus(
				baptizeAll(
					renameRegs2(
						frontDataLastLiving, takeVec, reserveSelSig, newPhysSources, newPhysDests
					),
					newNumberTags, renameGroupCtrNext, newGprTags
				),
				readyRegFlagsNextV
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

		effectiveMask <= getEffectiveMask(stageDataToCommit_2);
			
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
	stageDataToCommit.fullMask <= stageDataToCommit_2.fullMask;
	stageDataToCommit.data <= stageDataToCommit_2.data;

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
			--			When committing 1st op after expception/int -> fill with content of tempBuffer*
			--			*tempBuffer will be set to handler address of exception/int when it's signaled
			--			
			--			The 'target' field will be used to update return address for exc/int
			NEW_TARGET: block
				signal tempBuffWaiting: std_logic := '0';
				signal tempBuffValue: Mword := (others => '0');				
			begin

				stageDataToCommit_2 <= recreateGroup(robDataLiving, dataFromBQV, 
																	dataFromLastEffective.data(0).target,
																	tempBuffValue, tempBuffWaiting);
					insToLastEffective_2 <= getLastEffective(stageDataToCommit_2);		

				SYNCH: process(clk)
				begin
					if rising_edge(clk) then
						if eiEvents.eventOccured = '1' then 
							tempBuffWaiting <= '1';
							tempBuffValue <= stageDataToPC.basicInfo.ip;
						elsif sendingFromROB = '1' then -- when committing
							tempBuffWaiting <= '0';
						end if;
					end if;
				end process;
			end block;
				
				TMP_targetIns <= getLatePCData(
											stageDataOutPC,
											eiEvents.eventOccured, eiEvents.causing,
											execEventSignal, execCausing,
											stage0EventInfo.eventOccured, stage0EventInfo.causing,
											pcNext, causingNext);
											
			interruptCause.controlInfo.hasInterrupt <= intSignal;
			interruptCause.controlInfo.hasReset <= start;
				interruptCause.target <= TMP_targetIns.basicInfo.ip;

			dataToLastEffective.fullMask(0) <= sendingToCommit;
			dataToLastEffective.data(0) <= insToLastEffective_2;

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

			LATE_EVENT_SLOT: entity work.GenericStageMulti(LastEffective)
			port map(
				clk => clk, reset => resetSig, en => enSig,
				
				-- Interface with CQ
				prevSending => sendingToCommit,
				stageDataIn => dataToLastEffective,-- TMPpre_lastEffective,
				acceptingOut => open, -- unused but don't remove
				
				-- Interface with hypothetical further stage
				nextAccepting => sbEmpty or not lateEvents.eventOccured,
				sendingOut => sendingLateEvent,
				stageDataOut => dataFromLateEvent,--TMP_lastEffective,
				
				-- Event interface
				execEventSignal => '0', -- CAREFUL: committed cannot be killed!
				execCausing => interruptCause,		

				lockCommand => '0',

				stageEventsOut => lateEvents
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

