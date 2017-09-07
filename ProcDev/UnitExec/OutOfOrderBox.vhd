----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:01:07 09/07/2017 
-- Design Name: 
-- Module Name:    OutOfOrderBox - Behavioral 
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

use work.TEMP_DEV.all;
use work.GeneralPipeDev.all;

use work.ProcComponents.all;


entity OutOfOrderBox is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           en : in  STD_LOGIC;
			  
			  renamedDataLiving: in StageDataMulti;	-- INPUT			
			  renamedSending: in std_logic;
			  
			  iqAccepts: out std_logic; -- OUTPUT

	-- Sys reg interface	
			  sysRegReadSel: out slv5; -- OUTPUT  -- Doesn't need to be a port of OOO part
			  sysRegReadValue: in Mword; -- INPUT

	-- Mem interface
	        memLoadAddress: out Mword;
			  memLoadValue: in Mword;
			  memLoadAllow: out std_logic;
			  memLoadReady: in std_logic;

	-- evt
			 execEventSignalOut: out std_logic; -- OUTPUT/SIG
			 lateEventSignal: in std_logic;
			 execCausingOut: out InstructionState;

	-- Hidden to some degree, but may be useful for sth
			commitGroupCtrSig: in SmallNumber;
			commitGroupCtrNextSig: in SmallNumber; -- INPUT
		   commitGroupCtrIncSig: in SmallNumber;	-- INPUT
												
	-- ROB interface	
			robSending: out std_logic;		-- OUTPUT
			dataOutROB: out StageDataMulti;		-- OUTPUT

			sbAccepting: in std_logic;	-- INPUT
			commitAccepting: in std_logic; -- INPUT

			dataOutBQV: out StageDataMulti; -- OUTPUT
			dataOutSQ: out StageDataMulti -- OUTPUT			  
			  
			  );
end OutOfOrderBox;



architecture Behavioral of OutOfOrderBox is
	signal execEventSignal: std_logic := '0';
	signal execCausing: InstructionState := defaultInstructionState; -- OUTPUT/SIG
begin



end Behavioral;

