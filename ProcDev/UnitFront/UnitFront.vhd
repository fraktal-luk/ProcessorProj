----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:06:59 04/24/2016 
-- Design Name: 
-- Module Name:    UnitFront - Behavioral 
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


entity UnitFront is
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
		
		iin: in InsGroup; --WordArray(0 to PIPE_WIDTH-1);
		renameAccepting: in std_logic;
		execEventSignal: in std_logic;
		execCausing: in InstructionState;
		fetchLockCommand: in std_logic; 
						
		intSignal: in std_logic;				
	-- Outputs:
		iadr: out Mword;
		iadrvalid: out std_logic;
		dataLastLiving: out StageDataMulti; 
		--flowResponse0// ?? of just - 
		lastSending: out std_logic;
		fetchLockRequest: out std_logic		
	);
end UnitFront;

-- TODO: add feature for invalid "instruction": when (not ivalid), cancel fetched instruction and 
--			jump back to repeat fetching (or cause exception etc)
architecture Behavioral of UnitFront is
	signal fetchBlock: HwordArray(0 to FETCH_BLOCK_SIZE-1);
	signal resetSig, enabled: std_logic := '0';			
													
	signal frontEvents: FrontEventInfo;
	signal stage0Events: StageMultiEventInfo;	

	-- Interfaces between stages:													
	signal stageDataOutPC, stageDataOutFetch: StageDataPC := DEFAULT_DATA_PC;
	signal stageDataOutHbuffer, stageDataOut0: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	signal sendingOutPC, sendingOutFetch, sendingOutHbuffer, sendingOut0: std_logic := '0';
	signal acceptingOutPC, acceptingOutFetch, acceptingOutHbuffer, acceptingOut0: std_logic := '0';				
begin	 
	resetSig <= reset;
	enabled <= en;

	-- Fetched bits: input from instruction bus 
	FETCH_BLOCK: for i in 0 to PIPE_WIDTH-1 generate
		fetchBlock(2*i)	<= iin(i)(31 downto 16);
		fetchBlock(2*i+1) <= iin(i)(15 downto 0);
	end generate;		
								
	-- PC stage															
	SUBUNIT_PC: entity work.SubunitPC(Behavioral) port map(
		clk => clk, reset => reset, en => en,			
		nextAccepting => acceptingOutFetch,
		frontEvents =>	frontEvents,
		acceptingOut => acceptingOutPC,
		sendingOut => sendingOutPC,
		stageDataOut => stageDataOutPC
	);
		
	-- Fetch stage		
	SUBUNIT_FETCH: entity work.SubunitFetch(Behavioral) port map(
		clk => clk, reset => reset, en => en,
		fetchLockCommand => fetchLockCommand,
		prevSending => sendingOutPC,	
		nextAccepting => acceptingOutHbuffer,
		frontEvents =>	frontEvents,
		stageDataIn => stageDataOutPC,
		acceptingOut => acceptingOutFetch,
		sendingOut => sendingOutFetch,
		stageDataOut => stageDataOutFetch
	);	
	
	-- Hword buffer		
	SUBUNIT_HBUFFER: entity work.SubunitHbuffer(Behavioral) port map(
		clk => clk, reset => reset, en => en,
		fetchBlock => fetchBlock,
		prevSending => sendingOutFetch,	
		nextAccepting => acceptingOut0,
		frontEvents =>	frontEvents,
		stageDataIn => stageDataOutFetch,
		acceptingOut => acceptingOutHbuffer,
		sendingOut => sendingOutHbuffer,
		stageDataOut => stageDataOutHbuffer
	);		
	
	-- Decode stage		
	SUBUNIT_DECODE: entity work.SubunitDecode(Behavioral) port map(
		clk => clk, reset => reset, en => en,
		prevSending => sendingOutHbuffer,	
		nextAccepting => renameAccepting,
		frontEvents =>	frontEvents,
		stageDataIn => stageDataOutHbuffer,
		acceptingOut => acceptingOut0,
		sendingOut => sendingOut0,
		stageDataOut => stageDataOut0,
		stageEventsOut => stage0Events
	);	
	
			
	-- Front pipe exception/branch detection:
	-- PC: branch predicted from PC?
	-- Fetch: failed fetch?
	-- Hbuff: early branch/decode exceptions
	-- 0: branch/decode exceptions
	frontEvents <= getFrontEvents(stage0Events, intSignal, execEventSignal, execCausing);
				
	----------------------------------------------
	iadr <= stageDataOutPC.pcBase; 
	iadrvalid <= sendingOutPC; 
	----------------------------------------------	
	fetchLockRequest <= '0'; -- TEMP?
	dataLastLiving <= stageDataOut0;
	lastSending <= sendingOut0;
	----------------------------------------------	
end Behavioral;

