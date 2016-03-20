----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:27:46 01/04/2016 
-- Design Name: 
-- Module Name:    SimplePipeLogic - Behavioral 
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

use work.NewPipelineData.all;
--use work.GeneralPipeDev.all;

--use work.TEMP_DEV.all;
use work.CommonRouting.all;


entity SimplePipeLogic is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           en : in  STD_LOGIC;
				flowDrive: in FlowDriveSimple;
				flowResponse: out FlowResponseSimple			  
			  );
end SimplePipeLogic;

architecture Behavioral of SimplePipeLogic is

begin
	IMPLEM: entity work.PipeStageLogicSimple(Behavioral) port map(
		clk => clk, reset => reset, en => en,
			lockAccept => flowDrive.lockAccept,
			lockSend => flowDrive.lockSend,		
		kill => flowDrive.kill,
		prevSending => flowDrive.prevSending,
		nextAccepting => flowDrive.nextAccepting,
		
		isNew => flowResponse.isNew,
		full => flowResponse.full,
		living => flowResponse.living,
		accepting => flowResponse.accepting,
		sending => flowResponse.sending
	);
	
end Behavioral;

