----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:22:53 04/24/2016 
-- Design Name: 
-- Module Name:    SubunitPC - Behavioral 
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


entity SubunitPC is
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
		
		nextAccepting: in std_logic;
		
		frontEvents: in FrontEventInfo;
		
		acceptingOut: out std_logic;
		sendingOut: out std_logic;
		stageDataOut: out StageDataPC
	);
end SubunitPC;


architecture Behavioral of SubunitPC is
	signal dataPC, dataPCNext, dataPCNew: StageDataPC := INITIAL_DATA_PC;
	
	signal flowDrivePC: FlowDriveSimple := (others=>'0');
	signal flowResponsePC: FlowResponseSimple := (others=>'0');	
begin 	
	dataPCNew <= newPCData(dataPC, frontEvents);
	dataPCNext <= stagePCNext(dataPC, dataPCNew, 
											flowResponsePC.living, flowResponsePC.sending, flowDrivePC.prevSending);
	FRONT_CLOCKED: process(clk)
	begin					
		if rising_edge(clk) then
			if reset = '1' then
				
			elsif en = '1' then
				dataPC <= dataPCNext;
			end if;					
		end if;
	end process;

	SIMPLE_SLOT_LOGIC_PC: SimplePipeLogic port map(
		clk => clk, reset => reset, en => en,
		flowDrive => flowDrivePC,
		flowResponse => flowResponsePC
	);		

	flowDrivePC.prevSending <= flowResponsePC.accepting; -- CAREFUL! This way it never gets hungry
	flowDrivePC.nextAccepting <= nextAccepting;	

	flowDrivePC.kill <= frontEvents.affectedVec(0);		

	stageDataOut <= dataPC;
	acceptingOut <= flowResponsePC.accepting; -- Used anywhere?
	sendingOut <= flowResponsePC.sending;

end Behavioral;

