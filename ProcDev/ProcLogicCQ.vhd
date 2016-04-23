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
	return res;		
end function;
 
end ProcLogicCQ;
