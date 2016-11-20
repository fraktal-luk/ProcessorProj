--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;

use work.ProcBasicDefs.all;
use work.Helpers.all;

use work.ProcInstructionsNew.all;

use work.NewPipelineData.all;

use work.GeneralPipeDev.all;

--use work.CommonRouting.all;
use work.TEMP_DEV.all;

use work.ProcLogicExec.all;

use work.ProcComponents.all;


package SimLogicExec is

function shiftWord(w: word; sh: slv5; right, arith: std_logic) return word;

function performALU(ins: InstructionState) return InstructionState;


end SimLogicExec;



package body SimLogicExec is

function shiftWord(w: word; sh: slv5; right, arith: std_logic) return word is
	variable res: word := w;
	variable intSh: integer := slv2u(sh); -- CAREFUL, TODO: specify behavior
begin
	if right = '1' then	
		for i in 0 to 31 loop
			if i = intSh-1 then
				exit;
			end if;
			res(30 downto 0) := res(31 downto 1);
			if arith = '0' then
				res(31) := '0';
			end if;
		end loop;
	else
		for i in 0 to 31 loop
			if i = intSh-1 then
				exit;
			end if;
			res(31 downto 1) := res(30 downto 0);
			res(0) := '0';
		end loop;		
	end if;
	return res;
end function;

function performALU(ins: InstructionState) return InstructionState is
	variable res: InstructionState := ins;
	variable a, b, tmp, aluResult: Mword := (others => '0');
begin
	a := ins.argValues.arg0;
	b := ins.argValues.arg1;
	case ins.operation.func is
		when arithAdd => 
			tmp := addWord(a, b);
			if a(31) = b(31) and a(31) /= tmp(31) then
				res := setExecState(res, tmp, '0', "0001"); -- ??
			end if;
			res.result := tmp;
		when arithSub =>
			b := not b;
			b := addWord(b, X"00000001");
			tmp := addWord(a, b);
			if a(31) = b(31) and a(31) /= tmp(31) then
				res := setExecState(res, tmp, '0', "0001"); -- ??
			end if;
			res.result := tmp;
		when arithShra =>
			res.result := shiftWord(a, ins.constantArgs.c0, '1', '1');
		when logicAnd => 
			res.result := a and b;
		when logicOr => 
			res.result := a or b;			
		when logicShrl => 
			res.result := shiftWord(a, ins.constantArgs.c0, '1', '0');
		when logicShl =>
			res.result := shiftWord(a, ins.constantArgs.c0, '0', '0');			
		when others => 
			
	end case;
	
	return res;
end function;

 
end SimLogicExec;
