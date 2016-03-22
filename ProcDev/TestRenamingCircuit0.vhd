----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:53:22 03/14/2016 
-- Design Name: 
-- Module Name:    TestRenamingCircuit0 - Behavioral 
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

--use work.Renaming1.all;


entity TestRenamingCircuit0 is
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
		whichSendingFromCQ: in std_logic_vector(0 to PIPE_WIDTH-1);
		
		
		accepting: out std_logic; -- to frontend
		
		renamedDataLiving: out StageDataMulti;
		
			ra: out std_logic_vector(0 to 31);
		readyRegs: out std_logic_vector(0 to N_PHYSICAL_REGS-1);
		
		commitCtrNextOut: out SmallNumber;
		
		lastCommittedOut: out InstructionState;
		lastCommittedNextOut: out InstructionState
	);
end TestRenamingCircuit0;


architecture Behavioral of TestRenamingCircuit0 is
	signal resetSig, enabled: std_logic := '0';

		signal flowDrive1: FlowDriveSimple := (others=>'0');
		signal flowResponse1: FlowResponseSimple := (others=>'0');		
		signal stageData1, stageData1Living, stageData1Next, stageData1New:
															StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
		signal flowDriveCommit: FlowDriveSimple := (others=>'0');
		signal flowResponseCommit: FlowResponseSimple := (others=>'0');		
		signal stageDataCommit, stageDataCommitLiving, stageDataCommitNext, stageDataCommitNew:
						StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
			signal renameLockCommand, renameLockState, renameLockRelease: std_logic := '0';		
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
			signal reserveVec, commitVec, takeVec, putVec: std_logic_vector(0 to PIPE_WIDTH-1) := (others=>'0');
			--
			signal readySet, readyClear: std_logic_vector(0 to PIPE_WIDTH-1) := (others=>'0');

			signal newNumberTags: SmallNumberArray(0 to PIPE_WIDTH-1) := (others=>(others=>'0'));
			signal renameCtr, renameCtrNext, commitCtr, commitCtrNext: SmallNumber := (others=>'0');
				signal renameCtrInt: natural := 0;	

		signal partialKillMask1: std_logic_vector(0 to PIPE_WIDTH-1) := (others=>'0');

		-- CAREFUL, CHECK: to enable restoring from last committed
		signal hardTarget: InstructionBasicInfo := defaultBasicInfo;
		signal lastCommitted, lastCommittedNext: InstructionState := defaultInstructionState;	
	begin
		resetSig <= reset;
		enabled <= en;	
	
		-- Rename stage								
		stageData1New <= renameRegs(--TEMP_baptize(frontDataLastLiving, binFlowNum(renameCtr)),
											baptizeVec(frontDataLastLiving, newNumberTags),
											takeVec, physRenameDestSelects, 											
											newPhysSources, newPhysDests, newGprTags);
		--stageData1New_2		<=	
							--	renameAndBaptize(frontDataLastLiving, newPhysSources, newPhysDests,
							--							newGprTags, binFlowNum(renameCtr));
											
		stageData1Next <= stageMultiNext(stageData1Living, stageData1New,
									flowResponse1.living, flowResponse1.sending, flowDrive1.prevSending);			
		stageData1Living <= stageMultiHandleKill(stageData1, flowDrive1.kill, partialKillMask1);

		flowDrive1.prevSending <= frontLastSending;
		flowDrive1.nextAccepting <= iqAccepts;
		-- CAREFUL! Is it correct?
		flowDrive1.kill <= execEventSignal; -- Only later stages can kill Rename
		flowDrive1.lockAccept <= renameLockCommand;

		SIMPLE_SLOT_LOGIC_1: SimplePipeLogic port map(
				clk => clk, reset => resetSig, en => en,
				flowDrive => flowDrive1,
				flowResponse => flowResponse1
			);

		renameLockCommand <= renameLockState;
		-- Allow renaming when everything from rename/exec is committed - reg map will be well defined now
		renameLockRelease <= '1' when commitCtr = renameCtr else '0'; -- CAREFUL! when all committed
			
		-- Logic needed for renaming:	
			virtSources <=	getVirtualArgs(frontDataLastLiving);						
			virtDests <= getVirtualDests(frontDataLastLiving);			
			virtCommitDests <= getVirtualDests(stageDataCommitNew);
			
			physRenameDestSelects <= getDestMask(frontDataLastLiving);
				
			-- For free list:
			takeVec <= frontDataLastLiving.fullMask;
			putVec <= stageDataCommitNew.fullMask;
			
		READY_LIST_DRIVES: for i in 0 to PIPE_WIDTH-1 generate
			readyClear(i) <=	'1' --frontLastSending 
									and physRenameDestSelects(i); -- takeVec(i);
			--	Only on "commit", not on "release"!			
			readySet(i) <= 	'1' --flowDriveCommit.prevSending 
									and physCommitDestSelects(i)
									and not stageDataCommitNew.data(i).controlInfo.exception; -- and operation done
		end generate;			
			
			REGS_TO_COMMIT: for i in 0 to PIPE_WIDTH-1 generate												
				physCommitDests(i) <= stageDataCommitNew.data(i).physicalDestArgs.d0;
				physCommitDestSelects(i) <= stageDataCommitNew.fullMask(i)
													and stageDataCommitNew.data(i).physicalDestArgs.sel(0);	
				-- CAREFUL! Version for new Free List
				newGprTags(i) <= "00" & newGprTags6(i);

				newNumberTags(i) <= i2slv(binFlowNum(renameCtr) + i + 1, SMALL_NUMBER_SIZE);		
			end generate;
			
				-- CAREFUL, TODO: shouldn't there be selection based on actual dest selects?	
				--			So that we only reserve/commit when dest /= p0 exists.
				--			In the present case it's attempted always, and p0 is just rejected by the mapper.
				commitVec <= physCommitDestSelects; --?
				reserveVec <= physRenameDestSelects; --?
			
			FREED_REGS: for i in 0 to PIPE_WIDTH-1 generate
				physCommitFreed(i) <= physStable(i) 
												when (physCommitDestSelects(i)
														and not stageDataCommitNew.data(i).controlInfo.exception) = '1' 	
										else physCommitDests(i);
			end generate;							
							
				GPR_MAP: entity work.RegisterMap0				
				generic map(
					WIDTH => PIPE_WIDTH,
					MAX_WIDTH => MW
				)
				port map(
					clk => clk, reset => resetSig, en => en,
					rewind => renameLockRelease, -- execEventSignal,
					commitAllow => flowDriveCommit.prevSending, -- Need vector? Maybe not, just use r0/p0 if no action.
 					commit => commitVec,
					reserveAllow => frontLastSending, 				-- [like above]
					reserve => reserveVec,
					selectReserve => virtDests,
					writeReserve => newPhysDests,
					selectCommit => virtCommitDests,
					writeCommit => physCommitDests,
					selectNewest => virtSources,
					readNewest => newPhysSources,
					selectStable => virtCommitDests,
					readStable => physStable
				);
														 
				GPR_FREE_LIST: entity work.FreeListQuad
				generic map(
					WIDTH => PIPE_WIDTH,
					MAX_WIDTH => MW
				)
				port map(
					clk => clk, reset => resetSig, en => en,
					rewind => execEventSignal,
					writeTag => restoredGprTag(5 downto 0),
					take => takeVec,
					enableTake => frontLastSending,
					readTake => newPhysDests,
					readTags => newGprTags6,
					put => putVec,
					enablePut => flowDriveCommit.prevSending,
					writePut => physCommitFreed
				);
				
		PIPE_SYNCHRONOUS: process(clk) 	
		begin
			if rising_edge(clk) then
				if resetSig = '1' then
					
				elsif enabled = '1' then	
					stageData1 <= stageData1Next;										
					
					renameCtr <= renameCtrNext;
					commitCtr <= commitCtrNext;
												
					-- lock when exec part causes event
					if execEventSignal = '1' then -- CAREFUL
						renameLockState <= '1';	
					elsif renameLockRelease = '1' then
						renameLockState <= '0';
					end if;												
																	
					stageDataCommit <= stageDataCommitNext;					
					
					-- Saving info about last committed instr (including exceptional, which don't write state)
					--	and target (what would be next after that last committed)
					if flowDriveCommit.prevSending = '1' then
						--lastCommitted <= getLastFull(stageDataCommitNew);
						hardTarget <= getHardTarget(stageDataCommitNew);
					end if;
					lastCommitted <= lastCommittedNext;
				end if;
			end if;
		end process;	
			
		lastCommittedNext <= getLastFull(stageDataCommitNew) when flowDriveCommit.prevSending = '1'
							else	lastCommitted;
			
		renameCtrNext <= 
			  execCausing.numberTag 
					when execEventSignal = '1' -- CAREFUL: Only when kill sig comes from further than here!
		else i2slv(slv2u(renameCtr) + countOnes(frontDataLastLiving.fullMask), SMALL_NUMBER_SIZE)
					when frontLastSending = '1'
		else renameCtr;
		
		restoredGprTag <= execCausing.gprTag; -- Restoring always the 'post' state, cause
															-- when exception, PR is just freed, not changing 'stable'		
		
	-- Commit stage: in order again							
		stageDataCommitLiving <= stageDataCommit; -- Nothing will kill it?
		stageDataCommitNew.fullMask <= whichSendingFromCQ;
		stageDataCommitNew.data <= -- ??(some may be killed? careful)
											cqDataLiving.data; -- CAREFUL: remember not to commit
																						-- those that have 0 in 'fullMask' 
		stageDataCommitNext <= stageMultiNext(stageDataCommitLiving, stageDataCommitNew,
							flowResponseCommit.living, flowResponseCommit.sending, flowDriveCommit.prevSending);			
						
			SIMPLE_SLOT_LOGIC_COMMIT: SimplePipeLogic port map(
				clk => clk, reset => resetSig, en => en,
				flowDrive => flowDriveCommit,
				flowResponse => flowResponseCommit
			);	
	
		-- Condition would be redundant: no change when X = '0', but X='0'	only when increment is nonzero! 
		commitCtrNext <= i2slv(slv2u(commitCtr) + countOnes(whichSendingFromCQ), SMALL_NUMBER_SIZE);	
		
		flowDriveCommit.nextAccepting <= '1'; -- Nothing block it
		-- NOTE: sending from CQ is in continuous packets; if bit 0 is '0', no else will be '1'
		flowDriveCommit.prevSending <= isNonzero(whichSendingFromCQ);
		
		-- Reg avalability map
		REG_READY_TABLE_NEW: entity work.TestReadyRegTable0
				generic map(
					WIDTH => PIPE_WIDTH,
					MAX_WIDTH => MW
				)			
				port map(
						clk => clk, reset => resetSig, en => en, 
						-- Setting inputs
						-- TEMP: setting 'ready' on commit, but later make reg writing before commit if possible
						enSet => flowDriveCommit.prevSending,
						setVec => readySet,
						selectSet => physCommitDests,
						
						enClear => frontLastSending,
						clearVec => readyClear,
						selectClear => newPhysDests,
						
						outputData => readyRegs		
		);
		
		
		accepting <= flowResponse1.accepting;
		renamedDataLiving <= stageData1Living;
		
		commitCtrNextOut <= commitCtrNext;	

		lastCommittedOut <= lastCommitted;
		lastCommittedNextOut <= lastCommittedNext;
end Behavioral;

