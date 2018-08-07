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
	generic(
		USE_CLEAR: std_logic := '1';
		COMPARE_TAG: std_logic := '0';
		WIDTH: natural := 1
	);
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
		
		prevSending: in std_logic;
		nextAccepting: in std_logic;


		--stageDataIn: in StageDataMulti;
		stageDataIn2: in InstructionSlotArray(0 to WIDTH-1);
		
		acceptingOut: out std_logic;
		sendingOut: out std_logic;
		--stageDataOut: out StageDataMulti;
		stageDataOut2: out InstructionSlotArray(0 to WIDTH-1);

		execEventSignal: in std_logic;
		lateEventSignal: in std_logic;
		execCausing: in InstructionState
		--lockCommand: in std_logic		
	);
end GenericStageMulti;



architecture Behavioral of GenericStageMulti is
	signal flowDrive: FlowDriveSimple := (others=>'0');
	signal flowResponse, flowResponse_C: FlowResponseSimple := (others=>'0');		
	signal st, stNext: --, stageData, stageDataLiving, stageDataNext, stageDataNew:
														StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	--signal partialKillMask: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');		
	--signal contentState, contentStateNext: ContentStateSimple := DEFAULT_CS_SIMPLE;
	signal before: std_logic := '0';
	
	signal stageData2, stageDataNext2: InstructionSlotArray(0 to WIDTH-1) := (others => DEFAULT_INSTRUCTION_SLOT);
begin
	--stageDataNew <= stageDataIn;										
	--stageDataNext <= stageMultiNextCl(stageDataLiving, stageDataNew,
	--							flowResponse.living, flowResponse.sending, flowDrive.prevSending,
	--							flowDrive.kill and USE_CLEAR, false);			
	--stageDataLiving <= stageData; --stageMultiHandleKill(stageData, flowDrive.kill and USE_CLEAR);

	stageDataNext2 <= stageArrayNext(stageData2, stageDataIn2,
								flowResponse.living, flowResponse.sending, flowDrive.prevSending,
								flowDrive.kill and USE_CLEAR);	

	--contentStateNext <= nextContentState(contentState, flowDrive, reset, en);
	--flowResponse_C <= getResponse(contentState, flowDrive);

	st <= makeSDM(stageData2);
	stNext <= makeSDM(stageDataNext2);

	PIPE_CLOCKED: process(clk) 
	begin
		if rising_edge(clk) then
		--	contentState <= contentStateNext;		
		--	stageData <= stageDataNext;
			stageData2 <= stageDataNext2;

			logMulti(--stageData.data, stageData.fullMask, stageDataLiving.fullMask, flowResponse);
						st.data, st.fullMask, st.fullMask, flowResponse);
			checkMulti(--stageData, stageDataNext, flowDrive, flowResponse);
						st, stNext, flowDrive, flowResponse);
		end if;
	end process;

	SIMPLE_SLOT_LOGIC: SimplePipeLogic port map(
		clk => clk, reset => reset, en => en,
		flowDrive => flowDrive,
		flowResponse => flowResponse
	);

	flowDrive.prevSending <= prevSending;--isNonzero(stageDataIn.fullMask);--stageDataIn.fullMask(0);
	flowDrive.nextAccepting <= nextAccepting;
	
	--before <= '1';
	before <= (not COMPARE_TAG) or CMP_tagBefore(execCausing.tags.renameIndex, stageData2(0).ins.tags.renameIndex);
	flowDrive.kill <= (before and execEventSignal) or lateEventSignal;
	--flowDrive.lockAccept <= lockCommand;

	acceptingOut <= flowResponse.accepting;		
	sendingOut <= flowResponse.sending;
	--stageDataOut <= stageDataLiving;--.data <= stageDataLiving.data;
	--stageDataOut.fullMask <= stageDataLiving.fullMask when flowResponse.sending = '1' else (others => '0');
	stageDataOut2 <= stageData2;	
end Behavioral;


architecture Bypassed of GenericStageMulti is
begin
	acceptingOut <= nextAccepting;		
	sendingOut <= prevSending;
	--stageDataOut <= stageDataIn; -- TODO: clear temp ctrl info?	
	stageDataOut2 <= stageDataIn2;
end Bypassed;
