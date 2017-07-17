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


package ProcLogicRenaming is


type RegisterMapRequest is record
	sel: std_logic_vector(0 to PIPE_WIDTH-1);
	index: RegNameArray(0 to PIPE_WIDTH-1);
	value: PhysNameArray(0 to PIPE_WIDTH-1);
end record;

constant DEFAULT_REGISTER_MAP_REQUEST: RegisterMapRequest := 
	(sel => (others => '0'), index => (others => (others => '0')), value => (others => (others => '0')));

function getRegMapRequest(sd: StageDataMulti; newPhys: PhysNameArray) return RegisterMapRequest;


function baptizeVec(sd: StageDataMulti; tags: SmallNumberArray) 
return StageDataMulti;

function renameRegs2(insVec: StageDataMulti; takeVec, destMask: std_logic_vector;
								psVec, pdVec: PhysNameArray) 		
return StageDataMulti;

function setArgStatus(insVec: StageDataMulti; readyRegFlagsVirtualNext: std_logic_vector) 
return StageDataMulti;

	
function prepareForAGU(insVec: StageDataMulti) return StageDataMulti;
function prepareForBranch(insVec: StageDataMulti) return StageDataMulti;
function prepareForAlu(insVec: StageDataMulti; bl: std_logic_vector) return StageDataMulti;
function prepareForStoreData(insVec: StageDataMulti) return StageDataMulti;


function getStableDestsParallel(insVec: StageDataMulti; pdVec: PhysNameArray) return PhysNameArray;

function baptizeGroup(insVec: StageDataMulti; newGroupTag: SmallNumber) return StageDataMulti;

function baptizeAll(insVec: StageDataMulti; numberTags: SmallNumberArray;
						  newGroupTag: SmallNumber; gprTags: SmallNumberArray)
return StageDataMulti;


-- TODO: use effective mask rather than full mask in this functions!
--function fetchLockCommitting(sd: StageDataMulti; effective: std_logic_vector) return std_logic;
function getSysRegWriteAllow(sd: StageDataMulti; effective: std_logic_vector) return std_logic;
-- CAREFUL: this seems not used and would choose the last value in group
function getSysRegWriteSel(sd: StageDataMulti) return slv5;
-- CAREFUL: this seems not used and would choose the last value in group
function getSysRegWriteValue(sd: StageDataMulti) return Mword;

-- FUNCTION BODY
function TMP_handleSpecial(sd: StageDataMulti) return StageDataMulti is
	variable res: StageDataMulti := sd;
	variable found: boolean := false;
begin
	-- If found special instruction, kill next ones
	for i in 0 to PIPE_WIDTH-1 loop
		if found then
			res.fullMask(i) := '0';
		end if;

		if 	res.data(i).controlInfo.specialAction = '1'
			or res.data(i).controlInfo.hasException = '1' -- CAREFUL
			--	TODO: include here also early branches? 
		then
			found := true;
		end if;
	end loop;
	
	return res;
end function;


function initList return PhysNameArray;

end ProcLogicRenaming;



package body ProcLogicRenaming is

function getRegMapRequest(sd: StageDataMulti; newPhys: PhysNameArray) return RegisterMapRequest is
	variable res: RegisterMapRequest;
begin
	-- Choose ops that have real virtual destination.
	-- Unselect mappings not written because of WAW dependency.
	res.sel := getDestMask(sd) and sd.fullMask 		-- have to be full!
					and not getExceptionMask(sd)			-- if exception, doesn't write
					and not findOverriddenDests(sd);
	for i in 0 to PIPE_WIDTH-1 loop
		res.index(i) := sd.data(i).virtualDestArgs.d0;
		res.value(i) := newPhys(i);
	end loop;
	return res;
end function;


function baptizeVec(sd: StageDataMulti; tags: SmallNumberArray) 
return StageDataMulti is
	variable res: StageDataMulti := sd;
begin
	for i in res.data'range loop
		if true or res.fullMask(i) = '1' then
			res.data(i).numberTag := tags(i);
		end if;
	end loop;
	return res;
end function;


function renameRegs2(insVec: StageDataMulti; takeVec, destMask: std_logic_vector;
							psVec, pdVec: PhysNameArray) 
return StageDataMulti is
	variable res: StageDataMulti := insVec;
	variable k: natural := 0;					
begin
	for i in insVec.fullMask'range loop
		-- Set physical dest
		res.data(i).physicalDestArgs.sel(0) := destMask(i);
		if takeVec(i) = '1' then
			res.data(i).physicalDestArgs.d0 := pdVec(k);
			k := k + 1;
		end if;
	end loop;
	
	for i in insVec.fullMask'range loop	
		-- Set physical sources
		res.data(i).physicalArgs.sel := res.data(i).virtualArgs.sel;
		res.data(i).physicalArgs.s0 := psVec(3*i+0);	
		res.data(i).physicalArgs.s1 := psVec(3*i+1);			
		res.data(i).physicalArgs.s2 := psVec(3*i+2);							
		-- Correct physical sources for group dependencies
		for j in insVec.fullMask'range loop	
			-- Is s0 equal to prev instruction's dest?				
			if j = i then exit; end if;				
			if insVec.data(i).virtualArgs.s0 = insVec.data(j).virtualDestArgs.d0
				and isNonzero(insVec.data(i).virtualArgs.s0) = '1' -- CAREFUL: don't copy dummy dest for r0
			then
				res.data(i).physicalArgs.s0 := res.data(j).physicalDestArgs.d0;
			end if;		
			if 	 insVec.data(i).virtualArgs.s1 = insVec.data(j).virtualDestArgs.d0
				and isNonzero(insVec.data(i).virtualArgs.s1) = '1' -- CAREFUL: don't copy dummy dest for r0
			then	
				res.data(i).physicalArgs.s1 := res.data(j).physicalDestArgs.d0;						
			end if;	
			if 	 insVec.data(i).virtualArgs.s2 = insVec.data(j).virtualDestArgs.d0 
				and isNonzero(insVec.data(i).virtualArgs.s2) = '1' -- CAREFUL: don't copy dummy dest for r0
			then
				res.data(i).physicalArgs.s2 := res.data(j).physicalDestArgs.d0;						
			end if;						
		end loop;
		
	end loop;

	return res;
end function;


function setArgStatus(insVec: StageDataMulti; readyRegFlagsVirtualNext: std_logic_vector) 
return StageDataMulti is
	variable res: StageDataMulti := insVec;
begin
	for i in insVec.fullMask'range loop	
		-- Set state markers: "zero" bit		
		if isNonzero(res.data(i).virtualArgs.s0) = '0' then
			res.data(i).argValues.zero(0) := '1';
		end if;
		
		if isNonzero(res.data(i).virtualArgs.s1) = '0' then
			res.data(i).argValues.zero(1) := '1';
		end if;

		if isNonzero(res.data(i).virtualArgs.s2) = '0' then
			res.data(i).argValues.zero(2) := '1';
		end if;		
			
		-- Set 'missing' flags for non-const arguments
		res.data(i).argValues.missing := res.data(i).physicalArgs.sel and not res.data(i).argValues.zero;
		
		-- Handle possible immediate arg
		if res.data(i).constantArgs.immSel = '1' then
			res.data(i).argValues.missing(1) := '0';
			res.data(i).argValues.immediate := '1';
			res.data(i).argValues.zero(1) := '0';
			res.data(i).argValues.arg1 := res.data(i).constantArgs.imm;					
		end if;
		
		res.data(i).argValues.readyBefore := not res.data(i).argValues.missing;

			-- TODO: now handle 'completed' flags. If only main Exec cluster, 'completed2' = '1'.
			--													If only secondary Exec cl, 'completed'  = '1'.
			--													If both clusters,				both				'0'.
				-- Set completed2 to false if it does need to be performed by the instruction
			res.data(i).controlInfo.completed := not res.data(i).classInfo.mainCluster;				
			res.data(i).controlInfo.completed2 := not res.data(i).classInfo.secCluster;
				
	end loop;	
	
	
	return res; -- CAREFUL: this must be removed if using virtual ready map
	
		-- Virtual ready table
		for i in 0 to PIPE_WIDTH-1 loop
			res.data(i).argValues.missing(0) := res.data(i).argValues.missing(0) 
					and not readyRegFlagsVirtualNext(3*i + 0);
			res.data(i).argValues.missing(1) := res.data(i).argValues.missing(1)
					and not readyRegFlagsVirtualNext(3*i + 1);
			res.data(i).argValues.missing(2) := res.data(i).argValues.missing(2)
					and not readyRegFlagsVirtualNext(3*i + 2);
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
		if bl(i) = '1'
		then
			--		assert bl(i) = '1' report "ttttt";
		
			res.data(i).operation := (Alu, arithAdd);
		
			res.data(i).physicalArgs.s0 := (others => '0');
			res.data(i).argValues.zero(0) := '1';
			res.data(i).argValues.missing(0) := '0';
			
			res.data(i).constantArgs.imm := res.data(i).result;
		--else	
			--		assert bl(i) = '0' report "rrrrrrrrrr";
		end if;
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
	end loop;
	return res;
end function;


-- CAREFUL: if use bypassing (>> usage in top module), don't exclude overridden dests 
--				from selection in RegisterFreeList!
function getStableDestsParallel(insVec: StageDataMulti; pdVec: PhysNameArray) return PhysNameArray is
	variable res: PhysNameArray(0 to PIPE_WIDTH-1) := pdVec(0 to PIPE_WIDTH-1);
begin
		return res; -- no bypassing
		
	for i in insVec.fullMask'range loop
		for j in insVec.fullMask'range loop	
			-- Is s0 equal to prev instruction's dest?				
			if j = i then exit; end if;				
			if insVec.data(i).virtualDestArgs.d0 = insVec.data(j).virtualDestArgs.d0
				and isNonzero(insVec.data(i).virtualDestArgs.d0) = '1' -- CAREFUL: don't copy dummy dest for r0
			then
				res(i) := insVec.data(j).physicalDestArgs.d0;
			end if;		
		end loop;			
	end loop;

	return res;
end function;


function baptizeGroup(insVec: StageDataMulti; newGroupTag: SmallNumber) return StageDataMulti is
	variable res: StageDataMulti := insVec;
begin
	for i in 0 to PIPE_WIDTH-1 loop
		res.data(i).groupTag := newGroupTag or i2slv(i, SMALL_NUMBER_SIZE);
	end loop;
	return res;
end function;

	
function baptizeAll(insVec: StageDataMulti; numberTags: SmallNumberArray;
						  newGroupTag: SmallNumber; gprTags: SmallNumberArray)
return StageDataMulti is
	variable res: StageDataMulti := insVec;
begin
	for i in 0 to PIPE_WIDTH-1 loop
		res.data(i).groupTag := newGroupTag or i2slv(i, SMALL_NUMBER_SIZE);
		res.data(i).numberTag := numberTags(i);
		res.data(i).gprTag := gprTags(i); -- ???		
	end loop;
	return res;
end function;


--	function fetchLockCommitting(sd: StageDataMulti; effective: std_logic_vector) return std_logic is
--	begin
--		for i in sd.fullMask'range loop
--			if --sd.fullMask(i) = '1' 
--						effective(i) = '1'
--				and sd.data(i).classInfo.fetchLock = '1' then
--				return '1';
--			end if;
--		end loop;
--		return '0';
--	end function;
	
	function getSysRegWriteAllow(sd: StageDataMulti; effective: std_logic_vector) return std_logic is
	begin
		for i in sd.fullMask'range loop
			if 	--sd.fullMask(i) = '1'
					effective(i) = '1'
				and sd.data(i).operation.unit = System
				and sd.data(i).operation.func = sysMtc
				and sd.data(i).controlInfo.hasException = '0' -- Don't allow if instruction had exception!
			then
				return '1';
			end if;
		end loop;
		return '0';
	end function;

	-- CAREFUL: this seems not used and would choose the last value in group
	function getSysRegWriteSel(sd: StageDataMulti) return slv5 is
		variable res: slv5 := (others => '0');
	begin
		for i in sd.fullMask'range loop
			if sd.fullMask(i) = '1' then
				res := sd.data(i).constantArgs.c0;
			end if;
		end loop;
		return res;
	end function;

	-- CAREFUL: this seems not used and would choose the last value in group
	function getSysRegWriteValue(sd: StageDataMulti) return Mword is
		variable res: Mword := (others => '0');
	begin
		for i in sd.fullMask'range loop
			if sd.fullMask(i) = '1' then
				res := sd.data(i).result;
			end if;
		end loop;
		return res;
	end function;

function initList return PhysNameArray is
	variable res: PhysNameArray(0 to FREE_LIST_SIZE-1) := (others => (others=> '0'));
begin
	for i in 0 to N_PHYS - 32 - 1 loop
		res(i) := i2slv(32 + i, PhysName'length);
	end loop;
	return res;
end function;
			
end ProcLogicRenaming;
