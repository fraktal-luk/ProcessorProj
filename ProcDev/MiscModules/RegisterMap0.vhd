----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:31:56 02/20/2016 
-- Design Name: 
-- Module Name:    RegisterMap0 - Behavioral 
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


entity RegisterMap0 is
	generic(
		WIDTH: natural := 1;
		MAX_WIDTH:natural := 4		
	);
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           en : in  STD_LOGIC;
           rewind : in  STD_LOGIC;
           reserveAllow : in  STD_LOGIC;
           reserve : in  STD_LOGIC_VECTOR (0 to WIDTH-1);
           commitAllow : in  STD_LOGIC;
           commit : in  STD_LOGIC_VECTOR (0 to WIDTH-1);
				selectReserve: in RegNameArray(0 to WIDTH-1);
				writeReserve: in PhysNameArray(0 to WIDTH-1);
				selectCommit: in RegNameArray(0 to WIDTH-1);
				writeCommit: in PhysNameArray(0 to WIDTH-1);
				selectNewest: in RegNameArray(0 to 3*WIDTH-1);
				readNewest: out PhysNameArray(0 to 3*WIDTH-1);
				selectStable: in RegNameArray(0 to WIDTH-1);
				readStable: out PhysNameArray(0 to WIDTH-1) 			  
		  );
end RegisterMap0;


architecture Implem of RegisterMap0 is
	signal reserveMW, commitMW: std_logic_vector(0 to MAX_WIDTH-1) := (others=>'0');
	signal selectReserveMW, selectCommitMW, selectStableMW: RegNameArray(0 to MAX_WIDTH-1) 
				:= (others=>(others=>'0'));
	signal selectNewestMW: RegNameArray(0 to 3*MAX_WIDTH-1) := (others=>(others=>'0'));
	
	signal writeReserveMW, writeCommitMW, readStableMW: PhysNameArray(0 to 3*MAX_WIDTH-1)
				:= (others=>(others=>'0'));	
	signal readNewestMW: PhysNameArray(0 to 3*MAX_WIDTH-1) := (others=>(others=>'0'));
begin
	reserveMW(0 to WIDTH-1) <= reserve;
	commitMW(0 to WIDTH-1) <= commit;
	
	selectReserveMW(0 to WIDTH-1) <= selectReserve;
	selectCommitMW(0 to WIDTH-1) <= selectCommit;
	selectNewestMW(0 to 3*WIDTH-1) <= selectNewest;
	selectStableMW(0 to WIDTH-1) <= selectStable;
	
	writeReserveMW(0 to WIDTH-1) <= writeReserve;
	writeCommitMW(0 to WIDTH-1) <= writeCommit;
	readNewest <= readNewestMW(0 to 3*WIDTH-1);
	readStable <= readStableMW(0 to WIDTH-1);
	
			IMPL: entity work.TempVerilogRegMap port map(
				clk=>clk, reset=>reset, en=>en,
				rewind => rewind,
				
				commit => commitMW,
				commitAllow => commitAllow,
				reserve => reserveMW,
				reserveAllow => reserveAllow,
				
				selectReserve => selectReserveMW(0), selectReserveN => selectReserveMW(1), 
				selectReserve2 => selectReserveMW(2), selectReserve3 => selectReserveMW(3),
				selectCommit => selectCommitMW(0), selectCommitN => selectCommitMW(1), 
				selectCommit2 => selectCommitMW(2), selectCommit3 => selectCommitMW(3),
				
				writeReserve => writeReserveMW(0), writeReserveN => writeReserveMW(1), 
				writeReserve2 => writeReserveMW(2), writeReserve3 => writeReserveMW(3),
				writeCommit => writeCommitMW(0), writeCommitN => writeCommitMW(1), 
				writeCommit2 => writeCommitMW(2), writeCommit3 => writeCommitMW(3),
				
				select0 => selectNewestMW(0), select1 => selectNewestMW(1), select2 => selectNewestMW(2), 
				select3 => selectNewestMW(3), select4 => selectNewestMW(4), select5 => selectNewestMW(5), 
				select6 => selectNewestMW(6), select7 => selectNewestMW(7), select8 => selectNewestMW(8), 
				select9 => selectNewestMW(9), select10 => selectNewestMW(10), select11 => selectNewestMW(11), 
				
				read0 => readNewestMW(0), read1 => readNewestMW(1), read2 => readNewestMW(2), 
				read3 => readNewestMW(3), read4 => readNewestMW(4), read5 => readNewestMW(5), 
				read6 => readNewestMW(6), read7 => readNewestMW(7), read8 => readNewestMW(8), 
				read9 => readNewestMW(9), read10 => readNewestMW(10), read11 => readNewestMW(11),
				
				selectStable => selectStableMW(0), 
				selectStableN => selectStableMW(1),
				selectStable2 => selectStableMW(2),
				selectStable3 => selectStableMW(3),
				
				readStable => readStableMW(0), -- physCommitFreed(0)		
				readStableN => readStableMW(1),
				readStable2 => readStableMW(2),
				readStable3 => readStableMW(3)
			);	
	
end Implem;

