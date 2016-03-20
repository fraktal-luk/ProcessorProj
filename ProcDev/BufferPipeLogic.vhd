----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    01:55:58 01/10/2016 
-- Design Name: 
-- Module Name:    BufferPipeLogic - Behavioral 
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

--use work.GeneralPipeDev.all;

use work.NewPipelineData.all;

entity BufferPipeLogic is
	generic (
		CAPACITY: natural := 1;
		MAX_OUTPUT: natural := 1;
		MAX_INPUT: natural := 1
	);	
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           en : in  STD_LOGIC;
				flowDrive: in FlowDriveBuffer;
				flowResponse: out FlowResponseBuffer			  
			  );	
end BufferPipeLogic;



architecture Behavioral of BufferPipeLogic is

begin
	IMPLEM: entity work.PipeStageLogicBuffer(Behavioral) generic map(
		CAPACITY => CAPACITY,
		MAX_OUTPUT => MAX_OUTPUT,
		MAX_INPUT => MAX_INPUT
	)
	port map(
		clk => clk, reset => reset, en => en,
			lockAccept => flowDrive.lockAccept,
			lockSend => flowDrive.lockSend,
		killAll => flowDrive.killAll,
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

