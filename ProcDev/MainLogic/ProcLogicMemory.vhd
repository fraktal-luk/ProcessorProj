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

use work.Decoding2.all;

use work.TEMP_DEV.all;
use work.GeneralPipeDev.all;

--use work.Queues.all;


package ProcLogicMemory is

function compareAddress(content: InstructionStateArray; fullMask: std_logic_vector;
								ins: InstructionState) return std_logic_vector;
function findNewestMatch(content: InstructionStateArray;
								 cmpMask: std_logic_vector; pStart: SmallNumber; ins: InstructionState)
return std_logic_vector;
		
function findOldestMatch(content: InstructionStateArray;
								 cmpMask: std_logic_vector; pStart: SmallNumber; ins: InstructionState)
return std_logic_vector;		


	function findFirstFilled(content: InstructionStateArray; livingMask: std_logic_vector;
									 nextAccepting: std_logic)
	return std_logic_vector;

function findCommittingSQ(content: InstructionStateArray; livingMask: std_logic_vector;
								  committingTag: InsTag; send: std_logic) return StageDataMulti;

function getAddressCompleted(ins: InstructionState) return std_logic;
function getDataCompleted(ins: InstructionState) return std_logic;
function setAddressCompleted(ins: InstructionState; state: std_logic) return InstructionState;
function setDataCompleted(ins: InstructionState; state: std_logic) return InstructionState;


				function lmQueueNext(content: InstructionStateArray;
									  livingMask: std_logic_vector;
									  newContent: InstructionState;
									  sendingVec: std_logic_vector; -- shows which one sending
									  receiving: std_logic;
									  receivingVec: std_logic_vector;
									  newFilled: std_logic_vector;
									  filling: std_logic) return InstructionStateArray;

function lmMaskNext(livingMask: std_logic_vector;
					  sendingVec: std_logic_vector;
					  receiving: std_logic;
					  receivingVec: std_logic_vector) return std_logic_vector;

function findFirstFree(mask: std_logic_vector) return std_logic_vector;

	function TMP_cmpTagsBefore(content: InstructionStateArray; tag: InsTag)
	return std_logic_vector;

	function TMP_cmpTagsAfter(content: InstructionStateArray; tag: InsTag)
	return std_logic_vector;

	function setLoadException(ins: InstructionState) return InstructionState;
	
	function getLSResultData(ins: InstructionState;
									  memLoadReady: std_logic; memLoadValue: Mword;
									  sysLoadReady: std_logic; sysLoadValue: Mword;
									  storeForwardSending: std_logic; storeForwardIns: InstructionState
										) return InstructionState;

	function getSendingToDLQ(sendingAfterRW, sendingSelectedLQ: std_logic;
									 lsResultData: InstructionState) return std_logic;	
	function calcEffectiveAddress(ins: InstructionState) return InstructionState;

end ProcLogicMemory;



package body ProcLogicMemory is

		
function compareAddress(content: InstructionStateArray; fullMask: std_logic_vector;
								ins: InstructionState) return std_logic_vector is
	variable res: std_logic_vector(0 to content'length-1) := (others => '0');
begin
	for i in 0 to res'length-1 loop
		if 	 fullMask(i) = '1'
			and content(i).controlInfo.completed = '1' -- Addressmust be already known!
			and ins.argValues.arg1 = content(i).argValues.arg1 then
			res(i) := '1';
		end if;
	end loop;
	
	return res;
end function;

		-- To find what to forward from StoreQueue
		function findNewestMatch(content: InstructionStateArray;
										 cmpMask: std_logic_vector; pStart: SmallNumber;
										 ins: InstructionState)
		return std_logic_vector is
			constant LEN: integer := cmpMask'length;		
			variable res, older, before: std_logic_vector(0 to LEN-1) := (others => '0');
			variable indices, rawIndices: SmallNumberArray(0 to LEN-1) := (others => (others => '0'));
			variable matchBefore: std_logic := '0';
			
			variable tmpVec: std_logic_vector(0 to LEN-1) := (others => '0');
		begin
			-- From qs we must check which are older than ins
			--indices := getQueueIndicesFrom(LEN, pStart);
			--rawIndices := getQueueIndicesFrom(LEN, (others => '0'));
			older := TMP_cmpTagsBefore(content, ins.tags.renameIndex);
			before := setToOnes(older, slv2u(pStart));
			-- Use priority enc. to find last in the older ones. But they may be divided:
			--		V  1 1 1 0 0 0 0 1 1 1 and cmp  V
			--		   0 1 0 0 0 0 0 1 0 1
			-- and then there are 2 runs of bits and those at the enc must be ignored (r older than first run)
			
			-- If there's a match before pStart, it is younger than those at or after pStart
			tmpVec := cmpMask and older and before;
			matchBefore := isNonzero(tmpVec);
			
			if matchBefore = '1' then
				-- Ignore those after
				tmpVec := cmpMask and older and before;
				res := invertVec(getFirstOne(invertVec(tmpVec)));
			else
				-- Don't ignore any matches
				tmpVec := cmpMask and older;
				res := invertVec(getFirstOne(invertVec(tmpVec)));
			end if;
			
			return res;
		end function;
		
		-- To check what in the LoadQueue has an error
		function findOldestMatch(content: InstructionStateArray;
										 cmpMask: std_logic_vector; pStart: SmallNumber;
										 ins: InstructionState)
		return std_logic_vector is
			constant LEN: integer := cmpMask'length;
			variable res, newer, areAtOrAfter: std_logic_vector(0 to LEN-1) := (others => '0');
			variable indices, rawIndices: SmallNumberArray(0 to LEN-1) := (others => (others => '0'));
			variable matchAtOrAfter: std_logic := '0';
			
			variable tmpVec: std_logic_vector(0 to LEN-1) := (others => '0');
		begin
			-- From qs we must check which are newer than ins
			--indices := getQueueIndicesFrom(LEN, pStart);
			--rawIndices := getQueueIndicesFrom(LEN, (others => '0'));
			newer := TMP_cmpTagsAfter(content, ins.tags.renameIndex);
			areAtOrAfter := not setToOnes(newer, slv2u(pStart));
			-- Use priority enc. to find first in the newer ones. But they may be divided:
			--		V  1 1 1 0 0 0 0 1 1 1 and cmp  V
			--		   0 1 0 0 0 0 0 1 0 1
			-- and then there are 2 runs of bits and those at the enc must be ignored (r newer than first run)
			
			-- So, elems at the end are ignored when those conditions cooccur:
			--		pStart > ins.groupTag and [match exists that match.groupTag < ins.groupTag]
			tmpVec := cmpMask and newer and areAtOrAfter;
			matchAtOrAfter := isNonzero(tmpVec);
			
			if matchAtOrAfter = '1' then
				-- Ignore those before
				tmpVec := cmpMask and newer and areAtOrAfter;
				res := getFirstOne(tmpVec);
			else
				-- Don't ignore any matches
				tmpVec := cmpMask and newer;
				res := getFirstOne(tmpVec);
			end if;
			
			return res;
		end function;

			
			-- Set '1' where first occupied slot with completed transfer lies.
			function findFirstFilled(content: InstructionStateArray; livingMask: std_logic_vector;
										  nextAccepting: std_logic)
			return std_logic_vector is
				variable res: std_logic_vector(0 to livingMask'length-1) := (others => '0');
			begin
				if nextAccepting = '0' then
					return res;
				end if;
				
				for i in 0 to res'length-1 loop
					if (livingMask(i) and content(i).controlInfo.completed
										  and	content(i).controlInfo.completed2) = '1' then
						res(i) := '1';										  
						exit;
					end if;
				end loop;
				
				return res;
			end function;
							
					function findCommittingSQ(content: InstructionStateArray; livingMask: std_logic_vector;
													  committingTag: InsTag; send: std_logic) return StageDataMulti is
							variable res: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
						begin
							res.data := content(0 to PIPE_WIDTH-1);
							for i in 0 to PIPE_WIDTH-1 loop
								if (content(i).tags.renameIndex(TAG_SIZE-1 downto LOG2_PIPE_WIDTH)
									= committingTag(TAG_SIZE-1 downto LOG2_PIPE_WIDTH))
									and (livingMask(i) = '1') and (send = '1')
								then	
									res.fullMask(i) := '1';
								end if;	
							end loop;

							return res;
						end function;

function getAddressCompleted(ins: InstructionState) return std_logic is
begin
	return ins.controlInfo.completed;
end function;

function getDataCompleted(ins: InstructionState) return std_logic is
begin
	return ins.controlInfo.completed2;
end function;

function setAddressCompleted(ins: InstructionState; state: std_logic) return InstructionState is
	variable res: InstructionState := ins;
begin
	res.controlInfo.completed := state;
	return res;
end function;

function setDataCompleted(ins: InstructionState; state: std_logic) return InstructionState is
	variable res: InstructionState := ins;
begin
	res.controlInfo.completed2 := state;
	return res;
end function;



				function lmQueueNext(content: InstructionStateArray;
									  livingMask: std_logic_vector;
									  newContent: InstructionState;
									  sendingVec: std_logic_vector; -- shows which one sending
									  receiving: std_logic;
									  receivingVec: std_logic_vector;
									  newFilled: std_logic_vector;
									  filling: std_logic
									  ) return InstructionStateArray is
					constant LEN: integer := content'length;
					variable res: InstructionStateArray(0 to LEN-1) := content;
				begin
					for i in 0 to LEN-1 loop
						if (filling and newFilled(i) and livingMask(i)) = '1' then
							res(i).controlInfo.completed2 := '1';
						end if;
						
					
						if receiving = '1' and receivingVec(i) = '1' then
							res(i) := newContent;
						elsif sendingVec(i) = '1' then
							null; 
						end if;
					end loop;
					
					return res;
				end function;


function lmMaskNext(livingMask: std_logic_vector;
					  sendingVec: std_logic_vector;
					  receiving: std_logic;
					  receivingVec: std_logic_vector
) return std_logic_vector is
	constant LEN: integer := livingMask'length;
	variable outMask: std_logic_vector(0 to LEN-1) := (others => '0');
begin
	outMask := outMask and not sendingVec;
	if receiving = '1' then 
		outMask := outMask or receivingVec;
	end if;
	return outMask;
end function;

function findFirstFree(mask: std_logic_vector) return std_logic_vector is
	variable res: std_logic_vector(0 to mask'length-1) := (others => '0');
begin
	for i in 0 to mask'length-1 loop
		if mask(i) = '0' then
			res(i) := '1';
			exit;
		end if;
	end loop;
	
	return res;
end function;


	function TMP_cmpTagsBefore(content: InstructionStateArray; tag: InsTag)
	return std_logic_vector is
		variable res: std_logic_vector(0 to content'length-1) := (others => '0');
		variable diff: SmallNumber := (others => '0');
	begin
		for i in 0 to res'length-1 loop
			res(i) := CMP_tagBefore(content(i).tags.renameIndex, tag); -- If grTag < tag then diff(high) = '1'
		end loop;
		return res;
	end function;

	function TMP_cmpTagsAfter(content: InstructionStateArray; tag: InsTag)
	return std_logic_vector is
		variable res: std_logic_vector(0 to content'length-1) := (others => '0');
		variable diff: SmallNumber := (others => '0');
	begin
		for i in 0 to res'length-1 loop
			res(i) := CMP_tagBefore(tag, content(i).tags.renameIndex); -- If grTag > tag then diff(high) = '1'
		end loop;
		return res;
	end function;

	function setLoadException(ins: InstructionState) return InstructionState is
		variable res: InstructionState := ins;
	begin
		res.controlInfo.hasException := '1';
		return res;
	end function;
	
	function getLSResultData(ins: InstructionState;
									  memLoadReady: std_logic; memLoadValue: Mword;
									  sysLoadReady: std_logic; sysLoadValue: Mword;
									  storeForwardSending: std_logic; storeForwardIns: InstructionState
										) return InstructionState is
		variable res: InstructionState := ins;
	begin
		-- TODO: remember about miss/hit status and reason of miss if relevant!
		if storeForwardSending = '1' then
			res := setDataCompleted(res, getDataCompleted(storeForwardIns));
			res := setInsResult(res, storeForwardIns.argValues.arg2);
		elsif isSysRegRead(res) = '1' then
			res := setDataCompleted(res, sysLoadReady);
			res := setInsResult(res, sysLoadValue);		
		elsif isLoad(res) = '1' then 
			res := setDataCompleted(res, memLoadReady);
			res := setInsResult(res, memLoadValue);
		else -- is store or sys reg write?
			res := setDataCompleted(res, '1'); -- TEMP!
			
		end if;
		
		return res;
	end function;

	function getSendingToDLQ(sendingAfterRW, sendingSelectedLQ: std_logic;
									 lsResultData: InstructionState) return std_logic is
	begin
		return		(		sendingAfterRW
								 --and (isLoad(lsResultData) or isSysRegRead(lsResultData))
								 and not getDataCompleted(lsResultData))  -- When missed etc.
							or  sendingSelectedLQ; -- When store hits younger load and must get off the way	
	end function;
	
	function calcEffectiveAddress(ins: InstructionState) return InstructionState is
	begin
		return setInstructionTarget(ins, addMwordFaster(ins.argValues.arg0, ins.argValues.arg1));
	end function;

end ProcLogicMemory;
