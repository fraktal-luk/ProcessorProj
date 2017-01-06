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


-- TODO: move logging and checking to another file
------------
-- Logging and checking
---------

function makeLogPath(str: string) return string;

-- CAREFUL: synthesis is turned of in this case because including std.textio.all somehow
--				causes additional 3% logic utilization
-- pragma synthesis off
procedure logArrayImplem(insArr: InstructionStateArray; full, living: std_logic_vector;
								 filename: string; desc: string);
-- pragma synthesis on

procedure logArray(insArr: InstructionStateArray; full, living: std_logic_vector;
						 filename: string; desc: string);

procedure logSimple(signal stageData: in InstructionState; fr: FlowResponseSimple);

procedure logBuffer(signal data: InstructionStateArray; fullMask, livingMask: std_logic_vector;
							flowResponse: FlowResponseBuffer);

procedure logMulti(signal data: InstructionStateArray; fullMask, livingMask: std_logic_vector;
							flowResponse: FlowResponseSimple);

procedure checkBuffer(bufferData: InstructionStateArray; fullMask: std_logic_vector;
							 bufferDataNext: InstructionStateArray; fullMaskNext: std_logic_vector;
							 bufferDrive: FlowDriveBuffer; bufferResponse: FlowResponseBuffer);

procedure checkSimple(ins, insNext: InstructionState;
							 flowDrive: FlowDriveSimple; flowResponse: FlowResponseSimple);

procedure checkMulti(stageData, stageDataNext: StageDataMulti;
							flowDrive: FlowDriveSimple; flowResponse: FlowResponseSimple);

procedure checkIQ(bufferData: InstructionStateArray; fullMask: std_logic_vector; 
						bufferDataNext: InstructionStateArray; fullMaskNext: std_logic_vector;
						insSending: InstructionState; sending: std_logic;
						bufferDrive: FlowDriveBuffer; bufferResponse: FlowResponseBuffer);
-------------------------------
-- End of logging and checking
---------

function makeSlotArray(insVec: InstructionStateArray; mask: std_logic_vector) return InstructionSlotArray;

function extractFullMask(queueContent: InstructionSlotArray) return std_logic_vector;
function extractData(queueContent: InstructionSlotArray) return InstructionStateArray;

function moveQueue(content, newContent: InstructionSlotArray; nFull, nOut, nIn: integer)
return InstructionSlotArray;

function selectFromQueue(content: InstructionSlotArray; index: integer) return InstructionSlot;

function removeFromQueue(content: InstructionSlotArray; index: integer) return InstructionSlotArray;


function stageSimpleNext(content, newContent: InstructionState; full, sending, receiving: std_logic)
return InstructionState;

function stageMultiNext(livingContent, newContent: StageDataMulti; full, sending, receiving: std_logic)
return StageDataMulti;

function stageMultiHandleKill(content: StageDataMulti; 
										killAll: std_logic; killVec: std_logic_vector) 
										return StageDataMulti;
-----------------------									
				
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
		

	
-- FORWARDING NETWORK ------------
function getWrittenTags(lastCommitted: StageDataMulti) return PhysNameArray;

function getResultTags(execEnds: InstructionStateArray;
			stageDataCQ: StageDataCommitQueue;
			dispatchDataA, dispatchDataB, dispatchDataC, dispatchDataD: InstructionState;
			lastCommitted: StageDataMulti) 
return PhysNameArray;

function getNextResultTags(execPreEnds: InstructionStateArray;
			dispatchDataA, dispatchDataB, dispatchDataC, dispatchDataD: InstructionState) 
return PhysNameArray;
	
function getResultValues(execEnds: InstructionStateArray; 
										stageDataCQ: StageDataCommitQueue;
										lastCommitted: StageDataMulti)
return MwordArray;	
			
	function getLastFull(newContent: StageDataMulti) return InstructionState;

	function killByTag(before, ei, int: std_logic) return std_logic;
	
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


function getInstructionResults(insVec: StageDataMulti) return MwordArray is
	variable res: MwordArray(0 to PIPE_WIDTH-1) := (others => (others => '0'));
begin
	for i in insVec.fullMask'range loop
		res(i) := insVec.data(i).result;
		res(i) := insVec.data(i).result;
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
begin
	for i in insVec.fullMask'range loop
		for j in insVec.fullMask'range loop
			if j > i and insVec.data(i).virtualDestArgs.d0 = insVec.data(j).virtualDestArgs.d0 then
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
		res(i) := insVec.fullMask(i) 
				and insVec.data(i).physicalDestArgs.sel(0);
	end loop;			
	return res;
end function;

function getExceptionMask(insVec: StageDataMulti) return std_logic_vector is
	variable res: std_logic_vector(insVec.fullMask'range) := (others=>'0');
begin
	for i in insVec.fullMask'range loop
		res(i) := insVec.fullMask(i) 
				and insVec.data(i).controlInfo.newException;
	end loop;			
	return res;
end function;


function getWrittenTags(lastCommitted: StageDataMulti) return PhysNameArray is
	variable writtenTags: PhysNameArray(0 to PIPE_WIDTH-1) := (others=>(others=>'0'));	
begin	
	-- Slots in writeback stage
	for i in 0 to PIPE_WIDTH-1 loop
		writtenTags(i) := lastCommitted.data(i).physicalDestArgs.d0;
	end loop;
	
	return writtenTags;
end function;


function getResultTags(execEnds: InstructionStateArray; 
						stageDataCQ: StageDataCommitQueue;
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
	resultTags(3) := execEnds(3).physicalDestArgs.d0;			
	
	-- CQ slots
	for i in 0 to CQ_SIZE-1 loop 
		resultTags(4 + i) := stageDataCQ.data(i).physicalDestArgs.d0;  	
	end loop;

	return resultTags;

	---- Slots in writeback stage
	--for i in 0 to PIPE_WIDTH-1 loop
	--	resultTags(4 + CQ_SIZE + i) := lastCommitted.data(i).physicalDestArgs.d0;
	--end loop;			
	--
	--return resultTags;
end function;		

function getNextResultTags(execPreEnds: InstructionStateArray;
						dispatchDataA, dispatchDataB, dispatchDataC, dispatchDataD: InstructionState) 
return PhysNameArray is
	variable nextResultTags: PhysNameArray(0 to N_NEXT_RES_TAGS-1) := (others=>(others=>'0'));
begin
	nextResultTags(0) := dispatchDataA.physicalDestArgs.d0;
	
	nextResultTags(1) := execPreEnds(1).physicalDestArgs.d0;
	nextResultTags(2) := execPreEnds(2).physicalDestArgs.d0;
	
	nextResultTags(3) := dispatchDataD.physicalDestArgs.d0;	
	return nextResultTags;
end function;


function getResultValues(execEnds: InstructionStateArray; 
						stageDataCQ: StageDataCommitQueue;
						lastCommitted: StageDataMulti)
return MwordArray is
	variable resultVals: MwordArray(0 to N_RES_TAGS-1) := (others=>(others=>'0'));		
begin
	resultVals(0) := execEnds(0).result;
	resultVals(1) := execEnds(1).result;
	resultVals(2) := execEnds(2).result;
	resultVals(3) := execEnds(3).result;			
			
	-- CQ slots
	for i in 0 to CQ_SIZE-1 loop 
		resultVals(4 + i) := stageDataCQ.data(i).result;  	
	end loop;
	
	return resultVals;
	
	--for i in 0 to PIPE_WIDTH-1 loop
	--	resultVals(4 + CQ_SIZE + i) := lastCommitted.data(i).result;
	--end loop;
	--	
	--return resultVals;
end function;	
			
			
	function getLastFull(newContent: StageDataMulti) return InstructionState is
		variable res: InstructionState := defaultInstructionState;
	begin
		-- Seeking from right side cause we need the last one 
		for i in newContent.fullMask'reverse_range loop
			if newContent.fullMask(i) = '1' then
				res := newContent.data(i);				
				exit;
			end if;
		end loop;
		return res;
	end function;			
	
	function killByTag(before, ei, int: std_logic) return std_logic is
	begin
		-- Version with unified exec/interrupt event
		return before and ei;
		-- Version with separate interrupt 
		--return (before and ei) or int;
	end function;



-- TODO: move those below to another file
---------------------------------------------------------
-- Logging and checking
----------------------------------------

function makeLogPath(str: string) return string is
	variable res: string(1 to str'length) := str;
begin
	for i in res'range loop
		if res(i) = ':' then
			res(i) := '#';
		end if;
	end loop;
	
	return res & ".txt";
end function;

-- CAREFUL: synthesis is turned of in this case because including std.textio.all somehow
--				causes additional 3% logic utilization
-- pragma synthesis off
procedure logArrayImplem(insArr: InstructionStateArray; full, living: std_logic_vector;
								 filename: string; desc: string) is
   use std.textio.all;

	file outFile: text open append_mode is filename;
	variable fline: line;
begin
	write(fline, time'image(now) & ", " & desc);
	writeline(outFile, fline);
	
	for i in 0 to insArr'length-1 loop
		if full(i) = '0' then
			write(fline, "(-)");
		else
			if living(i) = '0' then
				write(fline, "x");
			end if;
			write(fline,
						  integer'image(slv2u(insArr(i).numberTag))
				& "@" & integer'image(slv2u(insArr(i).basicInfo.ip)));
		end if;
		write(fline, ", ");
		
	end loop;
	writeline(outFile, fline);
end procedure;
-- pragma synthesis on


procedure logArray(insArr: InstructionStateArray; full, living: std_logic_vector;
						 filename: string; desc: string) is
begin
	if LOG_PIPELINE then
		-- pragma synthesis off
		logArrayImplem(insArr, full, living, filename, desc);
		-- pragma synthesis on
	end if;
end procedure;


procedure logSimple(signal stageData: in InstructionState; fr: FlowResponseSimple) is	
	variable data: InstructionStateArray(0 to 0) := (0 => stageData);
	variable fullMask: std_logic_vector(0 to 0) := (0 => fr.full);
	variable livingMask: std_logic_vector(0 to 0) := (0 => fr.living);	
begin
	if fr.full = '0' then
		return;
	end if;
	logArray(data, fullMask, livingMask, --now, 
														makeLogPath(stageData'path_name), "");
		return;
end procedure;


procedure logBuffer(signal data: InstructionStateArray; fullMask, livingMask: std_logic_vector;
							flowResponse: FlowResponseBuffer) is
begin	
	if isNonzero(flowResponse.full) = '0' then
		return;
	end if;
	logArray(data, fullMask, livingMask, --now,
														makeLogPath(data'path_name), "");
end procedure;

procedure logMulti(signal data: InstructionStateArray; fullMask, livingMask: std_logic_vector;
							flowResponse: FlowResponseSimple) is	
begin	
	if flowResponse.full = '0' then
		return;
	end if;
	logArray(data, fullMask, livingMask, --now,
														makeLogPath(data'path_name), "");
end procedure;



procedure checkBuffer(bufferData: InstructionStateArray; fullMask: std_logic_vector;
							 bufferDataNext: InstructionStateArray; fullMaskNext: std_logic_vector;
							 bufferDrive: FlowDriveBuffer; bufferResponse: FlowResponseBuffer) is
	variable commonPart1, commonPart2: InstructionStateArray(bufferData'range)
		:= (others => DEFAULT_INSTRUCTION_STATE);
	variable nFull, nLiving, nFullNext, nSending, nReceiving: integer := 0;
	variable nCommon: integer := 0;
begin
	-- pragma synthesis off

	if not BASIC_CHECKS then
		return;
	end if;

	nFull := integer(slv2u(bufferResponse.full));
	nLiving := integer(slv2u(bufferResponse.living));
	nSending := integer(slv2u(bufferResponse.sending));
	nReceiving := integer(slv2u(bufferDrive.prevSending));
	
	nFullNext := nLiving + nReceiving - nSending;
	-- full, fullMask - agree?
	assert countOnes(fullMask) = nFull;
		assert countOnes(fullMask(0 to nFull-1)) = nFull; -- checking continuity	
	-- next full, fullMaskNext - agree?
	assert countOnes(fullMaskNext) = nFullNext;
		assert countOnes(fullMaskNext(0 to nFullNext-1)) = nFullNext; -- checking continuity	
	-- number of killed agrees?
		--??
	-- number of new agrees?
		-- ??
	-- ??
	
	-- Check if content is matching. Which one correspond in the 2 arrays?
		-- Get those that are living. Some of them will be shifted out (nSending),
		--	some remain. [nSending to nLiving-1] should be found in [0 to nLiving-nSending-1] in new array.
		-- 
	nCommon := nLiving - nSending;	
	for i in 0 to nCommon - 1 loop
		commonPart1(i) := bufferData(i + nSending);
		commonPart2(i) := bufferDataNext(i);
	end loop;
	
	-- CHECK: does it make sense to examine this? Should other kinds of data be compared?
	for i in 0 to nCommon-1 loop
		assert commonPart1(i).numberTag = commonPart2(i).numberTag; -- TODO: is this the right tag field?
		assert commonPart1(i).basicInfo.ip = commonPart2(i).basicInfo.ip;
	end loop;
	
	-- pragma synthesis on	
end procedure;


procedure checkSimple(ins, insNext: InstructionState;
							 flowDrive: FlowDriveSimple; flowResponse: FlowResponseSimple) is
begin
	-- pragma synthesis off

	if not BASIC_CHECKS then
		return;
	end if;

	-- pragma synthesis on
end procedure;

procedure checkMulti(stageData, stageDataNext: StageDataMulti;
							flowDrive: FlowDriveSimple; flowResponse: FlowResponseSimple) is
	variable nFull: integer := 0;
begin
	-- pragma synthesis off

	if not BASIC_CHECKS then
		return;
	end if;

	-- If flowResponse shows full, the mask can't be empty?

	-- If stalled, new content must match the old? (Already guaranteed by stageMultiNext?),
	--					...
	
	nFull:= countOnes(stageData.fullMask);
	if flowResponse.full = '1' then
		assert countOnes(stageData.fullMask(0 to nFull-1)) = nFull; -- check continuity of mask?
	end if;
	-- pragma synthesis on	
end procedure;

procedure checkIQ(bufferData: InstructionStateArray; fullMask: std_logic_vector; 
						bufferDataNext: InstructionStateArray; fullMaskNext: std_logic_vector;
						insSending: InstructionState; sending: std_logic;
						bufferDrive: FlowDriveBuffer; bufferResponse: FlowResponseBuffer) is
	variable commonPart1, commonPart2: InstructionStateArray(bufferData'range)
		:= (others => DEFAULT_INSTRUCTION_STATE);
	variable nFull, nLiving, nFullNext, nSending, nReceiving: integer := 0;
	variable nCommon: integer := 0;
	variable move: integer:= 0;
	variable insSendingMatch: InstructionState := DEFAULT_INSTRUCTION_STATE;
begin
	-- pragma synthesis off

	if not BASIC_CHECKS then
		return;
	end if;

	nFull := integer(slv2u(bufferResponse.full));
	nLiving := integer(slv2u(bufferResponse.living));
	nSending := integer(slv2u(bufferResponse.sending));
	nReceiving := integer(slv2u(bufferDrive.prevSending));
	
	nFullNext := nLiving + nReceiving - nSending;
	-- full, fullMask - agree?
	assert countOnes(fullMask) = nFull;
		assert countOnes(fullMask(0 to nFull-1)) = nFull; -- checking continuity		
	-- next full, fullMaskNext - agree?
	assert countOnes(fullMaskNext) = nFullNext;
		assert countOnes(fullMaskNext(0 to nFullNext-1)) = nFullNext; -- checking continuity	
	-- number of killed agrees?
		--??
	-- number of new agrees?
		-- ??
	-- ??
	
	
	-- CAREFUL: in IQ sending is from any living slot, not just the first. Deal with this here!
	-- Check if content is matching. Which one correspond in the 2 arrays?
		-- Get those that are living. Some of them will be shifted out (nSending),
		--	some remain. [nSending to nLiving-1] should be found in [0 to nLiving-nSending-1] in new array.
		-- 
	nCommon := nLiving - nSending;	
	for i in 0 to nLiving - 1 loop
		-- In old array we have to skip the op that is being sent
		if sending = '1' and bufferData(i).numberTag = insSending.numberTag 
			then -- CAREFUL: is this the right tag field?
			move := 1;
					--report "rtttt";
			insSendingMatch := bufferData(i);
			-- Check the op that is sent?
			assert insSendingMatch.numberTag = insSending.numberTag; -- TODO: is this the right tag field?
			assert insSendingMatch.basicInfo.ip = insSending.basicInfo.ip;		
		end if;
		
		-- If we have visited all living instructions in old array, we break, because 
		--		it one less is copied to commonPart1, not all of them. Otherwise we could go out of array!
		if i + move >= nLiving - 1 then
			exit;
		end if;
				
		commonPart1(i) := bufferData(i + move);
		commonPart2(i) := bufferDataNext(i);		
	end loop;
	
	-- CHECK: does it make sense to examine this? Should other kinds of data be compared?
	for i in 0 to nCommon-1 loop
		assert commonPart1(i).numberTag = commonPart2(i).numberTag; -- TODO: is this the right tag field?
		assert commonPart1(i).basicInfo.ip = commonPart2(i).basicInfo.ip;
	end loop;
	
	-- pragma synthesis on	
end procedure;


end GeneralPipeDev;
