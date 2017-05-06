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
	fullMask: std_logic_vector(0 to HBUFFER_SIZE-1);
		cmpMask: std_logic_vector(0 to HBUFFER_SIZE-1);
	nFullV: SmallNumber;
end record;

constant DEFAULT_HBUFF_QUEUE_DATA: HbuffQueueData := (
		contentT => (others => DEFAULT_INSTRUCTION_STATE),
	content => (others => DEFAULT_INSTRUCTION_STATE),
	fullMask => (others => '0'),
		cmpMask => (others => '0'),	
	nFullV => (others => '0')
);


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

-- nIn indicates number of full positions, aligned to right (for jump to not-beginning of block)
-- CAREFUL: The start IP in bock can be encoded in the IP of element (0)?
function TEMP_movingQueue_q16_i8_o8(buffIn: HbuffQueueData;
												input: InstructionStateArray;
												nFullV, nInV, nOutV: SmallNumber; killAll: std_logic;
												startIP: Mword)
return HbuffQueueData is
	constant qin: InstructionStateArray(0 to HBUFFER_SIZE-1) := buffIn.content;
	constant maskIn: std_logic_vector(0 to HBUFFER_SIZE-1) := buffIn.fullMask;
	constant QLEN: integer := qin'length; -- Must be 16
	constant ILEN: integer := input'length; -- must be 8
	variable res: HbuffQueueData := DEFAULT_HBUFF_QUEUE_DATA;
	
	-- Extended: aditional 8 elements, filled with the last in queue; for convenience
	variable qinExt: InstructionStateArray(0 to HBUFFER_SIZE + 8 - 1) := 
																(others => qin(HBUFFER_SIZE-1));
	variable inputExt: InstructionStateArray(0 to ILEN + 4 - 1) := 
																(others => input(ILEN-1));
	
	variable resContent: InstructionStateArray(0 to QLEN-1) := (others => DEFAULT_INSTRUCTION_STATE);
	variable resContentT: InstructionStateArray(0 to QLEN-1) := (others => DEFAULT_INSTRUCTION_STATE);
	variable resMask, resMaskT: std_logic_vector(0 to QLEN-1) := (others => '0');
	
	variable nFull, nIn, nOut: integer := 0;
	variable nRem, nOff, nOffMR, nFullNew: integer := 0;
	variable s0, s1, s2, s3, sT: std_logic_vector(1 downto 0) := "00";
	variable v0, v1, v2, v3, vT: InstructionStateArray(0 to 3) := (others => DEFAULT_INSTRUCTION_STATE);
	
	variable iMod: integer := 0;
begin
	nFull := binFlowNum(nFullV);
	nIn := binFlowNum(nInV);
	nOut := binFlowNum(nOutV);	

	nOff := ILEN - nIn; -- TODO: It will be gathered from low bits of IP of fetched block!
	nRem := nFull - nOut;
	nOffMR := nOff - nRem;
	nFullNew := nRem + nIn;
	if killAll = '1' then
		nFullNew := 0;
	end if;

	inputExt(0 to ILEN-1) := input;
	qinExt(0 to HBUFFER_SIZE-1) := qin;

	resContent := qin;
	resContentT := qin;
	
		report   integer'image(nOut) & "<<" & integer'image(nFull) & "<<"
				&	integer'image(nIn);
		report  "nRem: " & integer'image(nRem) & ", nOffMR: " & integer'image(nOffMR);
	
	
	-- For each index in queue we have to find a set of functions:
	-- from set {queue(0 to MAX_OUT-1), input} find selection and CLK_EN
	-- {sel(i), cken(i)} = f(i, nFull, nIn, nOut)
	-- where sel is 4b
	for i in 0 to QLEN-1 loop
				--report "Iter " & integer'image(i);
			
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
		
		iMod := i mod 4;
		
		v0 := qinExt(i+1 to i+4);
		v1 := qinExt(i+5 to i+8);
		v2 := inputExt(iMod+0 to iMod+3);
		v3 := inputExt(iMod+4 to iMod+7);
		
		s0 := i2slv(nOut-1, 2);
		s1 := s0;
		s2 := i2slv(nOffMR, 2);
		s3 := s2;

		if i < nRem then
			if nOut <= 4 then
				sT := "00";
					--	report "A";
			else
				sT := "01";
					--	report "B";
			end if;	
		else	
			if nOffMR < 4 - i then
				sT := "10";
					--	report "C";
			else
				sT := "11";
					--	report "D";
			end if;
		end if;
		
		-- This condition generates clock enable
		-- CAREFUL: nOut 
		if	nOut /= 0 or i >= nRem then --  nRem can be replaced with nFull
			resContentT(i) := selectIns4x4(v0, v1, v2, v3, 
													s0, s1, s2, s3,
													sT);
		end if;										 
		
		-- Fill reference queue
		if i < nRem then -- from queue
			if i + nOut < QLEN then
				resContent(i) := qin(i + nOut);
			else
				-- ??
			end if;
		else -- from input
			if i + nOffMR < ILEN then
				resContent(i) := input(i + nOffMR);
			else
				-- ??
			end if;
		end if;
		
		-- Fill reference mask
		if i < nFullNew then
			resMask(i) := '1';
		end if;
		
			if resMask(i) = '1' and resContent(i) /= resContentT(i) then
				--report "ohno!";
				res.cmpMask(i) := '1';				
			end if;
		
	end loop;
	
		res.contentT := resContentT;
	res.content := resContentT;
	res.fullMask := resMask;
	res.nFullV := i2slv(nFullNew, SMALL_NUMBER_SIZE);
	
	return res;
end function;


end Queues;



package body Queues is


end Queues;
