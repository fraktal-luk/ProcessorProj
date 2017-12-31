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


package Viewing is

	type IssueView is record
		acceptingVecA, acceptingVecB, acceptingVecC, acceptingVecD, acceptingVecE:
													std_logic_vector(0 to PIPE_WIDTH-1);
		queueSendingA, queueSendingB, queueSendingC, queueSendingD, queueSendingE: std_logic;
		queueDataA, queueDataB, queueDataC, queueDataD, queueDataE: InstructionState;
		---
		issueAcceptingA, issueAcceptingB, issueAcceptingC, issueAcceptingD, issueAcceptingE: std_logic;
		sendingSchedA, sendingSchedB, sendingSchedC, sendingSchedD, sendingSchedE,
			execAcceptingA, execAcceptingB, execAcceptingC, execAcceptingD, execAcceptingE: std_logic;
		dataOutSchedA, dataOutSchedB, dataOutSchedC, dataOutSchedD, dataOutSchedE: InstructionState;		
	end record;

	constant DEFAULT_ISSUE_VIEW: IssueView := (
		acceptingVecA => (others => '0'), 
		acceptingVecB => (others => '0'), 
		acceptingVecC => (others => '0'), 
		acceptingVecD => (others => '0'), 
		acceptingVecE => (others => '0'),
		queueSendingA => '0',
		queueSendingB => '0',
		queueSendingC => '0',
		queueSendingD => '0',
		queueSendingE => '0',
		queueDataA => DEFAULT_INSTRUCTION_STATE,
		queueDataB => DEFAULT_INSTRUCTION_STATE,
		queueDataC => DEFAULT_INSTRUCTION_STATE,
		queueDataD => DEFAULT_INSTRUCTION_STATE,
		queueDataE => DEFAULT_INSTRUCTION_STATE,
		sendingSchedA => '0',
		sendingSchedB => '0',
		sendingSchedC => '0',
		sendingSchedD => '0',
		sendingSchedE => '0',
		issueAcceptingA => '0',
		issueAcceptingB => '0',
		issueAcceptingC => '0',
		issueAcceptingD => '0',
		issueAcceptingE => '0',
		execAcceptingA => '0',
		execAcceptingB => '0',
		execAcceptingC => '0',
		execAcceptingD => '0',
		execAcceptingE => '0',
		dataOutSchedA => DEFAULT_INSTRUCTION_STATE,
		dataOutSchedB => DEFAULT_INSTRUCTION_STATE,
		dataOutSchedC => DEFAULT_INSTRUCTION_STATE,
		dataOutSchedD => DEFAULT_INSTRUCTION_STATE,
		dataOutSchedE => DEFAULT_INSTRUCTION_STATE		
	);
		
	function getIssueView(iqOutputArr, schedOutputArr: InstructionSlotArray;
								 iqAcceptingVecArr: SLVA;
								 issueAcceptingArr, execAcceptingArr: std_logic_vector)
	return IssueView;

end Viewing;



package body Viewing is


	function getIssueView(iqOutputArr, schedOutputArr: InstructionSlotArray;
								 iqAcceptingVecArr: SLVA;
								 issueAcceptingArr, execAcceptingArr: std_logic_vector)
	return IssueView is
		variable res: IssueView := DEFAULT_ISSUE_VIEW;
		variable queueSendingArr, schedSendingArr: std_logic_vector(0 to 5-1) := (others => '0');
		variable queueDataArr, schedDataArr: InstructionStateArray(0 to 5-1)
								:= (others => DEFAULT_INSTRUCTION_STATE);
	begin
			queueSendingArr := extractFullMask(iqOutputArr); -- For viewing
			queueDataArr := extractData(iqOutputArr); -- For viewing
		
		res.queueSendingA := queueSendingArr(0);
		res.queueSendingB := queueSendingArr(1);
		res.queueSendingC := queueSendingArr(2);
		res.queueSendingD := queueSendingArr(3);
		res.queueSendingE := queueSendingArr(4);
		
		res.queueDataA := queueDataArr(0);
		res.queueDataB := queueDataArr(1);
		res.queueDataC := queueDataArr(2);
		res.queueDataD := queueDataArr(3);
		res.queueDataE := queueDataArr(4);
		
		res.acceptingVecA := iqAcceptingVecArr(0);
		res.acceptingVecB := iqAcceptingVecArr(1);
		res.acceptingVecC := iqAcceptingVecArr(2);
		res.acceptingVecD := iqAcceptingVecArr(3);
		res.acceptingVecE := iqAcceptingVecArr(4);

			schedSendingArr := extractFullMask(schedOutputArr); -- Only for viewing
			schedDataArr := extractData(schedOutputArr); -- Only for viewing

			res.issueAcceptingA := issueAcceptingArr(0);
			res.issueAcceptingB := issueAcceptingArr(1);
			res.issueAcceptingC := issueAcceptingArr(2);
			res.issueAcceptingD := issueAcceptingArr(3);
			res.issueAcceptingE := issueAcceptingArr(4);

			res.execAcceptingA := execAcceptingArr(0);
			res.execAcceptingB := execAcceptingArr(1);
			res.execAcceptingC := execAcceptingArr(2);
			res.execAcceptingD := execAcceptingArr(3);
			res.execAcceptingE := execAcceptingArr(4);
		
			res.dataOutSchedA := schedDataArr(0);
			res.dataOutSchedB := schedDataArr(1);
			res.dataOutSchedC := schedDataArr(2);
			res.dataOutSchedD := schedDataArr(3);
			res.dataOutSchedE := schedDataArr(4);
			
			-- Not used
			res.sendingSchedA := schedSendingArr(0);
			res.sendingSchedB := schedSendingArr(1);
			res.sendingSchedC := schedSendingArr(2);
			res.sendingSchedD := schedSendingArr(3);
			res.sendingSchedE := schedSendingArr(4);		
		
		return res;
	end function;
 
end Viewing;
