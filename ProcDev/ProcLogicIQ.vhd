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
		
function extractPhysSources(data: InstructionStateArray) return PhysNameArray;

function extractPhysS0(data: InstructionStateArray) return PhysNameArray;
function extractPhysS1(data: InstructionStateArray) return PhysNameArray;
function extractPhysS2(data: InstructionStateArray) return PhysNameArray;

function extractMissing(data: InstructionStateArray) return std_logic_vector;		

function extractMissing0(data: InstructionStateArray) return std_logic_vector;		
function extractMissing1(data: InstructionStateArray) return std_logic_vector;		
function extractMissing2(data: InstructionStateArray) return std_logic_vector;		
				
-- Get inputs form registers and immediate value
function getIssueArgValues(pa: InstructionPhysicalArgs; ca: InstructionConstantArgs;
									ready: std_logic_vector; vals: MwordArray)
return InstructionArgValues;

-- get args still missing (used while waiting for issue, possibly in the cycle when going to Exec)
function updateArgValues(av: InstructionArgValues; --pa: InstructionPhysicalArgs;
								ready: std_logic_vector;
								vals: MwordArray) 
return InstructionArgValues; 

function updateInstructionArgValues2(ins: InstructionState; ai: ArgStatusInfo) 
return InstructionState;

function getForwardingStatusInfoD(av: in InstructionArgValues; pa: in InstructionPhysicalArgs; 
										 content: in MwordArray;--fn: ForwardingNetwork
										tags, nextTags: in PhysNameArray; nResultTags: integer) return ArgStatusInfo;

function getArgInfoArrayD(data: InstructionStateArray; vals: MwordArray; 
										resultTags, nextTags: PhysNameArray; nResultTags: integer)	
return ArgStatusInfoArray;	


function getForwardingStatusInfoD2(av: in InstructionArgValues; pa: in InstructionPhysicalArgs; 
										content0, content1, content2: in MwordArray;--fn: ForwardingNetwork
										tags0, tags1, tags2, 
										nextTags: in PhysNameArray; nResultTags: integer) return ArgStatusInfo;

function getArgInfoArrayD2(data: InstructionStateArray; 
										content0, content1, content2: in MwordArray;--fn: ForwardingNetwork
										tags0, tags1, tags2, 
										nextTags: PhysNameArray; nResultTags: integer)
return ArgStatusInfoArray;

	
-- True if all args are ready
function readyForExec(ins: InstructionState) return std_logic;

function getArgStatus(ai: ArgStatusInfo;
							 --missing, uMissing: std_logic_vector(0 to 2);								 
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


function iqContentNext2(queueData: InstructionStateArray; dataNew: StageDataMulti; 
								 fullMask, readyMask: std_logic_vector;
								 nextAccepting: std_logic;
								 living, sending, prevSending: integer;
								 prevSendingOK: std_logic)
return InstructionSlotArray;

function iqExtractFullMask(queueContent: InstructionSlotArray) return std_logic_vector;

function iqExtractData(queueContent: InstructionSlotArray) return InstructionStateArray;

	
end ProcLogicIQ;



package body ProcLogicIQ is
	
function extractPhysSources(data: InstructionStateArray) return PhysNameArray is
	variable res: PhysNameArray(0 to 3*data'length-1) := (others => (others => '0'));
begin
	for i in data'range loop
		res(3*i + 0) := data(i).physicalArgs.s0;
		res(3*i + 1) := data(i).physicalArgs.s1;
		res(3*i + 2) := data(i).physicalArgs.s2;		
	end loop;
	return res;
end function;	
	
function extractPhysS0(data: InstructionStateArray) return PhysNameArray is
	variable res: PhysNameArray(0 to data'length-1) := (others => (others => '0'));
begin
	for i in data'range loop
		res(i) := data(i).physicalArgs.s0;		
	end loop;
	return res;
end function;		

function extractPhysS1(data: InstructionStateArray) return PhysNameArray is
	variable res: PhysNameArray(0 to data'length-1) := (others => (others => '0'));
begin
	for i in data'range loop
		res(i) := data(i).physicalArgs.s1;		
	end loop;
	return res;
end function;		

function extractPhysS2(data: InstructionStateArray) return PhysNameArray is
	variable res: PhysNameArray(0 to data'length-1) := (others => (others => '0'));
begin
	for i in data'range loop
		res(i) := data(i).physicalArgs.s2;		
	end loop;
	return res;
end function;		


	
function extractMissing(data: InstructionStateArray) return std_logic_vector is
	variable res: std_logic_vector(0 to 3*data'length-1) := (others => '0');
begin
	for i in data'range loop
		res(3*i + 0) := data(i).argValues.missing(0);
		res(3*i + 1) := data(i).argValues.missing(1);
		res(3*i + 2) := data(i).argValues.missing(2);		
	end loop;
	return res;
end function;	

function extractMissing0(data: InstructionStateArray) return std_logic_vector is
	variable res: std_logic_vector(0 to data'length-1) := (others => '0');
begin
	for i in data'range loop
		res(i) := data(i).argValues.missing(0);
	end loop;
	return res;
end function;

function extractMissing1(data: InstructionStateArray) return std_logic_vector is
	variable res: std_logic_vector(0 to data'length-1) := (others => '0');
begin
	for i in data'range loop
		res(i) := data(i).argValues.missing(1);
	end loop;
	return res;
end function;
	
function extractMissing2(data: InstructionStateArray) return std_logic_vector is
	variable res: std_logic_vector(0 to data'length-1) := (others => '0');
begin
	for i in data'range loop
		res(i) := data(i).argValues.missing(2);
	end loop;
	return res;
end function;


	
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
function updateArgValues(av: InstructionArgValues; -- pa: InstructionPhysicalArgs;
									ready: std_logic_vector; vals: MwordArray) 
return InstructionArgValues is
	variable res: InstructionArgValues := av;
begin
	if (res.missing(0) and ready(0)) = '1' then
		res.missing(0) := '0';
		res.arg0 := vals(0);
	end if;
		--return res;
	if (res.missing(1) and ready(1)) = '1' then
		res.missing(1) := '0';
		res.arg1 := vals(1);
	end if;
		--		return res;
	if (res.missing(2) and ready(2)) = '1' then
		res.missing(2) := '0';
		res.arg2 := vals(2);
	end if;
	
	return res;
end function;	

										
function updateInstructionArgValues2(ins: InstructionState; ai: ArgStatusInfo) 
return InstructionState is
	variable res: InstructionState := ins;
begin
	if (ins.argValues.missing(0) and ai.ready(0)) = '1' then
		res.argValues.missing(0) := '0';
		res.argValues.arg0 := ai.vals(0);
	end if;		
		--return res;
	if (ins.argValues.missing(1) and ai.ready(1)) = '1' then
		res.argValues.missing(1) := '0';
		res.argValues.arg1 := ai.vals(1);
	end if;
		--		return res;
	if (ins.argValues.missing(2) and ai.ready(2)) = '1' then
		res.argValues.missing(2) := '0';
		res.argValues.arg2 := ai.vals(2);
	end if;
	
	return res;
end function;


function getForwardingStatusInfoD(av: in InstructionArgValues; pa: in InstructionPhysicalArgs; 
										 content: in MwordArray;--fn: ForwardingNetwork
										tags, nextTags: in PhysNameArray; nResultTags: integer) return ArgStatusInfo
is		
	variable stored, ready, nextReady: std_logic_vector(0 to 2) := (others=>'0');
	variable locs, nextLocs: SmallNumberArray(0 to 2) := (others=>(others=>'0'));
	variable vals: MwordArray(0 to 2) := (others=>(others=>'0'));
	variable res: ArgStatusInfo;
begin
	stored := not av.missing;	
	
	-- Find where tag agrees with s0
	for i in --tags'range loop -- CAREFUL! Is this loop optimal for muxing?
				--0 to nResultTags-1 loop
				nResultTags-1 downto 0 loop
			-- CAREFUL! showing only nonzero tags (p0 never needs lookup)
--			if isNonzero(tags(i)) = '0' then
--				next;
--			end if;		
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
--			if isNonzero(nextTags(i)) = '0' then
--				next;
--			end if;		
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
	res.ready := ready;
	res.locs := locs;
	res.vals := vals;
	res.nextReady := nextReady;
	res.nextLocs := nextLocs;
	
	return res;								
end function;


function getArgInfoArrayD(data: InstructionStateArray; vals: MwordArray; 
										resultTags, nextTags: PhysNameArray; nResultTags: integer)
return ArgStatusInfoArray is
	variable res: ArgStatusInfoArray(data'range);
begin
	for i in res'range loop
		res(i) := getForwardingStatusInfoD(data(i).argValues, data(i).physicalArgs, vals, 
					resultTags, nextTags, nResultTags);
	end loop;
	
	return res;
end function;


function getForwardingStatusInfoD2(av: in InstructionArgValues; pa: in InstructionPhysicalArgs; 
										content0, content1, content2: in MwordArray;--fn: ForwardingNetwork
										tags0, tags1, tags2, 
										nextTags: in PhysNameArray; nResultTags: integer) return ArgStatusInfo
is		
	variable stored, ready, nextReady: std_logic_vector(0 to 2) := (others=>'0');
	variable locs, nextLocs: SmallNumberArray(0 to 2) := (others=>(others=>'0'));
	variable vals: MwordArray(0 to 2) := (others=>(others=>'0'));
	variable res: ArgStatusInfo;
begin
	stored := not av.missing;	
	
	-- Find where tag agrees with s0
	for i in tags0'length-1 downto 0 loop		
		if tags0(i) = pa.s0 then
			ready(0) := '1';
			locs(0) := i2slv(i, SMALL_NUMBER_SIZE);
			vals(0) := content0(i);
		end if;
	end loop;
		
	for i in tags1'length-1 downto 0 loop				
		if tags1(i) = pa.s1 then
			ready(1) := '1';
			locs(1) := i2slv(i, SMALL_NUMBER_SIZE);
			vals(1) := content1(i);
		end if;
	end loop;		
		
	for i in tags2'length-1 downto 0 loop				
		if tags2(i) = pa.s2 then
			ready(2) := '1';
			locs(2) := i2slv(i, SMALL_NUMBER_SIZE);
			vals(2) := content2(i);
		end if;
	end loop;
	
	for i in nextTags'range loop
			-- CAREFUL
--			if isNonzero(nextTags(i)) = '0' then
--				next;
--			end if;		
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
	res.ready := ready;
	res.locs := locs;
	res.vals := vals;
	res.nextReady := nextReady;
	res.nextLocs := nextLocs;
	
	return res;								
end function;

function getArgInfoArrayD2(data: InstructionStateArray; 
										content0, content1, content2: in MwordArray;--fn: ForwardingNetwork
										tags0, tags1, tags2, 
										nextTags: PhysNameArray; nResultTags: integer)
return ArgStatusInfoArray is
	variable res: ArgStatusInfoArray(data'range);
begin
	for i in res'range loop
		res(i) := getForwardingStatusInfoD2(data(i).argValues, data(i).physicalArgs,
														content0, content1, content2, 
														tags0, tags1, tags2,
														nextTags, nResultTags);
	end loop;
	
	return res;
end function;



function getArgStatus(ai: ArgStatusInfo;
							 --missing, uMissing: std_logic_vector(0 to 2);
							 living: std_logic;
							 readyRegs: std_logic_vector)
return ArgStatusStruct is
	variable res: ArgStatusStruct;
begin
	res.ready := ai.ready;
	res.locs := ai.locs;
	res.vals := ai.vals;
	res.readyNext := ai.nextReady;
	
	res.missing := not ai.stored;

	res.readyReg := readyRegs;
	res.readyNow := res.ready;
	
	-- NOTE: 'stillMissing' will be 'missing and not readyNow (??and not readyRegs??)'
	res.stillMissing := res.missing and not res.readyNow;
			
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
		res(i) := getArgStatus(aiA(i), livingMask(i), readyRegs(3*i to 3*i + 2)); --,
	end loop;
	
	return res;
end function;	


function updateIQData(data: InstructionStateArray; aiArray: ArgStatusInfoArray)
return InstructionStateArray is
	variable res: InstructionStateArray(data'range);
begin
	for i in res'range loop
		res(i) := updateInstructionArgValues2(data(i), aiArray(i));
	end loop;

	return res;
end function;


function readyForExec(ins: InstructionState) return std_logic is
	variable res: std_logic;
begin
	if --ins.argValues.missing = "000" then
		isNonzero(ins.argValues.missing) = '0' then
		res := '1';
	else
		res := '0';
	end if;	
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


function iqContentNext2(queueData: InstructionStateArray; dataNew: StageDataMulti; 
								 fullMask, readyMask: std_logic_vector;
								 nextAccepting: std_logic;
								 living, sending, prevSending: integer;
								 prevSendingOK: std_logic)
return InstructionSlotArray is
	variable res: InstructionSlotArray(-1 to queueData'right) := (others => DEFAULT_INSTRUCTION_SLOT); 
	-- CAREFUL! Not including the negative index
	constant QUEUE_SIZE: natural := queueData'right + 1;
	variable i, j: integer;	
	
	variable iqDataNext: InstructionStateArray(0 to QUEUE_SIZE - 1) -- + PIPE_WIDTH)
					:= (others => defaultInstructionState);
	variable iqFullMaskNext: std_logic_vector(0 to QUEUE_SIZE - 1) :=	(others => '0');
	variable dispatchDataNew: InstructionState := defaultInstructionState;
	variable sends, anyReady: std_logic := '0';
		constant CLEAR_EMPTY_SLOTS_IQ: boolean := true;
		
		variable xVec: InstructionStateArray(0 to QUEUE_SIZE + PIPE_WIDTH - 1);
		variable yVec: InstructionStateArray(0 to 3*PIPE_WIDTH-1);
		variable yMask: std_logic_vector(0 to 3*PIPE_WIDTH-1) := (others => '0');
		variable x,y: integer := 0; 
		variable tempMask: std_logic_vector(0 to QUEUE_SIZE-1) := (others => '0');
		variable nAfterSending: integer := living;
			variable shiftNum: integer := 0;
begin
--	if not CLEAR_EMPTY_SLOTS_IQ then
--		iqDataNext := queueData;
--	end if;
	if nAfterSending < 0 then
	--	nAfterSending := 0;
	end if;	

		xVec := queueData & dataNew.data; -- CAREFUL: What to append after queueData?
					xVec(QUEUE_SIZE) := xVec(QUEUE_SIZE-1);
		yVec := dataNew.data & dataNew.data & dataNew.data;	
		yMask := dataNew.fullMask & dataNew.fullMask & dataNew.fullMask; 
		
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
		--report "A";
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



function iqExtractFullMask(queueContent: InstructionSlotArray) return std_logic_vector is
	variable res: std_logic_vector(0 to queueContent'length-1) := (others => '0');
begin
	for i in res'range loop
		res(i) := queueContent(i).full;
	end loop;
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
