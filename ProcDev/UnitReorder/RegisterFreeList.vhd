----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:52:10 01/07/2017 
-- Design Name: 
-- Module Name:    RegisterFreeList - Behavioral 
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

use work.ProcLogicRenaming.all;



entity RegisterFreeList is
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
		
		rewind: in std_logic;
		causingInstruction: in InstructionState;
		
		sendingToReserve: in std_logic;
		takeAllow: in std_logic;
		stageDataToReserve: in StageDataMulti;
		
		newPhysDests: out PhysNameArray(0 to PIPE_WIDTH-1);
		newPhysDestPointer: out SmallNumber;

		sendingToRelease: in std_logic;
		stageDataToRelease: in StageDataMulti;
		
		physStableDelayed: in PhysNameArray(0 to PIPE_WIDTH-1)
	);	
end RegisterFreeList;



architecture Behavioral of RegisterFreeList is

		signal freeListTakeAllow: std_logic := '0';
		signal freeListTakeSel: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
		-- Don't remove, it is used by newPhysDestPointer!
		signal freeListTakeNumTags: PhysNameArray(0 to PIPE_WIDTH-1) := (others => (others => '0'));
		signal freeListPutAllow: std_logic := '0';
		signal freeListPutSel: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
		signal freeListRewind: std_logic := '0';
		signal freeListWriteTag: slv6 := (others => '0');
		
			signal stableUpdateSelDelayed: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
			signal physCommitFreedDelayed, physCommitDestsDelayed: 
							PhysNameArray(0 to PIPE_WIDTH-1) := (others=>(others=>'0'));
begin

		FREED_DELAYED_SELECTION: for i in 0 to PIPE_WIDTH-1 generate	-- for free list
			physCommitFreedDelayed(i) <= physStableDelayed(i) when stableUpdateSelDelayed(i) = '1'
										else physCommitDestsDelayed(i);
		end generate;

		physCommitDestsDelayed <= getPhysicalDests(stageDataToRelease); -- for free list
		stableUpdateSelDelayed <=  -- for free list
					getPhysicalDestMask(stageDataToRelease) and not getExceptionMask(stageDataToRelease);

		-- CAREFUL! Because there's a delay of 1 cycle to read FreeList, we need to do reading
		--				before actual instrucion goes to Rename, and pointer shows to new registers for next
		--				instruction, not those that are visible on output. So after every rewinding
		--				we must send a signal to read and advance the pointer.
		--				Rewinding has 2 specific moemnts: the event signal, and renameLockRelease,
		--				so on the former the rewinded pointer is written, and on the latter incremented and read.
		--				We also need to do that before the first instruction is executed (that's why resetSig here).
		freeListTakeAllow <= takeAllow;
		
		freeListTakeSel <= (others => '1') when ALLOC_REGS_ALWAYS
						 else stageDataToReserve.fullMask; -- Taking a reg for every instruction, sometimes dummy		
		freeListPutAllow <= sendingToRelease;  -- for free list
		-- Releasing a register every time (but not always prev stable!)
		freeListPutSel <= (others => '1') when ALLOC_REGS_ALWAYS 
						else stageDataToRelease.fullMask;		
		freeListRewind <= rewind;
		
		
		freeListWriteTag <= causingInstruction.gprTag(5 downto 0) when USE_GPR_TAG
							else  causingInstruction.groupTag(5 downto 0);
									-- TODO: clear low bits for superscalar (when groups work!)
		
		REG_FREE_LIST: entity work.FreeListQuad (Behavioral)
															--	(Implem)
		generic map(
			WIDTH => PIPE_WIDTH,
			MAX_WIDTH => MW
		)
		port map(
			clk => clk, reset => reset, en => en,
			
			-- Interface for setting list to previous state
			rewind => freeListRewind,		
			writeTag => freeListWriteTag,
			
			-- Reading values from list
			enableTake => freeListTakeAllow,
			take => freeListTakeSel,
			readTake => newPhysDests,	-- BL_OUT
			readTags => freeListTakeNumTags,
			
			-- Writing values to list
			enablePut => freeListPutAllow,	
			put => freeListPutSel,
			writePut => physCommitFreedDelayed
		);
		
		newPhysDestPointer(5 downto 0) <= freeListTakeNumTags(0); -- BL_OUT	
		newPhysDestPointer(7 downto 6) <= (others => '0');
end Behavioral;

