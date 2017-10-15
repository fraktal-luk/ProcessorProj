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
		acceptingOut: out std_logic;
		sendingOut: out std_logic;
		stageDataOut: out StageDataMulti
	);
end SubunitHbuffer;



architecture Implem of SubunitHbuffer is
	signal hbufferDataA, hbufferDataANext, hbufferDataANext_O, hbufferDataANext_N:
									InstructionStateArray(0 to HBUFFER_SIZE-1)
			:= (others => DEFAULT_ANNOTATED_HWORD);
	signal hbufferDataANew: InstructionStateArray(0 to 2*PIPE_WIDTH-1)	
			:= (others => DEFAULT_ANNOTATED_HWORD);

	signal hbufferDrive: FlowDriveBuffer := (killAll => '0', lockAccept => '0', lockSend => '0',
																others=>(others=>'0'));
	signal hbufferResponse: FlowResponseBuffer := (others=>(others=>'0'));

		signal fullMask, fullMaskNext, livingMask, fullMaskNext_O, fullMaskNext_N:
					std_logic_vector(0 to HBUFFER_SIZE-1) := (others=>'0');
	signal hbuffOut: HbuffOutData 
				:= (sd => DEFAULT_STAGE_DATA_MULTI, nOut=>(others=>'0'), nHOut=>(others=>'0'));

	signal partialKillMaskHbuffer: std_logic_vector(0 to HBUFFER_SIZE-1) := (others=>'0');
	signal nHIn: SmallNumber := (others => '0');
	signal sendingSig: SmallNumber := (others => '0');
	
		signal buffData, buffData2, buffDataNext: HbuffQueueData := DEFAULT_HBUFF_QUEUE_DATA;

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
				--ta <= hbufferDrive.nextAccepting;
				--tb <= hbufferDrive.prevSending;
				--qs1 <= TMP_change_Shifting(qs0, ta, tb, TMP_mask, TMP_killMask, execEventSignal);
				qs1 <= TMP_change_Shifting(
									qs0, hbufferDrive.nextAccepting, hbufferDrive.prevSending,
										TMP_mask, TMP_killMask, execEventSignal);
										
									--getQueueIndicesForInput_Shifting(qs0, TMP_mask, 2*PIPE_WIDTH,
									--												hbufferDrive.nextAccepting);
				inputIndices <= getQueueIndicesForInput_ShiftingHbuff(
										qs0, TMP_mask, hbufferDrive.nextAccepting, 2*PIPE_WIDTH, TMP_offset);																					
				TMP_ckEnForInput <= getEnableForInput_Shifting(
										qs0, TMP_mask, hbufferDrive.nextAccepting, hbufferDrive.prevSending);


				movedIndices <= getQueueIndicesForMoved_Shifting(
										qs0, TMP_mask,	hbufferDrive.nextAccepting, hbufferDrive.prevSending);
				TMP_ckEnForMoved <= getEnableForMoved_Shifting(
										qs0, TMP_mask, hbufferDrive.nextAccepting, hbufferDrive.prevSending);


				TMP_maskNext <= getQueueMaskNext_Shifting(qs1, TMP_mask);

				TMP_stageDataNext <= TMP_getNewContent_General(TMP_stageData, hbufferDataANew,
																		 TMP_ckEnForMoved, movedIndices,
																		 TMP_ckEnForInput, inputIndices);


			TMP_offset <= getFetchOffset(stageDataIn.basicInfo.ip);

	nHIn <= i2slv(FETCH_BLOCK_SIZE - (slv2u(stageDataIn.basicInfo.ip(ALIGN_BITS-1 downto 1))),
					  SMALL_NUMBER_SIZE);

	hbufferDataANew <= getAnnotatedHwords(stageDataIn, fetchBlock);					

		-- TODO: handle possibility of partial killing by partialKillMask?
		livingMask <= fullMask when execEventSignal = '0' else (others => '0');
		
	hbuffOut <= newFromHbuffer(hbufferDataA, livingMask);

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
	
	hbufferDrive.prevSending <= nHIn when prevSending = '1'
								else 	(others=>'0');
	hbufferDrive.nextAccepting <= hbuffOut.nHOut when nextAccepting = '1'
									else (others=>'0');			
							
	-- CAREFUL! If in future using lockSend for Hbuff, it must be used also here, giving 0 for sending!								
	sendingSig <= hbuffOut.nOut when nextAccepting = '1'
									 else (others=>'0');
	hbufferDrive.killAll <= execEventSignal;

	hbufferDrive.kill <=	num2flow(countOnes(fullMask and partialKillMaskHbuffer));

	stageDataOut <= hbuffOut.sd;				
	acceptingOut <= not isNonzero(fullMask(HBUFFER_SIZE - FETCH_BLOCK_SIZE to HBUFFER_SIZE-1));
	sendingOut <= isNonzero(sendingSig);	

end Implem;

