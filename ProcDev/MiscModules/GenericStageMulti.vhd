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
		lockCommand: in std_logic		
	);
end GenericStageMulti;



architecture Behavioral of GenericStageMulti is
	signal flowDrive: FlowDriveSimple := (others=>'0');
	signal flowResponse, flowResponse_C: FlowResponseSimple := (others=>'0');		
	signal stageData, stageDataLiving, stageDataNext, stageDataNew:
														StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	signal partialKillMask: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');		
	signal contentState, contentStateNext: ContentStateSimple := DEFAULT_CS_SIMPLE;
begin
	stageDataNew <= stageDataIn;										
	stageDataNext <= stageMultiNext(stageDataLiving, stageDataNew,
								flowResponse.living, flowResponse.sending, flowDrive.prevSending);			
	stageDataLiving <= stageMultiHandleKill(stageData, flowDrive.kill);

	contentStateNext <= nextContentState(contentState, flowDrive, reset, en);
	flowResponse_C <= getResponse(contentState, flowDrive);

	PIPE_CLOCKED: process(clk) 	
	begin
		if rising_edge(clk) then
			contentState <= contentStateNext;		
			stageData <= stageDataNext;

			logMulti(stageData.data, stageData.fullMask, stageDataLiving.fullMask, flowResponse);
			checkMulti(stageData, stageDataNext, flowDrive, flowResponse);				
		end if;
	end process;

	SIMPLE_SLOT_LOGIC: SimplePipeLogic port map(
		clk => clk, reset => reset, en => en,
		flowDrive => flowDrive,
		flowResponse => flowResponse
	);

	flowDrive.prevSending <= isNonzero(stageDataIn.fullMask);--stageDataIn.fullMask(0);
	flowDrive.nextAccepting <= nextAccepting;
	flowDrive.kill <= execEventSignal or lateEventSignal;
	flowDrive.lockAccept <= lockCommand;

	acceptingOut <= flowResponse.accepting;		
	sendingOut <= flowResponse.sending;
	stageDataOut.data <= stageDataLiving.data;
	stageDataOut.fullMask <= stageDataLiving.fullMask when flowResponse.sending = '1' else (others => '0');								 
end Behavioral;



architecture Behavioral2 of GenericStageMulti is
	signal flowDrive: FlowDriveSimple := (others=>'0');
	signal flowResponse, flowResponse_C: FlowResponseSimple := (others=>'0');		
	signal stageData, stageDataLiving, stageDataNext, stageDataNew:
														StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	signal partialKillMask: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');	
	signal contentState, contentStateNext: ContentStateSimple := DEFAULT_CS_SIMPLE;
begin
	stageDataNew <= stageDataIn;										
	stageDataNext <= stageMultiNext(stageDataLiving, stageDataNew,
								flowResponse.living, flowResponse.sending, flowDrive.prevSending);			
	stageDataLiving <= stageMultiHandleKill(stageData, flowDrive.kill);

	contentStateNext <= nextContentState(contentState, flowDrive, reset, en);
	flowResponse_C <= getResponse(contentState, flowDrive);

	PIPE_CLOCKED: process(clk) 	
	begin
		if rising_edge(clk) then
			contentState <= contentStateNext;
			stageData <= stageDataNext;
				
			logMulti(stageData.data, stageData.fullMask, stageDataLiving.fullMask, flowResponse);
			checkMulti(stageData, stageDataNext, flowDrive, flowResponse);				
		end if;
	end process;

	SIMPLE_SLOT_LOGIC: SimplePipeLogic port map(
		clk => clk, reset => reset, en => en,
		flowDrive => flowDrive,
		flowResponse => flowResponse
	);

	flowDrive.prevSending <= isNonzero(stageDataIn.fullMask); -- CAREFUL: The difference from Behavioral
	flowDrive.nextAccepting <= nextAccepting;
	flowDrive.kill <= execEventSignal or lateEventSignal;
	flowDrive.lockAccept <= lockCommand;

	acceptingOut <= flowResponse.accepting;		
	sendingOut <= flowResponse.sending;
	stageDataOut.data <= stageDataLiving.data;
	stageDataOut.fullMask <= stageDataLiving.fullMask when flowResponse.sending = '1' else (others => '0');
end Behavioral2;



architecture Renaming of GenericStageMulti is
	signal flowDrive: FlowDriveSimple := (others=>'0');
	signal flowResponse: FlowResponseSimple := (others=>'0');		
	signal stageData, stageDataLiving, stageDataNext, stageDataNew:
														StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	signal partialKillMask: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');	
begin
	stageDataNew <= stageDataIn;--work.ProcLogicRouting.setBranchLink(stageDataIn);
	stageDataNext <= stageMultiNextCl(stageDataLiving, stageDataNew,
								flowResponse.living, flowResponse.sending, flowDrive.prevSending, false);			
	stageDataLiving <= stageMultiHandleKill(stageData, '0');

	PIPE_CLOCKED: process(clk) 	
	begin
		if rising_edge(clk) then
			stageData <= stageDataNext;

			logMulti(stageData.data, stageData.fullMask, stageDataLiving.fullMask, flowResponse);
			checkMulti(stageData, stageDataNext, flowDrive, flowResponse);
		end if;
	end process;

	SIMPLE_SLOT_LOGIC: SimplePipeLogic port map(
		clk => clk, reset => reset, en => en,
		flowDrive => flowDrive,
		flowResponse => flowResponse
	);

	flowDrive.prevSending <= stageDataIn.fullMask(0);
	flowDrive.nextAccepting <= nextAccepting;
	flowDrive.kill <= execEventSignal or lateEventSignal;
	flowDrive.lockAccept <= lockCommand;

	acceptingOut <= flowResponse.accepting;		
	sendingOut <= flowResponse.sending;
	stageDataOut.data <= stageDataLiving.data;
	stageDataOut.fullMask <= stageDataLiving.fullMask when flowResponse.sending = '1' else (others => '0');	
end Renaming;


-- Kill signal generated only when tag comparison allows or interrupt
architecture SingleTagged of GenericStageMulti is
	signal flowDrive: FlowDriveSimple := (others=>'0');
	signal flowResponse: FlowResponseSimple := (others=>'0');		
	signal stageData, stageDataLiving, stageDataNext, stageDataNew: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	signal partialKillMask: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
begin
	stageDataNew <= stageDataIn;										
	stageDataNext <= stageMultiNext(stageDataLiving, stageDataNew,
								flowResponse.living, flowResponse.sending, flowDrive.prevSending);			
	stageDataLiving <= stageMultiHandleKill(stageData, flowDrive.kill);

	PIPE_CLOCKED: process(clk) 	
	begin
		if rising_edge(clk) then
			stageData <= stageDataNext;

			logMulti(stageData.data, stageData.fullMask, stageDataLiving.fullMask, flowResponse);
			checkMulti(stageData, stageDataNext, flowDrive, flowResponse);
		end if;
	end process;

	SIMPLE_SLOT_LOGIC: SimplePipeLogic port map(
		clk => clk, reset => reset, en => en,
		flowDrive => flowDrive,
		flowResponse => flowResponse
	);
	
	KILLER: block
		signal before: std_logic;
	begin
		before <= CMP_tagBefore(execCausing.tags.renameIndex, stageData.data(0).tags.renameIndex);
		flowDrive.kill <= killByTag(before, execEventSignal,
										lateEventSignal);
	end block;	
	
	flowDrive.prevSending <= stageDataIn.fullMask(0);
	flowDrive.nextAccepting <= nextAccepting;
	flowDrive.lockAccept <= lockCommand;

	acceptingOut <= flowResponse.accepting;		
	sendingOut <= flowResponse.sending;
	stageDataOut.data <= stageDataLiving.data;
	stageDataOut.fullMask <= stageDataLiving.fullMask when flowResponse.sending = '1' else (others => '0');
end SingleTagged;


architecture Bypassed of GenericStageMulti is
begin
	acceptingOut <= nextAccepting;		
	sendingOut <= prevSending;
	stageDataOut <= stageDataIn; -- TODO: clear temp ctrl info?	
end Bypassed;
