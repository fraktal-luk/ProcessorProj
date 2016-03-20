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
begin
	takeMW(0 to WIDTH-1) <= take;
	putMW(0 to WIDTH-1) <= put;
	
	readTags <= readTagsMW(0 to WIDTH-1);
	
	readTake <= readTakeMW(0 to WIDTH-1);
	writePutMW(0 to WIDTH-1) <= writePut;
	
	IMPL: entity work.VerilogFreeListQuad
	generic map(
		WIDTH => WIDTH
	)
	port map(
			clk => clk, reset => reset, en => en,
			rewind => rewind,
			
			readTags0 => readTagsMW(0),
			readTags1 => readTagsMW(1),
			readTags2 => readTagsMW(2),
			readTags3 => readTagsMW(3),
			
			writeTag => writeTag,
			
			enablePut => enablePut,
			put => putMW,
			
			enableTake => enableTake,
			take => takeMW,
			
			readTake0 => readTakeMW(0),
			readTake1 => readTakeMW(1),
			readTake2 => readTakeMW(2),
			readTake3 => readTakeMW(3),
			
			writePut0 => writePutMW(0),
			writePut1 => writePutMW(1),
			writePut2 => writePutMW(2),
			writePut3 => writePutMW(3)
	);

end Behavioral;

