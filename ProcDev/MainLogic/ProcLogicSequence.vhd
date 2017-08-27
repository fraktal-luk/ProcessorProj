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


-- SEQUENCE ---------
-- Jump target, increment if not jump 
function getLinkInfoNormal(ins: InstructionState) return InstructionBasicInfo;
-- Handler address and system state
function getExceptionTarget(ins: InstructionState) return InstructionBasicInfo;
-- Target, which may be exception handler call
function getLinkInfoSuper(ins: InstructionState) return InstructionBasicInfo;
----------------


function getLatePCData(commitEvent: std_logic; commitCausing: InstructionState)
return InstructionState;

function newPCData(content: InstructionState;
						  commitEvent: std_logic; commitCausing: InstructionState;
						  execEvent: std_logic; execCausing: InstructionState;	
						  decodeEvent: std_logic; decodeCausing: InstructionState;
						  pcNext: Mword)
return InstructionState;

	function NEW_generalEvents(pcData: InstructionState;
										commitEvent: std_logic; commitCausing: InstructionState;
										execEvent: std_logic; execCausing: InstructionState;	
										decodeEvent: std_logic; decodeCausing: InstructionState;
										pcNext: Mword)
	return GeneralEventInfo;


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


function getLatePCData(commitEvent: std_logic; commitCausing: InstructionState)
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
						res.basicInfo.ip := X"00000020";  --TEMP!!
				elsif commitCausing.operation.func = sysRetE then
						res.basicInfo.ip := X"00000030";  --TEMP!!					
				end if;				
		end if;		
	
	return res;
end function;


function newPCData(content: InstructionState;
						  commitEvent: std_logic; commitCausing: InstructionState;
						  execEvent: std_logic; execCausing: InstructionState;	
						  decodeEvent: std_logic; decodeCausing: InstructionState;
						  pcNext: Mword)
return InstructionState is
	variable res: InstructionState := content;
	variable newPC: Mword := (others=>'0');
begin
	if commitEvent = '1' then -- when from exec or front
		res.basicInfo.ip := commitCausing.target;
	elsif execEvent = '1' then		
		res.basicInfo.ip := execCausing.target;
	elsif decodeEvent = '1' then
			if BRANCH_AT_DECODE then
				res.basicInfo.ip := decodeCausing.target;	
			end if;
	else	-- Increment by the width of fetch group
		res.basicInfo.ip := pcNext;
	end if;	

	return res;
end function;

	function NEW_generalEvents(pcData: InstructionState;
										commitEvent: std_logic; commitCausing: InstructionState;
										execEvent: std_logic; execCausing: InstructionState;	
										decodeEvent: std_logic; decodeCausing: InstructionState;
										pcNext: Mword)
	return GeneralEventInfo is
		variable res: GeneralEventInfo;
	begin
		res.affectedVec := (others => '0');
		res.eventOccured := '1';
			res.killPC := '0';
			
		res.causing := decodeCausing;
	
		if commitEvent = '1' then 
			res.killPC := '1';
			res.causing := commitCausing;
			res.affectedVec(0 to 4) := (others => '1');
		elsif execEvent = '1' then
			res.causing := execCausing;
			res.affectedVec(0 to 4) := (others => '1');
		elsif decodeEvent = '1' then
			res.causing := decodeCausing;
			res.affectedVec(0 to 3) := (others => '1');
		else
			res.eventOccured := '0';
		end if;
		
		return res;
	end function;
	
end ProcLogicSequence;
