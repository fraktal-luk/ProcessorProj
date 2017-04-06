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

--use std.textio.all;


package ProcLogicFront is


function getInstructionClassInfo(ins: InstructionState) return InstructionClassInfo;

-- Writes target to the 'target' field
function setBranchTarget(ins: InstructionState) return InstructionState;

function instructionFromWord(w: word) return InstructionState;

function decodeInstruction(inputState: InstructionState) return InstructionState;

function decodeMulti(sd: StageDataMulti) return StageDataMulti;

-- DEPREC?? How many hwords will be fetched - depends on PC alignment
function pc2size(pc: Mword; alignBits: natural; capacity: PipeFlow) return PipeFlow;

function bufferAHNext(content: InstructionStateArray;
									livingMask: std_logic_vector;
								newContent: InstructionStateArray; 
								fetchData: InstructionState;
									fetchBasicInfo: InstructionBasicInfo;								
								nFull, nOut, nIn: integer) 
return InstructionStateArray;

function TEMP_hbufferFullMaskNext(content: InstructionStateArray;
											livingMask: std_logic_vector;
											newContent: InstructionStateArray;
											prevSending: std_logic;											
											fetchData: InstructionState;
												fetchBasicInfo: InstructionBasicInfo;											
											nFull, nOut, nIn: integer)  
return std_logic_vector;


function TEMP_hbufferStageDataNext(content: InstructionStateArray;
											livingMask: std_logic_vector;
											newContent: InstructionStateArray;
											prevSending: std_logic;
											fetchData: InstructionState;
												fetchBasicInfo: InstructionBasicInfo;											
											nFull, nOut, nIn: integer)  
return StageDataHbuffer;


function newFromHbuffer(content: InstructionStateArray; fullMask: std_logic_vector)
return HbuffOutData;

function newPCData(content: InstructionState; ge: GeneralEventInfo; pcNext, causingNext: Mword)--;
return InstructionState;

function newPCData2(content: InstructionState;
						  commitEvent: std_logic; commitCausing: InstructionState;
						  execEvent: std_logic; execCausing: InstructionState;	
						  decodeEvent: std_logic; decodeCausing: InstructionState;
						  pcNext, causingNext: Mword)
						--					excTarget: InstructionBasicInfo
return InstructionState;

	function NEW_generalEvents(pcData: InstructionState;
										commitEvent: std_logic; commitCausing: InstructionState;
										execEvent: std_logic; execCausing: InstructionState;	
										decodeEvent: std_logic; decodeCausing: InstructionState;
										pcNext, causingNext: Mword)
										--	excTarget: InstructionBasicInfo)
	return GeneralEventInfo;

function getAnnotatedHwords(--fetchData: InstructionState;
									 fetchBasicInfo: InstructionBasicInfo; 
									 fetchBlock: HwordArray)
return InstructionStateArray;

-- TODO, CHECK: use this instead of getGeneralEvents?
function detectEventsMulti(sd: StageDataMulti; receiving: std_logic) return InstructionSlot;

function getGeneralEvents(eventArr: InstructionSlotArray)
return GeneralEventInfo;

function stageMultiEvents(sd: StageDataMulti; isNew: std_logic) return StageMultiEventInfo;

function TEMP_events(inputs: InstructionSlotArray) return InstructionSlotArray;

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

				-- Which clusters?
				-- TEMP!
				ci.mainCluster := '1';
				if ins.operation = (Memory, store) then
					ci.secCluster := '1';
				end if;
				
				-- TODO: branch with link should also contain main cluster because link goes there!
				if ins.operation.unit = Jump then
					ci.secCluster := '1';
					if isNonzero(ins.virtualDestArgs.d0) = '0' then
						ci.mainCluster := '0';
					end if;
				elsif	(ins.operation.unit = System and ins.operation.func /= sysMfc) then
					ci.mainCluster := '0';
					ci.secCluster := '1';
				end if;

			ci.branchAlways := '0';
			ci.branchCond := '0';

			if 	 	(ins.operation.func = jump and ins.constantArgs.c1 = COND_NONE)
				--or		ins.operation.func = sysRetE
				--or 	ins.operation.func = sysRetI
			then
				ci.branchAlways := '1';
			elsif (ins.operation.func = jump and ins.constantArgs.c1 /= COND_NONE) then 
				ci.branchCond := '1';	
			end if;
			
			-- Branch to register
			if ins.operation.func = jump and ins.constantArgs.immSel = '0' then
				ci.branchReg := '1';
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
				-- TEMP: code for predicting every regular jump (even "branch never"!) as taken
--				if res.operation.func = jump then
--					res.controlInfo.newEvent := '1';
--					res.controlInfo.hasEvent := '1';
--					res.controlInfo.newBranch := '1';
--					res.controlInfo.hasBranch := '1';					
--				end if;
	
		if res.classInfo.undef = '1' then
			--res.controlInfo.newEvent := '1';
			--res.controlInfo.hasEvent := '1';			
					--res.controlInfo.exception := '1';
			--res.controlInfo.newException := '1';
			--res.controlInfo.hasException := '1';
			res.controlInfo.exceptionCode := i2slv(ExceptionType'pos(undefinedInstruction), SMALL_NUMBER_SIZE);
		end if;
		
		-- CAREFUL! Indicate that fetch lock must be applied
		if res.classInfo.fetchLock = '1' then
			res.controlInfo.newEvent := '1';
			res.controlInfo.hasEvent := '1';				
			res.controlInfo.newFetchLock := '1';
			res.controlInfo.hasFetchLock := '1';
		end if;
		
		
		res.target := (others => '0');
		-- TEMP!
		--res := setBranchTarget(res); 
		
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
	res := num2flow(cap - slv2u(pc(alignBits-1 downto 1)));
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
	tempX := content & newContent;
			tempMaskX(0 to content'length-1) := livingMask;
	for k in 0 to --content'length + newContent'length - 1 loop
						tempY'length-1 loop
		tempY(k) := newContent(k mod newContent'length); -- & newContent & newContent & newContent;	
	end loop;
			
	--tempX(0 to content'length-1 - nOut) := tempX(nOut to content'length-1);
	--	tempMaskX(0 to content'length-1 - nOut) := tempMaskX(nOut to content'length-1);
		tempX(0 to content'length-1) := tempX(nOut to content'length-1 + nOut);
			tempMaskX(0 to content'length-1) := tempMaskX(nOut to content'length-1 + nOut);	

	--tempY(0 to content'length-1 - newShift) := 
	--	tempY(		(content'length - nFull + nOut) + newShift 
	--				to (content'length - nFull + nOut) + content'length-1 );
		tempY(0 to content'length-1) := 
			tempY(		(content'length - nFull + nOut) + newShift 
								to (content'length - nFull + nOut) + content'length-1 + newShift);

	for p in 0 to content'length-1 loop
		if --nFull - nOut > p then
			tempMaskX(p) = '1' then
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
			tempMaskY(k) := prevSending; --newContentMask(k); -- & newContent & newContent & newContent;
			tempMaskY(content'length + k) := prevSending; --newContentMask(k); -- & newContent & newContent & newContent;
		--end if;
	end loop;
	
	tempMaskX(0 to tempMaskX'length-1 - nOut) := tempMaskX(nOut to tempMaskX'length-1);
		
--	tempMaskY(0 to content'length-1 - newShift) := 
--		tempMaskY(		(content'length - nFull + nOut) + newShift 
--					to (content'length - nFull + nOut) + content'length-1 );
					
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
	for k in 0 to tempY'length-1 loop
		tempY(k) := newContent(k mod newContent'length); -- & newContent & newContent & newContent;	
	end loop;			
			
	for k in 0 to newContent'length - 1 loop
		--if nIn /= 0 then
			tempMaskY(k) := prevSending; --newContentMask(k); -- & newContent & newContent & newContent;
			tempMaskY(content'length + k) := prevSending; --newContentMask(k); -- & newContent & newContent & newContent;
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


function newFromHbuffer(content: InstructionStateArray; fullMask: std_logic_vector)
return HbuffOutData is
	variable res: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	variable ret: HbuffOutData;
	variable j: integer := 0;
	variable nOut: integer;
begin
	for i in 0 to PIPE_WIDTH-1 loop
		res.data(i).bits := content(i).bits(15 downto 0) & X"0000"; --content(i+1).bits;
		res.data(i).basicInfo := content(i).basicInfo;
	end loop;

	for i in 0 to PIPE_WIDTH-1 loop
		nOut := PIPE_WIDTH;
		if (fullMask(j) and --content(j).shortIns) = '1' then
									content(j).classInfo.short) = '1' then
			res.fullMask(i) := '1';
			res.data(i).bits(31 downto 16) := content(j).bits(15 downto 0); -- & content(j+1).bits; --X"0000";
			res.data(i).basicInfo := content(j).basicInfo;
				--res.data(i).basicInfo.intLevel(7 downto 2) := "000000";
				--res.data(i).basicInfo.systemLevel(7 downto 2) := "000000";				
			j := j + 1;
		elsif (fullMask(j) and fullMask(j+1)) = '1' then
			res.fullMask(i) := '1';
			res.data(i).bits := content(j).bits(15 downto 0) & content(j+1).bits(15 downto 0);
			res.data(i).basicInfo := content(j).basicInfo;	
				--res.data(i).basicInfo.intLevel(7 downto 2) := "000000";
				--res.data(i).basicInfo.systemLevel(7 downto 2) := "000000";				
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


function newPCData(content: InstructionState; ge: GeneralEventInfo; pcNext, causingNext: Mword)--;
return InstructionState is
	variable res: InstructionState := content;
	variable newPC: Mword := (others=>'0');
begin
	if ge.eventOccured = '1' then -- when from exec or front		
		if ge.causing.controlInfo.newReset = '1' then -- TEMP!
			res.basicInfo.ip := (others => '0');
			res.basicInfo.intLevel := "00000000";		
		elsif ge.causing.controlInfo.newInterrupt = '1' then
			res.basicInfo.ip := INT_BASE; -- TEMP!
			res.basicInfo.intLevel := "00000001";		
		elsif ge.causing.controlInfo.newException = '1' then
			-- TODO, FIX: exceptionCode sliced - shift left by ALIGN_BITS? or leave just base address
			res.basicInfo.ip := EXC_BASE(MWORD_SIZE-1 downto ge.causing.controlInfo.exceptionCode'length)
									& ge.causing.controlInfo.exceptionCode(
															ge.causing.controlInfo.exceptionCode'length-1 downto ALIGN_BITS)
									& EXC_BASE(ALIGN_BITS-1 downto 0);			
			res.basicInfo.systemLevel := "00000001";			
		elsif ge.causing.controlInfo.newFetchLock = '1' then	
			res.basicInfo.ip := causingNext;
		elsif ge.causing.controlInfo.newBranch = '1' then
			res.basicInfo.ip := ge.causing.target;
		elsif ge.causing.controlInfo.newReturn = '1' then
			res.basicInfo.ip := ge.causing.result;
		end if;				
	else	-- Increment by the width of fetch group
		res.basicInfo.ip := pcNext;
	end if;	

	return res;
end function;


function newPCData2(content: InstructionState;
						  commitEvent: std_logic; commitCausing: InstructionState;
						  execEvent: std_logic; execCausing: InstructionState;	
						  decodeEvent: std_logic; decodeCausing: InstructionState;
						  pcNext, causingNext: Mword)
							--	excTarget: InstructionBasicInfo)
return InstructionState is
	variable res: InstructionState := content;
	variable newPC: Mword := (others=>'0');
begin
	if commitEvent = '1' then -- when from exec or front	
		if commitCausing.controlInfo.newReset = '1' then -- TEMP!
			res.basicInfo.ip := (others => '0');
			res.basicInfo.intLevel := "00000000";				
		elsif commitCausing.controlInfo.newInterrupt = '1' then
			res.basicInfo.ip := INT_BASE; -- TEMP!
			res.basicInfo.intLevel := "00000001";		
		else -- if commitCausing.controlInfo.newException = '1' then
			-- TODO, FIX: exceptionCode sliced - shift left by ALIGN_BITS? or leave just base address
			res.basicInfo.ip := EXC_BASE(MWORD_SIZE-1 downto commitCausing.controlInfo.exceptionCode'length)
									& commitCausing.controlInfo.exceptionCode(
													commitCausing.controlInfo.exceptionCode'length-1 downto ALIGN_BITS)
									& EXC_BASE(ALIGN_BITS-1 downto 0);	
									--		INT_BASE;
			res.basicInfo.systemLevel := "00000001";
		end if;	
	elsif execEvent = '1' then		
		if execCausing.controlInfo.newBranch = '1' then
			res.basicInfo.ip := execCausing.target;
		else -- if execCausing.controlInfo.newReturn = '1'
			res.basicInfo.ip := execCausing.result;
														--target;
		end if;	
	elsif decodeEvent = '1' then		
		if decodeCausing.controlInfo.newFetchLock = '1' then	
			res.basicInfo.ip := causingNext;
		end if;
	else	-- Increment by the width of fetch group
		res.basicInfo.ip := pcNext;
	end if;	

	return res;
end function;


	function NEW_generalEvents(pcData: InstructionState;
										commitEvent: std_logic; commitCausing: InstructionState;
										execEvent: std_logic; execCausing: InstructionState;	
										decodeEvent: std_logic; decodeCausing: InstructionState;
										pcNext, causingNext: Mword)
											--excTarget: InstructionBasicInfo
	return GeneralEventInfo is
		variable res: GeneralEventInfo;
	begin
		res.affectedVec := (others => '0');
		res.eventOccured := '1';
		res.causing := decodeCausing;
	
		if commitEvent = '1' then 
			res.causing := commitCausing;
			res.affectedVec(0 to 4) := (others => '1');
		elsif execEvent = '1' then
			res.causing := execCausing;
			res.affectedVec(0 to 4) := (others => '1');
		elsif decodeEvent = '1' then
			res.causing := decodeCausing;
			res.affectedVec(0 to 3) := (others => '1');
		else
			res.eventOccured := '0';
		end if;
		
		res.newStagePC := newPCData2( pcData,
												commitEvent, commitCausing,
												execEvent, execCausing,
												decodeEvent, decodeCausing,
												pcNext, causingNext);
												--	excTarget);
		
		return res;
	end function;


function getAnnotatedHwords(--fetchData: InstructionState;
									 fetchBasicInfo: InstructionBasicInfo; 
									 fetchBlock: HwordArray)
return InstructionStateArray is
	variable res: InstructionStateArray(0 to 2*PIPE_WIDTH-1) := (others => DEFAULT_ANNOTATED_HWORD);
	variable hwordBasicInfo: InstructionBasicInfo := fetchBasicInfo; --fetchData.basicInfo;
	variable	tempWord: word := (others => '0');
begin
	for i in 0 to 2*PIPE_WIDTH-1 loop
		hwordBasicInfo.ip := fetchBasicInfo.ip(MWORD_SIZE-1 downto ALIGN_BITS) & i2slv(2*i, ALIGN_BITS);
			hwordBasicInfo.intLevel(SMALL_NUMBER_SIZE-1 downto 2) := (others => '0');
			hwordBasicInfo.systemLevel(SMALL_NUMBER_SIZE-1 downto 2) := (others => '0');
		tempWord(15 downto 0) := fetchBlock(i);		

		res(i).bits := tempWord;
		res(i).basicInfo := hwordBasicInfo;
		res(i).classInfo.short := '0'; -- TEMP!	
	end loop;
	return res;
end function;


function detectEventsMulti(sd: StageDataMulti; receiving: std_logic) return InstructionSlot is
	variable res: InstructionSlot := ('0', sd.data(PIPE_WIDTH-1)); 
begin
	for i in sd.fullMask'range loop
		if sd.fullMask(i) = '1' and sd.data(i).controlInfo.newEvent = '1' then
			res := ('1', sd.data(i));
		end if;
	end loop;
	return res;
end function;


function getGeneralEvents(eventArr: InstructionSlotArray)
return GeneralEventInfo is	
	variable res: GeneralEventInfo;
begin
	res.eventOccured := eventArr(0).full;
	--res.fromExec := eventArr(6).data.controlInfo.newEvent;
	--res.fromInt := eventArr(0).ins.controlInfo.newInterrupt;
	res.causing := eventArr(0).ins;
			
		-- CAREFUL! Must have matching indices to work correctly!	
		res.affectedVec := (others => '0');
		for i in res.affectedVec'range loop
			res.affectedVec(i) := eventArr(i).full;
		end loop;
		
	return res;
end function;


function stageMultiEvents(sd: StageDataMulti; isNew: std_logic) return StageMultiEventInfo is
	variable res: StageMultiEventInfo := (eventOccured => '0', causing => defaultInstructionState,
														partialKillMask => (others=>'0'));
	variable t, tp: std_logic := '0';
	variable eVec: std_logic_vector(0 to PIPE_WIDTH-1) := (others=>'0');
begin
	-- TODO: change default res.causing to the value "causing" input of the pipe stage?
	res.causing := sd.data(PIPE_WIDTH-1);
	if isNew = '0' then
		return res;
	end if;
	
	for i in sd.fullMask'reverse_range loop
		-- Is there an event at this slot? 
		t := sd.fullMask(i) and sd.data(i).controlInfo.newEvent;		
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


function TEMP_events(inputs: InstructionSlotArray) return InstructionSlotArray is
	variable res: InstructionSlotArray(0 to inputs'length-1) := inputs;
	variable found: std_logic := '0';
	variable causing: InstructionState := defaultInstructionState;
	variable j: integer;
begin
	--		report integer'image(inputs'left);
	--		report integer'image(inputs'right);
	-- Search from latest stages until we find an event, then propagate it to the front
	for i in res'reverse_range loop
		j := i + inputs'left; -- correct for possible strange indexing of input array
		if found = '1' then
			res(i).ins := causing;
			res(i).full := '1';
		elsif inputs(j).full = '1' and inputs(j).ins.controlInfo.newEvent = '1' then
			found := '1';
			causing := inputs(j).ins;
			res(i).full := '0';
		else
			res(i).full := '0';
		end if;
	end loop;
	
	return res;
end function;

 
end ProcLogicFront;
