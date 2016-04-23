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


package ProcLogicIQ is				
				
-- Get inputs form registers and immediate value
function getIssueArgValues(pa: InstructionPhysicalArgs; ca: InstructionConstantArgs;
									ready: std_logic_vector; vals: MwordArray)
return InstructionArgValues;

-- get args still missing (used while waiting for issue, possibly in the cycle when going to Exec)
function updateArgValues(av: InstructionArgValues; pa: InstructionPhysicalArgs; ready: std_logic_vector;
								vals: MwordArray) 
return InstructionArgValues; 

function updateInstructionArgValues(ins: InstructionState; av: InstructionArgValues) 
return InstructionState;	

procedure findForwardingSourcesWithNext(av: in InstructionArgValues; pa: in InstructionPhysicalArgs; 
										tags: in PhysNameArray; content: in MwordArray;
										nextTags: in PhysNameArray;
										stored: out std_logic_vector;
										ready: out std_logic_vector; locs: out SmallNumberArray;
										nextReady: out std_logic_vector; nextLocs: out SmallNumberArray;											
										vals: out MwordArray);																						

function getForwardingStatusInfo(av: in InstructionArgValues; pa: in InstructionPhysicalArgs; 
										 content: in MwordArray;--fn: ForwardingNetwork
										tags, nextTags: in PhysNameArray) return ArgStatusInfo;

function getArgInfoArray(data: InstructionStateArray; vals: MwordArray; 
										resultTags, nextTags: PhysNameArray)	
return ArgStatusInfoArray;	
	
-- True if all args are ready
function readyForExec(ins: InstructionState) return std_logic;

function getArgStatus(ai: ArgStatusInfo;
							 missing, uMissing: std_logic_vector(0 to 2);								 
							 living: std_logic;
							 readyRegs: std_logic_vector)
return ArgStatusStruct;	

function getArgStatusArray(aiA: ArgStatusInfoArray;
									livingMask: std_logic_vector;
									readyRegs: std_logic_vector)
return ArgStatusStructArray;	

function updateIQData(data: InstructionStateArray; aiArray: ArgStatusInfoArray)
return InstructionStateArray;

function extractReadyMask(asA: ArgStatusStructArray) return std_logic_vector;	

function iqStep(dataLiving: InstructionStateArray; dataNew: StageDataMulti; 
					 fullMask, readyMask: std_logic_vector;
					 nextAccepting: std_logic;						 
					 living, sending, prevSending: integer;
					 prevSendingOK: std_logic)					 
return IQStepData;
	
end ProcLogicIQ;



package body ProcLogicIQ is
	
-- Get inputs form registers and immediate value
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
										
										
procedure findForwardingSourcesWithNext(av: in InstructionArgValues; pa: in InstructionPhysicalArgs; 
										tags: in PhysNameArray; content: in MwordArray;
										nextTags: in PhysNameArray;
										stored: out std_logic_vector;
										ready: out std_logic_vector; locs: out SmallNumberArray;
										nextReady: out std_logic_vector; nextLocs: out SmallNumberArray;											
										vals: out MwordArray)
is
	--variable res: SmallNumberArray(0 to 2) := (others=>(others=>'0'));
begin
	stored := not av.missing;
	ready := "000";
	locs := (others=>(others=>'0'));
	vals := (others=>(others=>'0'));
	nextReady := "000";
	nextLocs := (others=>(others=>'0'));		
	
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
	
	for i in nextTags'range loop
			-- CAREFUL
			if isNonzero(nextTags(i)) = '0' then
				next;
			end if;		
		if nextTags(i) = pa.s0 then
			nextReady(0) := '1';
			nextLocs(0) := i2slv(i, SMALL_NUMBER_SIZE);
		end if;
		if nextTags(i) = pa.s1 then
			nextReady(1) := '1';
			nextLocs(1) := i2slv(i, SMALL_NUMBER_SIZE);
		end if;
		if nextTags(i) = pa.s2 then
			nextReady(2) := '1';
			nextLocs(2) := i2slv(i, SMALL_NUMBER_SIZE);
		end if;			
	end loop;
	
end procedure;	
	

function getForwardingStatusInfo(av: in InstructionArgValues; pa: in InstructionPhysicalArgs; 
										 content: in MwordArray;--fn: ForwardingNetwork
										tags, nextTags: in PhysNameArray) return ArgStatusInfo
is		
	variable stored, ready, nextReady: std_logic_vector(0 to 2) := (others=>'0');
	variable locs, nextLocs: SmallNumberArray(0 to 2) := (others=>(others=>'0'));
	variable vals: MwordArray(0 to 2) := (others=>(others=>'0'));
begin
	findForwardingSourcesWithNext(av, pa, 
									tags,	content,
									nextTags,
									stored,	
									ready, locs,
									nextReady, nextLocs,
									vals);
	return (stored, ready, locs, vals,		nextReady, nextLocs);								
end function;	

function getArgInfoArray(data: InstructionStateArray; vals: MwordArray; 
										resultTags, nextTags: PhysNameArray)
return ArgStatusInfoArray is
	variable res: ArgStatusInfoArray(data'range);
begin
	for i in res'range loop
		res(i) := getForwardingStatusInfo(data(i).argValues, data(i).physicalArgs, vals, 
					resultTags, nextTags);
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


function getArgStatus(ai: ArgStatusInfo;
							 missing, uMissing: std_logic_vector(0 to 2);
							 living: std_logic;
							 readyRegs: std_logic_vector)
return ArgStatusStruct is
	--constant missing: std_logic_vector(0 to 2) := missing; -- data.argValues.missing;
	--constant uMissing: std_logic_vector(0 to 2) := uMissing; -- dataUpdated.argValues.missing;
	variable res: ArgStatusStruct;
begin
	res.ready := ai.ready;
	res.locs := ai.locs;
	res.vals := ai.vals;
	res.readyNext := ai.nextReady;
	
	-- NOTE: 'missing' will be 'not ai.stored' 		
	res.missing := not ai.stored;
			res.C_missing := missing; 
							--assert res.missing /= not ai.stored report "123" severity error;
	res.readyReg := readyRegs;
	res.readyNow := res.ready;
	
	-- NOTE: 'stillMissing' will be 'missing and not readyNow (??and not readyRegs??)'
	res.stillMissing := res.missing and not res.readyNow;
			res.C_stillMissing := uMissing;
				--assert res.stillMissing /= (res.missing and not res.readyNow) report "456" severity error;										
								
	res.nextMissing := res.stillMissing and not res.readyNext and not res.readyReg;
	res.nMissing :=  countOnes(res.missing);
	res.nMissingNext := countOnes(res.nextMissing);
	
	res.readyAll := living and not isNonzero(res.stillMissing);
	res.readyNextAll := living and not isNonzero(res.nextMissing);		
	return res;
end function;
	
								
function getArgStatusArray(aiA: ArgStatusInfoArray;
									livingMask: std_logic_vector;
									readyRegs: std_logic_vector)
return ArgStatusStructArray is
	variable res: ArgStatusStructArray(livingMask'range);
begin
	for i in res'range loop
		res(i) := getArgStatus(aiA(i), "000", "000", livingMask(i), readyRegs(3*i to 3*i + 2)); --,
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
	res.sends := '0';	
	res.iqDataNext := (others=>defaultInstructionState);
	res.iqFullMaskNext := (others=>'0');
	res.dispatchDataNew := defaultInstructionState;
	-- CAREFUL: avoid errors at undefined vales:
	if dataLiving'length > IQ_A_SIZE then
		return res;
	end if;		
	
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
	-- Now we have (or don't have) first ready
	if (readyMask(i) and nextAccepting) = '1' then
		res.dispatchDataNew := dataLiving(i);
		res.sends := '1';
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
	while i < LEN and j < PIPE_WIDTH and dataNew.fullMask(j) = '1' loop
		res.iqDataNext(i) := dataNew.data(j);
		res.iqFullMaskNext(i) := '1';
		i := i + 1;
		j := j + 1;
	end loop;
	return res;
end function;

end ProcLogicIQ;
