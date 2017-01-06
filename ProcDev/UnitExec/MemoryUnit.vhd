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


entity MemoryUnit is
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
		
		storeAddressWr: in std_logic;
		storeValueWr: in std_logic;

		storeAddressDataIn: in InstructionState;
		storeValueDataIn: in InstructionState;
		
		execEventSignal: in std_logic;
		execCausing: in InstructionState;
		
		intSignal: in std_logic;
		
		acceptingOutSQ: out std_logic;
		sendingOutSQ: out std_logic;
		dataOutSQ: out InstructionState
	);
end MemoryUnit;



architecture Behavioral of MemoryUnit is
	
					constant SQ_SIZE: integer := 4;
				
					signal content: InstructionSlotArray(0 to SQ_SIZE-1) := (others => DEFAULT_INSTRUCTION_SLOT);
					
						signal content2, contentK, content2U, content2Next: InstructionSlotArray(0 to SQ_SIZE-1)
								:= (others => DEFAULT_INSTRUCTION_SLOT);
						signal contentTmp: InstructionSlotArray(-1 to SQ_SIZE-1) 
								:= (others => DEFAULT_INSTRUCTION_SLOT);
					
					
					-- TODO: use completed + completed2 for readyA + readyD ???
					signal readyA, readyD, readyAD, readyMask: std_logic_vector(0 to SQ_SIZE-1) := (others => '0');
					
					signal wrAddress, wrData, sameTag: std_logic := '0';
					signal dataA, dataD: InstructionState := DEFAULT_INSTRUCTION_STATE;
					
					signal posA, posD, posSend, posSendTemp: integer := 0; 
					
					signal fullMask, livingMask, killMask: std_logic_vector(0 to SQ_SIZE-1)
											:= (others => '0');
					
					function getPos(content: InstructionSlotArray; ins: InstructionState) return integer is
						variable res: integer := 0;
						variable ff, m: integer := 0;
						variable hff, hm: boolean := false;
					begin
						for i in content'length-1 downto 0 loop
							if content(i).ins.groupTag = ins.groupTag then
								hm := true;
								m := i;
							end if;
							
							if content(i).full = '0' then
								hff := true;
								ff := i;
							end if;
						end loop;
					
						if hm then 
							res := m;
						else
							res := ff;
						end if;
					
						return res;
					end function;
					
					function getReadyToSend(content: InstructionSlotArray) return std_logic_vector is
						constant LEN: integer := content'length;
						variable res: std_logic_vector(0 to LEN-1) := (others => '0');
					begin
						for i in 0 to LEN-1 loop
							res(i) := content(i).full 
									and content(i).ins.controlInfo.completed
									and content(i).ins.controlInfo.completed2;
						end loop;
						
						return res;
					end function;
					
					
					function writeToSQ(content: InstructionSlotArray;
											 storeAddressData: InstructionState;
											 storeValueData: InstructionState;
											 wrAddress: std_logic; wrValue: std_logic) return InstructionSlotArray is
						constant LEN: integer := content'length;
						variable res: InstructionSlotArray(0 to LEN-1) := content;
						variable foundMatchA, foundMatchV: std_logic := '0';
					begin
						-- Find where to put addressData
						if wrAddress = '1' then
							for i in 0 to LEN-1 loop
								-- When match found:
								if storeAddressData.groupTag = content(i).ins.groupTag and content(i).full = '1' then
									res(i).ins.argValues.arg1 := storeAddressData.result;
									res(i).ins.controlInfo.completed := '1';
									foundMatchA := '1';
								end if;
							end loop;
							
							for i in 0 to LEN-1 loop
								-- Find where to put addressData							
								-- When match found:
								if foundMatchA = '0' and content(i).full = '0' then
									res(i).full := '1';
									res(i).ins.argValues.arg1 := storeAddressData.result;
									res(i).ins.controlInfo.completed := '1';
										res(i).ins.groupTag := storeAddressData.groupTag;
									exit;	
								end if;
							end loop;						
						end if;
						
						-- Find where to put value data
						if wrValue = '1' then
							for i in 0 to LEN-1 loop
								-- When match found (it includes new address op if it is begin written this cycle!)
								if storeValueData.groupTag = content(i).ins.groupTag and content(i).full = '1' then
									res(i).ins.argValues.arg2 := storeValueData.argValues.arg2;
									res(i).ins.controlInfo.completed2 := '1';
									foundMatchV := '1';
								end if;
							end loop;
							
							for i in 0 to LEN-1 loop
								-- Find where to put addressData							
								-- When match found:
								if foundMatchV = '0' and content(i).full = '0' then
									res(i).full := '1';
									res(i).ins.argValues.arg2 := storeValueData.argValues.arg2;
									res(i).ins.controlInfo.completed2 := '1';
										res(i).ins.groupTag := storeValueData.groupTag;
									exit;									
								end if;
							end loop;						
						end if;
					
						return res;
					end function;
					
					
					function sendingFromSQ(content: InstructionSlotArray;
												  ready: std_logic_vector; tag: SmallNumber)
					return InstructionSlot is
						variable res: InstructionSlot := DEFAULT_INSTRUCTION_SLOT;
						constant LEN: integer := content'length;						
					begin
						for i in 0 to LEN-1 loop
							res.ins := content(i).ins;
							if content(i).ins.groupTag = tag and content(i).full = '1'
							then
									if ready(i) = '0' then
										report "Not ready to send!" severity error;
									end if;
									
								res.full := '1';
								exit;
							end if;
						end loop;
						
						-- TODO: need to clear the slot, return new state!
						return res;
					end function;
					

							function sendingFromSQ2(content: InstructionSlotArray;
														   ready: std_logic_vector; tag: SmallNumber)
							return InstructionSlotArray is
								constant LEN: integer := content'length;
								variable res: InstructionSlotArray(-1 to LEN-1)
													:= (others => DEFAULT_INSTRUCTION_SLOT);
							begin
								res(0 to LEN-1) := content;
								for i in 0 to LEN-1 loop
									res(-1).ins := content(i).ins;
									if content(i).full = '1' and
											--content(i).ins.groupTag = tag
											ready(i) = '1' -- TEMP: send without confirmation about committing
									then
											if ready(i) = '0' then
												report "Not ready to send!" severity error;
											end if;
										
										res(i).full := '0';
										res(i).ins.controlInfo.completed := '0';
										res(i).ins.controlInfo.completed2 := '0';
										
										res(-1).full := '1';
										exit;
									end if;
								end loop;
								
								return res;
							end function;
					
					function killInSQ(content: InstructionSlotArray;
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
				
							contentK <= killInSQ(content2, execEventSignal, killMask);
							contentTmp <= sendingFromSQ2(contentK, readyMask, dummyCommitTag);
							content2U <= contentTmp(0 to SQ_SIZE-1);
							content2Next <= writeToSQ(content2U, dataA, dataD, wrAddress, wrData);
				
					-- INPUTS
					--		clk, reset, en
					--		execEventSignal, activeCausing, intSig, +
					wrAddress <= storeAddressWr;
					wrData <= storeValueWr;
					
					dataA <= storeAddressDataIn;
					dataD <= storeValueDataIn;
							
						-- Add signal from commit logic: tags to be sent (to implement for mem consistency)
					
					----------
					
						-- OUTPUTS:						
							acceptingOutSQ <= '1'; -- TEMP!
							
							sendingOutSQ <= isNonzero(readyAD);
							dataOutSQ <= content(posSend).ins;
							readyMask <= getReadyToSend(content);	-- CAREFUL:	not an output
							--		sendingOutSQ <= contentTmp(-1).full;
							--		dataOutSQ <= contentTmp(-1).ins;						
						----------
							--		readyMask <= getReadyToSend(content2);

						
						-- CAREFUL: to match for writing Adr, completed2 should be '1', and when
						--				matching for writing Data, completed should be '1'
						posA <= getPos(content, dataA);
						posD <= getPos(content, dataD);
										
						sameTag <= '1' when dataA.groupTag = dataD.groupTag else '0';
					
							posSendTemp <= getFirstOnePosition(readyAD);
							posSend <= 0 when posSendTemp < 0 else posSendTemp;
							
						fullMask <= extractFullMask(content);
						livingMask <= fullMask and not killMask;
						readyAD <= readyA and readyD and livingMask;		
								
								
					process (clk)
					begin
						if rising_edge(clk) then
							if en = '1' then
								-- Possibilities: new A, new D, new A+D, update A, update D
								--						remaining ones: null (trivial), update A+D: error!
								
								-- nA -> adr to 1st free
								-- nD -> data to 1st free
								-- nAD -> adr+data to 1st free
								-- uA -> adr to matching
								-- uD -> data to matching
								-- 0 -> nothing
								-- uAD -> error error!
								
								-- 1st free can be shown as matching if no match is found.
								-- It makes it simpler:
								-- wrA -> (adr, info) to matching
								-- wrD -> (data, info) to matching
								-- 	"info" means tags, 'full' flag etc. (whole instruction state?)
	
	
								if wrAddress = '1' then
									content(posA).full <= '1';
										content(posA).ins.controlInfo.completed <= '1';
									content(posA).ins.groupTag <= dataA.groupTag;	
										content(posA).ins.argValues.arg1 <= dataA.result; -- the address
									readyA(posA) <= '1';
								end if;
								
								if wrData = '1' then
									-- Write tag if it's not written at the same time by address unit
									-- In case of A+D: treat the A writing as "first", seen by D as already written
									--							(it could be the reverse OFC)									
									if sameTag = '0' or wrAddress = '0' then
										content(posD).full <= '1';
										content(posD).ins.groupTag <= dataD.groupTag;
									end if;
										content(posA).ins.controlInfo.completed2 <= '1';									
									content(posD).ins.argValues.arg2 <= dataD.argValues.arg2; -- data to store
									readyD(posD) <= '1';									
								end if;
								
								
								for i in 0 to SQ_SIZE-1 loop
									if killMask(i) = '1' then
										content(i).full <= '0';
										readyA(i) <= '0';
										readyD(i) <= '0';
									end if;
								end loop;
								
								-- Clearing when sending 
								if isNonzero(readyAD) = '1' then
									--false then -- NOTE, TODO: sending must wait for committing, not just ready args
									content(posSend).full <= '0';
									readyA(posSend) <= '0';
									readyD(posSend) <= '0';
										content(posSend).ins.controlInfo.completed <= '0';
										content(posSend).ins.controlInfo.completed2 <= '0';
								end if;
											
									content2 <= content2Next;
							end if;
						end if;
					end process;
					
					KILLERS: for i in 0 to SQ_SIZE-1 generate
						signal before: std_logic;
						signal a, b: std_logic_vector(7 downto 0);
					begin
						a <= execCausing.groupTag;
						b <= content(i).ins.groupTag;
						IQ_KILLER: entity work.CompareBefore8 port map(
							inA =>  a,
							inB =>  b,
							outC => before
						);		
						killMask(i) <= killByTag(before, execEventSignal, intSignal) -- before and execEventSignal
												and fullMask(i);									
					end generate;
					


end Behavioral;

