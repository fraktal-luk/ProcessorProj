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

use work.NewPipelineData.all;

use work.TEMP_DEV.all;
use work.GeneralPipeDev.all;


package Queues is

type HbuffQueueData is record
		contentT: InstructionStateArray(0 to HBUFFER_SIZE-1);
	content: InstructionStateArray(0 to HBUFFER_SIZE-1);
		fullMaskT: std_logic_vector(0 to HBUFFER_SIZE-1);
	fullMask: std_logic_vector(0 to HBUFFER_SIZE-1);
		cmpMask: std_logic_vector(0 to HBUFFER_SIZE-1);
	nFullV: SmallNumber;
end record;

constant DEFAULT_HBUFF_QUEUE_DATA: HbuffQueueData := (
		contentT => (others => DEFAULT_INSTRUCTION_STATE),
	content => (others => DEFAULT_INSTRUCTION_STATE),
		fullMaskT => (others => '0'),	
	fullMask => (others => '0'),
		cmpMask => (others => '0'),	
	nFullV => (others => '0')
);


constant IGNORE_CMP_NB: boolean := true;--false;

function getCNB(nbi: integer) return integer is
begin
	if IGNORE_CMP_NB then
		return 8;
	else
		return nbi;
	end if;
end function;

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

function lessThan(v: SmallNumber; ref: integer; nbi: integer) return std_logic is
	variable nb: integer := getCNB(nbi);
	variable res: std_logic := '0';
	variable table: std_logic_vector(0 to 2**nb-1) := (others => '0');
	
	variable vv, rv: std_logic_vector(nb-1 downto 0) := (others => '0');
begin
	assert nb < 9 report "Dont use so large numbers!" severity failure;

	rv := i2slv(ref, nb); 
	vv := v(nb-1 downto 0);

	-- Generate truth table 
	for i in 0 to 2**nb-1 loop
		if i < ref then
			table(i) := '1';
		else
			table(i) := '0';
		end if;
	end loop;
	
	res := table(slv2u(vv));
	
	return res;
end function;

function greaterThan(v: SmallNumber; ref: integer; nbi: integer) return std_logic is
	variable nb: integer := getCNB(nbi);
	variable res: std_logic := '0';
	variable table: std_logic_vector(0 to 2**nb-1) := (others => '0');
	
	variable vv, rv: std_logic_vector(nb-1 downto 0) := (others => '0');
begin
	assert nb < 9 report "Dont use so large numbers!" severity failure;

	rv := i2slv(ref, nb); 
	vv := v(nb-1 downto 0);

	-- Generate truth table 
	for i in 0 to 2**nb-1 loop
		if i > ref then
			table(i) := '1';
		else
			table(i) := '0';
		end if;
	end loop;
	
	res := table(slv2u(vv));
	
	return res;
end function;

function lessThanSigned(v: SmallNumber; ref: integer; nbi: integer) return std_logic is
	variable nb: integer := getCNB(nbi);
	variable res: std_logic := '0';
	variable table: std_logic_vector(0 to 2**nb-1) := (others => '0');
	
	variable vv, rv: std_logic_vector(nb-1 downto 0) := (others => '0');
	
begin
	assert nb < 9 report "Dont use so large numbers!" severity failure;

	rv := i2slv(ref, nb); 
	vv := v(nb-1 downto 0);

	-- Generate truth table 
	for i in 0 to 2**nb-1 loop
		if i - 2**(nb-1) < ref then
			table(i) := '1';
		else
			table(i) := '0';
		end if;
	end loop;
	
	res := table(slv2s(vv) + 2**(nb-1));
	
	return res;
end function;



function selectIns4(v0: InstructionStateArray(0 to 3);
						  s0: std_logic_vector(1 downto 0))
						  return InstructionState is
	variable res: InstructionState := DEFAULT_INSTRUCTION_STATE;
begin
	case s0 is
		when "00" => 
			res := v0(0);
		when "01" => 
			res := v0(1);
		when "10" =>
			res := v0(2);
		when others =>
			res := v0(3);
	end case;
	
	return res;
end function;
						  

function selectIns4x4(v0, v1, v2, v3: InstructionStateArray(0 to 3);
							 s0, s1, s2, s3: std_logic_vector(1 downto 0); -- select (for each subvec)
							 sT: std_logic_vector(1 downto 0)) -- select top
							 return InstructionState is
	variable res: InstructionState := DEFAULT_INSTRUCTION_STATE;
	variable t0, t1, t2, t3: InstructionState := DEFAULT_INSTRUCTION_STATE;
	variable tVec: InstructionStateArray(0 to 3) := (others => DEFAULT_INSTRUCTION_STATE);
begin
	t0 := selectIns4(v0, s0);
	t1 := selectIns4(v1, s1);
	t2 := selectIns4(v2, s2);
	t3 := selectIns4(v3, s3);
	
	tVec := (t0, t1, t2, t3);
	res := selectIns4(tVec, sT);
	
	return res;
end function;							 


function selectQueueNext(queueList: InstructionStateArray; queueIndex: SmallNumber; condQueueHigh: std_logic;
								 inputList: InstructionStateArray; inputIndex: SmallNumber; condInputHigh: std_logic;
								 condChooseInput: std_logic) return InstructionState is
	variable res: InstructionState := DEFAULT_INSTRUCTION_STATE;

	variable s0, s1, s2, s3, sT: std_logic_vector(1 downto 0) := "00";
	variable v0, v1, v2, v3, vT: InstructionStateArray(0 to 3) := (others => DEFAULT_INSTRUCTION_STATE);
begin		
				-- Subdivision of lists for 4-to-1 muxes
				v0 := queueList(0 to 3);
				v1 := queueList(4 to 7);
				v2 := inputList(0 to 3);
				v3 := inputList(4 to 7);
					
				-- Selection variables for submuxes
				s0 := queueIndex(1 downto 0);
				s1 := s0;
				s2 := inputIndex(1 downto 0);
				s3 := s2;

				-- Selection var for top level mux				
				if condChooseInput = '0' then
					sT(1) := '0';
					sT(0) := condQueueHigh;
				else
					sT(1) := '1';
					sT(0) := condInputHigh;
				end if;
				
				res := selectIns4x4(v0, v1, v2, v3, 		s0, s1, s2, s3,		sT);
	return res;
end function;


-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
	--	Algorithm for moving a queue with max input 8 and max output 8
	--	

	-- For each index in queue we have to find a set of functions:
	-- from set {queue(0 to MAX_OUT-1), input} find selection and CLK_EN
	-- {sel(i), cken(i)} = f(i, nFull, nIn, nOut)
	-- where sel is 4b
		-- q(0) can be updated from q(1..8) or from input(0..7) etc
		
		-- nFull[5], nIn[4], nOut[4]  -> 13 bits!
		-- But can be reduced because some combinations are exclusive: if we have nFull=16, nIn=0 etc
		
		-- Another constraint if no limitations of decode due to instruction type:
		-- 	when nFull <= 4 we send all or nothing because 4 instrucitons out must
		--		have at least 4 hwords. So 3 bits are enough: |{000, 100, 101, 110, 111, 1000}| == 6
		--															000,  	100, 101, 110, 111, (1000 -> 0xx; 011 ??)
		-- But when such restrictions exist, all in 0..8 can occur.
		
		-- For (nFull-nOut) differing by 4, first level selection is the same (in groups of 4),
		--		and only second level selection (which group of 4) is different
		
		-- Formula for CKEN:
		--	  When nOut /= 0: everything moves	
		--	  When nOut = 0 : only those not full  
		--   So formula would be:
		--		CKEN <- (nOut /= 0) or i >= nFull  ??
		--										   ^ can be substituted to i >= nRem (because it's cae for nOut = 0)!
		--				This will cause writing to elems beyond the new size - uneeded 
		--			So we can change the second part to:
		--			...or (i >= nRem && i < nRem + 8)  ??
		--		And whar about new fullMask? Is the mask needed at all?
		--
		-- Formulas for selection:
		--			nRem = nFull-nOut
		--			offset = 8-nIn
		--		i < nRem: take from queue
		--		i >= nRem: take from input
		--	 Higher level selection:	-------------------
		--		(i<nRem) : take from queue	
		--			A.	nOut <= 4 : take from first "4" after "i" in queue
		--			B.	nOut > 4  : take from second "4" after "i" in queue
		--		(i>=nRem) : take from input
		--			C.	(i-nRem+offset) < 4 : take from first "4" of input
		--			D.	(i-nRem+offset) >= 4: take from second "4" of input
		--  Lower level selection: -----------
		--		A) q(i) <- q(i + nOut)
		--		B) q(i) <- q(i + nOut)  // == i + 4 + (nOut-4), or (nOut mod 4)
		--		C) q(i) <- in(i - nRem + offset)
		--		D) q(i) <- in(i - nRem + offset) // == (i + 4) + (- nRem + offset - 4)
		--	 Bit widths:
		--		A) nOut[1:0] // CAREFUL! Indexing form 1, not 0 because nOut==0 is not moving
		--		B) nOut[1:0] //
		--		C) nOffMR[1:0] // This time from 0; nOffMR := offset - nRem
		--		D) nOffMR[1:0]
-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------



-- nIn indicates number of full positions, aligned to right (for jump to not-beginning of block)
-- CAREFUL: The start IP in bock can be encoded in the IP of element (0)?
function TEMP_movingQueue_q16_i8_o8(buffIn: HbuffQueueData;
												input: InstructionStateArray;
												nFullV, nInV, nOutV: SmallNumber; killAll: std_logic;
												startIP: Mword)
return HbuffQueueData is
	constant qin: InstructionStateArray(0 to HBUFFER_SIZE-1) := buffIn.content;
	constant QLEN: integer := qin'length;
	constant ILEN: integer := input'length; -- max 8
	variable res: HbuffQueueData := DEFAULT_HBUFF_QUEUE_DATA;
	
	-- Extended: aditional 8 elements, filled with the last in queue; for convenience
	variable qinExt: InstructionStateArray(0 to HBUFFER_SIZE + 8 - 1) := (others => qin(HBUFFER_SIZE-1));
	variable inputExt: InstructionStateArray(0 to ILEN + 4 - 1) := (others => input(ILEN-1));
	
		variable queueList: InstructionStateArray(0 to 7) := (others => DEFAULT_INSTRUCTION_STATE);
		variable inputList: InstructionStateArray(0 to 7) := (others => DEFAULT_INSTRUCTION_STATE);		
	
	variable resContentT: InstructionStateArray(0 to QLEN-1) := (others => DEFAULT_INSTRUCTION_STATE);
	variable resMask, resMaskT: std_logic_vector(0 to QLEN-1) := (others => '0');
	
	variable nRemV, nOffV, nOffMRV, nFullNewV, nOutM1V: SmallNumber := (others => '0');
	variable queueIndex, inputIndex: SmallNumber := (others => '0');
	
		variable tempInstructionState: InstructionState := DEFAULT_INSTRUCTION_STATE;
	
	variable iMod: integer := 0;
		variable cond0, condChooseInput, condQueueHigh, condInputHigh: std_logic := '0';
begin
			nOffV(ALIGN_BITS-2 downto 0) := startIP(ALIGN_BITS-1 downto 1);
			nRemV := subSN(nFullV, nOutV);
			nOffMRV := subSN(nOffV, nRemV);
			
			if killAll = '1' then
				nFullNewV := (others => '0');
			else
				nFullNewV := addSN(nRemV, nInV);			
			end if;

			nOutM1V := subSN(nOutV, X"01");


	inputExt(0 to ILEN-1) := input;
	qinExt(0 to HBUFFER_SIZE-1) := qin;
	resContentT := qin;

	-- For each index in queue we have to find a set of functions:
	-- from set {queue(0 to MAX_OUT-1), input} find selection and CLK_EN
	-- {sel(i), cken(i)} = f(i, nFull, nIn, nOut)
	-- where sel is 4b
	for i in 0 to QLEN-1 loop		
		iMod := i mod 4;
		
		-- Now prepare 2 lists of elements to select - 1 from queue content, another form input
			queueList := qinExt(i+1 to i+8);
			inputList := inputExt(iMod+0 to iMod+7);

			queueIndex := nOutM1V;
			inputIndex := nOffMRV;

			-- CONDITION: cond0 := (nRem > i) -- !! 5b - 1b						
			cond0 := greaterThan(nRemV, i, 5);		
			condChooseInput := not cond0;
				
			condQueueHigh := greaterThan(nOutV, 4, 4);
									--greaterThan(nOutM1V, 3, 4)
			condInputHigh := not lessThanSigned(nOffMRV, 4-i, 6);

			-- Internal handling of partition and muxing:
			tempInstructionState := selectQueueNext(queueList, queueIndex, condQueueHigh,
																 inputList, inputIndex, condInputHigh,
																 condChooseInput);
		-- This condition generates clock enable
		-- CAREFUL: nOut /= 0 could be equiv to nextAccepting?
		--				nextAccepting will differ from nOut /= 0 when nFull = 0, but in this case
		--				the second part of condition is true everywhere, so the substitution seems valid!
		-- CONDITION:(nOut /= 0 or nRem <= i) --  nRem can be replaced with nFull
		if	(nOutV(3 downto 0) & cond0) /= "00001" then		 
			resContentT(i) := tempInstructionState;
		end if;										 

		-- Fill implementation mask
		-- CONDITION = (nFullNew > i)
		resMaskT(i) := greaterThan(nFullNewV, i, 5);
	end loop;

	res.content := resContentT;
	res.fullMask := resMaskT;
	res.nFullV := nFullNewV;
	
	return res;
end function;


-- nIn indicates number of full positions, aligned to right (for jump to not-beginning of block)
-- CAREFUL: The start IP in bock can be encoded in the IP of element (0)?
function TEMP_movingQueue_q16_i8_o8_Ref(buffIn: HbuffQueueData;
												input: InstructionStateArray;
												nFullV, nInV, nOutV: SmallNumber; killAll: std_logic;
												startIP: Mword)
return HbuffQueueData is
	constant qin: InstructionStateArray(0 to HBUFFER_SIZE-1) := buffIn.content;
	constant QLEN: integer := qin'length;
	constant ILEN: integer := input'length; -- max 8
	variable res: HbuffQueueData := DEFAULT_HBUFF_QUEUE_DATA;

	variable resContent: InstructionStateArray(0 to QLEN-1) := (others => DEFAULT_INSTRUCTION_STATE);
	variable resMask, resMaskT: std_logic_vector(0 to QLEN-1) := (others => '0');
	
	variable nFull, nIn, nOut: integer := 0;
	variable nRem, nOff, nOffMR, nFullNew: integer := 0;
begin
	resContent := qin;

	nFull := binFlowNum(nFullV);
	nIn := binFlowNum(nInV);
	nOut := binFlowNum(nOutV);	

	nOff := (ILEN - nIn) mod 8; -- TODO: It will be gathered from low bits of IP of fetched block?
	nRem := nFull - nOut;
	nOffMR := nOff - nRem;
	nFullNew := nRem + nIn;
	if killAll = '1' then
		nFullNew := 0;
	end if;

	for i in 0 to QLEN-1 loop
		-- Fill reference queue
		if i < nRem then -- from queue
			if i + nOut < QLEN then
				resContent(i) := qin(i + nOut);
			end if;
		else -- from input
			if i + nOffMR < ILEN then
				resContent(i) := input(i + nOffMR);
			end if;
		end if;
		
			-- Fill reference mask
			if i < nFullNew then -- !! Make new condition for resMaskT. 5b -> 1b (each i) 
				resMask(i) := '1';
			end if;
	end loop;
	
	res.content := resContent;
	res.fullMask := resMask;
	res.nFullV := i2slv(nFullNew, SMALL_NUMBER_SIZE);
	
	return res;
end function;


end Queues;



package body Queues is


end Queues;
