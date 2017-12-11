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

use work.Decoding2.all;

use work.TEMP_DEV.all;
use work.GeneralPipeDev.all;


package ProcLogicExec is

	-- DUMMY: This performs some siple operation to obtain a result
	function passArg0(ins: InstructionState) return InstructionState;
	function passArg1(ins: InstructionState) return InstructionState;
	function execLogicOr(ins: InstructionState) return InstructionState;
	function execLogicXor(ins: InstructionState) return InstructionState;

	-- set exception flags
	function raiseExecException(ins: InstructionState) return InstructionState;
	
	function resolveBranchCondition(av: InstructionArgValues; ca: InstructionConstantArgs) return std_logic;

	function basicBranch(ins: InstructionState; sysRegValue: Mword;
								linkAddress: Mword) return InstructionState;

	function setExecState(ins: InstructionState;
								result: Mword; carry: std_logic; exc: std_logic_vector(3 downto 0))
	return InstructionState;

	function executeAlu(ins: InstructionState) return InstructionState;

	function isIndirectBranchOrReturn(ins: InstructionState) return std_logic;
	
end ProcLogicExec;



package body ProcLogicExec is

	function passArg0(ins: InstructionState) return InstructionState is
		variable res: InstructionState := ins;
	begin
		res.result := res.argValues.arg0;
		return res;
	end function;

	function passArg1(ins: InstructionState) return InstructionState is
		variable res: InstructionState := ins;
	begin
		res.result := res.argValues.arg1;
		return res;
	end function;

	function execLogicOr(ins: InstructionState) return InstructionState is
		variable res: InstructionState := ins;
	begin
		res.result := res.argValues.arg0 or res.argValues.arg1;
		return res;
	end function;	

	function execLogicXor(ins: InstructionState) return InstructionState is
		variable res: InstructionState := ins;
	begin
		res.result := res.argValues.arg0 xor res.argValues.arg1;
		return res;
	end function;	

 
	function raiseExecException(ins: InstructionState) return InstructionState is
		variable res: InstructionState := ins;
	begin
		res.controlInfo.newEvent := '1';	
		--res.controlInfo.hasEvent := '1';	
		--res.controlInfo.newException := '1';
		res.controlInfo.hasException := '1';			
		return res;	
	end function;

	function resolveBranchCondition(av: InstructionArgValues; ca: InstructionConstantArgs) return std_logic is
		variable isZero: std_logic;
	begin
		isZero := not isNonzero(av.arg0);
			
		if ca.c1 = COND_NONE then
			return '1';
		elsif ca.c1 = COND_Z and isZero = '1' then
			return '1';
		elsif ca.c1 = COND_NZ and isZero = '0' then
			return '1';
		else
			return '0';
		end if;	
		
	end function;

	function basicBranch(ins: InstructionState; sysRegValue: Mword;
								linkAddress: Mword) return InstructionState is
		variable res: InstructionState := ins;
		variable branchTaken: std_logic := '0';
	begin		
			res.operation := (General, Unknown);
	
			-- Return address
			res.result := linkAddress;
			if ins.classInfo.branchCond = '1' then
				branchTaken := resolveBranchCondition(ins.argValues, ins.constantArgs);
				if res.controlInfo.hasBranch = '1' and branchTaken = '0' then
					res.controlInfo.hasBranch := '0';
					--res.controlInfo.newReturn := '1';
					res.controlInfo.hasReturn := '1';						
					res.controlInfo.newEvent := '1';
					--res.controlInfo.hasEvent := '1';						
				elsif res.controlInfo.hasBranch = '0' and branchTaken = '1' then				
					res.controlInfo.hasReturn := '0';
					res.controlInfo.newBranch := '1';
					res.controlInfo.hasBranch := '1';						
					res.controlInfo.newEvent := '1';
					--res.controlInfo.hasEvent := '1';					
				end if;
			end if;	

			res.target := ins.argValues.arg1;
								
		return res;
	end function;
 
	function setExecState(ins: InstructionState;
								result: Mword; carry: std_logic; exc: std_logic_vector(3 downto 0))
	return InstructionState is
		variable res: InstructionState := ins;
	begin
		res.result := result;
		res.controlInfo.newEvent := isNonzero(exc);
		--res.controlInfo.hasEvent := res.controlInfo.newEvent;
		--res.controlInfo.newException := res.controlInfo.newEvent;
		res.controlInfo.hasException := res.controlInfo.newEvent;						
		res.controlInfo.exceptionCode := (others => '0');
		res.controlInfo.exceptionCode(3 downto 0) := exc;
		return res;
	end function;
	
	function executeAlu(ins: InstructionState) return InstructionState is
		variable res: InstructionState := ins;
		variable result: Mword := (others => '0');
		variable arg0, arg1, arg2: Mword := (others => '0');
			variable argAddSub: Mword := (others => '0');
			variable carryIn: std_logic := '0';
		variable c0, c1: slv5 := (others => '0');
		variable resultExt: std_logic_vector(MWORD_SIZE downto 0) := (others => '0');
		variable ov, carry: std_logic := '0';
		variable shH, shL: integer := 0;
		variable shNum, shTemp: SmallNumber := (others => '0');
			variable tempBits: std_logic_vector(95 downto 0) := (others => '0'); -- TEMP! for 32b only
			variable shiftedBytes: std_logic_vector(39 downto 0) := (others => '0');
	begin
		arg0 := ins.argValues.arg0;
		arg1 := ins.argValues.arg1;
		arg2 := ins.argValues.arg2;
	
		c0 := ins.constantArgs.c0;
		c1 := ins.constantArgs.c1;	
	
	
			if ins.operation.func = arithSub then
				argAddSub := not arg1;
				carryIn := '1';
			else
				argAddSub := arg1;
				carryIn := '0';
			end if;
	
	
		shTemp(4 downto 0) := c0; -- CAREFUL, TODO: handle the issue of 1-32 vs 0-31	
		if ins.operation.func = logicShl then
			shNum := subSN(shNum, shTemp);
			
			--	report integer'image(slv2u(shNum));
			--	report integer'image(slv2s(shNum(5 downto 3)));
		else
			shNum := shTemp;
		end if;
	
		shH := slv2s(shNum(5 downto 3));
				--0;
		shL := slv2u(shNum(2 downto 0));
	
		if ins.operation.func = arithShra then
			tempBits(95 downto 64) := (others => arg0(MWORD_SIZE-1));	
		end if;
		tempBits(63 downto 32) := arg0;
	
			shiftedBytes := tempBits(71 + 8*shH downto 32 + 8*shH);
			
	
		-- Shifting: divide into byte part and intra-byte part
		--	shift left by 8*H + L
		-- must be universal: the H part also negative
		-- shift right by 3: 8*(-1) + 5
		--	Let's treat the number as 64 bit: [arg0 & 0x00000000] and mux relative to right bound.
		-- sh right 20 -> move window left by 2*8 + 4
		-- sh right 31 -> move window left by 3*8 + 7
		-- sh left   2 -> move window right by -1*8 + 6
		-- sh left  15 -> move window right by -2*8 + 1
		
		-- So, for shift left, number is negative, for right is positive
		-- Most negative byte count is -4, giving -4*8 + 0 = -32
		-- Most positive byte count is 3, giving 3*8 + 7 = 31
		

				resultExt := --addMwordExt(arg0, arg1);
								addMwordFasterExt(arg0, --arg1, '0');
																argAddSub, carryIn);	
		case ins.operation.func is 
			when arithAdd => 
				--resultExt := --addMwordExt(arg0, arg1);
				--				addMwordFasterExt(arg0, --arg1, '0');
				--												argAddSub, carryIn);
				if
					(arg0(MWORD_SIZE-1) = arg1(MWORD_SIZE-1)) and
					(arg0(MWORD_SIZE-1) /= resultExt(MWORD_SIZE-1))				
				then
					ov := '1';
				end if;
				carry := resultExt(MWORD_SIZE);
				result := resultExt(MWORD_SIZE-1 downto 0);
			when arithSub =>
				--resultExt := --subMwordExt(arg0, arg1);
				--				addMwordFasterExt(arg0, --not arg1, '1'); -- NOTE: sub x,y as add x,~y+1	
				--												argAddSub, carryIn);
				if
					(arg0(MWORD_SIZE-1) /= arg1(MWORD_SIZE-1)) and
					(arg0(MWORD_SIZE-1) /= resultExt(MWORD_SIZE-1))				
				then
					ov := '1';
				end if;
				carry := resultExt(MWORD_SIZE); -- CAREFUL, with subtraction carry is different, keep in mind
				result := resultExt(MWORD_SIZE-1 downto 0);	

			when logicAnd =>
				result := arg0 and arg1;				
			when logicOr =>
				result := arg0 or arg1;
				
--				when arithShra => 
--					--result := (others => arg0(MWORD_SIZE-1)); -- Sign injection
--					--result(MWORD_SIZE-1 - sh downto 0) := arg0(MWORD_SIZE-1 downto sh);
--				
--				when logicShrl =>
--					result(MWORD_SIZE-1 - shL downto 0) := arg0(MWORD_SIZE-1 downto shL);
--				when logicShl =>
--					result(MWORD_SIZE-1 downto shL) := arg0(MWORD_SIZE-1 - shL downto 0);				
--				
			when others => 
				result := shiftedBytes(31 + shL downto shL);
			
				--report "Unknown alu operation" severity error;
		end case;
		
		if ov = '1' then
			res.controlInfo.newEvent := '1';
			res.controlInfo.hasException := '1';
			res.controlInfo.exceptionCode := (0 => '1', others => '0'); -- ???
		end if;
		
		res.result := result;
		
		return res;
	end function;

		function isIndirectBranchOrReturn(ins: InstructionState) return std_logic is
		begin
			return 	  (ins.controlInfo.hasBranch and not ins.constantArgs.immSel)
					 or   ins.controlInfo.hasReturn;
		end function;

end ProcLogicExec;
