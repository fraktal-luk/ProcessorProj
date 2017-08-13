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
use work.ProcLogicMemory.all;

use work.BasicCheck.all;

use work.Queues.all;


entity MemoryUnit is
	generic(
		QUEUE_SIZE: integer := 4;
		CLEAR_COMPLETED: boolean := true;
		KEEP_INPUT_CONTENT: boolean := false
	);
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;

		acceptingOut: out std_logic;
		prevSending: in std_logic;
		dataIn: in StageDataMulti;

		storeAddressWr: in std_logic;
		storeValueWr: in std_logic;

		storeAddressDataIn: in InstructionState;
		storeValueDataIn: in InstructionState;

		committing: in std_logic;
		groupCtrNext: in SmallNumber;
		groupCtrInc: in SmallNumber;

		lateEventSignal: in std_logic;
		execEventSignal: in std_logic;
		execCausing: in InstructionState;
		
		nextAccepting: in std_logic;		
		sendingSQOut: out std_logic;
			dataOutV: out StageDataMulti;
		dataOutSQ: out InstructionState
	);
end MemoryUnit;


architecture Behavioral of MemoryUnit is
	constant zeroMask: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');

	signal sendingSQ: std_logic := '0';							

	signal content, contentNext, contentUpdated:
					InstructionSlotArray(0 to QUEUE_SIZE-1) := (others => DEFAULT_INSTRUCTION_SLOT);
	signal contentData, contentDataNext,  TMP_content, TMP_contentNext: InstructionStateArray(0 to QUEUE_SIZE-1)
																			:= (others => DEFAULT_INSTRUCTION_STATE);
	signal fullMask, livingMask, killMask, contentMaskNext, matchingA, matchingD,
				matchingShA, matchingShD,  
				TMP_mask, TMP_ckEnForInput, TMP_sendingMask, TMP_killMask, TMP_maskNext,	TMP_maskA, TMP_maskD
								: std_logic_vector(0 to QUEUE_SIZE-1) := (others => '0'); 
	signal sqOutData, TMP_frontW, TMP_preFrontW, TMP_sendingData: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

	signal bufferDrive: FlowDriveBuffer := (killAll => '0', lockAccept => '0', lockSend => '0',
																others=>(others=>'0'));
	signal bufferResponse: FlowResponseBuffer := (others=>(others=>'0'));
	
		signal qs0, qs1: TMP_queueState := TMP_defaultQueueState;
		signal ta, tb: SmallNumber := (others => '0');
		signal contentView: InstructionStateArray(0 to QUEUE_SIZE-1) := (others => DEFAULT_INSTRUCTION_STATE);
		signal maskView: std_logic_vector(0 to QUEUE_SIZE-1) := (others => '0');
		
		signal inputIndices: SmallNumberArray(0 to QUEUE_SIZE-1) := (others => (others => '0'));
	
	signal inputIndices_T: SmallNumberArray(0 to QUEUE_SIZE-1) := (others => (others => '0'));
	signal ckEnForInput_T, sendingMask_T: std_logic_vector(0 to QUEUE_SIZE-1) := (others => '0');
begin				
	ta <= bufferDrive.nextAccepting;
	tb <= bufferDrive.prevSending;
	qs1 <= TMP_change(qs0, ta, tb, TMP_mask, TMP_killMask, lateEventSignal or execEventSignal, TMP_maskNext);
			
	inputIndices <= getQueueIndicesForInput(qs0, TMP_mask);
	-- indices for moved part in shifting queue would be nSend (bufferResponse.sending) everywhere
	TMP_ckEnForInput <= getQueueEnableForInput(qs0, TMP_mask, bufferDrive.prevSending);
	-- in shifting queue this would be shfited by nSend
	-- Also slots for moved part would have enable, found from (i < nRemaining), only if nSend /= 0
	TMP_sendingMask <= getQueueSendingMask(qs0, TMP_mask, bufferDrive.nextAccepting);
	TMP_killMask <= getKillMask(TMP_content, TMP_mask, execCausing, execEventSignal, lateEventSignal);
				
	TMP_maskNext <= (TMP_mask and not TMP_killMask and not TMP_sendingMask) or TMP_ckEnForInput;
	-- in shifting queue generated from (i < nFullNext)
	TMP_contentNext <=
				TMP_getNewContentUpdate(TMP_content, dataIn.data, TMP_ckEnForInput, inputIndices,
												TMP_maskA, TMP_maskD,
												storeAddressWr, storeValueWr, storeAddressDataIn, storeValueDataIn,
												CLEAR_COMPLETED, KEEP_INPUT_CONTENT);

	TMP_maskA <= findMatching(makeSlotArray(TMP_content, TMP_mask), storeAddressDataIn); --dataA);
	TMP_maskD <= findMatching(makeSlotArray(TMP_content, TMP_mask), storeValueDataIn);

		contentView <= normalizeInsArray(qs0, TMP_content);
		maskView <= normalizeMask(qs0, TMP_mask);

	TMP_frontW <= getQueueFrontWindow(qs0, TMP_content, TMP_mask);
	TMP_preFrontW <= getQueuePreFrontWindow(qs0, TMP_content, TMP_mask);
	TMP_sendingData <= findCommittingSQ(TMP_frontW.data, TMP_frontW.fullMask, groupCtrInc, committing);


		fullMask <= extractFullMask(content);
		livingMask <= fullMask and not killMask;
			
			-- CAREFUL: for shifting queue, the bit will be shifted by nSend, so condition is matching(i+nSend)
		matchingA <= findMatching(content, storeAddressDataIn); --dataA);
		matchingD <= findMatching(content, storeValueDataIn); -- dataD);
							
		matchingShA <= queueMaskNext(matchingA, zeroMask,
																 binFlowNum(bufferResponse.full),
																 countOnes(sqOutData.fullMask),
																 prevSending);																

		matchingShD <= queueMaskNext(matchingD, zeroMask,
																 binFlowNum(bufferResponse.full),
																 countOnes(sqOutData.fullMask),
																 prevSending);
			
		contentDataNext <= storeQueueNext(extractData(content), fullMask,
																 dataIn.data, dataIn.fullMask,
																 binFlowNum(bufferResponse.full),
																 countOnes(sqOutData.fullMask),
																 prevSending,
																 storeAddressDataIn, --dataA
																 storeValueDataIn,--dataD,
																 storeAddressWr, storeValueWr,
																 matchingShA, matchingShD,
																 CLEAR_COMPLETED);

		contentMaskNext <= queueMaskNext(livingMask, dataIn.fullMask,
																 binFlowNum(bufferResponse.living),
																 countOnes(sqOutData.fullMask),
																 prevSending);
		contentUpdated <= makeSlotArray(contentDataNext, contentMaskNext);		
		contentNext <= contentUpdated;
		
			sqOutData <= TMP_sendingData;
					
			sendingSQ <= isNonzero(sqOutData.fullMask);
			dataOutSQ <= sqOutData.data(0); -- CAREFUL, TEMP!
				dataOutV <= sqOutData;
			contentData <= extractData(content);
			
			process (clk)
			begin
				if rising_edge(clk) then	
						qs0 <= qs1;
						TMP_mask <= TMP_maskNext;	
						TMP_content <= TMP_contentNext;
						
					content <= contentNext;					
					
					--	assert inputIndices = inputIndices_T report "norrr";
					--	assert sendingMask_T = TMP_sendingMask report "anutt";
					
					logBuffer(contentData, fullMask, livingMask, bufferResponse);	
					-- NOTE: below has no info about flow constraints. It just checks data against
					--			flow numbers, while the validity of those numbers is checked by slot logic
					checkBuffer(extractData(content), fullMask, extractData(contentNext),
																				extractFullMask(contentNext),
										bufferDrive, bufferResponse);
				end if;
			end process;
					
			SLOT_BUFF: entity work.BufferPipeLogic(BehavioralDirect)
			generic map(
				CAPACITY => QUEUE_SIZE, -- PIPE_WIDTH*2*2
				MAX_OUTPUT => PIPE_WIDTH,
				MAX_INPUT => PIPE_WIDTH
			)		
			port map(
				clk => clk, reset => reset, en => en,
				flowDrive => bufferDrive,
				flowResponse => bufferResponse
			);						

	bufferDrive.prevSending <=num2flow(countOnes(dataIn.fullMask)) when prevSending = '1' else (others => '0');
	bufferDrive.kill <= num2flow(countOnes(killMask));
	bufferDrive.nextAccepting <= num2flow(countOnes(sqOutData.fullMask));
					
					KILLERS: for i in 0 to QUEUE_SIZE-1 generate
						signal before: std_logic;
						signal a, b: std_logic_vector(7 downto 0);
						signal c: SmallNumber := (others => '0');						
					begin
						a <= execCausing.groupTag;
						b <= content(i).ins.groupTag;
						c <= subSN(a, b);
						before <= c(7);
						killMask(i) <= killByTag(before, execEventSignal, lateEventSignal)
												and fullMask(i);									
					end generate;
					
	acceptingOut <= not TMP_preFrontW.fullMask(0);

	
	sendingSQOut <= sendingSQ;
end Behavioral;

