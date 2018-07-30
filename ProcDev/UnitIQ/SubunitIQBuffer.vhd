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
		--aiArray: in ArgStatusInfoArray(0 to IQ_SIZE-1);
		--aiNew: in ArgStatusInfoArray(0 to PIPE_WIDTH-1);
		fni: ForwardingInfo;
		readyRegFlags: in std_logic_vector(0 to 3*PIPE_WIDTH-1);
		
		acceptingVec: out std_logic_vector(0 to PIPE_WIDTH-1);
		schedulerOut: out SchedulerEntrySlot
		--queueSending: out std_logic;
		--iqDataOut: out InstructionStateArray(0 to IQ_SIZE-1)
		--newDataOut: out InstructionState
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
	signal queueContentUpdated, queueContentUpdatedSel: SchedulerEntrySlotArray(0 to IQ_SIZE-1)
				:= (others => DEFAULT_SCH_ENTRY_SLOT);
	signal newContent: SchedulerEntrySlotArray(0 to PIPE_WIDTH-1) := (others => DEFAULT_SCH_ENTRY_SLOT);
				
	signal newSchedData: SchedulerEntrySlotArray(0 to PIPE_WIDTH-1) := (others => DEFAULT_SCH_ENTRY_SLOT);
				
	signal newDataU: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;												
	signal sends: std_logic := '0';
	signal dispatchDataNew: SchedulerEntrySlot := DEFAULT_SCH_ENTRY_SLOT;
	
	signal TMP_sendingWin: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

	--signal aiArray: ArgStatusInfoArray(0 to IQ_SIZE-1);
	--signal aiNew: ArgStatusInfoArray(0 to PIPE_WIDTH-1);
	
	signal qs0, qs1: TMP_queueState := TMP_defaultQueueState;

	signal writtenTagsZ: PhysNameArray(0 to PIPE_WIDTH-1) := (others => (others => '0'));		
			
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
	
	function getSchedData(insArr: InstructionStateArray) return SchedulerEntrySlotArray is
		variable res: SchedulerEntrySlotArray(0 to PIPE_WIDTH-1) := (others => DEFAULT_SCH_ENTRY_SLOT);
	begin
		for i in 0 to PIPE_WIDTH-1 loop
			res(i).ins := insArr(i);

			-- Set state markers: "zero" bit		
			if isNonzero(res(i).ins.virtualArgSpec.args(0)(4 downto 0)) = '0' then
				res(i).ins.argValues.zero(0) := '1';
			end if;
			
			if isNonzero(res(i).ins.virtualArgSpec.args(1)(4 downto 0)) = '0' then
				res(i).ins.argValues.zero(1) := '1';
			end if;

			if isNonzero(res(i).ins.virtualArgSpec.args(2)(4 downto 0)) = '0' then
				res(i).ins.argValues.zero(2) := '1';
			end if;		
				
			-- Set 'missing' flags for non-const arguments
			res(i).ins.argValues.missing := res(i).ins.physicalArgSpec.intArgSel and not res(i).ins.argValues.zero;
			
			-- Handle possible immediate arg
			if res(i).ins.constantArgs.immSel = '1' then
				res(i).ins.argValues.missing(1) := '0';
				res(i).ins.argValues.immediate := '1';
				res(i).ins.argValues.zero(1) := '0';
				--res.data(i).argValues.arg1 := res.data(i).constantArgs.imm;					
			end if;			

		end loop;
		return res;
	end function;
begin
	flowDriveQ.prevSending <= num2flow(countOnes(newData.fullMask)) when prevSendingOK = '1' else (others => '0');
	flowDriveQ.kill <= num2flow(countOnes(killMask));
	flowDriveQ.nextAccepting <=  num2flow(1) when sends = '1' else num2flow(0);															

--	aiNew <= getArgInfoArrayD2(newData.data, 
--											fni.resultTags, fni.resultTags, fni.resultTags,
--											fni.nextResultTags, fni.writtenTags);
--
--	aiArray <= getArgInfoArrayD2(queueData, 
--											fni.resultTags, fni.resultTags, fni.resultTags,
--											fni.nextResultTags, writtenTagsZ);

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
		
	inputEnable <= getEnableForInput_Shifting(qs0, IQ_SIZE, flowDriveQ.nextAccepting, flowDriveQ.prevSending);
	inputIndices <= getQueueIndicesForInput_Shifting(qs0, IQ_SIZE, flowDriveQ.nextAccepting, PIPE_WIDTH);
			
	livingMask <= fullMask and not killMask;

		fullMask <= extractFullMask(queueContent);
		queueData <= extractData(queueContent);
			
	fullMaskNext <= extractFullMask(queueContentNext);
	queueDataNext <= extractData(queueContentNext);	
	sends <= isNonzero(readyMask_C) and nextAccepting;
	dispatchDataNew <= TMP_clearDestIfEmpty(prioSelect(queueContentUpdatedSel, readyMask2), sends);
		stayMask <= TMP_setUntil(readyMask_C, nextAccepting);

			newSchedData <= getSchedData(newData.data);

		newContent <= --updateForWaitingArray(newData.data, readyRegFlags, aiNew, '1');
						  updateForWaitingArrayFNI(newSchedData, readyRegFlags, fni, '1');
			newDataU.fullMask <= newData.fullMask;
			newDataU.data <= extractData(newContent);
		
		queueContentNext <= iqContentNext4(queueContentUpdated, newDataU, 
														livingMask,
														stayMask,--readyMask2, --_C,
														sends,
														nextAccepting,
														binFlowNum(flowResponseQ.living),
														binFlowNum(flowResponseQ.sending),
														binFlowNum(flowDriveQ.prevSending),
														prevSendingOK);
					
	queueContentUpdated <= --updateForWaitingArray(queueData, readyRegFlags, aiArray, '0');
									updateForWaitingArrayFNI(queueContent, readyRegFlags, fni, '0');
	queueContentUpdatedSel <= --updateForSelectionArray(queueData, readyRegFlags, aiArray);
									 updateForSelectionArrayFNI(queueContent, readyRegFlags, fni);

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
		
	schedulerOut <= (sends, dispatchDataNew.ins, dispatchDataNew.state);
end Implem;
