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

--use work.CommonRouting.all;
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
		intCausingOut: out InstructionState;
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
			
		-- Interface to Commit with CQ
		cqDataLiving: in StageDataMulti;
		anySendingFromCQ: in std_logic;
		-- 'accepting' signal missing, because assumed always true
		
		-- Interface with ROB
		robDataLiving: in StageDataMulti;
		sendingFromROB: in std_logic;
											
		readyRegFlagsOut: out std_logic_vector(0 to 3*PIPE_WIDTH-1);
		
		-- Counter outputs
		--	commitCtrNextOut: out SmallNumber;
		commitGroupCtrOut: out SmallNumber;
		commitGroupCtrNextOut: out SmallNumber;
		
		start: in std_logic	
	);
end UnitSequencer;

-- TODO: add feature for invalid fetch: when (not ivalid), cancel fetched instruction and 
--			jump back to repeat fetching (or cause exception etc)
architecture Behavioral of UnitSequencer is
	signal resetSig, enSig: std_logic := '0';							
	
	signal stageDataOutPC: InstructionState := DEFAULT_INSTRUCTION_STATE;
	signal sendingOutPC: std_logic := '0';
	signal acceptingOutPC: std_logic := '0';
		
	signal frontEvents: FrontEventInfo;
		
		signal frontEventSig: std_logic := '0';
		signal sysRegWriteAllow: std_logic := '0';

		signal execOrIntEventSignal: std_logic := '0';
		signal execOrIntCausing, intCausing: InstructionState := defaultInstructionState;
-------------------------------
		signal committing: std_logic := '0';
	

		signal stageDataRenameIn: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	
		signal stageDataOutRename: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
		signal sendingOutRename: std_logic:= '0';
		signal acceptingOutRename: std_logic := '0';

		signal stageDataOutCommit: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
		signal sendingOutCommit: std_logic:= '0';
		signal acceptingOutCommit: std_logic := '0';

	signal anySendingFromCQSig: std_logic := '0';
						
		signal sendingToCommit: std_logic := '0';
		signal stageDataToCommit: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
						
						
	signal newPhysDests, physCommitDests, physCommitDestsDelayed,
			physCommitFreedDelayed,
			physStable, physStableDelayed: 
					PhysNameArray(0 to PIPE_WIDTH-1) := (others=>(others=>'0'));
					
	signal newPhysSources: PhysNameArray(0 to 3*PIPE_WIDTH-1) := (others=>(others=>'0'));	-- linking							
	signal newGprTags: SmallNumberArray(0 to PIPE_WIDTH-1) := (others=>(others=>'0'));	

	signal newNumberTags: SmallNumberArray(0 to PIPE_WIDTH-1) := (others=>(others=>'0'));
	signal renameCtr, renameCtrNext, commitCtr, commitCtrNext: SmallNumber := --(others=>'0');
																										(others => '1');
	signal renameGroupCtr, renameGroupCtrNext, commitGroupCtr, commitGroupCtrNext: SmallNumber :=
																						INITIAL_GROUP_TAG;
	
	signal stableUpdateSel, stableUpdateSelDelayed:
									std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');

	-- CAREFUL, CHECK: to enable restoring from last committed
	signal lastCommitted, lastCommittedNext: InstructionState := defaultLastComitted;
	
	signal fetchLockRequest, fetchLockCommit, fetchLockState: std_logic := '0';
	signal renameLockCommand, renameLockRelease, renameLockState: std_logic := '0';	
	
	signal readyRegsSig: std_logic_vector(0 to N_PHYSICAL_REGS-1) := (0 to 31 => '1', others=>'0');
	signal readyRegFlags, readyRegFlagsNext: std_logic_vector(0 to 3*PIPE_WIDTH-1) := (others => '0');
				
	constant HAS_RESET_SEQ: std_logic := '1';
	constant HAS_EN_SEQ: std_logic := '1';			
begin	 
	resetSig <= reset and HAS_RESET_SEQ;
	enSig <= en or not HAS_EN_SEQ;
								
	-- PC stage															
	SUBUNIT_PC: entity work.SubunitPC(--Behavioral)
													Implem)
	port map(
		clk => clk, reset => resetSig, en => enSig,
		
		-- Committed/being committed
		lastCommittedNextIn => lastCommittedNext,
		committingIn => committing,
			
		lockSendCommand => fetchLockState,
		-- Interface with hypothetical previous stage
		acceptingOut => acceptingOutPC,
		
		-- Interface with later stages
		nextAccepting => frontAccepting,	
		sendingOut => sendingOutPC,
		stageDataOut => stageDataOutPC,
			
		-- Sys reg interface
		sysRegWriteAllow => sysRegWriteAllow,
		sysRegWriteSel => sysRegWriteSel,
		sysRegWriteValue => sysRegWriteValue,

		sysRegReadSel => sysRegReadSel,
		sysRegReadValue => sysRegReadValue,
		
		-- Event interface
		frontEvents =>	frontEvents,

		start => start
	);


	EVENTS: block
		signal eventInsArray: InstructionSlotArray(0 to N_EVENT_AREAS-1) 
							:= (others => DEFAULT_INSTRUCTION_SLOT);
		signal eventCauseArrayS: InstructionSlotArray(0 to N_EVENT_AREAS-1)
							:= (others => DEFAULT_INSTRUCTION_SLOT);							
	begin	
		eventCauseArrayS(4) <= (stage0EventInfo.eventOccured, stage0EventInfo.causing);
			
		eventCauseArrayS(6) <= (execEventSignal, execCausing);
		eventCauseArrayS(7) <= (intSignal, intCausing);	
		
		eventInsArray <= TEMP_events(eventCauseArrayS);
		killVecOut <= extractFullMask(eventInsArray);		
		frontEvents <= getFrontEvents(eventInsArray);

		intCausing <= setInterrupt(lastCommitted, intSignal, "00000000");		
		execOrIntEventSignal <= intSignal or execEventSignal;
		execOrIntCausing <= intCausing when intSignal = '1' else execCausing;
		
		execOrIntEventSignalOut <= execOrIntEventSignal;	
		intCausingOut <= intCausing;
		execOrIntCausingOut <= execOrIntCausing;
	end block;

	frontEventSig <= frontEvents.eventOccured;
		
	fetchLockRequest <= frontEvents.eventOccured and frontEvents.causing.controlInfo.newFetchLock;
				

	iadr <= stageDataOutPC.basicInfo.ip and i2slv(-PIPE_WIDTH*4, MWORD_SIZE); -- Clearing low bits
				
	iadrvalid <= sendingOutPC;
	
	pcDataLiving <= stageDataOutPC;
	pcSending <= sendingOutPC;	

-----------------------------------------------
------------------------------------------------

	anySendingFromCQSig <= anySendingFromCQ;
		
	-- Rename stage
	RENAMING: block		
		signal reserveSelSig, takeVec: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0' );															
	begin	
		reserveSelSig <= getDestMask(frontDataLastLiving);
		takeVec <= (others => '1') when ALLOC_REGS_ALWAYS
				else frontDataLastLiving.fullMask;		

		stageDataRenameIn <= baptizeGroup(
									renameRegs(baptizeVec(frontDataLastLiving, newNumberTags),
												takeVec, reserveSelSig, 											
												newPhysSources, newPhysDests, newGprTags),
									renameGroupCtrNext
								);
	
		SUBUNIT_RENAME: entity work.GenericStageMulti(Behavioral)
		port map(
			clk => clk, reset => resetSig, en => enSig,
			
			-- Interface with front
			prevSending => frontLastSending,	
			stageDataIn => stageDataRenameIn,
			acceptingOut => acceptingOutRename,
			
			-- Interface with IQ
			nextAccepting => iqAccepts,
			sendingOut => sendingOutRename,
			stageDataOut => stageDataOutRename,
			
			-- Event interface
			execEventSignal => execOrIntEventSignal,
			execCausing => execOrIntCausing,
			lockCommand => renameLockCommand		
		);
	end block;
	
	GEN_NUMBER_TAGS: for i in 0 to PIPE_WIDTH-1 generate	
		newNumberTags(i) <= i2slv(binFlowNum(renameCtr) + i + 1, SMALL_NUMBER_SIZE);
	end generate;			



	GPR_MAP_BL: block
		signal virtDests, virtCommitDests: RegNameArray(0 to PIPE_WIDTH-1) := (others=>(others=>'0'));
		signal virtSources: RegNameArray(0 to 3*PIPE_WIDTH-1) := (others=>(others=>'0'));
	
		signal gprReserveReq, gprCommitReq: RegisterMapRequest := DEFAULT_REGISTER_MAP_REQUEST;
	
		signal gprRewind: std_logic := '0';
		signal gprCommitAllow: std_logic := '0';
		signal gprReserveAllow: std_logic := '0';
	begin	
		gprRewind <= renameLockRelease and renameLockState;  -- for GPR map
		gprReserveAllow <= frontLastSending; -- for GPR map
		gprCommitAllow <= sendingToCommit;	-- for GPR map
		
		virtSources <= getVirtualArgs(frontDataLastLiving);-- for GPR map
		virtDests <= getVirtualDests(frontDataLastLiving); -- for GPR map // UNUSED?
			
		gprReserveReq <= getRegMapRequest(frontDataLastLiving, newPhysDests); -- for GPR map	
		gprCommitReq <= getRegMapRequest(stageDataToCommit, physCommitDests); -- for GPR map

		virtCommitDests <= getVirtualDests(stageDataToCommit); -- for GPR map
		physCommitDests <= getPhysicalDests(stageDataToCommit);  -- for GPR map

		
		GPR_MAP: entity work.RegisterMap0 (Behavioral)
													--	(Implem)
		generic map(
			WIDTH => PIPE_WIDTH,
			MAX_WIDTH => MW
		)
		port map(
			clk => clk, reset => resetSig, en => enSig,
			
			rewind => gprRewind, -- on specified rollback event
			
			-- Interface for updating speculative mapping at Rename
			reserveAllow => 	gprReserveAllow,
			reserve => 			gprReserveReq.sel, --
			selectReserve => 	gprReserveReq.index, --
			writeReserve => 	gprReserveReq.value, --
			
			-- Interface for updating stable mapping at Commit
			commitAllow => 	gprCommitAllow,
			commit => 			gprCommitReq.sel,
			selectCommit => 	gprCommitReq.index,
			writeCommit => 	gprCommitReq.value,

			-- Reading speculative mapping (Rename)
			selectNewest => virtSources,
			readNewest => newPhysSources,
			
			-- Reading stable mapping (Commit, for freeing the old value)
			selectStable => virtCommitDests,
			readStable => physStable
		);
	end block;
	

	FREE_LIST_BL: block
		-- GPR free list signals
		signal freeListTakeAllow: std_logic := '0';
		signal freeListTakeSel: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
		-- Don't remove, it is used by newPhysDestPointer!
		signal freeListTakeNumTags: PhysNameArray(0 to PIPE_WIDTH-1) := (others => (others => '0'));
		signal newPhysDestPointer: SmallNumber := (others => '0');
		signal freeListPutAllow: std_logic := '0';
		signal freeListPutSel: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
		signal freeListRewind: std_logic := '0';
		signal freeListWriteTag: slv6 := (others => '0');
	begin

		FREED_DELAYED_SELECTION: for i in 0 to PIPE_WIDTH-1 generate	-- for free list
			physCommitFreedDelayed(i) <= physStableDelayed(i) when stableUpdateSelDelayed(i) = '1'
										else physCommitDestsDelayed(i);
		end generate;

		physCommitDestsDelayed <= getPhysicalDests(stageDataOutCommit); -- for free list
		stableUpdateSelDelayed <=  -- for free list
					getPhysicalDestMask(stageDataOutCommit) and not getExceptionMask(stageDataOutCommit);

		-- CAREFUL! Because there's a delay of 1 cycle to read FreeList, we need to do reading
		--				before actual instrucion goes to Rename, and pointer shows to new registers for next
		--				instruction, not those that are visible on output. So after every rewinding
		--				we must send a signal to read and advance the pointer.
		--				Rewinding has 2 specific moemnts: the event signal, and renameLockRelease,
		--				so on the former the rewinded pointer is written, and on the latter incremented and read.
		--				We also need to do that before the first instruction is executed (that's why resetSig here).
		freeListTakeAllow <= frontLastSending or (renameLockRelease and renameLockState); 
		
		freeListTakeSel <= (others => '1') when ALLOC_REGS_ALWAYS
						 else frontDataLastLiving.fullMask; -- Taking a reg for every instruction, sometimes dummy		
		freeListPutAllow <= sendingOutCommit;  -- for free list
		-- Releasing a register every time (but not always prev stable!)
		freeListPutSel <= (others => '1') when ALLOC_REGS_ALWAYS 
						else stageDataOutCommit.fullMask;		
		freeListRewind <= execOrIntEventSignal;
		
		
		 freeListWriteTag <= execOrIntCausing.gprTag(5 downto 0) when USE_GPR_TAG
							else  execOrIntCausing.groupTag(5 downto 0);
									-- TODO: clear low bits for superscalar (when groups work!)
		
		GPR_FREE_LIST: entity work.FreeListQuad (Behavioral)
															--	(Implem)
		generic map(
			WIDTH => PIPE_WIDTH,
			MAX_WIDTH => MW
		)
		port map(
			clk => clk, reset => resetSig, en => enSig,
			
			-- Interface for setting list to previous state
			rewind => freeListRewind,		
			writeTag => freeListWriteTag,
			
			-- Reading values from list
			enableTake => freeListTakeAllow,
			take => freeListTakeSel,
			readTake => newPhysDests,
			readTags => freeListTakeNumTags,	-- Don't remove!
			
			-- Writing values to list
			enablePut => freeListPutAllow,	
			put => freeListPutSel,
			writePut => physCommitFreedDelayed
		);
		
		newPhysDestPointer(5 downto 0) <= freeListTakeNumTags(0);
			
		GEN_GPR_TAGS: for i in 0 to PIPE_WIDTH-1 generate												
			newGprTags(i) <= i2slv((slv2u(newPhysDestPointer) + i) mod FREE_LIST_SIZE, SMALL_NUMBER_SIZE);
		end generate;			
	end block;

	
	GPR_READY_TABLE_BL: block
		-- GPR ready table signals
		signal readyTableClearAllow: std_logic := '0';
		signal readyTableClearSel: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
		signal readyTableSetAllow: std_logic := '0';
		signal readyTableSetSel: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
		signal readyTableSetTags: PhysNameArray(0 to PIPE_WIDTH-1) := (others => (others =>'0'));	
	begin		
		readyTableSetAllow <= anySendingFromCQSig;  -- for ready table	
		readyTableSetSel <= getPhysicalDestMask(cqDataLiving) and not getExceptionMask(cqDataLiving);
		readyTableSetTags <= getPhysicalDests(cqDataLiving); -- for ready table

		readyTableClearAllow <= frontLastSending; -- for ready table
		readyTableClearSel <= getDestMask(frontDataLastLiving);	-- for ready table		
		
		-- Reg avalability map
		REG_READY_TABLE_NEW: entity work.TestReadyRegTable0 (Behavioral)
																			 --(Implem)
		generic map(
			WIDTH => PIPE_WIDTH,
			MAX_WIDTH => MW
		)			
		port map(
			clk => clk, reset => resetSig, en => enSig, 
			
			-- Interface for clearing 'ready' bits
			enClear => readyTableClearAllow,	-- when renaming
			clearVec => readyTableClearSel,	-- clearing for all newly assigned physical regs 
			selectClear => newPhysDests, -- readyTableClearTags, -- newly assigned physical regs
			
			-- Setting inputs
			-- NOTE: setting 'ready' on commit, but later reg writing maybe before commit if possible?
			-- Interface for setting 'ready' bits
			enSet => readyTableSetAllow,	-- when committing (properly should be at writeback)
			setVec => readyTableSetSel,	-- at writeback of individual results (enSet above must be '1'!) 
			selectSet => readyTableSetTags,
			
			outputData => readyRegsSig -- readyRegs	
		);	
		
		readyRegFlagsNext <= extractReadyRegBits(readyRegsSig, stageDataOutRename.data);
	end block;

 
	COMMON_STATE: block
	begin
		renameCtrNext <= 
			  execOrIntCausing.numberTag 
					when execOrIntEventSignal = '1' -- CAREFUL: Only when kill sig comes from further than here!
		else i2slv(slv2u(renameCtr) + countOnes(frontDataLastLiving.fullMask), SMALL_NUMBER_SIZE)
					when frontLastSending = '1'
		else renameCtr;

			renameGroupCtrNext <= 
							  execOrIntCausing.groupTag and i2slv(-PIPE_WIDTH, SMALL_NUMBER_SIZE) -- low bits always '0'
							when execOrIntEventSignal = '1'
						else i2slv(slv2u(renameGroupCtr) + PIPE_WIDTH, SMALL_NUMBER_SIZE)
							when frontLastSending = '1'
						else renameGroupCtr;
						
		commitCtrNext <= 
						execOrIntCausing.numberTag when intSignal = '1' -- CAREFUL: without it could deadlock!
				else	i2slv(slv2u(commitCtr) + countOnes(cqDataLiving.fullMask), SMALL_NUMBER_SIZE);	
		
			commitGroupCtrNext <=	
							  i2slv(slv2u(commitGroupCtr) + PIPE_WIDTH, SMALL_NUMBER_SIZE)
								when sendingFromROB = '1'
						else commitGroupCtr;	
			
		-- Re-allow renaming when everything from rename/exec is committed - reg map will be well defined now
		renameLockRelease <= '1' when commitGroupCtr = renameGroupCtr else '0';
			-- CAREFUL, CHECK: when the counters are equal, renaming can be resumed, but renameLockRelease
			-- 					 takes effect in next cycle, so before tha cycle renaming is still stopped.
			--						 Should compare to commitCtrNext instead?
			--						 But remember that rewinding GPR map needs a cycle, and before it happens,
			--						 renaming can't be done! So this delay may be caused by this problem.
			
		PIPE_SYNCHRONOUS: process(clk) 	
		begin
			if rising_edge(clk) then
				if resetSig = '1' then					
				elsif enSig = '1' then					
					renameCtr <= renameCtrNext;
					commitCtr <= commitCtrNext;					
					renameGroupCtr <= renameGroupCtrNext;
					commitGroupCtr <= commitGroupCtrNext;
					
					readyRegFlags <= readyRegFlagsNext;
					
					-- Lock when exec part causes event
					if execOrIntEventSignal = '1' then -- CAREFUL
						renameLockState <= '1';	
					elsif renameLockRelease = '1' then
						renameLockState <= '0';
					end if;												
						
					if fetchLockRequest = '1' then
						fetchLockState <= '1';
					elsif (fetchLockCommit or frontEventSig) = '1' then -- CAREFUL! frontEventSig may be not
																						 --			 from front?
						fetchLockState <= '0';
					end if;	
					
					physStableDelayed <= getStableDestsParallel(stageDataToCommit, physStable);
					lastCommitted <= lastCommittedNext;
				end if;
			end if;
		end process;

	end block;
							 		

	sendingToCommit <= sendingFromROB;	
	stageDataToCommit <= robDataLiving;

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

		lastCommittedNext <= getLastFull(stageDataToCommit) when sendingToCommit = '1'				
								else	lastCommitted;

		committing <= sendingToCommit;
		
		fetchLockCommit <= fetchLockCommitting(stageDataToCommit);
	
		sysRegWriteAllow <= getSysRegWriteAllow(stageDataToCommit);

	renameLockCommand <= renameLockState;
			
	renameAccepting <= acceptingOutRename;
	renamedDataLiving <= stageDataOutRename;
	renamedSending <= sendingOutRename;
	
	commitGroupCtrOut <= commitGroupCtr;
	commitGroupCtrNextOut <= commitGroupCtrNext;

	readyRegFlagsOut <= readyRegFlags;
end Behavioral;

