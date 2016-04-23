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

-- PIPE GENERAL --------------------

-- If less than all declared can be sent, decides to send nothing
--	! Based only on total numbers, not positioning
function TEMP_calcSendingZero(nextAccepting, wantSend: PipeFlow) return PipeFlow;

-- BUFFER: Here capacity/full are interpreted as binary coding, not counting '1'-s!
--	! Based only on total numbers, not positioning
-- DEPREC
function TEMP_calcSendingBuffer(nextAccepting, wantSend: PipeFlow) return PipeFlow;
-- DEPREC
function TEMP_calcSendingSimple(nextAccepting, wantSend: std_logic) return std_logic;

-- BUFFER
-- UNUSED
function TEMP_stateAfterSendingBuffer(full, sending: PipeFlow) return PipeFlow;

function TEMP_stateAfterSendingSimple(full, sending: std_logic) return std_logic;

-- UNUSED
function TEMP_calcAcceptingBuffer(canAccept, capacity, rest: PipeFlow) return PipeFlow;

function TEMP_calcAcceptingSimple(canAccept, rest: std_logic) return std_logic;

-- UNUSED
function TEMP_stateAfterReceivingBuffer(full, receiving: PipeFlow) return PipeFlow;

function TEMP_stateAfterReceivingSimple(full, receiving: std_logic) return std_logic;

-- UNUSED
procedure TEMP_defaultFlowDeclarations(capacity, full: in PipeFlow; canAccept, wantSend: out PipeFlow);

function TEMP_defaultCanAccept(capacity, full: in PipeFlow) return PipeFlow;
function TEMP_defaultWantSend(capacity, full: in PipeFlow) return PipeFlow;

--UNUSED
function TEMP_defaultCanAcceptSimple(full: std_logic) return std_logic;
-- UNUSED
function TEMP_defaultWantSendSimple(full: std_logic) return std_logic;
------------------------------



-- PIPE GENERAL -------
function stageSimpleNext(content, newContent: InstructionState; full, sending, receiving: std_logic)
return InstructionState;

function stageMultiNext(livingContent, newContent: StageDataMulti; full, sending, receiving: std_logic)
return StageDataMulti;

function stageMultiHandleKill(content: StageDataMulti; 
										killAll: std_logic; killVec: std_logic_vector) 
										return StageDataMulti;
-----------------------										
				

		

	
	-- FORWARDING NETWORK ------------
	-- TODO: [this ignores newly read registers]
	function TEMP_getResultTags(execEnds: InstructionStateArray;
				--execData: ExecDataTable;
				stageDataCQ: StageDataCommitQueue;
				dispatchDataA, dispatchDataB, dispatchDataC, dispatchDataD: InstructionState) 
	return PhysNameArray;

	-- TODO: [this too]
	function TEMP_getNextResultTags(execPreEnds: InstructionStateArray;
				--execData: ExecDataTable;
				dispatchDataA, dispatchDataB, dispatchDataC, dispatchDataD: InstructionState) 
	return PhysNameArray;
	-----------------------
	
	-- EXEC
	function getExecDataUpdated(execData: ExecDataTable;
						dispatchAUpdated, dispatchBUpdated, dispatchCUpdated, dispatchDUpdated: InstructionState)
	return ExecDataTable;
	-- EXEC
	function getExecPrevResponses(				
		execResponses: ExecResponseTable; 
		frDispatchA, frDispatchB, frDispatchC, frDispatchD: FlowResponseSimple)
	return execResponseTable;
	-- EXEC
	function getExecNextResponses(				
		execResponses: ExecResponseTable; 
		flowResponseAPost, flowResponseBPost, 
		flowResponseCPost, flowResponseDPost: FlowResponseSimple)
	return execResponseTable;					
	
	
	-- CAREFUL: 'getHardTarget' safe to use?
	
	-- COMMIT
	function getHardTarget(newContent: StageDataMulti) return InstructionBasicInfo;		
	-- COMMIT
	function getLastFull(newContent: StageDataMulti) return InstructionState;
end GeneralPipeDev;



package body GeneralPipeDev is


function TEMP_calcSendingZero(nextAccepting, wantSend: PipeFlow) return PipeFlow is
	variable res: PipeFlow := (others=>'0');
	variable a, b: natural;
begin
	a := binFlowNum(nextAccepting);
	b := binFlowNum(wantSend);
	if b > a then
		b := 0;
	end if;
	return num2flow(b, false);
end function;


function TEMP_calcSendingBuffer(nextAccepting, wantSend: PipeFlow) return PipeFlow is
	variable res: PipeFlow := (others=>'0');
	variable a,b: natural;
begin
	-- Get minimum of (nextAccepting, wantSend) positive slots
	a := binFlowNum(nextAccepting);
	b := binFlowNum(wantSend);
	if b > a then
		b := a;
	end if;
	return num2flow(b, false);
end function;


function TEMP_calcSendingSimple(nextAccepting, wantSend: std_logic) return std_logic is
begin
	return nextAccepting and wantSend;
end function;


function TEMP_stateAfterSendingBuffer(full, sending: PipeFlow) return PipeFlow is
	variable res: PipeFlow := (others=>'0');	
	variable fu, se: integer;
	variable remaining: integer;	
begin
	fu := binFlowNum(full);
	se := binFlowNum(sending);
	remaining := fu - se;
	-- CAREFUL! Use binary coding for 'full'
	res := i2slv(remaining, PipeFlow'length);
	return res;
end function;

function TEMP_stateAfterSendingSimple(full, sending: std_logic) return std_logic is
begin
	--assert (full or not sending) = '1' report "Try to send from empty?" severity warning;
	return full and not sending;
end function;


function TEMP_calcAcceptingBuffer(canAccept, capacity, rest: PipeFlow) return PipeFlow is
	variable res: PipeFlow := (others=>'0');
	variable ca, cap, fu, se: integer;
	variable remaining, free: integer;
begin
	ca := binFlowNum(canAccept);
	cap := binFlowNum(capacity);
	-- How many could be inserted?
	remaining := binFlowNum(rest); --fu - se;
	free := cap - remaining;
	-- minimum of 'free' and 'canAccept'
	if free < ca then
		ca := free;
	end if;
	
	res := i2slv(ca, PipeFlow'length); --
	return res;
end function;


function TEMP_calcAcceptingSimple(canAccept, rest: std_logic) return std_logic is
begin
	return canAccept and not rest;	
end function;

function TEMP_stateAfterReceivingBuffer(full, receiving: PipeFlow) return PipeFlow is
	variable res: PipeFlow := (others=>'0');
	variable re, fu, total: integer;	
begin
	re := binFlowNum(receiving);
	fu := binFlowNum(full);
	total := fu + re;
	res := i2slv(total, PipeFlow'length);
	return res;
end function;

function TEMP_stateAfterReceivingSimple(full, receiving: std_logic) return std_logic is
begin
	--assert (full and receiving) = '0' report "Trying to receive into full slot" severity warning;
	return full or receiving;
end function;


procedure TEMP_defaultFlowDeclarations(capacity, full: in PipeFlow; canAccept, wantSend: out PipeFlow) is
begin
	-- Declare sending whole content and accept whole capacity
	wantSend := TEMP_defaultWantSend(capacity, full);
	canAccept := TEMP_defaultCanAccept(capacity, full);	
end procedure;

function TEMP_defaultCanAccept(capacity, full: in PipeFlow) return PipeFlow is
begin
	-- TODO: what about aligning and otherwise normalizing the outputs?
	return capacity;	
end function;

function TEMP_defaultWantSend(capacity, full: in PipeFlow) return PipeFlow is
begin
	return full;   -- TODO: what about aligning and otherwise normalizing the outputs?
end function;


function TEMP_defaultCanAcceptSimple(full: std_logic) return std_logic is
begin
	return '1';
end function;

function TEMP_defaultWantSendSimple(full: std_logic) return std_logic is
begin
	return full;
end function;


function stageSimpleNext(content, newContent: InstructionState; full, sending, receiving: std_logic)
return InstructionState is 
	variable res: InstructionState := defaultInstructionState;
begin
	if receiving = '1' then -- take full
		res := newContent;
	elsif sending = '1' then -- take empty
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
	variable res: StageDataMulti := (fullMask => (others=>'0') , data =>(others => defaultInstructionState));
	--InstructionStateArray(content'range) := (others=>defaultInstructionState);
begin
	if receiving = '1' then -- take full
		res := newContent;
	elsif sending = '1' then -- take empty
		res := DEFAULT_STAGE_DATA_MULTI;
	else -- stall or killed (kill can be partial)
		if full = '0' then
			-- Do nothing: leave it empty
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
begin										
	if killAll = '1' then
		-- Everything gets killed, so we leave it empty
	else
		res.fullMask := content.fullMask and not killVec;
		for i in res.data'range loop
			if res.fullMask(i) = '1' then
				res.data(i) := content.data(i);
			else
				-- Leaving empty
			end if;
		end loop;
	end if;
	return res;
end function;


	function TEMP_getResultTags(execEnds: InstructionStateArray; 
							--execData: ExecDataTable;
							stageDataCQ: StageDataCommitQueue;
							dispatchDataA, dispatchDataB, dispatchDataC, dispatchDataD: InstructionState) 
	return PhysNameArray is
		variable resultTags: PhysNameArray(0 to N_RES_TAGS-1) := (others=>(others=>'0'));
	begin
		--resultTags(0) := execData(ExecA0).physicalDestArgs.d0; 
		--resultTags(1) := execData(ExecB2).physicalDestArgs.d0; 
		--resultTags(2) := execData(ExecC2).physicalDestArgs.d0; 
		--resultTags(3) := execData(ExecD0).physicalDestArgs.d0; 
			resultTags(0) := execEnds(0).physicalDestArgs.d0;
			resultTags(1) := execEnds(1).physicalDestArgs.d0;
			resultTags(2) := execEnds(2).physicalDestArgs.d0;
			resultTags(3) := execEnds(3).physicalDestArgs.d0;			
		-- CQ slots
		resultTags(4) := stageDataCQ.data(0).physicalDestArgs.d0; 
		resultTags(5) := stageDataCQ.data(1).physicalDestArgs.d0; 
		resultTags(6) := stageDataCQ.data(2).physicalDestArgs.d0; 
		resultTags(7) := stageDataCQ.data(3).physicalDestArgs.d0; 			
		-- ?? Newly read registers. TODO: add actual register reading, cause this is just tmp tag forwarding!
			--	CAREFUL: do we even need 'prevDataASel0' when we have DispatchA data?
			-- TODO: eliminate those tags that would double others (don't read reg if it's already in network)
			--			> And probably it would be impossible to read it from reg file if still in forw network!				
						resultTags(8) := dispatchDataA.physicalArgs.s0; -- prevDataASel0.physicalArgs.s0;
						resultTags(9) := dispatchDataA.physicalArgs.s1; -- prevDataASel0.physicalArgs.s1;		
						resultTags(10) := dispatchDataA.physicalArgs.s2;
						
						resultTags(11) := dispatchDataB.physicalArgs.s0; -- prevDataASel0.physicalArgs.s0;
						resultTags(12) := dispatchDataB.physicalArgs.s1; -- prevDataASel0.physicalArgs.s1;		
						resultTags(13) := dispatchDataB.physicalArgs.s2;
							
						resultTags(14) := dispatchDataC.physicalArgs.s0; -- prevDataASel0.physicalArgs.s0;
						resultTags(15) := dispatchDataC.physicalArgs.s1; -- prevDataASel0.physicalArgs.s1;		
						resultTags(16) := dispatchDataC.physicalArgs.s2;
						
						resultTags(17) := dispatchDataD.physicalArgs.s0; -- prevDataASel0.physicalArgs.s0;
						resultTags(18) := dispatchDataD.physicalArgs.s1; -- prevDataASel0.physicalArgs.s1;		
						resultTags(19) := dispatchDataD.physicalArgs.s2;		
		return resultTags;
	end function;
	
	function TEMP_getNextResultTags(execPreEnds: InstructionStateArray;
							--execData: ExecDataTable;
							dispatchDataA, dispatchDataB, dispatchDataC, dispatchDataD: InstructionState) 
	return PhysNameArray is
		variable nextResultTags: PhysNameArray(0 to N_RES_TAGS-1) := (others=>(others=>'0'));
	begin
		nextResultTags(0) := dispatchDataA.physicalDestArgs.d0;
		--nextResultTags(1) := execData(ExecB1).physicalDestArgs.d0; 
		--nextResultTags(2) := execData(ExecC1).physicalDestArgs.d0; 
		nextResultTags(3) := dispatchDataD.physicalDestArgs.d0;
			nextResultTags(1) := execPreEnds(1).physicalDestArgs.d0;
			nextResultTags(2) := execPreEnds(2).physicalDestArgs.d0;
		return nextResultTags;
	end function;

	-- TODO: probably useless, maybe remove
	function getExecDataUpdated(execData: ExecDataTable;
						dispatchAUpdated, dispatchBUpdated, dispatchCUpdated, dispatchDUpdated: InstructionState)
	return ExecDataTable is
		variable execDataUpdated: ExecDataTable;
	begin	
		execDataUpdated := ( 	
			ExecA0 => execData(ExecA0),
			ExecB0 => execData(ExecB0), ExecB1 => execData(ExecB1), ExecB2 => execData(ExecB2),
			ExecC0 => execData(ExecC0), ExecC1 => execData(ExecC1), ExecC2 => execData(ExecC2),
			ExecD0 => execData(ExecD0),
			others=> defaultInstructionState);		
		return execDataUpdated;
	end function;
		
	function getExecPrevResponses(execResponses: ExecResponseTable; 
											frDispatchA, frDispatchB, frDispatchC, frDispatchD: FlowResponseSimple)
	return execResponseTable is
		variable execPrevResponses: ExecResponseTable;
	begin	
		execPrevResponses := (
			ExecA0 => frDispatchA,
			ExecB0 => frDispatchB, ExecB1 => execResponses(ExecB0), ExecB2 => execResponses(ExecB1),
			ExecC0 => frDispatchC, ExecC1 => execResponses(ExecC0), ExecC2 => execResponses(ExecC1),
			ExecD0 => frDispatchD,
			others => (others=>'0'));
		return execPrevResponses;	
	end function;

	function getExecNextResponses(				
		execResponses: ExecResponseTable; 
		flowResponseAPost, flowResponseBPost, 
		flowResponseCPost, flowResponseDPost: FlowResponseSimple)
	return execResponseTable is
		variable execNextResponses: ExecResponseTable;
	begin		
		execNextResponses := (
			ExecA0 => flowResponseAPost,
			ExecB0 => execResponses(ExecB1), ExecB1 => execResponses(ExecB2),ExecB2 => flowResponseBPost,
			ExecC0 => execResponses(ExecC1), ExecC1 => execResponses(ExecC2),	ExecC2 => flowResponseCPost,
			ExecD0 => flowResponseDPost,
			others => (others=>'0'));	
		return execNextResponses;	
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
