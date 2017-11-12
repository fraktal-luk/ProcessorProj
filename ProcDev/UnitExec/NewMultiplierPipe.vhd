----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:05:35 09/12/2017 
-- Design Name: 
-- Module Name:    NewMultiplierPipe - Behavioral 
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


entity NewMultiplierPipe is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           en : in  STD_LOGIC;
           inA : in  STD_LOGIC_VECTOR (31 downto 0);
           inB : in  STD_LOGIC_VECTOR (31 downto 0);
           inC : in  STD_LOGIC_VECTOR (31 downto 0);
           result : out  STD_LOGIC_VECTOR (63 downto 0));
end NewMultiplierPipe;


architecture Behavioral of NewMultiplierPipe is
	signal aHigh, aLow, bHigh, bLow, aHighDelay, bLowDelay: hword := (others => '0');
	signal lowResult, lowResultDelay, lowResultDelay2: word := (others => '0');
	signal innerAddend, outerAddend, innerResult, outerResult: std_logic_vector(47 downto 0) := (others => '0'); 
begin
	aHigh <= inA(31 downto 16);
	aLow <= inA(15 downto 0);
	bHigh <= inB(31 downto 16);
	bLow <= inB(15 downto 0);
	
	process(clk)
	begin
		if rising_edge(clk) then
			aHighDelay <= aHigh;
			bLowDelay <= bLow;
			lowResultDelay <= lowResult;
			lowResultDelay2 <= lowResultDelay;
		end if;
	end process;
	
	
	MULT_LOW: entity work.Mult16
	port map(
		clk => clk,
		a => aLow,
		b => bLow,
--		c => (others => '0'),
		p => lowResult
	);
	
	outerAddend(15 downto 0) <= lowResult(31 downto 16);
	
	MADD_OUTER: entity work.MultAcc16
	port map(
		clk => clk,
		a => aLow,
		b => bHigh,
		c => outerAddend,
		p => outerResult--result(31 downto 0)		
	);

	innerAddend <= outerResult; 

	MADD_INNER: entity work.MultAcc16
	port map(
		clk => clk,
		a => aHighDelay,
		b => bLowDelay,
		c => innerAddend,
		p => innerResult--result(31 downto 0)		
	);
	
	result(63 downto 32) <= (others => '0');
	result(31 downto 16) <= innerResult(15 downto 0);
	result(15 downto 0) <= lowResultDelay2(15 downto 0);
	
end Behavioral;

