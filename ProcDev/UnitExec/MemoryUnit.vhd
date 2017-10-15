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
		groupCtrNext: in SmallNumber; -- DEPREC?
		groupCtrInc: in SmallNumber;

		lateEventSignal: in std_logic;
		execEventSignal: in std_logic;
		execCausing: in InstructionState;
		
		nextAccepting: in std_logic;		
		sendingSQOut: out std_logic;
			dataOutV: out StageDataMulti
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
				TMP_mask, TMP_ckEnForInput, TMP_sendingMask, TMP_killMask, TMP_livingMask,
				TMP_maskNext,	TMP_maskA, TMP_maskD
								: std_logic_vector(0 to QUEUE_SIZE-1) := (others => '0'); 
	signal sqOutData, TMP_frontW, TMP_preFrontW, TMP_sendingData: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

	signal bufferDrive: FlowDriveBuffer := (killAll => '0', lockAccept => '0', lockSend => '0',
																others=>(others=>'0'));
	signal bufferResponse: FlowResponseBuffer := (others=>(others=>'0'));
	
		signal qs0, qs1: TMP_queueState := TMP_defaultQueueState;
		--signal ta, tb: SmallNumber := (others => '0');
		signal contentView, contentNextView:
					InstructionStateArray(0 to QUEUE_SIZE-1) := (others => DEFAULT_INSTRUCTION_STATE);
		signal maskView, liveMaskView, maskNextView: std_logic_vector(0 to QUEUE_SIZE-1) := (others => '0');
		
		signal inputIndices: SmallNumberArray(0 to QUEUE_SIZE-1) := (others => (others => '0'));	
begin				
	qs1 <= TMP_change(qs0,
							bufferDrive.nextAccepting,
							bufferDrive.prevSending,
							TMP_mask, TMP_killMask, lateEventSignal or execEventSignal, TMP_maskNext);
			
	inputIndices <= getQueueIndicesForInput(qs0, TMP_mask, PIPE_WIDTH);
	-- indices for moved part in shifting queue would be nSend (bufferResponse.sending) everywhere
	TMP_ckEnForInput <= getQueueEnableForInput(qs0, TMP_mask, bufferDrive.prevSending);
	-- in shifting queue this would be shfited by nSend
	-- Also slots for moved part would have enable, found from (i < nRemaining), only if nSend /= 0
	TMP_sendingMask <= getQueueSendingMask(qs0, TMP_mask, bufferDrive.nextAccepting);
	TMP_killMask <= getKillMask(TMP_content, TMP_mask, execCausing, execEventSignal, lateEventSignal);
	TMP_livingMask <= TMP_mask and not TMP_killMask;			
				
	TMP_maskNext <= (TMP_mask and not TMP_killMask and not TMP_sendingMask) or TMP_ckEnForInput;
	-- in shifting queue generated from (i < nFullNext)
	TMP_contentNext <=
				TMP_getNewContentUpdate(TMP_content, dataIn.data, TMP_ckEnForInput, inputIndices,
												TMP_maskA, TMP_maskD,
												storeAddressWr, storeValueWr, storeAddressDataIn, storeValueDataIn,
												CLEAR_COMPLETED, KEEP_INPUT_CONTENT);

	TMP_maskA <= findMatching(makeSlotArray(TMP_content, TMP_mask), storeAddressDataIn);
	TMP_maskD <= findMatching(makeSlotArray(TMP_content, TMP_mask), storeValueDataIn);

		contentView <= normalizeInsArray(qs0, TMP_content);
		maskView <= normalizeMask(qs0, TMP_mask);
		liveMaskView <= normalizeMask(qs0, TMP_livingMask);
		contentNextView <= normalizeInsArray(qs1, TMP_contentNext);
		maskNextView <= normalizeMask(qs1, TMP_maskNext);

	TMP_frontW <= getQueueFrontWindow(qs0, TMP_content, TMP_mask);
	TMP_preFrontW <= getQueuePreFrontWindow(qs0, TMP_content, TMP_mask);
	TMP_sendingData <= findCommittingSQ(TMP_frontW.data, TMP_frontW.fullMask, groupCtrInc, committing);
		
			sqOutData <= TMP_sendingData;
					
			sendingSQ <= isNonzero(sqOutData.fullMask);
			dataOutV <= sqOutData;
			contentData <= extractData(content);
			
			process (clk)
			begin
				if rising_edge(clk) then	
						qs0 <= qs1;
						TMP_mask <= TMP_maskNext;	
						TMP_content <= TMP_contentNext;
					
					logBuffer(contentView, maskView, liveMaskView, bufferResponse);					
					
					-- NOTE: below has no info about flow constraints. It just checks data against
					--			flow numbers, while the validity of those numbers is checked by slot logic	
					checkBuffer(contentView, maskView, contentNextView, maskNextView,
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
	bufferDrive.kill <= num2flow(countOnes(TMP_killMask));
	bufferDrive.nextAccepting <= num2flow(countOnes(sqOutData.fullMask));
					
	acceptingOut <= not TMP_preFrontW.fullMask(0);

	
	sendingSQOut <= sendingSQ;
end Behavioral;

