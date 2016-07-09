----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:27:12 04/25/2016 
-- Design Name: 
-- Module Name:    UnitReorder - Behavioral 
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
--use work.FrontPipeDev.all;
use work.CommonRouting.all;
use work.TEMP_DEV.all;

use work.ProcLogicRenaming.all;

use work.ProcComponents.all;


entity UnitReorder is
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
		
		iqAccepts: in std_logic;
		execEventSignal: in std_logic;
		execCausing: in InstructionState;
		
		frontDataLastLiving: in StageDataMulti;
		frontLastSending: in std_logic;
		
		cqDataLiving: in StageDataMulti;

		anySendingFromCQ: in std_logic;
		
		accepting: out std_logic; -- to frontend
		
		renamedDataLiving: out StageDataMulti;
		renamedSending: out std_logic;
		
		-- CAREFUL: readyRegs are read instantly, without cycle delay. But reg file needs a cycle to be read
		readyRegs: out std_logic_vector(0 to N_PHYSICAL_REGS-1);
		
		commitCtrNextOut: out SmallNumber;
		
		stageDataCommittedOut: out StageDataMulti;
		lastCommittedOut: out InstructionState;
		lastCommittedNextOut: out InstructionState
	);
end UnitReorder;


architecture Behavioral of UnitReorder is
	signal resetSig, enSig: std_logic := '0';

	signal whichSendingFromCQ: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');

		signal stageDataOutRename: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
		signal sendingOutRename: std_logic:= '0';
		signal acceptingOutRename: std_logic := '0';

		signal stageDataOutCommit: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
		signal sendingOutCommit: std_logic:= '0';
		signal acceptingOutCommit: std_logic := '0';

	signal anySendingFromCQSig: std_logic := '0';
															
	signal renameLockCommand, renameLockRelease: std_logic := '0';	
	signal renameLockState: std_logic := '0';	-- register
	signal renameDestinations: std_logic_vector(0 to PIPE_WIDTH-1) := (others=>'0');	
	signal virtDests, virtCommitDests: RegNameArray(0 to PIPE_WIDTH-1) := (others=>(others=>'0'));					
	signal newPhysDests, physCommitDests, physCommitFreed, physStable: 
					PhysNameArray(0 to PIPE_WIDTH-1) := (others=>(others=>'0'));							
	signal physRenameDestSelects: std_logic_vector(0 to PIPE_WIDTH-1) := (others=>'0');		
	signal physCommitDestSelects: std_logic_vector(0 to PIPE_WIDTH-1) := (others=>'0');		
	signal virtSources: RegNameArray(0 to 3*PIPE_WIDTH-1) := (others=>(others=>'0'));
	signal newPhysSources: PhysNameArray(0 to 3*PIPE_WIDTH-1) := (others=>(others=>'0'));								
	signal newGprTags: SmallNumberArray(0 to PIPE_WIDTH-1) := (others=>(others=>'0'));	
	signal newGprTags6: PhysNameArray(0 to PIPE_WIDTH-1) := (others=>(others=>'0'));		
	signal restoredGprTag: SmallNumber := (others=>'0');

	signal newNumberTags: SmallNumberArray(0 to PIPE_WIDTH-1) := (others=>(others=>'0'));
	signal renameCtr, renameCtrNext, commitCtr, commitCtrNext: SmallNumber := (others=>'0');

	signal partialKillMask1: std_logic_vector(0 to PIPE_WIDTH-1) := (others=>'0');

	signal renamingMask, committingMask: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
	signal reserveSel, commitSel: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');

	signal readyClearSel, readySetSel: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');

	-- GPR map signals
	signal gprRewind: std_logic := '0';
	signal gprCommitAllow: std_logic := '0';
	signal gprCommitSel: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
	signal gprCommitVirt: RegNameArray(0 to PIPE_WIDTH-1) := (others => (others =>'0'));
	signal gprCommitPhys: PhysNameArray(0 to PIPE_WIDTH-1) := (others => (others =>'0'));
	signal gprReserveAllow: std_logic := '0';
	signal gprReserveSel: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
	signal gprReserveVirt: RegNameArray(0 to PIPE_WIDTH-1) := (others => (others =>'0'));
	signal gprReservePhys: PhysNameArray(0 to PIPE_WIDTH-1) := (others => (others =>'0'));
	signal gprNewestVirt: RegNameArray(0 to 3*PIPE_WIDTH-1) := (others => (others =>'0'));
	signal gprNewestPhys: PhysNameArray(0 to 3*PIPE_WIDTH-1) := (others => (others =>'0'));
	signal gprStableVirt: RegNameArray(0 to PIPE_WIDTH-1) := (others => (others =>'0'));
	signal gprStablePhys: PhysNameArray(0 to PIPE_WIDTH-1) := (others => (others =>'0'));
		
	-- GPR free list signals
	signal freeListTakeAllow: std_logic := '0';
	signal freeListTakeSel: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
	signal freeListTakeTags: PhysNameArray(0 to PIPE_WIDTH-1) := (others => (others => '0'));
	signal freeListTakeNumTags: PhysNameArray(0 to PIPE_WIDTH-1) := (others => (others => '0'));	
	signal freeListPutAllow: std_logic := '0';
	signal freeListPutSel: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
	signal freeListPutTags: PhysNameArray(0 to PIPE_WIDTH-1) := (others => (others => '0')); 	
	signal freeListRewind: std_logic := '0';
	signal freeListRewindTag: SmallNumber := (others => '0');	

	-- GPR ready table signals
	signal readyTableClearAllow: std_logic := '0';
	signal readyTableClearSel: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
	signal readyTableClearTags: PhysNameArray(0 to PIPE_WIDTH-1) := (others => (others =>'0'));
	signal readyTableSetAllow: std_logic := '0';
	signal readyTableSetSel: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
	signal readyTableSetTags: PhysNameArray(0 to PIPE_WIDTH-1) := (others => (others =>'0'));

	-- CAREFUL, CHECK: to enable restoring from last committed
	signal hardTarget: InstructionBasicInfo := defaultBasicInfo;
	signal lastCommitted, lastCommittedNext: InstructionState := defaultInstructionState;

	constant HAS_RESET_REORDER: std_logic := '1';
	constant HAS_EN_REORDER: std_logic := '1';	
begin
	resetSig <= reset and HAS_RESET_REORDER;
	enSig <= en or not HAS_EN_REORDER;	
	
	anySendingFromCQSig <= anySendingFromCQ;
	
	
	-- TODO: refactor physical destination assignment to allow using block RAM for free reg stack?
	-- Rename stage
	SUBUNIT_RENAME: entity work.SubunitRename(Behavioral)
	port map(
		clk => clk, reset => resetSig, en => enSig,
		
		prevSending => frontLastSending,	
		nextAccepting => iqAccepts,
		execEventSignal => execEventSignal,
		execCausing => execCausing,
		renameLockCommand => renameLockCommand,
		stageDataIn => frontDataLastLiving,
		acceptingOut => acceptingOutRename, -- open,
		sendingOut => sendingOutRename, --open,
		stageDataOut => stageDataOutRename, --open
		
		newPhysSources => newPhysSources,
		newPhysDests => newPhysDests,
		newGprTags => newGprTags,
		newNumberTags => newNumberTags,
	
		virtSources => virtSources,
		virtDests => virtDests,
		renamingMask => renamingMask,
		reserveSel => reserveSel,
		readyClearSel => readyClearSel
	);
	
	restoredGprTag <= execCausing.gprTag; -- Restoring always the 'post' state, cause
														-- when exception, PR is just freed, not changing 'stable'
	
	GEN_GPR_TAGS: for i in 0 to PIPE_WIDTH-1 generate												
		-- Rename
		newGprTags(i) <= "00" & newGprTags6(i);
	end generate;

	
	GEN_NUMBER_TAGS: for i in 0 to PIPE_WIDTH-1 generate	
		newNumberTags(i) <= i2slv(binFlowNum(renameCtr) + i + 1, SMALL_NUMBER_SIZE);
	end generate;			
			
	-- Rename main signals:
	-- out:
	-- frontLastSending
	-- gprReserveSel
	-- virtDests
	-- virtSources
	-- frontDataLastLiving.fullMask
	-- in:
	-- newPhysDests
	-- newPhysSources
	-- freeListTakeTags
	-- freeListTakeNumTags
	-- 
			
	gprRewind <= renameLockRelease;		-- I
	gprCommitAllow <= anySendingFromCQSig; -- C
	gprCommitSel <= commitSel; -- C
	gprCommitVirt <= virtCommitDests; -- C
	gprCommitPhys <= physCommitDests; -- C
	gprReserveAllow <= frontLastSending; -- R
	gprReserveSel <= reserveSel; -- R
	gprReserveVirt <= virtDests; -- R
	gprReservePhys <= newPhysDests; -- R
	gprNewestVirt <= virtSources; -- R
	newPhysSources <= gprNewestPhys; -- R		##
	gprStableVirt <= virtCommitDests; -- C
	physStable <= gprStablePhys;		-- C		##

	freeListTakeAllow <= frontLastSending; -- R
	freeListTakeSel <= renamingMask; -- Taking a reg for every instruction, sometimes dummy
	newPhysDests <= freeListTakeTags; -- R			##
	newGprTags6 <= freeListTakeNumTags; -- R		##
	freeListPutAllow <= anySendingFromCQSig; -- C
	freeListPutSel <= committingMask; -- Releasing a register every time (but not always prev stable!)
	freeListPutTags <= physCommitFreed;	-- C
	freeListRewind <= execEventSignal; -- I
	freeListRewindTag	<= restoredGprTag; -- Change to PhysName, so that indexing is here, not in port map?
	
	readyTableSetAllow <= anySendingFromCQSig;  -- C
	readyTableClearAllow <= frontLastSending; -- R
	readyTableSetTags <= physCommitDests; -- C
	readyTableClearTags <= newPhysDests; -- R
	readyTableSetSel <= readySetSel;
	readyTableClearSel <= readyClearSel;
	
	-----------------
	-- gprRewind
	-- gprCommitAllow
	--	gprCommitSel
	-- gprCommitVirt
	-- gprCommitPhys
	-- gprReserveAllow
	-- gprReserveSel
	-- gprReserveVirt
	-- gprReservePhys
	-- gprNewestVirt
	-- gprNewestPhys
	-- gprStableVirt
	-- gprStablePhys
	
	GPR_MAP: entity work.RegisterMap0				
	generic map(
		WIDTH => PIPE_WIDTH,
		MAX_WIDTH => MW
	)
	port map(
		clk => clk, reset => resetSig, en => enSig,
		rewind => gprRewind,
		
		commitAllow => gprCommitAllow,
		commit => gprCommitSel,
		
		reserveAllow => gprReserveAllow,
		reserve => gprReserveSel,
		
		selectReserve => gprReserveVirt,
		writeReserve => gprReservePhys,
		
		selectCommit => gprCommitVirt, 
		writeCommit => gprCommitPhys,
		
		selectNewest => gprNewestVirt,
		readNewest => gprNewestPhys,
		
		selectStable => gprStableVirt,
		readStable => gprStablePhys
	);
	
		
	-- ---------------
	-- freeListTakeAllow
	-- freeListTakeSel
	-- freeListTakeTags
	-- freeListTakeNumTags
	-- freeListPutAllow
	-- freeListPutSel
	-- freeListPutTags	
	-- freeListRewind
	-- freeListRewindTag	
		
	GPR_FREE_LIST: entity work.FreeListQuad
	generic map(
		WIDTH => PIPE_WIDTH,
		MAX_WIDTH => MW
	)
	port map(
		clk => clk, reset => resetSig, en => enSig,
		
		rewind => freeListRewind,		
		writeTag => freeListRewindTag(5 downto 0),
		
		enableTake => freeListTakeAllow,
		take => freeListTakeSel,		
		readTake => freeListTakeTags,
		readTags => freeListTakeNumTags,
		
		enablePut => freeListPutAllow,		
		put => freeListPutSel,
		writePut => freeListPutTags
	);
		
	
	-- --------------------
	-- readyTableClearAllow
	-- readyTableClearSel
	-- readyTableClearTags
	-- readyTableSetAllow
	-- readyTableSetSel
	-- readyTableSetTags
	
	-- Reg avalability map
	REG_READY_TABLE_NEW: entity work.TestReadyRegTable0
	generic map(
		WIDTH => PIPE_WIDTH,
		MAX_WIDTH => MW
	)			
	port map(
		clk => clk, reset => resetSig, en => enSig, 
		-- Setting inputs
		-- NOTE: setting 'ready' on commit, but later reg writing maybe before commit if possible?
		enSet => readyTableSetAllow,
		setVec => readyTableSetSel,
		selectSet => readyTableSetTags,
		
		enClear => readyTableClearAllow,
		clearVec => readyTableClearSel,
		selectClear => readyTableClearTags,
		
		outputData => readyRegs	
	);	
 
 
	COMMON_STATE: block
	begin
		renameCtrNext <= 
			  execCausing.numberTag 
					when execEventSignal = '1' -- CAREFUL: Only when kill sig comes from further than here!
		else i2slv(slv2u(renameCtr) + countOnes(frontDataLastLiving.fullMask), SMALL_NUMBER_SIZE)
					when frontLastSending = '1'
		else renameCtr;

		-- Condition would be redundant: no change when X = '0', but X='0' only when increment is nonzero! 
		commitCtrNext <= i2slv(slv2u(commitCtr) + countOnes(committingMask), SMALL_NUMBER_SIZE);	

		-- Re-allow renaming when everything from rename/exec is committed - reg map will be well defined now
		renameLockRelease <= '1' when commitCtr = renameCtr else '0'; -- CAREFUL! when all committed
			
		renameLockCommand <= renameLockState;			

		PIPE_SYNCHRONOUS: process(clk) 	
		begin
			if rising_edge(clk) then
				if resetSig = '1' then
					
				elsif enSig = '1' then					
					renameCtr <= renameCtrNext;
					commitCtr <= commitCtrNext;
												
					-- Lock when exec part causes event
					if execEventSignal = '1' then -- CAREFUL
						renameLockState <= '1';	
					elsif renameLockRelease = '1' then
						renameLockState <= '0';
					end if;												
																					
					-- Saving info about last committed instr (including exceptional, which don't write state)
					--	and target (what would be next after that last committed)
					if anySendingFromCQSig = '1' then --flowDriveCommit.prevSending = '1' then
						-- CAREFUL: Should this signal be ever used?
						--hardTarget <= getHardTarget(cqDataLiving);
					end if;
					--lastCommitted <= lastCommittedNext;
				end if;
			end if;
		end process;	
	end block;
							 											
	-- Commit stage: in order again				
	SUBUNIT_COMMIT: entity work.SubunitCommit(Behavioral)
	port map(
		clk => clk, reset => resetSig, en => enSig,
		
		prevSending => anySendingFromCQSig,
		nextAccepting => '1',
		execEventSignal => execEventSignal,
		execCausing => execCausing,
		stageDataIn => cqDataLiving, 		
		acceptingOut => open, -- unused but don't remove
		sendingOut => open, -- as above
		stageDataOut => stageDataOutCommit,
		
		physStable => physStable,
		
		physCommitFreed => physCommitFreed, 
		virtCommitDests => virtCommitDests,
		physCommitDests => physCommitDests,
		commitSel => commitSel,
		readySetSel => readySetSel,
		committingMask => committingMask,
		
		lastCommittedOut => lastCommitted,
		lastCommittedNextOut => lastCommittedNext
	);

	stageDataCommittedOut <= stageDataOutCommit;		
			
	accepting <= acceptingOutRename;
	renamedDataLiving <= stageDataOutRename;
	renamedSending <= sendingOutRename;
	
	commitCtrNextOut <= commitCtrNext;	

	lastCommittedOut <= lastCommitted;
	lastCommittedNextOut <= lastCommittedNext;
end Behavioral;

