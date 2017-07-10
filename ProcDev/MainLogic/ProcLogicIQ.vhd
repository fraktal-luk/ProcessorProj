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

function getDispatchArgValues(ins: InstructionState;-- ai: ArgStatusInfo;
										vals: MwordArray)
return InstructionState;

function updateDispatchArgs(ins: InstructionState; vals: MwordArray; regValues: MwordArray) --;
										--ai: ArgStatusInfo)
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

function iqContentNext3(queueData, queueDataSel: InstructionStateArray; inputData: StageDataMulti; 
								 fullMask,
										livingMask,
								 readyMask: std_logic_vector;
								 nextAccepting: std_logic;
								 living, sending, prevSending: integer;
								 prevSendingOK: std_logic)
return InstructionSlotArray;

function extractReadyMaskNew(insVec: InstructionStateArray) return std_logic_vector;


function updateForWaiting(ins: InstructionState;
									readyRegFlags: std_logic_vector;
									ai: ArgStatusInfo;
									isNew: std_logic)
									return InstructionState;
									
function updateForSelection(ins: InstructionState;
									readyRegFlags: std_logic_vector;
									ai: ArgStatusInfo)
									return InstructionState;
									
function updateForWaitingArray(insArray: InstructionStateArray;
									readyRegFlags: std_logic_vector;
									aia: ArgStatusInfoArray;
									isNew: std_logic)
									return InstructionStateArray;
									
function updateForSelectionArray(insArray: InstructionStateArray;
									readyRegFlags: std_logic_vector;
									aia: ArgStatusInfoArray)
									return InstructionStateArray;	
end ProcLogicIQ;



package body ProcLogicIQ is

-- pragma synthesis off

function beginHistory(avs: InstructionArgValues; ready: std_logic_vector; nextReady: std_logic_vector)
return InstructionArgValues is
	variable res: InstructionArgValues := avs;
begin
	res.hist0(1) := '-';
	res.hist0(2) := '-';
	res.hist0(3) := '-';
	
	res.hist1(1) := '-';
	res.hist1(2) := '-';
	res.hist1(3) := '-';

	res.hist2(1) := '-';
	res.hist2(2) := '-';
	res.hist2(3) := '-';	
	
	if nextReady(0) = '1' then
		res.hist0(1) := 'N';
	end if;		

	if nextReady(1) = '1' then			
		res.hist1(1) := 'N';
	end if;

	if nextReady(2) = '1' then				
		res.hist2(1) := 'N';
	end if;			
	
	if ready(0) = '1' then
		res.hist0(1) := 'u';
	end if;		

	if ready(1) = '1' then
		res.hist1(1) := 'u';
	end if;

	if ready(2) = '1' then
		res.hist2(1) := 'u';
	end if;		
	
	return res;
end function;

function dispatchArgHistory(avs: InstructionArgValues) return InstructionArgValues is
	variable res: InstructionArgValues := avs;
begin
	res.hist0(2) := '-';
	res.hist1(2) := '-';
	res.hist2(2) := '-';	
	
	if avs.zero(0) = '1' then
		res.hist0(2) := 'z';	
	end if;
	
	if avs.immediate = '1' then
		res.hist1(2) := 'i';		
	elsif avs.zero(1) = '1' then
		res.hist1(2) := 'z';	
	end if;
	
	if avs.zero(2) = '1' then
		res.hist2(2) := 'z';	
	end if;		
	
	return res;
end function;

function updateArgHistory(avs: InstructionArgValues) return InstructionArgValues is
	variable res: InstructionArgValues := avs;
begin
	res.hist0(3) := '-';
	res.hist1(3) := '-';
	res.hist2(3) := '-';
	
	if (avs.readyNext(0) and not avs.zero(0)) = '1' then
		res.hist0(3) := 'n';	
	elsif (avs.readyNow(0) and not avs.zero(0)) = '1' then
	else
		res.hist0(3) := 'r';	
	end if;

	if	(avs.readyNext(1) and not avs.zero(1) and not avs.immediate) = '1' then
		res.hist1(3) := 'n';	
	elsif (avs.immediate or (avs.readyNow(1) and not avs.zero(2))) = '1' then
	else
		res.hist1(3) := 'r';		
	end if;

	if (avs.readyNext(2) and not avs.zero(2)) = '1' then
		res.hist2(3) := 'n';
	elsif (avs.readyNow(2) and not avs.zero(2)) = '1' then	
	else
		res.hist2(3) := 'r';
	end if;		
		
	return res;
end function;
-- pragma synthesis on


function selectUpdatedArg(avs: InstructionArgValues; ind: integer; immed: std_logic; def: Mword;
								  vals: MwordArray; regValues: MwordArray)
return Mword is
	variable res: Mword := def;
	variable selector: std_logic_vector(1 downto 0) := "00";
	variable tbl: MwordArray(0 to 3) := (others => (others => '0'));
begin
	
	if	(avs.readyNext(ind) and not avs.zero(ind) and not immed) = '1' then
		-- Use new value from Exec
		res := vals(slv2u(avs.nextLocs(ind)));		
			selector := avs.nextLocs(ind)(1 downto 0);
	elsif (avs.readyNow(ind) and not avs.zero(ind)) = '1' then
		res := def;
			selector := "10";
	else -- Use register value
		res := regValues(ind);
			selector := "11";
	end if;
		
	tbl(0) := vals(0);
	tbl(1) := vals(1);
	tbl(2) := def;
	tbl(3) := regValues(ind);
	
	case selector is
		when "00" => 
			res := tbl(0);
		when "01" => 
			res := tbl(1);
		when "10" => 
			res := tbl(2);
		when others => 
			res := tbl(3);
	end case;
	
	return res;
end function;


function getDispatchArgValues(ins: InstructionState;-- ai: ArgStatusInfo;
										vals: MwordArray)
return InstructionState is
	variable res: InstructionState := ins;
		variable v0, v1: std_logic_vector(1 downto 0) := "00";
		variable selected0, selected1: Mword := (others => '0');
begin			
	res.argValues.arg0 := vals(slv2u(res.argValues.locs(0)));
	
	if res.argValues.immediate = '1' then
		res.argValues.arg1 := res.constantArgs.imm;
	else
		res.argValues.arg1 := vals(slv2u(res.argValues.locs(1)));
	end if;
	
------ Different formulation for arg1 to use 2 LUTs rather than 3 per bit.
--		 Doesn't work as expected, probably need to be directly forced in lower level.
---------------------------------------
--	v0 := res.argValues.locs(1)(1 downto 0);
--	
--	if res.argValues.immediate = '1' then
--		v1 := "11";
--	elsif res.argValues.locs(1)(2 downto 0) = "100" then
--		v1 := "01";
--	elsif res.argValues.locs(1)(2 downto 0) = "101" then
--		v1 := "10";
--	else
--		v1 := "00";
--	end if;
--	
--	case v0 is
--		when "00" =>
--			selected0 := vals(0);
--		when "01" => 
--			selected0 := vals(1);
--		when "10" => 
--			selected0 := vals(2);
--		when others => 
--			selected0 := vals(3);
--	end case;		
--	
--	case v1 is
--		when "00" =>
--			selected1 := selected0;
--		when "01" => 
--			selected1 := vals(4);
--		when "10" => 
--			selected1 := vals(5);
--		when others => 
--			selected1 := res.constantArgs.imm;
--	end case;
--	
--	res.argValues.arg1 := selected1;
----------------------------------
	
	res.argValues.arg2 := vals(slv2u(res.argValues.locs(2)));

	-- pragma synthesis off
	res.argValues := dispatchArgHistory(res.argValues);
	-- pragma synthesis on
	
	return res;
end function;


function updateDispatchArgs(ins: InstructionState; vals: MwordArray; regValues: MwordArray) --;
										--ai: ArgStatusInfo)
return InstructionState is
	variable res: InstructionState := ins;
	variable aa: MwordArray(0 to 5) := (others => (others => '0'));
	variable ind: integer := 0;
		variable selector: std_logic_vector(0 to 1) := "00";
		variable tbl: MwordArray(0 to 3) := (others => (others => '0'));
		variable carg0, carg1, carg2: Mword;
begin
	-- pragma synthesis off
	res.argValues := updateArgHistory(res.argValues);
	-- pragma synthesis on

-- readyNext && not zero -> next val, readyNow && not zero -> keep, else -> reg

	-- Clear 'missing' flag where readyNext indicates.
	res.argValues.missing := res.argValues.missing and 
								not (res.argValues.readyNext and not res.argValues.zero);

	carg0 := selectUpdatedArg(res.argValues, 0, '0', res.argValues.arg0, vals, regValues);	
	carg1 := selectUpdatedArg(res.argValues, 1, res.argValues.immediate, res.argValues.arg1, vals, regValues);	
	carg2 := selectUpdatedArg(res.argValues, 2, '0', res.argValues.arg2, vals, regValues);	

	res.argValues.arg0 := carg0;
	res.argValues.arg1 := carg1;
	res.argValues.arg2 := carg2;

	return res;
end function;


function getForwardingStatusInfoD2(av: in InstructionArgValues; pa: in InstructionPhysicalArgs; 
										tags0, tags1, tags2, 
										nextTags, writtenTags: in PhysNameArray) return ArgStatusInfo
is		
	variable stored, ready, nextReady, written: std_logic_vector(0 to 2) := (others=>'0');
	variable locs, nextLocs: SmallNumberArray(0 to 2) := (others=>(others=>'0'));
	--variable vals: MwordArray(0 to 2) := (others=>(others=>'0'));
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
	--res.vals := vals;
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


function readyForExec(ins: InstructionState) return std_logic is
	variable res: std_logic;
begin
	return not isNonzero(ins.argValues.missing);
end function;	

function extractReadyMaskNew(insVec: InstructionStateArray) return std_logic_vector is
	variable res: std_logic_vector(insVec'range);
begin	
	for i in res'range loop
		res(i) := not isNonzero(insVec(i).argValues.missing);
	end loop;
	return res;
end function;


function iqContentNext3(queueData, queueDataSel: InstructionStateArray; inputData: StageDataMulti; 
								 fullMask,
									livingMask,
								 readyMask: std_logic_vector;
								 nextAccepting: std_logic;
								 living, sending, prevSending: integer;
								 prevSendingOK: std_logic)
return InstructionSlotArray is
	constant QUEUE_SIZE: natural := queueData'length; -- queueData'right + 1;

	variable res: InstructionSlotArray(-1 to QUEUE_SIZE-1) := (others => DEFAULT_INSTRUCTION_SLOT); 
	
	variable dataNew: StageDataMulti := inputData;
	
	variable iqDataNext: InstructionStateArray(0 to QUEUE_SIZE - 1) -- + PIPE_WIDTH)
					:= (others => defaultInstructionState);
	variable iqFullMaskNext: std_logic_vector(0 to QUEUE_SIZE - 1) :=	(others => '0');
	variable dispatchDataNew: InstructionState := defaultInstructionState;
	variable sends, anyReady: std_logic := '0';
				
	variable xVec: InstructionStateArray(0 to QUEUE_SIZE + PIPE_WIDTH - 1);
	variable yVec: InstructionStateArray(0 to QUEUE_SIZE + PIPE_WIDTH - 1);
	variable yMask: std_logic_vector(0 to QUEUE_SIZE + PIPE_WIDTH-1)	:= (others => '0');
	variable tempMask: std_logic_vector(0 to QUEUE_SIZE-1) := (others => '0');
	variable fullMaskSh: std_logic_vector(0 to QUEUE_SIZE-1) := livingMask; --fullMask;
	variable nAfterSending: integer := living;
	variable shiftNum: integer := 0;			
begin
		-- Important, new instrucitons in queue must be marked!
		for i in 0 to PIPE_WIDTH-1 loop
			dataNew.data(i).argValues.newInQueue := '1';
		end loop;

		xVec := queueData & dataNew.data; -- CAREFUL: What to append after queueData?
		xVec(QUEUE_SIZE) := xVec(QUEUE_SIZE-1);
					
		for k in 0 to yVec'right loop
			yVec(k) := dataNew.data(k mod PIPE_WIDTH);
		end loop;	
		
		for k in 0 to PIPE_WIDTH-1 loop
			yMask(k) := dataNew.fullMask(k); -- not wrapping mod k, to enable straight copying to new fullMask
		end loop;
		
	-- Finding slots that are before first ready
	dispatchDataNew := queueDataSel(0);
	tempMask := (others => not nextAccepting);  -- CAREFUL! This because if not nextAccepting, nothing
																	-- is send, so no shifting.
	for i in 0 to tempMask'length-1 loop
		dispatchDataNew := queueDataSel(i);	
		if readyMask(i) = '1' then
			anyReady := livingMask(i); -- and nextAccepting; 
			exit;
		end if;
		tempMask(i) := '1';
	end loop;

	if (anyReady and nextAccepting) = '1' then
		sends := '1';
		nAfterSending := nAfterSending-1;
		fullMaskSh(0 to QUEUE_SIZE-2) := livingMask(1 to QUEUE_SIZE-1);
		fullMaskSh(QUEUE_SIZE-1) := '0';
	end if;
		
	-- CAREFUL! When not dispatching, dispatch stage must signal no result, so clear it here
	if sends = '0' then
		dispatchDataNew.physicalDestArgs.d0 := (others => '0');
	end if;
	
	if nAfterSending < 0 then
		nAfterSending := 0;
	elsif nAfterSending > yVec'length then	
		nAfterSending := yVec'length;
	end if;

	shiftNum := nAfterSending;
		shiftNum := countOnes(fullMaskSh); -- CAREFUL: this seems to reduce some logic
		
	-- CAREFUL, TODO:	solve the issue with HDLCompiler:1827
	yVec(shiftNum to yVec'length - 1) := yVec(0 to yVec'length - 1 - shiftNum);
	yMask(shiftNum to yVec'length - 1) := yMask(0 to yVec'length - 1 - shiftNum);

	-- Now assign from x or y
	iqDataNext := queueData;
	for i in 0 to QUEUE_SIZE-1 loop
		iqFullMaskNext(i) := fullMaskSh(i) or (yMask(i) and prevSendingOK);
		if fullMaskSh(i) = '1' then -- From x	
			if tempMask(i) = '1' then
				iqDataNext(i) := xVec(i);
			else
				iqDataNext(i) := xVec(i + 1);
			end if;
		else -- From y
			iqDataNext(i) := yVec(i);
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


function updateForWaiting(ins: InstructionState;
									readyRegFlags: std_logic_vector;
									ai: ArgStatusInfo;
									isNew: std_logic)
									return InstructionState is
	variable res: InstructionState := ins;
	variable tmp8: SmallNumber := (others => '0');
	variable rrf: std_logic_vector(0 to 2) := (others => '0');
begin	
	res.argValues.readyNow := (others => '0'); 
	res.argValues.readyNext := (others => '0');

	-- 
	if res.argValues.newInQueue = '1' then
		tmp8 := res.groupTag and i2slv(PIPE_WIDTH-1, SMALL_NUMBER_SIZE);
		rrf := readyRegFlags(3*slv2u(tmp8) to 3*slv2u(tmp8) + 2);
		res.argValues.missing := res.argValues.missing and not rrf;
	end if;
	
	res.argValues.missing := res.argValues.missing and not ai.written;
	res.argValues.missing := res.argValues.missing and not ai.ready;
	res.argValues.missing := res.argValues.missing and not ai.nextReady;	
	
	-- CAREFUL! DEPREC statement?
	res.argValues.newInQueue := isNew;
	
		res.basicInfo := DEFAULT_BASIC_INFO;	
	
	return res;
end function;


function updateForSelection(ins: InstructionState;
									readyRegFlags: std_logic_vector;
									ai: ArgStatusInfo)
									return InstructionState is
	variable res: InstructionState := ins;
	variable tmp8: SmallNumber := (others => '0');
	variable rrf: std_logic_vector(0 to 2) := (others => '0');
begin	
	res.argValues.readyNow := (others => '0'); 
	res.argValues.readyNext := (others => '0');

	-- Checking reg ready flags (only for new ops in queue)
	-- CAREFUL! Which reg ready flags are for this instruction?
	--				Use groupTag, because it identifies the slot in previous superscalar stage
	if res.argValues.newInQueue = '1' then
		tmp8 := res.groupTag and i2slv(PIPE_WIDTH-1, SMALL_NUMBER_SIZE);
		rrf := readyRegFlags(3*slv2u(tmp8) to 3*slv2u(tmp8) + 2);
		res.argValues.missing := res.argValues.missing and not rrf;
	end if;

	-- pragma synthesis off				
	res.argValues := beginHistory(res.argValues, ai.ready, ai.nextReady);
	-- pragma synthesis on

	res.argValues.missing := res.argValues.missing and not ai.nextReady;
	res.argValues.readyNext := ai.nextReady;
	-- CAREFUL, NOTE: updating 'missing' with ai.ready would increase delay, unneeded with full 'nextReady'	
	res.argValues.readyNow := ai.ready;	

	res.argValues.locs := ai.locs;	
	res.argValues.nextLocs := ai.nextLocs;

		res.bits := (others => '0');
		res.result := (others => '0');
		res.target := (others => '0');		
--		
		res.controlInfo.completed := '0';
		res.controlInfo.completed2 := '0';
			res.basicInfo := DEFAULT_BASIC_INFO;
		res.controlInfo.newEvent := '0';
		--res.controlInfo.newInterrupt := '0';
		--res.controlInfo.newException := '0';
		res.controlInfo.newBranch := '0';
		--res.controlInfo.newReturn := '0';
		--res.controlInfo.newFetchLock := '0';

		--	res.controlInfo.hasEvent := '0';
		res.controlInfo.hasInterrupt := '0';
		--	res.controlInfo.hasException := '0';
		--	res.controlInfo.hasBranch := '0';
		res.controlInfo.hasReturn := '0';
		--res.controlInfo.hasFetchLock := '0';
		
		res.controlInfo.exceptionCode := (others => '0');
	
	return res;
end function;
							
									
function updateForWaitingArray(insArray: InstructionStateArray;
									readyRegFlags: std_logic_vector;
									aia: ArgStatusInfoArray;
									isNew: std_logic)
									return InstructionStateArray is
	variable res: InstructionStateArray(0 to insArray'length-1) := insArray;
begin
	for i in insArray'range loop			
		res(i) := updateForWaiting(insArray(i), readyRegFlags, aia(i), isNew);
	end loop;
	return res;
end function;


function updateForSelectionArray(insArray: InstructionStateArray;
									readyRegFlags: std_logic_vector;
									aia: ArgStatusInfoArray)
									return InstructionStateArray is
	variable res: InstructionStateArray(0 to insArray'length-1) := insArray;
begin
	for i in insArray'range loop
		res(i) := updateForSelection(insArray(i), readyRegFlags, aia(i));
	end loop;	
	return res;
end function;

end ProcLogicIQ;
