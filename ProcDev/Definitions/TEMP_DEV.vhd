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

	-- TODO: automatically handle 32/64b config
	function TEMP_addMword(a, b: Mword) return Mword;

	function addMword(a, b: Mword) return Mword;


function setInstructionTarget(ins: InstructionState; target: Mword) return InstructionState;

-- Gives queue number based on functional unit
function unit2queue(unit: ExecUnit) return natural;
function findByExecUnit(iv: InstructionStateArray; seeking: ExecUnit) return std_logic_vector;
function routeToIQ(sd: StageDataMulti; srcVec: std_logic_vector) return StageDataMulti;	

	function routeToIQ2(sd: StageDataMulti; srcVec: std_logic_vector) return StageDataMulti;	
	
	-- Tells if 'a' is older than 'b'
	function tagBefore(a, b: SmallNumber) return std_logic;

function extractReadyRegBits(bits: std_logic_vector; data: InstructionStateArray)
return std_logic_vector;

function extractReadyRegBitsV(bits: std_logic_vector; data: InstructionStateArray)
return std_logic_vector;

-- Next address, even if after a taken branch -- UNUSED
function getIncrementedAddress(ins: InstructionState) return Mword;

function getAddressIncrement(ins: InstructionState) return Mword;

-- What would be next in flow without exceptions - that is next one or jump target 
function getNormalTargetAddress(ins: InstructionState; causingNext: Mword) return Mword;

-- Address to go to if exception happens
function getHandlerAddress(ins: InstructionState) return Mword;

-- Jump target, increment if not jump 
function getLinkInfoNormal(ins: InstructionState; causingNext: Mword) return InstructionBasicInfo;
-- Handler address and system state
function getExceptionTarget(ins: InstructionState; causingNext: Mword) return InstructionBasicInfo;
-- Target, which may be exception handler call
function getLinkInfoSuper(ins: InstructionState; causingNext: Mword) return InstructionBasicInfo;


function clearTempControlInfoSimple(ins: InstructionState) return InstructionState;
function clearTempControlInfoMulti(sd: StageDataMulti) return StageDataMulti;

function setException(ins: InstructionState; intSignal, resetSignal, isNew: std_logic)
return InstructionState;

function isHalt(ins: InstructionState) return std_logic;

function clearEmptyResultTags(insVec: InstructionStateArray; fullMask: std_logic_vector)
return InstructionStateArray;

function trgForBQ(insVec: StageDataMulti) return StageDataMulti;


function findForALU(iv: InstructionStateArray) return std_logic_vector;

function findBranchLink(insv: StageDataMulti) return std_logic_vector;

function whichBranchLink(insv: StageDataMulti) return std_logic_vector;
function setBranchLink(insv: StageDataMulti) return StageDataMulti;

function findStores(insv: StageDataMulti) return std_logic_vector;
function findLoads(insv: StageDataMulti) return std_logic_vector;

end TEMP_DEV;



package body TEMP_DEV is

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

	function setInstructionTarget(ins: InstructionState; target: Mword) return InstructionState is
		variable res: InstructionState := ins;
	begin
		res.target := target;
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
	
		function shiftedIndex(startInd: integer; mask: std_logic_vector) return integer is
			variable res: integer := mask'length-1;
		begin
			for i in startInd to mask'length-2 loop -- ignoring last mask bit, because it's neutral for content
				if mask(i) = '1' then
					res := res - 1;
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

function extractReadyRegBitsV(bits: std_logic_vector; data: InstructionStateArray) return std_logic_vector is
	variable res: std_logic_vector(0 to 3*data'length-1) := (others => '0'); -- 31) := (others=>'0');
begin
	for i in 0 to data'length-1 loop
		res(3*i + 0) := bits(slv2u(data(i).virtualArgs.s0));
		res(3*i + 1) := bits(slv2u(data(i).virtualArgs.s1));
		res(3*i + 2) := bits(slv2u(data(i).virtualArgs.s2));					
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

-- "Normal target" is sequential/branch, without exceptions
function getNormalTargetAddress(ins: InstructionState; causingNext: Mword) return Mword is
begin
	if ins.controlInfo.hasBranch = '1' then
		return ins.target;
	else 
		return --causingNext;
					ins.target; -- CAREFUL: designed to be the same when non-branch!
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
	res.ip := getHandlerAddress(ins);
	res.systemLevel := "00000001";	
	return res;
end function;


function getLinkInfoSuper(ins: InstructionState; causingNext: Mword) return InstructionBasicInfo is
	variable res: InstructionBasicInfo := ins.basicInfo;
begin
	if ins.controlInfo.hasException = '1' then 
		return getExceptionTarget(ins, causingNext);
	-- > NOTE, TODO: Interupt chaining can be implemented in a simple way: when another interrupt appears, 
	--		jump to handler directly from currently running handler, but don't set ILR.
	--		ILR will remain from the first interrupt in chain, just like in tail function call
	else
		return getLinkInfoNormal(ins, causingNext);
	end if;
end function;


function clearTempControlInfoSimple(ins: InstructionState) return InstructionState is
	variable res: InstructionState := ins;
begin
	res.controlInfo.newEvent := '0';
	res.controlInfo.newInterrupt := '0';
	res.controlInfo.newException := '0';
	res.controlInfo.newBranch := '0';
	res.controlInfo.newReturn := '0';
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

	
function setException(ins: InstructionState; intSignal, resetSignal, isNew: std_logic)
return InstructionState is
	variable res: InstructionState := ins;
		variable lateFetchLock: std_logic := '0';
begin
		if LATE_FETCH_LOCK then
			lateFetchLock := '1';
		end if;	
			
	res.controlInfo.newEvent := ((res.controlInfo.hasException 
											or res.controlInfo.specialAction
											--		or (res.controlInfo.hasFetchLock and lateFetchLock)
											)
											and isNew) 
									or intSignal or resetSignal;
	res.controlInfo.hasEvent := res.controlInfo.hasEvent or res.controlInfo.newEvent;

	res.controlInfo.newException := res.controlInfo.hasException and isNew; 

	res.controlInfo.newInterrupt := intSignal;
	res.controlInfo.hasInterrupt := intSignal;
	-- ^ Interrupts delayed by 1 cycle if exception being committed!
	
	res.controlInfo.newReset := resetSignal;
	res.controlInfo.hasReset := resetSignal;
		
	-- ...?	
	return res;
end function;	

function isHalt(ins: InstructionState) return std_logic is
	variable res: std_logic := '0';
begin
	if ins.operation = (System, sysHalt) and ins.controlInfo.hasInterrupt = '0' then 
		res := '1';
	end if;
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



function isolateArgSubset(ins: InstructionState; destSel: std_logic; srcSel: std_logic_vector(0 to 2))
return InstructionState is
	variable res: InstructionState := ins;
begin
	res.virtualDestArgs.sel(0) := res.virtualDestArgs.sel(0) and destSel;
	res.virtualArgs.sel := res.virtualArgs.sel and srcSel;	
	return res;
end function;

	-- float load: dest FP
	-- float store: src(2) FP
	-- float op: all FP
	-- f2i: src FP
	-- i2f: dest FP
	-- others: no FP
	
	-- from the above it seems such possibilities for FP: none, dest, src(2), src, dest & src
	-- More than 4 options, so 3 bits needed. It means [dest, src(2), src(0:1)] are quit independent
	--	and can be explicitly stated separately.
	-- There can be also mem and system signature:
	--	mem dest, mem src(2)
	-- sys dest, sys src(?)
	-- To sum up, there are 7 bits for selection, with by far most combinations illegal.
	-- This doesn't include the int selection! It may have to be introduced.
	
	-- Another distinction is: which cluster it belongs to? 
	--	Int/StoreData/FP
	-- Those clusters seem to approximately mean destination type.
	-- What about branches? They use integer regs, but change program flow instead of writing regs (which 
	--	they can too). So destination could be yet another category (link address delegated to Int cluster
	-- or injected into mem/cross exchange),
	--	with Int sources. But what about system regs? They probably belong to a category
	-- together with branches.
	
	
function trgForBQ(insVec: StageDataMulti) return StageDataMulti is
	variable res: StageDataMulti := insVec;
begin
	for i in 0 to PIPE_WIDTH-1 loop
		res.data(i).argValues.arg1 := res.data(i).target;
	end loop;
	
	return res;
end function;	
	
	
function getStoreAddressPart(ins: InstructionState)
return InstructionState is
	variable res: InstructionState := ins;
	constant srcs: std_logic_vector(0 to 2) := ('1', '1', '0');
begin
	res := isolateArgSubset(res, '1', srcs);
	return res;
end function;

function getLoadAddressPart(ins: InstructionState)
return InstructionState is
	variable res: InstructionState := ins;
	constant srcs: std_logic_vector(0 to 2) := ('1', '1', '0');
begin
	res := isolateArgSubset(res, '0', srcs);
	return res;
end function;

function getStoreDataPart(ins: InstructionState)
return InstructionState is
	variable res: InstructionState := ins;
	constant srcs: std_logic_vector(0 to 2) := ('0', '0', '1');
begin
	res := isolateArgSubset(res, '1', srcs);
	return res;
end function;

function getResultPart(ins: InstructionState)
return InstructionState is
	variable res: InstructionState := ins;
	constant srcs: std_logic_vector(0 to 2) := ('0', '0', '0');
begin
	res := isolateArgSubset(res, '1', srcs);
	return res;
end function;

function getSourcePart(ins: InstructionState)
return InstructionState is
	variable res: InstructionState := ins;
	constant srcs: std_logic_vector(0 to 2) := ('1', '1', '1');
begin
	res := isolateArgSubset(res, '0', srcs);
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
		if insv.data(i).operation = (Memory, store) then
			res(i) := '1';
		end if;
	end loop;
	return res;
end function;

function findLoads(insv: StageDataMulti) return std_logic_vector is
	variable res: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
begin
	for i in 0 to PIPE_WIDTH-1 loop
		if insv.data(i).operation = (Memory, load) then
			res(i) := '1';
		end if;
	end loop;
	return res;
end function;



end TEMP_DEV;

