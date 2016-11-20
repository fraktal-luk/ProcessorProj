----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:58:51 07/01/2016 
-- Design Name: 
-- Module Name:    RegisterFile0 - Behavioral 
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


entity RegisterFile0 is
	generic(
		WIDTH: natural := 1;
		WRITE_WIDTH: natural := 1;
		MAX_WIDTH: natural := 4		
	);
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           en : in  STD_LOGIC;
			  
					readAllowT0: in std_logic;
					readAllowT1: in std_logic;
					readAllowT2: in std_logic;
					readAllowT3: in std_logic;
			  
			  writeAllow: in std_logic;
			  writeVec: in std_logic_vector(0 to WIDTH-1);			  
			  selectWrite: in PhysNameArray(0 to WIDTH-1);			  	
			  writeValues: in MwordArray(0 to WIDTH-1);	

			  selectRead: in PhysNameArray(0 to 3*WIDTH-1);
			  readValues: out MwordArray(0 to 3*WIDTH-1)
			  );
end RegisterFile0;

architecture Implem of RegisterFile0 is
	signal resetSig, enSig: std_logic := '0';

	signal writeVecMW: std_logic_vector(0 to MAX_WIDTH-1) := (others => '0');
	signal selectWriteMW: PhysNameArray(0 to MAX_WIDTH-1) := (others => (others => '0'));
	signal writeValuesMW: MwordArray(0 to MAX_WIDTH-1) := (others => (others => '0'));
	signal selectReadMW: PhysNameArray(0 to 3*MAX_WIDTH-1) := (others => (others => '0'));	
	signal readValuesMW: MwordArray(0 to 3*MAX_WIDTH-1) := (others => (others => '0'));	

	constant HAS_RESET_REGFILE: std_logic := '1';
	constant HAS_EN_REGFILE: std_logic := '1';
begin
	resetSig <= reset and HAS_RESET_REGFILE;
	enSig <= en or not HAS_EN_REGFILE;

	writeVecMW(0 to WIDTH-1) <= writeVec; -- when writeAllow = '1' else (others => '0');
		writeVecMW(WIDTH to MAX_WIDTH-1) <= (others => '0');
	selectWriteMW(0 to WIDTH-1) <= selectWrite;
	writeValuesMW(0 to WIDTH-1) <= writeValues;
	
	selectReadMW(0 to 3*WIDTH-1) <= selectRead;
	readValues <= readValuesMW(0 to 3*WIDTH-1);
	
	IMPL: entity work.TestVerilogRegfile6P
	generic map(
		N_WRITE => WRITE_WIDTH
	)
	port map(
		clk => clk, reset => resetSig, en => enSig,
		
		commitAllow => writeAllow,
		commitVec => writeVecMW,
		writeSelect0 => selectWriteMW(0),
		writeSelect1 => selectWriteMW(1),
		writeSelect2 => selectWriteMW(2),
		writeSelect3 => selectWriteMW(3),
		writeData0 => writeValuesMW(0),
		writeData1 => writeValuesMW(1),
		writeData2 => writeValuesMW(2),
		writeData3 => writeValuesMW(3),
			
			readAllowT0 => readAllowT0,
			readAllowT1 => readAllowT1,
			readAllowT2 => readAllowT2,
			readAllowT3 => readAllowT3,
		
		readSelect0 => selectReadMW(0),
		readSelect1 => selectReadMW(1),
		readSelect2 => selectReadMW(2),
		readSelect3 => selectReadMW(3),
		readSelect4 => selectReadMW(4),
		readSelect5 => selectReadMW(5),
		readSelect6 => selectReadMW(6),
		readSelect7 => selectReadMW(7),
		readSelect8 => selectReadMW(8),
		readSelect9 => selectReadMW(9),
		readSelect10 => selectReadMW(10),
		readSelect11 => selectReadMW(11),
		
		readData0 => readValuesMW(0),
		readData1 => readValuesMW(1),
		readData2 => readValuesMW(2),
		readData3 => readValuesMW(3),
		readData4 => readValuesMW(4),
		readData5 => readValuesMW(5),
		readData6 => readValuesMW(6),
		readData7 => readValuesMW(7),
		readData8 => readValuesMW(8),
		readData9 => readValuesMW(9),
		readData10 => readValuesMW(10),
		readData11 => readValuesMW(11)		
	);
	
end Implem;

