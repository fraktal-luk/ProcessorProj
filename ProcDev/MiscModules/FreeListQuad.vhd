----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:55:29 02/20/2016 
-- Design Name: 
-- Module Name:    FreeListQuad - Behavioral 
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
--use work.Renaming1.all;


entity FreeListQuad is
	generic(
		WIDTH: natural := 1;
		MAX_WIDTH:natural := 4		
	);
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           en : in  STD_LOGIC;
           rewind : in  STD_LOGIC;
			  
			  writeTag: in PhysName;
			  readTags: out PhysNameArray(0 to WIDTH-1);			  
			  
			  take: in std_logic_vector(0 to WIDTH-1);
			  enableTake: in std_logic;
			  readTake: out PhysNameArray(0 to WIDTH-1);
			  
			  put: in std_logic_vector(0 to WIDTH-1);
			  enablePut: in std_logic;			  
			  writePut: in PhysNameArray(0 to WIDTH-1)
		  );

end FreeListQuad;


architecture Behavioral of FreeListQuad is
	signal takeMW, putMW: std_logic_vector(0 to MAX_WIDTH-1) := (others=>'0');
	signal readTakeMW, writePutMW, readTagsMW: PhysNameArray(0 to MAX_WIDTH-1) := (others=>(others=>'0'));
	
	signal readTakeMW_C, readTagsMW_C: PhysNameArray(0 to MAX_WIDTH-1) := (others=>(others=>'0'));

	constant LIST_SIZE: integer := FREE_LIST_SIZE; --64; -- CAREFUL! 
	
	function initList return PhysNameArray;

	signal listContent: PhysNameArray(0 to LIST_SIZE-1) := initList;
	signal listPtrTake: SmallNumber := i2slv(0, SMALL_NUMBER_SIZE);
	signal listPtrPut: SmallNumber := i2slv(32, SMALL_NUMBER_SIZE);
	
	function initList return PhysNameArray is
		variable res: PhysNameArray(0 to LIST_SIZE-1) := (others => (others=> '0'));
	begin
		for i in 0 to 31 loop
			res(i) := i2slv(32 + i, PhysName'length);
		end loop;
		return res;
	end function;
	
begin
	takeMW(0 to WIDTH-1) <= take;
	putMW(0 to WIDTH-1) <= put;
	
	readTags <= readTagsMW(0 to WIDTH-1);
	
	readTake <= readTakeMW(0 to WIDTH-1);
	writePutMW(0 to WIDTH-1) <= writePut;
	
	
	READ_LIST: for i in 0 to WIDTH-1 generate
		readTagsMW(i) <= i2slv((slv2u(listPtrTake) + i) mod LIST_SIZE, readTagsMW(i)'length);
	end generate;
	
	SYNCHRONOUS: process(clk)
		variable indPut, indTake: integer := 0;
	begin
		if rising_edge(clk) then
			--if reset = '1' then
				
			--elsif en = '1' then
				indTake := slv2u(listPtrTake); 
				indPut := slv2u(listPtrPut);
								
				if rewind = '1' then
					listPtrTake(5 downto 0) <= writeTag; -- Indexing TMP
				end if;
				
				if enableTake = '1' and rewind = '0' then
					for i in 0 to WIDTH-1 loop
						-- indTake := slv2u(listPtrTake);
						-- 
						readTakeMW(i) <= listContent((slv2u(listPtrTake) + i) mod LIST_SIZE);
					end loop;
					indTake := (indTake + WIDTH) mod LIST_SIZE;					
					listPtrTake <= i2slv(indTake, listPtrTake'length);
				end if;
				
				if enablePut = '1' then
					for i in 0 to WIDTH-1 loop
						-- for each element of input vec
						if putMW(i) = '1' then
							listContent(indPut) <= writePutMW(i);
							indPut := (indPut + 1) mod LIST_SIZE;
						end if;
					end loop;
					listPtrPut <= i2slv(indPut, listPtrPut'length);	
				end if;
				
			--end if;
		end if;
	end process;

end Behavioral;
