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
	
end GeneralPipeDev;
