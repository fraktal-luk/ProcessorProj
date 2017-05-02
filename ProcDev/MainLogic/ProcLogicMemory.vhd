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

use work.Decoding2.all;

use work.TEMP_DEV.all;
use work.GeneralPipeDev.all;


package ProcLogicMemory is

	function findReadySQ(content: InstructionStateArray; livingMask: std_logic_vector;
								nextAccepting: std_logic)
	return StageDataMulti;

	function findFirstFilled(content: InstructionStateArray; livingMask: std_logic_vector;
									 nextAccepting: std_logic)
	return std_logic_vector;

function findCommittingSQ(content: InstructionStateArray; livingMask: std_logic_vector;
								  committingTag: SmallNumber; send: std_logic) return StageDataMulti;							

function storeQueueNext(content: InstructionStateArray;
									  livingMask: std_logic_vector;
									  newContent: InstructionStateArray;
									  newMask: std_logic_vector;
									  nLiving: integer;
									  sending: integer;
									  receiving: std_logic;
									  dataA, dataD: InstructionState;
									  wrA, wrD: std_logic;
									  mA, mD: std_logic_vector;
									  clearCompleted: boolean									  
									  ) return InstructionStateArray;

				function lmQueueNext(content: InstructionStateArray;
									  livingMask: std_logic_vector;
									  newContent: InstructionStateArray;
									  newMask: std_logic_vector;
									  nLiving: integer;
									  sendingVec: std_logic_vector; -- shows which one sending
									  receiving: std_logic;
									  dataA, dataD: InstructionState;
									  wrA, wrD: std_logic;
									  mA, mD: std_logic_vector;
									  clearCompleted: boolean
									  ) return InstructionStateArray;

function lmMaskNext(livingMask: std_logic_vector;
					  newMask: std_logic_vector;
					  nLivingIn: integer;
					  sendingVec: std_logic_vector;
					  receiving: std_logic) return std_logic_vector;
					  
end ProcLogicMemory;



package body ProcLogicMemory is

			function findReadySQ(content: InstructionStateArray; livingMask: std_logic_vector;
										  nextAccepting: std_logic)
			return StageDataMulti is
				variable res: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
			begin
				res.data := content(0 to PIPE_WIDTH-1);
				if nextAccepting = '0' then
					return res;
				end if;
				
				for i in 0 to PIPE_WIDTH-1 loop
					if (livingMask(i) and content(i).controlInfo.completed
										  and	content(i).controlInfo.completed2) = '0' then
						exit;
					end if;
					res.fullMask(i) := '1';
				end loop;
				
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
													  committingTag: SmallNumber; send: std_logic) return StageDataMulti is
							variable res: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
						begin
							res.data := content(0 to PIPE_WIDTH-1);
							for i in 0 to PIPE_WIDTH-1 loop
								if (content(i).groupTag(SMALL_NUMBER_SIZE-1 downto LOG2_PIPE_WIDTH)
									= committingTag(SMALL_NUMBER_SIZE-1 downto LOG2_PIPE_WIDTH))
									and (livingMask(i) = '1') and (send = '1')
								then	
									res.fullMask(i) := '1';
								end if;	
							end loop;

							return res;
						end function;
							
				function storeQueueNext(content: InstructionStateArray;
									  livingMask: std_logic_vector;
									  newContent: InstructionStateArray;
									  newMask: std_logic_vector;
									  nLiving: integer;
									  sending: integer;
									  receiving: std_logic;
									  dataA, dataD: InstructionState;
									  wrA, wrD: std_logic;
									  mA, mD: std_logic_vector;
									  clearCompleted: boolean
									  ) return InstructionStateArray is
					constant LEN: integer := content'length;
					variable tempContent, tempNewContent: InstructionStateArray(0 to LEN + PIPE_WIDTH-1)
									:= (others => DEFAULT_INSTRUCTION_STATE);
					variable tempMask: std_logic_vector(0 to LEN + PIPE_WIDTH-1) := (others => '0');
					variable res: InstructionStateArray(0 to LEN-1)
											:= (others => DEFAULT_INSTRUCTION_STATE);--content;
					variable outMask: std_logic_vector(0 to LEN-1) := (others => '0');
					variable c1, c2: std_logic := '0';
					variable sv: Mword := (others => '0');
						variable sh: integer := sending;
				begin							
					tempContent(0 to LEN-1) := content;
					for i in 0 to LEN-1 loop
						tempNewContent(i) := newContent((nLiving-sh + i) mod PIPE_WIDTH);
					end loop;
					
					tempMask(0 to LEN-1) := livingMask;

					-- Shift by n of sending
					tempContent(0 to LEN - 1) := tempContent(sh to sh + LEN-1);
					-- CAREFUL: tempMask must have enough zeros at the end to clear outdated 'ones'!
					outMask(0 to LEN-1) := tempMask(sh to sh + LEN-1); 
					
					for i in 0 to LEN-1 loop
						res(i).basicInfo := DEFAULT_BASIC_INFO;
							c1 := res(i).controlInfo.completed;
							c2 := res(i).controlInfo.completed2;
							res(i).controlInfo := DEFAULT_CONTROL_INFO;
							res(i).controlInfo.completed := c1;
							res(i).controlInfo.completed2 := c2;
						res(i).bits := (others => '0');
						res(i).classInfo := DEFAULT_CLASS_INFO;
						res(i).constantArgs := DEFAULT_CONSTANT_ARGS;
						res(i).virtualArgs := DEFAULT_VIRTUAL_ARGS;
						res(i).virtualDestArgs := DEFAULT_VIRTUAL_DEST_ARGS;
						res(i).physicalArgs := DEFAULT_PHYSICAL_ARGS;
						res(i).physicalDestArgs := DEFAULT_PHYSICAL_DEST_ARGS;
						
						res(i).numberTag := (others => '0');
						res(i).gprTag := (others => '0');
						
							sv := res(i).argValues.arg2;
							res(i).argValues := DEFAULT_ARG_VALUES;
							res(i).argValues.arg2 := sv;
						res(i).target := (others => '0');
						
						if outMask(i) = '1' then									
							res(i).groupTag := tempContent(i).groupTag;
							res(i).operation := tempContent(i).operation; --(Memory, store);														
						else
							res(i).groupTag := tempNewContent(i).groupTag;
							res(i).operation := tempNewContent(i).operation; --(Memory, store);							
						end if;
															
						if (wrA and mA(i)) = '1' then
							res(i).argValues.arg1 := dataA.result;
							res(i).controlInfo.completed := '1';
						elsif outMask(i) = '1' then
							res(i).argValues.arg1 := tempContent(i).argValues.arg1;
							res(i).controlInfo.completed := tempContent(i).controlInfo.completed;									
						else
							res(i).argValues.arg1 := tempNewContent(i).argValues.arg1;
							if clearCompleted then
								res(i).controlInfo.completed := '0';
							else
								res(i).controlInfo.completed := tempNewContent(i).controlInfo.completed;
							end if;	
						end if;

						if (wrD and mD(i)) = '1' then									
							res(i).argValues.arg2 := dataD.argValues.arg2;
							res(i).controlInfo.completed2 := '1';
						elsif outMask(i) = '1' then
							res(i).argValues.arg2 := tempContent(i).argValues.arg2;
							res(i).controlInfo.completed2 := tempContent(i).controlInfo.completed2;
						else	
							res(i).argValues.arg2 := tempNewContent(i).argValues.arg2;
							if clearCompleted then
								res(i).controlInfo.completed2 := '0';
							else
								res(i).controlInfo.completed2 := tempNewContent(i).controlInfo.completed2;
							end if;
						end if;

					end loop;
					
					return res;
				end function;


				function lmQueueNext(content: InstructionStateArray;
									  livingMask: std_logic_vector;
									  newContent: InstructionStateArray;
									  newMask: std_logic_vector;
									  nLiving: integer;
									  sendingVec: std_logic_vector; -- shows which one sending
									  receiving: std_logic;
									  dataA, dataD: InstructionState;
									  wrA, wrD: std_logic;
									  mA, mD: std_logic_vector;
									  clearCompleted: boolean
									  ) return InstructionStateArray is
					constant LEN: integer := content'length;
					variable tempContent, tempNewContent: InstructionStateArray(0 to LEN + PIPE_WIDTH-1)
									:= (others => DEFAULT_INSTRUCTION_STATE);
					variable tempMask: std_logic_vector(0 to LEN + PIPE_WIDTH-1) := (others => '0');
					variable res: InstructionStateArray(0 to LEN-1)
											:= (others => DEFAULT_INSTRUCTION_STATE);--content;
					variable outMask: std_logic_vector(0 to LEN-1) := (others => '0');
					variable c1, c2: std_logic := '0';
					variable sv: Mword := (others => '0');
					variable sh: integer := 0;
					variable shifted: boolean := false;
				begin
					if isNonzero(sendingVec) = '1' then
						sh := 1;
					end if;
				
					tempContent(0 to LEN-1) := content;
					for i in 0 to LEN-1 loop
						tempNewContent(i) := newContent((nLiving-sh + i) mod PIPE_WIDTH);
					end loop;
					
					tempMask(0 to LEN-1) := livingMask;

					-- Shift by n of sending
					for i in 0 to LEN-1 loop
						if sendingVec(i) = '1' then
							shifted := true;
						end if;
						if shifted then
							tempContent(i) := tempContent(i+1);
						else
							null;
						end if;
					end loop;
					
					-- CAREFUL: tempMask must have enough zeros at the end to clear outdated 'ones'!
					outMask(0 to LEN-1) := tempMask(sh to sh + LEN-1); 
					
					for i in 0 to LEN-1 loop
						res(i).basicInfo := DEFAULT_BASIC_INFO;
							c1 := res(i).controlInfo.completed;
							c2 := res(i).controlInfo.completed2;
							res(i).controlInfo := DEFAULT_CONTROL_INFO;
							res(i).controlInfo.completed := c1;
							res(i).controlInfo.completed2 := c2;
						res(i).bits := (others => '0');
							res(i).operation := (Memory, store);
						res(i).classInfo := DEFAULT_CLASS_INFO;
						res(i).constantArgs := DEFAULT_CONSTANT_ARGS;
						res(i).virtualArgs := DEFAULT_VIRTUAL_ARGS;
						res(i).virtualDestArgs := DEFAULT_VIRTUAL_DEST_ARGS;
						res(i).physicalArgs := DEFAULT_PHYSICAL_ARGS;
						res(i).physicalDestArgs := DEFAULT_PHYSICAL_DEST_ARGS;
						
						res(i).numberTag := (others => '0');
						res(i).gprTag := (others => '0');
						
							sv := res(i).argValues.arg2;
							res(i).argValues := DEFAULT_ARG_VALUES;
							res(i).argValues.arg2 := sv;
						res(i).target := (others => '0');
						
						if outMask(i) = '1' then									
							res(i).groupTag := tempContent(i).groupTag;
						else
							res(i).groupTag := tempNewContent(i).groupTag;										
						end if;
															
						if (wrA and mA(i)) = '1' then
							res(i).argValues.arg1 := dataA.result;
							res(i).controlInfo.completed := '1';
						elsif outMask(i) = '1' then
							res(i).argValues.arg1 := tempContent(i).argValues.arg1;
							res(i).controlInfo.completed := tempContent(i).controlInfo.completed;									
						else
							res(i).argValues.arg1 := tempNewContent(i).argValues.arg1;
							if clearCompleted then
								res(i).controlInfo.completed := '0';
							else
								res(i).controlInfo.completed := tempNewContent(i).controlInfo.completed;
							end if;	
						end if;

						if (wrD and mD(i)) = '1' then									
							res(i).argValues.arg2 := dataD.argValues.arg2;
							res(i).controlInfo.completed2 := '1';
						elsif outMask(i) = '1' then
							res(i).argValues.arg2 := tempContent(i).argValues.arg2;
							res(i).controlInfo.completed2 := tempContent(i).controlInfo.completed2;
						else	
							res(i).argValues.arg2 := tempNewContent(i).argValues.arg2;
							if clearCompleted then
								res(i).controlInfo.completed2 := '0';
							else
								res(i).controlInfo.completed2 := tempNewContent(i).controlInfo.completed2;
							end if;
						end if;

					end loop;
					
					return res;
				end function;

function lmMaskNext(livingMask: std_logic_vector;
					  newMask: std_logic_vector;
					  nLivingIn: integer;
					  sendingVec: std_logic_vector;
					  receiving: std_logic) return std_logic_vector is
	variable nLiving: integer := nLivingIn;
	constant LEN: integer := livingMask'length;
	variable tempMask: std_logic_vector(0 to LEN + PIPE_WIDTH-1) := (others => '0');
	variable outMask: std_logic_vector(0 to LEN-1) := (others => '0');
	variable shifted: boolean := false;
begin
	if nLiving < 0  or nLiving > LEN then
		nLiving := 0;
	end if;
		
	tempMask(0 to LEN-1) := livingMask;	
	for i in 0 to LEN-1 loop
		if sendingVec(i) = '1' then
			shifted := true;
		end if;	
	
		if shifted then
			tempMask(i) := tempMask(i+1);
		else
			tempMask(i) := tempMask(i);
		end if;
	end loop;

	-- Append new data
	if receiving = '1' then
		if shifted then
			tempMask(nLiving-1 to nLiving-1 + PIPE_WIDTH-1) := newMask;
		else
			tempMask(nLiving to nLiving + PIPE_WIDTH-1) := newMask;
		end if;
	end if;

	outMask := tempMask(0 to LEN-1);
	
	return outMask;
end function;

end ProcLogicMemory;
