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
use work.Decoding2.all;

use work.NewPipelineData.all;

package TEMP_DEV is

type StageDataCommitQueue is record
	fullMask: std_logic_vector(0 to CQ_SIZE-1); 
	data: InstructionStateArray(0 to CQ_SIZE-1);
end record;

type TEMP_StageDataPC is record
	basicInfo: InstructionBasicInfo;
	pc: Mword;
	pcBase: Mword;
	nFull: natural;
	nH: PipeFlow; -- number of hwords 	
end record;

constant DEFAULT_DATA_PC: TEMP_StageDataPC := (			pc => (others=>'0'),
																		pcBase => (others=>'0'),
																		nFull => 0,
																		nH => (others=>'0'),
																		basicInfo => defaultBasicInfo
																		);	
-- CAREFUL: this is PC "before" address 0 																		
constant INITIAL_DATA_PC: TEMP_StageDataPC := (			pc => i2slv(-PIPE_WIDTH*4, MWORD_SIZE),
																		pcBase => i2slv(-PIPE_WIDTH*4, MWORD_SIZE),
																		nFull => 0,
																		nH => (others=>'0'),
																		basicInfo => defaultBasicInfo
																		);

type TEMP_StageDataFetch is record
	pc: Mword;
	pcBase: Mword; -- DEPREC?
	nFull: natural;	
end record;

type AnnotatedHword is record
	bits: hword;
	ip: Mword;
	basicInfo: InstructionBasicInfo;
end record;

type AnnotatedHwordArray is array (integer range <>) of AnnotatedHword;

-- Info supplied by hword buffer
type HwordBufferData is record
	readyOps: std_logic_vector(0 to PIPE_WIDTH-1); --PipeFlow;
	shortInstructions: std_logic_vector(0 to PIPE_WIDTH-1); 
	words: WordArray(0 to PIPE_WIDTH-1);
	cumulSize: IntArray(0 to PIPE_WIDTH);
end record;

type FrontEventInfo is record
	eventOccured: std_logic;
	ePC, eFetch, eHbuff, e0, e1: std_logic;
	iPC, iFetch, iHbuff, i0, i1: integer;
	mPC, mFetch, m0, m1: std_logic_vector(0 to PIPE_WIDTH-1); -- Event masks
	pPC, pFetch, p0, p1: std_logic_vector(0 to PIPE_WIDTH-1); -- Event masks
	mHbuff, pHbuff: std_logic_vector(0 to HBUFFER_SIZE-1);
	causing: InstructionState;
	affectedVec, causingVec: std_logic_vector(0 to 4);	
	fromExec, fromInt: std_logic;	
end record;

type ExecRelTable is array (ExecStages'left to ExecStages'right) of ExecStages; 

type ExecDriveTable is array (ExecStages'left to ExecStages'right) of FlowDriveSimple;							
type ExecResponseTable is array (ExecStages'left to ExecStages'right) of FlowResponseSimple;
	
type ExecDataTable is array (ExecStages'left to ExecStages'right) of InstructionState;
	
	subtype PipeStageDataU is InstructionStateArray;	
	subtype SingleStageData is PipeStageDataU(0 to 0);
	subtype PipeStageData is PipeStageDataU(0 to PIPE_WIDTH-1);

	-- CAREFUL: this holds only for IQ A
	type IQStepData is record 
		iqDataNext: InstructionStateArray(0 to IQ_A_SIZE-1);
		iqFullMaskNext: std_logic_vector(0 to IQ_A_SIZE-1);
		dispatchDataNew: InstructionState;
		wantSend: std_logic;
	end record;
										
	function iqStep(dataLiving: InstructionStateArray; dataNew: StageDataMulti; 
						 fullMask, readyMask: std_logic_vector;
						 nextAccepting: std_logic;						 
						 living, sending, prevSending: integer;
						 prevSendingOK: std_logic)					 
	return IQStepData;
	
	function iqStep2(dataLiving: InstructionStateArray; dataNew: StageDataMulti; 
						 fullMask, readyMask: std_logic_vector;
						 nextAccepting: std_logic;						 
						 living, sending, prevSending: integer)					 
	return IQStepData;
	
			type ArgStatusInfo is record
				ready: std_logic_vector(0 to 2);
				locs: SmallNumberArray(0 to 2);
				vals: MwordArray(0 to 2);
			end record;
	
			type ArgStatusStruct is record
				readyAll: std_logic;
				readyNextAll: std_logic;
				ready: std_logic_vector(0 to 2);
				locs: SmallNumberArray(0 to 2);
				vals: MwordArray(0 to 2);
					missing: std_logic_vector(0 to 2);
					readyReg: std_logic_vector(0 to 2);
					readyNow: std_logic_vector(0 to 2);
					readyNext: std_logic_vector(0 to 2);
					stillMissing: std_logic_vector(0 to 2);
					nMissing: integer;
					nextMissing: std_logic_vector(0 to 2);
					nMissingNext: integer;					
			end record;

			type ArgStatusInfoArray is array(integer range <>) of ArgStatusInfo;
			type ArgStatusStructArray is array(integer range <>) of ArgStatusStruct;

	-- WARNING, TODO: Some functions may need inputs from other sources, like branch history buffer etc.

	-- # Decode actions:
	function getInstructionClassInfo(ins: InstructionState) return InstructionClassInfo;

	-- writes target to the 'target' field
	function setBranchTarget(ins: InstructionState) return InstructionState;

	-- TEMP?
	function basicJumpAddress(ins: InstructionState) return Mword;

	function instructionFromWord(w: word) return InstructionState;

	function decodeInstruction(inputState: InstructionState) return InstructionState;

	function TEMP_branchPredict(ins: InstructionState) return InstructionState;

	-- # Renaming:
	-- Those should return a result, which enables deciding how many PRs are used, to correctly
	--		update renaming engine state! PhysicalArgs propably make this possible, cause 
	--		they indicate which were used, and '1's can be counted
				
	function getPhysicalSources(va: InstructionVirtualArgs; pn: PhysNameArray) return InstructionPhysicalArgs;	
	function getPhysicalDest(vd: InstructionVirtualDestArgs; pr: PhysName) return InstructionPhysicalDestArgs;
	
	-- DEPREC?
	-- Here pd can have selectio bit set or zero, which decides if incrementing or not
		-- CAREFUL! Note that when op uses no destination, then on committing it should make no change in 
		-- last committed reg tag, so it takes the 'old value', not 'new value' (incremented by one).
		-- Remember that if Exec exceptions flush their source, state must rewind to that PRECEDING the cause,
		--	but when branch decision in Exec, op itself is not flushed, and state reverses to that AFTER
		--	the renaming of causing instruction!
	function getRegTag(prevTag: SmallNumber; pd: InstructionPhysicalDestArgs) return SmallNumber; 
	
	-- # Register reading
	-- get inputs form registers and immediate value
	
	function getIssueArgValues(pa: InstructionPhysicalArgs; ca: InstructionConstantArgs;
										ready: std_logic_vector; vals: MwordArray)
	return InstructionArgValues;
	
	-- get args still missing (used while waiting for issue, possibly in the cycle when going to Exec)
	function updateArgValues(av: InstructionArgValues; pa: InstructionPhysicalArgs; ready: std_logic_vector;
									vals: MwordArray) 
	return InstructionArgValues; 
	
	function updateInstructionArgValues(ins: InstructionState; av: InstructionArgValues) 
	return InstructionState;	
	
	procedure findForwardingSources(av: in InstructionArgValues; pa: in InstructionPhysicalArgs; 
											tags: in PhysNameArray; content: in MwordArray;
											ready: out std_logic_vector; locs: out SmallNumberArray;
											vals: out MwordArray);
											
	function getForwardingStatus(av: in InstructionArgValues; pa: in InstructionPhysicalArgs; 
											tags: in PhysNameArray) return std_logic_vector;

	function getForwardingStatusInfo(av: in InstructionArgValues; pa: in InstructionPhysicalArgs; 
											 content: in MwordArray;--fn: ForwardingNetwork
											tags: in PhysNameArray) return ArgStatusInfo;
	
	function getArgInfoArray(data: InstructionStateArray; vals: MwordArray; resultTags: PhysNameArray)
	return ArgStatusInfoArray;	
		
	-- true if all args are ready
	function readyForExec(ins: InstructionState) return std_logic;
	
	function findReady(arr: InstructionStateArray) return std_logic_vector;
	
	-- # Exec
	
	-- DUMMY: This performs some siple operation to obtain a result
	function passArg0(ins: InstructionState) return InstructionState;

	-- set exception flags
	function raiseExecException(ins: InstructionState) return InstructionState;
	
	function resolveBranchCondition(av: InstructionArgValues; ca: InstructionConstantArgs) return std_logic;
	
	function basicBranch(ins: InstructionState) return InstructionState;
	
	-- Tells if 'a' is older than 'b'
	function tagBefore(a, b: SmallNumber) return std_logic;
	
	-- To determine which subpipe result directs control flow
	function findOldestSignal(ready: std_logic_vector; tags: SmallNumberArray) return std_logic_vector;
	
	function getArgStatus(ai: ArgStatusInfo;
								 data, dataUpdated: InstructionState; living: std_logic;
								 readyRegs: std_logic_vector;
								 resultTags, nextResultTags: PhysNameArray; vals: MwordArray)
	return ArgStatusStruct;	
	
	function getArgStatusArray(aiA: ArgStatusInfoArray;
										data, dataUpdated: InstructionStateArray; livingMask: std_logic_vector;
										readyRegs: std_logic_vector;
										resultTags, nextResultTags: PhysNameArray; vals: MwordArray)
	return ArgStatusStructArray;	
	
	function updateIQData(data: InstructionStateArray; aiArray: ArgStatusInfoArray)
	return InstructionStateArray;

	function extractReadyMask(asA: ArgStatusStructArray) return std_logic_vector;	
	
end TEMP_DEV;



package body TEMP_DEV is

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
	
	
	function setBranchTarget(ins: InstructionState) return InstructionState is
		variable res: InstructionState := ins;
	begin
		-- NOTE: jump relative to this instruction, not next one
		res.target := i2slv(slv2s(ins.constantArgs.imm) + slv2s(ins.basicInfo.ip), MWORD_SIZE);		
		return res;
	end function;
	
	
	-- What PC should be when controlevent happens - based on kiling instruciton 
	--	DEPRECATED
--	function getTargetPC(ins: InstructionState) return Mword is
--		-- CAREFUL, TODO: "assumed 4B" problem
--		variable res: Mword;
--	begin
--		if ins.classInfo.system = '1' and ins.classInfo.undef = '0' then -- TEMP!
--			report "Setting target from system instruction...";
--			res := i2slv( slv2s(ins.basicInfo.ip) + 4, MWORD_SIZE); -- DUMMY: go to next
--		elsif ins.controlInfo.branchSpeculated = '1' then
--			-- It must be immediate branch if we are to know the target
--			-- TODO: ensure correct signedness etc, prevent overflow if relevant...
--			res := i2slv(slv2s(ins.constantArgs.imm) + slv2s(ins.basicInfo.ip) + 4, MWORD_SIZE); 
--		elsif ins.controlInfo.exception = '1' then	
--			res := EXC_TABLE(slv2u(ins.controlInfo.exceptionCode));
--		end if;	
--		
--		return res;	
--	end function;	
	
	
	
	function basicJumpAddress(ins: InstructionState) return Mword is
	begin
		if ins.controlInfo.branchExecute = '1' then
			return ins.target;
		elsif ins.controlInfo.branchCancel = '1' then
			return ins.result;
		elsif ins.controlInfo.exception = '1' then
			return EXC_TABLE(slv2u(ins.controlInfo.exceptionCode));
		else 
			return (others=>'0');
		end if;
		
	end function;
	
	-------------
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
	

	
	function getPhysicalSources(va: InstructionVirtualArgs; pn: PhysNameArray) 
	return InstructionPhysicalArgs is
		variable pa: InstructionPhysicalArgs := defaultPhysicalArgs;
	begin
		pa.sel := va.sel;
		-- CAREFUL: In this version, writing occurs even if not selected
		pa.s0 := pn(0); 
		pa.s1 := pn(1);
		pa.s2 := pn(2);
		return pa;
	end function;
	
	function getPhysicalDest(vd: InstructionVirtualDestArgs; pr: PhysName)
	return InstructionPhysicalDestArgs is
		variable pd: InstructionPhysicalDestArgs := defaultPhysicalDestArgs;
	begin
		pd.sel := vd.sel;
		-- CAREFUL: In this version, writing occurs even if not selected		
		pd.d0 := pr;
		return  pd;
	end function;
	
	-- Here pd can have selectio bit set or zero, which decides if incrementing or not
	function getRegTag(prevTag: SmallNumber; pd: InstructionPhysicalDestArgs) return SmallNumber is
		variable pt, k: integer;
	begin
		pt := slv2u(prevTag);
		if pd.sel(0) = '1' then -- TODO: use safe method to exclude allocating for p0!
			pt := pt + 1;
		end if;
		return i2slv(pt, SMALL_NUMBER_SIZE);
	end function;	
	
	-- # Register reading
	-- get inputs form registers and immediate value
	function getIssueArgValues(pa: InstructionPhysicalArgs; ca: InstructionConstantArgs;
										ready: std_logic_vector; vals: MwordArray) 
	return InstructionArgValues is
		variable res: InstructionArgValues := defaultArgValues;
	begin	
		if pa.sel(0) = '1' then
			if ready(0) = '1' then
				res.arg0 := vals(0);
			else
				res.missing(0) := '1';
			end if;
		end if;
		
		-- CAREFUL! Here we must check if it's immediate value!
		assert (ca.immSel and pa.sel(1)) = '0' 	-- Never should have s1 and imm together!
				report "Immediate value together with reg src1!" severity error; 
		
		if ca.immSel = '1' then
			res.arg1 := ca.imm;
		end if;
		
		if pa.sel(1) = '1' then
			if ready(1) = '1' then
				res.arg1 := vals(1);
			else
				res.missing(1) := '1';
			end if;
		end if;

		if pa.sel(2) = '1' then
			if ready(2) = '1' then
				res.arg2 := vals(2);
			else
				res.missing(2) := '1';
			end if;
		end if;		
		return res;
	end function;
	
	-- get args still missing (used while waiting for issue, possibly in the cycle when going to Exec)
	function updateArgValues(av: InstructionArgValues; pa: InstructionPhysicalArgs;
										ready: std_logic_vector; vals: MwordArray) 
	return InstructionArgValues is
		variable res: InstructionArgValues := av;
	begin
		if (res.missing(0) and ready(0)) = '1' then
			res.missing(0) := '0';
			res.arg0 := vals(0);
		end if;

		if (res.missing(1) and ready(1)) = '1' then
			res.missing(1) := '0';
			res.arg1 := vals(1);
		end if;

		if (res.missing(2) and ready(2)) = '1' then
			res.missing(2) := '0';
			res.arg2 := vals(2);
		end if;
		
		return res;
	end function;	
	
	function updateInstructionArgValues(ins: InstructionState; av: InstructionArgValues) 
	return InstructionState is
		variable res: InstructionState := ins;
	begin
		res.argValues := av;
		return res;
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
	
	function getForwardingStatus(av: in InstructionArgValues; pa: in InstructionPhysicalArgs; 
											--fn: ForwardingNetwork
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
	
	function getForwardingStatusInfo(av: in InstructionArgValues; pa: in InstructionPhysicalArgs; 
											 content: in MwordArray;--fn: ForwardingNetwork
											tags: in PhysNameArray) return ArgStatusInfo
	is		
		variable ready: std_logic_vector(0 to 2) := (others=>'0');
		variable locs: SmallNumberArray(0 to 2) := (others=>(others=>'0'));
		variable vals: MwordArray(0 to 2) := (others=>(others=>'0'));
	begin
		findForwardingSources(av, pa, tags, 	
										content,
										ready, locs, vals);
		return (ready, locs, vals);								
	end function;	
	
	function getArgInfoArray(data: InstructionStateArray; vals: MwordArray; resultTags: PhysNameArray)
	return ArgStatusInfoArray is
		variable res: ArgStatusInfoArray(data'range);
	begin
		for i in res'range loop
			res(i) := getForwardingStatusInfo(data(i).argValues, data(i).physicalArgs, vals, resultTags);
		end loop;
		
		return res;
	end function;


	function readyForExec(ins: InstructionState) return std_logic is
		variable res: std_logic;
	begin
		if ins.argValues.missing = "000" then
			res := '1';
		else
			res := '0';
		end if;	
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
 
	function passArg0(ins: InstructionState) return InstructionState is
		variable res: InstructionState := ins;
	begin
		res.result := res.argValues.arg0;
		return res;
	end function;
 
	function raiseExecException(ins: InstructionState) return InstructionState is
		variable res: InstructionState := ins;
	begin
		res.controlInfo.exception := '1';
		--res.controlInfo.exceptionCode
		res.controlInfo.unseen := '1';
		return res;	
	end function;

	function resolveBranchCondition(av: InstructionArgValues; ca: InstructionConstantArgs) return std_logic is
		variable isZero: std_logic;
		--variable zeros: Mword := (others=>'0');
	begin
		isZero := not isNonzero(av.arg0);
			
		if ca.c1 = COND_NONE then
			return '1';
		elsif ca.c1 = COND_Z and isZero = '1' then
			return '1';
		elsif ca.c1 = COND_NZ and isZero = '0' then
			return '1';
		else
			return '0';
		end if;	
		
	end function;

	function basicBranch(ins: InstructionState) return InstructionState is
		variable res: InstructionState := ins;
	begin
		-- Return address
		-- CAREFUL, TODO: when introducing 16b instructions, it won't be always 4 bytes ahead!
		res.result := i2slv(slv2u(ins.basicInfo.ip) + 4, MWORD_SIZE);
		
		if ins.classInfo.branchCond = '1' then
			res.controlInfo.branchConfirmed := resolveBranchCondition(ins.argValues, ins.constantArgs);
			if res.controlInfo.branchSpeculated = '1' and res.controlInfo.branchConfirmed = '0' then
				res.controlInfo.branchCancel := '1';
				res.controlInfo.execEvent := '1';
				--res.controlInfo.unseen := '1';
			elsif res.controlInfo.branchSpeculated = '0' and res.controlInfo.branchConfirmed = '1' then
				res.controlInfo.branchExecute := '1';
				res.controlInfo.execEvent := '1';
				--res.controlInfo.unseen := '1';				
			end if;
		end if;
		
		return res;
	end function;

	-- CAREFUL! In this version (ci = ai - bi, no negatio on return) "10...0" WILL be after "0...0"!
	--				Generally, "0..01" to "10..0" will be.
	function tagBefore(a, b: SmallNumber) return std_logic is
		variable ai, bi, ci: integer;
		variable c: SmallNumber;
	begin
		ai := slv2u(a);
		bi := slv2u(b);
		ci := ai - bi;
		c := i2slv(ci, SMALL_NUMBER_SIZE);
		return c(c'high);
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
	
	
	function getArgStatus(ai: ArgStatusInfo;
								 data, dataUpdated: InstructionState; living: std_logic;
								 readyRegs: std_logic_vector;
								 resultTags, nextResultTags: PhysNameArray; vals: MwordArray)
	return ArgStatusStruct is
		variable res: ArgStatusStruct;
	begin
			res.ready := ai.ready;
			res.locs := ai.locs;
			res.vals := ai.vals;

			res.missing := data.argValues.missing;
			res.readyReg := readyRegs;
				-- CAREFUL: this probably redundant with 'ready'
			res.readyNow := -- getForwardingStatus(data(i).argValues, data(i).physicalargs, resultTags);
									res.ready;
			res.readyNext := getForwardingStatus(data.argValues, data.physicalArgs, nextResultTags);
 			
			res.stillMissing := dataUpdated.argValues.missing;
			res.nextMissing := res.stillMissing and not res.readyNext and not res.readyReg;
			res.nMissing :=  countOnes(res.missing);
			res.nMissingNext := countOnes(res.nextMissing);
			
			res.readyAll := living and not isNonzero(res.stillMissing);
			res.readyNextAll := living and not isNonzero(res.nextMissing);		
		return res;
	end function;
		
									
	function getArgStatusArray(aiA: ArgStatusInfoArray;
										data, dataUpdated: InstructionStateArray; livingMask: std_logic_vector;
										readyRegs: std_logic_vector;
										resultTags, nextResultTags: PhysNameArray; vals: MwordArray)
	return ArgStatusStructArray is
		variable res: ArgStatusStructArray(data'range);
	begin
		for i in res'range loop
			res(i) := getArgStatus(aiA(i), data(i), dataUpdated(i), livingMask(i), readyRegs(3*i to 3*i + 2),
											resultTags, nextResultTags, vals);	
		end loop;
		
		return res;
	end function;	
	
	function updateIQData(data: InstructionStateArray; aiArray: ArgStatusInfoArray)
	return InstructionStateArray is
		variable res: InstructionStateArray(data'range);
	begin
		for i in res'range loop
			res(i) := updateInstructionArgValues(data(i),
				updateArgValues(data(i).argValues, data(i).physicalArgs, aiArray(i).ready, aiArray(i).vals));
		end loop;
	
		return res;
	end function;

	function extractReadyMask(asA: ArgStatusStructArray) return std_logic_vector is
		variable res: std_logic_vector(asA'range);
	begin	
		for i in res'range loop
			res(i) := asA(i).readyNextAll;
		end loop;
		
		return res;
	end function;

		
	function iqStep(dataLiving: InstructionStateArray; dataNew: StageDataMulti; 
						 fullMask, readyMask: std_logic_vector;
						 nextAccepting: std_logic;
						 living, sending, prevSending: integer;
						 prevSendingOK: std_logic)
	return IQStepData is
		constant LEN: natural := dataLiving'length;
		variable res: IQStepData;
		variable i, j: integer;
	begin
		res.wantSend := '0';
		-- CAREFUL: avoid errors at undefined vales:
		if dataLiving'length > IQ_A_SIZE then
			return res;
		end if;
	
		res.iqDataNext := (others=>defaultInstructionState);
		res.iqFullMaskNext := (others=>'0');
		res.dispatchDataNew := defaultInstructionState;
		i := 0;
		-- Copy what's before first ready
		while 			(fullMask(i) 
				and not (readyMask(i) and nextAccepting)) = '1' loop
						-- CAREFUL: never allow shifting subsequent ops into slot which wants to send
									-- when it can't because next stage doesn't allow!
			res.iqDataNext(i) := dataLiving(i);
			res.iqFullMaskNext(i) := '1';			
			i := i + 1;
			if i >= LEN then
				return res;
			end if;
		end loop;
				--report "aaaa";
		-- Now we have (or don't have) first ready
		if readyMask(i) = '1' then
			res.dispatchDataNew := dataLiving(i);
			res.wantSend := '1';
		end if;
				
		-- Are there more full slots after first ready?
		for k in 0 to LEN-2 loop
			if k >= i and fullMask(k+1) = '1' then
				-- CAREFUL: this should never happen if sending is blocked, cause we'd overwrite the instruction!
				res.iqDataNext(i) := dataLiving(i+1);
				res.iqFullMaskNext(i) := '1';
				i := i + 1;				
			end if;
		end loop;	

		-- Now copy new input
		-- if prevSending = 0 then
		if prevSendingOK = '0' then
			return res;
		end if;
		j := 0;
				--report "ccccc";
		while i < LEN and j < PIPE_WIDTH and dataNew.fullMask(j) = '1' loop
			res.iqDataNext(i) := dataNew.data(j);
			res.iqFullMaskNext(i) := '1';
			i := i + 1;
			j := j + 1;
		end loop;
				--report "ddddd";
		return res;
	end function;
	
	
	
	function iqStep2(dataLiving: InstructionStateArray; dataNew: StageDataMulti; 
						 fullMask, readyMask: std_logic_vector;
						 nextAccepting: std_logic;
						 living, sending, prevSending: integer)
	return IQStepData is
		constant LEN: natural := dataLiving'length;
		variable res: IQStepData;
		variable j: integer := 0;
		variable before: boolean := true;
		variable sends: boolean := false;
	begin
		res.wantSend := '0';
		-- CAREFUL: avoid errors at undefined vales:
		if dataLiving'length > IQ_A_SIZE then
			return res;
		end if;
	
		res.iqDataNext := (others=>defaultInstructionState);
		res.iqFullMaskNext := (others=>'0');
		res.dispatchDataNew := defaultInstructionState;
		
		for i in 0 to LEN-1 loop
			if fullMask(i) = '1' and before and readyMask(i) = '0' then
				-- Copy this
				res.iqDataNext(i) := dataLiving(i); -- to the same position
				res.iqFullMaskNext(i) := '1';				
			elsif fullMask(i) = '1' and readyMask(i) = '1' then	
				before := false;
				-- Check if can send 
				if nextAccepting = '1' then
					sends := true;
					-- Prepare sending
					if readyMask(i) = '1' then
						res.dispatchDataNew := dataLiving(i);
						res.wantSend := '1';
					end if;					
				else	
					-- copy this
					res.iqDataNext(i) := dataLiving(i); -- to the same position
					res.iqFullMaskNext(i) := '1';					
				end if;
			elsif fullMask(i) = '1' and not before then 	
				-- Copy what remains after sending
				if sends then
					res.iqDataNext(i-1) := dataLiving(i); -- to shifter position
					res.iqFullMaskNext(i-1) := '1';
				else
					res.iqDataNext(i) := dataLiving(i); -- to the same position
					res.iqFullMaskNext(i) := '1';					
				end if;
			elsif fullMask(i) = '0' and j < dataNew.data'length and prevSending /= 0 then	
				-- Copy from new data
				if dataNew.fullMask(j) = '1' then
					res.iqDataNext(i) := dataNew.data(j);
					res.iqFullMaskNext(i) := '1';
				end if;
				j := j + 1;
			end if;
			
		end loop;
				
		return res;
	end function;
	
end TEMP_DEV;
