----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    01:09:50 01/08/2017 
-- Design Name: 
-- Module Name:    ReadyRegisterTable - Behavioral 
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


entity ReadyRegisterTable is
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;

		sendingToReserve: in std_logic;
		stageDataToReserve: in StageDataMulti;

			newPhysDests: in PhysNameArray(0 to PIPE_WIDTH-1);
	
		stageDataReserved: in StageDataMulti;

		sendingToWrite: in std_logic;
		stageDataToWrite: in StageDataMulti;
		
		readyRegFlagsNext: out std_logic_vector(0 to 3*PIPE_WIDTH-1)
	);
end ReadyRegisterTable;



architecture Behavioral of ReadyRegisterTable is
		signal readyTableClearAllow: std_logic := '0';
		signal readyTableClearSel: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
		signal readyTableSetAllow: std_logic := '0';
		signal readyTableSetSel: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
		signal readyTableSetTags: PhysNameArray(0 to PIPE_WIDTH-1) := (others => (others =>'0'));
		
		signal readyRegsSig: std_logic_vector(0 to N_PHYSICAL_REGS-1) := (0 to 31 => '1', others=>'0');

		--signal newPhysDests: PhysNameArray(0 to PIPE_WIDTH-1) := (others=>(others=>'0'));		
begin		
		readyTableSetAllow <= sendingToWrite;  -- for ready table	
		readyTableSetSel <= getPhysicalDestMask(stageDataToWrite) 
						and not getExceptionMask(stageDataToWrite);
		readyTableSetTags <= getPhysicalDests(stageDataToWrite); -- for ready table

		readyTableClearAllow <= sendingToReserve; -- for ready table
		readyTableClearSel <= getDestMask(stageDataToReserve);	-- for ready table		
		
		--newPhysDests <= getPhysicalDests(stageDataToReserve);
		
		REG_READY_TABLE: entity work.TestReadyRegTable0 (Behavioral)
																			 --(Implem)
		generic map(
			WIDTH => PIPE_WIDTH,
			MAX_WIDTH => MW
		)			
		port map(
			clk => clk, reset => reset, en => en, 
			
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
		
		readyRegFlagsNext <= extractReadyRegBits(readyRegsSig, stageDataReserved.data);

end Behavioral;

