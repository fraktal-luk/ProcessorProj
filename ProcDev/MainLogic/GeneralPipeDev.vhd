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
use work.ProcHelpers.all;

use work.ProcInstructionsNew.all;

use work.NewPipelineData.all;

use work.TEMP_DEV.all;



package GeneralPipeDev is

function getTagHigh(tag: std_logic_vector) return std_logic_vector;
function getTagLow(tag: std_logic_vector) return std_logic_vector;
function getTagHighSN(tag: InsTag) return SmallNumber;
function getTagLowSN(tag: InsTag) return SmallNumber;	
function clearTagLow(tag: std_logic_vector) return std_logic_vector;	
function clearTagHigh(tag: std_logic_vector) return std_logic_vector;	
function alignAddress(adr: std_logic_vector) return std_logic_vector;
function clearLowBits(vec: std_logic_vector; n: integer) return std_logic_vector;
function getLowBits(vec: std_logic_vector; n: integer) return std_logic_vector;

constant INITIAL_GROUP_TAG: InsTag := (others => '0');

constant DEFAULT_DATA_PC: InstructionState := defaultInstructionState;
constant DEFAULT_ANNOTATED_HWORD: InstructionState := defaultInstructionState;


type StageDataCommitQueue is record
	fullMask: std_logic_vector(0 to CQ_SIZE-1); 
	data: InstructionStateArray(0 to CQ_SIZE-1);
end record;

-- FORWARDING NETWORK
type ForwardingInfo is record
	writtenTags: PhysNameArray(0 to PIPE_WIDTH-1);
	resultTags: PhysNameArray(0 to N_RES_TAGS-1);
	nextResultTags: PhysNameArray(0 to N_NEXT_RES_TAGS-1);
	nextTagsM2:	PhysNameArray(0 to 2); -- TEMP?
	resultValues: MwordArray(0 to N_RES_TAGS-1);
end record;

constant DEFAULT_FORWARDING_INFO: ForwardingInfo := (
	writtenTags => (others => (others => '0')),
	resultTags => (others => (others => '0')),
	nextResultTags => (others => (others => '0')),
	nextTagsM2 => (others => (others => '0')),
	resultValues => (others => (others => '0'))
);


function makeSDM(arr: InstructionSlotArray) return StageDataMulti;
function squeezeSD(sd: StageDataMulti; srcVec: std_logic_vector) return StageDataMulti;

function makeSlotArray(insVec: InstructionStateArray; mask: std_logic_vector) return InstructionSlotArray;

function extractFullMask(queueContent: InstructionSlotArray) return std_logic_vector;
function extractData(queueContent: InstructionSlotArray) return InstructionStateArray;

function extractFullMask(queueContent: SchedulerEntrySlotArray) return std_logic_vector;
function extractData(queueContent: SchedulerEntrySlotArray) return InstructionStateArray;


function moveQueue(content, newContent: InstructionSlotArray; nFull, nOut, nIn: integer)
return InstructionSlotArray;

function selectFromQueue(content: InstructionSlotArray; index: integer) return InstructionSlot;

function removeFromQueue(content: InstructionSlotArray; index: integer) return InstructionSlotArray;

function chooseIns(content: InstructionStateArray; which: std_logic_vector)
return InstructionState;


function findMatching(content: InstructionSlotArray; ins: InstructionState)
return std_logic_vector;

-- TODO: is redundant, should unify with findMatching?
function findMatchingGroupTag(arr: InstructionStateArray; ins: InstructionState)
return std_logic_vector;


function stageMultiNext(livingContent, newContent: StageDataMulti; full, sending, receiving: std_logic)
return StageDataMulti;

	function stageMultiNextCl(livingContent, newContent: StageDataMulti; full, sending, receiving: std_logic;
										kill: std_logic; clearEmptySlots: boolean)
	return StageDataMulti;

	function stageArrayNext(livingContent, newContent: InstructionSlotArray; full, sending, receiving: std_logic;
										kill: std_logic)
	return InstructionSlotArray;

function stageMultiHandleKill(content: StageDataMulti; 
										killAll: std_logic) 
										return StageDataMulti;

function stageCQNext_New(content: StageDataCommitQueue; newContent: InstructionStateArray;
		livingMask: std_logic_vector;
		ready: std_logic_vector;
		outWidth: integer;
		nFull, nOut, nIn: integer)
return StageDataCommitQueue;

-----------------------									

function getPhysicalSources(ins: InstructionState) return PhysNameArray;
	
function clearTempControlInfoSimple(ins: InstructionState) return InstructionState;
function clearTempControlInfoMulti(sd: StageDataMulti) return StageDataMulti;
	
	-- TODO: use these to implement StageDataMulti corresponding functions?
	function getArrayResults(ia: InstructionStateArray) return MwordArray;
	function getArrayPhysicalDests(ia: InstructionStateArray) return PhysNameArray;
	function getArrayDestMask(ia: InstructionStateArray; fm: std_logic_vector) return std_logic_vector;
	
function getInstructionResults(insVec: StageDataMulti) return MwordArray;
function getVirtualArgs(insVec: StageDataMulti) return RegNameArray;
function getPhysicalArgs(insVec: StageDataMulti) return PhysNameArray;
function getVirtualDests(insVec: StageDataMulti) return RegNameArray;
function getPhysicalDests(insVec: StageDataMulti) return PhysNameArray;
-- Which elements really have a destination, not r0
function getDestMask(insVec: StageDataMulti) return std_logic_vector;
-- Find which ops write to the same virtual reg as later instructions in group
function findOverriddenDests(insVec: StageDataMulti) return std_logic_vector;

-- This works on physical arg selection bits, assuming that checking for r0/p0 was done earlier. 
function getPhysicalDestMask(insVec: StageDataMulti) return std_logic_vector;

function getExceptionMask(insVec: StageDataMulti) return std_logic_vector;

function getEffectiveMask(newContent: StageDataMulti) return std_logic_vector;
function getLastEffective(newContent: StageDataMulti) return InstructionState;

function getSendingFromCQ(livingMask: std_logic_vector) return std_logic_vector;


function CMP_tagBefore(tagA, tagB: InsTag) return std_logic is
	variable wA, wB: word := (others => '0');
	variable wC: std_logic_vector(32 downto 0) := (others => '0');
begin
	wA(TAG_SIZE-1 downto 0) := tagA;
	wB(TAG_SIZE-1 downto 0) := tagB;
	wB := not wB;
	-- TODO: when going to 64 bit, this must be changed!
	wC := addMwordFasterExt(wA, wB, '1');
	wC(32 downto TAG_SIZE) := (others => '0');
	return wC(TAG_SIZE-1);
end function;

function CMP_tagAfter(tagA, tagB: InsTag) return std_logic is
	variable wA, wB, wC: word := (others => '0');
begin
	return CMP_tagBefore(tagB, tagA);
end function;


function getStoredArg1(ins: InstructionState) return Mword is
begin
	return ins.result;
end function;

function getStoredArg2(ins: InstructionState) return Mword is
begin
	return ins.target;
end function;

function setStoredArg1(ins: InstructionState; val: Mword) return InstructionState is
	variable res: InstructionState := ins;
begin
	res.result := val;
	return res;
end function;

function setStoredArg2(ins: InstructionState; val: Mword) return InstructionState is
	variable res: InstructionState := ins;
begin
	res.target := val;
	return res;
end function;


function killByTag(before, ei, int: std_logic) return std_logic;
	
-- FORWARDING NETWORK ------------
-- UNUSED
function getWrittenTags(lastCommitted: StageDataMulti) return PhysNameArray; -- DEPREC

function getResultTags(execOutputs: InstructionSlotArray;
			stageDataCQ: InstructionSlotArray;
			lastCommitted: StageDataMulti) 
return PhysNameArray;

function getNextResultTags(execOutputsPre: InstructionSlotArray;
			schedOutputArr: SchedulerEntrySlotArray)
return PhysNameArray;
	
function getResultValues(execOutputs: InstructionSlotArray; 
										stageDataCQ: InstructionSlotArray;
										lastCommitted: StageDataMulti)
return MwordArray;	
---------------------

function getKillMask(content: InstructionStateArray; fullMask: std_logic_vector;
							causing: InstructionState; execEventSig: std_logic; lateEventSig: std_logic)
return std_logic_vector;

function setInstructionIP(ins: InstructionState; ip: Mword) return InstructionState;
function setInstructionTarget(ins: InstructionState; target: Mword) return InstructionState;
function setInsResult(ins: InstructionState; result: Mword) return InstructionState;

	function isLoad(ins: InstructionState) return std_logic;
	function isSysRegRead(ins: InstructionState) return std_logic;
	function isStore(ins: InstructionState) return std_logic;
	function isSysRegWrite(ins: InstructionState) return std_logic;

function getAddressIncrement(ins: InstructionState) return Mword;

-- Description: arg1 := target
function trgForBQ(insVec: StageDataMulti) return StageDataMulti;

type SLVA is array (integer range <>) of std_logic_vector(0 to PIPE_WIDTH-1);

end GeneralPipeDev;



package body GeneralPipeDev is

function getTagHigh(tag: std_logic_vector) return std_logic_vector is
	variable res: std_logic_vector(tag'high-LOG2_PIPE_WIDTH downto 0) := (others => '0');
begin
	res := tag(tag'high downto LOG2_PIPE_WIDTH);
	return res;
end function;

function getTagLow(tag: std_logic_vector) return std_logic_vector is
	variable res: std_logic_vector(LOG2_PIPE_WIDTH-1 downto 0) := (others => '0');
begin
	res := tag(LOG2_PIPE_WIDTH-1 downto 0);
	return res;
end function;

function getTagHighSN(tag: InsTag) return SmallNumber is
	variable res: SmallNumber := (others => '0');
begin
	res(TAG_SIZE-1-LOG2_PIPE_WIDTH downto 0) := tag(TAG_SIZE-1 downto LOG2_PIPE_WIDTH);
	return res;
end function;

function getTagLowSN(tag: InsTag) return SmallNumber is
	variable res: SmallNumber := (others => '0');
begin
	res(LOG2_PIPE_WIDTH-1 downto 0) := tag(LOG2_PIPE_WIDTH-1 downto 0);
	return res;
end function;


function clearTagLow(tag: std_logic_vector) return std_logic_vector is
	variable res: std_logic_vector(tag'high downto 0) := (others => '0');
begin
	res := tag;
	res(LOG2_PIPE_WIDTH-1 downto 0) := (others => '0');
	return res;
end function;	

function clearTagHigh(tag: std_logic_vector) return std_logic_vector is
	variable res: std_logic_vector(tag'high downto 0) := (others => '0');
begin
	res := tag;
	res(tag'high downto LOG2_PIPE_WIDTH) := (others => '0');
	return res;
end function;

function alignAddress(adr: std_logic_vector) return std_logic_vector is
	variable res: std_logic_vector(adr'high downto 0) := (others => '0');
begin
	res := adr;
	res(ALIGN_BITS-1 downto 0) := (others => '0');
	return res;
end function;

function clearLowBits(vec: std_logic_vector; n: integer) return std_logic_vector is
	variable res: std_logic_vector(vec'high downto 0) := (others => '0');
begin
	res := vec;
	res(n-1 downto 0) := (others => '0');
	return res;
end function;

function getLowBits(vec: std_logic_vector; n: integer) return std_logic_vector is
	variable res: std_logic_vector(n-1 downto 0) := (others => '0');
begin
	res(n-1 downto 0) := vec(n-1 downto 0);
	return res;
end function;


function makeSDM(arr: InstructionSlotArray) return StageDataMulti is
	variable res: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	constant LEN: integer := arr'length;
begin
	
	for i in 0 to PIPE_WIDTH-1 loop
		if i >= LEN then
			exit;
		end if;
		res.fullMask(i) := arr(i).full;
		res.data(i) := arr(i).ins;
	end loop;
	
	return res;
end function;

function squeezeSD(sd: StageDataMulti; srcVec: std_logic_vector) return StageDataMulti is
	variable res: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	variable k: natural := 0;
		constant CLEAR_EMPTY_SLOTS_IQ_ROUTING: boolean := false;
begin
	if not CLEAR_EMPTY_SLOTS_IQ_ROUTING then
		res.data := sd.data;
	end if;

	for i in sd.fullMask'range loop
		-- Fill with input(j) where j is index of i-th '1' in srcVec
		-- For output(0):
		--	"0000" -> 3?
		-- "0001" -> 3
		-- "0010" -> 2
		-- "0011" -> 2
		-- "0100" -> 1
		-- "0101" -> 1
		-- "0110" -> 1 etc.
		--		 ^ last bit is neutral for data, only matters for 'full' bit
		-- For output(1):
		-- "0000" -> 3?
		-- "0001" -> 3?
		-- "0010" -> 3?
		-- "0011" -> 3
		-- "0100" -> 3? 2?
		-- "0101" -> 3
		-- "0110" -> 2
		-- "0111" -> 2
		-- "1000" -> 1? 2? 3? 
		-- "1001" -> 3
		-- "1010" -> 2
		-- "1011" -> 2
		-- "1100" -> 1
		-- "1101" -> 1
		-- "1110" -> 1
		-- "1111" -> 1
		-- 	 ^ last bit is neutral, penult is not
		--			Formula: 1 + ofs, ofs = 0 when "11__", 1 when "101_" or "011_", else 2 ??
		-- For output(2):
		-- "0000" -> ?
		-- "0001" -> ?
		-- "0010" -> ?
		-- "0011" -> ?
		-- "0100" -> ?
		-- "0101" -> ?
		-- "0110" -> ?
		-- "0111" -> 3
		-- "1000" -> ?
		-- "1001" -> ?
		-- "1010" -> ?
		-- "1011" -> 3
		-- "1100" -> ?
		-- "1101" -> 3
		-- "1110" -> 2
		-- "1111" -> 2
		-- 	^ last bit neutral. 2 when "111_", 3 when "110_"
		--		formula": 2 + ofs, ofs = 0 when "111_", else 1
		
		-- Idea: separate the logic for each output. index(0) = f0(mask), index(1) = f1(mask) etc.
		-- So in this place make inner loop with each possible mux index
		for j in 0 to PIPE_WIDTH-1 loop
			-- Select route input(j)->output(i) if condition met
			res.data(i) := sd.data(j);
			if countOnes(srcVec(0 to j-1)) = i and srcVec(j) = '1' then
				res.fullMask(i) := '1';
				exit;
			end if;
		end loop;
	end loop;
	return res;
end function;


function makeSlotArray(insVec: InstructionStateArray; mask: std_logic_vector) return InstructionSlotArray is
	variable res: InstructionSlotArray(0 to insVec'length-1) := (others => DEFAULT_INSTRUCTION_SLOT);
begin
	for i in 0 to res'length-1 loop
		res(i).ins := insVec(i);
		res(i).full := mask(i); 
	end loop;
	
	return res;
end function;


function extractFullMask(queueContent: InstructionSlotArray) return std_logic_vector is
	variable res: std_logic_vector(0 to queueContent'length-1) := (others => '0');
begin
	for i in res'range loop
		res(i) := queueContent(i).full;
	end loop;
	return res;
end function;

function extractData(queueContent: InstructionSlotArray) return InstructionStateArray is
	variable res: InstructionStateArray(0 to queueContent'length-1) := (others => defaultInstructionState);
begin
	for i in res'range loop
		res(i) := queueContent(i).ins;
	end loop;
	return res;
end function;

function extractFullMask(queueContent: SchedulerEntrySlotArray) return std_logic_vector is
	variable res: std_logic_vector(0 to queueContent'length-1) := (others => '0');
begin
	for i in res'range loop
		res(i) := queueContent(i).full;
	end loop;
	return res;
end function;

function extractData(queueContent: SchedulerEntrySlotArray) return InstructionStateArray is
	variable res: InstructionStateArray(0 to queueContent'length-1) := (others => defaultInstructionState);
begin
	for i in res'range loop
		res(i) := queueContent(i).ins;
	end loop;
	return res;
end function;


function moveQueue(content, newContent: InstructionSlotArray; nFull, nOut, nIn: integer)
return InstructionSlotArray is
	variable res: InstructionSlotArray(0 to content'length-1) := (others => DEFAULT_INSTRUCTION_SLOT);
begin
	if nFull > content'length then
		return content;
	end if;

	if nOut > nFull then
		return content;
	end if;
	
	if nFull - nOut + nIn > content'length then
		return content;
	end if;



	for i in 0 to res'length-1 loop --(nFull-nOut) - 1 loop
		if i > nFull-nOut - 1 then
			exit;
		end if;
		res(i) := content(nOut + i);
	end loop;
	
	for i in 0 to newContent'length-1 loop --nIn - 1 loop
		if i > nIn - 1 then
			exit;
		end if;
		res(nFull-nOut + i) := newContent(i);
	end loop;
	
	return res;
end function;


function selectFromQueue(content: InstructionSlotArray; index: integer) return InstructionSlot is
	variable res: InstructionSlot := DEFAULT_INSTRUCTION_SLOT;
begin
	if index < content'left or index > content'right then
		return res;
	end if;
	return content(index);
end function;

function removeFromQueue(content: InstructionSlotArray; index: integer) return InstructionSlotArray is 
	variable res: InstructionSlotArray(0 to content'length-1) := (others => DEFAULT_INSTRUCTION_SLOT);
begin
	if index < content'left or index > content'right then
		return content;
	end if;

	for i in 0 to res'length-1 loop --index-1 loop
		if i > index-1 then
			exit;
		end if;
		res(i) := content(i);
	end loop;
	
	for i in 0 to content'length-1 loop --index+1 to content'length-1 loop
		if i < index + 1 then
			next;
		end if;
		
		if i-1 < 0 then
			next;
		end if;
		res(i-1) := content(i);
	end loop;
	
	return res;
end function;


function chooseIns(content: InstructionStateArray; which: std_logic_vector)
return InstructionState is
	variable res: InstructionState := DEFAULT_INSTRUCTION_STATE;
begin
	for i in 0 to which'length-1 loop
		if which(i) = '1' then
			res := content(i);
			exit;
		end if;
	end loop;
	
	return res;
end function;


function findMatching(content: InstructionSlotArray; ins: InstructionState)
return std_logic_vector is
	variable res: std_logic_vector(content'range) := (others => '0');
begin
	-- Find where to put addressData
	for i in 0 to content'length-1 loop							
		if ins.tags.renameIndex = content(i).ins.tags.renameIndex and content(i).full = '1' then
			res(i) := '1';
		end if;
	end loop;							
	return res;
end function;


function findMatchingGroupTag(arr: InstructionStateArray; ins: InstructionState)
return std_logic_vector is
	variable res: std_logic_vector(0 to arr'length-1) := (others => '0');
begin
	for i in 0 to arr'length-1 loop
		if arr(i).tags.renameIndex = ins.tags.renameIndex then
			res(i) := '1';
		end if;
	end loop;
	
	return res;
end function;


function stageMultiNext(livingContent, newContent: StageDataMulti; full, sending, receiving: std_logic)
return StageDataMulti is 
	variable res: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
		constant CLEAR_VACATED_SLOTS_GENERAL: boolean := false; 
begin
	--return stageMultiNextCl(livingContent, newContent, full, sending, receiving, false);
end function;


	function stageMultiNextCl(livingContent, newContent: StageDataMulti; full, sending, receiving: std_logic;
										kill: std_logic; clearEmptySlots: boolean)
	return StageDataMulti is 
		variable res: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
		--	constant CLEAR_VACATED_SLOTS_GENERAL: boolean := clearEmptySlots; 
	begin
		res := livingContent;
		if kill = '1' then
			res.fullMask := (others => '0');
		end if;
		
		if receiving = '1' then -- take full
			res := newContent;
		elsif sending = '1' or full = '0' then -- take empty
			-- CAREFUL: clearing result tags for empty slots
			for i in 0 to PIPE_WIDTH-1 loop
				res.data(i).physicalArgSpec.dest := (others => '0');
				res.data(i).controlInfo.newEvent := '0';
			end loop;
			res.fullMask := (others => '0');
		end if;			
			
		return res;
	end function;


	function stageArrayNext(livingContent, newContent: InstructionSlotArray; full, sending, receiving: std_logic;
										kill: std_logic)
	return InstructionSlotArray is 
		constant LEN: natural := livingContent'length;
		variable res: InstructionSlotArray(0 to LEN-1) := (others => DEFAULT_INSTRUCTION_SLOT);
		--	constant CLEAR_VACATED_SLOTS_GENERAL: boolean := clearEmptySlots; 
	begin
		res := livingContent;
		if kill = '1' then
			for i in 0 to LEN-1 loop
				res(i).full := '0';
			end loop;
		end if;
		
		if receiving = '1' then -- take full
			res := newContent;
		elsif sending = '1' or full = '0' then -- take empty
			-- CAREFUL: clearing result tags for empty slots
			for i in 0 to LEN-1 loop
				res(i).ins.physicalArgSpec.dest := (others => '0');
				res(i).ins.controlInfo.newEvent := '0';
			end loop;
				for i in 0 to LEN-1 loop
					res(i).full := '0';
				end loop;
		end if;			
			
		return res;
	end function;


function stageMultiHandleKill(content: StageDataMulti; 
										killAll: std_logic) 
										return StageDataMulti is
	variable res: StageDataMulti := content;
	--	constant CLEAR_KILLED_SLOTS_GENERAL: boolean := false;
begin
--	if not CLEAR_KILLED_SLOTS_GENERAL then
--		res.data := content.data;
--	end if;
	
	if killAll = '1' then
		res.fullMask := (others => '0');
		--res := DEFAULT_STAGE_DATA_MULTI;
	--else
	--	res.fullMask := content.fullMask;-- and not killVec;
	end if;
	
--	for i in res.data'range loop
--		if res.fullMask(i) = '1' then
--			res.data(i) := content.data(i);
--		end if;
--	end loop;
	return res;
end function;


	function getArrayResults(ia: InstructionStateArray) return MwordArray is
		variable res: MwordArray(0 to ia'length-1) := (others => (others => '0'));
	begin
		for i in 0 to res'length-1 loop
			res(i) := ia(i).result; 
		end loop;
		return res;
	end function;
	
	function getArrayPhysicalDests(ia: InstructionStateArray) return PhysNameArray is
		variable res: PhysNameArray(0 to ia'length-1) := (others => (others => '0'));
	begin
		for i in 0 to res'length-1 loop
			res(i) := ia(i).physicalArgSpec.dest;			
		end loop;
		return res;
	end function;
	
	function getArrayDestMask(ia: InstructionStateArray; fm: std_logic_vector) return std_logic_vector is
		variable res: std_logic_vector(0 to ia'length-1) := (others => '0');
	begin
		for i in 0 to res'length-1 loop
			res(i) := fm(i) and ia(i).physicalArgSpec.intDestSel;
		end loop;
		return res;
	end function;


function getInstructionResults(insVec: StageDataMulti) return MwordArray is
	variable res: MwordArray(0 to PIPE_WIDTH-1) := (others => (others => '0'));
begin
	for i in insVec.fullMask'range loop
		res(i) := insVec.data(i).result;
	end loop;
	return res;
end function;

function getVirtualArgs(insVec: StageDataMulti) return RegNameArray is
	variable res: RegNameArray(0 to 3*insVec.fullMask'length-1) := (others=>(others=>'0'));
begin
	for i in insVec.fullMask'range loop
		res(3*i+0) := insVec.data(i).virtualArgSpec.args(0)(4 downto 0);
		res(3*i+1) := insVec.data(i).virtualArgSpec.args(1)(4 downto 0);
		res(3*i+2) := insVec.data(i).virtualArgSpec.args(2)(4 downto 0);
	end loop;
	return res;
end function;

function getPhysicalArgs(insVec: StageDataMulti) return PhysNameArray is
	variable res: PhysNameArray(0 to 3*insVec.fullMask'length-1) := (others=>(others=>'0'));
begin
	for i in insVec.fullMask'range loop
		res(3*i+0) := insVec.data(i).physicalArgSpec.args(0);
		res(3*i+1) := insVec.data(i).physicalArgSpec.args(1);
		res(3*i+2) := insVec.data(i).physicalArgSpec.args(2);
	end loop;
	return res;
end function;

function getVirtualDests(insVec: StageDataMulti) return RegNameArray is
	variable res: RegNameArray(0 to insVec.fullMask'length-1) := (others=>(others=>'0'));
begin
	for i in insVec.fullMask'range loop
		res(i) := insVec.data(i).virtualArgSpec.dest(4 downto 0);
	end loop;
	return res;
end function;		

function getPhysicalDests(insVec: StageDataMulti) return PhysNameArray is
	variable res: PhysNameArray(0 to insVec.fullMask'length-1) := (others=>(others=>'0'));
begin
	for i in insVec.fullMask'range loop
		res(i) := insVec.data(i).physicalArgSpec.dest;
	end loop;
	return res;
end function;


function getDestMask(insVec: StageDataMulti) return std_logic_vector is
	variable res: std_logic_vector(insVec.fullMask'range) := (others=>'0');
begin
	for i in insVec.fullMask'range loop
		res(i) := insVec.fullMask(i) 
				and insVec.data(i).virtualArgSpec.intDestSel				
				and isNonzero(insVec.data(i).virtualArgSpec.dest(4 downto 0));
	end loop;			
	return res;
end function;


function findOverriddenDests(insVec: StageDataMulti) return std_logic_vector is
	variable res: std_logic_vector(insVec.fullMask'range) := (others=>'0');
	variable em: std_logic_vector(insVec.fullMask'range) := (others => '0');
begin
	em := getExceptionMask(insVec);
	for i in insVec.fullMask'range loop
		for j in insVec.fullMask'range loop
			if 		j > i and insVec.fullMask(j) = '1' and em(j) = '0' -- CAREFUL: if exception, doesn't write
				and insVec.data(i).virtualArgSpec.dest(4 downto 0) = insVec.data(j).virtualArgSpec.dest(4 downto 0)
			then				
				res(i) := '1';
			end if;
		end loop;
	end loop;			
	return res;
end function;


function getPhysicalDestMask(insVec: StageDataMulti) return std_logic_vector is
	variable res: std_logic_vector(insVec.fullMask'range) := (others=>'0');
begin
	for i in insVec.fullMask'range loop
		res(i) := insVec.data(i).physicalArgSpec.intDestSel;
	end loop;			
	return res;
end function;

function getExceptionMask(insVec: StageDataMulti) return std_logic_vector is
	variable res: std_logic_vector(insVec.fullMask'range) := (others=>'0');
begin
	for i in insVec.fullMask'range loop
		res(i) := insVec.data(i).controlInfo.hasException;
	end loop;			
	return res;
end function;


function getWrittenTags(lastCommitted: StageDataMulti) return PhysNameArray is
	variable writtenTags: PhysNameArray(0 to PIPE_WIDTH-1) := (others=>(others=>'0'));	
begin	
	for i in 0 to PIPE_WIDTH-1 loop -- Slots in writeback stage
		writtenTags(i) := lastCommitted.data(i).physicalArgSpec.dest;
	end loop;	
	return writtenTags;
end function;


function getResultTags(execOutputs: InstructionSlotArray; stageDataCQ: InstructionSlotArray;
							  lastCommitted: StageDataMulti)
return PhysNameArray is
	variable resultTags: PhysNameArray(0 to N_RES_TAGS-1) := (others=>(others=>'0'));	
begin
	-- CAREFUL! Remember tht empty slots should have 0 as result tag, even though the rest of 
	--				their state may remain invalid for simplicity!
	resultTags(0) := execOutputs(0).ins.physicalArgSpec.dest;
	resultTags(1) := execOutputs(1).ins.physicalArgSpec.dest;													
	resultTags(2) := execOutputs(2).ins.physicalArgSpec.dest;

	-- CQ slots
	for i in 0 to CQ_SIZE-1 loop 
		resultTags(4-1 + i) := stageDataCQ(i).ins.physicalArgSpec.dest;		
	end loop;
	return resultTags;
end function;		

function getNextResultTags(execOutputsPre: InstructionSlotArray;
						schedOutputArr: SchedulerEntrySlotArray
						) 
return PhysNameArray is
	variable nextResultTags: PhysNameArray(0 to N_NEXT_RES_TAGS-1) := (others=>(others=>'0'));
begin
	nextResultTags(0) := schedOutputArr(0).ins.physicalArgSpec.dest;
	nextResultTags(1) := execOutputsPre(1).ins.physicalArgSpec.dest;
	nextResultTags(2) := execOutputsPre(2).ins.physicalArgSpec.dest;
	return nextResultTags;
end function;


function getResultValues(execOutputs: InstructionSlotArray; 
						stageDataCQ: InstructionSlotArray;
						lastCommitted: StageDataMulti)
return MwordArray is
	variable resultVals: MwordArray(0 to N_RES_TAGS-1) := (others=>(others=>'0'));		
begin
	resultVals(0) := execOutputs(0).ins.result;
	resultVals(1) := execOutputs(1).ins.result;
	resultVals(2) := execOutputs(2).ins.result;
			
	for i in 0 to CQ_SIZE-1 loop 	-- CQ slots
		resultVals(4-1 + i) := stageDataCQ(i).ins.result;  	
	end loop;
	return resultVals;
end function;	


	function getLastEffective(newContent: StageDataMulti) return InstructionState is
		variable res: InstructionState := newContent.data(0);
	begin
		-- Seeking from right side cause we need the last one 
		for i in newContent.fullMask'range loop
			-- Count only full instructions
			if newContent.fullMask(i) = '1' then
				res := newContent.data(i);
			else
				exit;
			end if;
			
			-- If this one has an event, following ones don't count
			if 	newContent.data(i).controlInfo.hasException = '1'
				or newContent.data(i).controlInfo.specialAction = '1'	-- CAREFUL! This also breaks flow!
				or newContent.data(i).controlInfo.dbtrap = '1'
			then 
				res.controlInfo.newEvent := '1'; -- Announce that event is to happen now!
				exit;
			end if;
			
		end loop;
		return res;
	end function;

	function getEffectiveMask(newContent: StageDataMulti) return std_logic_vector is
		variable res: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
	begin
		-- Seeking from right side cause we need the last one 
		for i in newContent.fullMask'range loop
			if newContent.fullMask(i) = '1' then -- Count only full instructions
				res(i) := '1';
			else
				exit;
			end if;
			
			-- CAREFUL, TODO: what if there's a branch (or branch correction) and valid path after it??
			-- If this one has an event, following ones don't count
			if 	newContent.data(i).controlInfo.hasException = '1'
				or newContent.data(i).controlInfo.specialAction = '1'
				or newContent.data(i).controlInfo.dbtrap = '1'
			then
				exit;
			end if;
			
		end loop;
		return res;
	end function;
	
	function killByTag(before, ei, int: std_logic) return std_logic is
	begin
		return (before and ei) or int;
	end function;


function getSendingFromCQ(livingMask: std_logic_vector) return std_logic_vector is
	variable res: std_logic_vector(0 to PIPE_WIDTH-1) := (others=>'0');
begin
	for i in 0 to PIPE_WIDTH-1 loop
		if livingMask(i) = '1' then
			res(i) := '1';
		else
			exit;
		end if;
	end loop;	
	return res;
end function;


function stageCQNext_New(content: StageDataCommitQueue; newContent: InstructionStateArray;
		livingMask: std_logic_vector;
		ready: std_logic_vector;
		outWidth: integer;
		nFull, nOut, nIn: integer)
return StageDataCommitQueue is
	variable res: StageDataCommitQueue := (fullMask => (others=>'0'), 
														data => (others=>defaultInstructionState));
	variable dataTemp: InstructionStateArray(0 to CQ_SIZE-1) := (others => defaultInstructionState);
	variable fullMaskTemp: std_logic_vector(0 to CQ_SIZE-1) := (others => '0');
		
	variable newFullMask: std_logic_vector(0 to content.fullMask'length-1) := (others => '0');
		constant CLEAR_EMPTY_SLOTS_CQ: boolean := false;
		
	variable newCompactedData: InstructionStateArray(0 to 3);
	variable newCompactedMask: std_logic_vector(0 to 3);
begin
	newCompactedData := newContent;
	newCompactedMask := ready;
	-- CAREFUL: even when not clearing empty slots, result tags probably should be cleared!
	--				It's to prevent reading of fake results from empty slots
	if not CLEAR_EMPTY_SLOTS_CQ then
	end if;
		
	dataTemp := content.data(1 to CQ_SIZE-1) & newContent(newContent'right); 		
	fullMaskTemp := content.fullMask(1 to CQ_SIZE-1) & '0';
	
	for i in 0 to content.fullMask'length-1 loop
		if newCompactedMask(i) = '1' then
			dataTemp(i) := newCompactedData(i);
			fullMaskTemp(i) := '1';
		end if;
	end loop;
	
	res.data := dataTemp(0 to CQ_SIZE-1);
	res.fullMask := fullMaskTemp(0 to CQ_SIZE-1);
		
	-- CAREFUL! Clearing tags in empty slots, to avoid incorrect info about available results!
	for i in 0 to res.fullMask'length-1 loop
		if res.fullMask(i) = '0' then
			res.data(i).physicalArgSpec.dest := (others => '0');
		end if;
		
		-- TEMP: also clear unneeded data for all instructions
		res.data(i).constantArgs := defaultConstantArgs; -- c0 needed for sysMtc if not using temp reg in Exec
		--res.data(i).argValues := defaultArgValues;
		res.data(i).ip := (others => '0');
		res.data(i).bits := (others => '0');
	end loop;
	
	return res;		
end function;


function getPhysicalSources(ins: InstructionState) return PhysNameArray is
	variable res: PhysNameArray(0 to 2) := (others => (others => '0'));
begin
	res := (0 => ins.physicalArgSpec.args(0), 1 => ins.physicalArgSpec.args(1), 2 => ins.physicalArgSpec.args(2));			
	return res;
end function;

function clearTempControlInfoSimple(ins: InstructionState) return InstructionState is
	variable res: InstructionState := ins;
begin
	res.controlInfo.newEvent := '0';
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


function getKillMask(content: InstructionStateArray; fullMask: std_logic_vector;
							causing: InstructionState; execEventSig: std_logic; lateEventSig: std_logic)
return std_logic_vector is
	variable res: std_logic_vector(0 to fullMask'length-1);
	variable diff: SmallNumber := (others => '0');
begin
	for i in 0 to fullMask'length-1 loop
		res(i) := killByTag(CMP_tagBefore(causing.tags.renameIndex, content(i).tags.renameIndex),
									execEventSig, lateEventSig) and fullMask(i);
	end loop;
	return res;
end function;

function setInstructionIP(ins: InstructionState; ip: Mword) return InstructionState is
	variable res: InstructionState := ins;
begin
	res.ip := ip;
	return res;
end function;

function setInstructionTarget(ins: InstructionState; target: Mword) return InstructionState is
	variable res: InstructionState := ins;
begin
	res.target := target;
	return res;
end function;

function setInsResult(ins: InstructionState; result: Mword) return InstructionState is
	variable res: InstructionState := ins;
begin
	res.result := result;
	return res;
end function;

	function isLoad(ins: InstructionState) return std_logic is
	begin
		return bool2std(ins.operation.func = load);
	end function;
	
	function isSysRegRead(ins: InstructionState) return std_logic is
	begin
		return bool2std(ins.operation = (System, sysMfc));
	end function;
	
	function isStore(ins: InstructionState) return std_logic is
	begin
		return bool2std(ins.operation.func = store);
	end function;

	function isSysRegWrite(ins: InstructionState) return std_logic is
	begin
		return bool2std(ins.operation = (System, sysMtc));
	end function;

function getAddressIncrement(ins: InstructionState) return Mword is
	variable res: Mword := (others => '0');
begin
	if ins.classInfo.short = '1' then
		res(1) := '1'; -- 2
	else
		res(2) := '1'; -- 4
	end if;
	return res;
end function;

function trgForBQ(insVec: StageDataMulti) return StageDataMulti is
	variable res: StageDataMulti := insVec;
	variable result, target: Mword;
begin
	for i in 0 to PIPE_WIDTH-1 loop
		target := res.data(i).target;
		result := res.data(i).result;
		res.data(i) := setStoredArg1(res.data(i), target);
		res.data(i) := setStoredArg2(res.data(i), result);
	end loop;
	
	return res;
end function;

end GeneralPipeDev;
