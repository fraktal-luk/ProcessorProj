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


package ProcLogicSequence is
		-- group:  revTag = causing.groupTag and i2slv(-PIPE_WIDTH, SMALL_NUMBER_SIZE), mask = all ones
		-- sequential: revTag = causing.numberTag, mask = new group's fullMask		
		function nextCtr(ctr: SmallNumber; rewind: std_logic; revTag: SmallNumber;
									 allow: std_logic; mask: std_logic_vector) 
		return SmallNumber;
		
		constant ALL_FULL: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '1');

-- Jump target, increment if not jump 
function getLinkInfoNormal(ins: InstructionState) return InstructionBasicInfo;
-- Handler address and system state
function getExceptionTarget(ins: InstructionState) return InstructionBasicInfo;
-- Target, which may be exception handler call
function getLinkInfoSuper(ins: InstructionState) return InstructionBasicInfo;
----------------

function getLatePCData(commitEvent: std_logic; commitCausing: InstructionState;
								linkExc, linkInt, stateExc, stateInt: Mword)
return InstructionState;

function newPCData(content: InstructionState;
						  commitEvent: std_logic; commitCausing: InstructionState;
						  execEvent: std_logic; execCausing: InstructionState;	
						  frontEvent: std_logic; frontCausing: InstructionState;
						  pcNext: Mword)
return InstructionState;

	function NEW_generalEvents(pcData: InstructionState;
										commitEvent: std_logic; commitCausing: InstructionState;
										execEvent: std_logic; execCausing: InstructionState;	
										frontEvent: std_logic; frontCausing: InstructionState;
										pcNext: Mword)
	return GeneralEventInfo;

-- BACK ROUTING
-- Unifies content of ROB slot with BQ, others queues etc. to restore full state needed at Commit
function recreateGroup(insVec: StageDataMulti; bqGroup: StageDataMulti; prevAddress: Mword)
return StageDataMulti;

function setException2(ins, causing: InstructionState;
							  intSignal, resetSignal, isNew, phase0, phase1, phase2: std_logic)
return InstructionState;

function setPhase(ins: InstructionState; phase0, phase1, phase2: std_logic)
return InstructionState;

function setLateTargetAndLink(ins: InstructionState; target: Mword; link: Mword; phase1: std_logic)
return InstructionState;

function getAddressIncrement(ins: InstructionState) return Mword;

function checkIvalid(ins: InstructionState; ivalid: std_logic) return InstructionState;

function makeInterruptCause(targetIns: InstructionState; intSignal, start: std_logic)
return InstructionState;

end ProcLogicSequence;



package body ProcLogicSequence is
		-- group:  revTag = causing.groupTag and i2slv(-PIPE_WIDTH, SMALL_NUMBER_SIZE), mask = all ones
		-- sequential: revTag = causing.numberTag, mask = new group's fullMask		
		function nextCtr(ctr: SmallNumber; rewind: std_logic; revTag: SmallNumber;
									 allow: std_logic; mask: std_logic_vector) 
		return SmallNumber is			
		begin
			if rewind = '1' then
				return revTag;
			elsif allow = '1' then
				return i2slv(slv2u(ctr) + countOnes(mask), SMALL_NUMBER_SIZE);
			else
				return ctr;
			end if;
		end function;

function getLinkInfoNormal(ins: InstructionState) return InstructionBasicInfo is
	variable res: InstructionBasicInfo := ins.basicInfo;
begin
	res.ip := ins.result;
	return res;
end function;


function getExceptionTarget(ins: InstructionState) return InstructionBasicInfo is
	variable res: InstructionBasicInfo := ins.basicInfo;
begin
	-- get handler adr and system level 
	res.ip := --getHandlerAddress(ins);
			-- TODO, FIX: exceptionCode sliced - shift left by ALIGN_BITS? or leave just base address
		EXC_BASE(MWORD_SIZE-1 downto ins.controlInfo.exceptionCode'length)
	& ins.controlInfo.exceptionCode(ins.controlInfo.exceptionCode'length-1 downto ALIGN_BITS)
	& EXC_BASE(ALIGN_BITS-1 downto 0);		
	
	res.systemLevel := "00000001";	
	return res;
end function;


function getLinkInfoSuper(ins: InstructionState) return InstructionBasicInfo is
	variable res: InstructionBasicInfo := ins.basicInfo;
begin
	if ins.controlInfo.hasException = '1' then 
		return getExceptionTarget(ins);
	-- > NOTE, TODO: Interupt chaining can be implemented in a simple way: when another interrupt appears, 
	--		jump to handler directly from currently running handler, but don't set ILR.
	--		ILR will remain from the first interrupt in chain, just like in tail function call
	else
		return getLinkInfoNormal(ins);
	end if;
end function;


function getLatePCData(commitEvent: std_logic; commitCausing: InstructionState;
								linkExc, linkInt, stateExc, stateInt: Mword)
return InstructionState is
	variable res: InstructionState := DEFAULT_INSTRUCTION_STATE;-- content;
	variable newPC: Mword := (others=>'0');
begin
		if commitCausing.controlInfo.hasReset = '1' then -- TEMP!
			res.basicInfo.ip := (others => '0');
			res.basicInfo.intLevel := "00000000";				
		elsif commitCausing.controlInfo.hasInterrupt = '1' then
			res.basicInfo.ip := INT_BASE; -- TEMP!
			res.basicInfo.intLevel := "00000001";		
		elsif commitCausing.controlInfo.hasException = '1' then
			-- TODO, FIX: exceptionCode sliced - shift left by ALIGN_BITS? or leave just base address
			res.basicInfo.ip := EXC_BASE(MWORD_SIZE-1 downto commitCausing.controlInfo.exceptionCode'length)
									& commitCausing.controlInfo.exceptionCode(
													commitCausing.controlInfo.exceptionCode'length-1 downto ALIGN_BITS)
									& EXC_BASE(ALIGN_BITS-1 downto 0);	
									--		INT_BASE;
			res.basicInfo.systemLevel := "00000001";
			
		elsif commitCausing.controlInfo.specialAction = '1' then
				if commitCausing.operation.func = sysSync then
					res.basicInfo.ip := commitCausing.target;
				elsif commitCausing.operation.func = sysReplay then
					res.basicInfo.ip := commitCausing.basicInfo.ip;
				elsif commitCausing.operation.func = sysHalt then
					res.basicInfo.ip := commitCausing.target; -- ???
				elsif commitCausing.operation.func = sysRetI then
					res.basicInfo.ip := linkInt;
					res.basicInfo.systemLevel := stateInt(15 downto 8);
					res.basicInfo.intLevel := stateInt(7 downto 0);
				elsif commitCausing.operation.func = sysRetE then
					res.basicInfo.ip := linkExc;
					res.basicInfo.systemLevel := stateExc(15 downto 8);
					res.basicInfo.intLevel := stateExc(7 downto 0); 
				end if;				
		end if;		
	
	return res;
end function;


function newPCData(content: InstructionState;
						  commitEvent: std_logic; commitCausing: InstructionState;
						  execEvent: std_logic; execCausing: InstructionState;	
						  frontEvent: std_logic; frontCausing: InstructionState;
						  pcNext: Mword)
return InstructionState is
	variable res: InstructionState := content;
	variable newPC: Mword := (others=>'0');
begin
	if commitEvent = '1' then -- when from exec or front
		res.basicInfo.ip := commitCausing.target;
	elsif execEvent = '1' then		
		res.basicInfo.ip := execCausing.target;
	elsif frontEvent = '1' then
		--	report "front event!";
		res.basicInfo.ip := frontCausing.target;	
	else	-- Increment by the width of fetch group
		res.basicInfo.ip := pcNext;
	end if;	

	return res;
end function;

	function NEW_generalEvents(pcData: InstructionState;
										commitEvent: std_logic; commitCausing: InstructionState;
										execEvent: std_logic; execCausing: InstructionState;	
										frontEvent: std_logic; frontCausing: InstructionState;
										pcNext: Mword)
	return GeneralEventInfo is
		variable res: GeneralEventInfo;
	begin
		res.affectedVec := (others => '0');
		res.eventOccured := '1';
			res.killPC := '0';
			
		res.causing := frontCausing;
	
		if commitEvent = '1' then 
			res.killPC := '1';
			res.causing := commitCausing;
			--res.affectedVec(0 to 4) := (others => '1');
		elsif execEvent = '1' then
			res.causing := execCausing;
			--res.affectedVec(0 to 4) := (others => '1');
		elsif frontEvent = '1' then
			res.causing := frontCausing;
			--res.affectedVec(0 to 3) := (others => '1');
		else
			res.eventOccured := '0';
		end if;
		
		return res;
	end function;

-- Unifies content of ROB slot with BQ, others queues etc. to restore full state needed at Commit
function recreateGroup(insVec: StageDataMulti; bqGroup: StageDataMulti;
							  prevAddress: Mword--; tempValue: Mword; useTemp: std_logic
							  ) return StageDataMulti is
	variable res: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	variable targets: MwordArray(0 to PIPE_WIDTH-1) := (others => (others => '0'));
	variable ind: integer := 0;
	variable prevAdr: Mword := (others => '0');
begin
	res := insVec;
	
	prevAdr := prevAddress;
	
	for i in 0 to PIPE_WIDTH-1 loop
		targets(i) := bqGroup.data(i).target; -- Default to some input, not zeros 
	end loop;
	
	-- Take branch targets to correct places
	for i in 0 to PIPE_WIDTH-1 loop
		if bqGroup.fullMask(i) = '1' then
			ind := slv2u(getTagLow(bqGroup.data(i).groupTag));
			targets(ind) := bqGroup.data(i).argValues.arg1;
		end if;
	end loop;

	for i in 0 to PIPE_WIDTH-1 loop
		if insVec.data(i).controlInfo.hasBranch = '1' then
			null;
		else
			--targets(i) := i2slv(slv2u(prevAdr) + slv2u(getAddressIncrement(insVec.data(i))), MWORD_SIZE);
			targets(i) := addMwordBasic(prevAdr, getAddressIncrement(insVec.data(i)));
		end if;
		res.data(i).basicInfo.ip := prevAdr; -- ??
		prevAdr := targets(i);
		res.data(i).target := targets(i);
	end loop;
	
	return res;
end function;

function setPhase(ins: InstructionState;
							 phase0, phase1, phase2: std_logic)
return InstructionState is
	variable res: InstructionState := ins;
begin	
	res.controlInfo.phase0 := phase0;
	res.controlInfo.phase1 := phase1;
	res.controlInfo.phase2 := phase2;
	return res;
end function;


function setException2(ins, causing: InstructionState;
							  intSignal, resetSignal, isNew, phase0, phase1, phase2: std_logic)
return InstructionState is
	variable res: InstructionState := ins;
begin
	res.controlInfo.newEvent := ((res.controlInfo.hasException 
											or res.controlInfo.specialAction
											)
											and isNew) 
									or intSignal or resetSignal;

	res.controlInfo.hasInterrupt := res.controlInfo.hasInterrupt or intSignal;
	-- ^ Interrupts delayed by 1 cycle if exception being committed!
	
	res.controlInfo.hasReset := resetSignal;
		
	if phase1 = '1' then
		res.result := res.target;
		--res.target := causing.target;
	end if;
	
	if phase2 = '1' then
		res.controlInfo.newEvent := '0';	
			res.controlInfo.hasException := '0';
			res.controlInfo.hasInterrupt := '0';
			res.controlInfo.hasReset := '0';
			--res.controlInfo.hasEvent := '0';	
			res.controlInfo.specialAction := '0';			
	end if;
	
	return res;
end function;

function setLateTargetAndLink(ins: InstructionState; target: Mword; link: Mword; phase1: std_logic)
return InstructionState is
	variable res: InstructionState := ins;
begin

	if phase1 = '1' then
		res.result := link;
		res.target := target;
	end if;	
	
	return res;
end function;

function getAddressIncrement(ins: InstructionState) return Mword is
	variable res: Mword := (others => '0');
begin
	if ins.classInfo.short = '1' then
		res(1) := '1'; -- 2
	else
		res(2) := '1'; -- 4
	end if;
	return res;
end function;

function checkIvalid(ins: InstructionState; ivalid: std_logic) return InstructionState is
	variable res: InstructionState := ins;
begin
	res.controlInfo.squashed := not ivalid; -- CAREFUL: here we'll use 'squashed', must be cleared before ROB 
	return res;
end function;

function makeInterruptCause(targetIns: InstructionState; intSignal, start: std_logic)
return InstructionState is
	variable res: InstructionState := DEFAULT_INSTRUCTION_STATE;
begin
	res.controlInfo.hasInterrupt := intSignal;
	res.controlInfo.hasReset := start;
	res.target := targetIns.basicInfo.ip;	
	return res;
end function;

end ProcLogicSequence;
