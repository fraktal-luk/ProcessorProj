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
	content: InstructionStateArray(0 to HBUFFER_SIZE-1);
	fullMask: std_logic_vector(0 to HBUFFER_SIZE-1);
	nFullV: SmallNumber;
end record;

constant DEFAULT_HBUFF_QUEUE_DATA: HbuffQueueData := (
	content => (others => DEFAULT_INSTRUCTION_STATE),
	fullMask => (others => '0'),
	nFullV => (others => '0')
);


type TMP_queueState is record
	pStart: SmallNumber;
	pEnd: SmallNumber;
	nFull: SmallNumber;
end record;

-- Methods for the type:
-- getWindow (for all useful windows)
-- take -> just moving pointers?
-- put ->  ^^
-- compare pointers, move ptrs, etc? -- or is it just the question of proper arithmetic?
-- "normalize" from circular to fixed front?
-- > we need to check if operations are correct: not overflowing, not underflowing etc

function TMP_defaultQueueState return TMP_queueState is
	variable res: TMP_queueState;
begin
	res.pStart := (others => '0');
	res.pEnd := (others => '0');
	res.nFull := (others => '0');
	return res;
end function;


function smallNum(n: integer) return SmallNumber is
begin
	return i2slv(n, SMALL_NUMBER_SIZE);
end function;


function rotateMask(mask: std_logic_vector; n: integer) return std_logic_vector is
	constant LEN: integer := mask'length;
	variable res: std_logic_vector(0 to LEN-1) := (others => '0');
begin
	for j in 0 to LEN-1 loop
		res(j) := mask((j - n) mod LEN);
	end loop;
	return res;
end function;

function rotateInsArray(arr: InstructionStateArray; n: integer) return InstructionStateArray is
	constant LEN: integer := arr'length;
	variable res: InstructionStateArray(0 to LEN-1) := (others => DEFAULT_INSTRUCTION_STATE);
begin
	for j in 0 to LEN-1 loop
		res(j) := arr((j - n) mod LEN);
	end loop;
	return res;
end function;

-- Changes circular queue to its image with begining at 0
function normalizeMask(qs: TMP_queueState; mask: std_logic_vector) return std_logic_vector is
begin
	return rotateMask(mask, -slv2u(qs.pStart));
end function;

function normalizeInsArray(qs: TMP_queueState; arr: InstructionStateArray) return InstructionStateArray is
begin
	return rotateInsArray(arr, -slv2u(qs.pStart));
end function;

			-- UNUSED so far, also dilemma what to do when all zeros
			-- find position of first '1' if it exists
			function findQueueIndex(mask: std_logic_vector) return SmallNumber is
				variable res: SmallNumber := (others => '0');
			begin
				for i in 0 to mask'length-1 loop
					if mask(i) = '1' then
						return smallNum(i);
					end if;
				end loop;
				return res;
			end function;


-- for circular?
function TMP_change(qs: TMP_queueState; nSend, nRec: SmallNumber;
						fullMask, killMask: std_logic_vector; killSig: std_logic; maskNext: std_logic_vector)
return TMP_queueState is
	constant LEN: integer := fullMask'length;

	variable res: TMP_queueState := qs;
	variable pStartNew, pEndNew, pEndNext, nFullNext, pLive,
				sizeNum, maskNum, tempCnt: SmallNumber := (others => '0');
	variable liveMask, killedSearchMask, liveSearchMask,
				killedPr, livePr: std_logic_vector(0 to LEN-1) := (others => '0');
	variable pLiveSel: std_logic := '0';
begin
	-- TODO: check if not sending more than living, etc.

	sizeNum := i2slv(LEN, SMALL_NUMBER_SIZE);
	maskNum := i2slv(LEN-1, SMALL_NUMBER_SIZE);	
	assert countOnes(sizeNum) = 1 report "Size not binary";  -- make sure LEN is a binary number;
	
	liveMask := fullMask and not killMask;
	
	pStartNew := addSN(qs.pStart, nSend);						
	pEndNew := addSN(qs.pEnd, nRec);
	
	-- Where is "first killed" slot if any?
	killedPr(1 to LEN-1) := killMask(0 to LEN-2);
	killedPr(0) := killMask(LEN-1); -- CAREFUL: for shifting queue this would be constant '0'  
	--killedSearchMask := killMask and not killedPr; -- Bit sum must be 0 or 1
	
	-- Put this into a function?
	for i in 0 to LEN-1 loop
		pLive := i2slv(i, SMALL_NUMBER_SIZE);
		if killedPr(i) = '0' and (killMask(i) = '1') then -- we have "first killed"
			pLiveSel := '1';
			exit;
		end if;
	end loop;

	if pLiveSel = '1' then
		pEndNext := pLive;			
	else
		pEndNext := pEndNew;			
	end if;
	
	nFullNext := subSN(pEndNext, pStartNew); -- CAREFUL! Omits highest bit
	
	res.pStart := pStartNew and maskNum;
	res.pEnd := pEndNext and maskNum;	-- CAREFUL: in shifting queue 1 more bit for MAX_SIZE
	res.nFull := nFullNext and maskNum;	--				here likewise ^^
	-- Handle the case where every slot is full
	-- CAREFUL: must be a bit from future fullMask, cause current liveMask slot can be sent and cleared!
	if isNonzero(res.nFull) = '0' and maskNext(0) = '1' then -- Any slot from liveMask would do
		res.nFull := res.nFull or sizeNum;
	end if;
	return res;
end function;


function TMP_change_Shifting(qs: TMP_queueState; nSend, nRec: SmallNumber;
						fullMask, killMask: std_logic_vector; killSig: std_logic)--; maskNext: std_logic_vector)
return TMP_queueState is
	constant LEN: integer := fullMask'length;

	variable res: TMP_queueState := qs;
	variable pStartNew, pEndNew, pEndNext, nFullNext, pLive,
				sizeNum, maskNum, tempCnt: SmallNumber := (others => '0');
	variable liveMask, killedSearchMask, liveSearchMask,
				killedPr, livePr: std_logic_vector(0 to LEN-1) := (others => '0');
	variable pLiveSel: std_logic := '0';
begin
	-- TODO: check if not sending more than living, etc.

	sizeNum := i2slv(LEN, SMALL_NUMBER_SIZE);
	maskNum := i2slv(LEN-1, SMALL_NUMBER_SIZE);	
	assert countOnes(sizeNum) = 1 report "Size not binary";  -- make sure LEN is a binary number;
	
	liveMask := fullMask and not killMask;
	
	pStartNew := qs.pStart;--addSN(qs.pStart, nSend);						
	pEndNew := addSN(qs.pEnd, nRec);
	
	-- Where is "first killed" slot if any?
	killedPr(1 to LEN-1) := killMask(0 to LEN-2);
	killedPr(0) := '0'; -- CAREFUL: for shifting queue this would be constant '0'  
	--killedSearchMask := killMask and not killedPr; -- Bit sum must be 0 or 1
	
	-- Put this into a function?
	for i in 0 to LEN-1 loop
		pLive := i2slv(i, SMALL_NUMBER_SIZE);
		if killedPr(i) = '0' and (killMask(i) = '1') then -- we have "first killed"
			pLiveSel := '1';
			exit;
		end if;
	end loop;

	if pLiveSel = '1' then
		pEndNext := pLive;			
	else
		pEndNext := pEndNew;			
	end if;
	
	pEndNext := subSN(pEndNext, nSend); -- CAREFUL: diffrent from Circular, we move this
	
	nFullNext := subSN(pEndNext, pStartNew); -- CAREFUL! Omits highest bit
	
	res.pStart := pStartNew and maskNum;
	res.pEnd := pEndNext and (maskNum or sizeNum);	-- CAREFUL: in shifting queue 1 more bit for MAX_SIZE
	res.nFull := nFullNext and (maskNum or sizeNum);	--				here likewise ^^
	-- Handle the case where every slot is full
	-- CAREFUL: must be a bit from future fullMask, cause current liveMask slot can be sent and cleared!
	--if isNonzero(res.nFull) = '0' and maskNext(0) = '1' then -- Any slot from liveMask would do
	--	--res.nFull := res.nFull or sizeNum;
	--end if;
	return res;
end function;



function getQueueWindow(arr: InstructionStateArray; mask: std_logic_vector; ind: SmallNumber)
return StageDataMulti is
	variable res: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	constant LEN: integer := arr'length;
	constant indNum: integer := slv2u(ind);
begin
	for i in 0 to PIPE_WIDTH-1 loop
		res.fullMask(i) := mask((i + indNum) mod LEN);
		res.data(i) := arr((i + indNum) mod LEN);
	end loop;
	return res;
end function;


function getQueueFrontWindow(qs: TMP_queueState; arr: InstructionStateArray; mask: std_logic_vector)
return StageDataMulti is
begin
	return getQueueWindow(arr, mask, qs.pStart);
end function;

function getQueuePreFrontWindow(qs: TMP_queueState; arr: InstructionStateArray; mask: std_logic_vector)
return StageDataMulti is
begin
	return getQueueWindow(arr, mask, subSN(qs.pStart, smallNum(PIPE_WIDTH)));
end function;

function getQueueBackWindow(qs: TMP_queueState; arr: InstructionStateArray; mask: std_logic_vector)
return StageDataMulti is
begin
	return getQueueWindow(arr, mask, qs.pEnd);
end function;


-- Indices in numbers modulo length, where 0 is at given position
function getQueueIndicesFrom(size: integer; start: SmallNumber) return SmallNumberArray is
	constant LEN: integer := size;
	variable res: SmallNumberArray(0 to LEN-1) := (others => (others => '0'));
	variable sn: SmallNumber := (others => '0');
begin
	for i in 0 to LEN-1 loop
		sn := subSN(smallNum(i), start);
		res(i) := sn and smallNum(LEN-1); -- CAREFUL: mask to get bounded range
	end loop;
	return res;
end function;

function compareIndicesGreater(inds: SmallNumberArray; num: SmallNumber) return std_logic_vector is
begin
	return cmpGreaterThanUnsignedSNA(inds, num);
end function;

function compareIndicesSmaller(inds: SmallNumberArray; num: SmallNumber) return std_logic_vector is
begin
	return cmpLessThanUnsignedSNA(inds, num);
end function;

function compareIndicesEqual(inds: SmallNumberArray; num: SmallNumber) return std_logic_vector is
begin
	return cmpEqualToSNA(inds, num);
end function;

function trimSNA(arr: SmallNumberArray; maskNum: SmallNumber) return SmallNumberArray is
	constant LEN: integer := arr'length;
	variable res: SmallNumberArray(0 to LEN-1) := arr;
begin
	for i in 0 to LEN-1 loop
		res(i) := res(i) and maskNum;
	end loop;
	return res;
end function;

		function getQueueIndicesForInput(qs: TMP_queueState; len: integer; ilen: integer)
		return SmallNumberArray is
		begin
			return trimSNA(getQueueIndicesFrom(len, qs.pEnd), smallNum(ilen-1));
		end function;

-- CAREFUL: if buff size is not greater than PIPE_WIDTH, comparisons using MASK_NUM are not valid!
--				Applies to a number of functions below.
	function getQueueEnableForInput(qs: TMP_queueState; len: integer; nRec: SmallNumber)
	return std_logic_vector is
	begin
		return compareIndicesSmaller(getQueueIndicesFrom(len, qs.pEnd), nRec);
	end function;

		function getQueueIndicesForInput_Shifting(qs: TMP_queueState; len: integer;
																nSend: SmallNumber; ilen: integer)
		return SmallNumberArray is
		begin
			return trimSNA(getQueueIndicesFrom(len, subSN(qs.pEnd, nSend)), smallNum(ilen-1));
		end function;
		
		-- CAREFUL: needed for hbuffer
		function getQueueIndicesForInput_ShiftingHbuff(qs: TMP_queueState; len: integer;
																nSend: SmallNumber; ilen: integer; offset: SmallNumber)
		return SmallNumberArray is
		begin
			return trimSNA(getQueueIndicesFrom(len, subSN(subSN(qs.pEnd, nSend), offset)), smallNum(ilen-1));
		end function;


	function getEnableForInput_Shifting(qs: TMP_queueState; len: integer; nSend, nRec: SmallNumber)
	return std_logic_vector is
	begin
		return compareIndicesSmaller(getQueueIndicesFrom(len, subSN(qs.pEnd, nSend)), nRec);
	end function;


	function getEnableForMoved_Shifting(qs: TMP_queueState; size: integer; nSend, nRec: SmallNumber)
	return std_logic_vector is
		constant LEN: integer := size;
		variable res: std_logic_vector(0 to LEN-1) := (others => '0');
	begin
		if isNonzero(nSend) = '1' then
			return compareIndicesSmaller(getQueueIndicesFrom(LEN, qs.pStart), subSN(qs.pEnd, nSend));
		else
			return res;
		end if;
	end function;

	function getQueueIndicesForMoved_Shifting(qs: TMP_queueState; size: integer; nSend, nRec: SmallNumber)
	return SmallNumberArray is
		constant LEN: integer := size;
		variable res: SmallNumberArray(0 to LEN-1) := (others => (others => '0'));
	begin
		for i in 0 to LEN-1 loop
			res(i) := subSN(nSend, smallNum(1)) and smallNum(LEN-1);
		end loop;
		return res;
	end function;


	function getQueueSendingMask(qs: TMP_queueState; len: integer; nSend: SmallNumber)
	return std_logic_vector is
	begin
		return compareIndicesSmaller(getQueueIndicesFrom(len, qs.pStart), nSend);
	end function;


	function getQueueMaskNext_Shifting(qsNew: TMP_queueState; len: integer) return std_logic_vector is
	begin
		return compareIndicesSmaller(getQueueIndicesFrom(len, smallNum(0)), qsNew.pEnd);
	end function;


	function getKillMaskROB(qs: TMP_queueState; fullMask: std_logic_vector;
									causing: InstructionState; execEventSig: std_logic; lateEventSig: std_logic)
	return std_logic_vector is
		constant LEN: integer := fullMask'length;
		constant MASK_NUM: SmallNumber := i2slv(LEN-1, SMALL_NUMBER_SIZE);
		variable res: std_logic_vector(0 to LEN-1) := (others => '0');
		variable sn, sn0, ih: SmallNumber := (others => '0');
	begin
		ih := getTagHighSN(causing.groupTag);
			ih := subSN(ih, qs.pStart);
			ih := ih and MASK_NUM; -- We must cut it to effective index size, because it must be 
										  -- inside the range of ROB indices
										  
		-- qs.pStart is the beginning of vector
		for i in 0 to LEN-1 loop
			sn := i2slv(i+1, SMALL_NUMBER_SIZE); -- CAREFUL: +1 because group 1 goes to slot 0 etc!
															-- TODO: ensure that when changing initial group tag,
															--			this will be correctly changed too!
			sn := subSN(sn, qs.pStart); -- Index relative relative to start
			sn := sn and MASK_NUM;
			-- Check if higher part of causing tag is smaller than this index. If so, kill
			sn0 := subSN(ih, sn); -- If negative, s0 is smaller
			res(i) := ((sn0(sn0'high) and execEventSig) or lateEventSig)
						and fullMask(i);
		end loop;
		
		return res;
	end function;



function TMP_getNewContent_General(content: InstructionStateArray; newContent: InstructionStateArray;
												movedCken: std_logic_vector; movedIndices: SmallNumberArray;
												inputCken: std_logic_vector; inputIndices: SmallNumberArray)
return InstructionStateArray is
	constant LEN: integer := content'length;
	constant ILEN: integer := newContent'length;
	constant MASK_NUM: SmallNumber := i2slv(ILEN-1, SMALL_NUMBER_SIZE);
	variable res: InstructionStateArray(0 to LEN-1) := content;
	variable tmpSN: SmallNumber := (others => '0');
	variable moved: InstructionStateArray(0 to ILEN-1) := (others => DEFAULT_INSTRUCTION_STATE);
begin
	for i in 0 to LEN-1 loop
		-- "moved" list for each index is different
		for j in 0 to ILEN-1 loop
			moved(j) := content((i + j + 1) mod LEN); -- +1 because for 0 it's just no ck enable
		end loop;
	
		if inputCken(i) = '1' then
			res(i) := newContent(slv2u(inputIndices(i)));
		elsif movedCken(i) = '1' then
			res(i) := moved(slv2u(movedIndices(i)));
		end if;
	end loop;
	return res;
end function;


-- This will work for circular queues
function TMP_getNewContentUpdate(content: InstructionStateArray; newContent: InstructionStateArray;
									cken: std_logic_vector; indices: SmallNumberArray;
									maskA, maskD: std_logic_vector; wrA, wrD: std_logic;
									insA, insD: InstructionState;
									clearCompleted, keepInputContent: boolean)
return InstructionStateArray is
	constant LEN: integer := content'length;
	constant ILEN: integer := newContent'length;
	constant MASK_NUM: SmallNumber := i2slv(ILEN-1, SMALL_NUMBER_SIZE);
	variable res: InstructionStateArray(0 to LEN-1) := content;
	variable tmpSN: SmallNumber := (others => '0');
begin
	for i in 0 to LEN-1 loop
		tmpSN := indices(i) and MASK_NUM;
		--		Also: write only needed entires: for D -> result, completed2; for A -> target, completed 

		if (wrA and maskA(i)) = '1' then
			res(i).--target 
					argValues.arg1
					:= insA.result;
			res(i).controlInfo.completed := '1';
		end if;
		
		if (wrD and maskD(i)) = '1' then
			res(i).--result
					argValues.arg2
					:= insD.argValues.arg2;
			res(i).controlInfo.completed2 := '1';						
		end if;


		if cken(i) = '1' then -- cken is for new input
			-- CAREFUL: write only those fields that have to be written:
			--				groupTag, operation, completed = 0, completed2 = 0
			-- res(i) := newContent(slv2u(tmpSN));
			res(i).groupTag := newContent(slv2u(tmpSN)).groupTag;
			res(i).operation := newContent(slv2u(tmpSN)).operation;
			
			if keepInputContent then
				res(i).argValues := newContent(slv2u(tmpSN)).argValues;
			end if;
			
			if clearCompleted then
				res(i).controlInfo.completed := '0';
				res(i).controlInfo.completed2 := '0';
			else
				res(i).controlInfo.completed := newContent(slv2u(tmpSN)).controlInfo.completed;
				res(i).controlInfo.completed2 := newContent(slv2u(tmpSN)).controlInfo.completed2;				
			end if;
		end if;
	end loop;
	return res;
end function;

end Queues;



package body Queues is
							 


end Queues;
