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

package ProcBasicDefs is

	-- Typical data sizes
	subtype  byte is std_logic_vector( 7 downto 0);
	subtype hword is std_logic_vector(15 downto 0);
	subtype  word is std_logic_vector(31 downto 0);
	subtype dword is std_logic_vector(63 downto 0);
	subtype qword is std_logic_vector(127 downto 0);
	
	-- Special dataSizes
	subtype slv5  is std_logic_vector(4 downto 0);
	subtype slv6  is std_logic_vector(5 downto 0);
	subtype slv10 is std_logic_vector(9 downto 0);
	subtype slv21 is std_logic_vector(20 downto 0);
	subtype slv26 is std_logic_vector(25 downto 0);	
	
	subtype uint5 is natural range 0 to 31;
	subtype int10 is integer range -512 to 511;
	-- WARNING! When imm16 is unsigned, writing it as bit-equiv signed number is needed!
	subtype int16 is integer range -2**15 to 2**15 - 1;
	subtype int21 is integer range -2**20 to 2**20 - 1;
	subtype int26 is integer range -2**25 to 2**25 - 1; 
	
	type ByteArray is array(integer range <>) of byte;
	type HwordArray is array(integer range <>) of hword;
	type WordArray is array(integer range <>) of word;
	type DwordArray is array(integer range <>) of dword;
	
		type IntArray is array (integer range <>) of integer;
	
	function slv2s(v: std_logic_vector) return integer;
	function slv2u(v: std_logic_vector) return natural;
	function i2slv(val: integer; n: natural) return std_logic_vector;



subtype SmallNumber is byte;
type SmallNumberArray is array(integer range <>) of SmallNumber;
constant SMALL_NUMBER_SIZE: natural := SmallNumber'length;


function addSN(a, b: SmallNumber) return SmallNumber;
function subSN(a, b: SmallNumber) return SmallNumber;

function uminSN(a, b: SmallNumber) return SmallNumber;
function sminSN(a, b: SmallNumber) return SmallNumber;

function cmpLessSignedSN(a, b: SmallNumber) return std_logic;
function cmpGreaterSignedSN(a, b: SmallNumber) return std_logic;
function cmpLessUnsignedSN(a, b: SmallNumber) return std_logic;
function cmpGreaterUnsignedSN(a, b: SmallNumber) return std_logic;

function compareGreaterSNA(inds: SmallNumberArray; num: SmallNumber) return std_logic_vector;
function compareSmallerSNA(inds: SmallNumberArray; num: SmallNumber) return std_logic_vector;
function compareEqualSNA(inds: SmallNumberArray; num: SmallNumber) return std_logic_vector;

end ProcBasicDefs;



package body ProcBasicDefs is

	function slv2s(v: std_logic_vector) return integer is
		variable accum: integer := 0;
		variable bitVal: natural;
	begin
			if v(v'high) = '1' then
				accum := -1;
			else
				accum := 0;
			end if;
		
		for i in v'high-1 downto v'low loop
			if v(i) = '1' then
				bitVal := 1;
			else
				bitVal := 0;
			end if;
			
			accum := 2*accum + bitVal;
		end loop;
		
		return accum;
	end function;
	
	function slv2u(v: std_logic_vector) return natural is
		variable accum: natural := 0;
		variable bitVal: natural;
	begin
		for i in v'high downto v'low loop
			if v(i) = '1' then
				bitVal := 1;
				--report "1!";
			else
				bitVal := 0;
				--report "0!";
			end if;
			
			accum := 2*accum + bitVal;
		end loop;
		
		return accum;
	end function;	

--	function i2slv(val: integer; n: natural) return std_logic_vector is
--		variable num: integer := val;
--		variable v: std_logic_vector(n-1 downto 0);
--		variable res: std_logic_vector(n-1 downto 0);
--		variable bitVal: natural;
--		--variable newBit: std_logic;
--	begin
--			--	report "i 2 vec";
--		
--		for i in 0 to n-1 loop
--			bitVal := num mod 2;
--			num := (num-bitVal)/2;
--			if bitVal = 1 then
--				v(i) := '1'; -- := '1' & v;   report "1";
--			else
--				v(i) := '0'; -- := '0' & v;   report "0";
--			end if;
--		end loop;
--									--	report " ";
--		return v;
--	end function;	

----------------------------------------------------------------------
--  Below: copied from numeric_std!
----------------------------------------------------------------
function TO_UNSIGNED(ARG,SIZE: NATURAL) return std_logic_vector is
  variable RESULT: std_logic_vector (SIZE-1 downto 0) ;
  variable i_val:natural := ARG;
  begin
--  if (SIZE < 1) then return NAU; end if;
  for i in 0 to RESULT'left loop
    if (i_val MOD 2) = 0 then
       RESULT(i) := '0';
    else RESULT(i) := '1' ;
      end if;
    i_val := i_val/2 ;
    end loop;
  if not(i_val=0) then
--    assert NO_WARNING 
--    report "numeric_std.TO_UNSIGNED : vector truncated"
--		severity WARNING ;
    end if;
  return RESULT ;
  end TO_UNSIGNED;

     -- Id: D.4
function TO_SIGNED(ARG: INTEGER; SIZE: NATURAL) return std_logic_vector is
  variable RESULT: std_logic_vector (SIZE-1 downto 0) ;
  variable b_val : STD_LOGIC:= '0' ;
  variable i_val : INTEGER:= ARG ;
  begin
--  if (SIZE < 1) then return NAS; end if;
  if (ARG<0) then
    b_val := '1' ;
    i_val := -(ARG+1) ;
    end if ;
  for i in 0 to RESULT'left loop
    if (i_val MOD 2) = 0 then
      RESULT(i) := b_val;
    else 
      RESULT(i) := not b_val ;
      end if;
    i_val := i_val/2 ;
    end loop;
  if ((i_val/=0) or (b_val/=RESULT(RESULT'left))) then
--    assert NO_WARNING 
--    report "numeric_std.TO_SIGNED : vector truncated"
--    severity WARNING ;
    end if;
  return RESULT;
  end TO_SIGNED;
------------------------------------

	function i2slv(val: integer; n: natural) return std_logic_vector is
		variable num: integer := val;
		variable v: std_logic_vector(n-1 downto 0);
		variable res: std_logic_vector(n-1 downto 0);
		variable bitVal: natural;
		--variable newBit: std_logic;
	begin
			--	report "i 2 vec";
									--	report " ";
		return to_signed(val, n);
	end function;


--------------------


function addSN(a, b: SmallNumber) return SmallNumber is
	variable res: SmallNumber := (others => '0');
	variable rdigit, carry: std_logic := '0';
begin
	for i in 0 to SMALL_NUMBER_SIZE-1 loop
		rdigit := a(i) xor b(i) xor carry;
		carry := (a(i) and b(i)) or (a(i) and carry) or (b(i) and carry);
		res(i) := rdigit;
	end loop;
	return res;
end function;

function subSN(a, b: SmallNumber) return SmallNumber is
	variable res: SmallNumber := (others => '0');
	variable rdigit, carry: std_logic := '0';
begin
	carry := '1';
	for i in 0 to SMALL_NUMBER_SIZE-1 loop
		rdigit := a(i) xor (not b(i)) xor carry;
		carry := (a(i) and not b(i)) or (a(i) and carry) or ((not b(i)) and carry);
		res(i) := rdigit;
	end loop;
	return res;
end function;


function uminSN(a, b: SmallNumber) return SmallNumber is
	variable res: SmallNumber := (others => '0');
	variable rdigit, carry: std_logic := '0';
begin
	res := a;
	for i in SMALL_NUMBER_SIZE-1 downto 0 loop
		if a(i) = '0' and b(i) = '1' then
			res := a;
			exit;
		elsif a(i) = '1' and b(i) = '0' then 
			res := b;
			exit;
		else
			null;
		end if;
	end loop;
	return res;
end function;

function sminSN(a, b: SmallNumber) return SmallNumber is
	variable res: SmallNumber := (others => '0');
	variable rdigit, carry: std_logic := '0';
begin
	res := a;
	if a(SMALL_NUMBER_SIZE-1) = '1' and b(SMALL_NUMBER_SIZE-1) = '0' then
		res := a;
		return res;
	elsif a(SMALL_NUMBER_SIZE-1) = '0' and b(SMALL_NUMBER_SIZE-1) = '1' then
		res := b;
		return res;
	else
		null;
	end if;
	
	for i in SMALL_NUMBER_SIZE-2 downto 0 loop
		if a(i) = '0' and b(i) = '1' then
			res := a;
			exit;
		elsif a(i) = '1' and b(i) = '0' then 
			res := b;
			exit;
		else
			null;
		end if;
	end loop;
	return res;
end function;


function cmpLessSignedSN(a, b: SmallNumber) return std_logic is
begin
		if a(i) = '1' and b(i) = '0' then
			return '1';
		elsif a(i) = '0' and b(i) = '1' then
			return '0';
		end if;		

	for i in 1 to SMALL_NUMBER_SIZE-1 loop
		if a(i) = '0' and b(i) = '1' then
			return '1';
		elsif a(i) = '1' and b(i) = '0' then
			return '0';
		end if;
	end loop;
	return '0';
end function;

function cmpGreaterSignedSN(a, b: SmallNumber) return std_logic is
begin
		if a(i) = '0' and b(i) = '1' then
			return '1';
		elsif a(i) = '1' and b(i) = '0' then
			return '0';
		end if;		

	for i in 1 to SMALL_NUMBER_SIZE-1 loop
		if a(i) = '1' and b(i) = '0' then
			return '1';
		elsif a(i) = '0' and b(i) = '1' then
			return '0';
		end if;
	end loop;
	return '0';
end function;

function cmpLessUnsignedSN(a, b: SmallNumber) return std_logic is
begin
	for i in 0 to SMALL_NUMBER_SIZE-1 loop
		if a(i) = '1' and b(i) = '0' then
			return '0';
		elsif a(i) = '0' and b(i) = '1' then
			return '1';
		end if;
	end loop;
	return '0';
end function;

function cmpGreaterUnsignedSN(a, b: SmallNumber) return std_logic is
begin
	for i in 0 to SMALL_NUMBER_SIZE-1 loop
		if a(i) = '1' and b(i) = '0' then
			return '1';
		elsif a(i) = '0' and b(i) = '1' then
			return '0';
		end if;
	end loop;
	return '0';
end function;



function compareGreaterSNA(inds: SmallNumberArray; num: SmallNumber) return std_logic_vector is
	constant LEN: integer := inds'length;
	variable res: std_logic_vector(0 to LEN-1) := (others => '0');
	variable sn: SmallNumber := (others => '0');
begin
	for i in 0 to LEN-1 loop
		sn := subSN(num, inds(i)); -- If starts with 1, then num is smaller
		res(i) := sn(sn'high);
	end loop;
	return res;
end function;

function compareSmallerSNA(inds: SmallNumberArray; num: SmallNumber) return std_logic_vector is
	constant LEN: integer := inds'length;
	variable res: std_logic_vector(0 to LEN-1) := (others => '0');
	variable sn: SmallNumber := (others => '0');
begin
	for i in 0 to LEN-1 loop
		sn := subSN(inds(i), num); -- If starts with 1, then num is greater
		res(i) := sn(sn'high);
	end loop;
	return res;
end function;

function compareEqualSNA(inds: SmallNumberArray; num: SmallNumber) return std_logic_vector is
	constant LEN: integer := inds'length;
	variable res: std_logic_vector(0 to LEN-1) := (others => '0');
	variable sn: SmallNumber := (others => '0');
begin
	for i in 0 to LEN-1 loop
		if num = inds(i) then
			res(i) := '1';
		else
			res(i) := '0';
		end if;
	end loop;
	return res;
end function;


end ProcBasicDefs;
