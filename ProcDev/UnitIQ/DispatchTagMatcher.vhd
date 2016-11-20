----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:07:12 05/05/2016 
-- Design Name: 
-- Module Name:    DispatchTagMatcher - Behavioral 
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

--use work.CommonRouting.all;
use work.TEMP_DEV.all;

use work.ProcLogicIQ.all;

use work.ProcComponents.all;



entity DispatchTagMatcher is
	port(
		dispatchData: in InstructionState;
		resultTags: in PhysNameArray(0 to N_RES_TAGS-1);
		ai: out ArgStatusInfo
	);
end DispatchTagMatcher;



architecture Behavioral of DispatchTagMatcher is
	signal nextResultTags: PhysNameArray(0 to N_NEXT_RES_TAGS-1) := (others => (others => '0'));
	signal writtenTags: PhysNameArray(0 to PIPE_WIDTH-1) := (others => (others => '0'));
begin													
	ai <= getForwardingStatusInfoD2(dispatchData.argValues, dispatchData.physicalArgs, 
														resultTags(0 to 3), resultTags(0 to 3), resultTags(0 to 3), 
														nextResultTags, writtenTags);
end Behavioral;

