----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:57:56 12/11/2016 
-- Design Name: 
-- Module Name:    MemoryUnit - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


use work.ProcBasicDefs.all;
use work.Helpers.all;

use work.ProcInstructionsNew.all;

use work.NewPipelineData.all;

use work.GeneralPipeDev.all;

use work.TEMP_DEV.all;

use work.ProcComponents.all;

use work.ProcLogicFront.all;

use work.ProcLogicExec.all;


entity LoadQueue is
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;

			acceptingOut: out std_logic;
			prevSending: in std_logic;
			dataIn: in StageDataMulti;

		loadAddressWr: in std_logic;
		loadValueWr: in std_logic;

		loadAddressDataIn: in InstructionState;
		loadValueDataIn: in InstructionState;
		
			committing: in std_logic;
			groupCtrNext: in SmallNumber;
			
		execEventSignal: in std_logic;
		execCausing: in InstructionState;

		nextAccepting: in std_logic;
		
		acceptingOutLQ: out std_logic;
		sendingLQOut: out std_logic;
		dataOutLQ: out InstructionState
	);
end LoadQueue;



architecture Behavioral of LoadQueue is
	
					constant LQ_SIZE: integer := 4;
				
					signal content: InstructionSlotArray(0 to LQ_SIZE-1) := (others => DEFAULT_INSTRUCTION_SLOT);
					
	signal content2, contentK, content2U, content2Next, content2Updated, content2ToUpdate,
					content3: InstructionSlotArray(0 to LQ_SIZE-1)
								:= (others => DEFAULT_INSTRUCTION_SLOT);
						signal contentTmp: InstructionSlotArray(-1 to LQ_SIZE-1) 
								:= (others => DEFAULT_INSTRUCTION_SLOT);
					
					
					-- TODO: use completed + completed2 for readyA + readyD ???
					signal readyA, readyD, readyAD, readyMask: std_logic_vector(0 to LQ_SIZE-1) := (others => '0');
					
					signal wrAddress, wrData, sameTag: std_logic := '0';
					signal dataA, dataD: InstructionState := DEFAULT_INSTRUCTION_STATE;
					
					signal posA, posD, posSend, posSendTemp: integer := 0; 
					
					signal fullMask, livingMask, livingMask2, killMask: std_logic_vector(0 to LQ_SIZE-1)
											:= (others => '0');

			signal sendingLQ: std_logic := '0';

	constant zeroMask: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');

		signal lqOutData: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

		signal content2DataNext: InstructionStateArray(0 to LQ_SIZE-1)
												:= (others => DEFAULT_INSTRUCTION_STATE);
		signal content2MaskNext, matchingA, matchingD,
								matchingShA, matchingShD: std_logic_vector(0 to LQ_SIZE-1) := (others => '0'); 

	signal bufferDrive: FlowDriveBuffer := (killAll => '0', lockAccept => '0', lockSend => '0',
																others=>(others=>'0'));
	signal bufferResponse: FlowResponseBuffer := (others=>(others=>'0'));
					
					function writeToLQ(content: InstructionSlotArray;
											 loadAddressData: InstructionState;
											 loadValueData: InstructionState;
											 wrAddress: std_logic; wrValue: std_logic) return InstructionSlotArray is
						constant LEN: integer := content'length;
						variable res: InstructionSlotArray(0 to LEN-1) := content;
						variable foundMatchA, foundMatchV: std_logic := '0';
					begin

						-- Find where to put addressData
						for i in 0 to LEN-1 loop
							if wrAddress = '1' then
							
								-- When match found:
								if loadAddressData.groupTag = content(i).ins.groupTag and content(i).full = '1' then
									res(i).ins.argValues.arg1 := loadAddressData.result;
									res(i).ins.controlInfo.completed := '1';
									foundMatchA := '1';
								--	exit;
								end if;
							end if;	
								--return res;
						
						-- Find where to put value data
							if wrValue = '1' then
								-- When match found (it includes new address op if it is begin written this cycle!)
								if loadValueData.groupTag = content(i).ins.groupTag and content(i).full = '1' then
									res(i).ins.argValues.arg2 := loadValueData.argValues.arg2;
									res(i).ins.controlInfo.completed2 := '1';
									foundMatchV := '1';
								--	exit;
								end if;
							end if;	
						end loop;
					
						return res;
					end function;					
					
							function findSendingLQ(content: InstructionStateArray; livingMask: std_logic_vector;
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
														  and	content(i).controlInfo.completed) = '0' then
										exit;
									end if;
									res.fullMask(i) := '1';
								end loop;
								
								return res;
							end function;
							
							
							function lq2Next(content: InstructionStateArray;
												  livingMask: std_logic_vector;
												  newContent: InstructionStateArray;
												  newMask: std_logic_vector;
												  nLiving: integer;
												  sending: integer;
												  receiving: std_logic) return InstructionStateArray is
								variable tempContent: InstructionStateArray(0 to LQ_SIZE + PIPE_WIDTH-1)
												:= (others => DEFAULT_INSTRUCTION_STATE);
								variable tempMask: std_logic_vector(0 to LQ_SIZE + PIPE_WIDTH-1) := (others => '0');
								variable res: InstructionStateArray(0 to LQ_SIZE-1) := content;
								variable outMask: std_logic_vector(0 to LQ_SIZE-1) := (others => '0');
								variable c1, c2: std_logic := '0';
								variable lv: Mword := (others => '0');
									variable sh: integer := sending;
							begin
								if sh < 0 then sh := 0; end if;
								if sh > 1 then sh := 1; end if; 
							
								tempContent(0 to LQ_SIZE-1) := content;
								tempContent(LQ_SIZE to LQ_SIZE + PIPE_WIDTH-1) := newContent;
								
								tempMask(0 to LQ_SIZE-1) := livingMask;
								
								-- Append new data
								tempContent(nLiving to nLiving + PIPE_WIDTH-1) := newContent;
								if receiving = '1' then
									tempMask(nLiving to nLiving + PIPE_WIDTH-1) := newMask;
								end if;
																
								-- Shift by n of sending
								res(0 to LQ_SIZE - 1) := tempContent(sh to sh + LQ_SIZE-1);
								-- CAREFUL: tempMask must have enough zeros at the end to clear outdated 'ones'!
								outMask(0 to LQ_SIZE-1) := tempMask(sh to sh + LQ_SIZE-1); 
								
								-- 
								--res(nFull - sending to nFull - 
								
								for i in 0 to LQ_SIZE-1 loop
									res(i).basicInfo := DEFAULT_BASIC_INFO;
										c1 := res(i).controlInfo.completed;
										c2 := res(i).controlInfo.completed2;
										res(i).controlInfo := DEFAULT_CONTROL_INFO;
										res(i).controlInfo.completed := c1;
										res(i).controlInfo.completed2 := c2;
									res(i).bits := (others => '0');
										res(i).operation := (Memory, load);
									res(i).classInfo := DEFAULT_CLASS_INFO;
									res(i).constantArgs := DEFAULT_CONSTANT_ARGS;
									res(i).virtualArgs := DEFAULT_VIRTUAL_ARGS;
									res(i).virtualDestArgs := DEFAULT_VIRTUAL_DEST_ARGS;
									res(i).physicalArgs := DEFAULT_PHYSICAL_ARGS;
									res(i).physicalDestArgs := DEFAULT_PHYSICAL_DEST_ARGS;
									
									res(i).numberTag := (others => '0');
									res(i).gprTag := (others => '0');
									
										lv := res(i).argValues.arg2;
										res(i).argValues := DEFAULT_ARG_VALUES;
										res(i).argValues.arg2 := lv;
									res(i).target := (others => '0'); 
								end loop;
								
								return res;
							end function;

							function lq2MaskNext(content: InstructionStateArray;
												  livingMask: std_logic_vector;
												  newContent: InstructionStateArray;
												  newMask: std_logic_vector;
												  nLiving: integer;
												  sending: integer;
												  receiving: std_logic) return std_logic_vector is
								variable tempContent: InstructionStateArray(0 to LQ_SIZE + PIPE_WIDTH-1)
												:= (others => DEFAULT_INSTRUCTION_STATE);
								variable tempMask: std_logic_vector(0 to LQ_SIZE + PIPE_WIDTH-1) := (others => '0');
								variable res: InstructionStateArray(0 to LQ_SIZE-1) := content;
								variable outMask: std_logic_vector(0 to LQ_SIZE-1) := (others => '0');
							begin
								tempContent(0 to LQ_SIZE-1) := content;
								tempContent(LQ_SIZE to LQ_SIZE + PIPE_WIDTH-1) := newContent;
								
								tempMask(0 to LQ_SIZE-1) := livingMask;

									if nLiving >= LQ_SIZE or nLiving < 0 then -- CAREFUL, TODO: use modulo or sth?
										return outMask;
									end if;
								-- Append new data
								tempContent(nLiving to nLiving + PIPE_WIDTH-1) := newContent;
								if receiving = '1' then
									tempMask(nLiving to nLiving + PIPE_WIDTH-1) := newMask;
								end if;

								-- Shift by n of sending
								res(0 to LQ_SIZE - 1) := tempContent(sending to sending + LQ_SIZE-1);
								-- CAREFUL: tempMask must have enough zeros at the end to clear outdated 'ones'!
								outMask(0 to LQ_SIZE-1) := tempMask(sending to sending + LQ_SIZE-1); 
								-- 
								--res(nFull - sending to nFull - 
								
								return outMask;
							end function;

							function lq2Next2(content: InstructionStateArray;
												  livingMask: std_logic_vector;
												  newContent: InstructionStateArray;
												  newMask: std_logic_vector;
												  nLiving: integer;
												  sending: integer;
												  receiving: std_logic;
												  dataA, dataD: InstructionState;
												  wrA, wrD: std_logic;
												  mA, mD: std_logic_vector
												  ) return InstructionStateArray is
								variable tempContent, tempNewContent: InstructionStateArray(0 to LQ_SIZE + PIPE_WIDTH-1)
												:= (others => DEFAULT_INSTRUCTION_STATE);
								variable tempMask: std_logic_vector(0 to LQ_SIZE + PIPE_WIDTH-1) := (others => '0');
								variable res: InstructionStateArray(0 to LQ_SIZE-1)
														:= (others => DEFAULT_INSTRUCTION_STATE);--content;
								variable outMask: std_logic_vector(0 to LQ_SIZE-1) := (others => '0');
								variable c1, c2: std_logic := '0';
								variable lv: Mword := (others => '0');
									variable sh: integer := sending;
							begin
								--return res;
							
								tempContent(0 to LQ_SIZE-1) := content;
								for i in 0 to LQ_SIZE-1 loop
									tempNewContent(i) := newContent((nLiving-sh + i) mod PIPE_WIDTH);
								end loop;
								--	tempNewContent(LQ_SIZE to LQ_SIZE + PIPE_WIDTH-1) := newContent;
								
								tempMask(0 to LQ_SIZE-1) := livingMask;
								
								-- Append new data
								--tempContent(nLiving to nLiving + PIPE_WIDTH-1) := newContent;
								if receiving = '1' then
								--	tempMask(nLiving to nLiving + PIPE_WIDTH-1) := newMask;
								end if;
																
								-- Shift by n of sending
								tempContent(0 to LQ_SIZE - 1) := tempContent(sh to sh + LQ_SIZE-1);
								-- CAREFUL: tempMask must have enough zeros at the end to clear outdated 'ones'!
								outMask(0 to LQ_SIZE-1) := tempMask(sh to sh + LQ_SIZE-1); 
								
								-- 
								--res(nFull - sending to nFull - 
								
								for i in 0 to LQ_SIZE-1 loop
									res(i).basicInfo := DEFAULT_BASIC_INFO;
										c1 := res(i).controlInfo.completed;
										c2 := res(i).controlInfo.completed2;
										res(i).controlInfo := DEFAULT_CONTROL_INFO;
										res(i).controlInfo.completed := c1;
										res(i).controlInfo.completed2 := c2;
									res(i).bits := (others => '0');
										res(i).operation := (Memory, load);
									res(i).classInfo := DEFAULT_CLASS_INFO;
									res(i).constantArgs := DEFAULT_CONSTANT_ARGS;
									res(i).virtualArgs := DEFAULT_VIRTUAL_ARGS;
									res(i).virtualDestArgs := DEFAULT_VIRTUAL_DEST_ARGS;
									res(i).physicalArgs := DEFAULT_PHYSICAL_ARGS;
									res(i).physicalDestArgs := DEFAULT_PHYSICAL_DEST_ARGS;
									
									res(i).numberTag := (others => '0');
									res(i).gprTag := (others => '0');
									
										lv := res(i).argValues.arg2;
										res(i).argValues := DEFAULT_ARG_VALUES;
										res(i).argValues.arg2 := lv;
									res(i).target := (others => '0');
									
									if outMask(i) = '1' then									
										res(i).groupTag := tempContent(i).groupTag;
									else
										res(i).groupTag := tempNewContent(i).groupTag;										
									end if;
									
									--res(i).argValues.arg1 := dataA.result;
									--res(i).argValues.arg2 := dataD.argValues.arg2;
									
									if (wrA and mA(i)) = '1' then
										res(i).argValues.arg1 := dataA.result;
										res(i).controlInfo.completed := '1';
									elsif outMask(i) = '1' then
										res(i).argValues.arg1 := tempContent(i).argValues.arg1;
										res(i).controlInfo.completed := tempContent(i).controlInfo.completed;									
									else
										res(i).argValues.arg1 := tempNewContent(i).argValues.arg1;
										res(i).controlInfo.completed := tempNewContent(i).controlInfo.completed;
									end if;

									if (wrD and mD(i)) = '1' then									
										res(i).argValues.arg2 := dataD.argValues.arg2;
										res(i).controlInfo.completed2 := '1';
									elsif outMask(i) = '1' then
										res(i).argValues.arg2 := tempContent(i).argValues.arg2;
										res(i).controlInfo.completed2 := tempContent(i).controlInfo.completed2;
									else	
										res(i).argValues.arg2 := tempNewContent(i).argValues.arg2;
										res(i).controlInfo.completed2 := tempNewContent(i).controlInfo.completed2;										
									end if;
									
								end loop;
								
								return res;
							end function;


					
					function killInLQ(content: InstructionSlotArray;
											killSig: std_logic; killMask: std_logic_vector)
					return InstructionSlotArray is
						constant LEN: integer := content'length;
						variable res: InstructionSlotArray(0 to LEN-1) := content;
					begin
						if killSig = '0' then
							return res;
						end if;
						
						for i in 0 to LEN-1 loop
							res(i).full := content(i).full and not killMask(i);
						end loop;
						
						return res;
					end function;
					
						signal dummyCommitTag: SmallNumber := (others => '0');
				begin
				
							--	livingMask2 <= extractFullMask(contentK);
							fullMask <= extractFullMask(content2);
								livingMask2 <= fullMask and not killMask;
				
							content3 <= content2;
											--writeToLQ(content2, dataA, dataD, wrAddress, wrData);
				
								matchingA <= findMatching(content2, dataA);
								matchingD <= findMatching(content2, dataD);
							
							matchingShA <= queueMaskNext(--extractData(content2),
																	matchingA,
																--dataIn.data,
																zeroMask,
																 binFlowNum(bufferResponse.living),
																 --binFlowNum(bufferResponse.sending),
																	countOnes(lqOutData.fullMask),
																 prevSending);																

							matchingShD <= queueMaskNext(--extractData(content2),
																	matchingD,
																--dataIn.data,
																zeroMask,
																 binFlowNum(bufferResponse.living),
																 --binFlowNum(bufferResponse.sending),
																	countOnes(lqOutData.fullMask),
																 prevSending);
																 
				
							content2DataNext <= lq2Next2(extractData(content2), livingMask2,
																 dataIn.data, dataIn.fullMask,
																 binFlowNum(bufferResponse.living),
																 --binFlowNum(bufferResponse.sending),
																	countOnes(lqOutData.fullMask),
																 prevSending,
																 dataA, dataD, wrAddress, wrData,
																 matchingShA, matchingShD);

							content2MaskNext <= queueMaskNext(--extractData(content2),
																	livingMask2,
																 --dataIn.data,
																 dataIn.fullMask,
																 binFlowNum(bufferResponse.living),
																 --binFlowNum(bufferResponse.sending),
																	countOnes(lqOutData.fullMask),
																 prevSending);
							content2ToUpdate <= makeSlotArray(content2DataNext, content2MaskNext);
				
							content2Updated <= --writeToLQ(content2ToUpdate, dataA, dataD, wrAddress, wrData);
													 content2ToUpdate;
							content2Next <= content2Updated;
								lqOutData <= findSendingLQ(extractData(content2), livingMask2, nextAccepting);
				
					-- INPUTS
					--		clk, reset, en
					--		execEventSignal, activeCausing, intSig, +
					wrAddress <= loadAddressWr;
					wrData <= loadValueWr;
					
					dataA <= loadAddressDataIn;
					dataD <= loadValueDataIn;
							
						-- Add signal from commit logic: tags to be sent (to implement for mem consistency)
					
					----------
					
			-- OUTPUTS:						
			acceptingOutLQ <= '1'; -- TEMP!						
			sendingLQ <= isNonzero(lqOutData.fullMask);
			dataOutLQ <= lqOutData.data(0); -- CAREFUL, TEMP!
							
			fullMask <= extractFullMask(content2);
								
			process (clk)
			begin
				if rising_edge(clk) then			
					content2 <= content2Next;
				end if;
			end process;
					
			SLOT_HBUFF: entity work.BufferPipeLogic(Behavioral)
																	--BehavioralDirect)
			generic map(
				CAPACITY => LQ_SIZE, -- PIPE_WIDTH*2*2
				MAX_OUTPUT => PIPE_WIDTH,
				MAX_INPUT => PIPE_WIDTH
			)		
			port map(
				clk => clk, reset => reset, en => en,
				flowDrive => bufferDrive,
				flowResponse => bufferResponse
			);						

			bufferDrive.prevSending <= 
							num2flow(countOnes(dataIn.fullMask)) when prevSending = '1' else (others => '0');
			bufferDrive.kill <= num2flow(countOnes(killMask));
			bufferDrive.nextAccepting <= num2flow(countOnes(lqOutData.fullMask));
			acceptingOut <= --'1' when binFlowNum(bufferResponse.living) >= PIPE_WIDTH else '0';
								 --not isNonzero(livingMask2(LQ_SIZE-PIPE_WIDTH to LQ_SIZE-1));		
								 not livingMask2(LQ_SIZE-PIPE_WIDTH);
					
					KILLERS: for i in 0 to LQ_SIZE-1 generate
						signal before: std_logic;
						signal a, b: std_logic_vector(7 downto 0);
					begin
						a <= execCausing.groupTag;
						b <= content2(i).ins.groupTag;
						IQ_KILLER: entity work.CompareBefore8 port map(
							inA =>  a,
							inB =>  b,
							outC => before
						);		
						killMask(i) <= killByTag(before, execEventSignal, '0') -- before and execEventSignal
												and fullMask(i);									
					end generate;
	sendingLQOut <= sendingLQ;
end Behavioral;

