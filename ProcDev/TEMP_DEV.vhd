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

-- Next address, even if after a taken branch
function getNextInstructionAddress(ins: InstructionState) return Mword;

function getAddressIncrement(ins: InstructionState) return Mword;

-- What would be next in flow without exceptions - that is next one or jump target 
function getSucceedingInstructionAddress(ins: InstructionState; causingNext: Mword) return Mword;

-- Address to go to if exception happens
function getHandlerAddress(ins: InstructionState) return Mword;

-- Instruction to be executed next in absence of interrupts: whether next, jump target or exc handler
function getSyncFlowInstructionAddress(ins: InstructionState; causingNext: Mword; elr: Mword)
return Mword;

function getLinkInfoN(ins: InstructionState; causingNext: Mword) return InstructionBasicInfo;
function getLinkInfoJ(ins: InstructionState; causingNext: Mword) return InstructionBasicInfo;
function getExceptionTarget(ins: InstructionState; causingNext: Mword) return InstructionBasicInfo;
function getLinkInfoE(ins: InstructionState; linkInfoExc: InstructionBasicInfo; causingNext: Mword)
return InstructionBasicInfo;

function pcDataFromBasicInfo(bi: InstructionBasicInfo) return stageDataPC;

function clearTempControlInfoSimple(ins: InstructionState) return InstructionState;
function clearTempControlInfoMulti(sd: StageDataMulti) return StageDataMulti;

function setInterrupt(ins: InstructionState; intSignal: std_logic; intCode: SmallNumber)
return InstructionState;

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
		--res.controlInfo.unseen := '1';	
	
		if res.constantArgs.c1 = COND_NONE then -- 'none'; CAREFUL! Use correct codes!
			-- Jump
				--res.controlInfo.s0Event := '1';
			--res.controlInfo.branchSpeculated := '1'; -- ??
			--res.controlInfo.branchConfirmed := '1'; -- ??
		elsif res.constantArgs.c1 = COND_Z and res.virtualArgs.s0 = "00000" then -- 'zero'; CAREFUL! ...
			-- Jump
				--res.controlInfo.s0Event := '1';
			--res.controlInfo.branchSpeculated := '1'; -- ??
			--res.controlInfo.branchConfirmed := '1'; -- ??
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


function getNextInstructionAddress(ins: InstructionState) return Mword is
	variable nBytes: natural;
begin
	-- TODO: when short instructions introduced, differentiate into 2B and 4B 
	if false then -- For short ones
		nBytes := 2;			
	else
		nBytes := 4;
	end if;	
	return i2slv( slv2s(ins.basicInfo.ip) + nBytes, MWORD_SIZE);
end function;

function getAddressIncrement(ins: InstructionState) return Mword is
	variable res: Mword := (others => '0');
begin
	-- TODO: short instructions...
	if false then
		res(1) := '1'; -- 2
	else
		res(2) := '1'; -- 4
	end if;
	return res;
end function;


-- TODO: handle the situation of exception returns!
-- 		Also when committing a write to system reg, if it's the status reg, it must be incorporated
--			into target. It means that PC value for fetching must be updated with the status reg new value,
--			and if interrupt comes after that, the savedStateInt also must include the written change!
--			It seems that PC basicInfo must be constantly mapped from statusReg: it thus becomes a physical
--			register valid for instructions to be fetched. If so, writing to it obviously must prevent
--			any instruction from being fetched before the change is committed. Or otherwise it would be allowed
--			normally, with an exception occuring in writing makes younger ops in the pipeline invalid,
--			but this would be very complex.
function getSucceedingInstructionAddress(ins: InstructionState; causingNext: Mword) return Mword is
begin
	if ins.controlInfo.hasBranch = '1' then
		return ins.target;
	else 
		return --getNextInstructionAddress(ins);
				 causingNext;
	end if;
end function;

function getHandlerAddress(ins: InstructionState) return Mword is
begin
			-- TODO, FIX: exceptionCode sliced - shift left by ALIGN_BITS? or leave just base address
			return EXC_BASE(MWORD_SIZE-1 downto ins.controlInfo.exceptionCode'length)
									& ins.controlInfo.exceptionCode(
															ins.controlInfo.exceptionCode'length-1 downto ALIGN_BITS)
									& EXC_BASE(ALIGN_BITS-1 downto 0);			
			--res.basicInfo.systemLevel := "00000001";
end function;

function getSyncFlowInstructionAddress(ins: InstructionState; causingNext: Mword; elr: Mword)
return Mword is
	
begin
	if ins.controlInfo.newException = '1' then 
		return getHandlerAddress(ins);
	elsif ins.controlInfo.newExcReturn = '1' then
		return elr;
	else
		return getSucceedingInstructionAddress(ins, causingNext);
	end if;
end function;


function getLinkInfoN(ins: InstructionState; causingNext: Mword) return InstructionBasicInfo is
	variable res: InstructionBasicInfo := ins.basicInfo;
begin
	res.ip := --getNextInstructionAddress(ins);
					causingNext;
	return res;
end function;

function getLinkInfoJ(ins: InstructionState; causingNext: Mword) return InstructionBasicInfo is
	variable res: InstructionBasicInfo := ins.basicInfo;
begin
	-- get next adr considering possible jump 
	res.ip := getSucceedingInstructionAddress(ins, causingNext);
	-- CAREFUL! Probably undefined or sth if the instruction were to be exc return or int return
	--				(such things shoudn't happen probably)
	return res;
end function;


function getExceptionTarget(ins: InstructionState; causingNext: Mword) return InstructionBasicInfo is
	variable res: InstructionBasicInfo := ins.basicInfo;
begin
	-- get handler adr and system level 
	res.ip := getSucceedingInstructionAddress(ins, causingNext);
	res.systemLevel := "00000001";	
	return res;
end function;


function getLinkInfoE(ins: InstructionState; linkInfoExc: InstructionBasicInfo; causingNext: Mword)
return InstructionBasicInfo is
	variable res: InstructionBasicInfo := ins.basicInfo;
begin
	
	if ins.controlInfo.newException = '1' then 
		return getExceptionTarget(ins, causingNext);
	elsif ins.controlInfo.newExcReturn = '1' then	
		-- CAREFUL! when we have interrupt on returning from sync exception
		-- 			And if int/excReturn instructions are disabled, this should be too!
		return linkInfoExc;	

	-- CAREFUL! If interupt happens on returning from interrupt, we'd have problems probably.		
--			-- ?? Enable interrupt chaining by reusing linkInfoInt?	
--			elsif ins.controlInfo.intRet = '1' then	
--				return linkInfoInt;
	-- > Interupt chaining can be implemented in a simple way: when another interrupt appears, 
	--		jump to handler directly from currently running handler, but don't set ILR.
	--		ILR will remain from the first interrupt in chain, just like in tail function call

	else
		return getLinkInfoJ(ins, causingNext);
	end if;
end function;


function pcDataFromBasicInfo(bi: InstructionBasicInfo) return stageDataPC is
	variable res: StageDataPC := DEFAULT_DATA_PC;
begin
	res.basicInfo := bi;
	res.pc := bi.ip;
	res.pcBase := bi.ip(MWORD_SIZE-1 downto ALIGN_BITS)	& i2slv(0, ALIGN_BITS);
	res.nH := i2slv(FETCH_BLOCK_SIZE - (slv2u(bi.ip(ALIGN_BITS-1 downto 1))), SMALL_NUMBER_SIZE);
	
	return res;
end function;


function clearTempControlInfoSimple(ins: InstructionState) return InstructionState is
	variable res: InstructionState := ins;
begin
	res.controlInfo.newEvent := '0';
	res.controlInfo.newInterrupt := '0';
	res.controlInfo.newException := '0';
	res.controlInfo.newBranch := '0';
	res.controlInfo.newReturn := '0';
	res.controlInfo.newIntReturn := '0';
	res.controlInfo.newExcReturn := '0';
	res.controlInfo.newFetchLock := '0';	
	return res;
end function;

function clearTempControlInfoMulti(sd: StageDataMulti) return StageDataMulti is
	variable res: StageDataMulti := sd;
begin
	for i in res.fullMask'range loop
		res.data(i) := clearTempControlInfoSimple(res.data(i));
	end loop;
	return res;
end function;


	-- to integrate interrupt signal into instruction where it is injected
	function setInterrupt(ins: InstructionState; intSignal: std_logic; intCode: SmallNumber)
	return InstructionState is
		variable res: InstructionState := ins;
	begin
		res.controlInfo.newEvent := intSignal;
		res.controlInfo.hasEvent := intSignal;
		res.controlInfo.newInterrupt := intSignal;
		res.controlInfo.hasInterrupt := intSignal;
		-- ...?	
		return res;
	end function;	

end TEMP_DEV;
