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

function smallNum(n: integer) return SmallNumber is
begin
	return i2slv(n, SMALL_NUMBER_SIZE);
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

--
--
--function TMP_getFrontWindow(qs: TMP_queueState;
--									 arr: InstructionStateArray; mask: std_logic_vector)
--return StageDataMulti is
--	variable res: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
--	variable ind: integer := 0;
--	constant LEN: integer := arr'length; 
--begin
--	ind := slv2u(qs.pStart);
--	for i in 0 to PIPE_WIDTH-1 loop
--		res.fullMask(i) := mask((i + ind) mod LEN);
--		res.data(i) := arr((i + ind) mod LEN);
--	end loop;
--	
--	return res;
--end function;
--
--function TMP_getPreFrontWindow(qs: TMP_queueState;
--									 arr: InstructionStateArray; mask: std_logic_vector)
--return StageDataMulti is
--	variable res: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
--	variable ind: integer := 0;
--	constant LEN: integer := arr'length; 
--begin
--	ind := slv2u(qs.pStart) - PIPE_WIDTH;
--	for i in 0 to PIPE_WIDTH-1 loop
--		res.fullMask(i) := mask((i + ind) mod LEN);
--		res.data(i) := arr((i + ind) mod LEN);
--	end loop;
--	
--	return res;
--end function;
--
--function TMP_getBackWindow(qs: TMP_queueState;
--									 arr: InstructionStateArray; mask: std_logic_vector)
--return StageDataMulti is
--	variable res: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
--	variable ind: integer := 0;
--	constant LEN: integer := arr'length; 
--begin
--	ind := slv2u(qs.pEnd);
--	for i in 0 to PIPE_WIDTH-1 loop
--		res.fullMask(i) := mask((i + ind) mod LEN);
--		res.data(i) := arr((i + ind) mod LEN);
--	end loop;
--	
--	return res;
--end function;

-- Indices in numbers modulo length, where 0 is at given position
function getQueueIndicesFrom(mask: std_logic_vector; start: SmallNumber) return SmallNumberArray is
	constant LEN: integer := mask'length;	
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

function compareIndicesSmaller(inds: SmallNumberArray; num: SmallNumber) return std_logic_vector is
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

function compareIndicesEqual(inds: SmallNumberArray; num: SmallNumber) return std_logic_vector is
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

function trimSNA(arr: SmallNumberArray; maskNum: SmallNumber) return SmallNumberArray is
	constant LEN: integer := arr'length;
	variable res: SmallNumberArray(0 to LEN-1) := arr;
begin
	for i in 0 to LEN-1 loop
		res(i) := res(i) and maskNum;
	end loop;
	return res;
end function;


-- This calculates selection bits for the new input branch of muxes
-- In case of shifting queue, must work with updated back pointer, or nRemaining
function TMP_getIndicesForInput(qs: TMP_queueState; mask: std_logic_vector) return SmallNumberArray is
	constant LEN: integer := mask'length;
	constant MASK_NUM: SmallNumber := smallNum(PIPE_WIDTH-1);
							--	SmallNumber := i2slv(PIPE_WIDTH-1, SMALL_NUMBER_SIZE); -- Based on PIPE_WIDTH!
	variable res: SmallNumberArray(0 to LEN-1) := (others => (others => '0'));
	variable sn: SmallNumber := (others => '0');
begin
	for i in 0 to LEN-1 loop
		sn := smallNum(i);--i2slv(i, SMALL_NUMBER_SIZE);
		sn := subSN(sn, qs.pEnd);
		sn := sn and MASK_NUM;
		res(i) := sn;
	end loop;
	return res;
end function;

		function getQueueIndicesForInput(qs: TMP_queueState; mask: std_logic_vector) return SmallNumberArray is
		begin
			return trimSNA(getQueueIndicesFrom(mask, qs.pEnd), smallNum(PIPE_WIDTH-1));
		end function;

-- CAREFUL: if buff size is not greater than PIPE_WIDTH, comparisons using MASK_NUM are not valid!
--				Applies to a number of functions below.
function TMP_getCkEnForInput(qs: TMP_queueState; mask: std_logic_vector; nRec: SmallNumber)
return std_logic_vector is
	constant LEN: integer := mask'length;
		constant MASK_NUM: SmallNumber := i2slv(LEN-1, SMALL_NUMBER_SIZE); 
	variable res: std_logic_vector(0 to LEN-1) := (others => '0');
	variable sn, sn0: SmallNumber := (others => '0');
begin
	for i in 0 to LEN-1 loop
		-- Put '1' if (i - qs.pEnd) in [0 to nRec-1]  // or use enable for whole window up to PIEP_WIDTH-1??
			sn := i2slv(i, SMALL_NUMBER_SIZE);
			sn := subSN(sn, qs.pEnd);
				sn := sn and MASK_NUM;
			-- Check if sn is nonnegative but smaller than nRec
			sn0 := subSN(sn, nRec);
				--sn := sn and MASK_NUM;
				--sn0 := sn0 and MASK_NUM;
			
		res(i) := not sn(SMALL_NUMBER_SIZE-1) and sn0(SMALL_NUMBER_SIZE-1); 		
	end loop;	
	return res;
end function; 

	function getQueueEnableForInput(qs: TMP_queueState; mask: std_logic_vector; nRec: SmallNumber)
	return std_logic_vector is
	begin
		return compareIndicesSmaller(getQueueIndicesFrom(mask, qs.pEnd), nRec);
	end function;
	
	

	function TMP_getCkEnForInput_Shifting(qs: TMP_queueState; mask: std_logic_vector; nSend, nRec: SmallNumber)
	return std_logic_vector is
		constant LEN: integer := mask'length;
			constant MASK_NUM: SmallNumber := i2slv(LEN-1, SMALL_NUMBER_SIZE);		
		variable res: std_logic_vector(0 to LEN-1) := (others => '0');
		variable sn, sn0: SmallNumber := (others => '0');
	begin
		for i in 0 to LEN-1 loop
			-- Put '1' if (i - qs.pEnd) in [0 to nRec-1]  // or use enable for whole window up to PIEP_WIDTH-1??
				sn := i2slv(i, SMALL_NUMBER_SIZE);
				sn := subSN(sn, qs.pEnd);
				sn := addSN(sn, nSend); -- difference from circular: temporary pEnd moves towards front
					sn := sn and MASK_NUM;
				-- Check if sn is nonnegative but smaller than nRec
				sn0 := subSN(sn, nRec);
			res(i) := not sn(SMALL_NUMBER_SIZE-1) and sn0(SMALL_NUMBER_SIZE-1); 
		end loop;
		return res;
	end function;

	function TMP_getCkEnForMoved_Shifting(qs: TMP_queueState; mask: std_logic_vector; nSend, nRec: SmallNumber)
	return std_logic_vector is
		constant LEN: integer := mask'length;
			constant MASK_NUM: SmallNumber := i2slv(LEN-1, SMALL_NUMBER_SIZE);		
		variable res: std_logic_vector(0 to LEN-1) := (others => '0');
		variable sn, sn0, nRem: SmallNumber := (others => '0');
	begin
		for i in 0 to LEN-1 loop
			-- Put '1' if (i - qs.pEnd) in [0 to nRec-1]  // or use enable for whole window up to PIEP_WIDTH-1??
				sn := i2slv(i, SMALL_NUMBER_SIZE);
					sn := sn and MASK_NUM;
					nRem := subSN(qs.pEnd, nSend);
				-- Check if sn is nonnegative but smaller than nRemaining
				sn0 := subSN(sn, nRem);
			res(i) := not sn(SMALL_NUMBER_SIZE-1) and sn0(SMALL_NUMBER_SIZE-1)
							and isNonzero(nSend); -- moves only when sending something!
		end loop;
		return res;
	end function;


function TMP_getSendingMask(qs: TMP_queueState; mask: std_logic_vector; nSend: SmallNumber)
return std_logic_vector is
	constant LEN: integer := mask'length;
		constant MASK_NUM: SmallNumber := i2slv(LEN-1, SMALL_NUMBER_SIZE);	
	variable res: std_logic_vector(0 to LEN-1) := (others => '0');
	variable sn, sn0: SmallNumber := (others => '0');
begin
	for i in 0 to LEN-1 loop
			sn := i2slv(i, SMALL_NUMBER_SIZE);
			sn := subSN(sn, qs.pStart);
				sn := sn and MASK_NUM;
			-- Check if sn is nonnegative but smaller than nSend
			sn0 := subSN(sn, nSend);
		res(i) := not sn(SMALL_NUMBER_SIZE-1) and sn0(SMALL_NUMBER_SIZE-1); 
	end loop;
	return res;
end function;

	function getQueueSendingMask(qs: TMP_queueState; mask: std_logic_vector; nSend: SmallNumber)
	return std_logic_vector is
	begin
		return compareIndicesSmaller(getQueueIndicesFrom(mask, qs.pStart), nSend);
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



function TMP_getNewContent(content: InstructionStateArray; newContent: InstructionStateArray;
									cken: std_logic_vector; indices: SmallNumberArray)
return InstructionStateArray is
	constant LEN: integer := content'length;
	constant ILEN: integer := newContent'length;
	constant MASK_NUM: SmallNumber := i2slv(ILEN-1, SMALL_NUMBER_SIZE);
	variable res: InstructionStateArray(0 to LEN-1) := content;
	variable tmpSN: SmallNumber := (others => '0');
begin
	for i in 0 to LEN-1 loop
		tmpSN := indices(i) and MASK_NUM;
		if cken(i) = '1' then
			res(i) := newContent(slv2u(tmpSN));
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
		-- TODO: add updated slots to the mux
		-- 		The update will apply only to selected fields of the slots, and for circular queue
		--			those fields are never written from different sources.
		--			So for circular queue there can be independent loops, without multiplexing those fields.
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




function selectIns4(v0: InstructionStateArray(0 to 3);
						  s0: std_logic_vector(1 downto 0))
						  return InstructionState;

function selectIns4x4(v0, v1, v2, v3: InstructionStateArray(0 to 3);
							 s0, s1, s2, s3: std_logic_vector(1 downto 0); -- select (for each subvec)
							 sT: std_logic_vector(1 downto 0)) -- select top
							 return InstructionState;							 

function selectQueueNext(queueList: InstructionStateArray; queueIndex: SmallNumber; condQueueHigh: std_logic;
								 inputList: InstructionStateArray; inputIndex: SmallNumber; condInputHigh: std_logic;
								 condChooseInput: std_logic) return InstructionState;

-- nIn indicates number of full positions, aligned to right (for jump to not-beginning of block)
-- CAREFUL: The start IP in bock can be encoded in the IP of element (0)?
function TEMP_movingQueue_q16_i8_o8(buffIn: HbuffQueueData;
												input: InstructionStateArray;
												nFullV, nInV, nOutV: SmallNumber; killAll: std_logic;
												startIP: Mword)
return HbuffQueueData;

-- nIn indicates number of full positions, aligned to right (for jump to not-beginning of block)
-- CAREFUL: The start IP in bock can be encoded in the IP of element (0)?
function TEMP_movingQueue_q16_i8_o8_Ref(buffIn: HbuffQueueData;
												input: InstructionStateArray;
												nFullV, nInV, nOutV: SmallNumber; killAll: std_logic;
												startIP: Mword)
return HbuffQueueData;

end Queues;



package body Queues is

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
						res := v0(slv2u(s0));
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
					--	report integer'image(slv2u(s0)) & ", " & integer'image(slv2u(s2));
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
	variable inputExt: InstructionStateArray(0 to ILEN + 4+4 - 1 + 2) := (others => input(ILEN-1));
	variable inputExt5: InstructionStateArray(0 to 5*ILEN-1) := input & input & input & input & input;
	
	variable queueList, inputList: InstructionStateArray(0 to 7) := (others => DEFAULT_INSTRUCTION_STATE);
--	variable inputList: InstructionStateArray(0 to 7) := (others => DEFAULT_INSTRUCTION_STATE);		
	
	variable resContentT: InstructionStateArray(0 to QLEN-1) := (others => DEFAULT_INSTRUCTION_STATE);
	variable resMaskT: std_logic_vector(0 to QLEN-1) := (others => '0');
	
	variable nRemV, nOffV, nOffMRV, nFullNewV, nOutM1V: SmallNumber := (others => '0');
	variable queueIndex, inputIndex: SmallNumber := (others => '0');
	
	variable tempSelected: InstructionState := DEFAULT_INSTRUCTION_STATE;
	variable iMod: integer := 0;
	variable condChooseInput, condQueueHigh, condInputHigh: std_logic := '0';
begin
	nOffV(ALIGN_BITS-2 downto 0) := startIP(ALIGN_BITS-1 downto 1);
	nRemV := subSN(nFullV, nOutV);
	nOffMRV := subSN(nOffV, nRemV);
	nOutM1V := subSN(nOutV, X"01");		
	if killAll = '0' then -- else => zeros
		nFullNewV := addSN(nRemV, nInV);			
	end if;

	inputExt(0 to ILEN-1) := input;
	qinExt(0 to HBUFFER_SIZE-1) := qin;
	resContentT := qin;

	-- For each index in queue we have to find a set of functions:
	-- from set {queue(0 to MAX_OUT-1), input} find selection and CLK_EN
	-- {sel(i), cken(i)} = f(i, nFull, nIn, nOut), where sel is 4b
	for i in 0 to QLEN-1 loop		
		iMod := i mod ILEN;
		-- Prepare 2 lists of elements to select - 1 list from queue content, another form input
		queueList := qinExt(i+1 to i+8);
		inputList := inputExt5(iMod+0 to iMod+7);
		queueIndex := nOutM1V;
		inputIndex := nOffMRV;

		-- CONDITION = (nRem <= i)						
		condChooseInput := not greaterThan(nRemV, i, 5); -- from input - rather than from old content		
		condQueueHigh := greaterThan(nOutV, 4, 4);
								--greaterThan(nOutM1V, 3, 4)
		condInputHigh := not lessThan(nOffMRV and X"07", 4, 6); -- CAREFUL: means 3 bits for useful index!

		-- Internal handling of partition and muxing:
		tempSelected := selectQueueNext(queueList, queueIndex, condQueueHigh,
															 inputList, inputIndex, condInputHigh,
															 condChooseInput);						
		-- This condition generates clock enable
		-- CAREFUL: nOut /= 0 could be equiv to nextAccepting?
		--				nextAccepting will differ from nOut /= 0 when nFull = 0, but in this case
		--				the second part of condition is true everywhere, so the substitution seems valid!
		-- CONDITION:(nOut /= 0 or nRem <= i) --  nRem can be replaced with nFull
		if	(nOutV(3 downto 0) & condChooseInput) /= "00000" then		-- CAREFUL: nOutV must be no more than 4b long! 
			resContentT(i) := tempSelected;
		end if;										 

		-- CONDITION = (nFullNew > i)
		resMaskT(i) := greaterThan(nFullNewV, i, 5); -- fillng fullMask
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
