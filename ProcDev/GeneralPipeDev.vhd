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

--use work.Renaming1.all;

use work.NewPipelineData.all;

	use work.TEMP_DEV.all;

package GeneralPipeDev is

	component SimplePipeLogic is
		port(
			clk, reset, en: in std_logic;
			--kill: in std_logic;
			flowDrive: in FlowDriveSimple;
			flowResponse: out FlowResponseSimple
		);
	end component;

	component BufferPipeLogic is
	generic (
		CAPACITY: natural := 1;
		MAX_OUTPUT: natural := 1;
		MAX_INPUT: natural := 1
	);		
		port(
			clk, reset, en: in std_logic;
			--kill: in std_logic;
			flowDrive: in FlowDriveBuffer;
			flowResponse: out FlowResponseBuffer
		);
	end component;

	component RegisterMap is
		generic(
			WIDTH: natural := 1;
			MAX_WIDTH:natural := 4
		);
		 Port ( clk : in  STD_LOGIC;
				  reset : in  STD_LOGIC;
				  en : in  STD_LOGIC;
				  rewind : in  STD_LOGIC;
				  reserveAllow : in  STD_LOGIC;
				  reserve : in  STD_LOGIC_VECTOR (0 to WIDTH-1);
				  commitAllow : in  STD_LOGIC;
				  commit : in  STD_LOGIC_VECTOR (0 to WIDTH-1);
					selectReserve: in RegNameArray(0 to WIDTH-1);
					writeReserve: in PhysNameArray(0 to WIDTH-1);
					selectCommit: in RegNameArray(0 to WIDTH-1);
					writeCommit: in PhysNameArray(0 to WIDTH-1);
					selectNewest: in RegNameArray(0 to 3*WIDTH-1);
					readNewest: out PhysNameArray(0 to 3*WIDTH-1);
					selectStable: in RegNameArray(0 to WIDTH-1);
					readStable: out PhysNameArray(0 to WIDTH-1) 			  
			  );
	end component;

	component FreeListQuad is
		generic(
			WIDTH: natural := 1;
			MAX_WIDTH:natural := 4		
		);
		 Port ( clk : in  STD_LOGIC;
				  reset : in  STD_LOGIC;
				  en : in  STD_LOGIC;
				  rewind : in  STD_LOGIC;
				  
				  writeTag: in PhysName;
				  readTags: out PhysNameArray(0 to WIDTH-1);			  
				  
				  take: in std_logic_vector(0 to WIDTH-1);
				  enableTake: in std_logic;
				  readTake: out PhysNameArray(0 to WIDTH-1);
				  
				  put: in std_logic_vector(0 to WIDTH-1);
				  enablePut: in std_logic;			  
				  writePut: in PhysNameArray(0 to WIDTH-1)
			  );
	end component;


function pc2size(pc: Mword; alignBits: natural; capacity: PipeFlow) return PipeFlow;

-- If less than all declared can be sent, decides to send nothing
--	! Based only on total numbers, not positioning
function TEMP_calcSendingZero(nextAccepting, wantSend: PipeFlow) return PipeFlow;

-- BUFFER: Here capacity/full are interpreted as binary coding, not counting '1'-s!
--	! Based only on total numbers, not positioning
function TEMP_calcSendingBuffer(nextAccepting, wantSend: PipeFlow) return PipeFlow;
function TEMP_calcSendingSimple(nextAccepting, wantSend: std_logic) return std_logic;

-- BUFFER
function TEMP_stateAfterSendingBuffer(full, sending: PipeFlow) return PipeFlow;
function TEMP_stateAfterSendingSimple(full, sending: std_logic) return std_logic;

function TEMP_calcAcceptingBuffer(canAccept, capacity, rest: PipeFlow) return PipeFlow;
function TEMP_calcAcceptingSimple(canAccept, rest: std_logic) return std_logic;

function TEMP_stateAfterReceivingBuffer(full, receiving: PipeFlow) return PipeFlow;
function TEMP_stateAfterReceivingSimple(full, receiving: std_logic) return std_logic;

procedure TEMP_defaultFlowDeclarations(capacity, full: in PipeFlow; canAccept, wantSend: out PipeFlow);
function TEMP_defaultCanAccept(capacity, full: in PipeFlow) return PipeFlow;
function TEMP_defaultWantSend(capacity, full: in PipeFlow) return PipeFlow;

function TEMP_defaultCanAcceptSimple(full: std_logic) return std_logic;
function TEMP_defaultWantSendSimple(full: std_logic) return std_logic;

-- Some functions for general pipe support 
-- // Replaced by bufferAH approach?
function bufferHwordNext(content, newContent: HwordArray; nFull, nOut, nIn: integer) return HwordArray;

function bufferAHNext(content, newContent: AnnotatedHwordArray; nFull, nOut, nIn: integer) 
return AnnotatedHwordArray;

-- UNUSED?
function bufferNext(content, newContent: PipeStageDataU; nFull, nOut, nIn: integer) return PipeStageDataU;

-- DEPREC?
function normalStageNext(content, newContent: PipeStageDataU; nFull, nOut, nIn: integer) 
				return PipeStageDataU;

function stageSimpleNext(content, newContent: InstructionState; full, sending, receiving: std_logic)
return InstructionState;

function stageMultiNext(livingContent, newContent: StageDataMulti; full, sending, receiving: std_logic)
return StageDataMulti;

function stageMultiHandleKill(content: StageDataMulti; 
										killAll: std_logic; killVec: std_logic_vector) 
										return StageDataMulti;
function stageIQNext(content, newContent: PipeStageDataU; 
							sendingMask: std_logic_vector; nFull, nOut, nIn: integer) 
return PipeStageDataU;

-- DEPREC?
function stageCQNext(content, newContent: PipeStageDataU; 
		livingMask: std_logic_vector;
		ready: std_logic_vector; routes: IntArray; nFull, nOut, nIn: integer)
return PipeStageDataU; 
-- DEPREC?
function stageCQNext2(content, newContent: PipeStageDataU; 
		livingMask: std_logic_vector;
		ready: std_logic_vector;
		vecA, vecB, vecC, vecD: std_logic_vector; 
		nFull, nOut, nIn: integer)
return PipeStageDataU;


function updateCQMask(mask: std_logic_vector; 
		ready: std_logic_vector; routes: IntArray; nFull, nOut, nIn: integer)
return std_logic_vector;
		
function stageCQNext(content: StageDataCommitQueue; newContent: InstructionStateArray;
		livingMask: std_logic_vector;
		ready: std_logic_vector; routes: IntArray; nFull, nOut, nIn: integer)
return StageDataCommitQueue;
 		
function stageCQNext2(content: StageDataCommitQueue; newContent: InstructionStateArray;
		livingMask: std_logic_vector;
		ready: std_logic_vector;
		vecA, vecB, vecC, vecD: std_logic_vector; 
		nFull, nOut, nIn: integer)
return StageDataCommitQueue;		
		
function stagePCNext(content: TEMP_StageDataPC; targetInfo: InstructionBasicInfo;
							newNH: PipeFlow;
							full, sending, receiving: std_logic) return TEMP_StageDataPC;

function stageFetchNext(content, newContent: TEMP_StageDataPC;
							full, sending, receiving: std_logic) return TEMP_StageDataPC;

function nextTargetInfo(pcData: TEMP_StageDataPC; fe: FrontEventInfo; movedIP: Mword) 
return InstructionBasicInfo;

function getAnnotatedHwords(arr: HwordArray; ip: Mword; basicInfo: InstructionBasicInfo; hEndings: MwordArray) 
return AnnotatedHwordArray;

function hwordAddressEndings return MwordArray;

	-- TODO: [this ignores newly read registers]
	function TEMP_getResultTags(execData: ExecDataTable; stageDataCQ: StageDataCommitQueue;
				dispatchDataA, dispatchDataB, dispatchDataC, dispatchDataD: InstructionState) 
	return PhysNameArray;

	-- TODO: [this too]
	function TEMP_getNextResultTags(execData: ExecDataTable;
				dispatchDataA, dispatchDataB, dispatchDataC, dispatchDataD: InstructionState) 
	return PhysNameArray;


	function getExecDataUpdated(execData: ExecDataTable;
						dispatchAUpdated, dispatchBUpdated, dispatchCUpdated, dispatchDUpdated: InstructionState)
	return ExecDataTable;

	function getExecPrevResponses(				
		execResponses: ExecResponseTable; 
		frDispatchA, frDispatchB, frDispatchC, frDispatchD: FlowResponseSimple)
	return execResponseTable;

	function getExecNextResponses(				
		execResponses: ExecResponseTable; 
		flowResponseAPost, flowResponseBPost, 
		flowResponseCPost, flowResponseDPost: FlowResponseSimple)
	return execResponseTable;			
		
		
	function getTargetInfo(ins: InstructionState) return InstructionBasicInfo;				
	function getInstructionTarget(ins: InstructionState) return InstructionBasicInfo;
	function getHardTarget(newContent: StageDataMulti) return InstructionBasicInfo;		
	function getLastFull(newContent: StageDataMulti) return InstructionState;
		
end GeneralPipeDev;



package body GeneralPipeDev is



function pc2size(pc: Mword; alignBits: natural; capacity: PipeFlow) return PipeFlow is
	variable res: PipeFlow := (others=>'0');
	variable ending: natural;
	variable cap: natural;
begin
	ending := slv2u(pc(alignBits-1 downto 0));
	-- "ending" is eq to num of bytes over aligned PC
	cap := binFlowNum(capacity);
	res := --i2slv((2*cap - ending)/2, PipeFlow'length); -- CAREFUL, ending is a number of bytes, so must >> 1
		 	 i2slv(cap - slv2u(pc(alignBits-1 downto 1)), PipeFlow'length);
			--report "new " &	integer'image(	cap - slv2u(pc(alignBits-1 downto 1)) );
			--report "old " &  integer'image((2*cap - ending)/2);
	return res;
end function;

function TEMP_calcSendingZero(nextAccepting, wantSend: PipeFlow) return PipeFlow is
	variable res: PipeFlow := (others=>'0');
	variable a,b: natural;
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



function bufferHwordNext(content, newContent: HwordArray; nFull, nOut, nIn: integer) return HwordArray is
	variable res: HwordArray(content'range) := (others=>(others=>'0'));
	variable c1, c2, c3: boolean;
	variable newShift: integer := 0; -- CAREFUL! This determines where actual data starts in newContent
begin
	--	report integer'image(nFull - nOut);
	--	report integer'image(nFull - nOut + nIn - 1);
	--	report "------";
	-- CAREFUL! Here we check this condition, cause otherwise a failure happens
	c1 := nFull-nOut <= content'length; -- report "C1 filed";
	c2 := nFull-nOut >= 0; -- report "C2 failed";
	c3 := nFull-nOut+nIn-1 <= content'length; -- report "C3 failed";
	
	if not (c1 and c2 and c3) then
		--return res;
	end if;
	
	newShift := FETCH_BLOCK_SIZE - nIn;
	
	res(0 to nFull-nOut-1) := content(nOut to nFull-1);
	res(nFull-nOut to nFull-nOut+nIn-1) := newContent(newShift to newShift + nIn - 1);
	return res;
end function;


function bufferAHNext(content, newContent: AnnotatedHwordArray; nFull, nOut, nIn: integer) 
return AnnotatedHwordArray is
	variable res: AnnotatedHwordArray(content'range) 
			:= (others=>(bits=>(others=>'0'), ip => (others=>'0'), basicInfo=>defaultBasicInfo));
	variable c1, c2, c3: boolean;
	variable newShift: integer := 0; -- CAREFUL! This determines where actual data starts in newContent
begin
	-- CAREFUL! Here we check this condition, cause otherwise a failure happens
	c1 := nFull-nOut <= content'length; -- report "C1 filed";
	c2 := nFull-nOut >= 0; -- report "C2 failed";
	c3 := nFull-nOut+nIn-1 <= content'length; -- report "C3 failed";
	
	if not (c1 and c2 and c3) then
		report "Hbuffer bad conditions: " 
					& integer'image(nFull-nOut) & " "
					& integer'image(nFull-nOut+nIn-1);
		return res;
	end if;
	
	newShift := FETCH_BLOCK_SIZE - nIn;
	
	res(0 to nFull-nOut-1) := content(nOut to nFull-1);
	res(nFull-nOut to nFull-nOut+nIn-1) := newContent(newShift to newShift + nIn - 1);
	return res;
end function;


function bufferNext(content, newContent: PipeStageDataU; nFull, nOut, nIn: integer) return PipeStageDataU is
	variable res: PipeStageDataU(content'range) := (others=>defaultInstructionState);
	variable c1, c2, c3: boolean;
begin
	--	report integer'image(nFull - nOut);
	--	report integer'image(nFull - nOut + nIn - 1);
	--	report "------";
	-- CAREFUL! Here we check this condition, cause otherwise a failure happens
	c1 := nFull-nOut <= content'length; -- report "C1 filed";
	c2 := nFull-nOut >= 0; -- report "C2 failed";
	c3 := nFull-nOut+nIn-1 <= content'length; -- report "C3 failed";
	
	if not (c1 and c2 and c3) then
		--return res;
	end if;
	--report "conditins passed";
	
	res(0 to nFull-nOut-1) := content(nOut to nFull-1);
	res(nFull-nOut to nFull-nOut+nIn-1) := newContent(0 to nIn-1);
	return res;
end function;

function normalStageNext(content, newContent: PipeStageDataU; nFull, nOut, nIn: integer)
return PipeStageDataU is 
	variable res: PipeStageDataU(content'range) := (others=>(defaultInstructionState));
begin
	if nIn /= 0 then -- take full
		res := newContent;
	elsif nOut /= 0 then -- take empty
		--res := (others=>(others=>'0'));
	else -- stall
		res := content;
	end if;
	return res;
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


function stageIQNext(content, newContent: PipeStageDataU; 
							sendingMask: std_logic_vector; nFull, nOut, nIn: integer) 
return PipeStageDataU is
	variable res: PipeStageDataU(content'range) := (others=>defaultInstructionState);
	variable c1, c2, c3: boolean;
	variable j: integer := 0;
begin
	--	report integer'image(nFull - nOut);
	--	report integer'image(nFull - nOut + nIn - 1);
	--	report "------";
	-- CAREFUL! Here we check this condition, cause otherwise a failure happens
	c1 := nFull-nOut <= content'length; -- report "C1 filed";
	c2 := nFull-nOut >= 0; -- report "C2 failed";
	c3 := nFull-nOut+nIn-1 <= content'length; -- report "C3 failed";
	
	if not (c1 and c2 and c3) then
		--return res;
	end if;
	--report "conditins passed";
	for i in 0 to res'length-1 loop -- to nFull-1 loop
			--report integer'image(i);
		if i >= nFull then
			exit;
		end if;	
			
		if sendingMask(i) = '0' then
			res(j) := content(i);
			j := j+1;
		end if;
	end loop;

	if nFull-nOut+nIn-1 < res'length then
		res(nFull-nOut to nFull-nOut+nIn-1) := newContent(0 to nIn-1);
	end if;
	return res;
end function;


function stageCQNext(content, newContent: PipeStageDataU; 
		livingMask: std_logic_vector;
		ready: std_logic_vector; routes: IntArray; nFull, nOut, nIn: integer)
return PipeStageDataU is 
	variable res: PipeStageDataU(content'range) := (others => defaultInstructionState);
	--InstructionStateArray(content'range) := (others=>defaultInstructionState);
	variable j: integer;
begin

	for i in 0 to content'length-1 loop -- to livingContent'length - nOut - 1 loop
		if i >= content'length - nOut then
			exit;
		end if;
		if livingMask(i + nOut) = '1' then
			res(i) := content(i + nOut);	
		end if;	
	end loop;
	
	for i in 0 to ready'length-1 loop --  ready'range loop
		j := routes(i);
		if ready(i) = '1' and j >= 0 and j < content'length then
			res(j) := newContent(i);
		end if;
	end loop;
	return res;
end function;


function stageCQNext2(content, newContent: PipeStageDataU; 
		livingMask: std_logic_vector;
		ready: std_logic_vector;
		vecA, vecB, vecC, vecD: std_logic_vector; 
		nFull, nOut, nIn: integer)
return PipeStageDataU is 
	variable res: PipeStageDataU(content'range) := (others => defaultInstructionState);
	--InstructionStateArray(content'range) := (others=>defaultInstructionState);
	variable j: integer;
begin

	for i in 0 to content'length-1 loop -- to livingContent'length - nOut - 1 loop
		if i >= content'length - nOut then
			exit;
		end if;
		if livingMask(i + nOut) = '1' then
			res(i) := content(i + nOut);	
		end if;	
	end loop;
	
	for i in 0 to ready'length-1 loop --  ready'range loop
		if (vecA(i) and ready(0)) = '1' then 
			res(i) := newContent(0);
		elsif (vecB(i) and ready(1)) = '1' then
			res(i) := newContent(1);			
		elsif (vecC(i) and ready(2)) = '1' then
			res(i) := newContent(2);			
		elsif (vecD(i) and ready(3)) = '1' then
			res(i) := newContent(3);			
		end if;
		
	end loop;
	return res;
end function;


function updateCQMask(mask: std_logic_vector; 
		ready: std_logic_vector; routes: IntArray; nFull, nOut, nIn: integer)
return std_logic_vector is 
	variable res: std_logic_vector(mask'range) := (others => '0');
	--InstructionStateArray(content'range) := (others=>defaultInstructionState);
	variable j: integer;
begin

	for i in 0 to mask'length-1 loop -- to mask'length - nOut - 1 loop
		if i >= mask'length - nOut then
			exit;
		end if;	
		res(i) := mask(i + nOut);	
	end loop;
	
	for i in 0 to ready'length-1 loop -- ready'range loop
		j := routes(i);
		if ready(i) = '1' and j >= 0 and j < mask'length then
			res(j) := '1';
		end if;
	end loop;
	return res;
end function;


function stageCQNext(content: StageDataCommitQueue; newContent: InstructionStateArray;
		livingMask: std_logic_vector;
		ready: std_logic_vector; routes: IntArray; nFull, nOut, nIn: integer)
return StageDataCommitQueue is
	variable res: StageDataCommitQueue := (fullMask => (others=>'0'), 
														data => (others=>defaultInstructionState));
	variable j: integer;															
begin
	for i in 0 to content.data'length-1 loop -- to livingContent'length - nOut - 1 loop
		if i >= content.data'length - nOut then
			exit;
		end if;
		if livingMask(i + nOut) = '1' then
			res.data(i) := content.data(i + nOut);	
		end if;
		res.fullMask(i) := content.fullMask(i + nOut);	
	end loop;
	
	for i in 0 to ready'length-1 loop --  ready'range loop
		j := routes(i);
		if ready(i) = '1' and j >= 0 and j < content.data'length then
			res.data(j) := newContent(i);
			res.fullMask(j) := '1';
		end if;
	end loop;
	return res;		
end function;

function stageCQNext2(content: StageDataCommitQueue; newContent: InstructionStateArray;
		livingMask: std_logic_vector;
		ready: std_logic_vector;
		vecA, vecB, vecC, vecD: std_logic_vector; 
		nFull, nOut, nIn: integer)
return StageDataCommitQueue is
	variable res: StageDataCommitQueue := (fullMask => (others=>'0'), 
														data => (others=>defaultInstructionState));
	variable j: integer;															
begin
	for i in 0 to content.data'length-1 loop -- to livingContent'length - nOut - 1 loop
		if i >= content.data'length - nOut then
			exit;
		end if;
		if livingMask(i + nOut) = '1' then
			res.data(i) := content.data(i + nOut);	
		end if;
		res.fullMask(i) := content.fullMask(i + nOut);	
	end loop;
	
	for i in 0 to livingMask'length-1 loop --  ready'range loop
		if (vecA(i) and ready(0)) = '1' then 
			res.data(i) := newContent(0);
			res.fullMask(i) := '1';
		elsif (vecB(i) and ready(1)) = '1' then
			res.data(i) := newContent(1);	
			res.fullMask(i) := '1';			
		elsif (vecC(i) and ready(2)) = '1' then
			res.data(i) := newContent(2);			
			res.fullMask(i) := '1';			
		elsif (vecD(i) and ready(3)) = '1' then
			res.data(i) := newContent(3);	
			res.fullMask(i) := '1';			
		end if;		
	end loop;
	return res;		
end function;


function stagePCNext(content: TEMP_StageDataPC; targetInfo: InstructionBasicInfo;
							newNH: PipeFlow;
							full, sending, receiving: std_logic) return TEMP_StageDataPC is
	variable res: TEMP_StageDataPC;
begin
		res.pcBase := (others=>'0');
	if receiving = '1' then -- take full
		-- res := [from target info];
		res.basicInfo := targetInfo;
		res.pc := targetInfo.ip;
		res.pcBase(MWORD_SIZE-1 downto ALIGN_BITS) := targetInfo.ip(MWORD_SIZE-1 downto ALIGN_BITS); 
		res.nH := --pc2size(targetInfo.ip, ALIGN_BITS, num2flow(2*PIPE_WIDTH, false));
					newNH;
	elsif sending = '1' then -- take empty
		-- res := -- empty, default (should neve happen?)
	else -- stall
		if full = '1' then
			res := content;
		else
			-- res := default -- leave it empty
			-- should never happen?
		end if;
	end if;	
	return res;
end function;

function stageFetchNext(content, newContent: TEMP_StageDataPC;
							full, sending, receiving: std_logic) return TEMP_StageDataPC is
	variable res: TEMP_StageDataPC := DEFAULT_DATA_PC;
begin
	if receiving = '1' then -- take full
		res := newContent;
	elsif sending = '1' then -- take empty
		-- res := -- empty, default
	else -- stall
		if full = '1' then
			res := content;
		else
			-- res := default -- leave it empty
		end if;
	end if;	
	return res;
end function;

function nextTargetInfo(pcData: TEMP_StageDataPC; fe: FrontEventInfo; movedIP: Mword) 
return InstructionBasicInfo is
	variable res: InstructionBasicInfo := pcData.basicInfo;--defaultBasicInfo;
	variable baseIpVar, baseInc: Mword := (others=>'0');
begin 
	if (fe.eventOccured and fe.fromInt) = '1' then
		--res.ip := (others=>'0');
		res.ip := INT_TABLE(2); -- TEMP
		res.intLevel := "10000000"; -- TEMP
	elsif fe.eventOccured = '1' then -- when from exec or front
		-- TEMP!
		res.ip := basicJumpAddress(fe.causing);
		if fe.causing.controlInfo.exception = '1' then
			res.systemLevel := "10000000";
		end if;
	else
		res.ip := movedIP;	
	end if;
	
	return res;
end function;


function getAnnotatedHwords(arr: HwordArray; ip: Mword; basicInfo: InstructionBasicInfo; hEndings: MwordArray) 
return AnnotatedHwordArray is
	variable res: AnnotatedHwordArray(arr'range);
	variable hwordIP: Mword := (others=>'0');
	variable hwordBasicInfo: InstructionBasicInfo := basicInfo;
begin
	hwordIP := ip;
	hwordIP(0) := '0';
	for i in 0 to arr'length-1 loop
		-- NOTE: cause we use base IP, low bits are cleared. Instead of adding we just fll low bits
		-- CAREFUL: but the fetched block in 'arr' must be aligned and not exceed aligment size!
			-- FAIL: somehow this seems to increase LUT number!
		--hwordIP(ALIGN_BITS-1 downto 0) := --i2slv(i, ALIGN_BITS-1);
		hwordIP := ip(MWORD_SIZE-1 downto ALIGN_BITS) &	hEndings(i)(ALIGN_BITS-1 downto 0);
		hwordBasicInfo.ip := hwordIP;	
				--report integer'image(slv2u(hwordIP)) & ",, " & integer'image(slv2u(ip) + 2*i);
		res(i) := (bits => arr(i),
					  ip => --i2slv(slv2u(ip) + 2*i, MWORD_SIZE),
								hwordIP, -- CAREFUL: here using the "alignment" version
							basicInfo => hwordBasicInfo --defaultBasicInfo
					  );	
		--	res(i).basicInfo.ip := hwordIP; --res(i).ip;		  
	end loop;
	return res;
end function;

function hwordAddressEndings return MwordArray is
	variable res: MwordArray(0 to 2*PIPE_WIDTH-1) := (others=>(others=>'0'));	
begin	
	for i in 0 to 2*PIPE_WIDTH-1 loop
		res(i)(ALIGN_BITS-1 downto 0) := i2slv(2*i, ALIGN_BITS);
	end loop;
	return res;
end function;


	function TEMP_getResultTags(execData: ExecDataTable; stageDataCQ: StageDataCommitQueue;
							dispatchDataA, dispatchDataB, dispatchDataC, dispatchDataD: InstructionState) 
	return PhysNameArray is
		variable resultTags: PhysNameArray(0 to N_RES_TAGS-1) := (others=>(others=>'0'));
	begin
		resultTags(0) := execData(ExecA0).physicalDestArgs.d0; 
		resultTags(1) := execData(ExecB2).physicalDestArgs.d0; 
		resultTags(2) := execData(ExecC2).physicalDestArgs.d0; 
		resultTags(3) := execData(ExecD0).physicalDestArgs.d0; 
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
	
	function TEMP_getNextResultTags(execData: ExecDataTable;
							dispatchDataA, dispatchDataB, dispatchDataC, dispatchDataD: InstructionState) 
	return PhysNameArray is
		variable nextResultTags: PhysNameArray(0 to N_RES_TAGS-1) := (others=>(others=>'0'));
	begin
		nextResultTags(0) := dispatchDataA.physicalDestArgs.d0;
		nextResultTags(1) := execData(ExecB1).physicalDestArgs.d0; 
		nextResultTags(2) := execData(ExecC1).physicalDestArgs.d0; 
		nextResultTags(3) := dispatchDataD.physicalDestArgs.d0;
		return nextResultTags;
	end function;

	-- TODO: probably useless, maybe remove
	function getExecDataUpdated(execData: ExecDataTable;
						dispatchAUpdated, dispatchBUpdated, dispatchCUpdated, dispatchDUpdated: InstructionState)
	return ExecDataTable is
		variable execDataUpdated: ExecDataTable;
	begin	
		execDataUpdated := ( --DispatchA => dispatchAUpdated,	
									ExecA0 => execData(ExecA0),
									--DispatchB => dispatchBUpdated,
									ExecB0 => execData(ExecB0), ExecB1 => execData(ExecB1), ExecB2 => execData(ExecB2),
									--DispatchC => dispatchCUpdated,
									ExecC0 => execData(ExecC0), ExecC1 => execData(ExecC1), ExecC2 => execData(ExecC2),
									--DispatchD => dispatchDUpdated,
									ExecD0 => execData(ExecD0),
									others=> defaultInstructionState);		
		return execDataUpdated;
	end function;
	
	
	function getExecPrevResponses(				
		execResponses: ExecResponseTable; 
		--flowResponseAPre, flowResponseBPre, 
		--flowResponseCPre, flowResponseDPre,
		frDispatchA, frDispatchB, frDispatchC, frDispatchD: FlowResponseSimple)
	return execResponseTable is
		variable execPrevResponses: ExecResponseTable;
	begin	
			execPrevResponses := (
								--DispatchA => flowResponseAPre,
								ExecA0 => frDispatchA,
								--DispatchB => flowResponseBPre,
								ExecB0 => frDispatchB,
										ExecB1 => execResponses(ExecB0), ExecB2 => execResponses(ExecB1),
								--DispatchC => flowResponseCPre,
								ExecC0 => frDispatchC,
										ExecC1 => execResponses(ExecC0), ExecC2 => execResponses(ExecC1),
								--DispatchD => flowResponseDPre,
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
								--DispatchA => execResponses(ExecA0),
								ExecA0 => flowResponseAPost,
								--DispatchB => execResponses(ExecB0), 
								ExecB0 => execResponses(ExecB1), 
										ExecB1 => execResponses(ExecB2),ExecB2 => flowResponseBPost,
								--DispatchC => execResponses(ExecC0),
								ExecC0 => execResponses(ExecC1), 
										ExecC1 => execResponses(ExecC2),	ExecC2 => flowResponseCPost,
								--DispatchD => execResponses(ExecD0),
								ExecD0 => flowResponseDPost,
								others => (others=>'0'));	
		return execNextResponses;	
	end function;
			
	-- CAREFUL, TODO: 4B problem!	
	function getTargetInfo(ins: InstructionState) return InstructionBasicInfo is
		variable res: InstructionBasicInfo := ins.basicInfo;
	begin
		if ins.classInfo.system = '1' and ins.classInfo.undef = '0' then -- TEMP!
			report "Setting target from system instruction...";
			res.ip := i2slv( slv2s(ins.basicInfo.ip) + 4*PIPE_WIDTH, MWORD_SIZE); -- DUMMY: go to next
		elsif ins.controlInfo.branchSpeculated = '1' then
			-- It must be immediate branch if we are to know the target
			-- TODO: ensure correct signedness etc, prevent overflow if relevant...
			--res.ip := i2slv(slv2s(ins.constantArgs.imm) + slv2s(ins.basicInfo.ip) + 1, MWORD_SIZE); 
			-- !!! Also remeber that setTarget must be called first to calculate it!
			res.ip := ins.target;
		elsif ins.controlInfo.exception = '1' then	
			res.ip := EXC_TABLE(slv2u(ins.controlInfo.exceptionCode));
			res.systemLevel := i2slv(slv2u(res.systemLevel) + 1, SMALL_NUMBER_SIZE); -- TEMP!
		else -- normal: just next instruciton
			res.ip := i2slv( slv2s(ins.basicInfo.ip) + 4*PIPE_WIDTH, MWORD_SIZE); -- DUMMY: go to next			
		end if;	
		
		return res;	
	end function;	
	
	function getInstructionTarget(ins: InstructionState) return InstructionBasicInfo is
		variable res: InstructionBasicInfo := defaultBasicInfo;
	begin
		res := getTargetInfo(ins);
		return res;
	end function;
	
	function getHardTarget(newContent: StageDataMulti) return InstructionBasicInfo is
		variable res: InstructionBasicInfo := defaultBasicInfo;
	begin
		-- Seeking form right side cause we need the last one 
		for i in newContent.fullMask'reverse_range loop
			if newContent.fullMask(i) = '1' then
				res := getInstructionTarget(newContent.data(i));				
				exit;
			end if;
		end loop;
		return res;
	end function;	
		
	function getLastFull(newContent: StageDataMulti) return InstructionState is
		variable res: InstructionState := defaultInstructionState;
	begin
		-- Seeking form right side cause we need the last one 
		for i in newContent.fullMask'reverse_range loop
			if newContent.fullMask(i) = '1' then
				res := newContent.data(i);				
				exit;
			end if;
		end loop;
		return res;
	end function;			
		
end GeneralPipeDev;
