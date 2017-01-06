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
		

	
function renameRegs(insVec: StageDataMulti; takeVec, destMask: std_logic_vector;
								psVec, pdVec: PhysNameArray; gprTags: SmallNumberArray) 		
return StageDataMulti;
	
function prepareForAGU(insVec: StageDataMulti) return StageDataMulti;
function prepareForStoreData(insVec: StageDataMulti) return StageDataMulti;


function getStableDestsParallel(insVec: StageDataMulti; pdVec: PhysNameArray) return PhysNameArray;

function baptizeGroup(insVec: StageDataMulti; newGroupTag: SmallNumber) return StageDataMulti;

function fetchLockCommitting(sd: StageDataMulti) return std_logic;
function getSysRegWriteAllow(sd: StageDataMulti) return std_logic;
function getSysRegWriteSel(sd: StageDataMulti) return slv5;
function getSysRegWriteValue(sd: StageDataMulti) return Mword;

end ProcLogicRenaming;



package body ProcLogicRenaming is

function getRegMapRequest(sd: StageDataMulti; newPhys: PhysNameArray) return RegisterMapRequest is
	variable res: RegisterMapRequest;
begin
	-- Choose ops that have real virtual destination.
	-- Unselect mappings not written because of WAW dependency.
	res.sel := getDestMask(sd) and not findOverriddenDests(sd);
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



function renameRegs(insVec: StageDataMulti; takeVec, destMask: std_logic_vector;
							psVec, pdVec: PhysNameArray; gprTags: SmallNumberArray) 
return StageDataMulti is
	variable res: StageDataMulti := insVec;
	variable k: natural := 0;					
begin
	for i in insVec.fullMask'range loop		
		res.data(i).gprTag := gprTags(i); -- ???
		res.data(i).physicalArgs.sel := res.data(i).virtualArgs.sel;
		res.data(i).physicalArgs.s0 := psVec(3*i+0);	
		res.data(i).physicalArgs.s1 := psVec(3*i+1);			
		res.data(i).physicalArgs.s2 := psVec(3*i+2);							
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
		res.data(i).physicalDestArgs.sel(0) := destMask(i);
		if takeVec(i) = '1' then
			res.data(i).physicalDestArgs.d0 := pdVec(k);
			k := k + 1;
		end if;	
															
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
				res.data(i).controlInfo.completed2 := not res.data(i).classInfo.secCluster;
				
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



function getStableDestsParallel(insVec: StageDataMulti; pdVec: PhysNameArray) return PhysNameArray is
	variable res: PhysNameArray(0 to PIPE_WIDTH-1) := pdVec(0 to PIPE_WIDTH-1);
begin
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

	
	function fetchLockCommitting(sd: StageDataMulti) return std_logic is
	begin
		for i in sd.fullMask'range loop
			if sd.fullMask(i) = '1' and sd.data(i).classInfo.fetchLock = '1' then
				return '1';
			end if;
		end loop;
		return '0';
	end function;
	
	function getSysRegWriteAllow(sd: StageDataMulti) return std_logic is
	begin
		for i in sd.fullMask'range loop
			if 	sd.fullMask(i) = '1' 
				and sd.data(i).operation.unit = System
				and sd.data(i).operation.func = sysMtc
				and sd.data(i).controlInfo.hasException = '0' -- Don't allow if instruction had exception!
			then
				return '1';
			end if;
		end loop;
		return '0';
	end function;

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

end ProcLogicRenaming;
