----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:47:40 11/29/2016 
-- Design Name: 
-- Module Name:    IntegerAlu - Behavioral 
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



entity IntegerAlu is
	port(
		inputInstruction: in InstructionState;
		result: out Mword;
		exc: out std_logic_vector(3 downto 0)
	);
end IntegerAlu;



architecture Behavioral of IntegerAlu is

			signal a0, a1, a2, aluRes: Mword := (others => '0');
			signal c0, c1: slv5 := (others => '0');
			signal excSig: std_logic_vector(3 downto 0) := (others => '0');
			signal carry: std_logic := '0';
			signal funcSel: slv6 := (others => '0');
		begin
			a0 <= inputInstruction.argValues.arg0;
			a1 <= inputInstruction.argValues.arg1;
			a2 <= inputInstruction.argValues.arg2;			
			c0 <= inputInstruction.constantArgs.c0;
			c1 <= inputInstruction.constantArgs.c1;
		
			with inputInstruction.operation.func select
				funcSel <=
					"000001"	when arithAdd,
					"000010"	when arithSub,
					"000011"	when arithShra,
					"000100"	when logicAnd,
					"000101"	when logicOr,
					"000110"	when logicShl,
					"000111"	when logicShrl,
					--"001000"	when logicXor,					
					"000000"	when others;
		
			MAIN_ALU: entity work.VerilogALU32
			port map(
				clk => '0', reset => '0', en => '0', allow => '0',
				funcSelect => funcSel,
				dataIn0 => a0,
				dataIn1 => a1,
				dataIn2 => a2,
				c0 => c0,
				c1 => c1,
				dataOut0 => open,
				carryOut => open,
				exceptionOut => open,
				dataOut0Pre => aluRes,
				carryOutPre => carry,
				exceptionOutPre => excSig
			);
	
			--aluAOut <= setExecState(inputInstruction, aluRes, carry, exc);
	
	result <= aluRes;
	exc <= excSig;
end Behavioral;

