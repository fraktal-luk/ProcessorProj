--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;

use work.ProcBasicDefs.all;
use work.ProcInstructionsNew.all;
use work.NewPipelineData.all;
use work.GeneralPipeDev.all;

package ProcComponents is

	component SimplePipeLogic is
		port(
			clk, reset, en: in std_logic;
			--kill: in std_logic;
			flowDrive: in FlowDriveSimple;
			flowResponse: out FlowResponseSimple
		);
	end component;

	component BufferPipeLogic is
	generic (
		CAPACITY: natural := 1;
		MAX_OUTPUT: natural := 1;
		MAX_INPUT: natural := 1
	);		
		port(
			clk, reset, en: in std_logic;
			--kill: in std_logic;
			flowDrive: in FlowDriveBuffer;
			flowResponse: out FlowResponseBuffer
		);
	end component;

end ProcComponents;



package body ProcComponents is
end ProcComponents;
