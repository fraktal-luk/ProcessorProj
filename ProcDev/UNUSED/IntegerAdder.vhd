----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:48:26 11/29/2016 
-- Design Name: 
-- Module Name:    IntegerAdder - Behavioral 
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

use work.TEMP_DEV.all;

use work.ProcLogicExec.all;

use work.ProcComponents.all;



entity IntegerAdder is
	port(
		inA: in Mword;
		inB: in Mword;
		output: out Mword
	);
end IntegerAdder;


architecture Behavioral of IntegerAdder is
begin				
			INT_ADDER: entity work.VerilogALU32 port map(
				clk => '0', reset => '0', en => '0', allow => '0',
				funcSelect => "000001", -- addition
				dataIn0 => inA,
				dataIn1 => inB,
				dataIn2 => inB, -- Ignored
				c0 => "00000", c1 => "00000", 
				dataOut0 => open, carryOut => open, exceptionOut => open, 
				dataOut0Pre => output, carryOutPre => open, exceptionOutPre => open
			);


end Behavioral;

