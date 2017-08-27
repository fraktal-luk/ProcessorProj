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

function setInstructionTarget(ins: InstructionState; target: Mword) return InstructionState;


function extractReadyRegBits(bits: std_logic_vector; data: InstructionStateArray)
return std_logic_vector;

function extractReadyRegBitsV(bits: std_logic_vector; data: InstructionStateArray)
return std_logic_vector;

function getAddressIncrement(ins: InstructionState) return Mword;

-- Jump target, increment if not jump 
function getLinkInfoNormal(ins: InstructionState) return InstructionBasicInfo;
-- Handler address and system state
function getExceptionTarget(ins: InstructionState) return InstructionBasicInfo;
-- Target, which may be exception handler call
function getLinkInfoSuper(ins: InstructionState) return InstructionBasicInfo;


function clearTempControlInfoSimple(ins: InstructionState) return InstructionState;
function clearTempControlInfoMulti(sd: StageDataMulti) return StageDataMulti;

function setPhase(ins: InstructionState;
							 phase0, phase1, phase2: std_logic)
return InstructionState;

function setException2(ins, causing: InstructionState;
							  intSignal, resetSignal, isNew, phase0, phase1, phase2: std_logic)
return InstructionState;

function setLateTargetAndLink(ins: InstructionState; target: Mword; link: Mword; phase1: std_logic)
return InstructionState;


function clearEmptyResultTags(insVec: InstructionStateArray; fullMask: std_logic_vector)
return InstructionStateArray;

function trgForBQ(insVec: StageDataMulti) return StageDataMulti;
function trgToResult(ins: InstructionState) return InstructionState;
function trgToSR(ins: InstructionState) return InstructionState;
function setInsResult(ins: InstructionState; result: Mword) return InstructionState;


function addMwordBasic(a, b: Mword) return Mword;
function subMwordBasic(a, b: Mword) return Mword;

function addMwordExt(a, b: Mword) return std_logic_vector;
function subMwordExt(a, b: Mword) return std_logic_vector;

function addMwordFaster(a, b: Mword) return Mword;

function addMwordFasterExt(a, b: Mword; carryIn: std_logic) return std_logic_vector;


function setInterrupt(ins: InstructionState; int: std_logic) return InstructionState;

end TEMP_DEV;



package body TEMP_DEV is

	function setInstructionTarget(ins: InstructionState; target: Mword) return InstructionState is
		variable res: InstructionState := ins;
	begin
		res.target := target;
		return res;
	end function;

--		WHAT IS THIS?	
--		function shiftedIndex(startInd: integer; mask: std_logic_vector) return integer is
--			variable res: integer := mask'length-1;
--		begin
--			for i in startInd to mask'length-2 loop -- ignoring last mask bit, because it's neutral for content
--				if mask(i) = '1' then
--					res := res - 1;
--				end if;
--			end loop;
--			
--			return res;
--		end function;

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


function getLinkInfoNormal(ins: InstructionState) return InstructionBasicInfo is
	variable res: InstructionBasicInfo := ins.basicInfo;
begin
	res.ip := ins.result;
	return res;
end function;


function getExceptionTarget(ins: InstructionState) return InstructionBasicInfo is
	variable res: InstructionBasicInfo := ins.basicInfo;
begin
	-- get handler adr and system level 
	res.ip := --getHandlerAddress(ins);
			-- TODO, FIX: exceptionCode sliced - shift left by ALIGN_BITS? or leave just base address
		EXC_BASE(MWORD_SIZE-1 downto ins.controlInfo.exceptionCode'length)
	& ins.controlInfo.exceptionCode(ins.controlInfo.exceptionCode'length-1 downto ALIGN_BITS)
	& EXC_BASE(ALIGN_BITS-1 downto 0);		
	
	res.systemLevel := "00000001";	
	return res;
end function;


function getLinkInfoSuper(ins: InstructionState) return InstructionBasicInfo is
	variable res: InstructionBasicInfo := ins.basicInfo;
begin
	if ins.controlInfo.hasException = '1' then 
		return getExceptionTarget(ins);
	-- > NOTE, TODO: Interupt chaining can be implemented in a simple way: when another interrupt appears, 
	--		jump to handler directly from currently running handler, but don't set ILR.
	--		ILR will remain from the first interrupt in chain, just like in tail function call
	else
		return getLinkInfoNormal(ins);
	end if;
end function;


function clearTempControlInfoSimple(ins: InstructionState) return InstructionState is
	variable res: InstructionState := ins;
begin
	res.controlInfo.newEvent := '0';
	--res.controlInfo.newInterrupt := '0';
	--res.controlInfo.newException := '0';
	res.controlInfo.newBranch := '0';
	--res.controlInfo.newReturn := '0';
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

	
function setPhase(ins: InstructionState;
							 phase0, phase1, phase2: std_logic)
return InstructionState is
	variable res: InstructionState := ins;
begin	
	res.controlInfo.phase0 := phase0;
	res.controlInfo.phase1 := phase1;
	res.controlInfo.phase2 := phase2;
	return res;
end function;	


function setException2(ins, causing: InstructionState;
							  intSignal, resetSignal, isNew, phase0, phase1, phase2: std_logic)
return InstructionState is
	variable res: InstructionState := ins;
begin
	res.controlInfo.newEvent := ((res.controlInfo.hasException 
											or res.controlInfo.specialAction
											)
											and isNew) 
									or intSignal or resetSignal;

	res.controlInfo.hasInterrupt := res.controlInfo.hasInterrupt or intSignal;
	-- ^ Interrupts delayed by 1 cycle if exception being committed!
	
	res.controlInfo.hasReset := resetSignal;
		
	if phase1 = '1' then
			res.result := res.target;
		--res.target := causing.target;
	end if;
	
	if phase2 = '1' then
		res.controlInfo.newEvent := '0';	

			res.controlInfo.hasException := '0';
			res.controlInfo.hasInterrupt := '0';
			res.controlInfo.hasReset := '0';
			--res.controlInfo.hasEvent := '0';	
			res.controlInfo.specialAction := '0';			
	end if;
	
	return res;
end function;

function setLateTargetAndLink(ins: InstructionState; target: Mword; link: Mword; phase1: std_logic)
return InstructionState is
	variable res: InstructionState := ins;
begin

	if phase1 = '1' then
		res.result := link;
		res.target := target;
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
	
		
		function trgToResult(ins: InstructionState) return InstructionState is
			variable res: InstructionState := ins;
		begin
			-- CAREFUL! Here we use 'result' because it is the field copied to arg1 in mem queue!
			-- TODO: regularize usage of such fields, maybe remove 'target' from InstructionState?
			res.result := ins.target;
			return res;
		end function;
		
		function trgToSR(ins: InstructionState) return InstructionState is
			variable res: InstructionState := ins;
		begin
			-- CAREFUL! Here we use 'result' because it is the field copied to arg1 in mem queue!
			-- TODO: regularize usage of such fields, maybe remove 'target' from InstructionState?
			res.argValues.arg2(4 downto 0) := ins.constantArgs.c0;
			res.argValues.arg2(MWORD_SIZE-1 downto 5) := (others => '0');
			return res;
		end function;

		function setInsResult(ins: InstructionState; result: Mword) return InstructionState is
			variable res: InstructionState := ins;
		begin
			res.result := result;
			return res;
		end function;


--	
--function getStoreAddressPart(ins: InstructionState)
--return InstructionState is
--	variable res: InstructionState := ins;
--	constant srcs: std_logic_vector(0 to 2) := ('1', '1', '0');
--begin
--	res := isolateArgSubset(res, '1', srcs);
--	return res;
--end function;
--
--function getLoadAddressPart(ins: InstructionState)
--return InstructionState is
--	variable res: InstructionState := ins;
--	constant srcs: std_logic_vector(0 to 2) := ('1', '1', '0');
--begin
--	res := isolateArgSubset(res, '0', srcs);
--	return res;
--end function;
--
--function getStoreDataPart(ins: InstructionState)
--return InstructionState is
--	variable res: InstructionState := ins;
--	constant srcs: std_logic_vector(0 to 2) := ('0', '0', '1');
--begin
--	res := isolateArgSubset(res, '1', srcs);
--	return res;
--end function;
--
--function getResultPart(ins: InstructionState)
--return InstructionState is
--	variable res: InstructionState := ins;
--	constant srcs: std_logic_vector(0 to 2) := ('0', '0', '0');
--begin
--	res := isolateArgSubset(res, '1', srcs);
--	return res;
--end function;
--
--function getSourcePart(ins: InstructionState)
--return InstructionState is
--	variable res: InstructionState := ins;
--	constant srcs: std_logic_vector(0 to 2) := ('1', '1', '1');
--begin
--	res := isolateArgSubset(res, '0', srcs);
--	return res;
--end function;



function addMwordBasic(a, b: Mword) return Mword is
	variable res: Mword := (others => '0');
	variable rdigit, carry: std_logic := '0';
begin
	for i in 0 to MWORD_SIZE-1 loop
		rdigit := a(i) xor b(i) xor carry;
		carry := (a(i) and b(i)) or (a(i) and carry) or (b(i) and carry);
		res(i) := rdigit;
	end loop;
	return res;
end function;

function subMwordBasic(a, b: Mword) return Mword is
	variable res: Mword := (others => '0');
	variable rdigit, carry: std_logic := '0';
begin
	carry := '1';
	for i in 0 to MWORD_SIZE-1 loop
		rdigit := a(i) xor (not b(i)) xor carry;
		carry := (a(i) and not b(i)) or (a(i) and carry) or ((not b(i)) and carry);
		res(i) := rdigit;
	end loop;
	return res;
end function;

function addMwordExt(a, b: Mword) return std_logic_vector is
	variable res: std_logic_vector(MWORD_SIZE downto 0) := (others => '0');
	variable rdigit, carry: std_logic := '0';
begin
	for i in 0 to MWORD_SIZE-1 loop
		rdigit := a(i) xor b(i) xor carry;
		carry := (a(i) and b(i)) or (a(i) and carry) or (b(i) and carry);
		res(i) := rdigit;
	end loop;
	res(MWORD_SIZE) := carry;
	
	return res;
end function;

function subMwordExt(a, b: Mword) return std_logic_vector is
	variable res: std_logic_vector(MWORD_SIZE downto 0) := (others => '0');
	variable rdigit, carry: std_logic := '0';
begin
	carry := '1';
	for i in 0 to MWORD_SIZE-1 loop
		rdigit := a(i) xor (not b(i)) xor carry;
		carry := (a(i) and not b(i)) or (a(i) and carry) or ((not b(i)) and carry);
		res(i) := rdigit;
	end loop;
	res(MWORD_SIZE) := carry;
	
	return res;
end function;


	-- CAREFUL: assuming SMALL_NUMBER_SIZE = 8
	function addExt8(a, b: SmallNumber; cIn: std_logic) return std_logic_vector is
		variable res: std_logic_vector(8 downto 0) := (others => '0');
		variable rdigit, carry: std_logic := '0';
	begin
		carry := cIn;
		for i in 0 to 8-1 loop
			rdigit := a(i) xor b(i) xor carry;
			carry := (a(i) and b(i)) or (a(i) and carry) or (b(i) and carry);
			res(i) := rdigit;
		end loop;
		res(8) := carry;	
		return res;
	end function;


function addMwordFasterExt(a, b: Mword; carryIn: std_logic) return std_logic_vector is
	variable res: std_logic_vector(32 downto 0) := (others => '0'); -- CAREFUL, TODO: 32b only!
	variable rdigit, carry: std_logic := '0';
	variable partial0N, partial1N, partial2N, partial3N, partial0C, partial1C, partial2C, partial3C:
		std_logic_vector(8 downto 0) := (others => '0');
	variable c7, c15, c23, c31: std_logic := '0';	
begin
	-- Carry select, for 32b

	partial0N := addExt8(a(7 downto 0), b(7 downto 0), carryIn);
	partial0C := addExt8(a(7 downto 0), b(7 downto 0), '1');
	partial1N := addExt8(a(15 downto 8), b(15 downto 8), '0');
	partial1C := addExt8(a(15 downto 8), b(15 downto 8), '1');
	partial2N := addExt8(a(23 downto 16), b(23 downto 16), '0');
	partial2C := addExt8(a(23 downto 16), b(23 downto 16), '1');
	partial3N := addExt8(a(31 downto 24), b(31 downto 24), '0');
	partial3C := addExt8(a(31 downto 24), b(31 downto 24), '1');

	-- Carry chain, selection
	c7 := partial0N(8);
	c15 := partial1N(8) or (partial1C(8) and c7);
	c23 := partial2N(8) or (partial2C(8) and c15);
	c31 := partial3N(8) or (partial3C(8) and c23);
	
	if c23 = '1' then
		res(31 downto 24) := partial3C(7 downto 0);
	else
		res(31 downto 24) := partial3N(7 downto 0);		
	end if;

	if c15 = '1' then
		res(23 downto 16) := partial2C(7 downto 0);
	else
		res(23 downto 16) := partial2N(7 downto 0);		
	end if;
	
	if c7 = '1' then
		res(15 downto 8) := partial1C(7 downto 0);
	else
		res(15 downto 8) := partial1N(7 downto 0);		
	end if;	

	--if c23 = '1' then
		res(7 downto 0) := partial0N(7 downto 0);
	--else
	--	res(31 downto 24) := partial3N(7 downto 0);		
	--end if;
	res(32) := c31;
	
	return res;
end function;


function addMwordFaster(a, b: Mword) return Mword is
	variable res: Mword := (others => '0');
	variable rdigit, carry: std_logic := '0';
	variable partial0N, partial1N, partial2N, partial3N, partial0C, partial1C, partial2C, partial3C:
		std_logic_vector(8 downto 0) := (others => '0');
	variable c7, c15, c23, c31: std_logic := '0';	
begin
	-- Carry select, for 32b

	partial0N := addExt8(a(7 downto 0), b(7 downto 0), '0');
	partial0C := addExt8(a(7 downto 0), b(7 downto 0), '1');
	partial1N := addExt8(a(15 downto 8), b(15 downto 8), '0');
	partial1C := addExt8(a(15 downto 8), b(15 downto 8), '1');
	partial2N := addExt8(a(23 downto 16), b(23 downto 16), '0');
	partial2C := addExt8(a(23 downto 16), b(23 downto 16), '1');
	partial3N := addExt8(a(31 downto 24), b(31 downto 24), '0');
	partial3C := addExt8(a(31 downto 24), b(31 downto 24), '1');

	-- Carry chain, selection
	c7 := partial0N(8);
	c15 := partial1N(8) or (partial1C(8) and c7);
	c23 := partial2N(8) or (partial2C(8) and c15);
	c31 := partial3N(8) or (partial3C(8) and c23);
	
	if c23 = '1' then
		res(31 downto 24) := partial3C(7 downto 0);
	else
		res(31 downto 24) := partial3N(7 downto 0);		
	end if;

	if c15 = '1' then
		res(23 downto 16) := partial2C(7 downto 0);
	else
		res(23 downto 16) := partial2N(7 downto 0);		
	end if;
	
	if c7 = '1' then
		res(15 downto 8) := partial1C(7 downto 0);
	else
		res(15 downto 8) := partial1N(7 downto 0);		
	end if;	

	--if c23 = '1' then
		res(7 downto 0) := partial0N(7 downto 0);
	--else
	--	res(31 downto 24) := partial3N(7 downto 0);		
	--end if;
	
	return res;
end function;


function setInterrupt(ins: InstructionState; int: std_logic) return InstructionState is
	variable res: InstructionState := ins;
begin
	res.controlInfo.hasInterrupt := int;
	return res;
end function;

end TEMP_DEV;

