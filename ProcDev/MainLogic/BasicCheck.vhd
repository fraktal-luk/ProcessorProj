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
use work.BasicFlow.all;
use work.GeneralPipeDev.all;


package BasicCheck is

function makeLogPath(str: string) return string;

-- CAREFUL: synthesis is turned of in this case because including std.textio.all somehow
--				causes additional 3% logic utilization
-- pragma synthesis off
procedure logArrayImplem(insArr: InstructionStateArray; full, living: std_logic_vector;
								 filename: string; desc: string);
-- pragma synthesis on

procedure logArray(insArr: InstructionStateArray; full, living: std_logic_vector;
						 filename: string; desc: string);

procedure logSimple(signal stageData: in InstructionState; fr: FlowResponseSimple);

procedure logBuffer(signal data: InstructionStateArray; fullMask, livingMask: std_logic_vector;
							flowResponse: FlowResponseBuffer);

procedure logMulti(signal data: InstructionStateArray; fullMask, livingMask: std_logic_vector;
							flowResponse: FlowResponseSimple);

procedure checkBuffer(bufferData: InstructionStateArray; fullMask: std_logic_vector;
							 bufferDataNext: InstructionStateArray; fullMaskNext: std_logic_vector;
							 bufferDrive: FlowDriveBuffer; bufferResponse: FlowResponseBuffer);

procedure checkSimple(ins, insNext: InstructionState;
							 flowDrive: FlowDriveSimple; flowResponse: FlowResponseSimple);

procedure checkMulti(stageData, stageDataNext: StageDataMulti;
							flowDrive: FlowDriveSimple; flowResponse: FlowResponseSimple);

procedure checkIQ(bufferData: InstructionStateArray; fullMask: std_logic_vector; 
						bufferDataNext: InstructionStateArray; fullMaskNext: std_logic_vector;
						insSending: InstructionState; sending: std_logic;
						bufferDrive: FlowDriveBuffer; bufferResponse: FlowResponseBuffer);



procedure checkFreeList(indTake, indPutA, nTaken, nPut: in integer);

-- pragma synthesis off
procedure logFreeListImpl(indTake, indPut, nTaken, nPut: in integer;
							 content: in PhysNameArray; freeListTakeSel: in std_logic_vector;
							 putTags: in PhysNameArray; freeListPutSel: in std_logic_vector;
							 takeAllow: in std_logic; putAllow: in std_logic;
							 freeListRewind: in std_logic; freeListWriteTag: in SmallNumber;
							 filename: in string; desc: in string);
-- pragma synthesis on

procedure logFreeList(indTake, indPut, nTaken, nPut: in integer;
							 signal content: in PhysNameArray; freeListTakeSel: in std_logic_vector;
							 putTags: in PhysNameArray; freeListPutSel: in std_logic_vector;
							 takeAllow: in std_logic; putAllow: in std_logic;
							 freeListRewind: in std_logic; freeListWriteTag: in SmallNumber);


procedure reportWriting(signal storeAddressInput, storeValueInput: in InstructionSlot; mode: in MemQueueMode);

procedure reportForwarding(signal compareAddressInput: InstructionSlot;
											selectedDataOutputSig: InstructionSlot; mode: in MemQueueMode);

end BasicCheck;



package body BasicCheck is

function makeLogPath(str: string) return string is
	variable res: string(1 to str'length) := str;
begin
	for i in res'range loop
		if res(i) = ':' then
			res(i) := '#';
		elsif res(i) = '\' then
			res(i) := '_';
		end if;
	end loop;
	
	return res & ".txt";
end function;

-- CAREFUL: synthesis is turned of in this case because including std.textio.all somehow
--				causes additional 3% logic utilization
-- pragma synthesis off
procedure logArrayImplem(insArr: InstructionStateArray; full, living: std_logic_vector;
								 filename: string; desc: string) is
   use std.textio.all;

	file outFile: text open append_mode is filename;
	variable fline: line;
begin
	write(fline, time'image(now) & ", " & desc);
	writeline(outFile, fline);
	
	for i in 0 to insArr'length-1 loop
		if full(i) = '0' then
			write(fline, "(-)");
		else
			if living(i) = '0' then
				write(fline, "x");
			end if;
			write(fline,
						  integer'image(slv2u(insArr(i).tags.renameIndex))
				--& "/" & integer'image(slv2u(insArr(i).numberTag))
				& "@" & integer'image(slv2u(insArr(i).ip)));
		end if;
		write(fline, ", ");
		
	end loop;
	writeline(outFile, fline);
end procedure;
-- pragma synthesis on


procedure logArray(insArr: InstructionStateArray; full, living: std_logic_vector;
						 filename: string; desc: string) is
begin
	if LOG_PIPELINE then
		-- pragma synthesis off
		logArrayImplem(insArr, full, living, filename, desc);
		-- pragma synthesis on
	end if;
end procedure;


procedure logSimple(signal stageData: in InstructionState; fr: FlowResponseSimple) is	
	variable data: InstructionStateArray(0 to 0) := (0 => stageData);
	variable fullMask: std_logic_vector(0 to 0) := (0 => fr.full);
	variable livingMask: std_logic_vector(0 to 0) := (0 => fr.living);	
begin
	if fr.full = '0' then
		return;
	end if;
	logArray(data, fullMask, livingMask, --now, 
														makeLogPath(stageData'path_name), "");
		return;
end procedure;


procedure logBuffer(signal data: InstructionStateArray; fullMask, livingMask: std_logic_vector;
							flowResponse: FlowResponseBuffer) is
begin	
	if isNonzero(flowResponse.full) = '0' then
		return;
	end if;
	logArray(data, fullMask, livingMask, --now,
														makeLogPath(data'path_name), "");
end procedure;

procedure logMulti(signal data: InstructionStateArray; fullMask, livingMask: std_logic_vector;
							flowResponse: FlowResponseSimple) is	
begin	
	if flowResponse.full = '0' then
		return;
	end if;
	logArray(data, fullMask, livingMask, --now,
														makeLogPath(data'path_name), "");
end procedure;



procedure checkBuffer(bufferData: InstructionStateArray; fullMask: std_logic_vector;
							 bufferDataNext: InstructionStateArray; fullMaskNext: std_logic_vector;
							 bufferDrive: FlowDriveBuffer; bufferResponse: FlowResponseBuffer) is
	variable commonPart1, commonPart2: InstructionStateArray(bufferData'range)
		:= (others => DEFAULT_INSTRUCTION_STATE);
	variable nFull, nLiving, nFullNext, nSending, nReceiving: integer := 0;
	variable nCommon: integer := 0;
begin
	-- pragma synthesis off

	if not BASIC_CHECKS then
		return;
	end if;

	nFull := integer(slv2u(bufferResponse.full));
	nLiving := integer(slv2u(bufferResponse.living));
	nSending := integer(slv2u(bufferResponse.sending));
	nReceiving := integer(slv2u(bufferDrive.prevSending));
	
	nFullNext := nLiving + nReceiving - nSending;
	-- full, fullMask - agree?
	assert countOnes(fullMask) = nFull report "k!";
		assert countOnes(fullMask(0 to nFull-1)) = nFull report "io"; -- checking continuity	
	-- next full, fullMaskNext - agree?
	assert countOnes(fullMaskNext) = nFullNext report "yt";
		assert countOnes(fullMaskNext(0 to nFullNext-1)) = nFullNext report "uu"; -- checking continuity

	if countOnes(fullMask) /= nFull then
		report integer'image(fullMask'length) & " "
						& integer'image(countOnes(fullMask)) & " " & integer'image(nFull);
	end if;

		
	-- number of killed agrees?
		--??
	-- number of new agrees?
		-- ??
	-- ??
	
	-- Check if content is matching. Which one correspond in the 2 arrays?
		-- Get those that are living. Some of them will be shifted out (nSending),
		--	some remain. [nSending to nLiving-1] should be found in [0 to nLiving-nSending-1] in new array.
		-- 
	nCommon := nLiving - nSending;	
	for i in 0 to nCommon - 1 loop
		commonPart1(i) := bufferData(i + nSending);
		commonPart2(i) := bufferDataNext(i);
	end loop;
	
	-- CHECK: does it make sense to examine this? Should other kinds of data be compared?
	for i in 0 to nCommon-1 loop
		assert commonPart1(i).tags.renameIndex = commonPart2(i).tags.renameIndex report "u";
		assert commonPart1(i).ip = commonPart2(i).ip report "yio";
	end loop;
	
	-- pragma synthesis on	
end procedure;


procedure checkSimple(ins, insNext: InstructionState;
							 flowDrive: FlowDriveSimple; flowResponse: FlowResponseSimple) is
begin
	-- pragma synthesis off

	if not BASIC_CHECKS then
		return;
	end if;

	-- pragma synthesis on
end procedure;

procedure checkMulti(stageData, stageDataNext: StageDataMulti;
							flowDrive: FlowDriveSimple; flowResponse: FlowResponseSimple) is
	variable nFull: integer := 0;
begin
	-- pragma synthesis off

	if not BASIC_CHECKS then
		return;
	end if;

	-- If flowResponse shows full, the mask can't be empty?

	-- If stalled, new content must match the old? (Already guaranteed by stageMultiNext?),
	--					...
	
	nFull:= countOnes(stageData.fullMask);
	if flowResponse.full = '1' then
		assert countOnes(stageData.fullMask(0 to nFull-1)) = nFull report "myr"; -- check continuity of mask?
	end if;
	-- pragma synthesis on	
end procedure;

procedure checkIQ(bufferData: InstructionStateArray; fullMask: std_logic_vector; 
						bufferDataNext: InstructionStateArray; fullMaskNext: std_logic_vector;
						insSending: InstructionState; sending: std_logic;
						bufferDrive: FlowDriveBuffer; bufferResponse: FlowResponseBuffer) is
	variable commonPart1, commonPart2: InstructionStateArray(bufferData'range)
		:= (others => DEFAULT_INSTRUCTION_STATE);
	variable nFull, nLiving, nFullNext, nSending, nReceiving: integer := 0;
	variable nCommon: integer := 0;
	variable move: integer:= 0;
	variable insSendingMatch: InstructionState := DEFAULT_INSTRUCTION_STATE;
begin
	-- pragma synthesis off

	if not BASIC_CHECKS then
		return;
	end if;

	nFull := integer(slv2u(bufferResponse.full));
	nLiving := integer(slv2u(bufferResponse.living));
	nSending := integer(slv2u(bufferResponse.sending));
	nReceiving := integer(slv2u(bufferDrive.prevSending));
	
	nFullNext := nLiving + nReceiving - nSending;
	-- full, fullMask - agree?
	assert countOnes(fullMask) = nFull report "eeee";
		assert countOnes(fullMask(0 to nFull-1)) = nFull report "hjuu"; -- checking continuity		
	-- next full, fullMaskNext - agree?
	assert countOnes(fullMaskNext) = nFullNext report "h";
		assert countOnes(fullMaskNext(0 to nFullNext-1)) = nFullNext report "m,"; -- checking continuity	
	-- number of killed agrees?
		--??
	-- number of new agrees?
		-- ??
	-- ??
	
	
	-- CAREFUL: in IQ sending is from any living slot, not just the first. Deal with this here!
	-- Check if content is matching. Which one correspond in the 2 arrays?
		-- Get those that are living. Some of them will be shifted out (nSending),
		--	some remain. [nSending to nLiving-1] should be found in [0 to nLiving-nSending-1] in new array.
		-- 
	nCommon := nLiving - nSending;	
	for i in 0 to nLiving - 1 loop
		-- In old array we have to skip the op that is being sent
		if sending = '1' and bufferData(i).tags.renameIndex = insSending.tags.renameIndex 
			then -- CAREFUL: is this the right tag field?
			move := 1;
					--report "rtttt";
			insSendingMatch := bufferData(i);
			-- Check the op that is sent?
			assert insSendingMatch.tags.renameIndex = insSending.tags.renameIndex report "byj";
			assert insSendingMatch.ip = insSending.ip report "jjj";		
		end if;
		
		-- If we have visited all living instructions in old array, we break, because 
		--		it one less is copied to commonPart1, not all of them. Otherwise we could go out of array!
		if i + move > nLiving - 1 then
			exit;
		end if;
				
		commonPart1(i) := bufferData(i + move);
		commonPart2(i) := bufferDataNext(i);		
	end loop;
	
	-- CHECK: does it make sense to examine this? Should other kinds of data be compared?
	for i in 0 to nCommon-1 loop
		assert commonPart1(i).tags.renameIndex = commonPart2(i).tags.renameIndex report "jutrrrr";
		assert commonPart1(i).ip = commonPart2(i).ip report "oiu";
	end loop;
	
	-- pragma synthesis on	
end procedure;


procedure checkFreeList(indTake, indPutA, nTaken, nPut: in integer) is
	variable indPut: integer := indPutA;
	variable diff: integer := 0;
begin
	-- pragma synthesis off
	if indTake > indPut then
		indPut := indPut + FREE_LIST_SIZE;
	end if;
	diff := indPut - indTake;
	-- NOTE: Below alert doesn't mean that wrong operation happened, but if 'take' of sufficient width
	-- happens before 'put', it will read wrong data. It could be prevented when we lock Rename in such cases.
	assert diff >= PIPE_WIDTH report "Too few free registers on list" severity error;
	
	-- Now what will be the new state:
	diff := diff + nPut - nTaken;
	-- NOTE: like the previous alert, this is a careful reaction, not that something bad already has taken place. 
	assert diff >= PIPE_WIDTH report "Free list becoming drained!" severity error;
	
	-- TODO: check if no 0 values are read or written (if implementation prevents physical reg 0 from alloction)
	
	-- pragma synthesis on
end procedure;


-- pragma synthesis off
procedure logFreeListImpl(indTake, indPut, nTaken, nPut: in integer;
							 content: in PhysNameArray; freeListTakeSel: in std_logic_vector;
							 putTags: in PhysNameArray; freeListPutSel: in std_logic_vector;
							 takeAllow: in std_logic; putAllow: in std_logic;
							 freeListRewind: in std_logic; freeListWriteTag: in SmallNumber;
							 filename: in string; desc: in string) is
	use std.textio.all;

	file outFile: text open append_mode is filename;
	variable fline: line;
begin	
	write(fline, time'image(now) & ", " & desc);
	writeline(outFile, fline);
	
	if freeListRewind = '1' then
		write(fline, "Rewinding to: " & integer'image(slv2u(freeListWriteTag)));
		writeline(outFile, fline);
	end if;
	
	-- What's being taken from list:
	if takeAllow = '1' then
		write(fline, "Taking  at " & integer'image(indTake) & ":    ");
		for i in 0 to freeListTakeSel'length-1 loop
			if freeListTakeSel(i) = '1' then
				write(fline, integer'image(slv2u(content((indTake + i) mod FREE_LIST_SIZE))) & ","); 
			else
				write(fline, "_" & ",");
			end if;	
		end loop;
		writeline(outFile, fline);
	end if;

	-- What's being put to list:
	if putAllow = '1' then
		write(fline, "Putting at " & integer'image(indPut) & ":    " & "          ");
		for i in 0 to freeListPutSel'length-1 loop
			if freeListPutSel(i) = '1' then
				write(fline, integer'image(slv2u(putTags(i))) & ","); 
			else
				write(fline, "_" & ",");
			end if;	
		end loop;
		writeline(outFile, fline);
	end if;	
		
end procedure;
-- pragma synthesis on


procedure logFreeList(indTake, indPut, nTaken, nPut: in integer;
							 signal content: in PhysNameArray; freeListTakeSel: in std_logic_vector;
							 putTags: in PhysNameArray; freeListPutSel: in std_logic_vector;
							 takeAllow: in std_logic; putAllow: in std_logic;
							 freeListRewind: in std_logic; freeListWriteTag: in SmallNumber) is
begin
	-- pragma synthesis off
	if not LOG_FREE_LIST then
		return;
	end if;
					  logFreeListImpl(indTake, indPut, nTaken, nPut,
											content, freeListTakeSel,
											putTags, freeListPutSel,
											takeAllow, putAllow,
											freeListRewind, freeListWriteTag,
											makeLogPath(content'path_name),
											"");	
	
	--	pragma synthesis on
end procedure;


procedure reportWriting(signal storeAddressInput, storeValueInput: in InstructionSlot; mode: in MemQueueMode) is
begin
	-- pragma synthesis off
	if not REPORT_MEM_QUEUE_WRITES then
		return;
	end if;
	
	case mode is
		when store =>
			if storeAddressInput.full = '1' then
				report makeLogPath(storeAddressInput'path_name) & ": " &
							"writing store address " & integer'image(slv2u(storeAddressInput.ins.result)) &
							" by " & integer'image(slv2u(storeAddressInput.ins.tags.renameIndex));
			end if;

			if storeValueInput.full = '1' then
				report makeLogPath(storeAddressInput'path_name) & ": " &
							"writing store value " & integer'image(slv2u(getStoredArg2(storeAddressInput.ins))) &
							" by " & integer'image(slv2u(storeAddressInput.ins.tags.renameIndex));
			end if;
			
		when load =>
			if storeAddressInput.full = '1' then
				report makeLogPath(storeAddressInput'path_name) & ": " &
							"writing load address " & integer'image(slv2u(storeAddressInput.ins.result)) &
							" by " & integer'image(slv2u(storeAddressInput.ins.tags.renameIndex));
			end if;

--			if storeValueInput.full = '1' then
--				report makeLogPath(storeAddressInput'path_name) & ": " &
--							"writing value " & integer'image(slv2u(storeAddressInput.ins.argValues.arg2)) &
--							" by " & integer'image(slv2u(storeAddressInput.ins.tags.renameIndex));
--			end if;
		when others =>
	end case;
	-- pragma synthesis on
end procedure;

procedure reportForwarding(signal compareAddressInput: InstructionSlot;
											selectedDataOutputSig: InstructionSlot; mode: in MemQueueMode) is
begin	
	-- pragma synthesis off
	if not REPORT_MEM_QUEUE_FORWARDING then
		return;
	end if;
	
	case mode is
		when store => -- Checking what to forward from store queue
			if compareAddressInput.full = '1' then
				report makeLogPath(compareAddressInput'path_name) & ": " &
							"checking loading address " & integer'image(slv2u(compareAddressInput.ins.result)) &
							" by " & integer'image(slv2u(compareAddressInput.ins.tags.renameIndex));
			end if;

			if selectedDataOutputSig.full = '1' then
				report makeLogPath(compareAddressInput'path_name) & ": " &
							"matched storeded value " & integer'image(slv2u(getStoredArg2(selectedDataOutputSig.ins))) &
							" by " & integer'image(slv2u(selectedDataOutputSig.ins.tags.renameIndex));
			end if;
			
		when load => -- checking in load queue if there was a hazard
			if compareAddressInput.full = '1' then
				report makeLogPath(compareAddressInput'path_name) & ": " &
							"checking storing address " & integer'image(slv2u(compareAddressInput.ins.result)) &
							" by " & integer'image(slv2u(compareAddressInput.ins.tags.renameIndex));
			end if;

			if selectedDataOutputSig.full = '1' then
				report makeLogPath(compareAddressInput'path_name) & ": " &
							"matched load" &
							" by " & integer'image(slv2u(selectedDataOutputSig.ins.tags.renameIndex));
			end if;
		when others =>
	end case;
	-- pragma synthesis on
end procedure;

end BasicCheck;
