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


package Helpers is

function countOnes(vec: std_logic_vector) return natural;
function setToOnes(vec: std_logic_vector; n: natural) return std_logic_vector;

-- Leaves first continuous seq of ones, clears the rest
function firstGroupOfOnes(vec: std_logic_vector) return std_logic_vector;

-- Sets all bits starting from the position of first '1'
function setFromFirstOne(vec: std_logic_vector) return std_logic_vector;
-- Count leading zeroes of course
function clz(vec: std_logic_vector) return natural;
-- Shift left so that all leading zeroes are out
function alignLeft(vec: std_logic_vector) return std_logic_vector;

function findByNumber(numVec: IntArray; seeking: integer) return std_logic_vector;

-- Finding first position of qualified ones
-- Those 2 functions must work together: if returned slv at returned index is '0', then OFC it means "nothing" 
function getFirstOne(readySlots: std_logic_vector) return std_logic_vector;
function getFirstOnePosition(readySlots: std_logic_vector) return natural;

function isNonzero(vec: std_logic_vector) return std_logic;

end Helpers;


package body Helpers is

function countOnes(vec: std_logic_vector) return natural is
	variable sum: natural := 0;
begin
	for i in vec'range loop
		if vec(i) = '1' then
			sum := sum + 1;
		end if;
	end loop;
	return sum;
end function;


function setToOnes(vec: std_logic_vector; n: natural) return std_logic_vector is
	variable res: std_logic_vector(vec'range) := (others=>'0');
	variable b: natural := n;
begin
	if n > vec'length then
		return res;
	end if;
	
	for i in vec'range loop -- 0 to n-1 loop
		if i >= n then
			exit;
		end if;
		res(i) := '1';
	end loop;	
		
	return res;
end function;



function firstGroupOfOnes(vec: std_logic_vector) return std_logic_vector is
	variable res: std_logic_vector(vec'range) := (others=>'0');
	variable beforeOnes: boolean := true;
	variable afterOnes: boolean := false;	
begin
		for i in vec'range loop
			if beforeOnes then
				-- wait until first '1' appears
				if vec(i) = '1' then
								-- CAREFUL! This detail (wantSend instead of conj, just in this expression)
								--				makes the diff from WRONG version 
					beforeOnes := false;
				end if;
			end if;
			-- If we're already inside seq of '1's, go on until they end	
			if not beforeOnes then
				if vec(i) = '0' then
					afterOnes := true;
				end if;
			end if;
			
			-- If it's after the 1st seq of ones, we put zeros; otherwise copy 'conj'
			if afterOnes then
				res(i) := '0';
			else	
				res(i) := vec(i);
			end if;
		end loop;	
	
	return res;
end function;



function setFromFirstOne(vec: std_logic_vector) return std_logic_vector is
	variable res: std_logic_vector(vec'range) := (others=>'0');
	variable beforeOnes: boolean := true;
	--variable afterOnes: boolean := false;	
begin
		for i in vec'range loop
			if beforeOnes then
				-- wait until first '1' appears
				if vec(i) = '1' then
								-- CAREFUL! This detail (wantSend instead of conj, just in this expression)
								--				makes the diff from WRONG version 
					beforeOnes := false;
				end if;
			end if;
			-- If we're already inside seq of '1's, go on until they end	
			if not beforeOnes then
				res(i) := '1';
			end if;
		end loop;	
	
	return res;
end function;


function clz(vec: std_logic_vector) return natural is
	variable res: natural := 0;
begin
	for i in vec'range loop
		if vec(i) = '0' then
			res := res+1;
		else
			exit;
		end if;
	end loop;
	return res;
end function;

function alignLeft(vec: std_logic_vector) return std_logic_vector is
	variable res: std_logic_vector(vec'range) := (others=>'0');
	variable nlz: natural := clz(vec);
begin 
--			report integer'image(nlz);
	for i in vec'left to vec'right - nlz loop
		res(i) := vec(i + nlz);
	end loop;
	return res;
end function;


function findByNumber(numVec: IntArray; seeking: integer) return std_logic_vector is
	variable res: std_logic_vector(numVec'range) := (others=>'0');
begin
	for i in numVec'range loop
		if numVec(i) = seeking then
			res(i) := '1';
		end if;
	end loop;
	return res;
end function;


function getFirstOne(readySlots: std_logic_vector) return std_logic_vector is
	variable res: std_logic_vector(readySlots'range) := (others=>'0');
begin
	for i in readySlots'range loop
		if readySlots(i) = '1' then
			res(i) := '1';
			exit;
		end if;
	end loop;
	return res;
end function;

function getFirstOnePosition(readySlots: std_logic_vector) return natural is
	variable res: natural := 0;
begin
	for i in readySlots'range loop
		if readySlots(i) = '1' then
			res := i;
			exit;
		end if;
	end loop;
	return res;
end function;


function isNonzero(vec: std_logic_vector) return std_logic is
begin
	for i in vec'range loop
		if vec(i) = '1' then
			return '1';
		end if;
	end loop;
	return '0';
end function;

 
end Helpers;
