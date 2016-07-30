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


entity SubunitFetch is
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
			ivalid: in std_logic;
		fetchLockCommand: in std_logic;
		prevSending: in std_logic;
		nextAccepting: in std_logic;
		frontEvents: in FrontEventInfo;
		stageDataIn: in StageDataPC;		
		acceptingOut: out std_logic;
		sendingOut: out std_logic;
		stageDataOut: out StageDataPC
	);
end SubunitFetch;


architecture Behavioral of SubunitFetch is
	-- CAREFUL! Here using PC type cause is adequate.		
	signal stageDataFetch, stageDataFetchNext: StageDataPC := DEFAULT_DATA_PC;	
	
	signal flowDriveFetch: FlowDriveSimple := (others=>'0');
	signal flowResponseFetch: FlowResponseSimple := (others=>'0');		
begin	
	-- stageDataFetchNew <= stageDataPCLiving; // in practice this means just stageDataPC?
	stageDataFetchNext <= stageFetchNext(stageDataFetch, stageDataIn,
					flowResponseFetch.living, flowResponseFetch.sending, flowDriveFetch.prevSending);
					
	FRONT_CLOCKED: process(clk)
	begin					
		if rising_edge(clk) then
			if reset = '1' then
				
			elsif en = '1' then
				stageDataFetch <= stageDataFetchNext;
			end if;					
		end if;
	end process;	

	SIMPLE_SLOT_LOGIC_FETCH: SimplePipeLogic port map(
		clk => clk, reset => reset, en => en,
		flowDrive => flowDriveFetch,
		flowResponse => flowResponseFetch
	);			
	
	-- CAREFUL, TODO: cause proper control flow correction if full but ivalid = '0', cause it means
	--						failed fetch!
	
	flowDriveFetch.prevSending <= prevSending; 
	flowDriveFetch.nextAccepting <= nextAccepting; 				
	flowDriveFetch.lockAccept <= fetchLockCommand;	

	flowDriveFetch.kill <= frontEvents.affectedVec(1);

	stageDataOut <= stageDataFetch;
	acceptingOut <= flowResponseFetch.accepting;		
	sendingOut <= flowResponseFetch.sending;
end Behavioral;

