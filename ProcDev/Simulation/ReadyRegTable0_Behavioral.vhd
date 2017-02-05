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

--use work.CommonRouting.all;
use work.TEMP_DEV.all;

--use work.FrontPipeDevViewing.all;

architecture Behavioral_C of TestReadyRegTable0 is
	signal setVecMW, clearVecMW: std_logic_vector(0 to MAX_WIDTH-1) := (others=>'0'); 
	signal selectSetMW, selectClearMW: PhysNameArray(0 to MAX_WIDTH-1) := (others=>(others=>'0'));
	
	signal content: std_logic_vector(0 to N_PHYSICAL_REGS-1) := (0 to 31 => '1', others => '0');
begin
	setVecMW(0 to WIDTH-1) <= setVec when enSet = '1' else (others => '0');
	clearVecMW(0 to WIDTH-1) <= clearVec when enClear = '1' else (others => '0');
	selectSetMW(0 to WIDTH-1) <= selectSet;
	selectClearMW(0 to WIDTH-1) <= selectClear;

	
	outputData <= content;
	
	SYNCHRONOUS: process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				
			elsif en = '1' then
				for i in 0 to WIDTH-1 loop
					if setVecMW(i) = '1' then
						-- set 
						content(slv2u(selectSetMW(i))) <= '1';
					end if;
					
					if clearVecMW(i) = '1' then
						-- clear
						content(slv2u(selectClearMW(i))) <= '0';						
					end if;
				end loop;
			end if;
		end if;
	end process;
	
end Behavioral_C;

