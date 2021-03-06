----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:48:52 08/07/2016 
-- Design Name: 
-- Module Name:    ReorderBuffer - Behavioral 
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
use work.BasicFlow.all;
use work.GeneralPipeDev.all;

use work.TEMP_DEV.all;

use work.ProcLogicROB.all;

use work.Queues.all;


entity ReorderBuffer is
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
		
		lateEventSignal: in std_logic;
		execEventSignal: in std_logic;
		execCausing: in InstructionState; -- Redundant cause we have inputs from all Exec ends? 
		
		commitGroupCtr: in InsTag;
		commitGroupCtrNext: in InsTag;

		execEndSigs1: in InstructionSlotArray(0 to 3);
		execEndSigs2: in InstructionSlotArray(0 to 3);
		
		inputData: in StageDataMulti;
		prevSending: in std_logic;
		acceptingOut: out std_logic;
		
		nextAccepting: in std_logic;
		sendingOut: out std_logic; 
		
		outputData: out StageDataMulti
	);	
end ReorderBuffer;



architecture Implem of ReorderBuffer is
	signal fullMask, TMP_mask, TMP_ckEnForInput, TMP_sendingMask, TMP_killMask, TMP_livingMask, TMP_maskNext:
				std_logic_vector(0 to ROB_SIZE-1) := (others => '0');

		signal TMP_front, TMP_frontCircular: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	signal stageData, stageDataLiving, stageDataNext, stageDataUpdated,
					TMP_stageData, TMP_stageDataUpdated, TMP_stageDataNext: 
							StageDataROB := (fullMask => (others => '0'), data => (others => DEFAULT_STAGE_DATA_MULTI));
	signal flowDrive: FlowDriveBuffer	:= (killAll => '0', lockAccept => '0', lockSend => '0',
																others=>(others=>'0'));
	signal flowResponse: FlowResponseBuffer := (others => (others=> '0'));

	signal resetSig, enSig: std_logic := '0';	
	signal isSending: std_logic := '0';
	signal fromCommitted: std_logic := '0';
		
	signal numKilled: SmallNumber := (others => '0');

	signal qs0, qs1: TMP_queueState := TMP_defaultQueueState;
		
	signal inputIndices: SmallNumberArray(0 to ROB_SIZE-1) := (others => (others => '0'));

	signal inputIndices_T: SmallNumberArray(0 to ROB_SIZE-1) := (others => (others => '0'));
	signal ckEnForInput_T, sendingMask_T: std_logic_vector(0 to ROB_SIZE-1) := (others => '0');
	
	signal robView, robLivingView, robNextView, robLivingViewU, robNextViewU:
							StageDataROB := (fullMask => (others => '0'), data => (others => DEFAULT_STAGE_DATA_MULTI));

		signal execEnds: InstructionStateArray(0 to 3) := (others => DEFAULT_INSTRUCTION_STATE);
		signal execReady: std_logic_vector(0 to 3) := (others => '0');
		signal execEnds2: InstructionStateArray(0 to 3) := (others => DEFAULT_INSTRUCTION_STATE);
		signal execReady2: std_logic_vector(0 to 3) := (others => '0');
	
	constant ROB_HAS_RESET: std_logic := '0';
	constant ROB_HAS_EN: std_logic := '0';
begin
	resetSig <= reset and ROB_HAS_RESET;
	enSig <= en or not ROB_HAS_EN;
	
		execEnds <= extractData(execEndSigs1);
		execReady <= extractFullMask(execEndSigs1);
		execEnds2 <= extractData(execEndSigs2);
		execReady2 <= extractFullMask(execEndSigs2);
		
				qs1 <= TMP_change(qs0, flowDrive.nextAccepting, flowDrive.prevSending,
										TMP_mask, TMP_killMask, lateEventSignal or execEventSignal,
										TMP_maskNext);
										
				inputIndices <= getQueueIndicesForInput(qs0, ROB_SIZE, 1);
					-- indices for moved part in shifting queue would be nSend (bufferResponse.sending) everywhere
				TMP_ckEnForInput <= getQueueEnableForInput(qs0, ROB_SIZE, flowDrive.prevSending);
					-- in shifting queue this would be shfited by nSend
					-- Also slots for moved part would have enable, found from (i < nRemaining), only if nSend /= 0
				TMP_sendingMask <= getQueueSendingMask(qs0, ROB_SIZE, flowDrive.nextAccepting);
				TMP_killMask <= getKillMaskROB(qs0, TMP_mask, execEnds2(3), execEventSignal, lateEventSignal);

					TMP_livingMask <= TMP_mask and not TMP_killMask;

				TMP_maskNext <= (TMP_mask and not TMP_killMask and not TMP_sendingMask) or TMP_ckEnForInput;

				TMP_stageDataUpdated <= setCompleted_Circular(TMP_stageData, commitGroupCtr,
												execEnds, execReady, execEnds2, execReady2,
												execEventSignal, fromCommitted);
	
				TMP_stageDataNext <= stageROBNext_Circular(TMP_stageDataUpdated, TMP_mask, inputData,
															 binFlowNum(flowResponse.living),
															 '0',
															 prevSending, qs0.pEnd);
	
			TMP_frontCircular <= getSlotFromROB(TMP_stageData, qs0.pStart);
	
	robView <= normalizeROB(TMP_stageData, qs0.pStart);
	
		robLivingViewU.data <= TMP_stageData.data;
		robLivingViewU.fullMask <= TMP_livingMask;
	robLivingView <= normalizeROB(robLivingViewU, qs0.pStart);
	
		robNextViewU.fullMask <= TMP_maskNext;
		robNextViewU.data <= TMP_stageDataNext.data;
	robNextView <= normalizeROB(robNextViewU, qs1.pStart);
								
	ROB_SYNCHRONOUS: process (clk)
	begin
		if rising_edge(clk) then	
			qs0 <= qs1;
			TMP_mask <= TMP_maskNext;	
			TMP_stageData.data <= TMP_stageDataNext.data;
			TMP_stageData.fullMask <= TMP_maskNext;	-- CAREFUL: this is redundant

			logROB(robView, robLivingView, flowResponse);
			checkROB(robView, robNextView, flowDrive, flowResponse);
		end if;		
	end process;
	

	SLOT_ROB: entity work.BufferPipeLogic(--Behavioral)
														BehavioralDirect)
	generic map(
		CAPACITY => ROB_SIZE,
		MAX_OUTPUT => 1,	
		MAX_INPUT => 1				
	)
	Port map(
		clk => clk, reset => resetSig, en => enSig,
		flowDrive => flowDrive,
		flowResponse => flowResponse
	);			
	
	flowDrive.prevSending <= num2flow(1) when prevSending = '1' else num2flow(0);
	flowDrive.nextAccepting <= num2flow(1) when isSending = '1'
								else  (others => '0');
	
		numKilled <= getNumKilled(flowResponse.full,
												execEnds2(3).tags.renameIndex,
												commitGroupCtr, execEventSignal);
	
	flowDrive.kill <= numKilled;							
		flowDrive.killAll <= fromCommitted;
		
	isSending <= getBitFromROBMask(TMP_stageData, qs0.pStart)
				and groupCompleted(TMP_frontCircular)
				and not fromCommitted
							and nextAccepting;

	fromCommitted <= lateEventSignal;
						
	-- TODO: allow accepting also when queue full but sending, that is freeing a place?
	acceptingOut <= not getBitFromROBMaskPre(TMP_stageData, qs0.pStart);
								
	outputData.data <= TMP_frontCircular.data;
	outputData.fullMask <= TMP_frontCircular.fullMask when isSending = '1' else (others => '0');

	sendingOut <= isSending;
end Implem;

