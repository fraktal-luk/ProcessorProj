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

use work.Decoding2.all;

use work.NewPipelineData.all;

package TEMP_DEV is

-- MOVE somewhere more general?
-- Get '1' bits for remaining slots, pushed to left
function pushToLeft(fullSlots, freedSlots: std_logic_vector) return std_logic_vector;


-- Type for table: ExecUnit -> exec subpipe number
type ExecUnitToNaturalTable is array(ExecUnit'left to ExecUnit'right) of integer;

-- Routing table for issue queues
-- 0 - ALU, Div
-- 1 - MAC
-- 2 - Memory
-- 3 - Jump, System
constant N_ISSUE_QUEUES: natural := 4;
constant ISSUE_ROUTING_TABLE: ExecUnitToNaturalTable := (
		General => -1, -- Should never happen!
		ALU => 0,
		MAC => 1,
		Divide => 0,
		Jump => 3,
		Memory => 2,
		System => 3);


	function setInstructionTarget(ins: InstructionState; target: Mword) return InstructionState;

-- TEMP?
function TEMP_branchPredict(ins: InstructionState) return InstructionState;


-- IQ ROUTING
-- Gives queue number based on functional unit
function unit2queue(unit: ExecUnit) return natural;
-- IQ ROUTING
function findByExecUnit(iv: InstructionStateArray; seeking: ExecUnit) return std_logic_vector;
function routeToIQ(sd: StageDataMulti; srcVec: std_logic_vector) return StageDataMulti;	

	
	-- Tells if 'a' is older than 'b'
	function tagBefore(a, b: SmallNumber) return std_logic;
	
	-- To determine which subpipe result directs control flow
	function findOldestSignal(ready: std_logic_vector; tags: SmallNumberArray) return std_logic_vector;
		
-- General, UNUSED?
function selectInstructions(content: InstructionStateArray; numbers: IntArray; nI: integer)
return InstructionStateArray;

	
function getArgumentStatusInfo(missing: std_logic_vector;
										 physNames: PhysNameArray;
										 ra: std_logic_vector;
										 tags: PhysNameArray;
										 tagsNext: PhysNameArray;
										 vals: MwordArray)
return ArgumentStatusInfo;	

function getArgumentStatusInfoArray(missing: std_logic_vector;
										 physNames: PhysNameArray;
										 ra: std_logic_vector;
										 tags: PhysNameArray;
										 tagsNext: PhysNameArray;
										 vals: MwordArray)
return ArgumentStatusInfoArray;	

function updateInstructionArgs(ins: InstructionState; argInfo: ArgumentStatusInfo) return InstructionState;
	
function updateInstructionArrayArgs(ia: InstructionStateArray; aia: ArgumentStatusInfoArray)
return InstructionStateArray;

function findReadyInstructions(livingMask: std_logic_vector; aia: ArgumentStatusInfoArray) 
return std_logic_vector;

function extractReadyRegBits(bits: std_logic_vector; data: InstructionStateArray)
return std_logic_vector;
	
end TEMP_DEV;



package body TEMP_DEV is


function pushToLeft(fullSlots, freedSlots: std_logic_vector) return std_logic_vector is
	variable res: std_logic_vector(fullSlots'range) := (others => '0');
	variable remaining: std_logic_vector(fullSlots'range) := fullSlots and not freedSlots;
	variable k: integer := 0;
begin
	for i in remaining'range loop	
		if remaining(i) = '1' then
			res(k) := '1';
			k := k+1;
		end if;
	end loop;
	return res;
end function;
-----------------------------------------------------------


	function setInstructionTarget(ins: InstructionState; target: Mword) return InstructionState is
		variable res: InstructionState := ins;
	begin
		res.target := target;
		return res;
	end function;


function TEMP_branchPredict(ins: InstructionState) return InstructionState is
	variable res: InstructionState := ins;
begin
	if res.classInfo.branchCond = '1' then
		res.controlInfo.unseen := '1';	
	
		if res.constantArgs.c1 = COND_NONE then -- 'none'; CAREFUL! Use correct codes!
			-- Jump
				res.controlInfo.s0Event := '1';
			res.controlInfo.branchSpeculated := '1'; -- ??
			res.controlInfo.branchConfirmed := '1'; -- ??
		elsif res.constantArgs.c1 = COND_Z and res.virtualArgs.s0 = "00000" then -- 'zero'; CAREFUL! ...
			-- Jump
				res.controlInfo.s0Event := '1';
			res.controlInfo.branchSpeculated := '1'; -- ??
			res.controlInfo.branchConfirmed := '1'; -- ??
		elsif res.constantArgs.c1 = COND_NZ and res.virtualArgs.s0 /= "00000" then -- 'one'; CAREFUL!...
			-- No jump!
		else
			-- Need to speculate...
			-- ! src0 should be register other than r0
			-- Check	if displacement is negative
			--		TODO	
		end if;
	end if;
	
	return res;
end function;



function unit2queue(unit: ExecUnit) return natural is
begin
	return ISSUE_ROUTING_TABLE(unit);
end function;

function findByExecUnit(iv: InstructionStateArray; seeking: ExecUnit) return std_logic_vector is
	variable res: std_logic_vector(iv'range) := (others=>'0');
begin
	for i in iv'range loop
		if iv(i).operation.unit = seeking then
			res(i) := '1';
		end if;
	end loop;
	return res;
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
--------------------------------------
 

	-- CAREFUL! In this version (ci = ai - bi, no negatio on return) "10...0" WILL be after "0...0"!
	--				Generally, "0..01" to "10..0" will be.
	function tagBefore(a, b: SmallNumber) return std_logic is
		variable ai, bi, ci: integer;
		variable c: SmallNumber;
	begin
		ai := slv2u(a);
		bi := slv2u(b);
		ci := ai - bi;
		c := i2slv(ci, SMALL_NUMBER_SIZE);
		return c(c'high);
	end function;

	function findOldestSignal(ready: std_logic_vector; tags: SmallNumberArray) return std_logic_vector is
		variable res: std_logic_vector(ready'range) := (others=>'0');
		variable k: integer := 0;
	begin
		for i in 1 to ready'length-1 loop
			if ready(i) = '1' and tagBefore(tags(i), tags(k)) = '1' then
				k := i;
			end if;
		end loop;
		res(k) := '1';
		return res;
	end function;
	
function selectInstructions(content: InstructionStateArray; numbers: IntArray; nI: integer)
return InstructionStateArray is
	variable res: InstructionStateArray(content'range) := (others=>defaultInstructionState);
	variable ind: integer;
begin
	if nI < 0 or nI > numbers'length or nI > res'length
	then
		return res;
	end if;	
		for i in content'range loop
			if i >= nI or i >= numbers'length then
				exit;
			end if;
				if numbers(i) < 0 or numbers(i) >= content'length then
					return res;
				end if;	
					ind := numbers(i);	
					res(i) := content(ind); -- content(numbers(i));
		end loop;
	return res; 
end function;
	
	
function getArgumentStatusInfo(missing: std_logic_vector;
										 physNames: PhysNameArray;
										 ra: std_logic_vector;
										 tags: PhysNameArray;
										 tagsNext: PhysNameArray;
										 vals: MwordArray)
return ArgumentStatusInfo is
	variable res: ArgumentStatusInfo;
begin
	res.argStored := not missing;

	res.argNew := (others => '0');
	res.locs(0) := (others => '0');
	res.locs(1) := (others => '0');
	res.locs(2) := (others => '0');	
	res.vals(0) := (others => '0');
	res.vals(1) := (others => '0');
	res.vals(2) := (others => '0');
	
	res.argNext := (others => '0');
	res.locsNext(0) := (others => '0');
	res.locsNext(1) := (others => '0');
	res.locsNext(2) := (others => '0');

	-- Find in ready results
	-- Find where tag agrees with s0
	-- TODO: remove the possibility of multiple hits - it must be ensured by register reading part
	--			to prevent reading when arg present in forwarding network;
	--			Maybe also need to build some constraint into comparing logic itself
	for i in tags'range loop -- CAREFUL! Is this loop optimal for muxing?		
		-- CAREFUL! showing only nonzero tags (p0 never needs lookup)
		if isNonzero(tags(i)) = '0' then
			next;
		end if;		
		if tags(i) = physNames(0) then
			res.argNew(0) := '1';
			res.locs(0) := i2slv(i, SMALL_NUMBER_SIZE);
			res.vals(0) := vals(i);
		end if;
		if tags(i) = physNames(1) then
			res.argNew(1) := '1';
			res.locs(1) := i2slv(i, SMALL_NUMBER_SIZE);
			res.vals(1) := vals(i);
		end if;
		if tags(i) = physNames(2) then
			res.argNew(2) := '1';
			res.locs(2) := i2slv(i, SMALL_NUMBER_SIZE);
			res.vals(2) := vals(i);
		end if;
	end loop;
	-- Find what will be available in next cycle
	for i in tagsNext'range loop -- CAREFUL! Is this loop optimal for muxing?		
		-- CAREFUL! showing only nonzero tags (p0 never needs lookup)
		if isNonzero(tagsNext(i)) = '0' then
			next;
		end if;		
		if tagsNext(i) = physNames(0) then
			res.argNext(0) := '1';
			res.locsNext(0) := i2slv(i, SMALL_NUMBER_SIZE);
		end if;
		if tagsNext(i) = physNames(1) then
			res.argNext(1) := '1';
			res.locsNext(1) := i2slv(i, SMALL_NUMBER_SIZE);
		end if;
		if tagsNext(i) = physNames(2) then
			res.argNext(2) := '1';
			res.locsNext(2) := i2slv(i, SMALL_NUMBER_SIZE);
		end if;
	end loop;
	-- What ready in registers
	res.argRegs(0) := ra(slv2u(physNames(0)));
	res.argRegs(1) := ra(slv2u(physNames(1)));
	res.argRegs(2) := ra(slv2u(physNames(2)));	
	
	-- Derived info
	res.readyNow := res.argStored or res.argNew;
	res.readyNext := res.readyNow or res.argNext or res.argRegs; 
	res.notReady := not res.readyNext;

	res.filling := res.argNew and not res.argStored;
	
	res.allReady := res.readyNow(0) and res.readyNow(1) and res.readyNow(2); 
	res.allNext := res.readyNext(0) and res.readyNext(1) and res.readyNext(2);
	return res;
end function;	
	
function getArgumentStatusInfoArray(missing: std_logic_vector;
										 physNames: PhysNameArray;
										 ra: std_logic_vector;
										 tags: PhysNameArray;
										 tagsNext: PhysNameArray;
										 vals: MwordArray)
return ArgumentStatusInfoArray is
	variable res: ArgumentStatusInfoArray(0 to missing'length/3 - 1);
	variable m: std_logic_vector(0 to 2) := "000";
	variable p: PhysNameArray(0 to 2) := (others => (others => '0')); 
begin
	for i in res'range loop
		m := missing(3*i to 3*i + 2);
		p := physNames(3*i to 3*i + 2);
		res(i) := getArgumentStatusInfo(m, p, ra, 
														 tags, tagsNext, vals);
	end loop;
	return res;
end function;	

function updateInstructionArgs(ins: InstructionState; argInfo: ArgumentStatusInfo) return InstructionState
is
	variable res: InstructionState := ins;
begin
	if argInfo.filling(0) = '1' then
		res.argValues.missing(0) := '0';
		res.argValues.arg0 := argInfo.vals(0);
	end if;
	if argInfo.filling(1) = '1' then
		res.argValues.missing(1) := '0';
		res.argValues.arg1 := argInfo.vals(1);
	end if;
	if argInfo.filling(2) = '1' then
		res.argValues.missing(2) := '0';
		res.argValues.arg2 := argInfo.vals(2);
	end if;	
	return res;
end function;
	
function updateInstructionArrayArgs(ia: InstructionStateArray; aia: ArgumentStatusInfoArray)
return InstructionStateArray
is
	variable res: InstructionStateArray(ia'range) := ia;
begin
	for i in ia'range loop
		res(i) := updateInstructionArgs(ia(i), aia(i));
	end loop;
	return res;
end function;

function findReadyInstructions(livingMask: std_logic_vector; aia: ArgumentStatusInfoArray) 
return std_logic_vector is
	variable res: std_logic_vector(livingMask'range) := (others => '0');
begin
	for i in res'range loop
		res(i) := livingMask(i) and aia(i).allNext;
	end loop;
	return res;
end function;

	
function extractReadyRegBits(bits: std_logic_vector; data: InstructionStateArray)
return std_logic_vector is
	variable res: std_logic_vector(0 to 3*data'length-1) := (others => '0'); -- 31) := (others=>'0');
begin
	for i in 0 to data'length-1 loop
		res(3*i + 0) := bits(slv2u(data(i).physicalArgs.s0));
		res(3*i + 1) := bits(slv2u(data(i).physicalArgs.s1));
		res(3*i + 2) := bits(slv2u(data(i).physicalArgs.s2));					
	end loop;		
	return res;
end function;		
	
end TEMP_DEV;
