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

use work.Decoding2.all;

use work.TEMP_DEV.all;
use work.GeneralPipeDev.all;


package ProcLogicFront is

function getInstructionClassInfo(ins: InstructionState) return InstructionClassInfo;

-- Writes target to the 'target' field
function setBranchTarget(ins: InstructionState) return InstructionState;

function basicJumpAddress(ins: InstructionState) return Mword;

function instructionFromWord(w: word) return InstructionState;

function decodeInstruction(inputState: InstructionState) return InstructionState;

-- TEMP?
function TEMP_branchPredict(ins: InstructionState) return InstructionState;

function decodeMulti(sd: StageDataMulti) return StageDataMulti;

function pc2size(pc: Mword; alignBits: natural; capacity: PipeFlow) return PipeFlow;

function bufferAHNext(content, newContent: AnnotatedHwordArray; 
								fetchData: StageDataPC;
								nFull, nOut, nIn: integer) 
return AnnotatedHwordArray;

function newFromHbuffer(content: AnnotatedHwordArray; fullMask: std_logic_vector)
return HbuffOutData;

function stagePCNext(content, newContent: StageDataPC;
							full, sending, receiving: std_logic) return StageDataPC;
function newPCData(content: StageDataPC; fe: FrontEventInfo) return StageDataPC;

function stageFetchNext(content, newContent: StageDataPC;
							full, sending, receiving: std_logic) return StageDataPC;

function getAnnotatedHwords(fetchData: StageDataPC; fetchBlock: HwordArray)
return AnnotatedHwordArray;

function getFrontEvents(se0: StageMultiEventInfo;
									intEvent: std_logic;
									backEvent: std_logic;
									backCausing: InstructionState) 
return FrontEventInfo;

function stageMultiEvents(sd: StageDataMulti; isNew: std_logic) return StageMultiEventInfo;

function getNextInstructionAddress(ins: InstructionState) return Mword;

end ProcLogicFront;



package body ProcLogicFront is

function getInstructionClassInfo(ins: InstructionState) return InstructionClassInfo is
	variable ci: InstructionClassInfo := defaultClassInfo;
begin
	-- TODO: determine:
	--			illegal/undefined (incl. privilege level) 
	-- 		? what kind?
		-- Proposition: if condition is 'none', set "branch confirmed" 
		--				// or use "speculated"? Fact of being sure don't change anyth when constant jump?
		
		-- If branch upon r0, result also sure
		
		-- If branch conditionally, not on r0, need to speculate
			
	--			other special conditions: fetchLock? halt? etc...


			if ins.operation.func = sysUndef then
				ci.undef := '1';
			end if;

			ci.branchAlways := '0';
			ci.branchCond := '0';

			if 	 	(ins.operation.func = jump and ins.constantArgs.c1 = COND_NONE)
				or		ins.operation.func = sysRetE
				or 	ins.operation.func = sysRetI
			then
				ci.branchAlways := '1';
			elsif (ins.operation.func = jump and ins.constantArgs.c1 /= COND_NONE) then 
				ci.branchCond := '1';	
			end if;
			
			-- TODO: complete this!
			if  ins.operation.unit = System then
				ci.system := '1';
			end if;
			
			if  (ins.operation.func = sysMTC) then
				--res.writeSysSel := '1';
				ci.fetchLock := '1';
			else
				ci.fetchLock := '0';
			end if;

			if (ins.operation.func = sysMFC) then
				--res.readSysSel := '1';
			end if;


				
	return ci;
end function;

-- TODO, CAREFUL: inspect other possible paths, like "jump to next" for some instructions?
function setBranchTarget(ins: InstructionState) return InstructionState is
	variable res: InstructionState := ins;
begin
	-- NOTE: jump relative to this instruction, not next one
	res.target := i2slv(slv2s(ins.constantArgs.imm) + slv2s(ins.basicInfo.ip), MWORD_SIZE);		
	return res;
end function;	

function basicJumpAddress(ins: InstructionState) return Mword is
begin
	if ins.controlInfo.branchExecute = '1' then
		return ins.target;
	elsif ins.controlInfo.branchCancel = '1' then
		return ins.result;
	else -- TODO, CAREFUL: inspect other possible paths
		return (others=>'0');
	end if;		
end function;

function instructionFromWord(w: word) return InstructionState is
	variable res: InstructionState := defaultInstructionState;
begin
	res.bits := w;
	return res;
end function;

function decodeInstruction(inputState: InstructionState) return InstructionState is
	variable res: InstructionState := inputState;
	variable ofs: OpFieldStruct;
begin
	ofs := getOpFields(inputState.bits);
	ofsInfo(ofs,
					res.operation,
					res.classInfo,
					res.constantArgs,
					res.virtualArgs,
					res.virtualDestArgs);
	
	res.classInfo := getInstructionClassInfo(res);	
		
	-- TODO: other control flow considerations: detect exceptions etc.! 
	--...
		if res.classInfo.undef = '1' then
				res.controlInfo.s0Event := '1';
			res.controlInfo.unseen := '1';
			res.controlInfo.exception := '1';
			res.controlInfo.exceptionCode := i2slv(ExceptionType'pos(undefinedInstruction), SMALL_NUMBER_SIZE);
		end if;
		
		-- CAREFUL! Indicate that fetch lock must be applied
		if res.classInfo.fetchLock = '1' then 
			res.controlInfo.unseen := '1';
			res.controlInfo.fetchLockSignal := '1';
		end if;
		
		
		-- TEMP!
		res := setBranchTarget(res); 
		
	return res;
end function;

function TEMP_branchPredict(ins: InstructionState) return InstructionState is
	variable res: InstructionState := ins;
begin
	if res.classInfo.branchCond = '1' then
		res.controlInfo.unseen := '1';	
	
		if res.constantArgs.c1 = COND_NONE then -- 'none'; CAREFUL! Use correct codes!
			-- Jump
				res.controlInfo.s0Event := '1';
			res.controlInfo.branchSpeculated := '1'; -- ??
			res.controlInfo.branchConfirmed := '1'; -- ??
		elsif res.constantArgs.c1 = COND_Z and res.virtualArgs.s0 = "00000" then -- 'zero'; CAREFUL! ...
			-- Jump
				res.controlInfo.s0Event := '1';
			res.controlInfo.branchSpeculated := '1'; -- ??
			res.controlInfo.branchConfirmed := '1'; -- ??
		elsif res.constantArgs.c1 = COND_NZ and res.virtualArgs.s0 /= "00000" then -- 'one'; CAREFUL!...
			-- No jump!
		else
			-- Need to speculate...
			-- ! src0 should be register other than r0
			-- Check	if displacement is negative
			--		TODO	
		end if;
	end if;
	
	return res;
end function;
 
function decodeMulti(sd: StageDataMulti) return StageDataMulti is
	variable res: StageDataMulti := sd;
begin
	for i in 0 to PIPE_WIDTH-1 loop -- NOTE: Don't check fullMask?
		res.data(i) := decodeInstruction(sd.data(i));		
	end loop;
	return res;
end function;

function pc2size(pc: Mword; alignBits: natural; capacity: PipeFlow) return PipeFlow is
	variable res: PipeFlow := (others=>'0');
	variable ending, cap: natural;
begin
	ending := slv2u(pc(alignBits-1 downto 0));
	-- "ending" is eq to num of bytes over aligned PC
	cap := binFlowNum(capacity);
	res := i2slv(cap - slv2u(pc(alignBits-1 downto 1)), PipeFlow'length);
	return res;
end function;

function bufferAHNext(content, newContent: AnnotatedHwordArray; 
								fetchData: StageDataPC;
								nFull, nOut, nIn: integer) 
return AnnotatedHwordArray is
	variable temp: AnnotatedHwordArray(0 to content'length + newContent'length - 1) 
			:= (others => DEFAULT_ANNOTATED_HWORD);	
	variable res: AnnotatedHwordArray(content'range) 
			:= (others => DEFAULT_ANNOTATED_HWORD);
	variable newShift: integer := 0; -- CAREFUL! This determines where actual data starts in newContent
begin	
	newShift := slv2u(fetchData.pc(ALIGN_BITS-1 downto 1));				
	temp(0 to content'length - 1 - nOut) := content(nOut to content'length-1);
	temp(nFull-nOut to nFull-nOut+nIn-1) := newContent(newShift to newShift + nIn - 1);
	res := temp(0 to content'length - 1);
	return res;
end function;

function newFromHbuffer(content: AnnotatedHwordArray; fullMask: std_logic_vector)
return HbuffOutData is
	variable res: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	variable ret: HbuffOutData;
	variable j: integer := 0;
	variable nOut: integer;
begin
	for i in 0 to PIPE_WIDTH-1 loop
		nOut := PIPE_WIDTH;
		if (fullMask(j) and content(j).shortIns) = '1' then
			res.fullMask(i) := '1';
			res.data(i).bits := content(j).bits & X"0000";
			res.data(i).basicInfo := content(j).basicInfo;
			j := j + 1;
		elsif (fullMask(j) and fullMask(j+1)) = '1' then
			res.fullMask(i) := '1';
			res.data(i).bits := content(j).bits & content(j+1).bits;
			res.data(i).basicInfo := content(j).basicInfo;		
			j := j + 2;
		else
			nOut := i;
			exit;
		end if;			
	end loop;
	-- CAREFUL: now 'j' is the number of consumed hwords?
	ret.sd := res;
	ret.nOut := i2slv(nOut, SMALL_NUMBER_SIZE);
	ret.nHOut := i2slv(j, SMALL_NUMBER_SIZE);
	return ret;
end function;

function stagePCNext(content, newContent: StageDataPC; 
							full, sending, receiving: std_logic) return StageDataPC is
	variable res: StageDataPC := DEFAULT_DATA_PC;
begin
	if receiving = '1' then -- take full
		res := newContent;
	elsif sending = '1' then -- take empty
		null; -- default (should neve happen?)
	else -- stall
		if full = '1' then
			res := content;
		else -- leave it empty
			null; -- should never happen?
		end if;
	end if;	
	return res;
end function;

function newPCData(content: StageDataPC; fe: FrontEventInfo) return StageDataPC is
	variable res: StageDataPC := content;
	variable newPC: Mword := (others=>'0');
begin
	if fe.eventOccured = '1' then -- when from exec or front	
		-- TODO: need more cases to handle exc return and int return etc? Or maybe these are enough?
		if fe.fromInt = '1' then
			res.basicInfo.ip := INT_BASE; -- TEMP!
			res.basicInfo.intLevel := "10000000";	
		elsif fe.causing.controlInfo.exception = '1' then
			res.basicInfo.ip := EXC_BASE(MWORD_SIZE-1 downto fe.causing.controlInfo.exceptionCode'length)
									& fe.causing.controlInfo.exceptionCode(
															fe.causing.controlInfo.exceptionCode'length-1 downto ALIGN_BITS)
									& EXC_BASE(ALIGN_BITS-1 downto 0);			
			res.basicInfo.systemLevel := "10000000";
		elsif fe.causing.controlInfo.branchExecute = '1' then
			res.basicInfo.ip := fe.causing.target;
		elsif fe.causing.controlInfo.branchCancel = '1' then
			res.basicInfo.ip := fe.causing.result;
		end if;				
	else	
		res.basicInfo.ip := 
				i2slv(slv2u(content.pcBase(MWORD_SIZE-1 downto ALIGN_BITS)) + 1, MWORD_SIZE - ALIGN_BITS)
				& i2slv(0, ALIGN_BITS);		
	end if;	
	res.pc := res.basicInfo.ip;	
	res.pcBase := res.basicInfo.ip(MWORD_SIZE-1 downto ALIGN_BITS)	& i2slv(0, ALIGN_BITS);
	res.nH := i2slv(FETCH_BLOCK_SIZE - (slv2u(res.basicInfo.ip(ALIGN_BITS-1 downto 1))), SMALL_NUMBER_SIZE);
	return res;
end function;

function stageFetchNext(content, newContent: StageDataPC;
							full, sending, receiving: std_logic) return StageDataPC is
	variable res: StageDataPC := DEFAULT_DATA_PC;
begin
	if receiving = '1' then -- take full
		res := newContent;
	elsif sending = '1' then -- take empty
		null; -- empty, default
	else -- stall
		if full = '1' then
			res := content;
		else
			null; -- leave it empty
		end if;
	end if;	
	return res;
end function;

function getAnnotatedHwords(fetchData: StageDataPC; fetchBlock: HwordArray)
return AnnotatedHwordArray is
	variable res: AnnotatedHwordArray(0 to 2*PIPE_WIDTH-1);
	variable hwordBasicInfo: InstructionBasicInfo := fetchData.basicInfo;	
begin
	for i in 0 to 2*PIPE_WIDTH-1 loop
		hwordBasicInfo.ip := fetchData.pcBase(MWORD_SIZE-1 downto ALIGN_BITS) & i2slv(2*i, ALIGN_BITS);
		res(i) := (bits => fetchBlock(i),
					  ip => hwordBasicInfo.ip,
					  basicInfo => hwordBasicInfo,
					  shortIns => '0'); -- TEMP!
	end loop;
	return res;
end function;

function getFrontEvents(se0: StageMultiEventInfo;
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
	e0 := se0.eventOccured;
	
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
	elsif e0 = '1' then
		affectedVec := "11100";
		causingVec := "00010";	
		causing := se0.causing;
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
		
	res.ePC := ePC;
	res.eFetch := eFetch;
	res.eHbuff := eHbuff;
	res.e0 := e0;
	res.e1 := '0';	
	
	res.causingVec := causingVec;
	res.affectedVec := affectedVec;
	res.causing := causing;
	
	return res;
end function;


function stageMultiEvents(sd: StageDataMulti; isNew: std_logic) return StageMultiEventInfo is
	variable res: StageMultiEventInfo := (eventOccured => '0', causing => defaultInstructionState,
														partialKillMask => (others=>'0'));
	variable t, tp: std_logic := '0';
	variable eVec: std_logic_vector(0 to PIPE_WIDTH-1) := (others=>'0');
begin
	res.causing := sd.data(PIPE_WIDTH-1);
	if isNew = '0' then
		return res;
	end if;
	
	for i in sd.fullMask'reverse_range loop
		-- Is there an event at this slot? 
		t := sd.fullMask(i) and 
		(	sd.data(i).controlInfo.pcEvent
		or sd.data(i).controlInfo.fetchEvent
		or sd.data(i).controlInfo.hbuffEvent
		or sd.data(i).controlInfo.s0Event);
		
		eVec(i) := t;
		if t = '1' then
			res.causing := sd.data(i);				
		end if;
	end loop;

	for i in sd.fullMask'range loop
		if tp = '1' then
			res.partialKillMask(i) := '1';
		end if;
		tp := tp or eVec(i);			
	end loop;
	res.eventOccured := tp;
	
	return res;
end function;

function getNextInstructionAddress(ins: InstructionState) return Mword is
	variable nBytes: natural;
begin
	-- TODO: when short instructions introduced, differentiate into 2B and 4B 
	if false then -- For short ones
		nBytes := 2;			
	else
		nBytes := 4;
	end if;	
	return i2slv( slv2s(ins.basicInfo.ip) + nBytes, MWORD_SIZE);		
end function;
 
end ProcLogicFront;
