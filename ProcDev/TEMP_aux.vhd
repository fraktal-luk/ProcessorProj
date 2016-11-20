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


package TEMP_aux is


--		type ArgumentStatusInfo is record
--			-- Basic state
--			argStored: std_logic_vector(0 to 2); -- ready before
--			argNew: std_logic_vector(0 to 2);   -- ready from this cycle
--			argRegs: std_logic_vector(0 to 2);  -- can be read from reg for next cycle
--			argNext: std_logic_vector(0 to 2);  -- expected in forw. network in next cycle
--			-- Derived state
--			readyNow: std_logic_vector(0 to 2);  -- stored/forw. netw.
--			readyNext: std_logic_vector(0 to 2); -- forw. network next cycle
--			notReady: std_logic_vector(0 to 2);  -- won't be ready in next cycle
--			-- Scheduling status
--			allReady: std_logic; -- can go to exec now
--			allNext: std_logic;  -- can be dispatched now (to exec next cycle)
--			-- Completion info
--			filling: std_logic_vector(0 to 2); -- will be updated this cycle from forw. network/regs
--			locs: SmallNumberArray(0 to 2);	  -- location in FN
--			vals: MwordArray(0 to 2);			  -- arg values
--			locsNext: SmallNumberArray(0 to 2);	
--		end record;
--
--		type ArgumentStatusInfoArray is array(integer range <>) of ArgumentStatusInfo;


	
			type ArgStatusStruct is record
				readyAll: std_logic;
				readyNextAll: std_logic;
				ready: std_logic_vector(0 to 2);
				locs: SmallNumberArray(0 to 2);
				vals: MwordArray(0 to 2);
				missing: std_logic_vector(0 to 2);
					--C_missing: std_logic_vector(0 to 2);					
				--readyReg: std_logic_vector(0 to 2);
				readyNow: std_logic_vector(0 to 2);
				readyNext: std_logic_vector(0 to 2);
				stillMissing: std_logic_vector(0 to 2);
					--C_stillMissing: std_logic_vector(0 to 2);
				nMissing: integer;
				nextMissing: std_logic_vector(0 to 2);
				nMissingNext: integer;					
			end record;

			type ArgStatusStructArray is array(integer range <>) of ArgStatusStruct;



function getArgStatus(ai: ArgStatusInfo;
							ins: InstructionState;
							 living: std_logic)
return ArgStatusStruct;	

function getArgStatusArray(aiA: ArgStatusInfoArray;
									insArr: InstructionStateArray;
									livingMask: std_logic_vector)
return ArgStatusStructArray;

end TEMP_aux;



package body TEMP_aux is

function getArgStatus(ai: ArgStatusInfo;
							ins: InstructionState;
							living: std_logic)
return ArgStatusStruct is
	variable res: ArgStatusStruct;
begin
	res.ready := ins.argValues.readyBefore or ins.argValues.readyNow;	
	res.readyNext := ins.argValues.readyNext;

	res.missing := ins.argValues.missing;
	res.readyNow := res.ready;
	
	res.stillMissing := res.missing and not res.readyNow;
			
	res.nextMissing := res.stillMissing and not res.readyNext;
	res.nMissing := countOnes(res.missing);
	res.nMissingNext := countOnes(res.nextMissing);

	res.readyAll := living and not isNonzero(res.stillMissing);
	res.readyNextAll := living and not isNonzero(res.nextMissing);		
	return res;
end function;
	
	
function getArgStatusArray(aiA: ArgStatusInfoArray;
									insArr: InstructionStateArray;
									livingMask: std_logic_vector)
return ArgStatusStructArray is
	variable res: ArgStatusStructArray(livingMask'range);
begin
	for i in res'range loop
		res(i) := getArgStatus(aiA(i), insArr(i), livingMask(i));
	end loop;
	return res;
end function;	

 
end TEMP_aux;
