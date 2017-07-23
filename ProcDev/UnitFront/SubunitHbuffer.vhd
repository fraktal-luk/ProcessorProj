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
	signal hbufferDataA, hbufferDataANext: InstructionStateArray(0 to HBUFFER_SIZE-1)
			:= (others => DEFAULT_ANNOTATED_HWORD);
	signal hbufferDataANew: InstructionStateArray(0 to 2*PIPE_WIDTH-1)	
			:= (others => DEFAULT_ANNOTATED_HWORD);	
	
	-- DEPREC
	signal stageData, stageDataNext: StageDataHbuffer := DEFAULT_STAGE_DATA_HBUFFER;
	
	signal hbufferDrive: FlowDriveBuffer := (killAll => '0', lockAccept => '0', lockSend => '0',
																others=>(others=>'0'));
	signal hbufferResponse: FlowResponseBuffer := (others=>(others=>'0'));

	signal shortOpcodes: std_logic_vector(0 to HBUFFER_SIZE-1) := (others=>'0');-- DEPREC but used as dummy
	signal fullMaskHbuffer, livingMaskHbuffer: std_logic_vector(0 to HBUFFER_SIZE-1) := (others=>'0');
		signal fullMask2, fullMask2Next, livingMask2: std_logic_vector(0 to HBUFFER_SIZE-1) := (others=>'0');
	signal hbuffOut: HbuffOutData 
				:= (sd => DEFAULT_STAGE_DATA_MULTI, nOut=>(others=>'0'), nHOut=>(others=>'0'));

	signal partialKillMaskHbuffer: std_logic_vector(0 to HBUFFER_SIZE-1) := (others=>'0');
	signal nHIn: SmallNumber := (others => '0');
	signal sendingSig: SmallNumber := (others => '0');
	
		signal buffData, buffData2, buffDataNext: HbuffQueueData := DEFAULT_HBUFF_QUEUE_DATA;
	
begin
	nHIn <= i2slv(FETCH_BLOCK_SIZE - (slv2u(stageDataIn.basicInfo.ip(ALIGN_BITS-1 downto 1))),
					  SMALL_NUMBER_SIZE);

	hbufferDataANew <= getAnnotatedHwords(stageDataIn.basicInfo, fetchBlock);
	hbufferDataANext <= bufferAHNext(hbufferDataA,
										--livingMask2,
											fullMask2, -- NOTE: if flushing, no receiving so can be fullMask										
										hbufferDataANew,	
										DEFAULT_DATA_PC,
										stageDataIn.basicInfo,	
										--binFlowNum(hbufferResponse.living), 
											binFlowNum(hbufferResponse.full),
										--binFlowNum(hbufferResponse.sending),
											binFlowNum(hbufferDrive.nextAccepting),
										binFlowNum(hbufferDrive.prevSending));						
	fullMaskHbuffer <= setToOnes(shortOpcodes, binFlowNum(hbufferResponse.full));
		fullMask2Next <= TEMP_hbufferFullMaskNext(hbufferDataA,
											livingMask2,	
										hbufferDataANew,
											prevSending,
											DEFAULT_DATA_PC,										
										stageDataIn.basicInfo,											
										binFlowNum(hbufferResponse.living), 
										binFlowNum(hbufferResponse.sending), binFlowNum(hbufferDrive.prevSending));
		
		-- TODO: handle possibility of partial killing by partialKillMask!
		livingMask2 <= fullMask2 when --flowDriveHbuff.kill = '0' else (others => '0');
												execEventSignal = '0' else (others => '0');
-- CAREFUL:	alternative integrated version. Slower but smaller
--				stageDataNext <= TEMP_hbufferStageDataNext(
--										hbufferDataA,
--											--livingMaskHbuffer,
--											--fullMaskHbuffer,
--											livingMask2,	
--										hbufferDataANew,
--											prevSending,
--										stageDataIn_OLD,
--										binFlowNum(hbufferResponse.living), 
--										binFlowNum(hbufferResponse.sending), binFlowNum(hbufferDrive.prevSending));		
		
	livingMaskHbuffer <= setToOnes(shortOpcodes, binFlowNum(hbufferResponse.living)); -- TEMP?
	hbuffOut <= newFromHbuffer(hbufferDataA, --livingMaskHbuffer);
															livingMask2);
	
			buffDataNext <= 
			TEMP_movingQueue_q16_i8_o8(buffData,
												hbufferDataANew,
													hbufferResponse.full,
													hbufferDrive.prevSending,
													hbufferDrive.nextAccepting,
												execEventSignal,
												stageDataIn.basicInfo.ip);	
	
	FRONT_CLOCKED: process(clk)
	begin					
		if rising_edge(clk) then
			--if reset = '1' then
				
			--elsif en = '1' then
						buffData <= buffDataNext;
			
				hbufferDataA <= hbufferDataANext;
									--	stageDataNext.data;
					fullMask2 <= fullMask2Next;
									--	stageDataNext.fullMask;
				logBuffer(hbufferDataA, fullMask2, livingMask2, hbufferResponse);	
				-- NOTE: below has no info about flow constraints. It just checks data against
				--			flow numbers, while the validity of those numbers is checked by slot logic
				checkBuffer(hbufferDataA, fullMask2, hbufferDataANext, fullMask2Next,
									hbufferDrive, hbufferResponse);								
			--end if;		

					for i in 0 to fullMask2'length-1 loop
						if fullMask2Next(i) = '1' then
							assert buffDataNext.fullMask(i) = '1' report "not good maks!";
							assert buffDataNext.content(i) = hbufferDataANext(i) report "not mathcing";
						end if;
					end loop;
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

	hbufferDrive.kill <=	num2flow(countOnes(fullMaskHbuffer and partialKillMaskHbuffer));

	stageDataOut <= hbuffOut.sd;				
	acceptingOut <= not isNonzero(fullMask2(HBUFFER_SIZE - FETCH_BLOCK_SIZE to HBUFFER_SIZE-1));
							
	sendingOut <= isNonzero(sendingSig);	

end Implem;

