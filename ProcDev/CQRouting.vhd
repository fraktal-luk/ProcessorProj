----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:32:11 01/01/2016 
-- Design Name: 
-- Module Name:    CQRouting - Behavioral 
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


entity CQRouting is
	generic(
		MAX_SIZE: natural := 4
	);
	port(
		-- WARNING: This may be unused
		acceptingCQ: in PipeFlow; -- 'accepting' signal from CQ
	
		numBase: in SmallNumber;
		maxSize: in SmallNumber; -- DEPREC
		numA, numB,	numC, numD: in SmallNumber;
		selected: in std_logic_vector(0 to 3); -- it contains '1' when givn subpipe has ready op to send
		whichSend: in std_logic_vector(0 to 3);
		
		whichAccepted: out std_logic_vector(0 to 3); -- which subpipes will see 'nextAccepting'
		sendingToCQ: out PipeFlow; -- number of ops to send
		routes: out IntArray(0 to 3) -- To which slot is each incoming instruction going
		
	);
end CQRouting;


architecture Behavioral of CQRouting is
	signal routesSig: IntArray(routes'range);
begin
	routesSig(0) <= (slv2u(numA) - slv2u(numBase) - 1) mod 2**SMALL_NUMBER_SIZE;
	routesSig(1) <= (slv2u(numB) - slv2u(numBase) - 1) mod 2**SMALL_NUMBER_SIZE;
	routesSig(2) <= (slv2u(numC) - slv2u(numBase) - 1) mod 2**SMALL_NUMBER_SIZE;
	routesSig(3) <= (slv2u(numD) - slv2u(numBase) - 1) mod 2**SMALL_NUMBER_SIZE;
	
	--whichAccepted <= selected;
	whichAccepted(0) <= selected(0) when routesSig(0) < MAX_SIZE else '0'; 
	whichAccepted(1) <= selected(1) when routesSig(1) < MAX_SIZE else '0'; 
	whichAccepted(2) <= selected(2) when routesSig(2) < MAX_SIZE else '0'; 
	whichAccepted(3) <= selected(3) when routesSig(3) < MAX_SIZE else '0'; 
	
	sendingToCQ <= num2flow(countOnes(whichSend));
	routes <= routesSig;
end Behavioral;

