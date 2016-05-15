----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:19:22 05/03/2016 
-- Design Name: 
-- Module Name:    QueueTagMatcher - Behavioral 
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

use work.ProcLogicIQ.all;

use work.ProcComponents.all;


entity QueueTagMatcher is
	generic(
		IQ_SIZE: natural := 2
	);
	port(
		queueData: InstructionStateArray(0 to IQ_SIZE-1);
		resultTags: in PhysNameArray(0 to N_RES_TAGS-1);
		nextResultTags: in PhysNameArray(0 to N_RES_TAGS-1);
		vals: in MwordArray(0 to N_RES_TAGS-1);
		readyRegs: in std_logic_vector(0 to N_PHYSICAL_REGS-1);

		aiArray: out ArgStatusInfoArray(0 to IQ_SIZE-1);
		regsAllow: out std_logic_vector(0 to 3*IQ_SIZE-1) -- which args are ready in registers	
	);
end QueueTagMatcher;


architecture Behavioral of QueueTagMatcher is
	
begin
	aiArray <= getArgInfoArray(queueData, vals, resultTags, nextResultTags);
	regsAllow <= extractReadyRegBits(readyRegs, queueData);
end Behavioral;

