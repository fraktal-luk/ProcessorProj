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

  --use work.ProcGeneral.all; 
  
	use work.ProcBasicDefs.all;
--	use work.ProcInstructions.all;

package Arithmetic is
	
	-- Logical ops are built-in 
	
	-- signExtend(a: std_logic_vector, n: integer);
	-- zeroExtend(a: std_logic_vector, n: integer);
	
	--function addWord(a: word; b: word) return word;
	--function subWord(a: word; b: word) return word;
	--function addDword(a: dword; b: dword) return dword;
	--function subDword(a: dword; b: dword) return dword;
	--function shiftLogicalWord(a: word; sh: integer) return word;
	--function shiftArithmeticWord(a: word; sh: integer) return word;

	-- function compareUnsigned(
	-- function compareSigned(

	function multUnsigned(a: word; b: word) return dword;
	function multSigned(a: word; b: word) return dword;

	function divUnsigned(a: word; b: word) return word;
--	function divSigned(a: word; b: word) return word;

end Arithmetic;



package body Arithmetic is

	-- This is unsigned!
	function multUnsigned(a: word; b: word) return dword is
		variable res: dword := (others => '0');
		
		variable b0, b1, b2, b3: integer;
		variable h0, h1: integer;
		variable t0, t1, t2, t3, t4, t5, t6, t7: integer;
	begin
		h1 := slv2u(a(31 downto 16));
		h0 := slv2u(a(15 downto 0));
		
		b3 := slv2u(b(31 downto 24));
		b2 := slv2u(b(23 downto 16));
		b1 := slv2u(b(15 downto 8));
		b0 := slv2u(b(7 downto 0));
		
		t0 := h0 * b0; -- e0B
		t1 := h0 * b1; -- e1B
		t2 := h0 * b2; -- e2B
		t3 := h0 * b3; -- e3B
	
		t4 := h1 * b0; -- e2B
		t5 := h1 * b1; -- e3B
		t6 := h1 * b2; -- e4B
		t7 := h1 * b3; -- e5B 
		
--		report "temps:";
--		report integer'image(t0);
--		report integer'image(t1);
--		report integer'image(t2);
--		report integer'image(t3);
--		report integer'image(t4);
--		report integer'image(t5);
--		report integer'image(t6);
--		report integer'image(t7);
		
		
		res(31 downto 0) := i2slv(t0, 32);
		res(39 downto 8) := i2slv(slv2u(res(39 downto 8)) + t1, 32);
		res(47 downto 16) := i2slv(slv2u(res(47 downto 16)) + t2, 32);
		res(47 downto 16) := i2slv(slv2u(res(47 downto 16)) + t4, 32);
		res(55 downto 24) := i2slv(slv2u(res(55 downto 24)) + t3, 32);
		res(55 downto 24) := i2slv(slv2u(res(55 downto 24)) + t5, 32);		
		res(63 downto 32) := i2slv(slv2u(res(63 downto 32)) + t6, 32);		
		res(63 downto 40) := i2slv(slv2u(res(63 downto 40)) + t7, 24);		
		
		
		return res;
	end function;




	function multSigned(a: word; b: word) return dword is
		variable res: dword := (others => '0');
		
		variable b0, b1, b2, b3: integer;
		variable h0, h1: integer;
		variable t0, t1, t2, t3, t4, t5, t6, t7: integer;
	begin
		h1 := slv2s(a(31 downto 16));
		h0 := slv2u(a(15 downto 0)); -- This has to be 0 extended probably!
		
		b3 := slv2s(b(31 downto 24));
		b2 := slv2u(b(23 downto 16)); -- Here bytes 0-2 also need to be 0 extended, not sign extended
		b1 := slv2u(b(15 downto 8));
		b0 := slv2u(b(7 downto 0));
		
		t0 := h0 * b0; -- e0B
		t1 := h0 * b1; -- e1B
		t2 := h0 * b2; -- e2B
		t3 := h0 * b3; -- e3B
	
		t4 := h1 * b0; -- e2B
		t5 := h1 * b1; -- e3B
		t6 := h1 * b2; -- e4B
		t7 := h1 * b3; -- e5B 
		
--		report "temps:";
--		report integer'image(t0);
--		report integer'image(t1);
--		report integer'image(t2);
--		report integer'image(t3);
--		report integer'image(t4);
--		report integer'image(t5);
--		report integer'image(t6);
--		report integer'image(t7);
		
		
		res(31 downto 0) := i2slv(t0, 32);
		res(63 downto 32) := (others => res(31));
		
		res(39 downto 8) := i2slv(slv2s(res(39 downto 8)) + t1, 32);
		res(63 downto 40) := (others => res(39));
		
		res(47 downto 16) := i2slv(slv2s(res(47 downto 16)) + t2, 32);
		res(63 downto 48) := (others => res(47));
		
		res(47 downto 16) := i2slv(slv2s(res(47 downto 16)) + t4, 32);
		res(63 downto 48) := (others => res(47));
		
		res(55 downto 24) := i2slv(slv2s(res(55 downto 24)) + t3, 32);
		res(63 downto 56) := (others => res(55));
		
		res(55 downto 24) := i2slv(slv2s(res(55 downto 24)) + t5, 32);	
		res(63 downto 56) := (others => res(55));
		
		res(63 downto 32) := i2slv(slv2s(res(63 downto 32)) + t6, 32);	
		
		res(63 downto 40) := i2slv(slv2s(res(63 downto 40)) + t7, 24);		
		
		
		return res;
	end function;
 
-- 
	function divUnsigned(a: word; b: word) return word is
		variable aCopy: word := a;
		variable res: word := (others => '0');
		variable posA, posB: integer;
		variable nBits: natural;
		variable bS: word;
		variable sh: integer;
		variable tempDword: dword; 
		
		variable ia, ib: integer;
	begin
--	
--			return res;
----		
		-- Handle cases of 0
		if slv2u(b) = 0 then
			report "Division by 0!" severity warning;
			return (others=>'U');
		elsif slv2u(a) = 0 then
			if slv2u(b) = 0 then
				report "Dividing 0 by 0!" severity warning;
				return (others=>'U');
			else
				return (others=>'0');
			end if;
		end if;
--		
		-- Normal cases
		-- Find 1st '1' in a
		posA := -1;
		for i in 31 downto 0 loop
			if a(i) = '1' then
				posA := i;
				exit;
			end if;	
		end loop;
	
		-- Find 1st '1' in b
		posB := -1;
		for i in 31 downto 0 loop
			if b(i) = '1' then
				posB := i;
				exit;
			end if;	
		end loop;		
	
		if posB > posA then
			return (others=>'0');
		end if;
--		
		-- Shift B to match the leading 0 count
		sh := posA - posB;
		tempDword := (others => '0');
		tempDword(31+sh downto sh) := b;
		
		bS := tempDword(31 downto 0);
		
		-- Start calculating bits
		nBits := sh + 1;
				--report "n bits:";
				--report integer'image(nBits);
				--report "......";
		for i in 0 to nBits-1 loop
			ia := slv2u(aCopy);
			ib := slv2u(bS);
			
			if ib > ia then
				-- new bit = 0
				res(nBits-1-i) := '0';
								--report "0";
			else
				-- new bit = 1
				res(nBits-1-i) := '1';
								--report "1";

				aCopy := i2slv(ia - ib, 32);
			end if;
			-- shift right
			bS := '0' & bS(31 downto 1);
		end loop;
--		
--		
		return res;
	end function;
--	
--	
--	function divSigned(a: word; b: word) return word is
--	begin
--		-- TEMP: get absolute values and signs	
--		
--  	-- sgA := 
--		-- sgB :=
--		aAbs :=
--		bAbs := 
--
--	end function;
 
end Arithmetic;
