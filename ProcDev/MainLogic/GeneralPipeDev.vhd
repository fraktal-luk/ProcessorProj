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



package GeneralPipeDev is

function getTagHigh(tag: std_logic_vector) return std_logic_vector;
function getTagLow(tag: std_logic_vector) return std_logic_vector;
function getTagHighSN(tag: SmallNumber) return SmallNumber;
function getTagLowSN(tag: SmallNumber) return SmallNumber;	
function clearTagLow(tag: std_logic_vector) return std_logic_vector;	
function clearTagHigh(tag: std_logic_vector) return std_logic_vector;	
function alignAddress(adr: std_logic_vector) return std_logic_vector;
function clearLowBits(vec: std_logic_vector; n: integer) return std_logic_vector;
function getLowBits(vec: std_logic_vector; n: integer) return std_logic_vector;

constant INITIAL_GROUP_TAG: SmallNumber := (others => '0');

constant INITIAL_PC: Mword := i2slv(-PIPE_WIDTH*4, MWORD_SIZE);

constant INITIAL_BASIC_INFO: InstructionBasicInfo := (ip => INITIAL_PC,
																		systemLevel => (others => '0'),
																		intLevel => (others => '0'));																		

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
	resultValues: MwordArray(0 to N_RES_TAGS-1);
end record;

constant DEFAULT_FORWARDING_INFO: ForwardingInfo := (
	writtenTags => (others => (others => '0')),
	resultTags => (others => (others => '0')),
	nextResultTags => (others => (others => '0')),
	resultValues => (others => (others => '0'))
);


type StageMultiEventInfo is record
	eventOccured: std_logic;
	causing: InstructionState;
	partialKillMask: std_logic_vector(0 to PIPE_WIDTH-1);
end record;

constant DEFAULT_STAGE_MULTI_EVENT_INFO: StageMultiEventInfo
													:= (eventOccured => '0',
														  causing => defaultInstructionState,
														  partialKillMask => (others => '0'));


function makeSDM(arr: InstructionSlotArray) return StageDataMulti;

function makeSlotArray(insVec: InstructionStateArray; mask: std_logic_vector) return InstructionSlotArray;

function extractFullMask(queueContent: InstructionSlotArray) return std_logic_vector;
function extractData(queueContent: InstructionSlotArray) return InstructionStateArray;

function moveQueue(content, newContent: InstructionSlotArray; nFull, nOut, nIn: integer)
return InstructionSlotArray;

function selectFromQueue(content: InstructionSlotArray; index: integer) return InstructionSlot;

function removeFromQueue(content: InstructionSlotArray; index: integer) return InstructionSlotArray;

function chooseIns(content: InstructionStateArray; which: std_logic_vector)
return InstructionState;

-- CAREFUL! This is not a general function, only a special type of compacting
function compactData(data: InstructionStateArray; mask: std_logic_vector) return InstructionStateArray;
function compactMask(data: InstructionStateArray; mask: std_logic_vector) return std_logic_vector;

function findMatching(content: InstructionSlotArray; ins: InstructionState)
return std_logic_vector;

-- TODO: is redundant, should unify with findMatching?
function findMatchingGroupTag(arr: InstructionStateArray; ins: InstructionState)
return std_logic_vector;


function stageSimpleNext(content, newContent: InstructionState; full, sending, receiving: std_logic)
return InstructionState;

function stageMultiNext(livingContent, newContent: StageDataMulti; full, sending, receiving: std_logic)
return StageDataMulti;

	function stageMultiNextCl(livingContent, newContent: StageDataMulti; full, sending, receiving: std_logic;
										clearEmptySlots: boolean)
	return StageDataMulti;


function stageMultiHandleKill(content: StageDataMulti; 
										killAll: std_logic; killVec: std_logic_vector) 
										return StageDataMulti;

function stageCQNext(content: StageDataCommitQueue; newContent: InstructionStateArray;
		livingMask: std_logic_vector;
		ready: std_logic_vector;
		outWidth: integer;
		nFull, nOut, nIn: integer)
return StageDataCommitQueue;

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

function killByTag(before, ei, int: std_logic) return std_logic;
	
-- FORWARDING NETWORK ------------
-- UNUSED
function getWrittenTags(lastCommitted: StageDataMulti) return PhysNameArray; -- DEPREC

function getResultTags(execOutputs: InstructionSlotArray;
			stageDataCQ: InstructionSlotArray;
			lastCommitted: StageDataMulti) 
return PhysNameArray;

function getNextResultTags(execOutputsPre: InstructionSlotArray;
			schedOutputArr: InstructionSlotArray)
return PhysNameArray;
	
function getResultValues(execOutputs: InstructionSlotArray; 
										stageDataCQ: InstructionSlotArray;
										lastCommitted: StageDataMulti)
return MwordArray;	
---------------------


function simpleQueueNext(content: InstructionStateArray; newContent: InstructionStateArray;
		livingMask: std_logic_vector;
		newMask: std_logic_vector;
		nFull: integer;
		sending: std_logic
)
return InstructionSlotArray;


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

function getTagHighSN(tag: SmallNumber) return SmallNumber is
	variable res: SmallNumber := (others => '0');
begin
	res(SMALL_NUMBER_SIZE-1-LOG2_PIPE_WIDTH downto 0) := tag(SMALL_NUMBER_SIZE-1 downto LOG2_PIPE_WIDTH);
	return res;
end function;

function getTagLowSN(tag: SmallNumber) return SmallNumber is
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
		if ins.groupTag = content(i).ins.groupTag and content(i).full = '1' then
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
		if arr(i).groupTag = ins.groupTag then
			res(i) := '1';
		end if;
	end loop;
	
	return res;
end function;


function stageSimpleNext(content, newContent: InstructionState; full, sending, receiving: std_logic)
return InstructionState is 
	variable res: InstructionState := --defaultInstructionState;
												content;
begin
	if receiving = '1' then -- take full
		res := newContent;
	elsif sending = '1' then -- take empty
		-- CAREFUL: omitting this clearing would spare some logic, but clearing of result tag is needed!
		--						Otherwise following instructions would read results form empty slots!
		--res := defaultInstructionState;
			res.physicalDestArgs.d0 := (others => '0'); -- CAREFUL: clear result tag!
	else -- stall
		if full = '1' then
		--	res := content;
		else
			-- leave it empty
		end if;
	end if;
	return res;
end function;

function stageMultiNext(livingContent, newContent: StageDataMulti; full, sending, receiving: std_logic)
return StageDataMulti is 
	variable res: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
		constant CLEAR_VACATED_SLOTS_GENERAL: boolean := false; 
begin
	return stageMultiNextCl(livingContent, newContent, full, sending, receiving, false);
end function;


	function stageMultiNextCl(livingContent, newContent: StageDataMulti; full, sending, receiving: std_logic;
										clearEmptySlots: boolean)
	return StageDataMulti is 
		variable res: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
			constant CLEAR_VACATED_SLOTS_GENERAL: boolean := clearEmptySlots; 
	begin
		if not CLEAR_VACATED_SLOTS_GENERAL then
			res := livingContent;
		end if;
		
		-- CAREFUL, TODO: implement selective clearing of result tags when partial kill happens!
		
		if receiving = '1' then -- take full
			res := newContent;
		elsif sending = '1' then -- take empty
			if CLEAR_VACATED_SLOTS_GENERAL then
				res := DEFAULT_STAGE_DATA_MULTI;
			end if;	

			-- CAREFUL: clearing result tags for empty slots
			for i in 0 to PIPE_WIDTH-1 loop
				res.data(i).physicalDestArgs.d0 := (others => '0');
			end loop;
		else -- stall or killed (kill can be partial)
			if full = '0' then
				-- Do nothing
				for i in 0 to PIPE_WIDTH-1 loop
					res.data(i).physicalDestArgs.d0 := (others => '0');
				end loop;
			else
				res := livingContent;
			end if;
		end if;
				
			
		return res;
	end function;


function stageMultiHandleKill(content: StageDataMulti; 
										killAll: std_logic; killVec: std_logic_vector) 
										return StageDataMulti is
	variable res: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
		constant CLEAR_KILLED_SLOTS_GENERAL: boolean := false;
begin
	if not CLEAR_KILLED_SLOTS_GENERAL then
		res.data := content.data;
	end if;
	
	if killAll = '1' then
		-- Everything gets killed, so we just leave it
	else
		res.fullMask := content.fullMask and not killVec;
		for i in res.data'range loop
			if res.fullMask(i) = '1' then
				res.data(i) := content.data(i);
			else
				-- Do nothing
			end if;
		end loop;
	end if;
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
			res(i) := ia(i).physicalDestArgs.d0; 
		end loop;
		return res;
	end function;
	
	function getArrayDestMask(ia: InstructionStateArray; fm: std_logic_vector) return std_logic_vector is
		variable res: std_logic_vector(0 to ia'length-1) := (others => '0');
	begin
		for i in 0 to res'length-1 loop
			res(i) := fm(i) and ia(i).physicalDestArgs.sel(0); 
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
		res(3*i+0) := insVec.data(i).physicalArgs.s0;
		res(3*i+1) := insVec.data(i).physicalArgs.s1;
		res(3*i+2) := insVec.data(i).physicalArgs.s2;
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
		res(i) := insVec.data(i).physicalDestArgs.d0;
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
		res(i) := insVec.data(i).physicalDestArgs.sel(0);
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
		writtenTags(i) := lastCommitted.data(i).physicalDestArgs.d0;
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
	resultTags(0) := execOutputs(0).ins.physicalDestArgs.d0;
	resultTags(1) := execOutputs(1).ins.physicalDestArgs.d0;
	resultTags(2) := execOutputs(2).ins.physicalDestArgs.d0;
	
	-- CQ slots
	for i in 0 to CQ_SIZE-1 loop 
		resultTags(4-1 + i) := stageDataCQ(i).ins.physicalDestArgs.d0;  	
	end loop;
	return resultTags;
end function;		

function getNextResultTags(execOutputsPre: InstructionSlotArray;
						schedOutputArr: InstructionSlotArray
						) 
return PhysNameArray is
	variable nextResultTags: PhysNameArray(0 to N_NEXT_RES_TAGS-1) := (others=>(others=>'0'));
begin
	nextResultTags(0) := schedOutputArr(0).ins.physicalDestArgs.d0; -- sched stage for A	
	nextResultTags(1) := execOutputsPre(1).ins.physicalDestArgs.d0;
	--nextResultTags(2) := execPreEnds(2).physicalDestArgs.d0;
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


function compactData(data: InstructionStateArray; mask: std_logic_vector) return InstructionStateArray is
	variable res: InstructionStateArray(0 to 3) := --data(0 to 3);
														(data(1), data(2), data(0), data(3));
	variable k: integer := 0;
begin
	res(k) := data(1);
	if mask(1) = '1' then
		k := k + 1;
	end if;
	
	res(k) := data(2);
	if mask(2) = '1' then
		k := k + 1;
	end if;

	res(k) := data(0);	
	if mask(0) = '1' then
		k := k + 1;
	end if;	

-- CAREFUL: not using the 4th one because branch has no register write				
--	res(k) := data(3);	
--	if mask(3) = '1' then
--		k := k + 1;
--	end if;
	
	return res;
end function;


function compactMask(data: InstructionStateArray; mask: std_logic_vector) return std_logic_vector is
	variable res: std_logic_vector(0 to 3) := (others => '0');
	variable k: integer := 0;
begin
	res(k) := mask(1);
	if mask(1) = '1' then
		k := k + 1;
	end if;
	
	res(k) := mask(2);
	if mask(2) = '1' then
		k := k + 1;
	end if;

	res(k) := mask(0);	
	if mask(0) = '1' then
		k := k + 1;
	end if;
		
-- CAREFUL: not using the 4th one because branch has no register write		
--	res(k) := mask(3);	
--	if mask(3) = '1' then
--		k := k + 1;
--	end if;
	
	return res;
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


function stageCQNext(content: StageDataCommitQueue; newContent: InstructionStateArray;
		livingMask: std_logic_vector;
		ready: std_logic_vector;
		outWidth: integer;
		nFull, nOut, nIn: integer)
return StageDataCommitQueue is
	variable res: StageDataCommitQueue := (fullMask => (others=>'0'), 
														data => (others=>defaultInstructionState));
	variable contentExtended: InstructionStateArray(0 to CQ_SIZE+4-1) := 
								content.data & newContent;
	variable dataTemp: InstructionStateArray(0 to CQ_SIZE+4-1) := (others => defaultInstructionState);
	variable fullMaskTemp: std_logic_vector(0 to CQ_SIZE+4-1) := (others => '0');
		
	variable j: integer;
	variable k: integer := 0;
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
		dataTemp := contentExtended;
	end if;	

		for i in 0 to contentExtended'length - 1 - outWidth loop
			contentExtended(i) := contentExtended(i + outWidth);
		end loop;
		
		for i in 0 to content.data'length-1 loop
			if i < nFull - nOut then
								--outWidth then
				dataTemp(i) := contentExtended(i);		
				fullMaskTemp(i) := '1';
			elsif i < nFull - nOut + 4 then
									--outWidth + 4 then
				dataTemp(i) := newCompactedData(k);
				fullMaskTemp(i) := newCompactedMask(k);
				k := k + 1;
			else
				dataTemp(i) := contentExtended(i);
			end if;
		end loop;		
		
		
	res.data := dataTemp(0 to CQ_SIZE-1);
	res.fullMask := fullMaskTemp(0 to CQ_SIZE-1);
		
	-- CAREFUL! Clearing tags in empty slots, to avoid incorrect info about available results!
	for i in 0 to res.fullMask'length-1 loop
		if res.fullMask(i) = '0' then
			res.data(i).physicalDestArgs.d0 := (others => '0');
		end if;
		
		-- TEMP: also clear unneeded data for all instructions
		--res.data(i).virtualArgs := defaultVirtualArgs;
		res.data(i).constantArgs := defaultConstantArgs; -- c0 needed for sysMtc if not using temp reg in Exec
		res.data(i).argValues := defaultArgValues;
		res.data(i).basicInfo := defaultBasicInfo;
		res.data(i).bits := (others => '0');
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
			res.data(i).physicalDestArgs.d0 := (others => '0');
		end if;
		
		-- TEMP: also clear unneeded data for all instructions
		--res.data(i).virtualArgs := defaultVirtualArgs;
		res.data(i).constantArgs := defaultConstantArgs; -- c0 needed for sysMtc if not using temp reg in Exec
		res.data(i).argValues := defaultArgValues;
		res.data(i).basicInfo := defaultBasicInfo;
		res.data(i).bits := (others => '0');
	end loop;
	
	return res;		
end function;



function getPhysicalSources(ins: InstructionState) return PhysNameArray is
	variable res: PhysNameArray(0 to 2) := (others => (others => '0'));
begin
	res := (0 => ins.physicalArgs.s0, 1 => ins.physicalArgs.s1, 2 => ins.physicalArgs.s2);			
	return res;
end function;

function clearTempControlInfoSimple(ins: InstructionState) return InstructionState is
	variable res: InstructionState := ins;
begin
	res.controlInfo.newEvent := '0';
	--res.controlInfo.newInterrupt := '0';
	--res.controlInfo.newException := '0';
	--res.controlInfo.newBranch := '0';
	--res.controlInfo.newReturn := '0';
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


function simpleQueueNext(content: InstructionStateArray; newContent: InstructionStateArray;
		livingMask: std_logic_vector;
		newMask: std_logic_vector;
		nFull: integer;
		sending: std_logic
)
return InstructionSlotArray is
	constant LEN: integer := content'length;
	constant INPUT_LEN: integer := newContent'length;
	variable res: InstructionSlotArray(0 to LEN-1) := (others => DEFAULT_INSTRUCTION_SLOT);
	variable contentExtended: InstructionStateArray(0 to LEN + INPUT_LEN - 1) := 
																				content & newContent;
	variable dataTemp: InstructionStateArray(0 to LEN + INPUT_LEN - 1) := (others => defaultInstructionState);
	variable fullMaskTemp: std_logic_vector(0 to LEN + INPUT_LEN - 1) := (others => '0');
		
	variable j: integer;
	variable k: integer := 0;
	variable newFullMask: std_logic_vector(0 to LEN-1) := (others => '0');
		constant CLEAR_EMPTY_SLOTS: boolean := false;
	variable nFullNew: integer := nFull;
begin
	-- CAREFUL: even when not clearing empty slots, result tags probably should be cleared!
	--				It's to prevent reading of fake results from empty slots

	dataTemp(0 to LEN-1) := content;
	if not CLEAR_EMPTY_SLOTS then
		dataTemp := contentExtended;
	end if;	

	if sending = '1' then
		dataTemp(0 to LEN + INPUT_LEN - 2) := dataTemp(1 to LEN + INPUT_LEN - 1);
		nFullNew := nFull-1;
	end if;
		
		for i in 0 to LEN + INPUT_LEN - 1 loop
			if i < nFullNew then
								--outWidth then
				--dataTemp(i) := contentExtended(i);		
				fullMaskTemp(i) := '1';
			elsif i < nFullNew + INPUT_LEN then
									--outWidth + 4 then
				dataTemp(i) := newContent(k);
				fullMaskTemp(i) := newMask(k);
				k := k + 1;
			else
				--dataTemp(i) := contentExtended(i);
			end if;
		end loop;		
		
		
	res := makeSlotArray(dataTemp(0 to LEN-1), fullMaskTemp(0 to LEN-1));
	
	return res;		
end function;


function getKillMask(content: InstructionStateArray; fullMask: std_logic_vector;
							causing: InstructionState; execEventSig: std_logic; lateEventSig: std_logic)
return std_logic_vector is
	variable res: std_logic_vector(0 to fullMask'length-1);
	variable diff: SmallNumber := (others => '0');
begin
	for i in 0 to fullMask'length-1 loop
		diff := subSN(causing.groupTag, content(i).groupTag); -- High bit of diff carries the info "tag is before"
		res(i) := killByTag(diff(SMALL_NUMBER_SIZE-1), execEventSig, lateEventSig) and fullMask(i);
	end loop;
	return res;
end function;

function setInstructionIP(ins: InstructionState; ip: Mword) return InstructionState is
	variable res: InstructionState := ins;
begin
	res.basicInfo.ip := ip;
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
		if ins.operation.func = load then
			return '1';
		else
			return '0';
		end if;
	end function;
	
	function isSysRegRead(ins: InstructionState) return std_logic is
	begin
		if ins.operation = (System, sysMfc) then
			return '1';
		else
			return '0';
		end if;
	end function;
	
	function isStore(ins: InstructionState) return std_logic is
	begin
		if ins.operation.func = store then
			return '1';
		else
			return '0';
		end if;
	end function;

	function isSysRegWrite(ins: InstructionState) return std_logic is
	begin
		if ins.operation = (System, sysMtc) then
			return '1';
		else
			return '0';
		end if;
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

end GeneralPipeDev;
