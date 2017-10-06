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

function makeSlotArray(insVec: InstructionStateArray; mask: std_logic_vector) return InstructionSlotArray;

function extractFullMask(queueContent: InstructionSlotArray) return std_logic_vector;
function extractData(queueContent: InstructionSlotArray) return InstructionStateArray;

function moveQueue(content, newContent: InstructionSlotArray; nFull, nOut, nIn: integer)
return InstructionSlotArray;

function selectFromQueue(content: InstructionSlotArray; index: integer) return InstructionSlot;

function removeFromQueue(content: InstructionSlotArray; index: integer) return InstructionSlotArray;

-- CAREFUL! This is not a general function, only a special type of compacting
function compactData(data: InstructionStateArray; mask: std_logic_vector) return InstructionStateArray;
function compactMask(data: InstructionStateArray; mask: std_logic_vector) return std_logic_vector;

function findMatching(content: InstructionSlotArray; ins: InstructionState)
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

-----------------------									
	
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
function getWrittenTags(lastCommitted: StageDataMulti) return PhysNameArray; -- DEPREC

function getResultTags(execEnds: InstructionStateArray;
			stageDataCQ: InstructionStateArray;
			dispatchDataA, dispatchDataB, dispatchDataC, dispatchDataD: InstructionState;
			lastCommitted: StageDataMulti) 
return PhysNameArray;

function getNextResultTags(execPreEnds: InstructionStateArray;
			dispatchDataA, dispatchDataB, dispatchDataC, dispatchDataD: InstructionState) 
return PhysNameArray;
	
function getResultValues(execEnds: InstructionStateArray; 
										stageDataCQ: InstructionStateArray;
										lastCommitted: StageDataMulti)
return MwordArray;	
---------------------

-- OTHER EXEC -----------
function getExecEnds(oA, oB, oC, oD, oE: InstructionSlot) return InstructionStateArray;
function getExecEnds2(oA, oB, oC, oD, oE: InstructionSlot) return InstructionStateArray;
function getExecSending(oA, oB, oC, oD, oE: InstructionSlot) return std_logic_vector;
function getExecSending2(oA, oB, oC, oD, oE: InstructionSlot) return std_logic_vector;
function getExecPreEnds(opB, opC: InstructionState) return InstructionStateArray;
-----------------------


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

end GeneralPipeDev;



package body GeneralPipeDev is

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
		res(3*i+0) := insVec.data(i).virtualArgs.s0;
		res(3*i+1) := insVec.data(i).virtualArgs.s1;
		res(3*i+2) := insVec.data(i).virtualArgs.s2;
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
		res(i) := insVec.data(i).virtualDestArgs.d0;
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
				and insVec.data(i).virtualDestArgs.sel(0) 
				and isNonzero(insVec.data(i).virtualDestArgs.d0);
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
				and insVec.data(i).virtualDestArgs.d0 = insVec.data(j).virtualDestArgs.d0 then
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


function getResultTags(execEnds: InstructionStateArray; 
						stageDataCQ: InstructionStateArray;
						dispatchDataA, dispatchDataB, dispatchDataC, dispatchDataD: InstructionState;
						lastCommitted: StageDataMulti) 
return PhysNameArray is
	variable resultTags: PhysNameArray(0 to N_RES_TAGS-1) := (others=>(others=>'0'));	
begin
	-- CAREFUL! Remember tht empty slots should have 0 as result tag, even though the rest of 
	--				their state may remain invalid for simplicity!
	resultTags(0) := execEnds(0).physicalDestArgs.d0;
	resultTags(1) := execEnds(1).physicalDestArgs.d0;
	resultTags(2) := execEnds(2).physicalDestArgs.d0;
	
	-- CQ slots
	for i in 0 to CQ_SIZE-1 loop 
		resultTags(4-1 + i) := stageDataCQ(i).physicalDestArgs.d0;  	
	end loop;
	return resultTags;
end function;		

function getNextResultTags(execPreEnds: InstructionStateArray;
						dispatchDataA, dispatchDataB, dispatchDataC, dispatchDataD: InstructionState) 
return PhysNameArray is
	variable nextResultTags: PhysNameArray(0 to N_NEXT_RES_TAGS-1) := (others=>(others=>'0'));
begin
	nextResultTags(0) := dispatchDataA.physicalDestArgs.d0;	
	nextResultTags(1) := execPreEnds(1).physicalDestArgs.d0;
	--nextResultTags(2) := execPreEnds(2).physicalDestArgs.d0;
	return nextResultTags;
end function;


function getResultValues(execEnds: InstructionStateArray; 
						stageDataCQ: InstructionStateArray;
						lastCommitted: StageDataMulti)
return MwordArray is
	variable resultVals: MwordArray(0 to N_RES_TAGS-1) := (others=>(others=>'0'));		
begin
	resultVals(0) := execEnds(0).result;
	resultVals(1) := execEnds(1).result;
	resultVals(2) := execEnds(2).result;
			
	for i in 0 to CQ_SIZE-1 loop 	-- CQ slots
		resultVals(4-1 + i) := stageDataCQ(i).result;  	
	end loop;
	return resultVals;
end function;	

			
function getExecEnds(oA, oB, oC, oD, oE: InstructionSlot) return InstructionStateArray is
	variable res: InstructionStateArray(0 to 3) := (others => DEFAULT_INSTRUCTION_STATE);
begin
	res(0) := oA.ins;
	res(1) := oB.ins;
	res(2) := oC.ins;
	
	return res;
end function;

function getExecEnds2(oA, oB, oC, oD, oE: InstructionSlot) return InstructionStateArray is
	variable res: InstructionStateArray(0 to 3) := (others => DEFAULT_INSTRUCTION_STATE);
begin
	res(2) := oE.ins;
	res(3) := oD.ins;
	
	return res;
end function;

function getExecSending(oA, oB, oC, oD, oE: InstructionSlot) return std_logic_vector is
	variable res: std_logic_vector(0 to 3) := (others => '0');
begin
	res(0) := oA.full;
	res(1) := oB.full;
	res(2) := oC.full;
	
	return res;
end function;

function getExecSending2(oA, oB, oC, oD, oE: InstructionSlot) return std_logic_vector is
	variable res: std_logic_vector(0 to 3) := (others => '0');
begin
	res(2) := oE.full;
	res(3) := oD.full;
	
	return res;
end function;

function getExecPreEnds(opB, opC: InstructionState) return InstructionStateArray is
	variable res: InstructionStateArray(0 to 3) := (others => DEFAULT_INSTRUCTION_STATE);
begin
	res(1) := opB;
	res(2) := opC;
	
	return res;
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
		res.data(i).virtualArgs := defaultVirtualArgs;
		--	res.data(i).virtualDestArgs := defaultVirtualDestArgs;
		res.data(i).constantArgs := defaultConstantArgs; -- c0 needed for sysMtc if not using temp reg in Exec
		res.data(i).argValues := defaultArgValues;
		res.data(i).basicInfo := defaultBasicInfo;
		res.data(i).bits := (others => '0');
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


end GeneralPipeDev;
