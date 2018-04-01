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
use work.ProcHelpers.all;

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

function decodeInstruction(inputState: InstructionState) return InstructionState;

function decodeMulti(sd: StageDataMulti) return StageDataMulti;

function fillTargetsAndLinks(insVec: StageDataMulti) return StageDataMulti;

function newFromHbuffer(content: InstructionStateArray; fullMask: std_logic_vector)
return HbuffOutData;

function getFetchOffset(ip: Mword) return SmallNumber;

function getAnnotatedHwords(fetchIns: InstructionState; fetchInsMulti: StageDataMulti;
									 fetchBlock: HwordArray)
return InstructionStateArray;

function getFrontEventMulti(predictedAddress: Mword;
							  ins: InstructionState; receiving: std_logic; valid: std_logic;
							  hbuffAccepting: std_logic; fetchBlock: HwordArray(0 to FETCH_BLOCK_SIZE-1))
return StageDataMulti;


function getEarlyBranchMultiDataIn(predictedAddress: Mword;
							  ins: InstructionState; receiving: std_logic; valid: std_logic;
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
					-- TODO: remove this distinction because no longer used!
					-- For branch with link main cluster for destination write
					if isNonzero(ins.virtualArgSpec.dest(4 downto 0)) = '0' then						
						ci.mainCluster := '0';
					end if;
				elsif ins.operation = (System, sysMtc) then
					ci.secCluster := '1';
				elsif	(ins.operation.unit = System and ins.operation.func /= sysMfc) then
					ci.mainCluster := '0';
					ci.secCluster := '1';
				end if;

			if ins.operation.func = sysUndef then
				ci.mainCluster := '0';
				ci.secCluster := '0';
			end if;

			ci.branchCond := '0';
			if 	 	(ins.operation.func = jump and ins.constantArgs.c1 = COND_NONE) then
				null;
			elsif (ins.operation.func = jump and ins.constantArgs.c1 /= COND_NONE) then 
				ci.branchCond := '1';	
			end if;
				
	return ci;
end function;

function decodeInstruction(inputState: InstructionState) return InstructionState is
	variable res: InstructionState := inputState;
	variable ofs: OpFieldStruct;
	variable tmpVirtualArgs: InstructionVirtualArgs;
	variable tmpVirtualDestArgs: InstructionVirtualDestArgs;
begin
	ofs := getOpFields(inputState.bits);
	ofsInfo(ofs,
					res.operation,
					res.classInfo,
					res.constantArgs,
					tmpVirtualArgs,--res.virtualArgs,
					tmpVirtualDestArgs);--res.virtualDestArgs);
			
			--res.virtualArgs := tmpVirtualArgs;
			--res.virtualDestArgs := tmpVirtualDestArgs;
	
		res.virtualArgSpec.intDestSel := tmpVirtualDestArgs.sel(0);
		res.virtualArgSpec.floatDestSel := '0';
		res.virtualArgSpec.dest := (others => '0');		
		res.virtualArgSpec.dest(4 downto 0) := tmpVirtualDestArgs.d0;
		res.virtualArgSpec.intArgSel := tmpVirtualArgs.sel;
		res.virtualArgSpec.floatArgSel := (others => '0');
		res.virtualArgSpec.args(0) := (others => '0');
		res.virtualArgSpec.args(0)(4 downto 0) := tmpVirtualArgs.s0;
		res.virtualArgSpec.args(1) := (others => '0');		
		res.virtualArgSpec.args(1)(4 downto 0) := tmpVirtualArgs.s1;
		res.virtualArgSpec.args(2) := (others => '0');
		res.virtualArgSpec.args(2)(4 downto 0) := tmpVirtualArgs.s2;
	
	res.classInfo := getInstructionClassInfo(res);	

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
	
		if res.operation.func = sysUndef then
			res.controlInfo.hasException := '1';
			res.controlInfo.exceptionCode := i2slv(ExceptionType'pos(undefinedInstruction), SMALL_NUMBER_SIZE);
		end if;
		
		if res.controlInfo.squashed = '1' then	-- CAREFUL: ivalid was '0'
			report "Trying to decode invalid location" severity error;
		end if;
		
		res.controlInfo.squashed := '0';
		res.target := ofs.target;
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

function fillTargetsAndLinks(insVec: StageDataMulti) return StageDataMulti is
	variable res: StageDataMulti := insVec;
	variable target, link: Mword := (others => '0');
begin
	if not EARLY_TARGET_ENABLE then
		return res;
	end if;

	for i in 0 to PIPE_WIDTH-1 loop
		target := addMwordFaster(insVec.data(i).ip, insVec.data(i).target);
		link := addMwordBasic(insVec.data(i).ip, getAddressIncrement(insVec.data(i)));
		res.data(i).target := target;
		res.data(i).result := link;
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
		--res.data(i).basicInfo := content(i).basicInfo;
			res.data(i).ip := content(i).ip;
		res.data(i).controlInfo.squashed := content(i).controlInfo.squashed;
	end loop;

	for i in 0 to PIPE_WIDTH-1 loop
		nOut := PIPE_WIDTH;
		if (fullMask(j) and content(j).classInfo.short) = '1' then
			res.fullMask(i) := '1';
			res.data(i).bits := content(j).bits(15 downto 0) & content(j+1).bits(15 downto 0);			
			--res.data(i).basicInfo := content(j).basicInfo;
				res.data(i).ip := content(j).ip;
				res.data(i).controlInfo.squashed := content(j).controlInfo.squashed;			
				res.data(i).controlInfo.hasBranch := content(j).controlInfo.hasBranch;
			j := j + 1;
		elsif (fullMask(j) and fullMask(j+1)) = '1' then
			res.fullMask(i) := '1';
			res.data(i).bits := content(j).bits(15 downto 0) & content(j+1).bits(15 downto 0);
			--res.data(i).basicInfo := content(j).basicInfo;
				res.data(i).ip := content(j).ip;
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

		-- TODO: used once, refactor
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
	--constant fetchBasicInfo: InstructionBasicInfo := fetchIns.basicInfo;
	variable hwordBasicInfo: InstructionBasicInfo := DEFAULT_BASIC_INFO;--fetchBasicInfo;	
begin
	for i in 0 to 2*PIPE_WIDTH-1 loop
		hwordBasicInfo.ip := fetchIns.ip(MWORD_SIZE-1 downto ALIGN_BITS) & i2slv(2*i, ALIGN_BITS);
		--	hwordBasicInfo.intLevel(SMALL_NUMBER_SIZE-1 downto 2) := (others => '0');
		--	hwordBasicInfo.systemLevel(SMALL_NUMBER_SIZE-1 downto 2) := (others => '0');
		tempWord(15 downto 0) := fetchBlock(i);		

		res(i).bits := tempWord;
		res(i).ip := hwordBasicInfo.ip;
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


function getFrontEventMulti(predictedAddress: Mword;
							  ins: InstructionState; receiving: std_logic; valid: std_logic;
							  hbuffAccepting: std_logic; fetchBlock: HwordArray(0 to FETCH_BLOCK_SIZE-1))
return StageDataMulti is
	variable res: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	variable tempOffset, thisIP, tempTarget: Mword := (others => '0');
	variable targets: MwordArray(0 to PIPE_WIDTH-1) := (others => (others => '0'));
	variable fullOut, full, branchIns, predictedTaken: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
	variable nSkippedIns: integer := 0;
begin
	-- receiving, valid, accepting	-> good
	-- receiving, valid, not accepting -> refetch
	-- receiving, invalid, accepting -> error, will cause exception, but handled later, from decode on
	-- receiving, invalid, not accepting -> refetch??
	
	-- CAREFUL: Only without hword instructions now!
	-- Find which are before the start of fetch address
	nSkippedIns := slv2u(predictedAddress(ALIGN_BITS-1 downto 0))/4;								
			
	for i in 0 to PIPE_WIDTH-1 loop
		full(i) := '1'; -- For skipping we use 'skipped' flag, not clearing 'full' 
		if i < nSkippedIns then
			res.data(i).controlInfo.skipped := '1';
		end if;
	end loop;

	if (receiving and valid and hbuffAccepting) = '1' then
		-- Calculate target for each instruction, even if it's to be skipped
		for i in 0 to PIPE_WIDTH-1 loop
			thisIP := ins.ip(MWORD_SIZE-1 downto ALIGN_BITS) & i2slv(i*4, ALIGN_BITS);
		
			if 	fetchBlock(2*i)(15 downto 10) = opcode2slv(jl) 
				or fetchBlock(2*i)(15 downto 10) = opcode2slv(jz) 
				or fetchBlock(2*i)(15 downto 10) = opcode2slv(jnz)
			then
				branchIns(i) := '1';
				predictedTaken(i) := fetchBlock(2*i)(4);		-- CAREFUL, TODO: temporary predicted taken iff backwards
				tempOffset := (others => fetchBlock(2*i)(4));
				tempOffset(20 downto 0) := fetchBlock(2*i)(4 downto 0) & fetchBlock(2*i + 1);
			elsif fetchBlock(2*i)(15 downto 10) = opcode2slv(j) -- Long jump instruction
			then
				branchIns(i) := '1';
				predictedTaken(i) := '1'; -- Long jump is unconditional (no space for register encoding!)
				tempOffset := (others => fetchBlock(2*i)(9));
				tempOffset(25 downto 0) := fetchBlock(2*i)(9 downto 0) & fetchBlock(2*i + 1);
			end if;
			targets(i) := addMwordFaster(thisIP, tempOffset);
			
			-- Now applying the skip!
			if res.data(i).controlInfo.skipped = '1' then
				branchIns(i) := '0';
			end if;			
		end loop;
		
		-- Find if any branch predicted
		for i in 0 to PIPE_WIDTH-1 loop
			fullOut(i) := full(i);
			res.data(i).bits := fetchBlock(2*i) & fetchBlock(2*i+1);
			if full(i) = '1' and branchIns(i) = '1' and predictedTaken(i) = '1' then
				-- Here check if the next line from line predictor agress with the target predicted now.
				--	If so, don't cause the event but set invalidation mask that next line will use.
				if targets(i)(MWORD_SIZE-1 downto ALIGN_BITS) = ins.target(MWORD_SIZE-1 downto ALIGN_BITS) then					
					-- CAREFUL: Remeber that it actually is treated as a branch, otherwise would be done 
					--				again at Exec!
					res.data(i).controlInfo.hasBranch := '1';
				else
					-- Raise event
					res.data(i).controlInfo.newEvent := '1';
					res.data(i).controlInfo.hasBranch := '1';
					res.data(i).target := targets(i);
				end if;
				
				-- CAREFUL: When not using line predictor, branches predicted taken must always be done here 
				if not USE_LINE_PREDICTOR then
					res.data(i).controlInfo.newEvent := '1';
					res.data(i).controlInfo.hasBranch := '1';
					res.data(i).target := targets(i);
				end if;

				exit;
			end if;
		end loop;
	end if;
	
	res.fullMask := fullOut;
	return res;
end function;


function getEarlyBranchMultiDataIn(predictedAddress: Mword;
							  ins: InstructionState; receiving: std_logic; valid: std_logic;
							  hbuffAccepting: std_logic; fetchBlock: HwordArray(0 to FETCH_BLOCK_SIZE-1))
return StageDataMulti is
	variable res: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
begin
	res := getFrontEventMulti(predictedAddress, ins, receiving, valid, hbuffAccepting, fetchBlock);
	
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
