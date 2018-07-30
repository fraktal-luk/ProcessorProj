----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:04:45 07/30/2018 
-- Design Name: 
-- Module Name:    SchedulerStage - Behavioral 
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

use work.ProcBasicDefs.all;
use work.Helpers.all;

use work.ProcInstructionsNew.all;

use work.NewPipelineData.all;
use work.BasicFlow.all;

use work.GeneralPipeDev.all;

use work.ProcComponents.all;

use work.ProcLogicFront.all;

use work.BasicCheck.all;

use work.TEMP_DEV.all;

use work.ProcLogicSequence.all;


entity SchedulerStage is
	generic(
		USE_CLEAR: std_logic := '1';
		COMPARE_TAG: std_logic := '0'
	);
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
		
		prevSending: in std_logic;
		nextAccepting: in std_logic;


		stageDataIn: in SchedulerEntrySlot;		
		acceptingOut: out std_logic;
		sendingOut: out std_logic;
		stageDataOut: out SchedulerEntrySlot;
		
		execEventSignal: in std_logic;
		lateEventSignal: in std_logic;
		execCausing: in InstructionState;
		lockCommand: in std_logic		
	);
end SchedulerStage;



architecture Behavioral of SchedulerStage is
	signal flowDrive: FlowDriveSimple := (others=>'0');
	signal flowResponse, flowResponse_C: FlowResponseSimple := (others=>'0');		
	signal stageData, stageDataLiving, stageDataNext, stageDataNew:
														SchedulerEntrySlot := DEFAULT_SCH_ENTRY_SLOT;
	signal partialKillMask: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');		
	--signal contentState, contentStateNext: ContentStateSimple := DEFAULT_CS_SIMPLE;
	signal before: std_logic := '0';
	
	function stageSchedNext(livingContent, newContent: SchedulerEntrySlot; full, sending, receiving: std_logic;
										clearEmptySlots: boolean)
	return SchedulerEntrySlot is 
		variable res: SchedulerEntrySlot := DEFAULT_SCH_ENTRY_SLOT;
			constant CLEAR_VACATED_SLOTS_GENERAL: boolean := clearEmptySlots; 
	begin
		if not CLEAR_VACATED_SLOTS_GENERAL then
			res := livingContent;
		end if;
		
		if receiving = '1' then -- take full
			res := newContent;
		elsif sending = '1' then -- take empty
			if CLEAR_VACATED_SLOTS_GENERAL then
				res := DEFAULT_SCH_ENTRY_SLOT;
			end if;	

			-- CAREFUL: clearing result tags for empty slots
			--for i in 0 to PIPE_WIDTH-1 loop
				res.ins.physicalArgSpec.dest := (others => '0');
					res.ins.controlInfo.newEvent := '0';
			--end loop;
		else -- stall or killed (kill can be partial)
			if full = '0' then
				-- Do nothing
				--for i in 0 to PIPE_WIDTH-1 loop
					res.ins.physicalArgSpec.dest := (others => '0');
						res.ins.controlInfo.newEvent := '0';
				--end loop;
			else
				res := livingContent;
			end if;
		end if;			
			
		return res;
	end function;


function stageSchedHandleKill(content: SchedulerEntrySlot; 
										killAll: std_logic) 
										return SchedulerEntrySlot is
	variable res: SchedulerEntrySlot := DEFAULT_SCH_ENTRY_SLOT;
		constant CLEAR_KILLED_SLOTS_GENERAL: boolean := false;
begin
	if not CLEAR_KILLED_SLOTS_GENERAL then
		res := content;
	end if;
	
	if killAll = '1' then
		res.full := '0';
	else
		res.full := content.full;-- and not killVec;
	end if;
	
	--for i in res.data'range loop
		if res.full = '1' then
			res.ins := content.ins;
		end if;
	--end loop;
	return res;
end function;
	
begin
	stageDataNew <= stageDataIn;										
	stageDataNext <= stageSchedNext(stageDataLiving, stageDataNew,
								flowResponse.living, flowResponse.sending, flowDrive.prevSending, false);			
	stageDataLiving <= stageSchedHandleKill(stageData, flowDrive.kill and USE_CLEAR);

	--contentStateNext <= nextContentState(contentState, flowDrive, reset, en);
	--flowResponse_C <= getResponse(contentState, flowDrive);

	PIPE_CLOCKED: process(clk) 	
	begin
		if rising_edge(clk) then
		--	contentState <= contentStateNext;		
			stageData <= stageDataNext;

			--logMulti(stageData.data, stageData.fullMask, stageDataLiving.fullMask, flowResponse);
			--checkMulti(stageData, stageDataNext, flowDrive, flowResponse);				
		end if;
	end process;

	SIMPLE_SLOT_LOGIC: SimplePipeLogic port map(
		clk => clk, reset => reset, en => en,
		flowDrive => flowDrive,
		flowResponse => flowResponse
	);

	flowDrive.prevSending <= stageDataIn.full;--stageDataIn.fullMask(0);
	flowDrive.nextAccepting <= nextAccepting;
	
	--before <= '1';
	before <= (not COMPARE_TAG) or CMP_tagBefore(execCausing.tags.renameIndex, stageData.ins.tags.renameIndex);
	flowDrive.kill <= (before and execEventSignal) or lateEventSignal;
	flowDrive.lockAccept <= lockCommand;

	acceptingOut <= flowResponse.accepting;		
	sendingOut <= flowResponse.sending;
	stageDataOut.ins <= stageDataLiving.ins;
	stageDataOut.state <= stageDataLiving.state;
	stageDataOut.full <= stageDataLiving.full when flowResponse.sending = '1' else '0';								 
end Behavioral;