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
use work.GeneralPipeDev.all;

package CommonRouting is

-- Type for table: ExecUnit -> exec subpipe number
type ExecUnitToNaturalTable is array(ExecUnit'left to ExecUnit'right) of integer;

-- Routing table for issue queues
-- 0 - ALU, Div
-- 1 - MAC
-- 2 - Memory
-- 3 - Jump, System
constant N_ISSUE_QUEUES: natural := 4;
constant ISSUE_ROUTING_TABLE: ExecUnitToNaturalTable := (
		General => -1, -- Should never happen!
		ALU => 0,
		MAC => 1,
		Divide => 0,
		Jump => 3,
		Memory => 2,
		System => 3);

-- Calculates the info about interpretation of hword buffer content
function wholeInstructionData(--hwords: HwordArray; 
										shortOpcodes: std_logic_vector; nH, nIMax: integer)
				return HwordBufferData;

-- !! nIMax is the max number of instructions to decode WARNING! Maybe just use words'length ??
-- And remember, length of "cumulSize" may need to be +1 than words'length (if we index c.S. form 0) 
--  And "cumulSize" together with "shortI." determines the position of each instr in hword array,
--	 so "words", although it's not enough (because predecode info, itself used as "shortOpcodes" is already
--	  present and should be sent further too to prevent redundant logic in next stage), are not needed as output.
--		They can be extracted with "cumulSize" + "shortI" along with other info associated with each hword 	
procedure wholeInstructions(--hwords: in HwordArray; 
										shortOpcodes: in std_logic_vector; nH, nIMax: in integer; 
									 readyOps: out std_logic_vector; shortInstructions: out std_logic_vector;
									 words: out WordArray;
									 cumulSize: out IntArray -- This says how much hwords we consume if taking k ops
									-- WARNING! cumulSize has elements corresponding to (0, 1, 2...) ops, not from 1
									);

-- Prototype for extraction - TODO: change it to include additional info associated with each hword?
function extractFromHalves(hwords: HwordArray; cumulSize: IntArray;
									readyOps, shortInstructions: std_logic_vector)
									return WordArray;
-- Convert flow in number of instrucitons into num of hwords, according to additional data
function getHwordNumber(sending: PipeFlow; cumulSize: IntArray) return PipeFlow;

-- Gives queue number based on functional unit
function unit2queue(unit: ExecUnit) return natural;

function findByExecUnit(iv: InstructionStateArray; seeking: ExecUnit) return std_logic_vector;

-- Show which subpipes are allowed to send result to CQ (maybe all can always, depending on version)
function tagsAllowedCQ(tags: PhysNameArray; first, last: PhysName) return std_logic_vector;

-- Show which CQ slots will get an op from subpipes
function acceptingSlotsCQ(tags: PhysNameArray; allowed: std_logic_vector;
											first, last: PhysName) return std_logic_vector;

-- ????
-- Get '1' bits for remaining slots, pushed to left
function pushToLeft(fullSlots, sendingSlots: std_logic_vector) return std_logic_vector;

function getSendingFromCQ(livingMask: std_logic_vector) return std_logic_vector;

function selectInstructions(content: PipeStageDataU; numbers: IntArray; nI: integer) return PipeStageDataU;

function getKillMask(content: PipeStageDataU; fullMask: std_logic_vector; tag: SmallNumber)
return std_logic_vector;

-- NOTE: This would be needed if want to only find signals from proper stage
function getS0EventMask(sd: StageDataMulti; isNew: std_logic) return std_logic_vector;

function getEventMask(sd: StageDataMulti; isNew: std_logic) return std_logic_vector;

	function getCausingFrontStage(pcE, fetchE: std_logic; 
											hbufferE: std_logic_vector; s0E, s1E: std_logic_vector) 
	return std_logic_vector; -- FrontStages;	

	function getCausingFrontElement(pcE, fetchE: std_logic; 
											hbufferE: std_logic_vector; s0E, s1E: std_logic_vector;
											causingFS: std_logic_vector) 
	return integer;

	function getStagesToKill(causingFS: std_logic_vector; execES: std_logic) return std_logic_vector;


function TEMP_frontEvents(pcData: TEMP_StageDataPC; fetchData: TEMP_StageDataPC;--TEMP_StageDataFetch;
									hbufferData: HwordBufferData; stageData0, stageData1: StageDataMulti;
									nPC, nFetch: std_logic;
									--nHbuff: std_logic_vector(0 to HBUFFER_SIZE-1); -- Should be in hbufferData?
									n0, n1: std_logic;
									intEvent: std_logic;									
									backEvent: std_logic;
									backCausing: InstructionState) 
return FrontEventInfo;

function extractFromAH(arr: AnnotatedHwordArray; cumulSize: IntArray; 
									readyOps, shortInstructions: std_logic_vector)
									return InstructionStateArray;

function TEMP_baptize(sd: StageDataMulti; baseNum: integer) 
return StageDataMulti; 

-- Makes physical names the same as virtual names	
function DUMMY_rename(sd: StageDataMulti) return StageDataMulti;
		
		function getVirtualArgs(insVec: StageDataMulti) return RegNameArray;
		function getVirtualDests(insVec: StageDataMulti) return RegNameArray;
		function getDestMask(insVec: StageDataMulti) return std_logic_vector;
		
		function renameRegs(insVec: StageDataMulti; takeVec, destMask: std_logic_vector;
									psVec, pdVec: PhysNameArray; gprTags: SmallNumberArray) 		
		return StageDataMulti;
		
		function renameAndBaptize(insVec: StageDataMulti; psVec, pdVec: PhysNameArray;
											gprTags: SmallNumberArray;
											baseNum: integer) 
		return StageDataMulti; 
	
	
	function routeToIQ(sd: StageDataMulti; srcVec: std_logic_vector) return StageDataMulti;	
	
end CommonRouting;




package body CommonRouting is

function wholeInstructionData(--hwords: HwordArray;
										shortOpcodes: std_logic_vector; nH, nIMax: integer)
				return HwordBufferData is
	variable res: HwordBufferData;

	variable readyOps: std_logic_vector(0 to PIPE_WIDTH-1) := (others=>'0');
	variable shortInstructions: std_logic_vector(0 to PIPE_WIDTH-1) := (others=>'0');
	variable words: WordArray(0 to PIPE_WIDTH-1) := (others=>(others=>'0'));
	variable cumulSize: IntArray(0 to PIPE_WIDTH) := (others=>0);
begin
	wholeInstructions(--hwords, 
							shortOpcodes, nH, nIMax, 
							readyOps, shortInstructions, words, cumulSize);
	res.readyOps := readyOps;
	res.shortInstructions := shortInstructions;
	res.words := words;
	res.cumulSize := cumulSize;
	return res;
end function;				

procedure wholeInstructions(--hwords: in HwordArray; 
										shortOpcodes: in std_logic_vector; 
										nH, nIMax: in integer; 
									 readyOps: out std_logic_vector; shortInstructions: out std_logic_vector;
									 words: out WordArray;
									 cumulSize: out IntArray -- This says how much hwords we consume if taking k ops		 
									) is
	variable i: integer := 0;
	variable j: integer := 0;
	variable prevLong: boolean := false;
begin
	readyOps := (others=>'0');
	words := (others=>(others=>'0'));
	cumulSize := (others=>0);
	
	while  nH <= shortOpcodes'length and i < nH 	
		and nIMax <= readyOps'length and j < nIMax 
		and j < PIPE_WIDTH	
	loop	
		if prevLong then
			prevLong := false;
			--words(j) := hwords(i-1) & hwords(i);
			readyOps(j) := '1';
			shortInstructions(j) := '0';
			cumulSize(j+1) := i+1;
			j := j+1;
		elsif shortOpcodes(i) = '1' then
			prevLong := false;
			--words(j) := hwords(i) & X"0000";
			readyOps(j) := '1';
			shortInstructions(j) := '1';
			cumulSize(j+1) := i+1;
			j := j+1;		
		else
			prevLong := true;	
		end if;
		
		i := i + 1;
	end loop;
	
end procedure;

function extractFromHalves(hwords: HwordArray; cumulSize: IntArray; 
									readyOps, shortInstructions: std_logic_vector)
									return WordArray is
	variable res: WordArray(readyOps'range) := (others=>(others=>'0'));
	variable j: natural := 0;
begin
	-- Check if cumulSize can be used for indexing!
	for k in cumulSize'range loop
		if cumulSize(k) < 0 or cumulSize(k) >= hwords'length then
			return res;
		end if;
	end loop;

	for i in readyOps'range loop
		if readyOps(i) = '0' then 
			exit;
		end if;
		
		if shortInstructions(i) = '1' then
			res(i) := hwords(cumulSize(i)) & X"0000";
		else
			res(i) := hwords(cumulSize(i)) & hwords(cumulSize(i)+1);
		end if;
	end loop;
	return res;
end function;

function getHwordNumber(sending: PipeFlow; cumulSize: IntArray) return PipeFlow is
	variable res: PipeFlow;
	variable se, seH: natural;
begin
	se := binFlowNum(sending);			
	seH := cumulSize(se);
	res := i2slv(seH, PipeFlow'length);
	return res;
end function;


function unit2queue(unit: ExecUnit) return natural is
begin
	return ISSUE_ROUTING_TABLE(unit);
end function;


function findByExecUnit(iv: InstructionStateArray; seeking: ExecUnit) return std_logic_vector is
	variable res: std_logic_vector(iv'range) := (others=>'0');
begin
	for i in iv'range loop
		if iv(i).operation.unit = seeking then
			res(i) := '1';
		end if;
	end loop;
	return res;
end function;


function tagsAllowedCQ(tags: PhysNameArray; first, last: PhysName) return std_logic_vector is
	variable res: std_logic_vector(tags'range) := (others=>'0');
	variable t, a, b: natural;
begin
	a := slv2u(first);
	b := slv2u(last);
	for i in tags'range loop
		t := slv2u(tags(i));
		if t >= a and t <= b then
			res(i) := '1';
		end if;
	end loop;
	
	return res;
end function;

function acceptingSlotsCQ(tags: PhysNameArray; allowed: std_logic_vector;
									first, last: PhysName) return std_logic_vector is
	variable res: std_logic_vector(0 to CQ_SIZE-1) := (others=>'0');
	variable t, a, b: natural;
begin
	a := slv2u(first);
	b := slv2u(last);
	for i in tags'range loop
		t := slv2u(tags(i));
		if allowed(i) = '1' then
			res(t-a) := '1';
		end if;
	end loop;
	return res;
end function;


function pushToLeft(fullSlots, sendingSlots: std_logic_vector) return std_logic_vector is
	variable res: std_logic_vector(fullSlots'range) := (others => '0');
	variable remaining: std_logic_vector(fullSlots'range) := fullSlots and not sendingSlots;
	variable k: integer := 0;
begin
	for i in remaining'range loop	
		if remaining(i) = '1' then
			res(k) := '1';
			k := k+1;
		end if;
	end loop;
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


function selectInstructions(content: PipeStageDataU; numbers: IntArray; nI: integer) return PipeStageDataU is
	variable res: PipeStageDataU(content'range) := (others=>defaultInstructionState);
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

function getKillMask(content: PipeStageDataU; fullMask: std_logic_vector; tag: SmallNumber)
return std_logic_vector is
	variable res: std_logic_vector(fullMask'range) := (others=>'0');
begin
	for i in res'range loop
		if fullMask(i) = '1' and tagBefore(tag, content(i).numberTag) = '1' then
			res(i) := '1';
		end if;
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
			or sd.data(i).controlInfo.fetchEvent
			or sd.data(i).controlInfo.hbuffEvent
			or sd.data(i).controlInfo.s0Event);
		end loop;
	end if;
	return res;
end function;





	function getCausingFrontStage(pcE, fetchE: std_logic; 
											hbufferE: std_logic_vector; s0E, s1E: std_logic_vector) 
	return std_logic_vector is -- FrontStages is
		
	begin
		if countOnes(s0E) /= 0 then
			return "00010";
		elsif countOnes(hbufferE) /= 0 then
			return "00100";
		elsif fetchE = '1' then
			return "01000";
		elsif pcE = '1' then	
			return "10000"; 
		else
			return "00000"; -- But caller must check if it's really!
		end if;		
	end function;

	
	function getCausingFrontElement(pcE, fetchE: std_logic; 
											hbufferE: std_logic_vector; s0E, s1E: std_logic_vector;
											causingFS: std_logic_vector) 
	return integer is -- FrontStages is
		variable res: integer := 0; --std_logic_vector(0 to PIPE_WIDTH-1);
	begin
		case causingFS is
			when "10000" =>
				res := 0;
			when "01000" =>
				res := 0;
			when "00100" =>
				res := getFirstOnePosition(hbufferE);
			when "00010" =>
				res := getFirstOnePosition(s0E);
			when others =>
				null;
		end case;
		
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


function TEMP_frontEvents(pcData: TEMP_StageDataPC; fetchData: TEMP_StageDataPC;--TEMP_StageDataFetch;		
									hbufferData: HwordBufferData; stageData0, stageData1: StageDataMulti;
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


function extractFromAH(arr: AnnotatedHwordArray; cumulSize: IntArray; 
									readyOps, shortInstructions: std_logic_vector)
									return InstructionStateArray is
	variable res: InstructionStateArray(readyOps'range) := (others=>defaultInstructionState);
	variable j: natural := 0;
begin
	-- Check if cumulSize can be used for indexing!
	for k in cumulSize'range loop
		if cumulSize(k) < 0 or cumulSize(k) >= arr'length then
			return res;
		end if;
	end loop;

	for i in readyOps'range loop
		if readyOps(i) = '0' then 
			exit;
		end if;
		
		if shortInstructions(i) = '1' then
			res(i).bits := arr(cumulSize(i)).bits & X"0000";
		else
			res(i).bits := arr(cumulSize(i)).bits & arr(cumulSize(i)+1).bits;
		end if;
			res(i).basicInfo := arr(cumulSize(i)).basicInfo;
		res(i).basicInfo.ip := arr(cumulSize(i)).ip;
		
	end loop;
	return res;
end function;


function TEMP_baptize(sd: StageDataMulti; baseNum: integer) 
return StageDataMulti is
	variable res: StageDataMulti := sd;
begin
	for i in res.data'range loop
		if res.fullMask(i) = '1' then
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
		
		function getVirtualDests(insVec: StageDataMulti) return RegNameArray is
			variable res: RegNameArray(0 to insVec.fullMask'length-1) := (others=>(others=>'0'));
		begin
			for i in insVec.fullMask'range loop
				res(i) := insVec.data(i).virtualDestArgs.d0;
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
		
		function renameRegs(insVec: StageDataMulti; takeVec, destMask: std_logic_vector;
									psVec, pdVec: PhysNameArray; gprTags: SmallNumberArray) 
		return StageDataMulti is
			variable res: StageDataMulti := insVec;
			variable k: natural := 0;					
		begin
			for i in insVec.fullMask'range loop		
					res.data(i).gprTag := gprTags(i); -- ???
				res.data(i).physicalArgs.sel := res.data(i).virtualArgs.sel;
				res.data(i).physicalArgs.s0 := psVec(3*i+0);	
				res.data(i).physicalArgs.s1 := psVec(3*i+1);			
				res.data(i).physicalArgs.s2 := psVec(3*i+2);							
				for j in insVec.fullMask'range loop	
					-- Is s0 equal to prev instruction's dest?				
					if j = i then exit; end if;				
					if insVec.data(i).virtualArgs.s0 = insVec.data(j).virtualDestArgs.d0
						and isNonzero(insVec.data(i).virtualArgs.s0) = '1' -- CAREFUL: don't copy dummy dest for r0
					then
						res.data(i).physicalArgs.s0 := res.data(j).physicalDestArgs.d0;
					end if;		
					if 	 insVec.data(i).virtualArgs.s1 = insVec.data(j).virtualDestArgs.d0
						and isNonzero(insVec.data(i).virtualArgs.s1) = '1' -- CAREFUL: don't copy dummy dest for r0
					then	
						res.data(i).physicalArgs.s1 := res.data(j).physicalDestArgs.d0;						
					end if;	
					if 	 insVec.data(i).virtualArgs.s2 = insVec.data(j).virtualDestArgs.d0 
						and isNonzero(insVec.data(i).virtualArgs.s2) = '1' -- CAREFUL: don't copy dummy dest for r0
					then
						res.data(i).physicalArgs.s2 := res.data(j).physicalDestArgs.d0;						
					end if;						
				end loop;
				res.data(i).physicalDestArgs.sel(0) := destMask(i);
				if takeVec(i) = '1' then
--					res.data(i).physicalDestArgs.d0:= pdVec(i);
					-- actualPhysicalDests(i) := pdVec(k);
					res.data(i).physicalDestArgs.d0 := pdVec(k);
					k := k + 1;
				end if;	
				
				-- CAREFUL! Set 'missing' flags for register args and fill immediate if relevant
				res.data(i).argValues.missing(0) := 	res.data(i).physicalArgs.sel(0) 
																and isNonzero(res.data(i).virtualArgs.s0);
				res.data(i).argValues.missing(1) := 	res.data(i).physicalArgs.sel(1) 
																and isNonzero(res.data(i).virtualArgs.s1);
				res.data(i).argValues.missing(2) := 	res.data(i).physicalArgs.sel(2) 
																and isNonzero(res.data(i).virtualArgs.s2);
				if res.data(i).constantArgs.immSel = '1' then
					res.data(i).argValues.missing(1) := '0';
					res.data(i).argValues.arg1 := res.data(i).constantArgs.imm;					
				end if;	
			end loop;			
		
		
			return res;
		end function;
		
		-- CAREFUL: probably invalid
		function renameAndBaptize(insVec: StageDataMulti; psVec, pdVec: PhysNameArray;
											gprTags: SmallNumberArray;
											baseNum: integer) 
		return StageDataMulti is
			variable res: StageDataMulti := insVec;
			variable k: natural := 0;	
		begin
						
			for i in insVec.fullMask'range loop	
				-- Baptizing
					--if res.fullMask(i) = '1' then -- NOTE: if renaming ignores fullMask, maybe here also? 
						res.data(i).numberTag := i2slv(baseNum + i + 1, SMALL_NUMBER_SIZE);
					--end if;				
			
				-- Renaming (CAREFUL: shouldn't it also depend on fullMask?)
					res.data(i).gprTag := gprTags(i); -- ???
				res.data(i).physicalArgs.sel := res.data(i).virtualArgs.sel;
				res.data(i).physicalArgs.s0 := psVec(3*i+0);	
				res.data(i).physicalArgs.s1 := psVec(3*i+1);			
				res.data(i).physicalArgs.s2 := psVec(3*i+2);							
				for j in insVec.fullMask'range loop	
					-- Is s0 equal to prev instruction's dest?				
					if j = i then exit; end if;				
					if insVec.data(i).virtualArgs.s0 = insVec.data(j).virtualDestArgs.d0 then
						res.data(i).physicalArgs.s0 := pdVec(j);
					end if;		
					if insVec.data(i).virtualArgs.s1 = insVec.data(j).virtualDestArgs.d0 then
						res.data(i).physicalArgs.s1 := pdVec(j);
					end if;	
					if insVec.data(i).virtualArgs.s2 = insVec.data(j).virtualDestArgs.d0 then
						res.data(i).physicalArgs.s2 := pdVec(j);
					end if;						
				end loop;
				res.data(i).physicalDestArgs.sel(0) := res.data(i).virtualDestArgs.sel(0)
									-- CAREFUL: maybe just flag writing to r0 as no output, like this?
														and isNonzero(res.data(i).virtualDestArgs.d0);				
				-- CAREFUL! Here we don't assign PR's for r0
				if (res.data(i).virtualDestArgs.sel(0) and isNonzero(res.data(i).virtualDestArgs.d0)) = '1' then
					res.data(i).physicalDestArgs.d0 := pdVec(k);
					k := k + 1;
				end if;	
				
				-- CAREFUL! Set 'missing' flags for register args and fill immediate if relevant
				res.data(i).argValues.missing(0) := 	res.data(i).physicalArgs.sel(0) 
																and isNonzero(res.data(i).virtualArgs.s0);
				res.data(i).argValues.missing(1) := 	res.data(i).physicalArgs.sel(1) 
																and isNonzero(res.data(i).virtualArgs.s1);
				res.data(i).argValues.missing(2) := 	res.data(i).physicalArgs.sel(2) 
																and isNonzero(res.data(i).virtualArgs.s2);
				if res.data(i).constantArgs.immSel = '1' then
					res.data(i).argValues.missing(1) := '0';
					res.data(i).argValues.arg1 := res.data(i).constantArgs.imm;					
				end if;	
			end loop;			
				
			return res;
		end function;


	-- New routing to IQ, to replace IssueRouting
	function routeToIQ(sd: StageDataMulti; srcVec: std_logic_vector) return StageDataMulti is
		variable res: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
		variable k: natural := 0;
	begin
		for i in sd.fullMask'range loop
			if srcVec(i) = '1' then
				if sd.fullMask(k) = '0' then -- If no more instructions in packet, stop
					exit;
				end if;
				res.fullMask(k) := '1';
				res.data(k) := sd.data(i);
				k := k + 1;
			end if;
		end loop;
		return res;
	end function;	


end CommonRouting;
