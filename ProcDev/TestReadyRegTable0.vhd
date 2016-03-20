----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:46:27 03/07/2016 
-- Design Name: 
-- Module Name:    TestReadyRegTable0 - Behavioral 
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

--use work.FrontPipeDevViewing.all;

--use work.Renaming1.all;


entity TestReadyRegTable0 is
	generic(
		WIDTH: natural := 1;
		MAX_WIDTH:natural := 4		
	);
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
	
		enSet: in std_logic;
		setVec: in std_logic_vector(0 to WIDTH-1);
		selectSet: in PhysNameArray(0 to WIDTH-1);
		
		enClear: in std_logic;
		clearVec: in std_logic_vector(0 to WIDTH-1);
		selectClear: in PhysNameArray(0 to WIDTH-1);		
		
		outputData: out std_logic_vector(0 to N_PHYSICAL_REGS-1)		
	);
end TestReadyRegTable0;


architecture Behavioral of TestReadyRegTable0 is
	signal setVecMW, clearVecMW: std_logic_vector(0 to MAX_WIDTH-1) := (others=>'0'); 
	signal selectSetMW, selectClearMW: PhysNameArray(0 to MAX_WIDTH-1) := (others=>(others=>'0'));
begin
	setVecMW(0 to WIDTH-1) <= setVec;
	clearVecMW(0 to WIDTH-1) <= clearVec;
	selectSetMW(0 to WIDTH-1) <= selectSet;
	selectClearMW(0 to WIDTH-1) <= selectClear;

		IMPL: entity work.TestVerilogReadyRegTable64 port map(
						clk => clk, reset => reset, en => en, 
						-- Setting inputs
						-- TEMP: setting 'ready' on commit, but later make reg writing before commit if possible
						writeEnL(0) => setVecMW(0) and enSet,							
						writeEnL(1) => setVecMW(1) and enSet,							
						writeEnL(2) => setVecMW(2) and enSet,							
						writeEnL(3) => setVecMW(3) and enSet,							
						
						writeSelect0 => selectSetMW(0), --newPhysDests(0), --iaux(31 downto 26),
						writeSelect1 => selectSetMW(1), --iaux(25 downto 20),
						writeSelect2 => selectSetMW(2), --iaux(19 downto 14),
						writeSelect3 => selectSetMW(3), --iaux(13 downto 8) or "001100",
						
						-- Clearing inputs
						writeEnH(0) => clearVecMW(0) and enClear,							
						writeEnH(1) => clearVecMW(0) and enClear,							
						writeEnH(2) => clearVecMW(0) and enClear,							
						writeEnH(3) => clearVecMW(0) and enClear,							

						writeSelect4 => selectClearMW(0),  --"000000",
						writeSelect5 => selectClearMW(1),
						writeSelect6 => selectClearMW(2),
						writeSelect7 => selectClearMW(3),

						outputData => outputData
			);						

end Behavioral;

