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

function getDispatchArgValues(ins: InstructionState; vals: MwordArray) return InstructionState;

function updateDispatchArgs(ins: InstructionState; vals: MwordArray; regValues: MwordArray;
										ai: ArgStatusInfo)
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

function getDispatchArgValues(ins: InstructionState; vals: MwordArray) return InstructionState is
	variable res: InstructionState := ins;
begin
	-- pragma synthesis off
		res.argValues.hist0(2) := '-';
		res.argValues.hist1(2) := '-';
		res.argValues.hist2(2) := '-';
	-- pragma synthesis on

	if res.argValues.zero(0) = '1' then
		res.argValues.arg0 := (others => '0');
			-- pragma synthesis off		
			res.argValues.hist0(2) := 'z';
			-- pragma synthesis on			
	end if;

	if res.argValues.immediate = '1' then
		res.argValues.arg1 := res.constantArgs.imm;
			-- pragma synthesis off		
			res.argValues.hist1(2) := 'i';
			-- pragma synthesis on
	elsif --false and
			res.argValues.zero(1) = '1' then
		res.argValues.arg1 := (others => '0');
			-- pragma synthesis off		
			res.argValues.hist1(2) := 'z';
			-- pragma synthesis on
	end if;
	
	if res.argValues.zero(2) = '1' then
		res.argValues.arg2 := (others => '0');
			-- pragma synthesis off		
			res.argValues.hist2(2) := 'z';		
			-- pragma synthesis on
	end if;	
	
	return res;
end function;


function updateDispatchArgs(ins: InstructionState; vals: MwordArray; regValues: MwordArray;
										ai: ArgStatusInfo)
return InstructionState is
	variable res: InstructionState := ins;
begin
	-- pragma synthesis off
		res.argValues.hist0(3) := '-';
		res.argValues.hist1(3) := '-';
		res.argValues.hist2(3) := '-';
	-- pragma synthesis on

	if 	res.argValues.readyNow(0) = '1' 
		or res.argValues.zero(0) = '1'
		then
		-- Use what is already saved from FN
		null;
	elsif
		res.argValues.readyNext(0) = '1' then
		-- Use new value from Exec
		res.argValues.arg0 := vals(slv2u(ins.argValues.nextLocs(0)));
			res.argValues.missing(0) := '0';
			res.argValues.missing(0) := not ai.ready(0);
				-- pragma synthesis off			
				res.argValues.hist0(3) := 'n';			
				-- pragma synthesis on
	else
		-- Use register value
		res.argValues.arg0 := regValues(0);
			-- pragma synthesis off		
			res.argValues.hist0(3) := 'r';		
			-- pragma synthesis on
	end if;
	
	
	if 	res.argValues.readyNow(1) = '1'
		or res.argValues.zero(1) = '1'
		or res.argValues.immediate = '1'
		then
		-- Use what is already saved from FN
		null;
	elsif	
		res.argValues.readyNext(1) = '1' then
		-- Use new value from Exec
		res.argValues.arg1 := vals(slv2u(ins.argValues.nextLocs(1)));
			res.argValues.missing(1) := '0';
			res.argValues.missing(1) := not ai.ready(1);
				-- pragma synthesis off			
				res.argValues.hist1(3) := 'n';			
				-- pragma synthesis on
	else
		-- Use register value
		res.argValues.arg1 := regValues(1);
			-- pragma synthesis off		
			res.argValues.hist1(3) := 'r';		
			-- pragma synthesis on
	end if;	
	
	
	if 	res.argValues.readyNow(2) = '1'
		or res.argValues.zero(2) = '1'
		then
		-- Use what is already saved from FN
		null;
	elsif res.argValues.readyNext(2) = '1' then
		-- Use new value from Exec
		res.argValues.arg2 := vals(slv2u(ins.argValues.nextLocs(2)));
			res.argValues.missing(2) := '0';
			res.argValues.missing(2) := not ai.ready(2);
				-- pragma synthesis off			
				res.argValues.hist2(3) := 'n';			
				-- pragma synthesis on
	else
		-- Use register value
		res.argValues.arg2 := regValues(2);
			-- pragma synthesis off		
			res.argValues.hist2(3) := 'r';		
			-- pragma synthesis on
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
			res.argValues.hist0(1) := '-';
			res.argValues.hist0(2) := '-';
			res.argValues.hist0(3) := '-';
		-- pragma synthesis on
	
	-- For 'nextReady'
	if ai.nextReady(0) = '1' then
		res.argValues.missing(0) := '0';
		res.argValues.readyNext(0) := '1';
			-- pragma synthesis off			
			res.argValues.hist0(1) := 'N';
			-- pragma synthesis on			
	end if;		

	if ai.nextReady(1) = '1' then
		res.argValues.missing(1) := '0';
		res.argValues.readyNext(1) := '1';
			-- pragma synthesis off				
			res.argValues.hist1(1) := 'N';
			-- pragma synthesis on		
	end if;

	if ai.nextReady(2) = '1' then
		res.argValues.missing(2) := '0';
		res.argValues.readyNext(2) := '1';
			-- pragma synthesis off				
			res.argValues.hist2(1) := 'N';
			-- pragma synthesis on			
	end if;

	-- For 'ready'
	if ai.ready(0) = '1' then
		--res.argValues.missing(0) := '0'; -- NOTE: it would increase delay, unneeded with full 'nextReady'
		res.argValues.readyNow(0) := '1';
		res.argValues.arg0 := ai.vals(0);
			-- pragma synthesis off				
			res.argValues.hist0(1) := 'u';
			-- pragma synthesis on			
	end if;		

	if ai.ready(1) = '1' then
		--res.argValues.missing(1) := '0';
		res.argValues.readyNow(1) := '1';
		res.argValues.arg1 := ai.vals(1);
			-- pragma synthesis off				
			res.argValues.hist1(1) := 'u';
			-- pragma synthesis on			
	end if;

	if ai.ready(2) = '1' then
		--res.argValues.missing(2) := '0';
		res.argValues.readyNow(2) := '1';
		res.argValues.arg2 := ai.vals(2);
			-- pragma synthesis off				
			res.argValues.hist2(1) := 'u';
			-- pragma synthesis on			
	end if;
		
	res.argValues.locs := ai.locs;	
	res.argValues.nextLocs := ai.nextLocs;
	
	res.argValues.arg0 := ai.vals(0);
	res.argValues.arg1 := ai.vals(1);
	res.argValues.arg2 := ai.vals(2);
	
		--	res.virtualArgs := defaultVirtualArgs;
		--	res.virtualDestArgs := defaultVirtualDestArgs;

		res.bits := (others => '0');
		res.result := (others => '0');
		res.target := (others => '0');		
--		
		res.controlInfo.completed := '0';
		
		res.controlInfo.newEvent := '0';
		res.controlInfo.newInterrupt := '0';
		res.controlInfo.newException := '0';
		res.controlInfo.newBranch := '0';
		res.controlInfo.newReturn := '0';
		res.controlInfo.newFetchLock := '0';

		--	res.controlInfo.hasEvent := '0';
		res.controlInfo.hasInterrupt := '0';
		--	res.controlInfo.hasException := '0';
		--	res.controlInfo.hasBranch := '0';
		res.controlInfo.hasReturn := '0';
		res.controlInfo.hasFetchLock := '0';
		
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
