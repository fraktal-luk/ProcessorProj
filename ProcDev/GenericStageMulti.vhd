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

use work.GeneralPipeDev.all;

use work.ProcComponents.all;


entity GenericStageMulti is
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
		
		prevSending: in std_logic;
		nextAccepting: in std_logic;
		execEventSignal: in std_logic;
		execCausing: in InstructionState;
		stageDataIn: in StageDataMulti;		
		acceptingOut: out std_logic;
		sendingOut: out std_logic;
		stageDataOut: out StageDataMulti
	);
end GenericStageMulti;



architecture Behavioral of GenericStageMulti is
	signal flowDrive: FlowDriveSimple := (others=>'0');
	signal flowResponse: FlowResponseSimple := (others=>'0');		
	signal stageData, stageDataLiving, stageDataNext, stageDataNew:
														StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	signal partialKillMask: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
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
			end if;
		end if;
	end process;

	SIMPLE_SLOT_LOGIC: SimplePipeLogic port map(
		clk => clk, reset => reset, en => en,
		flowDrive => flowDrive,
		flowResponse => flowResponse
	);
	
	flowDrive.prevSending <= prevSending;
	flowDrive.nextAccepting <= nextAccepting;
	flowDrive.kill <= execEventSignal;
	--flowDrive.lockAccept <= renameLockCommand;

	acceptingOut <= flowResponse.accepting;		
	sendingOut <= flowResponse.sending;
	stageDataOut <= stageDataLiving;

end Behavioral;

