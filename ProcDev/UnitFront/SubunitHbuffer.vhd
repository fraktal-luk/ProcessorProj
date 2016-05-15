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

use work.CommonRouting.all;
use work.TEMP_DEV.all;

use work.ProcComponents.all;

use work.ProcLogicFront.all;


entity SubunitHbuffer is
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
		
		fetchBlock: in HwordArray(0 to FETCH_BLOCK_SIZE-1);
		prevSending: in std_logic;
		nextAccepting: in std_logic;
		frontEvents: in FrontEventInfo;
		stageDataIn: in StageDataPC;		
		acceptingOut: out std_logic;
		sendingOut: out std_logic;
		stageDataOut: out StageDataMulti
	);
end SubunitHbuffer;

architecture Behavioral of SubunitHbuffer is
	signal hbufferDataA, hbufferDataANext: AnnotatedHwordArray(0 to HBUFFER_SIZE-1);
	signal hbufferDataANew: AnnotatedHwordArray(0 to 2*PIPE_WIDTH-1);	
	
	signal hbufferDrive: FlowDriveBuffer := (killAll => '0', lockAccept => '0', lockSend => '0',
																others=>(others=>'0'));
	signal hbufferResponse: FlowResponseBuffer := (others=>(others=>'0'));
	-- Below: state visible to further (downstream) stages, compatible with their interface.
	--			CAREFUL! Not guaranteed to contain more than needed by next stage
	signal hbufferDriveDown: FlowDriveBuffer := (killAll => '0', lockAccept => '0', lockSend => '0',
																others=>(others=>'0'));
	signal hbufferResponseDown: FlowResponseBuffer := (others=>(others=>'0'));		

	signal shortOpcodes: std_logic_vector(0 to HBUFFER_SIZE-1) := (others=>'0');-- DEPREC but used as dummy
	signal fullMaskHbuffer, livingMaskHbuffer: std_logic_vector(0 to HBUFFER_SIZE-1) := (others=>'0');
	signal hbuffOut: HbuffOutData 
				:= (sd => DEFAULT_STAGE_DATA_MULTI, nOut=>(others=>'0'), nHOut=>(others=>'0'));
				
	signal flowDriveHBuff: FlowDriveSimple := (others=>'0');
	signal flowResponseHbuff: FlowResponseSimple := (others=>'0');	

	signal partialKillMaskHbuffer: std_logic_vector(0 to HBUFFER_SIZE-1) := (others=>'0');			
begin
	hbufferDataANew <= getAnnotatedHwords(stageDataIn, fetchBlock);
	hbufferDataANext <= bufferAHNext(hbufferDataA, hbufferDataANew,	
										stageDataIn,
										binFlowNum(hbufferResponse.living), 
										binFlowNum(hbufferResponse.sending), binFlowNum(hbufferDrive.prevSending));						
	fullMaskHbuffer <= setToOnes(shortOpcodes, binFlowNum(hbufferResponse.full));	
	livingMaskHbuffer <= setToOnes(shortOpcodes, binFlowNum(hbufferResponse.living)); -- TEMP?
	hbuffOut <= newFromHbuffer(hbufferDataA, livingMaskHbuffer);
	
	FRONT_CLOCKED: process(clk)
	begin					
		if rising_edge(clk) then
			if reset = '1' then
				
			elsif en = '1' then
				hbufferDataA <= hbufferDataANext;
			end if;					
		end if;
	end process;	

	SLOT_HBUFF: entity work.BufferPipeLogic(Behavioral) 
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
	
	hbufferDrive.prevSending <= stageDataIn.nH when prevSending = '1' -- CAREFUL: prevSending
								else 	(others=>'0');
	hbufferDrive.nextAccepting <= hbuffOut.nHOut when nextAccepting = '1'
									else (others=>'0');			
							
	hbufferDriveDown.nextAccepting <= num2flow(PIPE_WIDTH, false) when nextAccepting = '1'
										else 	(others=>'0');	
	-- CAREFUL! If in future using lockSend for Hbuff, it must be used also here, giving 0 for sending!								
	hbufferResponseDown.sending <= hbuffOut.nOut when nextAccepting = '1'
									 else (others=>'0');
	hbufferDrive.killAll <= flowDriveHbuff.kill;

	flowResponseHbuff.accepting <= 
					'1' when binFlowNum(hbufferResponse.accepting) >= binFlowNum(stageDataIn.nH) else '0';			
	flowResponseHbuff.sending <= isNonzero(hbufferResponseDown.sending);	

	hbufferDrive.kill <=	num2flow(countOnes(fullMaskHbuffer and partialKillMaskHbuffer), false);

	flowDriveHbuff.kill <= frontEvents.affectedVec(2);

	stageDataOut <= hbuffOut.sd;				
	acceptingOut <= flowResponseHbuff.accepting;	
	sendingOut <= flowResponseHbuff.sending;

end Behavioral;

