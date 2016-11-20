
library IEEE;
use IEEE.STD_LOGIC_1164.all;

use work.ProcBasicDefs.all;
use work.Helpers.all;

use work.ProcInstructionsNew.all;
use work.NewPipelineData.all;

use work.TEMP_DEV.all;
use work.GeneralPipeDev.all;


package SimLogicIQ is


function updateForWaitingSim(ins: InstructionState;
									readyRegFlags: std_logic_vector;
									ai: ArgStatusInfo;
									isNew: std_logic)
									return InstructionState;

function updateForWaitingArraySim(insArray: InstructionStateArray;
									readyRegFlags: std_logic_vector;
									aia: ArgStatusInfoArray;
									isNew: std_logic)
									return InstructionStateArray;


function updateForSelectionArraySim(insArray: InstructionStateArray;
									readyRegFlags: std_logic_vector;
									aia: ArgStatusInfoArray)
									return InstructionStateArray;

function updateForSelectionSim(ins: InstructionState;
									readyRegFlags: std_logic_vector;
									ai: ArgStatusInfo)
									return InstructionState;

end SimLogicIQ;



package body SimLogicIQ is


function updateForWaitingSim(ins: InstructionState;
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


function updateForWaitingArraySim(insArray: InstructionStateArray;
									readyRegFlags: std_logic_vector;
									aia: ArgStatusInfoArray;
									isNew: std_logic)
									return InstructionStateArray is
	variable res: InstructionStateArray(0 to insArray'length-1) := insArray;
begin
	for i in insArray'range loop			
		res(i) := updateForWaitingSim(insArray(i), readyRegFlags, aia(i), isNew);
	end loop;
	return res;
end function;



function updateForSelectionSim(ins: InstructionState;
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

			res.argValues.hist0(1) := '-';
			res.argValues.hist0(2) := '-';
			res.argValues.hist0(3) := '-';
			
	-- For 'nextReady'
	if ai.nextReady(0) = '1' then
		res.argValues.missing(0) := '0';
		res.argValues.readyNext(0) := '1';
			res.argValues.hist0(1) := 'N';		
	end if;		

	if ai.nextReady(1) = '1' then
		res.argValues.missing(1) := '0';
		res.argValues.readyNext(1) := '1';
			res.argValues.hist1(1) := 'N';		
	end if;

	if ai.nextReady(2) = '1' then
		res.argValues.missing(2) := '0';
		res.argValues.readyNext(2) := '1';
			res.argValues.hist2(1) := 'N';		
	end if;

	-- For 'ready'
	if ai.ready(0) = '1' then
		--res.argValues.missing(0) := '0'; -- NOTE: it would increase delay, unneeded with full 'nextReady'
		res.argValues.readyNow(0) := '1';
		res.argValues.arg0 := ai.vals(0);
			res.argValues.hist0(1) := 'u';		
	end if;		

	if ai.ready(1) = '1' then
		--res.argValues.missing(1) := '0';
		res.argValues.readyNow(1) := '1';
		res.argValues.arg1 := ai.vals(1);
			res.argValues.hist1(1) := 'u';		
	end if;

	if ai.ready(2) = '1' then
		--res.argValues.missing(2) := '0';
		res.argValues.readyNow(2) := '1';
		res.argValues.arg2 := ai.vals(2);			
			res.argValues.hist2(1) := 'u';		
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

function updateForSelectionArraySim(insArray: InstructionStateArray;
									readyRegFlags: std_logic_vector;
									aia: ArgStatusInfoArray)
									return InstructionStateArray is
	variable res: InstructionStateArray(0 to insArray'length-1) := insArray;
begin
	for i in insArray'range loop
		res(i) := updateForSelectionSim(insArray(i), readyRegFlags, aia(i));
	end loop;	
	return res;
end function;


end SimLogicIQ;
