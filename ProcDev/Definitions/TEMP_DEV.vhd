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

function extractReadyRegBits(bits: std_logic_vector; data: InstructionStateArray)
return std_logic_vector;

function extractReadyRegBitsV(bits: std_logic_vector; data: InstructionStateArray)
return std_logic_vector;

-- UNUSED
function clearEmptyResultTags(insVec: InstructionStateArray; fullMask: std_logic_vector)
return InstructionStateArray;

-- For partition into different clusters: int, FP, mem
function isolateArgSubset(ins: InstructionState; destSel: std_logic; srcSel: std_logic_vector(0 to 2))
return InstructionState;

-- Description: arg1 := target
function trgForBQ(insVec: StageDataMulti) return StageDataMulti;


-- TODO: should be moved somewhere else, but depends on Mword definition.
--			Because Mword is device specific, these functions must be redone as abstractions of addWord...
function addMwordBasic(a, b: Mword) return Mword;
function subMwordBasic(a, b: Mword) return Mword;

function addMwordExt(a, b: Mword) return std_logic_vector;
function subMwordExt(a, b: Mword) return std_logic_vector;

function addMwordFaster(a, b: Mword) return Mword;

function addMwordFasterExt(a, b: Mword; carryIn: std_logic) return std_logic_vector;

end TEMP_DEV;



package body TEMP_DEV is

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

end TEMP_DEV;

