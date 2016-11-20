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


package ProcLogicCQ is

function getSendingFromCQ(livingMask: std_logic_vector) return std_logic_vector;

function stageCQNext(content: StageDataCommitQueue; newContent: InstructionStateArray;
		livingMask: std_logic_vector;
		ready: std_logic_vector; routes: IntArray; nFull, nOut, nIn: integer)
return StageDataCommitQueue;

function stageCQNext2(content: StageDataCommitQueue; newContent: InstructionStateArray;
		livingMask: std_logic_vector;
		ready: std_logic_vector;
		vecA, vecB, vecC, vecD: std_logic_vector; 
		nFull, nOut, nIn: integer)
return StageDataCommitQueue;


function compactData(data: InstructionStateArray; mask: std_logic_vector) return InstructionStateArray;
function compactMask(data: InstructionStateArray; mask: std_logic_vector) return std_logic_vector;


function stageCQNext3(content: StageDataCommitQueue; newContent: InstructionStateArray;
		livingMask: std_logic_vector;
		ready: std_logic_vector;
		outWidth: integer;
		nFull, nOut, nIn: integer)
return StageDataCommitQueue;


end ProcLogicCQ;



package body ProcLogicCQ is

function getSendingFromCQ(livingMask: std_logic_vector) return std_logic_vector is
	variable res: std_logic_vector(0 to PIPE_WIDTH-1) := (others=>'0');
begin
	for i in 0 to PIPE_WIDTH-1 loop
		if livingMask(i) = '1' then
			res(i) := '1';
		else
			exit;
		end if;
	end loop;	
	return res;
end function;

function stageCQNext(content: StageDataCommitQueue; newContent: InstructionStateArray;
		livingMask: std_logic_vector;
		ready: std_logic_vector; routes: IntArray; nFull, nOut, nIn: integer)
return StageDataCommitQueue is
	variable res: StageDataCommitQueue := (fullMask => (others=>'0'), 
														data => (others=>defaultInstructionState));
	variable j: integer;															
begin
	for i in 0 to content.data'length-1 loop -- to livingContent'length - nOut - 1 loop
		if i >= content.data'length - nOut then
			exit;
		end if;
		if livingMask(i + nOut) = '1' then
			res.data(i) := content.data(i + nOut);	
		end if;
		res.fullMask(i) := content.fullMask(i + nOut);	
	end loop;
	
	for i in 0 to ready'length-1 loop --  ready'range loop
		j := routes(i);
		if ready(i) = '1' and j >= 0 and j < content.data'length then
			res.data(j) := newContent(i);
			res.fullMask(j) := '1';
		end if;
	end loop;
	return res;		
end function;

function stageCQNext2(content: StageDataCommitQueue; newContent: InstructionStateArray;
		livingMask: std_logic_vector;
		ready: std_logic_vector;
		vecA, vecB, vecC, vecD: std_logic_vector; 
		nFull, nOut, nIn: integer)
return StageDataCommitQueue is
	variable res: StageDataCommitQueue := (fullMask => (others=>'0'), 
														data => (others=>defaultInstructionState));
	variable j: integer;
	variable newFullMask: std_logic_vector(0 to content.fullMask'length-1) := (others => '0');
		constant CLEAR_EMPTY_SLOTS_CQ: boolean := false;
begin
	-- CAREFUL: even when not clearing empty slots, result tags probably should be cleared!
	--				It's to prevent reading of fake results from empty slots
	if not CLEAR_EMPTY_SLOTS_CQ then
		res := content;
	end if;	
	
	for i in 0 to content.data'length-1 loop -- to livingContent'length - nOut - 1 loop
		if i >= content.data'length - nOut then
			exit;
		end if;

		res.data(i) := content.data(i + nOut);		
		if livingMask(i + nOut) = '0' and CLEAR_EMPTY_SLOTS_CQ then
			res.data(i) := defaultInstructionState;	
		end if;
		
		newFullMask(i) := content.fullMask(i + nOut);
	end loop;
	res.fullMask := newFullMask;
	
	
	for i in 0 to livingMask'length-1 loop --  ready'range loop			
		if (vecA(i) and ready(0)) = '1' then 
			res.data(i) := newContent(0);
			res.fullMask(i) := '1';
		elsif (vecB(i) and ready(1)) = '1' then
			res.data(i) := newContent(1);	
			res.fullMask(i) := '1';			
		elsif (vecC(i) and ready(2)) = '1' then
			res.data(i) := newContent(2);			
			res.fullMask(i) := '1';			
		elsif (vecD(i) and ready(3)) = '1' then
			res.data(i) := newContent(3);	
			res.fullMask(i) := '1';			
		end if;		
	end loop;
	
	-- CAREFUL! Clearing tags in empty slots, to avoid incorrect info about available results!
	for i in 0 to res.fullMask'length-1 loop
		if res.fullMask(i) = '0' then
			res.data(i).physicalDestArgs.d0 := (others => '0');
		end if;
		
		-- TEMP: also clear unneeded data for all instructions
		res.data(i).virtualArgs := defaultVirtualArgs;
		--	res.data(i).virtualDestArgs := defaultVirtualDestArgs;
		res.data(i).constantArgs := defaultConstantArgs; -- c0 needed for sysMtc if not using temp reg in Exec
		res.data(i).argValues := defaultArgValues;
		res.data(i).basicInfo := defaultBasicInfo;
		res.data(i).bits := (others => '0');
	end loop;
	
	return res;		
end function;
 


function compactData(data: InstructionStateArray; mask: std_logic_vector) return InstructionStateArray is
	variable res: InstructionStateArray(0 to 3) := --data(0 to 3);
														(data(1), data(2), data(0), data(3));
	variable k: integer := 0;
begin
	res(k) := data(1);
	if mask(1) = '1' then
		k := k + 1;
	end if;
	
	res(k) := data(2);
	if mask(2) = '1' then
		k := k + 1;
	end if;

	res(k) := data(0);	
	if mask(0) = '1' then
		k := k + 1;
	end if;	

	res(k) := data(3);	
	if mask(3) = '1' then
		k := k + 1;
	end if;
	
	return res;
end function;


function compactMask(data: InstructionStateArray; mask: std_logic_vector) return std_logic_vector is
	variable res: std_logic_vector(0 to 3) := (others => '0');
	variable k: integer := 0;
begin
	res(k) := mask(1);
	if mask(1) = '1' then
		k := k + 1;
	end if;
	
	res(k) := mask(2);
	if mask(2) = '1' then
		k := k + 1;
	end if;

	res(k) := mask(0);	
	if mask(0) = '1' then
		k := k + 1;
	end if;	
	
	res(k) := mask(3);	
	if mask(3) = '1' then
		k := k + 1;
	end if;
	
	return res;
end function;



function stageCQNext3(content: StageDataCommitQueue; newContent: InstructionStateArray;
		livingMask: std_logic_vector;
		ready: std_logic_vector;
		outWidth: integer;
		nFull, nOut, nIn: integer)
return StageDataCommitQueue is
	variable res: StageDataCommitQueue := (fullMask => (others=>'0'), 
														data => (others=>defaultInstructionState));
	variable contentExtended: InstructionStateArray(0 to CQ_SIZE+4-1) := 
								content.data & newContent;
	variable dataTemp: InstructionStateArray(0 to CQ_SIZE+4-1) := (others => defaultInstructionState);
	variable fullMaskTemp: std_logic_vector(0 to CQ_SIZE+4-1) := (others => '0');
		
	variable j: integer;
	variable k: integer := 0;
	variable newFullMask: std_logic_vector(0 to content.fullMask'length-1) := (others => '0');
		constant CLEAR_EMPTY_SLOTS_CQ: boolean := false;
		
	variable newCompactedData: InstructionStateArray(0 to 3);
	variable newCompactedMask: std_logic_vector(0 to 3);
begin
	newCompactedData := newContent; --compactData(newContent, ready);
	newCompactedMask := ready; --compactMask(newContent, ready);
	-- CAREFUL: even when not clearing empty slots, result tags probably should be cleared!
	--				It's to prevent reading of fake results from empty slots
	if not CLEAR_EMPTY_SLOTS_CQ then
		dataTemp := contentExtended; -- content.data & newCompactedData;
	end if;	

--			for i in 0 to content.data'length-1 loop -- to livingContent'length - nOut - 1 loop
--				if i < nFull - nOut then
--					dataTemp(i) := content.data(i + nOut);		
--					fullMaskTemp(i) := '1'; -- content.fullMask(i + nOut);
--				elsif i < nFull - nOut + 4 then
--					dataTemp(i) := newCompactedData(k);
--					fullMaskTemp(i) := newCompactedMask(k);
--					k := k + 1;
--				else
--					--fullMaskTemp(i) := '0';
--				end if;
--			end loop;	
		
		for i in 0 to contentExtended'length - 1 - outWidth loop
			contentExtended(i) := contentExtended(i + outWidth);
		end loop;
		
		for i in 0 to content.data'length-1 loop -- to livingContent'length - nOut - 1 loop
			if i < nFull - nOut then
				dataTemp(i) := contentExtended(i);		
				fullMaskTemp(i) := '1'; -- content.fullMask(i + nOut);
			elsif i < nFull - nOut + 4 then
				dataTemp(i) := newCompactedData(k);
				fullMaskTemp(i) := newCompactedMask(k);
				k := k + 1;
			else
				dataTemp(i) := contentExtended(i);
				--fullMaskTemp(i) := '0';
			end if;
		end loop;		
		
		
	res.data := dataTemp(0 to CQ_SIZE-1);
	res.fullMask := fullMaskTemp(0 to CQ_SIZE-1);
		
	-- CAREFUL! Clearing tags in empty slots, to avoid incorrect info about available results!
	for i in 0 to res.fullMask'length-1 loop
		if res.fullMask(i) = '0' then
			res.data(i).physicalDestArgs.d0 := (others => '0');
		end if;
		
		-- TEMP: also clear unneeded data for all instructions
		res.data(i).virtualArgs := defaultVirtualArgs;
		--	res.data(i).virtualDestArgs := defaultVirtualDestArgs;
		res.data(i).constantArgs := defaultConstantArgs; -- c0 needed for sysMtc if not using temp reg in Exec
		res.data(i).argValues := defaultArgValues;
		res.data(i).basicInfo := defaultBasicInfo;
		res.data(i).bits := (others => '0');
	end loop;
	
	return res;		
end function;

end ProcLogicCQ;
