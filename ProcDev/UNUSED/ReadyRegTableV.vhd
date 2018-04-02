----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:44:29 01/28/2017 
-- Design Name: 
-- Module Name:    ReadyRegTableV - Behavioral 
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

use work.ProcBasicDefs.all;
use work.Helpers.all;

use work.ProcInstructionsNew.all;

use work.NewPipelineData.all;

use work.GeneralPipeDev.all;

--use work.CommonRouting.all;
use work.TEMP_DEV.all;


entity ReadyRegTableV is
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;

		sendingToReserve: in std_logic;
		stageDataToReserve: in StageDataMulti;

		--	newPhysDests: in PhysNameArray(0 to PIPE_WIDTH-1);
	
		--stageDataReserved: in StageDataMulti;

		sendingToWrite: in std_logic;
		stageDataToWrite: in StageDataMulti;
		
		readyRegFlagsNext: out std_logic_vector(0 to 3*PIPE_WIDTH-1)
	);
end ReadyRegTableV;



architecture Behavioral of ReadyRegTableV is
			constant WIDTH: natural := PIPE_WIDTH;
			constant MAX_WIDTH: natural := MW;

	signal setVecMW, clearVecMW: std_logic_vector(0 to MAX_WIDTH-1) := (others=>'0'); 
	signal selectSetVirtualMW, selectClearMW: RegNameArray(0 to MAX_WIDTH-1) := (others=>(others=>'0'));
	signal selectSetPhysicalMW: PhysNameArray(0 to MAX_WIDTH-1) := (others=>(others=>'0'));
	
	signal content: std_logic_vector(0 to N_PHYSICAL_REGS-1) := (0 to 31 => '1', others => '0');
	

		signal readyTableClearAllow: std_logic := '0';
		signal readyTableClearSel: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
		signal readyTableSetAllow: std_logic := '0';
		signal readyTableSetSel: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
		signal readyTableSetVirtualTags: RegNameArray(0 to PIPE_WIDTH-1) := (others => (others =>'0'));
		signal readyTableSetPhysicalTags: PhysNameArray(0 to PIPE_WIDTH-1) := (others => (others =>'0'));
		
		signal readyRegsSig: std_logic_vector(0 to N_PHYSICAL_REGS-1) := (0 to 31 => '1', others=>'0');

		--signal newPhysDests: PhysNameArray(0 to PIPE_WIDTH-1) := (others=>(others=>'0'));
			signal mapped: PhysNameArray(0 to 31) := (others => (others => '0')); -- TEMP
begin		
		readyTableSetAllow <= sendingToWrite;  -- for ready table	
		readyTableSetSel <= getPhysicalDestMask(stageDataToWrite) 
						and		stageDataToWrite.fullMask
						and not getExceptionMask(stageDataToWrite);
		readyTableSetPhysicalTags <= getPhysicalDests(stageDataToWrite); -- for ready table
		readyTableSetVirtualTags <= getVirtualDests(stageDataToWrite); -- for ready table

		readyTableClearAllow <= sendingToReserve; -- for ready table
		readyTableClearSel <= getDestMask(stageDataToReserve);	
	
	setVecMW(0 to WIDTH-1) <= readyTableSetSel when readyTableSetAllow = '1' else (others => '0');
	clearVecMW(0 to WIDTH-1) <= readyTableClearSel when readyTableClearAllow = '1' else (others => '0');
	selectSetVirtualMW(0 to WIDTH-1) <= readyTableSetVirtualTags;
	selectSetPhysicalMW(0 to WIDTH-1) <= readyTableSetPhysicalTags;
		
	selectClearMW(0 to WIDTH-1) <= getVirtualDests(stageDataToReserve);

	
	--outputData <= content;
	
	SYNCHRONOUS: process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				
			elsif en = '1' then
				for i in 0 to WIDTH-1 loop
					if setVecMW(i) = '1' then
						-- set 
						if selectSetPhysicalMW(i) = mapped(i) then
							content(slv2u(selectSetVirtualMW(i))) <= '1';
						end if;
					end if;
					
					if clearVecMW(i) = '1' then
						-- clear
						content(slv2u(selectClearMW(i))) <= '0';						
					end if;
				end loop;
			end if;
		end if;
	end process;

	readyRegFlagsNext <=
				extractReadyRegBits(content, stageDataToReserve.data); -- here using data before rename

end Behavioral;

