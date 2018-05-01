----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    02:24:40 05/07/2016 
-- Design Name: 
-- Module Name:    GenericStageMulti - Behavioral 
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

use work.ProcComponents.all;

use work.ProcLogicFront.all;

use work.BasicCheck.all;

use work.TEMP_DEV.all;

use work.ProcLogicSequence.all;


entity GenericStageMulti is
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
		
		prevSending: in std_logic;
		nextAccepting: in std_logic;


		stageDataIn: in StageDataMulti;		
		acceptingOut: out std_logic;
		sendingOut: out std_logic;
		stageDataOut: out StageDataMulti;
		
		execEventSignal: in std_logic;
		lateEventSignal: in std_logic;
		execCausing: in InstructionState;
		lockCommand: in std_logic;
		
		stageEventsOut: out StageMultiEventInfo		
	);
end GenericStageMulti;



architecture Behavioral of GenericStageMulti is
	signal flowDrive: FlowDriveSimple := (others=>'0');
	signal flowResponse, flowResponse_C: FlowResponseSimple := (others=>'0');		
	signal stageData, stageDataLiving, stageDataNext, stageDataNew:
														StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	signal partialKillMask: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');	
	signal stageEvents: StageMultiEventInfo;
	
		signal contentState, contentStateNext: ContentStateSimple := DEFAULT_CS_SIMPLE;
begin
	stageDataNew <= stageDataIn;										
	stageDataNext <= stageMultiNext(stageDataLiving, stageDataNew,
								flowResponse.living, flowResponse.sending, flowDrive.prevSending);			
	stageDataLiving <= stageMultiHandleKill(stageData, flowDrive.kill, partialKillMask);


		contentStateNext <= nextContentState(contentState, flowDrive, reset, en);
		flowResponse_C <= getResponse(contentState, flowDrive);

	PIPE_CLOCKED: process(clk) 	
	begin
		if rising_edge(clk) then
			contentState <= contentStateNext;
		
			if reset = '1' then
				
			elsif en = '1' then	
				stageData <= stageDataNext;
				

				logMulti(stageData.data, stageData.fullMask, stageDataLiving.fullMask, flowResponse);
				checkMulti(stageData, stageDataNext, flowDrive, flowResponse);				
			end if;
		end if;
	end process;

	SIMPLE_SLOT_LOGIC: SimplePipeLogic port map(
		clk => clk, reset => reset, en => en,
		flowDrive => flowDrive,
		flowResponse => flowResponse
	);
	
		stageEvents <= stageMultiEvents(stageData, flowResponse.isNew);								
		partialKillMask <= stageEvents.partialKillMask;
	
	flowDrive.prevSending <= --prevSending;
										stageDataIn.fullMask(0);
	flowDrive.nextAccepting <= nextAccepting;
	flowDrive.kill <= execEventSignal or lateEventSignal;
	flowDrive.lockAccept <= lockCommand;

	acceptingOut <= flowResponse.accepting;		
	sendingOut <= flowResponse.sending;
	--stageDataOut <= stageDataLiving; -- TODO: clear temp ctrl info?
		stageDataOut.data <= stageDataLiving.data;
		stageDataOut.fullMask <= stageDataLiving.fullMask when flowResponse.sending = '1'
								 else (others => '0');
								 
	stageEventsOut <= stageEvents;
end Behavioral;



architecture Behavioral2 of GenericStageMulti is
	signal flowDrive: FlowDriveSimple := (others=>'0');
	signal flowResponse, flowResponse_C: FlowResponseSimple := (others=>'0');		
	signal stageData, stageDataLiving, stageDataNext, stageDataNew:
														StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	signal partialKillMask: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');	
	signal stageEvents: StageMultiEventInfo;
	
		signal contentState, contentStateNext: ContentStateSimple := DEFAULT_CS_SIMPLE;
begin
	stageDataNew <= stageDataIn;										
	stageDataNext <= stageMultiNext(stageDataLiving, stageDataNew,
								flowResponse.living, flowResponse.sending, flowDrive.prevSending);			
	stageDataLiving <= stageMultiHandleKill(stageData, flowDrive.kill, partialKillMask);


		contentStateNext <= nextContentState(contentState, flowDrive, reset, en);
		flowResponse_C <= getResponse(contentState, flowDrive);

	PIPE_CLOCKED: process(clk) 	
	begin
		if rising_edge(clk) then
			contentState <= contentStateNext;
		
			if reset = '1' then
				
			elsif en = '1' then	
				stageData <= stageDataNext;
				

				logMulti(stageData.data, stageData.fullMask, stageDataLiving.fullMask, flowResponse);
				checkMulti(stageData, stageDataNext, flowDrive, flowResponse);				
			end if;
		end if;
	end process;

	SIMPLE_SLOT_LOGIC: SimplePipeLogic port map(
		clk => clk, reset => reset, en => en,
		flowDrive => flowDrive,
		flowResponse => flowResponse
	);
	
		stageEvents <= stageMultiEvents(stageData, flowResponse.isNew);								
		partialKillMask <= stageEvents.partialKillMask;
	
	flowDrive.prevSending <= --prevSending;
										isNonzero(stageDataIn.fullMask); -- CAREFUL: The difference from Behavioral
	flowDrive.nextAccepting <= nextAccepting;
	flowDrive.kill <= execEventSignal or lateEventSignal;
	flowDrive.lockAccept <= lockCommand;

	acceptingOut <= flowResponse.accepting;		
	sendingOut <= flowResponse.sending;
	--stageDataOut <= stageDataLiving; -- TODO: clear temp ctrl info?
		stageDataOut.data <= stageDataLiving.data;
		stageDataOut.fullMask <= stageDataLiving.fullMask when flowResponse.sending = '1'
								 else (others => '0');
								 
	stageEventsOut <= stageEvents;
end Behavioral2;



architecture Renaming of GenericStageMulti is
	signal flowDrive: FlowDriveSimple := (others=>'0');
	signal flowResponse: FlowResponseSimple := (others=>'0');		
	signal stageData, stageDataLiving, stageDataNext, stageDataNew:
														StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	signal partialKillMask: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');	
	signal stageEvents: StageMultiEventInfo;
begin
	stageDataNew <= stageDataIn;--work.ProcLogicRouting.setBranchLink(stageDataIn);
	stageDataNext <= stageMultiNextCl(stageDataLiving, stageDataNew,
								flowResponse.living, flowResponse.sending, flowDrive.prevSending, false);			
	stageDataLiving <= stageMultiHandleKill(stageData, '0', partialKillMask);

	PIPE_CLOCKED: process(clk) 	
	begin
		if rising_edge(clk) then
			if reset = '1' then
				
			elsif en = '1' then	
				stageData <= stageDataNext;

				logMulti(stageData.data, stageData.fullMask, stageDataLiving.fullMask, flowResponse);
				checkMulti(stageData, stageDataNext, flowDrive, flowResponse);				
			end if;
		end if;
	end process;

	SIMPLE_SLOT_LOGIC: SimplePipeLogic port map(
		clk => clk, reset => reset, en => en,
		flowDrive => flowDrive,
		flowResponse => flowResponse
	);
	
		stageEvents <= stageMultiEvents(stageData, flowResponse.isNew);								
		partialKillMask <= stageEvents.partialKillMask;
	
	flowDrive.prevSending <= --prevSending;
										stageDataIn.fullMask(0);
	flowDrive.nextAccepting <= nextAccepting;
	flowDrive.kill <= execEventSignal or lateEventSignal;
	flowDrive.lockAccept <= lockCommand;

	acceptingOut <= flowResponse.accepting;		
	sendingOut <= flowResponse.sending;
	--stageDataOut <= stageDataLiving; -- TODO: clear temp ctrl info?
		stageDataOut.data <= stageDataLiving.data;
		stageDataOut.fullMask <= stageDataLiving.fullMask when flowResponse.sending = '1'
								 else (others => '0');
	
	stageEventsOut <= stageEvents;
end Renaming;


-- Kill signal generated only when tag comparison allows or interrupt
architecture SingleTagged of GenericStageMulti is
	signal flowDrive: FlowDriveSimple := (others=>'0');
	signal flowResponse: FlowResponseSimple := (others=>'0');		
	signal stageData, stageDataLiving, stageDataNext, stageDataNew:
														StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	signal partialKillMask: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
	signal stageEvents: StageMultiEventInfo;	
begin
	stageDataNew <= stageDataIn;										
	stageDataNext <= stageMultiNext(stageDataLiving, stageDataNew,
								flowResponse.living, flowResponse.sending, flowDrive.prevSending);			
	stageDataLiving <= stageMultiHandleKill(stageData, flowDrive.kill, partialKillMask);

	PIPE_CLOCKED: process(clk) 	
	begin
		if rising_edge(clk) then
			if reset = '1' then
				
			elsif en = '1' then	
				stageData <= stageDataNext;

				logMulti(stageData.data, stageData.fullMask, stageDataLiving.fullMask, flowResponse);
				checkMulti(stageData, stageDataNext, flowDrive, flowResponse);
			end if;
		end if;
	end process;

	SIMPLE_SLOT_LOGIC: SimplePipeLogic port map(
		clk => clk, reset => reset, en => en,
		flowDrive => flowDrive,
		flowResponse => flowResponse
	);
	
	KILLER: block
		signal before: std_logic;
		--signal a, b: std_logic_vector(7 downto 0);
		--signal c: SmallNumber := (others => '0');
	begin
		--a <= execCausing.tags.renameIndex;
		--b <= stageData.data(0).tags.renameIndex;
		--c <= subSN(a, b);
		before <= --c(7);
					 CMP_tagBefore(execCausing.tags.renameIndex, stageData.data(0).tags.renameIndex);
		flowDrive.kill <= killByTag(before, execEventSignal,
										lateEventSignal);
	end block;	

		stageEvents <= stageMultiEvents(stageData, flowResponse.isNew);
	
	flowDrive.prevSending <= --prevSending;
										stageDataIn.fullMask(0);
	flowDrive.nextAccepting <= nextAccepting;
	--flowDrive.kill <= execEventSignal;
	flowDrive.lockAccept <= lockCommand;

	acceptingOut <= flowResponse.accepting;		
	sendingOut <= flowResponse.sending;
	--stageDataOut <= stageDataLiving; -- TODO: clear temp ctrl info?
		stageDataOut.data <= stageDataLiving.data;
		stageDataOut.fullMask <= stageDataLiving.fullMask when flowResponse.sending = '1'
								 else (others => '0');
								 
	stageEventsOut <= stageEvents;
end SingleTagged;


architecture Bypassed of GenericStageMulti is
begin
	acceptingOut <= nextAccepting;		
	sendingOut <= prevSending;
	stageDataOut <= stageDataIn; -- TODO: clear temp ctrl info?
	
	stageEventsOut <= DEFAULT_STAGE_MULTI_EVENT_INFO;	
end Bypassed;
