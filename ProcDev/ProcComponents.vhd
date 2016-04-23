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

	component RegisterMap is
		generic(
			WIDTH: natural := 1;
			MAX_WIDTH:natural := 4
		);
		 Port ( clk : in  STD_LOGIC;
				  reset : in  STD_LOGIC;
				  en : in  STD_LOGIC;
				  rewind : in  STD_LOGIC;
				  reserveAllow : in  STD_LOGIC;
				  reserve : in  STD_LOGIC_VECTOR (0 to WIDTH-1);
				  commitAllow : in  STD_LOGIC;
				  commit : in  STD_LOGIC_VECTOR (0 to WIDTH-1);
					selectReserve: in RegNameArray(0 to WIDTH-1);
					writeReserve: in PhysNameArray(0 to WIDTH-1);
					selectCommit: in RegNameArray(0 to WIDTH-1);
					writeCommit: in PhysNameArray(0 to WIDTH-1);
					selectNewest: in RegNameArray(0 to 3*WIDTH-1);
					readNewest: out PhysNameArray(0 to 3*WIDTH-1);
					selectStable: in RegNameArray(0 to WIDTH-1);
					readStable: out PhysNameArray(0 to WIDTH-1) 			  
			  );
	end component;

	component FreeListQuad is
		generic(
			WIDTH: natural := 1;
			MAX_WIDTH: natural := 4		
		);
		 Port ( clk : in  STD_LOGIC;
				  reset : in  STD_LOGIC;
				  en : in  STD_LOGIC;
				  rewind : in  STD_LOGIC;
				  
				  writeTag: in PhysName;
				  readTags: out PhysNameArray(0 to WIDTH-1);			  
				  
				  take: in std_logic_vector(0 to WIDTH-1);
				  enableTake: in std_logic;
				  readTake: out PhysNameArray(0 to WIDTH-1);
				  
				  put: in std_logic_vector(0 to WIDTH-1);
				  enablePut: in std_logic;			  
				  writePut: in PhysNameArray(0 to WIDTH-1)
			  );
	end component;

end ProcComponents;



package body ProcComponents is
end ProcComponents;
