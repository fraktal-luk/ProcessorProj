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

function instructionFromWord(w: word) return InstructionState;

function decodeInstruction(inputState: InstructionState) return InstructionState;

function decodeMulti(sd: StageDataMulti) return StageDataMulti;

function newFromHbuffer(content: InstructionStateArray; fullMask: std_logic_vector)
return HbuffOutData;

function getLatePCData(commitEvent: std_logic; commitCausing: InstructionState)
return InstructionState;

function newPCData(content: InstructionState;
						  commitEvent: std_logic; commitCausing: InstructionState;
						  execEvent: std_logic; execCausing: InstructionState;	
						  decodeEvent: std_logic; decodeCausing: InstructionState;
						  pcNext: Mword)
return InstructionState;

function getFetchOffset(ip: Mword) return SmallNumber;


	function NEW_generalEvents(pcData: InstructionState;
										commitEvent: std_logic; commitCausing: InstructionState;
										execEvent: std_logic; execCausing: InstructionState;	
										decodeEvent: std_logic; decodeCausing: InstructionState;
										pcNext: Mword)
	return GeneralEventInfo;

function getAnnotatedHwords(fetchBasicInfo: InstructionBasicInfo; 
									 fetchBlock: HwordArray)
return InstructionStateArray;

function stageMultiEvents(sd: StageDataMulti; isNew: std_logic) return StageMultiEventInfo;

end ProcLogicFront;



package body ProcLogicFront is

function getInstructionClassInfo(ins: InstructionState) return InstructionClassInfo is
	variable ci: InstructionClassInfo := defaultClassInfo;
begin
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

			if ins.operation.func = sysUndef then
				--ci.undef := '1';
				ci.mainCluster := '0';
				ci.secCluster := '0';
			end if;

			ci.branchAlways := '0';
			ci.branchCond := '0';

			if 	 	(ins.operation.func = jump and ins.constantArgs.c1 = COND_NONE) then
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
				--ci.system := '1';
			end if;
			
			if  (ins.operation.func = sysMTC) then
				ci.mtc := '1';
			end if;

			if (ins.operation.func = sysMFC) then
				ci.mfc := '1';
			end if;
				
	return ci;
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

				-- TEMP: code for predicting every regular jump (even "branch never"!) as taken
				if ((res.classInfo.branchAlways or res.classInfo.branchCond)
					and not res.classInfo.branchReg)	= '1' and BRANCH_AT_DECODE then
					res.controlInfo.newEvent := '1';
					--res.controlInfo.hasEvent := '1';
					res.controlInfo.newBranch := '1';
					res.controlInfo.hasBranch := '1';					
				end if;


				if res.operation.unit = System and
						(	res.operation.func = sysRetI or res.operation.func = sysRetE
						or res.operation.func = sysSync or res.operation.func = sysReplay
						or res.operation.func = sysHalt) then 		
					res.controlInfo.specialAction := '1';
					
						-- CAREFUL: Those ops don't get issued, they are handled at retirement
						res.classInfo.mainCluster := '0';
						res.classInfo.secCluster := '0';
				end if;	
	
		if --res.classInfo.undef = '1' then
			res.operation.func = sysUndef then
			res.controlInfo.hasException := '1';
			res.controlInfo.exceptionCode := i2slv(ExceptionType'pos(undefinedInstruction), SMALL_NUMBER_SIZE);
		end if;
		
		
		
		res.target := (others => '0');		
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



function newFromHbuffer(content: InstructionStateArray; fullMask: std_logic_vector)
return HbuffOutData is
	variable res: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	variable ret: HbuffOutData;
	variable j: integer := 0;
	variable nOut: integer;
begin
	for i in 0 to PIPE_WIDTH-1 loop
		res.data(i).bits := content(i).bits(15 downto 0) & content(i+1).bits(15 downto 0);		
		res.data(i).basicInfo := content(i).basicInfo;
	end loop;

	for i in 0 to PIPE_WIDTH-1 loop
		nOut := PIPE_WIDTH;
		if (fullMask(j) and content(j).classInfo.short) = '1' then
			res.fullMask(i) := '1';
			res.data(i).bits := content(j).bits(15 downto 0) & content(j+1).bits(15 downto 0);			
			res.data(i).basicInfo := content(j).basicInfo;
			j := j + 1;
		elsif (fullMask(j) and fullMask(j+1)) = '1' then
			res.fullMask(i) := '1';
			res.data(i).bits := content(j).bits(15 downto 0) & content(j+1).bits(15 downto 0);
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

function getLatePCData(commitEvent: std_logic; commitCausing: InstructionState)
return InstructionState is
	variable res: InstructionState := DEFAULT_INSTRUCTION_STATE;-- content;
	variable newPC: Mword := (others=>'0');
begin
		if commitCausing.controlInfo.hasReset = '1' then -- TEMP!
			res.basicInfo.ip := (others => '0');
			res.basicInfo.intLevel := "00000000";				
		elsif commitCausing.controlInfo.hasInterrupt = '1' then
			res.basicInfo.ip := INT_BASE; -- TEMP!
			res.basicInfo.intLevel := "00000001";		
		elsif commitCausing.controlInfo.hasException = '1' then
			-- TODO, FIX: exceptionCode sliced - shift left by ALIGN_BITS? or leave just base address
			res.basicInfo.ip := EXC_BASE(MWORD_SIZE-1 downto commitCausing.controlInfo.exceptionCode'length)
									& commitCausing.controlInfo.exceptionCode(
													commitCausing.controlInfo.exceptionCode'length-1 downto ALIGN_BITS)
									& EXC_BASE(ALIGN_BITS-1 downto 0);	
									--		INT_BASE;
			res.basicInfo.systemLevel := "00000001";
			
		elsif commitCausing.controlInfo.specialAction = '1' then
				if commitCausing.operation.func = sysSync then
					res.basicInfo.ip := commitCausing.target;
				elsif commitCausing.operation.func = sysReplay then
					res.basicInfo.ip := commitCausing.basicInfo.ip;
				elsif commitCausing.operation.func = sysHalt then
					res.basicInfo.ip := commitCausing.target; -- ???
				elsif commitCausing.operation.func = sysRetI then
						res.basicInfo.ip := X"00000020";  --TEMP!!
				elsif commitCausing.operation.func = sysRetE then
						res.basicInfo.ip := X"00000030";  --TEMP!!					
				end if;				
		end if;		
	
	return res;
end function;


function newPCData(content: InstructionState;
						  commitEvent: std_logic; commitCausing: InstructionState;
						  execEvent: std_logic; execCausing: InstructionState;	
						  decodeEvent: std_logic; decodeCausing: InstructionState;
						  pcNext: Mword)
return InstructionState is
	variable res: InstructionState := content;
	variable newPC: Mword := (others=>'0');
begin
	if commitEvent = '1' then -- when from exec or front
		res.basicInfo.ip := commitCausing.target;
	elsif execEvent = '1' then		
		res.basicInfo.ip := execCausing.target;
	elsif decodeEvent = '1' then
			if BRANCH_AT_DECODE then
				res.basicInfo.ip := decodeCausing.target;	
			end if;
	else	-- Increment by the width of fetch group
		res.basicInfo.ip := pcNext;
	end if;	

	return res;
end function;

		function getFetchOffset(ip: Mword) return SmallNumber is
			variable res: SmallNumber := (others => '0');
		begin
			res(ALIGN_BITS-2 downto 0) := ip(ALIGN_BITS-1 downto 1);
			return res;
		end function;


	function NEW_generalEvents(pcData: InstructionState;
										commitEvent: std_logic; commitCausing: InstructionState;
										execEvent: std_logic; execCausing: InstructionState;	
										decodeEvent: std_logic; decodeCausing: InstructionState;
										pcNext: Mword)
	return GeneralEventInfo is
		variable res: GeneralEventInfo;
	begin
		res.affectedVec := (others => '0');
		res.eventOccured := '1';
			res.killPC := '0';
			
		res.causing := decodeCausing;
	
		if commitEvent = '1' then 
			res.killPC := '1';
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
		
		return res;
	end function;


function getAnnotatedHwords(fetchBasicInfo: InstructionBasicInfo; 
									 fetchBlock: HwordArray)
return InstructionStateArray is
	variable res: InstructionStateArray(0 to 2*PIPE_WIDTH-1) := (others => DEFAULT_ANNOTATED_HWORD);
	variable hwordBasicInfo: InstructionBasicInfo := fetchBasicInfo;
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

end ProcLogicFront;
