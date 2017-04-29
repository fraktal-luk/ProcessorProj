----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:33:36 12/08/2015 
-- Design Name: 
-- Module Name:    NewCore0 - Behavioral 
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

entity NewCore0 is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           en : in  STD_LOGIC;
			  
			  -- address fot program mem
           iadrvalid: out std_logic;
			  iadr : out  Mword;
			  -- instruction input
			  ivalid: in std_logic;
           iin : in  InsGroup;
			  
			  -- Mem load interface
			  dread: out std_logic;
           dadr : out  Mword;
			  dvalid: in std_logic;			  
           din : in  Mword;
			  
			  -- Mem store interface
			  dwrite: out std_logic;
			  doutadr: out Mword;
           dout : out  Mword;
			  			  
			  -- Interrupt input (int0) and additional input (int1)
           int0 : in  STD_LOGIC;
           int1 : in  STD_LOGIC;
			  
			  -- Other buses for development 
           iaux : in  Mword;
           oaux : out  Mword			  
			  
			  );
end NewCore0;

