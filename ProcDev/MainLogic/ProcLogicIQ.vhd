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

function getDispatchArgValues(ins: InstructionState; st: SchedulerState;
											resultTags: PhysNameArray; vals: MwordArray; USE_IMM: boolean)
return SchedulerEntrySlot;

function updateDispatchArgs(ins: InstructionState; st: SchedulerState; vals: MwordArray; regValues: MwordArray)
return SchedulerEntrySlot;



function iqContentNext(queueContent: SchedulerEntrySlotArray; inputDataS: SchedulerEntrySlotArray;
								 stayMask, fullMask, livingMask
								 : std_logic_vector;
								 sendPossible, sends: std_logic;
								 nextAccepting: std_logic;
								 living, sending, prevSending: integer;
								 prevSendingOK: std_logic)
return SchedulerEntrySlotArray;

function extractReadyMaskNew(entryVec: SchedulerEntrySlotArray) return std_logic_vector;



function updateForWaitingFNI(ins: InstructionState; st: SchedulerState;
										readyRegFlags: std_logic_vector; fni: ForwardingInfo)--;
									--isNew: std_logic)
return SchedulerEntrySlot;

function updateForWaitingNewFNI(ins: InstructionState; st: SchedulerState;
										readyRegFlags: std_logic_vector; fni: ForwardingInfo)--;
									--isNew: std_logic)
return SchedulerEntrySlot;

function updateForSelectionFNI(ins: InstructionState; st: SchedulerState;
											readyRegFlags: std_logic_vector; fni: ForwardingInfo)
return SchedulerEntrySlot;


function updateForWaitingArrayFNI(insArray: SchedulerEntrySlotArray; readyRegFlags: std_logic_vector;
									fni: ForwardingInfo)--; isNew: std_logic)
return SchedulerEntrySlotArray;

function updateForWaitingArrayNewFNI(insArray: SchedulerEntrySlotArray; readyRegFlags: std_logic_vector;
									fni: ForwardingInfo)--; isNew: std_logic)
return SchedulerEntrySlotArray;


function updateForSelectionArrayFNI(insArray: SchedulerEntrySlotArray; readyRegFlags: std_logic_vector;
									fni: ForwardingInfo)
return SchedulerEntrySlotArray;

end ProcLogicIQ;



package body ProcLogicIQ is


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



function getDispatchArgValues(ins: InstructionState; st: SchedulerState;
											resultTags: PhysNameArray; vals: MwordArray; USE_IMM: boolean)
return SchedulerEntrySlot is
	variable res: SchedulerEntrySlot := DEFAULT_SCH_ENTRY_SLOT;
	variable v0, v1: std_logic_vector(1 downto 0) := "00";
	variable selected0, selected1: Mword := (others => '0');
	variable ready: std_logic_vector(0 to 2) := (others=>'0');
	variable locs: SmallNumberArray(0 to 2) := (others=>(others=>'0'));
begin
	res.ins := ins;
	res.state := st;


	for i in resultTags'length-1 downto 0 loop		
		if resultTags(i)(PHYS_REG_BITS-1 downto 0) = ins.physicalArgSpec.args(0)(PHYS_REG_BITS-1 downto 0) then
			ready(0) := '1';
			locs(0) := i2slv(i, SMALL_NUMBER_SIZE);
		end if;
	end loop;
		
	for i in resultTags'length-1 downto 0 loop				
		if resultTags(i)(PHYS_REG_BITS-1 downto 0) = ins.physicalArgSpec.args(1)(PHYS_REG_BITS-1 downto 0) then
			ready(1) := '1';
			locs(1) := i2slv(i, SMALL_NUMBER_SIZE);
		end if;
	end loop;		
		
--	for i in resultTags'length-1 downto 0 loop				
--		if resultTags(i)(PHYS_REG_BITS-1 downto 0) = ins.physicalArgSpec.args(2)(PHYS_REG_BITS-1 downto 0) then
--			ready(2) := '1';
--			locs(2) := i2slv(i, SMALL_NUMBER_SIZE);
--		end if;
--	end loop;

	res.state.argValues.readyNow := ready;
	res.state.argValues.locs := locs;


	res.state.argValues.arg0 := vals(slv2u(res.state.argValues.locs(0)));
	
	if res.state.argValues.immediate = '1' and USE_IMM then
		res.state.argValues.arg1 := res.ins.constantArgs.imm;
		res.state.argValues.arg1(31 downto 17) := (others => res.ins.constantArgs.imm(16)); -- 16b + addditional sign bit
	else
		res.state.argValues.arg1 := vals(slv2u(res.state.argValues.locs(1)));
	end if;

	--res.state.argValues.arg2 := vals(slv2u(res.state.argValues.locs(2)));

	return res;
end function;


function updateDispatchArgs(ins: InstructionState; st: SchedulerState; vals: MwordArray; regValues: MwordArray)
return SchedulerEntrySlot is
	variable res: SchedulerEntrySlot := DEFAULT_SCH_ENTRY_SLOT;
	variable aa: MwordArray(0 to 5) := (others => (others => '0'));
	variable ind: integer := 0;
	variable selector: std_logic_vector(0 to 1) := "00";
	variable tbl: MwordArray(0 to 3) := (others => (others => '0'));
	variable carg0, carg1, carg2: Mword;
begin
	res.ins := ins;
	res.state := st;

-- readyNext && not zero -> next val, readyNow && not zero -> keep, else -> reg
	-- Clear 'missing' flag where readyNext indicates.
	res.state.argValues.missing := res.state.argValues.missing and not (res.state.argValues.readyNext and not res.state.argValues.zero);
	carg0 := selectUpdatedArg(res.state.argValues, 0, '0', res.state.argValues.arg0, vals, regValues);
	carg1 := selectUpdatedArg(res.state.argValues, 1, res.state.argValues.immediate, res.state.argValues.arg1, vals, regValues);	
	--carg2 := selectUpdatedArg(res.state.argValues, 2, '0', res.state.argValues.arg2, vals, regValues);
	res.state.argValues.arg0 := carg0;
	res.state.argValues.arg1 := carg1;
	--res.state.argValues.arg2 := carg2;
	
	return res;
end function;


function extractReadyMaskNew(entryVec: SchedulerEntrySlotArray) return std_logic_vector is
	variable res: std_logic_vector(entryVec'range);
begin	
	for i in res'range loop
		res(i) := not isNonzero(entryVec(i).state.argValues.missing(0 to 1));
	end loop;
	return res;
end function;


function iqContentNext(queueContent: SchedulerEntrySlotArray; inputDataS: SchedulerEntrySlotArray;
								 stayMask, fullMask, livingMask
								 : std_logic_vector;
								 sendPossible, sends: std_logic;
								 nextAccepting: std_logic;
								 living, sending, prevSending: integer;
								 prevSendingOK: std_logic)
return SchedulerEntrySlotArray is
	constant QUEUE_SIZE: natural := queueContent'length;
	variable res: SchedulerEntrySlotArray(0 to QUEUE_SIZE-1) := (others => DEFAULT_SCH_ENTRY_SLOT); 	
	variable queueDataS: SchedulerEntrySlotArray(0 to QUEUE_SIZE-1) := queueContent;
	--variable dataNew: StageDataMulti := inputData;
	variable newMask: std_logic_vector(0 to PIPE_WIDTH-1) := extractFullMask(inputDataS);--inputData.fullMask;--
	variable dataNewDataS: SchedulerEntrySlotArray(0 to PIPE_WIDTH-1) := inputDataS;
	
	variable iqDataNextS: SchedulerEntrySlotArray(0 to QUEUE_SIZE - 1) := (others => DEFAULT_SCH_ENTRY_SLOT);
	variable iqFullMaskNext: std_logic_vector(0 to QUEUE_SIZE - 1) :=	(others => '0');

	variable xVecS: SchedulerEntrySlotArray(0 to QUEUE_SIZE + PIPE_WIDTH - 1);
	variable yVecS: SchedulerEntrySlotArray(0 to QUEUE_SIZE + PIPE_WIDTH - 1);
	variable yMask: std_logic_vector(0 to QUEUE_SIZE + PIPE_WIDTH-1)	:= (others => '0');
	variable fullMaskSh: std_logic_vector(0 to QUEUE_SIZE-1) := fullMask;
	variable livingMaskSh: std_logic_vector(0 to QUEUE_SIZE-1) := livingMask;
	variable nAfterSending: integer := living;
	variable shiftNum: integer := 0;			
begin
	-- Important, new instrucitons in queue must be marked!	
	for i in 0 to PIPE_WIDTH-1 loop
		dataNewDataS(i).state.argValues.newInQueue := '1';
	end loop;

	xVecS := queueDataS & dataNewDataS;
	xVecS(QUEUE_SIZE) := xVecS(QUEUE_SIZE-1);
	for i in 0 to QUEUE_SIZE + PIPE_WIDTH - 1 loop
		xVecS(i).state.argValues.newInQueue := '0';
	end loop;
		
	for k in 0 to yVecS'right loop
		yVecS(k) := dataNewDataS(k mod PIPE_WIDTH);
	end loop;	

	for k in 0 to PIPE_WIDTH-1 loop
		yMask(k) := newMask(k); -- not wrapping mod k to enable simple copying to new fullMask
	end loop;

	if sends = '1' then
		nAfterSending := nAfterSending-1;
	end if;

	for i in 0 to QUEUE_SIZE-2 loop
		if livingMask(i) = '0' or (livingMask(i+1) = '0' and sends = '1') then
			livingMaskSh(i) := '0';
		else
			livingMaskSh(i) := '1';
		end if;
	end loop;
	
	if livingMask(QUEUE_SIZE-1) = '0' or sends = '1' then
		livingMaskSh(QUEUE_SIZE-1) := '0';
	else
		livingMaskSh(QUEUE_SIZE-1) := '1';
	end if;

	for i in 0 to QUEUE_SIZE-2 loop
		if fullMask(i) = '0' or (fullMask(i+1) = '0' and sendPossible = '1') then
			fullMaskSh(i) := '0';
		else
			fullMaskSh(i) := '1';
		end if;
	end loop;
	
	if fullMask(QUEUE_SIZE-1) = '0' or sendPossible = '1' then
		fullMaskSh(QUEUE_SIZE-1) := '0';
	else
		fullMaskSh(QUEUE_SIZE-1) := '1';
	end if;


--	if nAfterSending < 0 then
--		nAfterSending := 0;
--	elsif nAfterSending > yVecS'length then	
--		nAfterSending := yVecS'length;
--	end if;
--
--	shiftNum := nAfterSending;
	shiftNum := countOnes(fullMaskSh); -- CAREFUL: this seems to reduce some logic

	-- CAREFUL, TODO:	solve the issue with HDLCompiler:1827
	yVecS(shiftNum to yVecS'length - 1) := yVecS(0 to yVecS'length - 1 - shiftNum);
	yMask(shiftNum to yVecS'length - 1) := yMask(0 to yVecS'length - 1 - shiftNum);

	-- Now assign from x or y
	iqDataNextS := queueDataS;
	for i in 0 to QUEUE_SIZE-1 loop
		iqFullMaskNext(i) := livingMaskSh(i) or (yMask(i) and prevSendingOK);
		if --yMask(i) = '0' then -- 
			fullMaskSh(i) = '1' then -- From x	
			if stayMask(i) = '1' then
				iqDataNextS(i) := xVecS(i);
			else
				iqDataNextS(i) := xVecS(i + 1);
			end if;
		else -- From y
			iqDataNextS(i) := yVecS(i);
		end if;
	end loop;

	-- Fill output array
	for i in 0 to res'right loop
		res(i).full := iqFullMaskNext(i);
		res(i).ins := iqDataNextS(i).ins;
		res(i).state := iqDataNextS(i).state;
	end loop;

	return res;
end function;



function updateForWaitingFNI(ins: InstructionState; st: SchedulerState;
										readyRegFlags: std_logic_vector; fni: ForwardingInfo)--;
									--isNew: std_logic)
return SchedulerEntrySlot is
	variable res: SchedulerEntrySlot := DEFAULT_SCHEDULER_ENTRY_SLOT;
	variable tmp8: SmallNumber := (others => '0');
	variable rrf: std_logic_vector(0 to 2) := (others => '0');

	variable stored, ready, nextReady, readyM2, written: std_logic_vector(0 to 2) := (others=>'0');
	variable locs, nextLocs, locsM2: SmallNumberArray(0 to 2) := (others=>(others=>'0'));
begin
	res.ins := ins;	
	res.state := st;

	-- nextReady - fast wakeup   
	-- NOTE: we don't save nextLocs because only the ops that are instantly issued will use it, so no
	-- 		point to store them for those that'll keep waiting
	for i in 0 to 0 loop -- only [0] uses fast wakeup
		if fni.nextResultTags(i)(PHYS_REG_BITS-1 downto 0) = ins.physicalArgSpec.args(0)(PHYS_REG_BITS-1 downto 0) then
			nextReady(0) := '1';
		end if;		
		if fni.nextResultTags(i)(PHYS_REG_BITS-1 downto 0) = ins.physicalArgSpec.args(1)(PHYS_REG_BITS-1 downto 0) then
			nextReady(1) := '1';
		end if;		
	end loop;
	
	-- readyM2 - slow wakeup
	for i in 1 to 2 loop -- [0] does not use slow wakeup
		if fni.nextTagsM2(i)(PHYS_REG_BITS-1 downto 0) = ins.physicalArgSpec.args(0)(PHYS_REG_BITS-1 downto 0) then
			readyM2(0) := '1';
			locsM2(0) := i2slv(i, SMALL_NUMBER_SIZE);
		end if;
		if fni.nextTagsM2(i)(PHYS_REG_BITS-1 downto 0) = ins.physicalArgSpec.args(1)(PHYS_REG_BITS-1 downto 0) then
			readyM2(1) := '1';
			locsM2(1) := i2slv(i, SMALL_NUMBER_SIZE);
		end if;
	end loop;

	res.state.argValues.readyNext := nextReady;
	
	res.state.argValues.readyM2 := readyM2;
	res.state.argValues.locsM2 := locsM2;

	-- 
	if res.state.argValues.newInQueue = '1' then
		tmp8 := getTagLowSN(res.ins.tags.renameIndex);-- and i2slv(PIPE_WIDTH-1, SMALL_NUMBER_SIZE);
		rrf := readyRegFlags(3*slv2u(tmp8) to 3*slv2u(tmp8) + 2);
		res.state.argValues.missing := res.state.argValues.missing and not rrf;
	end if;

	res.state.argValues.missing := res.state.argValues.missing and not nextReady;	
	res.state.argValues.missing := res.state.argValues.missing and not readyM2;
	
	res.ins.ip := (others => '0');
	return res;
end function;


function updateForWaitingNewFNI(ins: InstructionState; st: SchedulerState;
										readyRegFlags: std_logic_vector; fni: ForwardingInfo)--;
									--isNew: std_logic)
return SchedulerEntrySlot is
	variable res: SchedulerEntrySlot := DEFAULT_SCHEDULER_ENTRY_SLOT;
	variable tmp8: SmallNumber := (others => '0');
	variable rrf: std_logic_vector(0 to 2) := (others => '0');

	variable stored, ready, nextReady, readyM2, written: std_logic_vector(0 to 2) := (others=>'0');
	variable locs, nextLocs, locsM2: SmallNumberArray(0 to 2) := (others=>(others=>'0'));
begin
	res.ins := ins;	
	res.state := st;

	-- Find where tag agrees with s0
	for i in fni.resultTags'length-1 downto 0 loop		
		if fni.resultTags(i)(PHYS_REG_BITS-1 downto 0) = ins.physicalArgSpec.args(0)(PHYS_REG_BITS-1 downto 0) then
			ready(0) := '1';
			locs(0) := i2slv(i, SMALL_NUMBER_SIZE);
		end if;
	end loop;
		
	for i in fni.resultTags'length-1 downto 0 loop				
		if fni.resultTags(i)(PHYS_REG_BITS-1 downto 0) = ins.physicalArgSpec.args(1)(PHYS_REG_BITS-1 downto 0) then
			ready(1) := '1';
			locs(1) := i2slv(i, SMALL_NUMBER_SIZE);
		end if;
	end loop;		
	
	for i in fni.nextResultTags'range loop
		if fni.nextResultTags(i)(PHYS_REG_BITS-1 downto 0) = ins.physicalArgSpec.args(0)(PHYS_REG_BITS-1 downto 0) then
			nextReady(0) := '1';
			nextLocs(0) := i2slv(i, SMALL_NUMBER_SIZE);
		end if;
		if fni.nextResultTags(i)(PHYS_REG_BITS-1 downto 0) = ins.physicalArgSpec.args(1)(PHYS_REG_BITS-1 downto 0) then
			nextReady(1) := '1';
			nextLocs(1) := i2slv(i, SMALL_NUMBER_SIZE);
		end if;		
	end loop;

	for i in 1 to 2 loop -- [0] does not use slow wakeup
		if fni.nextTagsM2(i)(PHYS_REG_BITS-1 downto 0) = ins.physicalArgSpec.args(0)(PHYS_REG_BITS-1 downto 0) then
			readyM2(0) := '1';
			locsM2(0) := i2slv(i, SMALL_NUMBER_SIZE);
		end if;
		if fni.nextTagsM2(i)(PHYS_REG_BITS-1 downto 0) = ins.physicalArgSpec.args(1)(PHYS_REG_BITS-1 downto 0) then
			readyM2(1) := '1';
			locsM2(1) := i2slv(i, SMALL_NUMBER_SIZE);
		end if;
	end loop;

	res.state.argValues.readyNow := (others => '0'); 
	res.state.argValues.readyNext := (others => '0');
	
	res.state.argValues.readyM2 := readyM2;
	res.state.argValues.locsM2 := locsM2;

	-- 
	if res.state.argValues.newInQueue = '1' then
		tmp8 := getTagLowSN(res.ins.tags.renameIndex);-- and i2slv(PIPE_WIDTH-1, SMALL_NUMBER_SIZE);
		rrf := readyRegFlags(3*slv2u(tmp8) to 3*slv2u(tmp8) + 2);
		--res.state.argValues.missing := res.state.argValues.missing and not rrf;
	end if;
	
	res.state.argValues.missing := res.state.argValues.missing and not ready;
	res.state.argValues.missing := res.state.argValues.missing and not nextReady;	
	res.state.argValues.missing := res.state.argValues.missing and not readyM2;
	
	res.ins.ip := (others => '0');
	return res;
end function;


function updateForSelectionFNI(ins: InstructionState; st: SchedulerState;
				readyRegFlags: std_logic_vector; fni: ForwardingInfo)
return SchedulerEntrySlot is
	variable res: SchedulerEntrySlot := DEFAULT_SCHEDULER_ENTRY_SLOT;
	variable tmp8: SmallNumber := (others => '0');
	variable rrf: std_logic_vector(0 to 2) := (others => '0');

	variable stored, ready, nextReady, written: std_logic_vector(0 to 2) := (others=>'0');
	variable locs, nextLocs: SmallNumberArray(0 to 2) := (others=>(others=>'0'));
begin
	res.ins := ins;
	res.state := st;
	
	nextLocs := st.argValues.locsM2; -- CAREFUL: a cycle has passed so those locs are now 1 cycle ahead
	nextReady := st.argValues.readyM2;
	
	-- Here we consider fast wakeup and readyRegTags
	for i in 0 to 0 loop --fni.nextResultTags'range loop
		if fni.nextResultTags(i)(PHYS_REG_BITS-1 downto 0) = ins.physicalArgSpec.args(0)(PHYS_REG_BITS-1 downto 0) then
			nextReady(0) := '1';
			nextLocs(0) := i2slv(i, SMALL_NUMBER_SIZE);
		end if;
		if fni.nextResultTags(i)(PHYS_REG_BITS-1 downto 0) = ins.physicalArgSpec.args(1)(PHYS_REG_BITS-1 downto 0) then
			nextReady(1) := '1';
			nextLocs(1) := i2slv(i, SMALL_NUMBER_SIZE);
		end if;		
	end loop;

	res.state.argValues.readyNow := (others => '0'); 
	res.state.argValues.readyNext := nextReady;--(others => '0');

	-- Checking reg ready flags (only for new ops in queue)
	-- CAREFUL! Which reg ready flags are for this instruction?
	--				Use groupTag, because it identifies the slot in previous superscalar stage
	if res.state.argValues.newInQueue = '1' then
		tmp8 := getTagLowSN(res.ins.tags.renameIndex);-- and i2slv(PIPE_WIDTH-1, SMALL_NUMBER_SIZE);
		rrf := readyRegFlags(3*slv2u(tmp8) to 3*slv2u(tmp8) + 2);
		res.state.argValues.missing := res.state.argValues.missing and not rrf;
	end if;
	
	res.state.argValues.missing := res.state.argValues.missing and not nextReady;
	
	res.state.argValues.locs := locs;	
	res.state.argValues.nextLocs := nextLocs;

	-- Clear unused fields
	res.ins.bits := (others => '0');
	res.ins.result := (others => '0');
	res.ins.target := (others => '0');		
--		
	res.ins.controlInfo.completed := '0';
	res.ins.controlInfo.completed2 := '0';
	res.ins.ip := (others => '0');

	res.ins.controlInfo.newEvent := '0';
	res.ins.controlInfo.hasInterrupt := '0';
	res.ins.controlInfo.hasReturn := '0';		
	res.ins.controlInfo.exceptionCode := (others => '0');

	return res;
end function;



function updateForWaitingArrayFNI(insArray: SchedulerEntrySlotArray; readyRegFlags: std_logic_vector;
									fni: ForwardingInfo)--; isNew: std_logic)
return SchedulerEntrySlotArray is
	variable res: SchedulerEntrySlotArray(0 to insArray'length-1);-- := insArray;
begin
	for i in insArray'range loop	
		res(i) := updateForWaitingFNI(insArray(i).ins, insArray(i).state, readyRegFlags, fni);
	end loop;
	return res;
end function;


function updateForWaitingArrayNewFNI(insArray: SchedulerEntrySlotArray; readyRegFlags: std_logic_vector;
									fni: ForwardingInfo)--; isNew: std_logic)
return SchedulerEntrySlotArray is
	variable res: SchedulerEntrySlotArray(0 to insArray'length-1);-- := insArray;
begin
	for i in insArray'range loop	
		res(i) := updateForWaitingNewFNI(insArray(i).ins, insArray(i).state, readyRegFlags, fni);
			res(i).full := (insArray(i).full);
	end loop;
	return res;
end function;



function updateForSelectionArrayFNI(insArray: SchedulerEntrySlotArray; readyRegFlags: std_logic_vector;
									fni: ForwardingInfo)
return SchedulerEntrySlotArray is
	variable res: SchedulerEntrySlotArray(0 to insArray'length-1);-- := insArray;
begin
	for i in insArray'range loop
		res(i) := updateForSelectionFNI(insArray(i).ins, insArray(i).state, readyRegFlags, fni);
	end loop;	
	return res;
end function;

end ProcLogicIQ;
