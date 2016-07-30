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
-- This works on physical arg selection bits, assuming that checking for r0/p0 was done earlier. 
function getPhysicalDestMask(insVec: StageDataMulti) return std_logic_vector;
	
function getExceptionMask(insVec: StageDataMulti) return std_logic_vector;
		

	
-- FORWARDING NETWORK ------------
function getResultTags(execEnds: InstructionStateArray;
			--execData: ExecDataTable;
			stageDataCQ: StageDataCommitQueue;
			dispatchDataA, dispatchDataB, dispatchDataC, dispatchDataD: InstructionState;
			renamedDataPrev: StageDataMulti;
			readyRegsPrev: std_logic_vector;
			lastCommitted: StageDataMulti) 
return PhysNameArray;

function getNextResultTags(execPreEnds: InstructionStateArray;
			--execData: ExecDataTable;
			dispatchDataA, dispatchDataB, dispatchDataC, dispatchDataD: InstructionState) 
return PhysNameArray;
	
function getResultValues(execEnds: InstructionStateArray; 
										stageDataCQ: StageDataCommitQueue;
										lastCommitted: StageDataMulti;
										regValues: MwordArray)
return MwordArray;	
	-----------------------					
	
	-- CAREFUL: 'getHardTarget' safe to use?
	
	-- COMMIT
	function getHardTarget(newContent: StageDataMulti) return InstructionBasicInfo;		
	-- COMMIT
	function getLastFull(newContent: StageDataMulti) return InstructionState;
	
end GeneralPipeDev;



package body GeneralPipeDev is


function stageSimpleNext(content, newContent: InstructionState; full, sending, receiving: std_logic)
return InstructionState is 
	variable res: InstructionState := defaultInstructionState;
begin
	if receiving = '1' then -- take full
		res := newContent;
	elsif sending = '1' then -- take empty
		-- CAREFUL, TODO: omitting this clearing would spare some logic, but clearing of result tag is needed!
		--						Otherwise following instructions would read results form empty slots!
		res := defaultInstructionState;
	else -- stall
		if full = '1' then
			res := content;
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


function getResultTags(execEnds: InstructionStateArray; 
						--execData: ExecDataTable;
						stageDataCQ: StageDataCommitQueue;
						dispatchDataA, dispatchDataB, dispatchDataC, dispatchDataD: InstructionState;
						renamedDataPrev: StageDataMulti;
						readyRegsPrev: std_logic_vector;
						lastCommitted: StageDataMulti) 
return PhysNameArray is
	variable resultTags: PhysNameArray(0 to N_RES_TAGS-1) := (others=>(others=>'0'));
	
	variable regsAllow: std_logic_vector(0 to 3*PIPE_WIDTH-1) := (others => '0');
	
	constant IND_BASE: integer := 4 + CQ_SIZE;
	
	constant PRE_IQ_REG_READ: boolean := PRE_IQ_REG_READING;
	constant DISPATCH_REG_READ: boolean := not PRE_IQ_REG_READ;
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

	regsAllow := extractReadyRegBits(readyRegsPrev, renamedDataPrev.data);

	if PRE_IQ_REG_READ then
	
		for i in 0 to PIPE_WIDTH-1 loop
			resultTags(4 + CQ_SIZE + i) := lastCommitted.data(i).physicalDestArgs.d0;
		end loop;
		
		for i in 0 to PIPE_WIDTH-1 loop
			if regsAllow(3*i + 0) = '1' then
				resultTags(4 + CQ_SIZE + PIPE_WIDTH + 3*i + 0) := renamedDataPrev.data(i).physicalArgs.s0;
			end if;
			
			if regsAllow(3*i + 1) = '1' then
				resultTags(4 + CQ_SIZE + PIPE_WIDTH + 3*i + 1) := renamedDataPrev.data(i).physicalArgs.s1;			
			end if;
			
			if regsAllow(3*i + 2) = '1' then
				resultTags(4 + CQ_SIZE + PIPE_WIDTH + 3*i + 2) := renamedDataPrev.data(i).physicalArgs.s2;			
			end if;	
		end loop;
		
	end if;	

	if	DISPATCH_REG_READ then
	-- ?? Newly read registers. TODO: add actual register reading, cause this is just tmp tag forwarding!
		--	CAREFUL: do we even need 'prevDataASel0' when we have DispatchA data?
		-- TODO: eliminate those tags that would double others (don't read reg if it's already in network)
		--			> And probably it would be impossible to read it from reg file if still in forw network!				
		resultTags(IND_BASE + 0) := dispatchDataA.physicalArgs.s0; -- prevDataASel0.physicalArgs.s0;
		resultTags(IND_BASE + 1) := dispatchDataA.physicalArgs.s1; -- prevDataASel0.physicalArgs.s1;		
		resultTags(IND_BASE + 2) := dispatchDataA.physicalArgs.s2;
		
		resultTags(IND_BASE + 3) := dispatchDataB.physicalArgs.s0; -- prevDataASel0.physicalArgs.s0;
		resultTags(IND_BASE + 4) := dispatchDataB.physicalArgs.s1; -- prevDataASel0.physicalArgs.s1;		
		resultTags(IND_BASE + 5) := dispatchDataB.physicalArgs.s2;
			
		resultTags(IND_BASE + 6) := dispatchDataC.physicalArgs.s0; -- prevDataASel0.physicalArgs.s0;
		resultTags(IND_BASE + 7) := dispatchDataC.physicalArgs.s1; -- prevDataASel0.physicalArgs.s1;		
		resultTags(IND_BASE + 8) := dispatchDataC.physicalArgs.s2;
		
		resultTags(IND_BASE + 9) := dispatchDataD.physicalArgs.s0; -- prevDataASel0.physicalArgs.s0;
		resultTags(IND_BASE + 10) := dispatchDataD.physicalArgs.s1; -- prevDataASel0.physicalArgs.s1;		
		resultTags(IND_BASE + 11) := dispatchDataD.physicalArgs.s2;
	end if;
	
	return resultTags;
end function;		

function getNextResultTags(execPreEnds: InstructionStateArray;
						--execData: ExecDataTable;
						dispatchDataA, dispatchDataB, dispatchDataC, dispatchDataD: InstructionState) 
return PhysNameArray is
	variable nextResultTags: PhysNameArray(0 to N_NEXT_RES_TAGS-1) := (others=>(others=>'0'));
begin
	nextResultTags(0) := dispatchDataA.physicalDestArgs.d0;
	--nextResultTags(1) := execData(ExecB1).physicalDestArgs.d0; 
	--nextResultTags(2) := execData(ExecC1).physicalDestArgs.d0; 
	nextResultTags(3) := dispatchDataD.physicalDestArgs.d0;
		nextResultTags(1) := execPreEnds(1).physicalDestArgs.d0;
		nextResultTags(2) := execPreEnds(2).physicalDestArgs.d0;
	return nextResultTags;
end function;


function getResultValues(execEnds: InstructionStateArray; 
						stageDataCQ: StageDataCommitQueue;
						lastCommitted: StageDataMulti;
						regValues: MwordArray)
return MwordArray is
	variable resultVals: MwordArray(0 to N_RES_TAGS-1) := (others=>(others=>'0'));
	
	constant IND_BASE: integer := 4 + CQ_SIZE;
	
	constant PRE_IQ_REG_READ: boolean := PRE_IQ_REG_READING;
	constant DISPATCH_REG_READ: boolean := not PRE_IQ_REG_READ;		
begin
		resultVals(0) := execEnds(0).result;
		resultVals(1) := execEnds(1).result;
		resultVals(2) := execEnds(2).result;
		resultVals(3) := execEnds(3).result;			
			
	-- CQ slots
	for i in 0 to CQ_SIZE-1 loop 
		resultVals(4 + i) := stageDataCQ.data(i).result;  	
	end loop;

	if PRE_IQ_REG_READ then
	
		for i in 0 to PIPE_WIDTH-1 loop
			resultVals(4 + CQ_SIZE + i) := lastCommitted.data(i).result;
		end loop;
		
		for i in 0 to PIPE_WIDTH-1 loop
			-- 3 for each instruction slot
			resultVals(4 + CQ_SIZE + PIPE_WIDTH + 3*i + 0) := regValues(3*i + 0);
			resultVals(4 + CQ_SIZE + PIPE_WIDTH + 3*i + 1) := regValues(3*i + 1);
			resultVals(4 + CQ_SIZE + PIPE_WIDTH + 3*i + 2) := regValues(3*i + 2);
			--resultVals(4 + CQ_SIZE + PIPE_WIDTH + 3*i + 0) := execEnds(0).bits;
			--resultVals(4 + CQ_SIZE + PIPE_WIDTH + 3*i + 1) := execEnds(1).bits;
			--resultVals(4 + CQ_SIZE + PIPE_WIDTH + 3*i + 2) := execEnds(2).bits;				
		end loop;
		
	end if;	

	if	DISPATCH_REG_READ then
		for i in 0 to 11 loop
			resultVals(IND_BASE + 0) := regValues(i);	
		end loop;
	end if;		
	
	return resultVals;
end function;	
			
			
	function getHardTarget(newContent: StageDataMulti) return InstructionBasicInfo is
		variable res: InstructionBasicInfo := defaultBasicInfo;
	begin
		-- Seeking form right side cause we need the last one 
		for i in newContent.fullMask'reverse_range loop
			if newContent.fullMask(i) = '1' then
				-- TODO, CAREFUL: eliminate use of 'getInstructionTarget' cause it sets exc trg. as branch trg.? 
				--res := [getInstructionTarget](newContent.data(i));				
				exit;
			end if;
		end loop;
		return res;
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
		
end GeneralPipeDev;
