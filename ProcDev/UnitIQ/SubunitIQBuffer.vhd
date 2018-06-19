----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:07:12 05/05/2016 
-- Design Name: 
-- Module Name:    SubunitIQBuffer - Behavioral 
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

use work.ProcLogicIQ.all;

use work.ProcComponents.all;

use work.BasicCheck.all;

use work.Queues.all;


entity SubunitIQBuffer is
	generic(
		IQ_SIZE: natural := 2
	);
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
		
		prevSendingOK: in std_logic;
		newData: in StageDataMulti;
		nextAccepting: in std_logic;
		lateEventSignal: in std_logic;
		execEventSignal: in std_logic;
		execCausing: in InstructionState;
		aiArray: in ArgStatusInfoArray(0 to IQ_SIZE-1);
		aiNew: in ArgStatusInfoArray(0 to PIPE_WIDTH-1);
		readyRegFlags: in std_logic_vector(0 to 3*PIPE_WIDTH-1);
		
		acceptingVec: out std_logic_vector(0 to PIPE_WIDTH-1);
		schedulerOut: out SchedulerEntrySlot;
		--queueSending: out std_logic;
		iqDataOut: out InstructionStateArray(0 to IQ_SIZE-1)
		--newDataOut: out InstructionState
	);
end SubunitIQBuffer;


architecture Implem of SubunitIQBuffer is
	signal queueData, queueDataUpdated, queueDataUpdatedSel: InstructionStateArray(0 to IQ_SIZE-1) 
								:= (others=>defaultInstructionState);
	signal queueDataLiving, queueDataNext, TMP_dataNext, queueData_TMP: InstructionStateArray(0 to IQ_SIZE-1)
								:= (others=>defaultInstructionState);		
	signal fullMask, fullMaskNext, killMask, livingMask, readyMask, readyMask2, readyMask_C, stayMask,
				inputEnable, movedEnable, TMP_maskNext, sendingMask: std_logic_vector(0 to IQ_SIZE-1) := (others=>'0');	

	signal inputIndices, movedIndices: SmallNumberArray(0 to IQ_SIZE-1) := (others => (others => '0'));
								
	signal flowDriveQ: FlowDriveBuffer := (killAll => '0', lockAccept => '0', lockSend => '0', others=>(others=>'0'));
	signal flowResponseQ: FlowResponseBuffer := (others => (others=> '0'));

	signal queueContent, queueContentNext: InstructionSlotArray(-1 to IQ_SIZE-1)
				:= (others => DEFAULT_INSTRUCTION_SLOT);
																
	signal newDataU: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;												
	signal sends: std_logic := '0';
	signal dispatchDataNew: InstructionState := defaultInstructionState;
	
	signal sendingIndex: SmallNumber := (others => '0');
	signal TMP_sendingWin: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	
	signal qs0, qs1: TMP_queueState := TMP_defaultQueueState;
	signal sendingSlot: InstructionSlot := DEFAULT_INSTRUCTION_SLOT;
			
	function selectSending(arr: InstructionStateArray; mask: std_logic_vector; nextAccepting: std_logic)
	return InstructionSlot is
		constant LEN: integer := arr'length;
		variable res: InstructionSlot;
	begin
		res.full := mask(LEN-1);
		res.ins := arr(LEN-1);
		
		for i in 0 to LEN-1 loop
			if mask(i) = '1' then
				res.full := nextAccepting;
				res.ins := arr(i);
				exit;
			end if;
		end loop;
		return res;
	end function;
	
	-- Select item at first '1', or the last one if all zeros
	function prioSelect(elems: InstructionStateArray; selVec: std_logic_vector) return InstructionState is
	begin	
		for i in 0 to elems'length-1 loop
			if selVec(i) = '1' then
				return elems(i);
			end if;
		end loop;
		return elems(elems'length-1);
	end function;
	
	function TMP_clearDestIfEmpty(ins: InstructionState; sends: std_logic) return InstructionState is
		variable res: InstructionState := ins;
	begin
		if sends = '0' then
			res.physicalArgSpec.dest := (others => '0');
		end if;
		return res;
	end function;
	
	function TMP_setUntil(selVec: std_logic_vector; nextAccepting: std_logic) return std_logic_vector is
		variable res: std_logic_vector(0 to selVec'length-1) := (others => '0');
	begin
		for i in res'range loop
			if (selVec(i) and nextAccepting) = '1' then
				exit;
			else
				res(i) := '1';
			end if;
		end loop;
		return res;
	end function;
begin
	flowDriveQ.prevSending <= num2flow(countOnes(newData.fullMask)) when prevSendingOK = '1' else (others => '0');
	flowDriveQ.kill <= num2flow(countOnes(killMask));
	flowDriveQ.nextAccepting <=  num2flow(1) when (nextAccepting and isNonzero(readyMask_C)) = '1' else num2flow(0);															

	QUEUE_SYNCHRONOUS: process(clk) 	
	begin
		if rising_edge(clk) then
			qs0 <= qs1;
		
			queueData <= queueDataNext;
			fullMask <= fullMaskNext;

			logBuffer(queueData, fullMask, livingMask, flowResponseQ);
			checkIQ(queueData, fullMask, queueDataNext, fullMaskNext, dispatchDataNew, sends, flowDriveQ, flowResponseQ);
		end if;
	end process;	
	
		qs1 <= TMP_change_Shifting(qs0,
											flowDriveQ.nextAccepting,
											flowDriveQ.prevSending,
											fullMask, killMask,
											execEventSignal or execCausing.controlInfo.hasInterrupt);
		
	sendingMask <= getFirstOne(readyMask2 and livingMask) when nextAccepting = '1' else	(others => '0');
		
	inputEnable <= getEnableForInput_Shifting(qs0, IQ_SIZE, flowDriveQ.nextAccepting, flowDriveQ.prevSending);
	inputIndices <= getQueueIndicesForInput_Shifting(qs0, IQ_SIZE, flowDriveQ.nextAccepting, PIPE_WIDTH);
		
		-- CAREFUL: here we need to enable only those from sending, not from first
			-- find index of sending - probably not used
		sendingIndex <= findQueueIndex(sendingMask);
			
	movedEnable <= getEnableForMoved_Shifting(qs0, IQ_SIZE, flowDriveQ.nextAccepting, flowDriveQ.prevSending)
						and setFromFirstOne(sendingMask);
	movedIndices <= (others => (others => '0')); -- Always moved by 1 or not at all, so 0-th moved elem
		
	TMP_maskNext <= getQueueMaskNext_Shifting(qs1, IQ_SIZE);

	TMP_dataNext <= TMP_getNewContent_General(queueDataUpdated, newDataU.data,
															movedEnable, movedIndices, inputEnable, inputIndices);

	sendingSlot <=	selectSending(queueDataUpdatedSel, readyMask_C, nextAccepting);
			
	livingMask <= fullMask and not killMask;
					
	fullMaskNext <= extractFullMask(queueContentNext(0 to IQ_SIZE-1));
	queueDataNext <= extractData(queueContentNext(0 to IQ_SIZE-1));	
	sends <= isNonzero(readyMask2) and nextAccepting;
	dispatchDataNew <= TMP_clearDestIfEmpty(prioSelect(queueDataUpdatedSel, readyMask2), sends);
		stayMask <= TMP_setUntil(readyMask2, nextAccepting);

			newDataU.fullMask <= newData.fullMask;
			newDataU.data <= updateForWaitingArray(newData.data, readyRegFlags, aiNew, '1');
		queueContentNext <= iqContentNext4(queueDataUpdated, newDataU, 
														livingMask, 
														stayMask,--readyMask2, --_C,
														sends,
														nextAccepting,
														binFlowNum(flowResponseQ.living),
														binFlowNum(flowResponseQ.sending),
														binFlowNum(flowDriveQ.prevSending),
														prevSendingOK);
					
	queueDataUpdated <= updateForWaitingArray(queueData, readyRegFlags, aiArray, '0');
	queueDataUpdatedSel <= updateForSelectionArray(queueData, readyRegFlags, aiArray);

	readyMask2 <= extractReadyMaskNew(queueDataUpdatedSel);	
	readyMask_C <= readyMask2 and livingMask;
			
	SLOTS_IQ: entity work.BufferPipeLogic(BehavioralIQ) -- IQ)
	generic map(
		CAPACITY => IQ_SIZE,
		MAX_OUTPUT => 1,	-- CAREFUL! When can send to 2 different units at once, it must change to 2!
		MAX_INPUT => PIPE_WIDTH				
	)
	port map(
		clk => clk, reset =>  reset, en => en,
		flowDrive => flowDriveQ,
		flowResponse => flowResponseQ
	);	
	
	killMask <= getKillMask(queueData, fullMask, execCausing, execEventSignal, lateEventSignal); 
	
	acceptingVec <= not fullMask(IQ_SIZE-PIPE_WIDTH to IQ_SIZE-1);
		
	iqDataOut <= queueData;						
	schedulerOut <= (flowResponseQ.sending(0), dispatchDataNew, DEFAULT_SCHED_STATE);
end Implem;
