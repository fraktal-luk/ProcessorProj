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
	use work.ProcLogicRouting.all;


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
			newArr: in SchedulerEntrySlotArray(0 to PIPE_WIDTH-1);
		nextAccepting: in std_logic;
		lateEventSignal: in std_logic;
		execEventSignal: in std_logic;
		execCausing: in InstructionState;
		fni: ForwardingInfo;
		readyRegFlags: in std_logic_vector(0 to 3*PIPE_WIDTH-1);
		
		acceptingVec: out std_logic_vector(0 to PIPE_WIDTH-1);
		acceptingOut: out std_logic;
		
		anyReady: out std_logic;
		schedulerOut: out SchedulerEntrySlot;
		sending: out std_logic
	);
end SubunitIQBuffer;


architecture Implem of SubunitIQBuffer is
	signal queueData: InstructionStateArray(0 to IQ_SIZE-1)  := (others=>defaultInstructionState);
	signal queueDataNext: InstructionStateArray(0 to IQ_SIZE-1) -- For view
								:= (others=>defaultInstructionState);		
	signal fullMask, fullMaskNext, killMask, livingMask, readyMask, readyMask2, readyMask_C, stayMask,
				inputEnable, sendingMask: std_logic_vector(0 to IQ_SIZE-1) := (others=>'0');	

	signal inputIndices: SmallNumberArray(0 to IQ_SIZE-1) := (others => (others => '0'));
								
	signal flowDriveQ: FlowDriveBuffer := (killAll => '0', lockAccept => '0', lockSend => '0', others=>(others=>'0'));
	signal flowResponseQ: FlowResponseBuffer := (others => (others=> '0'));

	signal queueContent, queueContentNext: SchedulerEntrySlotArray(0 to IQ_SIZE-1)
				:= (others => DEFAULT_SCH_ENTRY_SLOT);
	signal queueContentUpdated, queueContentUpdatedSel, queueContentUpdated_T, queueContentUpdatedSel_T:
							SchedulerEntrySlotArray(0 to IQ_SIZE-1)
				:= (others => DEFAULT_SCH_ENTRY_SLOT);
	signal newContent, newContent_T: SchedulerEntrySlotArray(0 to PIPE_WIDTH-1) := (others => DEFAULT_SCH_ENTRY_SLOT);
				
	signal newSchedData: SchedulerEntrySlotArray(0 to PIPE_WIDTH-1) := (others => DEFAULT_SCH_ENTRY_SLOT);
				
	signal newDataU: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;												
	signal sends: std_logic := '0';
	signal dispatchDataNew: SchedulerEntrySlot := DEFAULT_SCH_ENTRY_SLOT;
	
	signal TMP_sendingWin: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	
	signal qs0, qs1: TMP_queueState := TMP_defaultQueueState;
	
	-- Select item at first '1', or the last one if all zeros
	function prioSelect(elems: SchedulerEntrySlotArray; selVec: std_logic_vector) return SchedulerEntrySlot is
	begin	
		for i in 0 to elems'length-1 loop
			if selVec(i) = '1' then
				return elems(i);
			end if;
		end loop;
		return elems(elems'length-1);
	end function;
	
	function TMP_clearDestIfEmpty(elem: SchedulerEntrySlot; sends: std_logic) return SchedulerEntrySlot is
		variable res: SchedulerEntrySlot := elem;
	begin
		if sends = '0' then
			res.ins.physicalArgSpec.dest := (others => '0');
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

			signal ch0, ch1, ch2: std_logic := '0';
begin
	flowDriveQ.prevSending <= num2flow(countOnes(newData.fullMask)) when prevSendingOK = '1' else (others => '0');
	flowDriveQ.kill <= num2flow(countOnes(killMask));
	flowDriveQ.nextAccepting <=  num2flow(1) when sends = '1' else num2flow(0);															

	QUEUE_SYNCHRONOUS: process(clk) 	
	begin
		if rising_edge(clk) then
			qs0 <= qs1;
		
			queueContent <= queueContentNext;

			logBuffer(queueData, fullMask, livingMask, flowResponseQ);
			checkIQ(queueData, fullMask, queueDataNext, fullMaskNext, dispatchDataNew.ins,
																		sends, flowDriveQ, flowResponseQ);
		end if;
	end process;	
	
		qs1 <= TMP_change_Shifting(qs0,
											flowDriveQ.nextAccepting,
											flowDriveQ.prevSending,
											fullMask, killMask,
											execEventSignal or execCausing.controlInfo.hasInterrupt);
		
	sendingMask <= getFirstOne(readyMask2 and livingMask) when nextAccepting = '1' else	(others => '0');

	livingMask <= fullMask and not killMask;

		fullMask <= extractFullMask(queueContent);
		queueData <= extractData(queueContent);
			
	fullMaskNext <= extractFullMask(queueContentNext);
	queueDataNext <= extractData(queueContentNext);	
	sends <= isNonzero(readyMask_C) and nextAccepting;
	dispatchDataNew <= TMP_clearDestIfEmpty(prioSelect(queueContentUpdatedSel, readyMask2), sends);
		stayMask <= TMP_setUntil(readyMask_C, nextAccepting);

		newSchedData <= getSchedData(newData.data, newData.fullMask);

		newContent <= --updateForWaitingArrayFNI(newSchedData, readyRegFlags, fni);--, '1');
				--newContent_T <= 
							--updateForWaitingArrayNewFNI(newSchedData, readyRegFlags, fni);
							newArr;
							
			--newDataU.fullMask <= newData.fullMask;
			--newDataU.data <= extractData(newContent);
			newDataU <= newData;
		queueContentNext <= iqContentNext(queueContentUpdated, newDataU,
																				--	newData.fullMask,
																					newContent,
														livingMask,
														stayMask,--readyMask2, --_C,
														sends,
														nextAccepting,
														binFlowNum(flowResponseQ.living),
														binFlowNum(flowResponseQ.sending),
														binFlowNum(flowDriveQ.prevSending),
														prevSendingOK);
					
	-- TODO: below could be optimized because some code is shared (comparators!)
	--queueContentUpdated <= updateForWaitingArrayFNI(queueContent, readyRegFlags, fni);--, '0');
	--queueContentUpdatedSel <= updateForSelectionArrayFNI(queueContent, readyRegFlags, fni);

		queueContentUpdated <= updateForWaitingArrayFNI2(queueContent, readyRegFlags, fni);--, '0');
		queueContentUpdatedSel <= updateForSelectionArrayFNI2(queueContent, readyRegFlags, fni);

			ch0 <= '1' when queueContentUpdatedSel(0).ins = queueContentUpdatedSel_T(0).ins else '0';
			ch1 <= '1' when queueContentUpdatedSel(0).state.argValues.missing = 
									queueContentUpdatedSel_T(0).state.argValues.missing else '0';


	readyMask2 <= extractReadyMaskNew(queueContentUpdatedSel);	
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
	acceptingOut <= not isNonzero(fullMask(IQ_SIZE-PIPE_WIDTH to IQ_SIZE-1)); 
	
	anyReady <= isNonzero(readyMask_C);
	
	schedulerOut <= (sends, dispatchDataNew.ins, dispatchDataNew.state);
	sending <= sends;
end Implem;
