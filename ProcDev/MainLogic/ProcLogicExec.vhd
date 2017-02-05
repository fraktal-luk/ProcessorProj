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
		res.controlInfo.hasEvent := '1';	
		res.controlInfo.newException := '1';	
		res.controlInfo.hasException := '1';			
		return res;	
	end function;

	function resolveBranchCondition(av: InstructionArgValues; ca: InstructionConstantArgs) return std_logic is
		variable isZero: std_logic;
		--variable zeros: Mword := (others=>'0');
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
		if ins.operation.unit = System then
--				if false and ins.operation.func = sysRetI then
--					res.controlInfo.newIntReturn := '1';
--					res.controlInfo.hasIntReturn := '1';					
--					res.controlInfo.newEvent := '1';
--					res.controlInfo.hasEvent := '1';					
--				elsif false and ins.operation.func = sysRetE then
--					res.controlInfo.newExcReturn := '1';
--					res.controlInfo.hasExcReturn := '1';						
--					res.controlInfo.newEvent := '1';
--					res.controlInfo.hasEvent := '1';						
--				elsif 
				if 
					ins.operation.func = sysMfc then			
					res.result := sysRegValue;
				elsif ins.operation.func = sysMtc then
					res.result := ins.argValues.arg0;
				elsif ins.operation.func = sysUndef then
					--res.controlInfo.newException := '1';
					res.controlInfo.hasException := '1';				
					--res.controlInfo.newEvent := '1';
					res.controlInfo.hasEvent := '1';					
				else
						
				end if;
		else		
			
			-- Return address
			-- CAREFUL, TODO: when introducing 16b instructions, it won't be always 4 bytes ahead!
			--	4B problem
			res.result := --i2slv(slv2u(ins.basicInfo.ip) + 4, MWORD_SIZE);
								linkAddress;
			if ins.classInfo.branchCond = '1' then
				branchTaken := resolveBranchCondition(ins.argValues, ins.constantArgs);
				if res.controlInfo.hasBranch = '1' and branchTaken = '0' then
					res.controlInfo.hasBranch := '0';
					res.controlInfo.newReturn := '1';
					res.controlInfo.hasReturn := '1';						
					res.controlInfo.newEvent := '1';
					res.controlInfo.hasEvent := '1';						
				elsif res.controlInfo.hasBranch = '0' and branchTaken = '1' then				
					res.controlInfo.hasReturn := '0';
					res.controlInfo.newBranch := '1';
					res.controlInfo.hasBranch := '1';						
					res.controlInfo.newEvent := '1';
					res.controlInfo.hasEvent := '1';					
				end if;
			end if;	

			if ins.classInfo.branchReg = '1' then
				res.target := ins.argValues.arg1;
			end if;	
		end if;
								
		return res;
	end function;
 
	function setExecState(ins: InstructionState;
								result: Mword; carry: std_logic; exc: std_logic_vector(3 downto 0))
	return InstructionState is
		variable res: InstructionState := ins;
	begin
		res.result := result;
		res.controlInfo.newEvent := isNonzero(exc);
		res.controlInfo.hasEvent := res.controlInfo.newEvent;
		res.controlInfo.newException := res.controlInfo.newEvent;
		res.controlInfo.hasException := res.controlInfo.newEvent;						
		res.controlInfo.exceptionCode := (others => '0');
		res.controlInfo.exceptionCode(3 downto 0) := exc;
		return res;
	end function;
	 
end ProcLogicExec;
