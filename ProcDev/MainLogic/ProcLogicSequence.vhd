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

use work.TEMP_DEV.all;
use work.GeneralPipeDev.all;


package ProcLogicSequence is

	function getNextPC(pc: Mword; jumpPC: Mword; jump: std_logic) return Mword;

		-- group:  revTag = causing.groupTag and i2slv(-PIPE_WIDTH, SMALL_NUMBER_SIZE), mask = all ones
		-- sequential: revTag = causing.numberTag, mask = new group's fullMask		
		function nextCtr(ctr: InsTag; rewind: std_logic; revTag: InsTag;
									 allow: std_logic; mask: std_logic_vector) 
		return InsTag;
		
		constant ALL_FULL: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '1');

function getLinkInfo(ins: InstructionState; state: Mword) return InstructionState;


function getLatePCData(commitEvent: std_logic; commitCausing: InstructionState;
								currentState, linkExc, linkInt, stateExc, stateInt: Mword)
return InstructionState;

function newPCData( commitEvent: std_logic; commitCausing: InstructionState;
						  execEvent: std_logic; execCausing: InstructionState;	
						  frontEvent: std_logic; frontCausing: InstructionState;
						  pcNext: Mword)
return InstructionState;

-- BACK ROUTING
-- Unifies content of ROB slot with BQ, others queues etc. to restore full state needed at Commit
function recreateGroup(insVec: StageDataMulti; bqGroup: StageDataMulti; prevTarget: Mword)
return StageDataMulti;


function isHalt(ins: InstructionState) return std_logic;

function setInterrupt3(targetIns: InstructionState; intSignal, start: std_logic) return InstructionState;

function clearControlEvents(ins: InstructionState) return InstructionState;

end ProcLogicSequence;



package body ProcLogicSequence is

	function getNextPC(pc: Mword; jumpPC: Mword; jump: std_logic) return Mword is
		variable res, pcBase: Mword := (others => '0'); 
	begin
		pcBase := pc and i2slv(-PIPE_WIDTH*4, MWORD_SIZE); -- Clearing low bits
		if jump = '1' then
			res := jumpPC;
		else
			res := addMwordBasic(pcBase, PC_INC);
		end if;
		return res;
	end function;
	
		-- group:  revTag = causing.groupTag and i2slv(-PIPE_WIDTH, SMALL_NUMBER_SIZE), mask = all ones
		-- sequential: revTag = causing.numberTag, mask = new group's fullMask		
		function nextCtr(ctr: InsTag; rewind: std_logic; revTag: InsTag;
									 allow: std_logic; mask: std_logic_vector) 
		return InsTag is
		begin
			if rewind = '1' then
				return revTag;
			elsif allow = '1' then
				return i2slv(slv2u(ctr) + countOnes(mask), TAG_SIZE);
			else
				return ctr;
			end if;
		end function;


function getLinkInfo(ins: InstructionState; state: Mword) return InstructionState is
	variable res: InstructionState := DEFAULT_INSTRUCTION_STATE;--ins.basicInfo;
begin
	res.ip := ins.target;
	--res.basicInfo.intLevel := state(7 downto 0);
	--res.basicInfo.systemLevel := state(15 downto 8);
		res.result := state;
	return res;
end function;



function getLatePCData(commitEvent: std_logic; commitCausing: InstructionState;
								currentState, linkExc, linkInt, stateExc, stateInt: Mword)
return InstructionState is
	variable res: InstructionState := DEFAULT_INSTRUCTION_STATE;-- content;
	variable newPC: Mword := (others=>'0');
begin	
		if commitCausing.controlInfo.hasInterrupt = '1' then
			if commitCausing.controlInfo.hasReset = '1' then
				res.ip := (others => '0'); -- TEMP!			
			else
				res.ip := INT_BASE; -- TEMP!
			end if;
				res.result := currentState or X"00000001";
				res.result := res.result and X"fdffffff"; -- Clear dbtrap
			--res.basicInfo.intLevel := "00000001";		
		elsif commitCausing.controlInfo.hasException = '1'
			or commitCausing.controlInfo.dbtrap = '1' then
			-- TODO, FIX: exceptionCode sliced - shift left by ALIGN_BITS? or leave just base address
			res.ip := EXC_BASE(MWORD_SIZE-1 downto commitCausing.controlInfo.exceptionCode'length)
									& commitCausing.controlInfo.exceptionCode(
													commitCausing.controlInfo.exceptionCode'length-1 downto ALIGN_BITS)
									& EXC_BASE(ALIGN_BITS-1 downto 0);	
									--		INT_BASE;
			-- TODO: if exception, it overrides dbtrap, but if only dbtrap, a specific vector address
				res.result := currentState or X"00000100";
				res.result := res.result and X"fdffffff";	-- Clear dbtrap
			--res.basicInfo.systemLevel := "00000001";
		elsif commitCausing.controlInfo.specialAction = '1' then
					res.result := currentState;
				if commitCausing.operation.func = sysSync then
					res.ip := commitCausing.target;
				elsif commitCausing.operation.func = sysReplay then
					res.ip := commitCausing.ip;
				elsif commitCausing.operation.func = sysHalt then
					res.ip := commitCausing.target; -- ???
				elsif commitCausing.operation.func = sysRetI then
						res.result := stateInt;
					res.ip := linkInt;
					--res.basicInfo.systemLevel := stateInt(15 downto 8);
					--res.basicInfo.intLevel := stateInt(7 downto 0);
				elsif commitCausing.operation.func = sysRetE then
						res.result := stateExc;
					res.ip := linkExc;
					--res.basicInfo.systemLevel := stateExc(15 downto 8);
					--res.basicInfo.intLevel := stateExc(7 downto 0); 
				end if;
		end if;		
	
	return res;
end function;


function newPCData( commitEvent: std_logic; commitCausing: InstructionState;
						  execEvent: std_logic; execCausing: InstructionState;	
						  frontEvent: std_logic; frontCausing: InstructionState;
						  pcNext: Mword)
return InstructionState is
	variable res: InstructionState := DEFAULT_INSTRUCTION_STATE;--content;
	variable newPC: Mword := (others=>'0');
begin
	if commitEvent = '1' then -- when from exec or front
		res.ip := commitCausing.target;
	elsif execEvent = '1' then		
		res.ip := execCausing.target;
	elsif frontEvent = '1' then
		--	report "front event!";
		res.ip := frontCausing.target;	
	else	-- Go to the next line
		res.ip := pcNext;
	end if;	

	return res;
end function;

-- Unifies content of ROB slot with BQ, others queues etc. to restore full state needed at Commit
function recreateGroup(insVec: StageDataMulti; bqGroup: StageDataMulti;
							  prevTarget: Mword--; tempValue: Mword; useTemp: std_logic
							  ) return StageDataMulti is
	variable res: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	variable targets: MwordArray(0 to PIPE_WIDTH-1) := (others => (others => '0'));
	variable ind: integer := 0;
	variable prevTrg: Mword := (others => '0');
begin
	res := insVec;
	
	prevTrg := prevTarget;
	
	for i in 0 to PIPE_WIDTH-1 loop
		targets(i) := prevTrg;--bqGroup.data(i).target; -- Default to some input, not zeros 
	end loop;
	
	-- Take branch targets to correct places
	for i in 0 to PIPE_WIDTH-1 loop
		if bqGroup.fullMask(i) = '1' then
			ind := slv2u(getTagLow(bqGroup.data(i).tags.renameIndex));
			targets(ind) := bqGroup.data(i).argValues.arg1;
		end if;
	end loop;

	for i in 0 to PIPE_WIDTH-1 loop
		if insVec.data(i).controlInfo.hasBranch = '1' then
			null;
		else
			targets(i) := addMwordBasic(prevTrg, getAddressIncrement(insVec.data(i)));
		end if;
		res.data(i).ip := prevTrg; -- ??
		prevTrg := targets(i);
		res.data(i).target := targets(i);
	end loop;
	
	return res;
end function;


	function isHalt(ins: InstructionState) return std_logic is
	begin
		if ins.operation.func = sysHalt then
			return '1';
		else
			return '0';
		end if;
	end function;

function setInterrupt3(ins: InstructionState; intSignal, start: std_logic) return InstructionState is
	variable res: InstructionState := ins;
begin
	res.controlInfo.hasInterrupt := intSignal;-- or start;
	res.controlInfo.hasReset := intSignal and start;
	-- CAREFUL: needed because updating link info must have either interrupt or exception
	if res.controlInfo.hasInterrupt = '1' then
		res.controlInfo.hasException := '0';
	end if;
	return res;
end function;

function clearControlEvents(ins: InstructionState) return InstructionState is
	variable res: InstructionState := ins;
begin
	res.controlInfo.newEvent := '0';
	res.controlInfo.hasInterrupt := '0';
	res.controlInfo.hasException := '0';	
	res.controlInfo.specialAction := '0';
	return res;
end function;

end ProcLogicSequence;
