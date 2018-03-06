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

use work.TEMP_DEV.all;
use work.GeneralPipeDev.all;


package ProcLogicRouting is

-- Gives queue number based on functional unit
function unit2queue(unit: ExecUnit) return integer;
function routeToIQ(sd: StageDataMulti; srcVec: std_logic_vector) return StageDataMulti;	
function routeToIQ2(sd: StageDataMulti; srcVec: std_logic_vector) return StageDataMulti;	


function findForALU(iv: InstructionStateArray) return std_logic_vector;

function findBranchLink(insv: StageDataMulti) return std_logic_vector;

function whichBranchLink(insv: StageDataMulti) return std_logic_vector;
function setBranchLink(insv: StageDataMulti) return StageDataMulti;

function findStores(insv: StageDataMulti) return std_logic_vector;
function findLoads(insv: StageDataMulti) return std_logic_vector;


function prepareForAGU(insVec: StageDataMulti) return StageDataMulti;
function prepareForBranch(insVec: StageDataMulti) return StageDataMulti;
function prepareForAlu(insVec: StageDataMulti; bl: std_logic_vector) return StageDataMulti;
function prepareForStoreData(insVec: StageDataMulti) return StageDataMulti;

-- Description: arg1 := target
function trgForBQ(insVec: StageDataMulti) return StageDataMulti;

end ProcLogicRouting;



package body ProcLogicRouting is

function unit2queue(unit: ExecUnit) return integer is
begin
	--return ISSUE_ROUTING_TABLE(unit);
	case unit is
		when General => return -1; -- Should never happen!
		when ALU => return 0;
		when MAC => return 1;
		when Divide => return 0;
		when Jump => return 3;
		when Memory => return 2;
		when System => return 3 + 1;
		when others => return -1;
	end case;
end function;

	-- New routing to IQ, to replace IssueRouting
	function routeToIQ(sd: StageDataMulti; srcVec: std_logic_vector) return StageDataMulti is
		variable res: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
		variable k: natural := 0;
			constant CLEAR_EMPTY_SLOTS_IQ_ROUTING: boolean := false;
	begin
		if not CLEAR_EMPTY_SLOTS_IQ_ROUTING then
			res.data := sd.data;
		end if;
	
		for i in sd.fullMask'range loop
			if srcVec(i) = '1' then
				if sd.fullMask(k) = '0' then -- If no more instructions in packet, stop
					exit;
				end if;
				res.fullMask(k) := '1';
				res.data(k) := sd.data(i);
				k := k + 1;
			end if;
		end loop;
		return res;
	end function;	

		function routeToIQ2(sd: StageDataMulti; srcVec: std_logic_vector) return StageDataMulti is
			variable res: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
			variable k: natural := 0;
				constant CLEAR_EMPTY_SLOTS_IQ_ROUTING: boolean := false;
		begin
			if not CLEAR_EMPTY_SLOTS_IQ_ROUTING then
				res.data := sd.data;
			end if;
		
			for i in sd.fullMask'range loop
				-- Fill with input(j) where j is index of i-th '1' in srcVec
				-- For output(0):
				--	"0000" -> 3?
				-- "0001" -> 3
				-- "0010" -> 2
				-- "0011" -> 2
				-- "0100" -> 1
				-- "0101" -> 1
				-- "0110" -> 1 etc.
				--		 ^ last bit is neutral for data, only matters for 'full' bit
				-- For output(1):
				-- "0000" -> 3?
				-- "0001" -> 3?
				-- "0010" -> 3?
				-- "0011" -> 3
				-- "0100" -> 3? 2?
				-- "0101" -> 3
				-- "0110" -> 2
				-- "0111" -> 2
				-- "1000" -> 1? 2? 3? 
				-- "1001" -> 3
				-- "1010" -> 2
				-- "1011" -> 2
				-- "1100" -> 1
				-- "1101" -> 1
				-- "1110" -> 1
				-- "1111" -> 1
				-- 	 ^ last bit is neutral, penult is not
				--			Formula: 1 + ofs, ofs = 0 when "11__", 1 when "101_" or "011_", else 2 ??
				-- For output(2):
				-- "0000" -> ?
				-- "0001" -> ?
				-- "0010" -> ?
				-- "0011" -> ?
				-- "0100" -> ?
				-- "0101" -> ?
				-- "0110" -> ?
				-- "0111" -> 3
				-- "1000" -> ?
				-- "1001" -> ?
				-- "1010" -> ?
				-- "1011" -> 3
				-- "1100" -> ?
				-- "1101" -> 3
				-- "1110" -> 2
				-- "1111" -> 2
				-- 	^ last bit neutral. 2 when "111_", 3 when "110_"
				--		formula": 2 + ofs, ofs = 0 when "111_", else 1
				
				-- Idea: separate the logic for each output. index(0) = f0(mask), index(1) = f1(mask) etc.
				-- So in this place make inner loop with each possible mux index
				for j in 0 to PIPE_WIDTH-1 loop
					-- Select route input(j)->output(i) if condition met
					res.data(i) := sd.data(j);
					if countOnes(srcVec(0 to j-1)) = i and srcVec(j) = '1' then
						res.fullMask(i) := '1';
						exit;
					end if;
				end loop;
			end loop;
			return res;
		end function;


function findForALU(iv: InstructionStateArray) return std_logic_vector is
	constant LEN: integer := iv'length;
	variable res: std_logic_vector(0 to LEN-1) := (others => '0'); 
begin
	for i in 0 to LEN-1 loop
		if iv(i).operation.unit = ALU then
			res(i) := '1';
		end if;
	end loop;
	return res;
end function;

function findBranchLink(insv: StageDataMulti) return std_logic_vector is
	variable res: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
begin
	for i in 0 to PIPE_WIDTH-1 loop
		if 	 insv.data(i).operation = (Jump, jump)
			and isNonzero(insv.data(i).virtualDestArgs.d0) = '1'
			and insv.data(i).virtualDestArgs.sel(0) = '1'
		then
			res(i) := '1';
		end if;
	end loop;
	return res;
end function;


function whichBranchLink(insv: StageDataMulti) return std_logic_vector is
	variable res: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
begin
	for i in 0 to PIPE_WIDTH-1 loop
		res(i) := insv.data(i).classInfo.branchLink;
	end loop;
	
	return res;
end function;

function setBranchLink(insv: StageDataMulti) return StageDataMulti is
	variable res: StageDataMulti := insv;
	variable bl: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
begin
	bl := findBranchLink(insv);
	for i in 0 to PIPE_WIDTH-1 loop
		res.data(i).classInfo.branchLink := bl(i);
	end loop;
	
	return res;
end function;


function findStores(insv: StageDataMulti) return std_logic_vector is
	variable res: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
begin
	for i in 0 to PIPE_WIDTH-1 loop
		if 	insv.data(i).operation = (Memory, store) 
			or	insv.data(i).operation = (System, sysMTC)
		then
			res(i) := '1';
		end if;
	end loop;
	return res;
end function;

function findLoads(insv: StageDataMulti) return std_logic_vector is
	variable res: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
begin
	for i in 0 to PIPE_WIDTH-1 loop
		if 	insv.data(i).operation = (Memory, load)
			or	insv.data(i).operation = (System, sysMFC)
		then
			res(i) := '1';
		end if;
	end loop;
	return res;
end function;



function prepareForAGU(insVec: StageDataMulti) return StageDataMulti is
	variable res: StageDataMulti := insVec;
begin
	for i in 0 to PIPE_WIDTH-1 loop
		res.data(i).virtualArgs.sel(2) := '0';
		res.data(i).physicalArgs.sel(2) := '0';
		res.data(i).argValues.missing(2) := '0';
		
			res.data(i).controlInfo.completed := '0';
			res.data(i).controlInfo.completed2 := '0';
	end loop;
	return res;
end function;

function prepareForBranch(insVec: StageDataMulti) return StageDataMulti is
	variable res: StageDataMulti := insVec;
begin
	for i in 0 to PIPE_WIDTH-1 loop
		if res.data(i).operation /= (System, sysMfc) then
			res.data(i).virtualDestArgs.sel := (others => '0');		
			res.data(i).virtualDestArgs.d0 := (others => '0');
			res.data(i).physicalDestArgs.sel := (others => '0');			
			res.data(i).physicalDestArgs.d0 := (others => '0');
		end if;
		
		if insVec.data(i).controlInfo.hasBranch = '1' then
			res.data(i).constantArgs.imm := res.data(i).result;			
		else
			res.data(i).constantArgs.imm := res.data(i).target;
		end if;
		
	end loop;
	return res;
end function;

function prepareForAlu(insVec: StageDataMulti; bl: std_logic_vector) return StageDataMulti is
	variable res: StageDataMulti := insVec;
begin
	for i in 0 to PIPE_WIDTH-1 loop
		--if 	 res.data(i).operation = (Jump, jump) and isNonzero(res.data(i).virtualDestArgs.d0) = '1'
		--	and res.data(i).virtualDestArgs.sel(0) = '1'
--		if bl(i) = '1'
--		then
--			--		assert bl(i) = '1' report "ttttt";
--		
--			res.data(i).operation := (Alu, arithAdd);
--		
--			res.data(i).physicalArgs.s0 := (others => '0');
--			res.data(i).argValues.zero(0) := '1';
--			res.data(i).argValues.missing(0) := '0';
--			
--			res.data(i).constantArgs.imm := res.data(i).result;
--		--else	
--			--		assert bl(i) = '0' report "rrrrrrrrrr";
--		end if;
	end loop;
	return res;
end function;

function prepareForStoreData(insVec: StageDataMulti) return StageDataMulti is
	variable res: StageDataMulti := insVec;
begin
	for i in 0 to PIPE_WIDTH-1 loop
		res.data(i).virtualArgs.sel(0) := '0';
		res.data(i).virtualArgs.sel(1) := '0';		
		res.data(i).physicalArgs.sel(0) := '0';
		res.data(i).physicalArgs.sel(1) := '0';		
		res.data(i).constantArgs.immSel := '0';
		res.data(i).virtualDestArgs.sel(0) := '0';
		res.data(i).physicalDestArgs.sel(0) := '0';
		
			res.data(i).controlInfo.completed := '0';
			res.data(i).controlInfo.completed2 := '0';
	end loop;
	return res;
end function;

function trgForBQ(insVec: StageDataMulti) return StageDataMulti is
	variable res: StageDataMulti := insVec;
begin
	for i in 0 to PIPE_WIDTH-1 loop
		res.data(i).argValues.arg1 := res.data(i).target;
		res.data(i).argValues.arg2 := res.data(i).result;
	end loop;
	
	return res;
end function;

end ProcLogicRouting;
