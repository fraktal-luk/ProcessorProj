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


package ProcLogicRouting is

-- Gives queue number based on functional unit
function unit2queue(unit: ExecUnit) return integer;

function getSrcVecA(sd: StagedataMulti) return std_logic_vector; 
function getSrcVecB(sd: StagedataMulti) return std_logic_vector;
function getSrcVecC(sd: StagedataMulti) return std_logic_vector;
function getSrcVecD(sd: StagedataMulti) return std_logic_vector;
function getLoadVec(sd: StagedataMulti) return std_logic_vector;
function getStoreVec(sd: StagedataMulti) return std_logic_vector;

function routeToIQ(sd: StageDataMulti; srcVec: std_logic_vector) return StageDataMulti;	

function findForALU(iv: InstructionStateArray) return std_logic_vector;

function findStores(insv: StageDataMulti) return std_logic_vector;
function findLoads(insv: StageDataMulti) return std_logic_vector;

function prepareForAGU(insVec: StageDataMulti) return StageDataMulti;

function prepareSSAForAGU(sa: SchedulerEntrySlotArray) return SchedulerEntrySlotArray;

function prepareForStoreData(insVec: StageDataMulti) return StageDataMulti;

function prepareForStoreSSA(sa: SchedulerEntrySlotArray) return SchedulerEntrySlotArray;

	function getSchedData(insArr: InstructionStateArray; fullMask: std_logic_vector) return SchedulerEntrySlotArray;

end ProcLogicRouting;



package body ProcLogicRouting is

function unit2queue(unit: ExecUnit) return integer is
begin
	case unit is
		when General => return -1; -- Should never happen!
		when ALU => return 0;
		when MAC => return 1;
		when Divide => return 0;
		when Jump => return 3;
		when Memory => return 2;
		when System => return 3 + 1;
		when others => return -1;
	end case;
end function;

function getSrcVecA(sd: StagedataMulti) return std_logic_vector is
	variable res: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
begin
	for i in 0 to PIPE_WIDTH-1 loop
		res(i) := sd.data(i).classInfo.pipeA and sd.fullMask(i);
	end loop;
	return res;
end function; 

function getSrcVecB(sd: StagedataMulti) return std_logic_vector is
	variable res: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
begin
	for i in 0 to PIPE_WIDTH-1 loop
		res(i) := sd.data(i).classInfo.pipeB and sd.fullMask(i);
	end loop;
	return res;
end function; 

function getSrcVecC(sd: StagedataMulti) return std_logic_vector is
	variable res: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
begin
	for i in 0 to PIPE_WIDTH-1 loop
		res(i) := sd.data(i).classInfo.pipeC and sd.fullMask(i);
	end loop;
	return res;
end function; 

function getSrcVecD(sd: StagedataMulti) return std_logic_vector is
	variable res: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
begin
	for i in 0 to PIPE_WIDTH-1 loop
		res(i) := sd.data(i).classInfo.branchIns and sd.fullMask(i);
	end loop;
	return res;
end function;

function getLoadVec(sd: StagedataMulti) return std_logic_vector is
	variable res: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
begin
	for i in 0 to PIPE_WIDTH-1 loop
		res(i) := sd.data(i).classInfo.load and sd.fullMask(i);
	end loop;
	return res;
end function;

function getStoreVec(sd: StagedataMulti) return std_logic_vector is
	variable res: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
begin
	for i in 0 to PIPE_WIDTH-1 loop
		res(i) := sd.data(i).classInfo.store and sd.fullMask(i);
	end loop;
	return res;
end function; 


function routeToIQ(sd: StageDataMulti; srcVec: std_logic_vector) return StageDataMulti is
	variable res: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	variable k: natural := 0;
		constant CLEAR_EMPTY_SLOTS_IQ_ROUTING: boolean := false;
begin
	return squeezeSD(sd, srcVec);
end function;


function findForALU(iv: InstructionStateArray) return std_logic_vector is
	constant LEN: integer := iv'length;
	variable res: std_logic_vector(0 to LEN-1) := (others => '0'); 
begin
	for i in 0 to LEN-1 loop
		if iv(i).operation.unit = ALU then
			res(i) := '1';
		end if;
	end loop;
	return res;
end function;

function findStores(insv: StageDataMulti) return std_logic_vector is
	variable res: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
begin
	for i in 0 to PIPE_WIDTH-1 loop
		if 	insv.data(i).operation = (Memory, store) 
			or	insv.data(i).operation = (System, sysMTC)
		then
			res(i) := '1';
		end if;
	end loop;
	return res;
end function;

function findLoads(insv: StageDataMulti) return std_logic_vector is
	variable res: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
begin
	for i in 0 to PIPE_WIDTH-1 loop
		if 	insv.data(i).operation = (Memory, load)
			or	insv.data(i).operation = (System, sysMFC)
		then
			res(i) := '1';
		end if;
	end loop;
	return res;
end function;


function prepareForAGU(insVec: StageDataMulti) return StageDataMulti is
	variable res: StageDataMulti := insVec;
begin
	for i in 0 to PIPE_WIDTH-1 loop
		--res.data(i).argValues.missing(2) := '0';
			--res.data(i).virtualArgSpec.intArgSel(2) := '0'; -- CAREFUL
			--res.data(i).virtualArgSpec.floatArgSel(2) := '0'; -- CAREFUL
			--res.data(i).physicalArgSpec.intArgSel(2) := '0'; -- CAREFUL
			--res.data(i).physicalArgSpec.floatArgSel(2) := '0'; -- CAREFUL
		
		res.data(i).virtualArgSpec.intArgSel(2) := '0';
		res.data(i).physicalArgSpec.intArgSel(2) := '0';
		
		res.data(i).controlInfo.completed := '0';
		res.data(i).controlInfo.completed2 := '0';
	end loop;
	return res;
end function;

function prepareSSAForAGU(sa: SchedulerEntrySlotArray) return SchedulerEntrySlotArray is
	variable res: SchedulerEntrySlotArray(0 to sa'length-1) := sa;
begin
	for i in 0 to PIPE_WIDTH-1 loop
		--res.data(i).argValues.missing(2) := '0';
			--res.data(i).virtualArgSpec.intArgSel(2) := '0'; -- CAREFUL
			--res.data(i).virtualArgSpec.floatArgSel(2) := '0'; -- CAREFUL
			--res.data(i).physicalArgSpec.intArgSel(2) := '0'; -- CAREFUL
			--res.data(i).physicalArgSpec.floatArgSel(2) := '0'; -- CAREFUL
		
		res(i).ins.virtualArgSpec.intArgSel(2) := '0';
		res(i).ins.physicalArgSpec.intArgSel(2) := '0';
		
		res(i).ins.controlInfo.completed := '0';
		res(i).ins.controlInfo.completed2 := '0';
	end loop;
	return res;
end function;


function prepareForStoreData(insVec: StageDataMulti) return StageDataMulti is
	variable res: StageDataMulti := insVec;
begin
	for i in 0 to PIPE_WIDTH-1 loop	
		res.data(i).constantArgs.immSel := '0';

		res.data(i).virtualArgSpec.intArgSel(0) := '0';
		res.data(i).virtualArgSpec.intArgSel(1) := '0';
		res.data(i).virtualArgSpec.intDestSel := '0';			

		res.data(i).physicalArgSpec.intArgSel(0) := '0';
		res.data(i).physicalArgSpec.intArgSel(1) := '0';
		res.data(i).physicalArgSpec.intDestSel := '0';
		
		res.data(i).controlInfo.completed := '0';
		res.data(i).controlInfo.completed2 := '0';
	end loop;
	return res;
end function;


function prepareForStoreSSA(sa: SchedulerEntrySlotArray) return SchedulerEntrySlotArray is
	variable res: SchedulerEntrySlotArray(0 to sa'length-1) := sa;--(others => DEFAULT_SCH_ENTRY_SLOT);
begin
	for i in 0 to PIPE_WIDTH-1 loop	
		res(i).ins.constantArgs.immSel := '0';
		
			res(i).ins.virtualArgSpec.args(0) := res(i).ins.virtualArgSpec.args(2);
			res(i).ins.virtualArgSpec.args(2) := (others => '0');

			res(i).ins.physicalArgSpec.args(0) := res(i).ins.physicalArgSpec.args(2);
			res(i).ins.physicalArgSpec.args(2) := (others => '0');
			
		res(i).ins.virtualArgSpec.intArgSel(0) := res(i).ins.virtualArgSpec.intArgSel(2);
		res(i).ins.virtualArgSpec.intArgSel(1) := '0';
		res(i).ins.virtualArgSpec.intArgSel(2) := '0';		
		res(i).ins.virtualArgSpec.intDestSel := '0';			

		res(i).ins.physicalArgSpec.intArgSel(0) := res(i).ins.physicalArgSpec.intArgSel(2);
		res(i).ins.physicalArgSpec.intArgSel(1) := '0';
		res(i).ins.physicalArgSpec.intArgSel(2) := '0';
		res(i).ins.physicalArgSpec.intDestSel := '0';
		
		res(i).ins.controlInfo.completed := '0';
		res(i).ins.controlInfo.completed2 := '0';
	end loop;
	return res;
end function;


	function getSchedData(insArr: InstructionStateArray; fullMask: std_logic_vector) return SchedulerEntrySlotArray is
		variable res: SchedulerEntrySlotArray(0 to PIPE_WIDTH-1) := (others => DEFAULT_SCH_ENTRY_SLOT);
	begin
		for i in 0 to PIPE_WIDTH-1 loop
			res(i).ins := insArr(i);
			res(i).full := fullMask(i);

			-- Set state markers: "zero" bit
			res(i).state.argValues.zero(0) := not isNonzero(res(i).ins.virtualArgSpec.args(0)(4 downto 0));
			res(i).state.argValues.zero(1) := not isNonzero(res(i).ins.virtualArgSpec.args(1)(4 downto 0));
			res(i).state.argValues.zero(2) := not isNonzero(res(i).ins.virtualArgSpec.args(2)(4 downto 0));

			-- Set 'missing' flags for non-const arguments
			res(i).state.argValues.missing := res(i).ins.physicalArgSpec.intArgSel and not res(i).state.argValues.zero;
			
			-- Handle possible immediate arg
			if res(i).ins.constantArgs.immSel = '1' then
				res(i).state.argValues.missing(1) := '0';
				res(i).state.argValues.immediate := '1';
				res(i).state.argValues.zero(1) := '0';
			end if;

			res(i).ins.ip := (others => '0');			
			res(i).ins.target := (others => '0');
			res(i).ins.result := (others => '0');
			res(i).ins.bits := (others => '0');

		end loop;
		return res;
	end function;


end ProcLogicRouting;
