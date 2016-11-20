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

-- Gives queue number based on functional unit
function unit2queue(unit: ExecUnit) return natural;
function findByExecUnit(iv: InstructionStateArray; seeking: ExecUnit) return std_logic_vector;
function routeToIQ(sd: StageDataMulti; srcVec: std_logic_vector) return StageDataMulti;	
	
	-- Tells if 'a' is older than 'b'
	function tagBefore(a, b: SmallNumber) return std_logic;
	
	-- To determine which subpipe result directs control flow
	function findOldestSignal(ready: std_logic_vector; tags: SmallNumberArray) return std_logic_vector;
		
-- General, UNUSED?
function selectInstructions(content: InstructionStateArray; numbers: IntArray; nI: integer)
return InstructionStateArray;


function extractReadyRegBits(bits: std_logic_vector; data: InstructionStateArray)
return std_logic_vector;

-- Next address, even if after a taken branch
function getIncrementedAddress(ins: InstructionState) return Mword;

function getAddressIncrement(ins: InstructionState) return Mword;

-- What would be next in flow without exceptions - that is next one or jump target 
function getNormalTargetAddress(ins: InstructionState; causingNext: Mword) return Mword;

-- Address to go to if exception happens
function getHandlerAddress(ins: InstructionState) return Mword;

-- Instruction to be executed next in absence of interrupts: whether next, jump target or exc handler
function getSuperTargetAddress(ins: InstructionState; causingNext: Mword)--; elr: Mword)
return Mword;

-- Incremented address
function getLinkInfoLinear(ins: InstructionState; causingNext: Mword) return InstructionBasicInfo;
-- Jump target, increment if not jumo 
function getLinkInfoNormal(ins: InstructionState; causingNext: Mword) return InstructionBasicInfo;
-- Handler address and system state
function getExceptionTarget(ins: InstructionState; causingNext: Mword) return InstructionBasicInfo;
-- Target, which may be exception handler call
function getLinkInfoSuper(ins: InstructionState; --linkInfoExc: InstructionBasicInfo;
								causingNext: Mword)
return InstructionBasicInfo;

function pcDataFromBasicInfo(bi: InstructionBasicInfo) return InstructionState;

function clearTempControlInfoSimple(ins: InstructionState) return InstructionState;
function clearTempControlInfoMulti(sd: StageDataMulti) return StageDataMulti;

function setInterrupt(ins: InstructionState; intSignal: std_logic; intCode: SmallNumber)
return InstructionState;

	
function extractPhysSources(data: InstructionStateArray) return PhysNameArray;

function extractPhysS0(data: InstructionStateArray) return PhysNameArray;
function extractPhysS1(data: InstructionStateArray) return PhysNameArray;
function extractPhysS2(data: InstructionStateArray) return PhysNameArray;

function extractMissing(data: InstructionStateArray) return std_logic_vector;		

function extractMissing0(data: InstructionStateArray) return std_logic_vector;		
function extractMissing1(data: InstructionStateArray) return std_logic_vector;		
function extractMissing2(data: InstructionStateArray) return std_logic_vector;		

function clearEmptyResultTags(insVec: InstructionStateArray; fullMask: std_logic_vector)
return InstructionStateArray;

	-- TODO: automatically handle 32/64b config
	function TEMP_addMword(a, b: Mword) return Mword;

	function addMword(a, b: Mword) return Mword;

	function addWordE(a, b: word) return std_logic_vector;
	function addWord(a, b: word) return word;
	function addDword(a, b: dword) return dword;

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
	
	
function extractReadyRegBits(bits: std_logic_vector; data: InstructionStateArray) return std_logic_vector is
	variable res: std_logic_vector(0 to 3*data'length-1) := (others => '0'); -- 31) := (others=>'0');
begin
	for i in 0 to data'length-1 loop
		res(3*i + 0) := bits(slv2u(data(i).physicalArgs.s0));
		res(3*i + 1) := bits(slv2u(data(i).physicalArgs.s1));
		res(3*i + 2) := bits(slv2u(data(i).physicalArgs.s2));					
	end loop;		
	return res;
end function;		


function getIncrementedAddress(ins: InstructionState) return Mword is
	variable nBytes: natural;
begin
	-- TODO: when short instructions introduced, differentiate into 2B and 4B 
	if false then -- For short ones
		nBytes := 2;			
	else
		nBytes := 4;
	end if;	
	--return i2slv( slv2s(ins.basicInfo.ip) + nBytes, MWORD_SIZE);
	return addMword(ins.basicInfo.ip, getAddressIncrement(ins));
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


-- CAREFUL:
-- 		When committing a write to system reg, if it's the status reg, it must be incorporated
--			into target. It means that PC value for fetching must be updated with the status reg new value,
--			and if interrupt comes after that, the savedStateInt also must include the written change!
--			It seems that PC basicInfo must be constantly mapped from statusReg: it thus becomes a physical
--			register valid for instructions to be fetched. If so, writing to it obviously must prevent
--			any instruction from being fetched before the change is committed. Or otherwise it would be allowed
--			normally, with an exception occuring in writing makes younger ops in the pipeline invalid,
--			but this would be very complex.
function getNormalTargetAddress(ins: InstructionState; causingNext: Mword) return Mword is
begin
	if ins.controlInfo.hasBranch = '1' then
		return ins.target;
	else 
		return causingNext;
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


function getSuperTargetAddress(ins: InstructionState; causingNext: Mword) return Mword is	
begin
	if ins.controlInfo.newException = '1' then 
		return getHandlerAddress(ins);
	else
		return getNormalTargetAddress(ins, causingNext);
	end if;
end function;


function getLinkInfoLinear(ins: InstructionState; causingNext: Mword) return InstructionBasicInfo is
	variable res: InstructionBasicInfo := ins.basicInfo;
begin
	res.ip := causingNext;
	return res;
end function;

function getLinkInfoNormal(ins: InstructionState; causingNext: Mword) return InstructionBasicInfo is
	variable res: InstructionBasicInfo := ins.basicInfo;
begin
	-- get next adr considering possible jump 
	res.ip := getNormalTargetAddress(ins, causingNext);
	return res;
end function;


function getExceptionTarget(ins: InstructionState; causingNext: Mword) return InstructionBasicInfo is
	variable res: InstructionBasicInfo := ins.basicInfo;
begin
	-- get handler adr and system level 
	res.ip := --getNormalTargetAddress(ins, causingNext); -- CAREFUL: Looks like error?
				  getHandlerAddress(ins);
	res.systemLevel := "00000001";	
	return res;
end function;


function getLinkInfoSuper(ins: InstructionState; causingNext: Mword) return InstructionBasicInfo is
	variable res: InstructionBasicInfo := ins.basicInfo;
begin
	if ins.controlInfo.newException = '1' then 
		return getExceptionTarget(ins, causingNext);
	-- > NOTE, TODO: Interupt chaining can be implemented in a simple way: when another interrupt appears, 
	--		jump to handler directly from currently running handler, but don't set ILR.
	--		ILR will remain from the first interrupt in chain, just like in tail function call
	else
		return getLinkInfoNormal(ins, causingNext);
	end if;
end function;


function pcDataFromBasicInfo(bi: InstructionBasicInfo) return InstructionState is
	variable res: InstructionState := DEFAULT_DATA_PC;
begin
	res.basicInfo := bi;
	--res.pc := bi.ip;
	--res.pcBase := bi.ip(MWORD_SIZE-1 downto ALIGN_BITS)	& i2slv(0, ALIGN_BITS);
	--res.nH := i2slv(FETCH_BLOCK_SIZE - (slv2u(bi.ip(ALIGN_BITS-1 downto 1))), SMALL_NUMBER_SIZE);
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
	--res.controlInfo.newIntReturn := '0';
	--res.controlInfo.newExcReturn := '0';
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
	
function extractPhysSources(data: InstructionStateArray) return PhysNameArray is
	variable res: PhysNameArray(0 to 3*data'length-1) := (others => (others => '0'));
begin
	for i in data'range loop
		res(3*i + 0) := data(i).physicalArgs.s0;
		res(3*i + 1) := data(i).physicalArgs.s1;
		res(3*i + 2) := data(i).physicalArgs.s2;		
	end loop;
	return res;
end function;	
	
function extractPhysS0(data: InstructionStateArray) return PhysNameArray is
	variable res: PhysNameArray(0 to data'length-1) := (others => (others => '0'));
begin
	for i in data'range loop
		res(i) := data(i).physicalArgs.s0;		
	end loop;
	return res;
end function;		

function extractPhysS1(data: InstructionStateArray) return PhysNameArray is
	variable res: PhysNameArray(0 to data'length-1) := (others => (others => '0'));
begin
	for i in data'range loop
		res(i) := data(i).physicalArgs.s1;		
	end loop;
	return res;
end function;		

function extractPhysS2(data: InstructionStateArray) return PhysNameArray is
	variable res: PhysNameArray(0 to data'length-1) := (others => (others => '0'));
begin
	for i in data'range loop
		res(i) := data(i).physicalArgs.s2;		
	end loop;
	return res;
end function;		


	
function extractMissing(data: InstructionStateArray) return std_logic_vector is
	variable res: std_logic_vector(0 to 3*data'length-1) := (others => '0');
begin
	for i in data'range loop
		res(3*i + 0) := data(i).argValues.missing(0);
		res(3*i + 1) := data(i).argValues.missing(1);
		res(3*i + 2) := data(i).argValues.missing(2);		
	end loop;
	return res;
end function;	

function extractMissing0(data: InstructionStateArray) return std_logic_vector is
	variable res: std_logic_vector(0 to data'length-1) := (others => '0');
begin
	for i in data'range loop
		res(i) := data(i).argValues.missing(0);
	end loop;
	return res;
end function;

function extractMissing1(data: InstructionStateArray) return std_logic_vector is
	variable res: std_logic_vector(0 to data'length-1) := (others => '0');
begin
	for i in data'range loop
		res(i) := data(i).argValues.missing(1);
	end loop;
	return res;
end function;
	
function extractMissing2(data: InstructionStateArray) return std_logic_vector is
	variable res: std_logic_vector(0 to data'length-1) := (others => '0');
begin
	for i in data'range loop
		res(i) := data(i).argValues.missing(2);
	end loop;
	return res;
end function;


function clearEmptyResultTags(insVec: InstructionStateArray; fullMask: std_logic_vector)
return InstructionStateArray is
	variable res: InstructionStateArray(0 to insVec'length-1) := insVec;
begin
	for i in 0 to PIPE_WIDTH-1 loop
		if fullMask(i) = '0' then
			res(i).physicalDestArgs.d0 := (others => '0');
		end if;
	end loop;
	return res;
end function;


		function TEMP_addMword(a, b: Mword) return Mword is
			variable res: Mword := (others => '0');
			variable al, ah, bl, bh, cl, ch: integer := 0;
			variable ta, tb: hword := (others => '0'); 
		begin
			ta := a(31 downto 16);
			ah := slv2u(ta);
			al := slv2u(a(15 downto 0));
			tb := b(31 downto 16);
			bh := slv2u(tb);
			bl := slv2u(b(15 downto 0));
			
			cl := bl + al;
			ch := ah + bh;
			
			if cl >= 2**16 then
				ch := ch + 1;
			end if;
			
			res(31 downto 16) := i2slv(ch, 16);
			res(15 downto 0) := i2slv(cl, 16);			
			return res;
		end function;

		function addMword(a, b: Mword) return Mword is
		begin
			-- TODO: handle 64b config
			return addWord(a, b);
		end function;		

		function addWordE(a, b: word) return std_logic_vector is
			variable res: std_logic_vector(32 downto 0) := (others => '0');
			variable al, ah, bl, bh, cl, ch: integer := 0;
			variable ta, tb: hword := (others => '0'); 
		begin
			ta := a(31 downto 16);
			ah := slv2u(ta);
			al := slv2u(a(15 downto 0));
			tb := b(31 downto 16);
			bh := slv2u(tb);
			bl := slv2u(b(15 downto 0));
			
			cl := bl + al;
			ch := ah + bh;
			
			if cl >= 2**16 then
				ch := ch + 1;
			end if;
			
			res(31 downto 16) := i2slv(ch, 16);
			res(15 downto 0) := i2slv(cl, 16);

			if ch >= 2**16 then
				res(32) := '1';
			end if;
			
			return res;
		end function;


		function addWord(a, b: word) return word is
			variable res: word := (others => '0');
			variable tmp: std_logic_vector(32 downto 0) := (others => '0');
		begin
			tmp := addWordE(a, b);
			res := tmp(31 downto 0); 
			return res;
		end function;

		function addDword(a, b: dword) return dword is
			variable res: dword := (others => '0');
			variable tmp: std_logic_vector(32 downto 0) := (others => '0');
			variable aw, bw, cw: word := (others => '0');
		begin
			tmp := addWordE(a(31 downto 0), b(31 downto 0));
			res(32 downto 0) := tmp; -- Includes carry form lower word! 
			cw := res(63 downto 32);
			aw := a(63 downto 32);
			bw := b(63 downto 32);
			tmp := addWordE(aw, bw);
			res(63 downto 32) := addWord(tmp(31 downto 0), cw);
			return res;
		end function;

end TEMP_DEV;
