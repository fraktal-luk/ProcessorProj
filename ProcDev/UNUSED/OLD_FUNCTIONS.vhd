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


package OLD_FUNCTIONS is

	subtype PipeStageDataU is InstructionStateArray;	
	subtype SingleStageData is PipeStageDataU(0 to 0);
	subtype PipeStageData is PipeStageDataU(0 to PIPE_WIDTH-1);

------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
---- PIPE FLOW CONTROL FUNCTIONS ------

-- If less than all declared can be sent, decides to send nothing
--	! Based only on total numbers, not positioning
-- UNUSED
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
-- UNUSED
function TEMP_stateAfterSendingSimple(full, sending: std_logic) return std_logic;

-- UNUSED
function TEMP_calcAcceptingBuffer(canAccept, capacity, rest: PipeFlow) return PipeFlow;
-- UNUSED
function TEMP_calcAcceptingSimple(canAccept, rest: std_logic) return std_logic;

-- UNUSED
function TEMP_stateAfterReceivingBuffer(full, receiving: PipeFlow) return PipeFlow;
-- UNUSED
function TEMP_stateAfterReceivingSimple(full, receiving: std_logic) return std_logic;

-- UNUSED
procedure TEMP_defaultFlowDeclarations(capacity, full: in PipeFlow; canAccept, wantSend: out PipeFlow);
----- USED ONLY IN ABOVE FUNCTION!
function TEMP_defaultCanAccept(capacity, full: in PipeFlow) return PipeFlow;
function TEMP_defaultWantSend(capacity, full: in PipeFlow) return PipeFlow;
----------------------------------

--UNUSED
function TEMP_defaultCanAcceptSimple(full: std_logic) return std_logic;
-- UNUSED
function TEMP_defaultWantSendSimple(full: std_logic) return std_logic;
------------------------------
--------------------------------------------------------------------------------





-- UNUSED				
function stageIQNext(content, newContent: PipeStageDataU; 
							sendingMask: std_logic_vector; nFull, nOut, nIn: integer) 
return PipeStageDataU;


-- DONT REMOVE. Reference alg for Hbuffer updating
function bufferAHNextDefault(content, newContent: AnnotatedHwordArray; 
								fetchData: StageDataPC;
								nFull, nOut, nIn: integer) 
return AnnotatedHwordArray;

-- UNUSED?
function findReady(arr: InstructionStateArray) return std_logic_vector;

-- UNUSED?
function getForwardingStatus(av: in InstructionArgValues; pa: in InstructionPhysicalArgs; 
										tags: in PhysNameArray) return std_logic_vector;

-- UNUSED
procedure findForwardingSources(av: in InstructionArgValues; pa: in InstructionPhysicalArgs; 
										tags: in PhysNameArray; content: in MwordArray;
										ready: out std_logic_vector; locs: out SmallNumberArray;
										vals: out MwordArray);

function TEMP_baptize(sd: StageDataMulti; baseNum: integer) 
return StageDataMulti;

-- Makes physical names the same as virtual names	
function DUMMY_rename(sd: StageDataMulti) return StageDataMulti;

-- UNUSED?
function bufferNext(content, newContent: PipeStageDataU; nFull, nOut, nIn: integer) return PipeStageDataU;

-- DEPREC?
function normalStageNext(content, newContent: PipeStageDataU; nFull, nOut, nIn: integer) 
				return PipeStageDataU;
-- UNUSED
function updateCQMask(mask: std_logic_vector; 
		ready: std_logic_vector; routes: IntArray; nFull, nOut, nIn: integer)
return std_logic_vector;

-- UNUSED
function bufferAHNext_OLD(content, newContent: AnnotatedHwordArray; 
								fetchData: StageDataPC;
								nFull, nOut, nIn: integer) 
return AnnotatedHwordArray;

-- DEPREC? - At the moment leave it in place.		
function stagePCNext_OLD(content: StageDataPC; targetInfo: InstructionBasicInfo;
							newNH: PipeFlow;
							full, sending, receiving: std_logic) return StageDataPC;

-- UNNEEDED?
function hwordAddressEndings return MwordArray;

-- NOTE: This would be needed if want to only find signals from proper stage
-- DEPREC?
function getS0EventMask(sd: StageDataMulti; isNew: std_logic) return std_logic_vector;
-- DEPREC?
function getEventMask(sd: StageDataMulti; isNew: std_logic) return std_logic_vector;

function getStagesToKill(causingFS: std_logic_vector; execES: std_logic) return std_logic_vector;

function frontEvents_OLD(pcData: StageDataPC; fetchData: StageDataPC;
									stageData0, stageData1: StageDataMulti;
									nPC, nFetch: std_logic;
									n0, n1: std_logic;
									intEvent: std_logic;									
									backEvent: std_logic;
									backCausing: InstructionState) 
return FrontEventInfo;

function frontEvents_OLD2(pcData: StageDataPC; fetchData: StageDataPC;
									stageData0: StageDataMulti;
									nPC, nFetch: std_logic;
									n0: std_logic;
									intEvent: std_logic;
									backEvent: std_logic;
									backCausing: InstructionState)									
return FrontEventInfo;

function extractPhysSources(data: InstructionStateArray) return PhysNameArray;

function extractPhysS0(data: InstructionStateArray) return PhysNameArray;
function extractPhysS1(data: InstructionStateArray) return PhysNameArray;
function extractPhysS2(data: InstructionStateArray) return PhysNameArray;

function extractMissing(data: InstructionStateArray) return std_logic_vector;		

function extractMissing0(data: InstructionStateArray) return std_logic_vector;		
function extractMissing1(data: InstructionStateArray) return std_logic_vector;		
function extractMissing2(data: InstructionStateArray) return std_logic_vector;		

function selectInstructions(content: InstructionStateArray; numbers: IntArray; nI: integer)
return InstructionStateArray is
	variable res: InstructionStateArray(content'range) := (others=>defaultInstructionState);
	variable ind: integer;
begin
	if nI < 0 or nI > numbers'length or nI > res'length
	then
		return res;
	end if;	
		for i in content'range loop
			if i >= nI or i >= numbers'length then
				exit;
			end if;
				if numbers(i) < 0 or numbers(i) >= content'length then
					return res;
				end if;	
					ind := numbers(i);	
					res(i) := content(ind); -- content(numbers(i));
		end loop;
	return res; 
end function;


function TEMP_branchPredict(ins: InstructionState) return InstructionState is
	variable res: InstructionState := ins;
begin
	if res.classInfo.branchCond = '1' then
		--res.controlInfo.unseen := '1';	
	
		if res.constantArgs.c1 = COND_NONE then -- 'none'; CAREFUL! Use correct codes!
			-- Jump
				--res.controlInfo.s0Event := '1';
			--res.controlInfo.branchSpeculated := '1'; -- ??
			--res.controlInfo.branchConfirmed := '1'; -- ??
		elsif res.constantArgs.c1 = COND_Z and res.virtualArgs.s0 = "00000" then -- 'zero'; CAREFUL! ...
			-- Jump
				--res.controlInfo.s0Event := '1';
			--res.controlInfo.branchSpeculated := '1'; -- ??
			--res.controlInfo.branchConfirmed := '1'; -- ??
		elsif res.constantArgs.c1 = COND_NZ and res.virtualArgs.s0 /= "00000" then -- 'one'; CAREFUL!...
			-- No jump!
		else
			-- Need to speculate...
			-- ! src0 should be register other than r0
			-- Check	if displacement is negative
			--			
		end if;
	end if;
	
	return res;
end function;

	function findOldestSignal(ready: std_logic_vector; tags: SmallNumberArray) return std_logic_vector is
		variable res: std_logic_vector(ready'range) := (others=>'0');
		variable k: integer := 0;
	begin
		for i in 1 to ready'length-1 loop
			if ready(i) = '1' and tagBefore(tags(i), tags(k)) = '1' then
				k := i;
			end if;
		end loop;
		res(k) := '1';
		return res;
	end function;

end OLD_FUNCTIONS;



package body OLD_FUNCTIONS is

--------------------------------

function TEMP_calcSendingZero(nextAccepting, wantSend: PipeFlow) return PipeFlow is
	variable res: PipeFlow := (others=>'0');
	variable a, b: natural;
begin
	a := binFlowNum(nextAccepting);
	b := binFlowNum(wantSend);
	if b > a then
		b := 0;
	end if;
	return num2flow(b);
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
	return num2flow(b);
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
	res := num2flow(remaining);
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
	
	res := num2flow(ca);
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
	res := num2flow(total);
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
	--  what about aligning and otherwise normalizing the outputs?
	return capacity;	
end function;

function TEMP_defaultWantSend(capacity, full: in PipeFlow) return PipeFlow is
begin
	return full;   --  what about aligning and otherwise normalizing the outputs?
end function;


function TEMP_defaultCanAcceptSimple(full: std_logic) return std_logic is
begin
	return '1';
end function;

function TEMP_defaultWantSendSimple(full: std_logic) return std_logic is
begin
	return full;
end function;
----------------------------------


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


function bufferAHNext(content: InstructionStateArray;
									livingMask: std_logic_vector;
								newContent: InstructionStateArray; 
								fetchData: InstructionState;
									fetchBasicInfo: InstructionBasicInfo;								
								nFull, nOut, nIn: integer) 
return InstructionStateArray is
	variable res: InstructionStateArray(0 to content'length-1) 
			:= (others => DEFAULT_ANNOTATED_HWORD);
	variable newShift: integer := 0; -- CAREFUL! This determines where actual data starts in newContent
		constant CLEAR_EMPTY_SLOTS_HBUFF: boolean := false;	
	variable tempX: InstructionStateArray(0 to content'length + newContent'length - 1) 
			:= (others => DEFAULT_ANNOTATED_HWORD);
	variable tempMaskX: std_logic_vector(0 to content'length + newContent'length - 1) := (others => '0');		
			
	variable tempY: InstructionStateArray(0 to 2*content'length + newContent'length - 1) 
			:= (others => DEFAULT_ANNOTATED_HWORD);
begin	
	-- CAREFUL! Hbuffer size MUST be a multiple of newContent size!

	newShift := slv2u(fetchBasicInfo.ip(ALIGN_BITS-1 downto 1)); -- pc(ALIGN_BITS-1 downto 1));					
		--	newShift := 0;
		-- For position 'i':
		-- Y: if taking newContent[y], it must be: nFull + y - newShift = i, so
		--		y = i + newShift - nFull 
		-- 	So let's get y := (i + newShift - nFull)
		-- X: if taking form content[x], it must be: i + nOut = x, so
		--		x := i + nOut
		--
		-- However, for Y: when i is end of queue, it can only take yMax,
		--					when end-1, it can take {yMax-1, yMax}, etc.
		-- and for X: x must be smaller than QUEUE_SIZE
		--
		-- Selection X vs Y: when nFull-nOut+nIn > i, select X, else select Y
		--	
		
	-- Prepare initial tempX, tempY, masks
	tempX := content & newContent;
			tempMaskX(0 to content'length-1) := livingMask;
	for k in 0 to tempY'length-1 loop
		tempY(k) := newContent(k mod newContent'length);
	end loop;
			
		-- Shift tempX + mask	
		tempX(0 to content'length-1) := tempX(nOut to content'length-1 + nOut);
			tempMaskX(0 to content'length-1) := tempMaskX(nOut to content'length-1 + nOut);	
		-- Shift tempY
		tempY(0 to content'length-1) := 
			tempY(		(content'length - nFull + nOut) + newShift 
								to (content'length - nFull + nOut) + content'length-1 + newShift);
	
	-- Select from X or Y
	for p in 0 to content'length-1 loop
		if tempMaskX(p) = '1' then
			res(p) := tempX(p);
		else		
			res(p) := tempY(p);
		end if;		
	end loop;

	if CLEAR_EMPTY_SLOTS_HBUFF then
		res(nFull - nOut + nIn to res'length-1) := (others => DEFAULT_ANNOTATED_HWORD);
	end if;
		
	return res;
end function;


function TEMP_hbufferFullMaskNext(content: InstructionStateArray;
											livingMask: std_logic_vector;
											newContent: InstructionStateArray;
											prevSending: std_logic;
											fetchData: InstructionState;
												fetchBasicInfo: InstructionBasicInfo;											
											nFull, nOut, nIn: integer)  
return std_logic_vector is
	variable res: std_logic_vector(0 to content'length-1) 
			:= (others => '0');
	variable newShift: integer := 0; -- CAREFUL! This determines where actual data starts in newContent
		constant CLEAR_EMPTY_SLOTS_HBUFF: boolean := false;	
	variable tempX: InstructionStateArray(0 to content'length + newContent'length - 1) 
			:= (others => DEFAULT_ANNOTATED_HWORD);
	variable tempMaskX: std_logic_vector(0 to content'length + newContent'length - 1) := (others => '0');		
			
	variable tempMaskY: std_logic_vector(0 to 2*content'length + newContent'length - 1) 
			:= (others => '0');
begin	
	-- CAREFUL! Hbuffer size MUST be a multiple of newContent size!

	newShift := slv2u(fetchBasicInfo.ip(ALIGN_BITS-1 downto 1)); -- pc(ALIGN_BITS-1 downto 1));					
		-- For position 'i':
		-- Y: if taking newContent[y], it must be: nFull + y - newShift = i, so
		--		y = i + newShift - nFull 
		-- 	So let's get y := (i + newShift - nFull)
		-- X: if taking form content[x], it must be: i + nOut = x, so
		--		x := i + nOut
		--
		-- However, for Y: when i is end of queue, it can only take yMax,
		--					when end-1, it can take {yMax-1, yMax}, etc.
		-- and for X: x must be smaller than QUEUE_SIZE
		--
		-- Selection X vs Y: when nFull-nOut+nIn > i, select X, else select Y
		--	
	tempX := content & newContent;
	tempMaskX(0 to content'length-1) := livingMask;
	for k in 0 to newContent'length - 1 loop
		--if nIn /= 0 then
			tempMaskY(k) := prevSending;
			tempMaskY(content'length + k) := prevSending;
		--end if;
	end loop;
	
	tempMaskX(0 to tempMaskX'length-1 - nOut) := tempMaskX(nOut to tempMaskX'length-1);
	tempMaskY(0 to content'length-1) := 
		tempMaskY(		(content'length - nFull + nOut) + newShift 
					to (content'length - nFull + nOut) + content'length-1 + newShift);					
					
	for p in 0 to content'length-1 loop	
		if --nFull - nOut > p then
			tempMaskX(p) = '1' then
											
			res(p) := '1';
		else		
			res(p) := tempMaskY(p);
		end if;	
	end loop;

	return res;
end function;


function TEMP_hbufferStageDataNext(content: InstructionStateArray;
											livingMask: std_logic_vector;
											newContent: InstructionStateArray;
											prevSending: std_logic;
											fetchData: InstructionState;
												fetchBasicInfo: InstructionBasicInfo;											
											nFull, nOut, nIn: integer)  
return StageDataHbuffer is
	variable res: StageDataHbuffer := DEFAULT_STAGE_DATA_HBUFFER;
	variable newShift: integer := 0; -- CAREFUL! This determines where actual data starts in newContent
		constant CLEAR_EMPTY_SLOTS_HBUFF: boolean := false;	
	variable tempX: InstructionStateArray(0 to content'length + newContent'length - 1) 
			:= (others => DEFAULT_ANNOTATED_HWORD);
	variable tempMaskX: std_logic_vector(0 to content'length + newContent'length - 1) := (others => '0');		
			
	variable tempY: InstructionStateArray(0 to 2*content'length + newContent'length - 1) 
			:= (others => DEFAULT_ANNOTATED_HWORD);					
	variable tempMaskY: std_logic_vector(0 to 2*content'length + newContent'length - 1) 
			:= (others => '0');
begin	
	-- CAREFUL! Hbuffer size MUST be a multiple of newContent size!

	newShift := slv2u(fetchBasicInfo.ip(ALIGN_BITS-1 downto 1));					
		-- For position 'i':
		-- Y: if taking newContent[y], it must be: nFull + y - newShift = i, so
		--		y = i + newShift - nFull 
		-- 	So let's get y := (i + newShift - nFull)
		-- X: if taking form content[x], it must be: i + nOut = x, so
		--		x := i + nOut
		--
		-- However, for Y: when i is end of queue, it can only take yMax,
		--					when end-1, it can take {yMax-1, yMax}, etc.
		-- and for X: x must be smaller than QUEUE_SIZE
		--
		-- Selection X vs Y: when nFull-nOut+nIn > i, select X, else select Y
		--	
	tempX := content & newContent;
	tempMaskX(0 to content'length-1) := livingMask;		
	for k in 0 to tempY'length-1 loop
		tempY(k) := newContent(k mod newContent'length); -- & newContent & newContent & newContent;	
	end loop;			
			
	for k in 0 to newContent'length - 1 loop
		--if nIn /= 0 then
			tempMaskY(k) := prevSending;
			tempMaskY(content'length + k) := prevSending;
		--end if;
	end loop;

	tempX(0 to content'length-1 - nOut) := tempX(nOut to content'length-1);
	tempMaskX(0 to tempMaskX'length-1 - nOut) := tempMaskX(nOut to tempMaskX'length-1);
		

	tempY(0 to content'length-1) := 
		tempY(		(content'length - nFull + nOut) + newShift 
					to (content'length - nFull + nOut) + content'length-1 + newShift);

	tempMaskY(0 to content'length-1) := 
		tempMaskY(		(content'length - nFull + nOut) + newShift 
					to (content'length - nFull + nOut) + content'length-1 + newShift);					
			
	for p in 0 to content'length-1 loop	
		if tempMaskX(p) = '1' then
			res.data(p) := tempX(p);
			res.fullMask(p) := '1';
		else
			res.data(p) := tempY(p);
			res.fullMask(p) := tempMaskY(p);
		end if;	
	end loop;
	
	return res;
end function;




function bufferAHNextDefault(content, newContent: AnnotatedHwordArray; 
								fetchData: StageDataPC;
								nFull, nOut, nIn: integer) 
return AnnotatedHwordArray is
	variable temp: AnnotatedHwordArray(0 to content'length + newContent'length - 1) 
			:= (others => DEFAULT_ANNOTATED_HWORD);	
	variable res: AnnotatedHwordArray(content'range) 
			:= (others => DEFAULT_ANNOTATED_HWORD);
	variable newShift: integer := 0; -- CAREFUL! This determines where actual data starts in newContent
		constant CLEAR_EMPTY_SLOTS_HBUFF: boolean := false;
begin	
	if not CLEAR_EMPTY_SLOTS_HBUFF then
		--temp(0 to content'length-1) := content;
		temp := content & newContent;
	end if;

	newShift := slv2u(fetchData.pc(ALIGN_BITS-1 downto 1));				
	temp(0 to content'length - 1 - nOut) := content(nOut to content'length-1);
	temp(nFull-nOut to nFull-nOut+nIn-1) := newContent(newShift to newShift + nIn - 1);		
	res := temp(0 to content'length - 1);
	return res;
end function;



function findReady(arr: InstructionStateArray) return std_logic_vector is
	variable res: std_logic_vector(arr'range) := (others=>'0');
begin
	for i in arr'range loop
		res(i) :=  '1' or
						readyForExec(arr(i));
	end loop;
	return res;
end function;

function getForwardingStatus(av: in InstructionArgValues; pa: in InstructionPhysicalArgs; 
										tags: in PhysNameArray) return std_logic_vector
is
	variable dummyContent: MwordArray(tags'range) := (others=>(others=>'0'));
	variable ready: std_logic_vector(0 to 2) := (others=>'0');
	variable locs: SmallNumberArray(0 to 2) := (others=>(others=>'0'));
	variable vals: MwordArray(0 to 2) := (others=>(others=>'0'));
begin
	findForwardingSources(av, pa, tags, 	
									dummyContent,
									ready, locs, vals);
	return ready;								
end function;

procedure findForwardingSources(av: in InstructionArgValues; pa: in InstructionPhysicalArgs; 
										tags: in PhysNameArray; content: in MwordArray;
										ready: out std_logic_vector; locs: out SmallNumberArray;
										vals: out MwordArray)
is
	--variable res: SmallNumberArray(0 to 2) := (others=>(others=>'0'));
begin
	ready := "000";
	locs := (others=>(others=>'0'));
	vals := (others=>(others=>'0'));
	
	-- Find where tag agrees with s0
	for i in tags'range loop -- CAREFUL! Is this loop optimal for muxing?		
			-- CAREFUL! showing only nonzero tags (p0 never needs lookup)
			if isNonzero(tags(i)) = '0' then
				next;
			end if;		
		if tags(i) = pa.s0 then
			ready(0) := '1';
			locs(0) := i2slv(i, SMALL_NUMBER_SIZE);
			vals(0) := content(i);
		end if;
		if tags(i) = pa.s1 then
			ready(1) := '1';
			locs(1) := i2slv(i, SMALL_NUMBER_SIZE);
			vals(1) := content(i);
		end if;
		if tags(i) = pa.s2 then
			ready(2) := '1';
			locs(2) := i2slv(i, SMALL_NUMBER_SIZE);
			vals(2) := content(i);
		end if;			
	end loop;
	
end procedure;

function TEMP_baptize(sd: StageDataMulti; baseNum: integer) 
return StageDataMulti is
	variable res: StageDataMulti := sd;
begin
	for i in res.data'range loop
		if true or res.fullMask(i) = '1' then
			res.data(i).numberTag := i2slv(baseNum + i + 1, SMALL_NUMBER_SIZE);
		end if;
	end loop;
	return res;
end function;

-- 
function DUMMY_rename(sd: StageDataMulti) return StageDataMulti is
	variable res: StageDataMulti := sd;
begin
	for i in sd.data'range loop
		if sd.fullMask(i) = '1' then
			res.data(i).physicalArgs.sel := sd.data(i).virtualArgs.sel;
			res.data(i).physicalArgs.s0 := '0' & sd.data(i).virtualArgs.s0;
			res.data(i).physicalArgs.s1 := '0' & sd.data(i).virtualArgs.s1;
			res.data(i).physicalArgs.s2 := '0' & sd.data(i).virtualArgs.s2;			
			
			res.data(i).physicalDestArgs.sel := sd.data(i).virtualDestArgs.sel;
			res.data(i).physicalDestArgs.d0 := '0' & sd.data(i).virtualDestArgs.d0;			
		end if;
	end loop;
	
	-- Check arg value states
	for i in sd.data'range loop
		if sd.fullMask(i) = '1' then
			if res.data(i).physicalArgs.sel(0) = '1' and res.data(i).physicalArgs.s0 /= "000000" then
				res.data(i).argValues.missing(0) := '1';
			end if;
			if res.data(i).constantArgs.immSel = '1' then
				res.data(i).argValues.arg1 := res.data(i).constantArgs.imm;
				res.data(i).argValues.missing(1) := '0';				
			elsif res.data(i).physicalArgs.sel(1) = '1' and res.data(i).physicalArgs.s1 /= "000000" then
				res.data(i).argValues.missing(1) := '1';
			end if;
			if res.data(i).physicalArgs.sel(2) = '1' and res.data(i).physicalArgs.s2 /= "000000" then
				res.data(i).argValues.missing(2) := '1';
			end if;
			
		end if;
	end loop;
	
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
 
function bufferAHNext_OLD(content, newContent: AnnotatedHwordArray; 
								fetchData: StageDataPC;-- newContentPC: Mword;
								nFull, nOut, nIn: integer) 
return AnnotatedHwordArray is
	variable res: AnnotatedHwordArray(content'range) 
			:= (others => DEFAULT_ANNOTATED_HWORD);
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
	
	newShift := slv2u(fetchData.pc(ALIGN_BITS-1 downto 1));
				
	res(0 to nFull-nOut-1) := content(nOut to nFull-1);
	res(nFull-nOut to nFull-nOut+nIn-1) := newContent(newShift to newShift + nIn - 1);
	return res;
end function; 

function stagePCNext_OLD(content: StageDataPC; targetInfo: InstructionBasicInfo;
							newNH: PipeFlow;
							full, sending, receiving: std_logic) return StageDataPC is
	variable res: StageDataPC;
begin
		res.pcBase := (others=>'0');
	if receiving = '1' then -- take full
		-- res := [from target info];
		res.basicInfo := targetInfo;
		res.pc := targetInfo.ip;
		res.pcBase(MWORD_SIZE-1 downto ALIGN_BITS) := targetInfo.ip(MWORD_SIZE-1 downto ALIGN_BITS); 
		res.nH := newNH;
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



function hwordAddressEndings return MwordArray is
	variable res: MwordArray(0 to 2*PIPE_WIDTH-1) := (others=>(others=>'0'));	
begin	
	for i in 0 to 2*PIPE_WIDTH-1 loop
		res(i)(ALIGN_BITS-1 downto 0) := i2slv(2*i, ALIGN_BITS);
	end loop;
	return res;
end function;


function getS0EventMask(sd: StageDataMulti; isNew: std_logic) return std_logic_vector is
	variable res: std_logic_vector(sd.fullMask'range) := (others=>'0');
begin
	if isNew = '1' then
		for i in res'range loop
			res(i) := sd.fullMask(i) and sd.data(i).controlInfo.s0Event;
		end loop;
	end if;
	return res;
end function;


function getEventMask(sd: StageDataMulti; isNew: std_logic) return std_logic_vector is
	variable res: std_logic_vector(sd.fullMask'range) := (others=>'0');
begin
	if isNew = '1' then
		for i in res'range loop
			res(i) := sd.fullMask(i) and 
			(	sd.data(i).controlInfo.pcEvent
			--or sd.data(i).controlInfo.fetchEvent
			--or sd.data(i).controlInfo.hbuffEvent
				'0'
			or sd.data(i).controlInfo.s0Event);
		end loop;
	end if;
	return res;
end function;

	
function getStagesToKill(causingFS: std_logic_vector; execES: std_logic) return std_logic_vector is
		variable res: std_logic_vector(0 to 4) := (others => '0');
begin
	if	execES = '1' then
		res := "11111";
		return res;
	end if;
	
	case causingFS is
		when "10000" =>
			res := "00000";
		when "01000" =>
			res := "10000";
		when "00100" =>
			res := "11000";
		when "00010" =>
			res := "11100";
		when others =>
			null;
	end case;
	
	return res;			
end function;

type TEMP_StageDataFetch is record
	pc: Mword;
	pcBase: Mword; -- DEPREC?
	nFull: natural;	
end record;

function frontEvents_OLD(pcData: StageDataPC; fetchData: StageDataPC;--TEMP_StageDataFetch;		
									--hbufferData: HwordBufferData;
									stageData0, stageData1: StageDataMulti;
									nPC, nFetch: std_logic;
									--nHbuff: std_logic_vector(0 to HBUFFER_SIZE-1); -- Should be in hbufferData?
									n0, n1: std_logic;
									intEvent: std_logic;
									backEvent: std_logic;
									backCausing: InstructionState) 
return FrontEventInfo is
	variable res: FrontEventInfo;
	variable iPC, iFetch, iHbuff, i0, i1: integer := 0;
	variable ePC, eFetch, eHbuff, e0, e1: std_logic := '0';	
	variable mPC, mFetch, m0, m1: std_logic_vector(0 to PIPE_WIDTH-1); -- Event masks
	variable pPC, pFetch, p0, p1: std_logic_vector(0 to PIPE_WIDTH-1); -- Event masks
	
	variable mHbuff, pHbuff: std_logic_vector(0 to HBUFFER_SIZE-1);
	variable eventOccured, fromExec, fromInt: std_logic := '0';
	variable causing: InstructionState := defaultInstructionState;
	variable affectedVec, causingVec: std_logic_vector(0 to 4);
begin
	-- Find events from further end of pipeline (in the oldest instructions) 
	m1 := (others=>'0'); --getEventMask(stageData1, n1);
	m0 := getS0EventMask(stageData0, n0);	
	mHbuff := (others=>'0'); -- TEMP  --hbufferData.events and nHbuff; -- ??	
	mFetch := (others=>'0'); --getEventMask();
	mPC := (others=>'0'); --getEventMask();
	-- Where is first signal:
	i1 := getFirstOnePosition(m1);
	i0 := getFirstOnePosition(m0);
	iHbuff := getFirstOnePosition(mHbuff);
	iFetch := getFirstOnePosition(mFetch);
	iPC := getFirstOnePosition(mPC);
	-- Does it actually happen:
	e1 := m1(i1);
	e0 := m0(i0);
	eHbuff := mHbuff(iHbuff);
	eFetch := mFetch(iFetch);
	ePC := mPC(iPC);
	-- Now scan from latest stage
	eventOccured := '1';
	fromExec := '0';
	fromInt := '0';
	if intEvent = '1' then
		affectedVec := "11111";
		causingVec := "00000";
		causing := backCausing;
		fromInt := '1';	
	elsif backEvent = '1' then
		affectedVec := "11111";
		causingVec := "00000";
		causing := backCausing;
		fromExec := '1';
	elsif e1 = '1' then
		affectedVec := "11110";
		causingVec := "00001";
		causing := stageData1.data(i1);
	elsif e0 = '1' then
		affectedVec := "11100";
		causingVec := "00010";	
		causing := stageData0.data(i0);
	elsif eHbuff = '1' then
		affectedVec := "11000";
		causingVec := "00100";	
		--causing := 
	elsif eFetch = '1' then
		affectedVec := "10000";
		causingVec := "01000";	
		--causing :=
	elsif ePC = '1' then
		affectedVec := "00000";
		causingVec := "10000";	
		--causing :=
	else 
		affectedVec := "00000";
		causingVec := "00000";	
		eventOccured := '0';
	end if;
	
	-- Partial kill masks
	--		Prob. no need to check for 'affected', cause stages OLDER than event will have masks clear anyway.
	p1 := setFromFirstOne(m1) and not getFirstOne(m1);
	p0 := setFromFirstOne(m0) and not getFirstOne(m0);
	pHbuff := setFromFirstOne(mHbuff) and not getFirstOne(mHbuff);
	pFetch := setFromFirstOne(mFetch) and not getFirstOne(mFetch);
	pPC := setFromFirstOne(mPC) and not getFirstOne(mPC);
	
	
	res.eventOccured := eventOccured;
	res.fromExec := fromExec;
	res.fromInt := fromInt;
	
	res.mPC := mPC;
	res.mFetch := mFetch;
	res.mHbuff := mHbuff;
	res.m0 := m0;
	res.m1 := m1;

	res.pPC := pPC;
	res.pFetch := pFetch;
	res.pHbuff := pHbuff;
	res.p0 := p0;
	res.p1 := p1;
	
	res.ePC := ePC;
	res.eFetch := eFetch;
	res.eHbuff := eHbuff;
	res.e0 := e0;
	res.e1 := e1;

	res.iPC := iPC;
	res.iFetch := iFetch;
	res.iHbuff := iHbuff;
	res.i0 := i0;
	res.i1 := i1;	
	
	res.causingVec := causingVec;
	res.affectedVec := affectedVec;
	res.causing := causing;
	
	return res;
end function;

function frontEvents_OLD2(pcData: StageDataPC; fetchData: StageDataPC;--TEMP_StageDataFetch;		
									--hbufferData: HwordBufferData;
									stageData0: StageDataMulti;
									nPC, nFetch: std_logic;
									--nHbuff: std_logic_vector(0 to HBUFFER_SIZE-1); -- Should be in hbufferData?
									n0: std_logic;
									intEvent: std_logic;
									backEvent: std_logic;
									backCausing: InstructionState) 
return FrontEventInfo is
	variable res: FrontEventInfo;
	variable iPC, iFetch, iHbuff, i0, i1: integer := 0;
	variable ePC, eFetch, eHbuff, e0, e1: std_logic := '0';	
	variable mPC, mFetch, m0, m1: std_logic_vector(0 to PIPE_WIDTH-1) := (others=>'0'); -- Event masks
	variable pPC, pFetch, p0, p1: std_logic_vector(0 to PIPE_WIDTH-1) := (others=>'0'); -- Event masks
	
	variable mHbuff, pHbuff: std_logic_vector(0 to HBUFFER_SIZE-1) := (others=>'0');
	variable eventOccured, fromExec, fromInt: std_logic := '0';
	-- NOTE: assign backCausing to remove unneccessary control branch 
	--			(which would happen when no events occur)?
	variable causing: InstructionState := backCausing; -- defaultInstructionState;
	variable affectedVec, causingVec: std_logic_vector(0 to 4) := (others=>'0');
begin
	-- Find events from further end of pipeline (in the oldest instructions) 
	m0 := getS0EventMask(stageData0, n0);	
	mHbuff := (others=>'0'); -- TEMP  --hbufferData.events and nHbuff; -- ??	
	mFetch := (others=>'0'); --getEventMask();
	mPC := (others=>'0'); --getEventMask();
	
		for i in PIPE_WIDTH-1 downto 0 loop
			if e0 = '1' then
				p0(i) := '1';
			end if;
			if n0 = '1' and m0(i) = '1' then
				e0 := '1';
				i0 := i;
				causing := stageData0.data(i);
			end if;			
		end loop;
	
	-- Now scan from latest stage
	eventOccured := '1';
	fromExec := '0';
	fromInt := '0';
	if intEvent = '1' then
		affectedVec := "11111";
		causingVec := "00000";
		--causing := backCausing;
		fromInt := '1';	
	elsif backEvent = '1' then
		affectedVec := "11111";
		causingVec := "00000";
		--causing := backCausing;
		fromExec := '1';
	elsif e0 = '1' then
		affectedVec := "11100";
		causingVec := "00010";	
--		causing := stageData0.data(i0);
	elsif eHbuff = '1' then
		affectedVec := "11000";
		causingVec := "00100";	
		--causing := 
	elsif eFetch = '1' then
		affectedVec := "10000";
		causingVec := "01000";	
		--causing :=
	elsif ePC = '1' then
		affectedVec := "00000";
		causingVec := "10000";	
		--causing :=
	else 
		affectedVec := "00000";
		causingVec := "00000";	
		eventOccured := '0';
	end if;
		
	res.eventOccured := eventOccured;
	res.fromExec := fromExec;
	res.fromInt := fromInt;
	
	res.mPC := mPC;
	res.mFetch := mFetch;
	res.mHbuff := mHbuff;
	res.m0 := m0;
	res.m1 := m1;

	res.pPC := pPC;
	res.pFetch := pFetch;
	res.pHbuff := pHbuff;
	res.p0 := p0;
	res.p1 := p1;
	
	res.ePC := ePC;
	res.eFetch := eFetch;
	res.eHbuff := eHbuff;
	res.e0 := e0;
	res.e1 := '0';

--	res.iPC := iPC;
--	res.iFetch := iFetch;
--	res.iHbuff := iHbuff;
--	res.i0 := i0;	
	
	res.causingVec := causingVec;
	res.affectedVec := affectedVec;
	res.causing := causing;
	
	return res;
end function;


--	
---- Get inputs form registers and immediate value
--function getIssueArgValues(pa: InstructionPhysicalArgs; ca: InstructionConstantArgs;
--									ready: std_logic_vector; vals: MwordArray) 
--return InstructionArgValues is
--	variable res: InstructionArgValues := defaultArgValues;
--begin	
--	if pa.sel(0) = '1' then
--		if ready(0) = '1' then
--			res.arg0 := vals(0);
--		else
--			res.missing(0) := '1';
--		end if;
--	end if;
--	
--	-- CAREFUL! Here we must check if it's immediate value!
--	assert (ca.immSel and pa.sel(1)) = '0' 	-- Never should have s1 and imm together!
--			report "Immediate value together with reg src1!" severity error; 
--	
--	if ca.immSel = '1' then
--		res.arg1 := ca.imm;
--	end if;
--	
--	if pa.sel(1) = '1' then
--		if ready(1) = '1' then
--			res.arg1 := vals(1);
--		else
--			res.missing(1) := '1';
--		end if;
--	end if;
--
--	if pa.sel(2) = '1' then
--		if ready(2) = '1' then
--			res.arg2 := vals(2);
--		else
--			res.missing(2) := '1';
--		end if;
--	end if;		
--	return res;
--end function;

-- get args still missing (used while waiting for issue, possibly in the cycle when going to Exec)
--function updateArgValues(av: InstructionArgValues;
--									ready: std_logic_vector; vals: MwordArray) 
--return InstructionArgValues is
--	variable res: InstructionArgValues := av;
--begin
--	if (res.missing(0) and ready(0)) = '1' then
--		res.missing(0) := '0';
--		res.arg0 := vals(0);
--	end if;
--
--	if (res.missing(1) and ready(1)) = '1' then
--		res.missing(1) := '0';
--		res.arg1 := vals(1);
--	end if;
--
--	if (res.missing(2) and ready(2)) = '1' then
--		res.missing(2) := '0';
--		res.arg2 := vals(2);
--	end if;
--	
--	return res;
--end function;	



--
--function getForwardingStatusInfoD(av: in InstructionArgValues; pa: in InstructionPhysicalArgs; 
--										 content: in MwordArray;
--										tags, nextTags: in PhysNameArray; nResultTags: integer) return ArgStatusInfo
--is		
--	variable stored, ready, nextReady: std_logic_vector(0 to 2) := (others=>'0');
--	variable locs, nextLocs: SmallNumberArray(0 to 2) := (others=>(others=>'0'));
--	variable vals: MwordArray(0 to 2) := (others=>(others=>'0'));
--	variable res: ArgStatusInfo;
--begin
--	stored := not av.missing;	
--	
--	-- Find where tag agrees with s0
--	for i in --tags'range loop -- CAREFUL! Is this loop optimal for muxing?
--				--0 to nResultTags-1 loop
--				nResultTags-1 downto 0 loop
--		
--		if tags(i) = pa.s0 then
--			ready(0) := '1';
--			locs(0) := i2slv(i, SMALL_NUMBER_SIZE);
--			vals(0) := content(i);
--		end if;
--		if tags(i) = pa.s1 then
--			ready(1) := '1';
--			locs(1) := i2slv(i, SMALL_NUMBER_SIZE);
--			vals(1) := content(i);
--		end if;
--		if tags(i) = pa.s2 then
--			ready(2) := '1';
--			locs(2) := i2slv(i, SMALL_NUMBER_SIZE);
--			vals(2) := content(i);
--		end if;
--	end loop;
--	
--	for i in nextTags'range loop
--		
--		if nextTags(i) = pa.s0 then
--			nextReady(0) := '1';
--			nextLocs(0) := i2slv(i, SMALL_NUMBER_SIZE);
--		end if;
--		if nextTags(i) = pa.s1 then
--			nextReady(1) := '1';
--			nextLocs(1) := i2slv(i, SMALL_NUMBER_SIZE);
--		end if;
--		if nextTags(i) = pa.s2 then
--			nextReady(2) := '1';
--			nextLocs(2) := i2slv(i, SMALL_NUMBER_SIZE);
--		end if;			
--	end loop;
--	
--	res.stored := stored;
--	res.ready := ready;
--	res.locs := locs;
--	res.vals := vals;
--	res.nextReady := nextReady;
--	res.nextLocs := nextLocs;
--	
--	return res;								
--end function;
--
--
--function getArgInfoArrayD(data: InstructionStateArray; vals: MwordArray; 
--										resultTags, nextTags: PhysNameArray; nResultTags: integer)
--return ArgStatusInfoArray is
--	variable res: ArgStatusInfoArray(data'range);
--begin
--	for i in res'range loop
--		res(i) := getForwardingStatusInfoD(data(i).argValues, data(i).physicalArgs, vals, 
--					resultTags, nextTags, nResultTags);
--	end loop;
--	
--	return res;
--end function;

	
function extractPhysSources(data: InstructionStateArray) return PhysNameArray is
	variable res: PhysNameArray(0 to 3*data'length-1) := (others => (others => '0'));
begin
	for i in data'range loop
		res(3*i + 0) := data(i).physicalArgs.s0;
		res(3*i + 1) := data(i).physicalArgs.s1;
		res(3*i + 2) := data(i).physicalArgs.s2;		
	end loop;
	return res;
end function;	
	
function extractPhysS0(data: InstructionStateArray) return PhysNameArray is
	variable res: PhysNameArray(0 to data'length-1) := (others => (others => '0'));
begin
	for i in data'range loop
		res(i) := data(i).physicalArgs.s0;		
	end loop;
	return res;
end function;		

function extractPhysS1(data: InstructionStateArray) return PhysNameArray is
	variable res: PhysNameArray(0 to data'length-1) := (others => (others => '0'));
begin
	for i in data'range loop
		res(i) := data(i).physicalArgs.s1;		
	end loop;
	return res;
end function;		

function extractPhysS2(data: InstructionStateArray) return PhysNameArray is
	variable res: PhysNameArray(0 to data'length-1) := (others => (others => '0'));
begin
	for i in data'range loop
		res(i) := data(i).physicalArgs.s2;		
	end loop;
	return res;
end function;		


	
function extractMissing(data: InstructionStateArray) return std_logic_vector is
	variable res: std_logic_vector(0 to 3*data'length-1) := (others => '0');
begin
	for i in data'range loop
		res(3*i + 0) := data(i).argValues.missing(0);
		res(3*i + 1) := data(i).argValues.missing(1);
		res(3*i + 2) := data(i).argValues.missing(2);		
	end loop;
	return res;
end function;	

function extractMissing0(data: InstructionStateArray) return std_logic_vector is
	variable res: std_logic_vector(0 to data'length-1) := (others => '0');
begin
	for i in data'range loop
		res(i) := data(i).argValues.missing(0);
	end loop;
	return res;
end function;

function extractMissing1(data: InstructionStateArray) return std_logic_vector is
	variable res: std_logic_vector(0 to data'length-1) := (others => '0');
begin
	for i in data'range loop
		res(i) := data(i).argValues.missing(1);
	end loop;
	return res;
end function;
	
function extractMissing2(data: InstructionStateArray) return std_logic_vector is
	variable res: std_logic_vector(0 to data'length-1) := (others => '0');
begin
	for i in data'range loop
		res(i) := data(i).argValues.missing(2);
	end loop;
	return res;
end function;


							
				function storeQueueNext(content: InstructionStateArray;
									  livingMask: std_logic_vector;
									  newContent: InstructionStateArray;
									  newMask: std_logic_vector;
									  nLiving: integer;
									  sending: integer;
									  receiving: std_logic;
									  dataA, dataD: InstructionState;
									  wrA, wrD: std_logic;
									  mA, mD: std_logic_vector;
									  clearCompleted: boolean
									  ) return InstructionStateArray is
					constant LEN: integer := content'length;
					variable tempContent, tempNewContent: InstructionStateArray(0 to LEN + PIPE_WIDTH-1)
									:= (others => DEFAULT_INSTRUCTION_STATE);
					variable tempMask: std_logic_vector(0 to LEN + PIPE_WIDTH-1) := (others => '0');
					variable res: InstructionStateArray(0 to LEN-1)
											:= (others => DEFAULT_INSTRUCTION_STATE);--content;
					variable outMask: std_logic_vector(0 to LEN-1) := (others => '0');
					variable c1, c2: std_logic := '0';
					variable sv: Mword := (others => '0');
						variable sh: integer := sending;
				begin							
					tempContent(0 to LEN-1) := content;
					for i in 0 to LEN-1 loop
						tempNewContent(i) := newContent((nLiving-sh + i) mod PIPE_WIDTH);
					end loop;
					
					tempMask(0 to LEN-1) := livingMask;

					-- Shift by n of sending
					tempContent(0 to LEN - 1) := tempContent(sh to sh + LEN-1);
					-- CAREFUL: tempMask must have enough zeros at the end to clear outdated 'ones'!
					outMask(0 to LEN-1) := tempMask(sh to sh + LEN-1); 
					
					for i in 0 to LEN-1 loop
						res(i).basicInfo := DEFAULT_BASIC_INFO;
							c1 := res(i).controlInfo.completed;
							c2 := res(i).controlInfo.completed2;
							res(i).controlInfo := DEFAULT_CONTROL_INFO;
							res(i).controlInfo.completed := c1;
							res(i).controlInfo.completed2 := c2;
						res(i).bits := (others => '0');
						res(i).classInfo := DEFAULT_CLASS_INFO;
						res(i).constantArgs := DEFAULT_CONSTANT_ARGS;
						res(i).virtualArgs := DEFAULT_VIRTUAL_ARGS;
						res(i).virtualDestArgs := DEFAULT_VIRTUAL_DEST_ARGS;
						res(i).physicalArgs := DEFAULT_PHYSICAL_ARGS;
						res(i).physicalDestArgs := DEFAULT_PHYSICAL_DEST_ARGS;
						
						res(i).numberTag := (others => '0');
						res(i).gprTag := (others => '0');
						
							sv := res(i).argValues.arg2;
							res(i).argValues := DEFAULT_ARG_VALUES;
							res(i).argValues.arg2 := sv;
						res(i).target := (others => '0');
						
						if outMask(i) = '1' then									
							res(i).groupTag := tempContent(i).groupTag;
							res(i).operation := tempContent(i).operation; --(Memory, store);														
						else
							res(i).groupTag := tempNewContent(i).groupTag;
							res(i).operation := tempNewContent(i).operation; --(Memory, store);							
						end if;
															
						if (wrA and mA(i)) = '1' then
							res(i).argValues.arg1 := dataA.result;
							res(i).controlInfo.completed := '1';
						elsif outMask(i) = '1' then
							res(i).argValues.arg1 := tempContent(i).argValues.arg1;
							res(i).controlInfo.completed := tempContent(i).controlInfo.completed;									
						else
							res(i).argValues.arg1 := tempNewContent(i).argValues.arg1;
							if clearCompleted then
								res(i).controlInfo.completed := '0';
							else
								res(i).controlInfo.completed := tempNewContent(i).controlInfo.completed;
							end if;	
						end if;

						if (wrD and mD(i)) = '1' then									
							res(i).argValues.arg2 := dataD.argValues.arg2;
							res(i).controlInfo.completed2 := '1';
						elsif outMask(i) = '1' then
							res(i).argValues.arg2 := tempContent(i).argValues.arg2;
							res(i).controlInfo.completed2 := tempContent(i).controlInfo.completed2;
						else	
							res(i).argValues.arg2 := tempNewContent(i).argValues.arg2;
							if clearCompleted then
								res(i).controlInfo.completed2 := '0';
							else
								res(i).controlInfo.completed2 := tempNewContent(i).controlInfo.completed2;
							end if;
						end if;

					end loop;
					
					return res;
				end function;

				--	function routeToIQ(sd: StageDataMulti; srcVec: std_logic_vector) return StageDataMulti is

--		variable res: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

--		variable k: natural := 0;

--			constant CLEAR_EMPTY_SLOTS_IQ_ROUTING: boolean := false;

--	begin

--		if not CLEAR_EMPTY_SLOTS_IQ_ROUTING then

--			res.data := sd.data;

--		end if;

--	

--		for i in sd.fullMask'range loop

--			if srcVec(i) = '1' then

--				if sd.fullMask(k) = '0' then -- If no more instructions in packet, stop

--					exit;

--				end if;

--				res.fullMask(k) := '1';

--				res.data(k) := sd.data(i);

--				k := k + 1;

--			end if;

--		end loop;

--		return res;

--	end function;	

end OLD_FUNCTIONS;
