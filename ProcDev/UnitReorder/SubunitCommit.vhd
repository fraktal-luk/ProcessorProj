----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:23:47 04/25/2016 
-- Design Name: 
-- Module Name:    SubunitCommit - Behavioral 
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

use work.CommonRouting.all;
use work.TEMP_DEV.all;

use work.ProcComponents.all;

use work.ProcLogicRenaming.all;


entity SubunitCommit is
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
		
		prevSending: in std_logic;
		nextAccepting: in std_logic;
		execEventSignal: in std_logic;
		execCausing: in InstructionState;
		stageDataIn: in StageDataMulti;		
		acceptingOut: out std_logic;
		sendingOut: out std_logic;
		stageDataOut: out StageDataMulti;
		--stageEventsOut: out StageMultiEventInfo
		
		physStable: in PhysNameArray(0 to PIPE_WIDTH-1);
		
		physCommitFreed: out PhysNameArray(0 to PIPE_WIDTH-1);
		virtCommitDests: out RegNameArray(0 to PIPE_WIDTH-1);
		physCommitDests: out PhysNameArray(0 to PIPE_WIDTH-1);
		commitSel: out std_logic_vector(0 to PIPE_WIDTH-1);
		readySetSel: out std_logic_vector(0 to PIPE_WIDTH-1);
		committingMask: out std_logic_vector(0 to PIPE_WIDTH-1);
		
			fetchLockCommit: out std_logic;

			sysRegWriteAllow: out std_logic;
			sysRegWriteSel: out slv5;
			sysRegWriteValue: out Mword;			
		lastCommittedOut: out InstructionState;
		lastCommittedNextOut: out InstructionState
	);
end SubunitCommit;


architecture Behavioral of SubunitCommit is
	signal flowDriveCommit: FlowDriveSimple := (others=>'0');
	signal flowResponseCommit: FlowResponseSimple := (others=>'0');		
	signal stageDataCommit, stageDataCommitLiving, stageDataCommitNext, stageDataCommitNew:
					StageDataMulti := DEFAULT_STAGE_DATA_MULTI;	
					
	signal anySendingFromCQSig: std_logic := '0';	
	signal physCommitDestsSig: PhysNameArray(0 to PIPE_WIDTH-1) := (others => (others => '0'));
	signal readySetSelSig, commitSelSig: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
	
	signal lastCommitted, lastCommittedNext: InstructionState := defaultInstructionState;
	
	function fetchLockCommitting(sd: StageDataMulti) return std_logic is
	begin
		for i in sd.fullMask'range loop
			if sd.fullMask(i) = '1' and sd.data(i).classInfo.fetchLock = '1' then
				return '1';
			end if;
		end loop;
		return '0';
	end function;
	
	function getsysRegWriteAllow(sd: StageDataMulti) return std_logic is
	begin
		for i in sd.fullMask'range loop
			if 	sd.fullMask(i) = '1' 
				and sd.data(i).operation.unit = System
				and sd.data(i).operation.func = sysMtc
			then
				return '1';
			end if;
		end loop;
		return '0';
	end function;

	function getSysRegWriteSel(sd: StageDataMulti) return slv5 is
		variable res: slv5 := (others => '0');
	begin
		for i in sd.fullMask'range loop
			if sd.fullMask(i) = '1' then
				res := sd.data(i).constantArgs.c0;
			end if;
		end loop;
		return res;
	end function;

	function getSysRegWriteValue(sd: StageDataMulti) return Mword is
		variable res: Mword := (others => '0');
	begin
		for i in sd.fullMask'range loop
			if sd.fullMask(i) = '1' then
				res := sd.data(i).result;
			end if;
		end loop;
		return res;
	end function;	
begin	
	stageDataCommitLiving <= stageDataCommit; -- Nothing will kill it?
	stageDataCommitNew <= stageDataIn;	-- ??(some may be killed? careful)					
							
	-- CAREFUL, TODO: maybe clear result tags in committed instructions after 1 cycle, cause 
	--						values are then already in registers and we shouldn't duplicate tags
	stageDataCommitNext <= stageMultiNext(stageDataCommitLiving, stageDataCommitNew,
						flowResponseCommit.living, flowResponseCommit.sending, flowDriveCommit.prevSending);			

	PIPE_CLOCKED: process(clk) 	
	begin
		if rising_edge(clk) then
			if reset = '1' then
				
			elsif en = '1' then	
				stageDataCommit <= stageDataCommitNext;
				lastCommitted <= lastCommittedNext;
			end if;
		end if;
	end process;

	-- CAREFUL, TODO: redundant selection here?
	lastCommittedNext <= getLastFull(stageDataIn) when anySendingFromCQSig = '1'				
						else	lastCommitted;
		
	SIMPLE_SLOT_LOGIC_COMMIT: SimplePipeLogic port map(
		clk => clk, reset => reset, en => en,
		flowDrive => flowDriveCommit,
		flowResponse => flowResponseCommit
	);	
		
		fetchLockCommit <= fetchLockCommitting(stageDataIn);
	
		sysRegWriteAllow <= getSysRegWriteAllow(stageDataIn);
		sysRegWriteSel <= getSysRegWriteSel(stageDataIn);
		sysRegWriteValue <= getSysRegWriteValue(stageDataIn);
	
	flowDriveCommit.nextAccepting <= '1'; -- Nothing block it
	-- NOTE: sending from CQ is in continuous packets; if bit 0 is '0', no else will be '1'
	flowDriveCommit.prevSending <= prevSending;
	
	stageDataOut <= stageDataCommitLiving;
	sendingOut <= flowResponseCommit.sending;		 
	acceptingOut <= flowResponseCommit.accepting; -- NOTE: prob. UNUSED, because always '1'
	
	physCommitDestsSig <= getPhysicalDests(stageDataIn);
	readySetSelSig <= commitSelSig and not getExceptionMask(stageDataIn);
	
	anySendingFromCQSig <= prevSending;
	commitSelSig <= getPhysicalDestMask(stageDataIn);	

	FREED_SELECTION: for i in 0 to PIPE_WIDTH-1 generate	
		-- Commit
		physCommitFreed(i) <= physStable(i) when readySetSelSig(i) = '1'
							  else physCommitDestsSig(i);
	end generate;		
	--
	virtCommitDests <= getVirtualDests(stageDataIn);
	physCommitDests <= physCommitDestsSig;		
	commitSel <= commitSelSig; 					
	readySetSel <= readySetSelSig;		
	committingMask <= stageDataIn.fullMask;

	lastCommittedOut <= lastCommitted;
	lastCommittedNextOut <= lastCommittedNext;	
end Behavioral;

