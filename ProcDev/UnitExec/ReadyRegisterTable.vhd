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
	generic(
		WRITE_WIDTH: integer := 1
	);
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;

		sendingToReserve: in std_logic;
		stageDataToReserve: in StageDataMulti;

			newPhysDests: in PhysNameArray(0 to PIPE_WIDTH-1);
	
		stageDataReserved: in StageDataMulti;

		--sendingToWrite: in std_logic;
		--stageDataToWrite: in StageDataMulti;
			writingMask: in std_logic_vector(0 to WRITE_WIDTH-1);
			writingData: in InstructionStateArray(0 to WRITE_WIDTH-1);
		
		readyRegFlagsNext: out std_logic_vector(0 to 3*PIPE_WIDTH-1)
	);
end ReadyRegisterTable;



architecture Behavioral of ReadyRegisterTable is
		constant WIDTH: natural := WRITE_WIDTH;

		signal readyTableClearAllow: std_logic := '0';
		signal readyTableClearSel: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
		--signal readyTableSetAllow: std_logic := '0';
		--signal readyTableSetSel: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
		--signal readyTableSetTags: PhysNameArray(0 to PIPE_WIDTH-1) := (others => (others =>'0'));
		
		signal readyRegsSig: std_logic_vector(0 to N_PHYSICAL_REGS-1) := (0 to 31 => '1', others=>'0');

		--signal newPhysDests: PhysNameArray(0 to PIPE_WIDTH-1) := (others=>(others=>'0'));
			signal altMask: std_logic_vector(0 to WRITE_WIDTH-1) := (others => '0');
			signal altDests: PhysNameArray(0 to WRITE_WIDTH-1) := (others => (others => '0'));
begin		
		--readyTableSetAllow <= sendingToWrite;  -- for ready table	
		--readyTableSetSel <= getPhysicalDestMask(stageDataToWrite) 
		--				and not getExceptionMask(stageDataToWrite);
		--readyTableSetTags <= getPhysicalDests(stageDataToWrite); -- for ready table

		readyTableClearAllow <= sendingToReserve; -- for ready table
		readyTableClearSel <= getDestMask(stageDataToReserve);	-- for ready table		
		
		--newPhysDests <= getPhysicalDests(stageDataToReserve);
			altMask <= getArrayDestMask(writingData, writingMask);
			altDests <= getArrayPhysicalDests(writingData);
		
		IMPL: block
			signal content: std_logic_vector(0 to N_PHYSICAL_REGS-1) := (0 to 31 => '1', others => '0');
		begin
				SYNCHRONOUS: process(clk)
				begin
					if rising_edge(clk) then
						--if reset = '1' then
						--elsif en = '1' then
--							if false then--CQ_SINGLE_OUTPUT then
--								if readyTableSetAllow = '1' then
--									for i in 0 to WIDTH-1 loop
--										if readyTableSetSel(i) = '1' then
--											-- set 
--											content(slv2u(readyTableSetTags(i))) <= '1';
--										end if;
--									end loop;
--								end if;
							--else-- CQ_THREE_OUTPUTS then
									for i in 0 to altMask'length-1 loop
										if altMask(i) = '1' then
											-- set 
											content(slv2u(altDests(i))) <= '1';
										end if;
									end loop;	
							--end if;
							
							if readyTableClearAllow = '1' then							
								for i in 0 to PIPE_WIDTH-1 loop								
									if readyTableClearSel(i) = '1' then
										-- clear
										content(slv2u(newPhysDests(i))) <= '0';						
									end if;
								end loop;
							end if;
							
						--end if;
					end if;
				end process;
				
			readyRegFlagsNext <= extractReadyRegBits(content, stageDataReserved.data);				
		end block;
		
		--readyRegFlagsNext <= extractReadyRegBits(readyRegsSig, stageDataReserved.data);

end Behavioral;

