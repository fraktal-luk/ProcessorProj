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


function updateInstructionArgValues2(ins: InstructionState; ai: ArgStatusInfo;
													readyRegFlags: std_logic_vector) 
return InstructionState;


function getDispatchArgValues(ins: InstructionState; vals: MwordArray) return InstructionState;

function updateDispatchArgs(ins: InstructionState; vals: MwordArray; regValues: MwordArray)
return InstructionState;


function getForwardingStatusInfoD2(av: in InstructionArgValues; pa: in InstructionPhysicalArgs; 
										tags0, tags1, tags2, 
										nextTags, writtenTags: in PhysNameArray) return ArgStatusInfo;

function getArgInfoArrayD2(data: InstructionStateArray; 
										tags0, tags1, tags2, 
										nextTags, writtenTags: PhysNameArray)
return ArgStatusInfoArray;

	
-- True if all args are ready
-- UNUSED?
function readyForExec(ins: InstructionState) return std_logic;

function getArgStatus(ai: ArgStatusInfo;
							ins: InstructionState;
							 living: std_logic)
return ArgStatusStruct;	

function getArgStatusArray(aiA: ArgStatusInfoArray;
									insArr: InstructionStateArray;
									livingMask: std_logic_vector)
return ArgStatusStructArray;	

function updateIQData(data: InstructionStateArray; aiArray: ArgStatusInfoArray;
								readyRegFlags: std_logic_vector)
return InstructionStateArray;

function extractReadyMask(asA: ArgStatusStructArray) return std_logic_vector;	


function iqContentNext2(queueData: InstructionStateArray; inputData: StageDataMulti; 
								 fullMask, readyMask: std_logic_vector;
								 nextAccepting: std_logic;
								 living, sending, prevSending: integer;
								 prevSendingOK: std_logic)
return InstructionSlotArray;

function iqExtractData(queueContent: InstructionSlotArray) return InstructionStateArray;
	
end ProcLogicIQ;



package body ProcLogicIQ is
										
function updateInstructionArgValues2(ins: InstructionState; ai: ArgStatusInfo;
													readyRegFlags: std_logic_vector) 
return InstructionState is
	variable res: InstructionState := ins;
	
	variable tmp8: SmallNumber := (others => '0');
	variable rrf: std_logic_vector(0 to 2) := (others => '0');
begin
	-- What was on result buses before, now remains available
	res.argValues.readyBefore := res.argValues.readyBefore or res.argValues.readyNow;
	
	res.argValues.readyNow := (others => '0'); 
	res.argValues.readyNext := (others => '0');

	-- CAREFUL! Problem: this requires distinguishing from which place in Rename this was sent!
	--				This is to know which reg ready flags are for this instruction
	--			Solution? Use groupTag, bause it identifies the slot in pipeline multi stages!
	if res.argValues.newInQueue = '1' then
		tmp8 := res.groupTag and i2slv(PIPE_WIDTH-1, SMALL_NUMBER_SIZE);
		rrf := readyRegFlags(3*slv2u(tmp8) to 3*slv2u(tmp8) + 2);
			res.argValues.readyBefore := res.argValues.readyBefore or rrf; -- !! 'OR', not 'AND'
			res.argValues.missing := res.argValues.missing and not rrf;

		-- NOTE: this probably can be outside the 'if res.argValues.newInQueue' block
		if (res.argValues.missing(0) and ai.written(0)) = '1' then
			res.argValues.missing(0) := '0';
			res.argValues.readyBefore(0) := '1';
		end if;

		if (res.argValues.missing(1) and ai.written(1)) = '1' then
			res.argValues.missing(1) := '0';
			res.argValues.readyBefore(1) := '1';
		end if;
		
		if (res.argValues.missing(2) and ai.written(2)) = '1' then
			res.argValues.missing(2) := '0';
			res.argValues.readyBefore(2) := '1';
		end if;	

	end if;


	if (ins.argValues.missing(0) and ai.ready(0)) = '1' then
		res.argValues.missing(0) := '0';
		res.argValues.readyNow(0) := '1';
	end if;		

	if (ins.argValues.missing(1) and ai.ready(1)) = '1' then
		res.argValues.missing(1) := '0';
		res.argValues.readyNow(1) := '1';			
	end if;

	if (ins.argValues.missing(2) and ai.ready(2)) = '1' then
		res.argValues.missing(2) := '0';
		res.argValues.readyNow(2) := '1';			
	end if;



	if (ins.argValues.missing(0) and ai.nextReady(0)) = '1' then
		res.argValues.arg0 := ai.vals(0);
		res.argValues.readyNext(0) := '1';
	end if;		

	if (ins.argValues.missing(1) and ai.nextReady(1)) = '1' then
		res.argValues.arg1 := ai.vals(1);
		res.argValues.readyNext(1) := '1';
	end if;

	if (ins.argValues.missing(2) and ai.nextReady(2)) = '1' then
		res.argValues.arg2 := ai.vals(2);
		res.argValues.readyNext(2) := '1';
	end if;
	
	res.argValues.newInQueue := '0';
	
	res.argValues.locs(0) := ai.locs(0);
	res.argValues.locs(1) := ai.locs(1);
	res.argValues.locs(2) := ai.locs(2);
	
	res.argValues.nextLocs(0) := ai.nextLocs(0);
	res.argValues.nextLocs(1) := ai.nextLocs(1);
	res.argValues.nextLocs(2) := ai.nextLocs(2);
			
	return res;
end function;


function getDispatchArgValues(ins: InstructionState; vals: MwordArray) return InstructionState is
	variable res: InstructionState := ins;
begin
	if res.argValues.zero(0) = '1' then
		res.argValues.arg0 := (others => '0');
	else
		res.argValues.arg0 := vals(slv2u(res.argValues.locs(0)));
	end if;

	if res.argValues.immediate = '1' then
		res.argValues.arg1 := res.constantArgs.imm;
	elsif res.argValues.zero(1) = '1' then
		res.argValues.arg1 := (others => '0');
	else
		res.argValues.arg1 := vals(slv2u(res.argValues.locs(1)));
	end if;
	
	if res.argValues.zero(2) = '1' then
		res.argValues.arg2 := (others => '0');
	else
		res.argValues.arg2 := vals(slv2u(res.argValues.locs(2)));
	end if;	
	
	return res;
end function;


function updateDispatchArgs(ins: InstructionState; vals: MwordArray; regValues: MwordArray)
return InstructionState is
	variable res: InstructionState := ins;
begin
	if res.argValues.readyNext(0) = '1' then
		-- Use new value from Exec
		res.argValues.arg0 := vals(slv2u(ins.argValues.nextLocs(0)));
			res.argValues.missing(0) := '0';
	elsif 	res.argValues.readyNow(0) = '1' 
			or res.argValues.zero(0) = '1'
		then
		-- Use what is already saved from FN
		null;
	else
		-- Use register value
		res.argValues.arg0 := regValues(0);
	end if;
	
	
	if res.argValues.readyNext(1) = '1' then
		-- Use new value from Exec
		res.argValues.arg1 := vals(slv2u(ins.argValues.nextLocs(1)));
			res.argValues.missing(1) := '0';
	elsif 	res.argValues.readyNow(1) = '1'
			or res.argValues.zero(1) = '1'
			or res.argValues.immediate = '1'
		then
		-- Use what is already saved from FN
		null;
	else
		-- Use register value
		res.argValues.arg1 := regValues(1);
	end if;	
	
	
	if res.argValues.readyNext(2) = '1' then
		-- Use new value from Exec
		res.argValues.arg2 := vals(slv2u(ins.argValues.nextLocs(2)));
			res.argValues.missing(2) := '0';
	elsif 	res.argValues.readyNow(2) = '1'
			or res.argValues.zero(2) = '1'
		then
		-- Use what is already saved from FN
		null;
	else
		-- Use register value
		res.argValues.arg2 := regValues(2);
	end if;	
	return res;
end function;


function getForwardingStatusInfoD2(av: in InstructionArgValues; pa: in InstructionPhysicalArgs; 
										tags0, tags1, tags2, 
										nextTags, writtenTags: in PhysNameArray) return ArgStatusInfo
is		
	variable stored, ready, nextReady, written: std_logic_vector(0 to 2) := (others=>'0');
	variable locs, nextLocs: SmallNumberArray(0 to 2) := (others=>(others=>'0'));
	variable vals: MwordArray(0 to 2) := (others=>(others=>'0'));
	variable res: ArgStatusInfo;
begin
	stored := not av.missing;	
	
	for i in writtenTags'length-1 downto 0 loop
		if writtenTags(i) = pa.s0 then
			written(0) := '1';
		end if;

		if writtenTags(i) = pa.s1 then
			written(1) := '1';
		end if;

		if writtenTags(i) = pa.s2 then
			written(2) := '1';
		end if;		
	end loop;
	
	-- Find where tag agrees with s0
	for i in tags0'length-1 downto 0 loop		
		if tags0(i) = pa.s0 then
			ready(0) := '1';
			locs(0) := i2slv(i, SMALL_NUMBER_SIZE);
		end if;
	end loop;
		
	for i in tags1'length-1 downto 0 loop				
		if tags1(i) = pa.s1 then
			ready(1) := '1';
			locs(1) := i2slv(i, SMALL_NUMBER_SIZE);
		end if;
	end loop;		
		
	for i in tags2'length-1 downto 0 loop				
		if tags2(i) = pa.s2 then
			ready(2) := '1';
			locs(2) := i2slv(i, SMALL_NUMBER_SIZE);
		end if;
	end loop;
	
	for i in nextTags'range loop
	
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
	
	res.stored := stored;
		res.written := written;
	res.ready := ready;
	res.locs := locs;
	res.vals := vals;
	res.nextReady := nextReady;
	res.nextLocs := nextLocs;
	
	return res;								
end function;

function getArgInfoArrayD2(data: InstructionStateArray; 
										tags0, tags1, tags2, 
										nextTags, writtenTags: PhysNameArray)
return ArgStatusInfoArray is
	variable res: ArgStatusInfoArray(data'range);
begin
	for i in res'range loop
		res(i) := getForwardingStatusInfoD2(data(i).argValues, data(i).physicalArgs,
														tags0, tags1, tags2,
														nextTags, writtenTags);
	end loop;
	return res;
end function;


function getArgStatus(ai: ArgStatusInfo;
							ins: InstructionState;
							living: std_logic)
return ArgStatusStruct is
	variable res: ArgStatusStruct;
begin
	res.ready := ins.argValues.readyBefore or ins.argValues.readyNow;	
	res.readyNext := ins.argValues.readyNext;

	res.missing := ins.argValues.missing;
	res.readyNow := res.ready;
	
	res.stillMissing := res.missing and not res.readyNow;
			
	res.nextMissing := res.stillMissing and not res.readyNext;
	res.nMissing := countOnes(res.missing);
	res.nMissingNext := countOnes(res.nextMissing);

	res.readyAll := living and not isNonzero(res.stillMissing);
	res.readyNextAll := living and not isNonzero(res.nextMissing);		
	return res;
end function;
	
	
function getArgStatusArray(aiA: ArgStatusInfoArray;
									insArr: InstructionStateArray;
									livingMask: std_logic_vector)
return ArgStatusStructArray is
	variable res: ArgStatusStructArray(livingMask'range);
begin
	for i in res'range loop
		res(i) := getArgStatus(aiA(i), insArr(i), livingMask(i));
	end loop;
	return res;
end function;	


function updateIQData(data: InstructionStateArray; aiArray: ArgStatusInfoArray;
								readyRegFlags: std_logic_vector)
return InstructionStateArray is
	variable res: InstructionStateArray(data'range);
begin
	for i in res'range loop
		res(i) := updateInstructionArgValues2(data(i), aiArray(i), readyRegFlags);
	end loop;
	return res;
end function;


function readyForExec(ins: InstructionState) return std_logic is
	variable res: std_logic;
begin
	return not isNonzero(ins.argValues.missing);
--	if isNonzero(ins.argValues.missing) = '0' then
--		res := '1';
--	else
--		res := '0';
--	end if;	
--	return res;
end function;	

function extractReadyMask(asA: ArgStatusStructArray) return std_logic_vector is
	variable res: std_logic_vector(asA'range);
begin	
	for i in res'range loop
		res(i) := asA(i).readyNextAll;
	end loop;
	return res;
end function;


function iqContentNext2(queueData: InstructionStateArray; inputData: StageDataMulti; 
								 fullMask, readyMask: std_logic_vector;
								 nextAccepting: std_logic;
								 living, sending, prevSending: integer;
								 prevSendingOK: std_logic)
return InstructionSlotArray is
	constant QUEUE_SIZE: natural := queueData'length; -- queueData'right + 1;

	variable res: InstructionSlotArray(-1 to QUEUE_SIZE-1) := (others => DEFAULT_INSTRUCTION_SLOT); 
	-- CAREFUL! Not including the negative index
	variable i, j: integer;	
	
		variable dataNew: StageDataMulti := inputData;
	
	variable iqDataNext: InstructionStateArray(0 to QUEUE_SIZE - 1) -- + PIPE_WIDTH)
					:= (others => defaultInstructionState);
	variable iqFullMaskNext: std_logic_vector(0 to QUEUE_SIZE - 1) :=	(others => '0');
	variable dispatchDataNew: InstructionState := defaultInstructionState;
	variable sends, anyReady: std_logic := '0';
		
		variable xVec: InstructionStateArray(0 to QUEUE_SIZE + PIPE_WIDTH - 1);
		variable yVec: InstructionStateArray(0 to QUEUE_SIZE + PIPE_WIDTH - 1);
		variable yMask: std_logic_vector(0 to QUEUE_SIZE + PIPE_WIDTH-1)	:= (others => '0');
		variable x, y: integer := 0; 
		variable tempMask: std_logic_vector(0 to QUEUE_SIZE-1) := (others => '0');
		variable nAfterSending: integer := living;
			variable shiftNum: integer := 0;
			
	constant CLEAR_EMPTY_SLOTS_IQ: boolean := true;	-- UNUSED?		
begin
		-- Important, new instrucitons in queue must be marked!
		for i in 0 to PIPE_WIDTH-1 loop
			dataNew.data(i).argValues.newInQueue := '1';
		end loop;

		xVec := queueData & dataNew.data; -- CAREFUL: What to append after queueData?
					xVec(QUEUE_SIZE) := xVec(QUEUE_SIZE-1);
					
		for k in 0 to yVec'right loop
			yVec(k) := dataNew.data(k mod PIPE_WIDTH);
			yMask(k) := dataNew.fullMask(k mod PIPE_WIDTH);
		end loop;	
		
	-- Finding slots that are before first ready
	for i in 0 to tempMask'length-1 loop
		dispatchDataNew := queueData(i);	
		if readyMask(i) = '1' and nextAccepting = '1' then
			anyReady := '1';
			-- Assigned for sending			
			exit;
		end if;
		tempMask(i) := '1';
	end loop;

	if (anyReady and nextAccepting) = '1' then
		sends := '1';
		nAfterSending := nAfterSending-1;
	end if;
		
		if nAfterSending < 0 then
			nAfterSending := 0;
		elsif nAfterSending > yVec'length then	
			nAfterSending := yVec'length;
		end if;

		shiftNum := nAfterSending;
		
		-- CAREFUL, TODO:	solve the issue with HDLCompiler:1827
		yVec(shiftNum to yVec'length - 1) := yVec(0 to yVec'length - 1 - shiftNum);
		yMask(shiftNum to yVec'length - 1) := yMask(0 to yVec'length - 1 - shiftNum);

	-- Now assign from x or y
	iqDataNext := queueData;
	for i in 0 to QUEUE_SIZE-1 loop

		if i < nAfterSending + prevSending then
			iqFullMaskNext(i) := '1';
		else
			iqFullMaskNext(i) := '0';
		end if;

		if i < nAfterSending then				
		-- From x	
			if tempMask(i) = '1' then
				iqDataNext(i) := xVec(i);
			else
				iqDataNext(i) := xVec(i + 1);
			end if;
			--iqFullMaskNext(i) := '1';	
		else
		-- From y
			iqDataNext(i) := yVec(i);
			--iqFullMaskNext(i) := yMask(i);
		end if;
	end loop;

	-- Fill output array
	for i in 0 to res'right loop
		res(i).full := iqFullMaskNext(i);
		res(i).ins := iqDataNext(i);
	end loop;
	res(-1).full := sends;
	res(-1).ins := dispatchDataNew;
	return res;
end function;


function iqExtractData(queueContent: InstructionSlotArray) return InstructionStateArray is
	variable res: InstructionStateArray(0 to queueContent'length-1) := (others => defaultInstructionState);
begin
	for i in res'range loop
		res(i) := queueContent(i).ins;
	end loop;
	return res;
end function;

end ProcLogicIQ;
