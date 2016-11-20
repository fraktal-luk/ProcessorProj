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

 
end OLD_FUNCTIONS;
