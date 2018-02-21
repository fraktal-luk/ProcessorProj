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

type HbuffOutData is record
	sd: StageDataMulti;
	nOut: SmallNumber;
	nHOut: SmallNumber;
end record;

constant DEFAULT_HBUFF_OUT: HbuffOutData := (sd => DEFAULT_STAGE_DATA_MULTI, nOut => (others => '0'),
															nHOut => (others => '0'));

function getInstructionClassInfo(ins: InstructionState) return InstructionClassInfo;

function instructionFromWord(w: word) return InstructionState;

function decodeInstruction(inputState: InstructionState) return InstructionState;

function decodeMulti(sd: StageDataMulti) return StageDataMulti;

function newFromHbuffer(content: InstructionStateArray; fullMask: std_logic_vector)
return HbuffOutData;

function getFetchOffset(ip: Mword) return SmallNumber;

function getAnnotatedHwords(fetchIns: InstructionState; fetchInsMulti: StageDataMulti;
									 fetchBlock: HwordArray)
return InstructionStateArray;


function stageMultiEvents(sd: StageDataMulti; isNew: std_logic) return StageMultiEventInfo;

function getFrontEvent(ins: InstructionState; receiving: std_logic; valid: std_logic;
							  hbuffAccepting: std_logic; fetchBlock: HwordArray(0 to FETCH_BLOCK_SIZE-1))
return InstructionState;

function getFrontEventMulti(ins: InstructionState; receiving: std_logic; valid: std_logic;
							  hbuffAccepting: std_logic; fetchBlock: HwordArray(0 to FETCH_BLOCK_SIZE-1))
return StageDataMulti;


function getEarlyBranchMultiDataIn(ins: InstructionState; receiving: std_logic; valid: std_logic;
							  hbuffAccepting: std_logic; fetchBlock: HwordArray(0 to FETCH_BLOCK_SIZE-1))
return StageDataMulti;

function countFullNonSkipped(insVec: StageDataMulti) return integer;

function findEarlyTakenJump(ins: InstructionState; insVec: StageDataMulti) return InstructionState;

end ProcLogicFront;



package body ProcLogicFront is

function getInstructionClassInfo(ins: InstructionState) return InstructionClassInfo is
	variable ci: InstructionClassInfo := defaultClassInfo;
begin
				-- Which clusters?
				-- CAREFUL, TODO: make it more regular and clear!
				ci.mainCluster := '1';
				if ins.operation = (Memory, store) then
					ci.secCluster := '1';
				end if;
				
				if ins.operation.unit = Jump then
					ci.secCluster := '1';
					-- For branch with link main cluster for destination write
					if isNonzero(ins.virtualDestArgs.d0) = '0' then
						ci.mainCluster := '0';
					end if;
				elsif ins.operation = (System, sysMtc) then
					ci.secCluster := '1';
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

--				-- TEMP: code for predicting every regular jump (even "branch never"!) as taken
--				if ((res.classInfo.branchAlways or res.classInfo.branchCond)
--					and not res.classInfo.branchReg)	= '1' and BRANCH_AT_DECODE then
--					res.controlInfo.newEvent := '1';
--					--res.controlInfo.hasEvent := '1';
--					res.controlInfo.newBranch := '1';
--					res.controlInfo.hasBranch := '1';					
--				end if;


				if res.operation.unit = System and
						(	res.operation.func = sysRetI or res.operation.func = sysRetE
						or res.operation.func = sysSync or res.operation.func = sysReplay
						or res.operation.func = sysError
						or res.operation.func = sysHalt) then 		
					res.controlInfo.specialAction := '1';
					
						-- CAREFUL: Those ops don't get issued, they are handled at retirement
						res.classInfo.mainCluster := '0';
						res.classInfo.secCluster := '0';
				end if;	
	
		if --res.classInfo.undef = '1' then
				res.operation.func = sysUndef 
		then
			res.controlInfo.hasException := '1';
			res.controlInfo.exceptionCode := i2slv(ExceptionType'pos(undefinedInstruction), SMALL_NUMBER_SIZE);
		end if;
		
		if res.controlInfo.squashed = '1' then	-- CAREFUL: ivalid was '0'
			report "Trying to decode invalid location" severity error;
		end if;
		
			res.controlInfo.squashed := '0';
		
		res.target := --(others => '0');
							ofs.target;
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
	variable ret: HbuffOutData := DEFAULT_HBUFF_OUT;
	variable j: integer := 0;
	variable nOut: integer;
begin
	for i in 0 to PIPE_WIDTH-1 loop
		res.data(i).bits := content(i).bits(15 downto 0) & content(i+1).bits(15 downto 0);		
		res.data(i).basicInfo := content(i).basicInfo;
			res.data(i).controlInfo.squashed := content(i).controlInfo.squashed;
	end loop;

	for i in 0 to PIPE_WIDTH-1 loop
		nOut := PIPE_WIDTH;
		if (fullMask(j) and content(j).classInfo.short) = '1' then
			res.fullMask(i) := '1';
			res.data(i).bits := content(j).bits(15 downto 0) & content(j+1).bits(15 downto 0);			
			res.data(i).basicInfo := content(j).basicInfo;
				res.data(i).controlInfo.squashed := content(j).controlInfo.squashed;			
				res.data(i).controlInfo.hasBranch := content(j).controlInfo.hasBranch;
			j := j + 1;
		elsif (fullMask(j) and fullMask(j+1)) = '1' then
			res.fullMask(i) := '1';
			res.data(i).bits := content(j).bits(15 downto 0) & content(j+1).bits(15 downto 0);
			res.data(i).basicInfo := content(j).basicInfo;
				res.data(i).controlInfo.squashed := content(j).controlInfo.squashed;
				res.data(i).controlInfo.hasBranch := content(j).controlInfo.hasBranch;
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

		function getFetchOffset(ip: Mword) return SmallNumber is
			variable res: SmallNumber := (others => '0');
		begin
			res(ALIGN_BITS-2 downto 0) := ip(ALIGN_BITS-1 downto 1);
			return res;
		end function;


function getAnnotatedHwords(fetchIns: InstructionState; fetchInsMulti: StageDataMulti;
									 fetchBlock: HwordArray)
return InstructionStateArray is
	variable res: InstructionStateArray(0 to 2*PIPE_WIDTH-1) := (others => DEFAULT_ANNOTATED_HWORD);
	variable	tempWord: word := (others => '0');
	constant fetchBasicInfo: InstructionBasicInfo := fetchIns.basicInfo;
	variable hwordBasicInfo: InstructionBasicInfo := fetchBasicInfo;	
begin
	for i in 0 to 2*PIPE_WIDTH-1 loop
		hwordBasicInfo.ip := fetchBasicInfo.ip(MWORD_SIZE-1 downto ALIGN_BITS) & i2slv(2*i, ALIGN_BITS);
			hwordBasicInfo.intLevel(SMALL_NUMBER_SIZE-1 downto 2) := (others => '0');
			hwordBasicInfo.systemLevel(SMALL_NUMBER_SIZE-1 downto 2) := (others => '0');
		tempWord(15 downto 0) := fetchBlock(i);		

		res(i).bits := tempWord;
		res(i).basicInfo := hwordBasicInfo;
		res(i).classInfo.short := '0'; -- TEMP!
			res(i).controlInfo.squashed := fetchIns.controlInfo.squashed; -- CAREFUL: guarding from wrong reading 
	end loop;
	
		for i in 0 to PIPE_WIDTH-1 loop
			--res(2*i).controlInfo.newEvent := fetchInsMulti.data(i).controlInfo.newEvent;
			res(2*i).controlInfo.hasBranch := fetchInsMulti.data(i).controlInfo.hasBranch;
			res(2*i).target := fetchInsMulti.data(i).target;
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

function getFrontEvent(ins: InstructionState; receiving: std_logic; valid: std_logic;
							  hbuffAccepting: std_logic; fetchBlock: HwordArray(0 to FETCH_BLOCK_SIZE-1))
return InstructionState is
	variable res: InstructionState := ins;
	variable tempOffset, tempTarget: Mword := (others => '0');
begin
	if valid = '0' then
		res.controlInfo.squashed := '1';
	end if;

	-- receiving, valid, accepting	-> good
	-- receiving, valid, not accepting -> refetch
	-- receiving, invalid, accepting -> error, will cause exception, but handled later, from decode on
	-- receiving, invalid, not accepting -> refetch??
--return res;
	if false and (receiving and not hbuffAccepting) = '1' then -- When need to refetch
		res.target := res.basicInfo.ip;
	

	end if;
	
	-- Check if it's a branch
	-- TODO: (should be done in predecode when loading to cache)
	-- CAREFUL: Only without hword instructions now!
		-- TMP
	if (receiving and valid and hbuffAccepting) = '1' then
		if 	fetchBlock(0)(15 downto 10) = opcode2slv(jl) 
			or fetchBlock(0)(15 downto 10) = opcode2slv(jz) 
			or fetchBlock(0)(15 downto 10) = opcode2slv(jnz)
		then
			--report "branch fetched!";
			
				--res.controlInfo.newEvent := '1';
				--res.controlInfo.hasBranch := '1';			
			
			tempOffset := "00000000000" & fetchBlock(0)(4 downto 0) & fetchBlock(1);
			tempTarget := addMwordFaster(res.basicInfo.ip, tempOffset);
			res.target := tempTarget;
		elsif fetchBlock(0)(15 downto 10) = opcode2slv(j)
		then
			--report "long branch fetched";
			tempOffset := "000000" & fetchBlock(0)(9 downto 0) & fetchBlock(1);
			tempTarget := addMwordFaster(res.basicInfo.ip, tempOffset);
			res.target := tempTarget;
		end if;
	end if;
	
	return res;
end function;


function getFrontEventMulti(ins: InstructionState; receiving: std_logic; valid: std_logic;
							  hbuffAccepting: std_logic; fetchBlock: HwordArray(0 to FETCH_BLOCK_SIZE-1))
return StageDataMulti is
	variable res0: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	variable res: InstructionState := ins;
	variable tempOffset, baseIP, tempTarget: Mword := (others => '0');
	variable targets: MwordArray(0 to PIPE_WIDTH-1) := (others => (others => '0'));
	variable fullOut, full, branchIns, predictedTaken: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
	variable nSkippedIns: integer := 0;
begin
	if valid = '0' then
		res.controlInfo.squashed := '1';
	end if;

	-- receiving, valid, accepting	-> good
	-- receiving, valid, not accepting -> refetch
	-- receiving, invalid, accepting -> error, will cause exception, but handled later, from decode on
	-- receiving, invalid, not accepting -> refetch??

	
	-- Check if it's a branch
	-- TODO: (should be done in predecode when loading to cache)
	-- CAREFUL: Only without hword instructions now!
		-- TMP
			-- Find which are before the start of fetch address
			nSkippedIns := slv2u(ins.basicInfo.ip(ALIGN_BITS-1 downto 0))/4; -- CORRECT?
			--	report integer'image(slv2u(ins.basicInfo.ip)) &  "; " & integer'image(nSkippedIns) & " skipped";
			for i in 0 to PIPE_WIDTH-1 loop
				full(i) := '1'; -- CAREFUL! For skipping using 'skipped' flag, not clearing 'full' 
				if i >= nSkippedIns then
					full(i) := '1';
				else
					res0.data(i).controlInfo.skipped := '1';
				end if;
			end loop;
			
	if (receiving and valid and hbuffAccepting) = '1' then
		for i in 0 to PIPE_WIDTH-1 loop
			-- Is normal branch instruction?
			if 	fetchBlock(2*i)(15 downto 10) = opcode2slv(jl) 
				or fetchBlock(2*i)(15 downto 10) = opcode2slv(jz) 
				or fetchBlock(2*i)(15 downto 10) = opcode2slv(jnz)
			then
				branchIns(i) := '1';
				predictedTaken(i) := fetchBlock(2*i)(4);
				tempOffset := (others => fetchBlock(2*i)(4));
				tempOffset(20 downto 0) := fetchBlock(2*i)(4 downto 0) & fetchBlock(2*i + 1);
				baseIP := res.basicInfo.ip(MWORD_SIZE-1 downto ALIGN_BITS) & i2slv(i*4, ALIGN_BITS); -- ??
				tempTarget := addMwordFaster(baseIP, tempOffset);
				targets(i) := tempTarget;			-- Long branch instruction?
			elsif fetchBlock(2*i)(15 downto 10) = opcode2slv(j)
			then
				branchIns(i) := '1';
				predictedTaken(i) := '1'; -- Long jump is unconditional (no space for register encoding!)
				tempOffset := (others => fetchBlock(2*i)(9));
				tempOffset(25 downto 0) := fetchBlock(2*i)(9 downto 0) & fetchBlock(2*i + 1);
				baseIP := res.basicInfo.ip(MWORD_SIZE-1 downto ALIGN_BITS) & i2slv(i*4, ALIGN_BITS); -- ??
				tempTarget := addMwordFaster(baseIP, tempOffset);
				targets(i) := tempTarget;
			end if;
			
		end loop;
		
		-- Find if any branch predicted
		for i in 0 to PIPE_WIDTH-1 loop
			fullOut(i) := full(i);
			res0.data(i).bits := fetchBlock(2*i) & fetchBlock(2*i+1);
			if full(i) = '1' and branchIns(i) = '1' and predictedTaken(i) = '1' then
				res0.data(i).controlInfo.newEvent := '1';
				res0.data(i).controlInfo.hasBranch := '1';
				res0.data(i).target := targets(i);
				exit;
			end if;
		end loop;
	end if;
	
	--res0.data(0) := res;
	res0.fullMask := fullOut;
	return res0;
end function;


function getEarlyBranchMultiDataIn(ins: InstructionState; receiving: std_logic; valid: std_logic;
							  hbuffAccepting: std_logic; fetchBlock: HwordArray(0 to FETCH_BLOCK_SIZE-1))
return StageDataMulti is
	variable res: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
begin
	res := getFrontEventMulti(ins, receiving, valid, hbuffAccepting, fetchBlock);
	
	return res;
end function;

function countFullNonSkipped(insVec: StageDataMulti) return integer is 
	variable res: integer := 0;
begin
	for i in 0 to PIPE_WIDTH-1 loop
		if insVec.fullMask(i) = '1' and insVec.data(i).controlInfo.skipped = '0' then
			res := res + 1;
		end if;
	end loop;
	return res;
end function;

function findEarlyTakenJump(ins: InstructionState; insVec: StageDataMulti) return InstructionState is
	variable res: InstructionState := ins;
begin
	for i in 0 to PIPE_WIDTH-1 loop
		if 		insVec.fullMask(i) = '1' and insVec.data(i).controlInfo.skipped = '0'
			and 	insVec.data(i).controlInfo.newEvent = '1'
		then
			res.controlInfo.newEvent := '1';
			res.controlInfo.hasBranch := '1';
			res.target  := insVec.data(i).target;
			exit;
		end if;
	end loop;
	
	return res;
end function;


end ProcLogicFront;
