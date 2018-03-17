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

end TEMP_DEV;



package body TEMP_DEV is

function extractReadyRegBits(bits: std_logic_vector; data: InstructionStateArray) return std_logic_vector is
	variable res: std_logic_vector(0 to 3*data'length-1) := (others => '0'); -- 31) := (others=>'0');
begin
	for i in 0 to data'length-1 loop
		res(3*i + 0) := bits(slv2u(data(i).physicalArgSpec.args(0)));
		res(3*i + 1) := bits(slv2u(data(i).physicalArgSpec.args(1)));
		res(3*i + 2) := bits(slv2u(data(i).physicalArgSpec.args(2)));					
	end loop;		
	return res;
end function;		

function extractReadyRegBitsV(bits: std_logic_vector; data: InstructionStateArray) return std_logic_vector is
	variable res: std_logic_vector(0 to 3*data'length-1) := (others => '0'); -- 31) := (others=>'0');
begin
	for i in 0 to data'length-1 loop
		res(3*i + 0) := bits(slv2u(data(i).virtualArgSpec.args(0)(4 downto 0)));
		res(3*i + 1) := bits(slv2u(data(i).virtualArgSpec.args(1)(4 downto 0)));
		res(3*i + 2) := bits(slv2u(data(i).virtualArgSpec.args(2)(4 downto 0)));
	end loop;		
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
	




end TEMP_DEV;

