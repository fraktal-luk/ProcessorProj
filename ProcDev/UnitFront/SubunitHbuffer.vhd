----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:12:19 04/24/2016 
-- Design Name: 
-- Module Name:    SubunitHbuffer - Behavioral 
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

use work.ProcComponents.all;
use work.ProcLogicFront.all;
use work.BasicCheck.all;
use work.Queues.all;

entity SubunitHbuffer is
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
		
		fetchBlock: in HwordArray(0 to FETCH_BLOCK_SIZE-1);
		prevSending: in std_logic;
		nextAccepting: in std_logic;
		execEventSignal: in std_logic;
		execCausing: in InstructionState;

		stageDataIn: in InstructionState;
		stageDataInMulti: StageDataMulti;
		acceptingOut: out std_logic;
		sendingOut: out std_logic;
		stageDataOut: out StageDataMulti
	);
end SubunitHbuffer;



architecture Implem of SubunitHbuffer is
	signal hbufferDataA, hbufferDataANext:
									InstructionStateArray(0 to HBUFFER_SIZE-1) := (others => DEFAULT_ANNOTATED_HWORD);
	signal hbufferDataANew: InstructionStateArray(0 to PIPE_WIDTH-1) := (others => DEFAULT_ANNOTATED_HWORD);

	signal hbufferDrive: FlowDriveBuffer := (killAll => '0', lockAccept => '0', lockSend => '0',
																others=>(others=>'0'));
	signal hbufferResponse: FlowResponseBuffer := (others=>(others=>'0'));

	signal fullMask, fullMaskNext, livingMask: std_logic_vector(0 to HBUFFER_SIZE-1) := (others=>'0');
	signal hbuffOut: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	signal partialKillMaskHbuffer: std_logic_vector(0 to HBUFFER_SIZE-1) := (others=>'0');
	signal nWIn, sendingSig: SmallNumber := (others => '0');
	
	signal TMP_stageData, TMP_stageDataUpdated, TMP_stageDataNext: InstructionStateArray(0 to HBUFFER_SIZE-1)
								:= (others => DEFAULT_INSTRUCTION_STATE);

	signal TMP_mask, TMP_ckEnForInput, TMP_ckEnForMoved, TMP_sendingMask, TMP_killMask, TMP_maskNext:
				std_logic_vector(0 to HBUFFER_SIZE-1) := (others => '0');
	signal qs0, qs1: TMP_queueState := TMP_defaultQueueState;
	signal ta, tb: SmallNumber := (others => '0');
		
	signal inputIndices, movedIndices: SmallNumberArray(0 to HBUFFER_SIZE-1) := (others => (others => '0'));
	
	signal TMP_offset: SmallNumber := (others => '0');
begin
	TMP_killMask <= getKillMask(TMP_stageData, TMP_mask, execCausing, '0', execEventSignal);
	qs1 <= TMP_change_Shifting(
					qs0, hbufferDrive.nextAccepting, hbufferDrive.prevSending, TMP_mask, TMP_killMask, execEventSignal);

	inputIndices <= getQueueIndicesForInput_ShiftingHbuff(
							qs0, HBUFFER_SIZE, hbufferDrive.nextAccepting, PIPE_WIDTH, TMP_offset);																					
	TMP_ckEnForInput <= getEnableForInput_Shifting(
							qs0, HBUFFER_SIZE, hbufferDrive.nextAccepting, hbufferDrive.prevSending);

	movedIndices <= getQueueIndicesForMoved_Shifting(
							qs0, HBUFFER_SIZE,	hbufferDrive.nextAccepting, hbufferDrive.prevSending);
	TMP_ckEnForMoved <= getEnableForMoved_Shifting(
							qs0, HBUFFER_SIZE, hbufferDrive.nextAccepting, hbufferDrive.prevSending);

	TMP_maskNext <= getQueueMaskNext_Shifting(qs1, HBUFFER_SIZE);
	TMP_stageDataNext <= TMP_getNewContent_General(TMP_stageData, hbufferDataANew,
															 TMP_ckEnForMoved, movedIndices,
															 TMP_ckEnForInput, inputIndices);

	TMP_offset <= getFetchOffsetW(stageDataIn.ip);

	nWIn <= i2slv(countFullNonSkipped(stageDataInMulti), SMALL_NUMBER_SIZE);

	hbufferDataANew <= getAnnotatedWords(stageDataIn, stageDataInMulti, fetchBlock);					

	livingMask <= fullMask when execEventSignal = '0' else (others => '0');
		
	hbuffOut <= newFromHbufferW(hbufferDataA, livingMask);

		hbufferDataANext <= TMP_stageDataNext;
		fullMaskNext <= TMP_maskNext;
	
		hbufferDataA <= TMP_stageData;
		fullMask <= TMP_mask;
		
	FRONT_CLOCKED: process(clk)
	begin					
		if rising_edge(clk) then
			qs0 <= qs1;
			TMP_stageData <= TMP_stageDataNext;
			TMP_mask <= TMP_maskNext;

			logBuffer(hbufferDataA, fullMask, livingMask, hbufferResponse);	
			-- NOTE: below has no info about flow constraints. It just checks data against
			--			flow numbers, while the validity of those numbers is checked by slot logic
			checkBuffer(hbufferDataA, fullMask, hbufferDataANext, fullMaskNext,
								hbufferDrive, hbufferResponse);
		end if;
	end process;	

	SLOT_HBUFF: entity work.BufferPipeLogic(BehavioralDirect)
															--BehavioralDirect)
	generic map(
		CAPACITY => HBUFFER_SIZE, -- PIPE_WIDTH*2*2
		MAX_OUTPUT => PIPE_WIDTH*2,
		MAX_INPUT => PIPE_WIDTH*2
	)		
	port map(
		clk => clk, reset => reset, en => en,
		flowDrive => hbufferDrive,
		flowResponse => hbufferResponse
	);		
	
	hbufferDrive.prevSending <= nWIn when prevSending = '1' else (others=>'0');
	hbufferDrive.nextAccepting <= --hbuffOut.nOut when nextAccepting = '1' else (others=>'0');			
					i2slv(countOnes(hbuffOut.fullMask), SMALL_NUMBER_SIZE) when nextAccepting = '1' else (others=>'0');

	-- CAREFUL! If in future using lockSend for Hbuff, it must be used also here, giving 0 for sending!								
	sendingSig <= i2slv(countOnes(hbuffOut.fullMask), SMALL_NUMBER_SIZE) when nextAccepting = '1' else (others=>'0');
	hbufferDrive.killAll <= execEventSignal;

	hbufferDrive.kill <=	num2flow(countOnes(fullMask and partialKillMaskHbuffer));

	stageDataOut.data <= hbuffOut.data;
	stageDataOut.fullMask <= hbuffOut.fullMask when isNonzero(sendingSig) = '1' else (others => '0');
	
	acceptingOut <= not isNonzero(fullMask(HBUFFER_SIZE - FETCH_BLOCK_SIZE/2 to HBUFFER_SIZE-1));
	sendingOut <= isNonzero(sendingSig);	

end Implem;

