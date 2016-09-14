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
										
		-- to front pipe
		iin: in InsGroup; --WordArray(0 to PIPE_WIDTH-1);
		ivalid: in std_logic;		
		----

		-- Interface PC to front
		pcDataLiving: in StageDataPC;
		pcSending: in std_logic;
		frontAccepting: out std_logic;

		stage0EventsOut: out StageMultiEventInfo;

		-- Interface front to renaming
		renameAccepting: in std_logic;		
		dataLastLiving: out StageDataMulti; 
		lastSending: out std_logic;
		-------
			killVector: in std_logic_vector(0 to N_EVENT_AREAS-1);

		--frontEventsIn: in FrontEventInfo;  -- UNUSED
		fetchLockCommand: in std_logic
		--fetchLockRequest: out std_logic	-- UNUSED					
	);
end UnitFront;

-- TODO: add feature for invalid "instruction": when (not ivalid), cancel fetched instruction and 
--			jump back to repeat fetching (or cause exception etc)
architecture Behavioral of UnitFront is
	signal resetSig, enSig: std_logic := '0';							
	
	----------------------
	-- Internal to event part
	signal eventInsArray: InstructionSlotArray(0 to 6) := (others => DEFAULT_INSTRUCTION_SLOT);
	signal eventCauseArrayS: InstructionSlotArray(0 to 6) := (others => DEFAULT_INSTRUCTION_SLOT);
	signal eventCauseArray: InstructionStateArray(0 to 6) := (others => defaultInstructionState);
	------------------
	
	-- Interface to front pipe
	signal frontEvents: FrontEventInfo; 
		signal frontEvents_C: FrontEventInfo;	
	signal stage0Events: StageMultiEventInfo;	-- from later stages

	-- Interfaces between stages:													
	-- from PC
	signal stageDataOutPCSig: StageDataPC := DEFAULT_DATA_PC;	
	signal sendingOutPCSig: std_logic := '0';
	signal acceptingOutPC: std_logic := '0';
	--------------------
	
	signal stageDataOutFetch: StageDataPC := DEFAULT_DATA_PC;
	signal stageDataOutHbuffer, stageDataOut0: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;	
	signal sendingOutFetch, sendingOutHbuffer, sendingOut0: std_logic := '0';	
	signal acceptingOutFetch, acceptingOutHbuffer, acceptingOut0: std_logic := '0';
	
	signal fetchBlock: HwordArray(0 to FETCH_BLOCK_SIZE-1) := (others => (others => '0'));
	
		signal ivalid1: std_logic := '0';
		signal stageDataOutFetch1: StageDataPC := DEFAULT_DATA_PC;
		signal sendingOutFetch1: std_logic := '0';	
		signal acceptingOutFetch1: std_logic := '0';	

		signal fetchBlock1: HwordArray(0 to FETCH_BLOCK_SIZE-1) := (others => (others => '0'));
	
		signal ivalidFinal: std_logic := '0';
		signal fetchBlockFinal: HwordArray(0 to FETCH_BLOCK_SIZE-1) := (others => (others => '0'));
		signal stageDataOutFetchFinal:  StageDataPC := DEFAULT_DATA_PC;
		signal sendingOutFetchFinal: std_logic := '0';
		
		signal acceptingForFetchFirst: std_logic := '0';
		
		constant FETCH_DELAYED: boolean := false;
	
	constant HAS_RESET_FRONT: std_logic := '1';
	constant HAS_EN_FRONT: std_logic := '1';	
begin	 
	resetSig <= reset and HAS_RESET_FRONT;
	enSig <= en or not HAS_EN_FRONT;
												
	-- Fetched bits: input from instruction bus 
	FETCH_BLOCK: for i in 0 to PIPE_WIDTH-1 generate
		fetchBlock(2*i)	<= iin(i)(31 downto 16);
		fetchBlock(2*i+1) <= iin(i)(15 downto 0);
	end generate;			
		
	-- Fetch stage		
	SUBUNIT_FETCH_0: entity work.SubunitFetch(Behavioral) port map(
		clk => clk, reset => resetSig, en => enSig,
				
		prevSending => pcSending,	
		nextAccepting => acceptingForFetchFirst,
		stageDataIn => pcDataLiving,
		ivalid => ivalid,
		
		acceptingOut => acceptingOutFetch,
		sendingOut => sendingOutFetch,
		stageDataOut => stageDataOutFetch,
		
		-- from event part
		--frontEvents =>	frontEvents,
			killIn => killVector(1),
		fetchLockCommand => fetchLockCommand		
	);	
			
			FETCH_DELAY: process (clk)
			begin
				if rising_edge(clk) then
					if resetSig = '1' then
					
					elsif enSig = '1' then
						if sendingOutFetch = '1' then
							ivalid1 <= ivalid;
							fetchBlock1 <= fetchBlock;					
						end if;
					end if;
				end if;	
			end process;				
			
			ivalidFinal <= ivalid1 when FETCH_DELAYED else ivalid;
			fetchBlockFinal <= fetchBlock1 when FETCH_DELAYED else fetchBlock;
			
			-- CAREFUL: this part must be bypassed (architecture Bypassed) when
			--				FETCH_DELAYED is false. If true, this should be normal.	
			SUBUNIT_FETCH_1: entity work.SubunitFetch(Bypassed)
																	--(Behavioral)
			port map(
				
				clk => clk, reset => resetSig, en => enSig,
						
				prevSending => sendingOutFetch,
				nextAccepting => acceptingOutHbuffer,
				stageDataIn => stageDataOutFetch,
				ivalid => ivalid1,
				
				acceptingOut => acceptingOutFetch1,
				sendingOut => sendingOutFetch1,
				stageDataOut => stageDataOutFetch1,
				
				-- from event part
				--frontEvents =>	frontEvents,
					killIn => killVector(2),
				fetchLockCommand => '0'		
			);
	
		stageDataOutFetchFinal <= stageDataOutFetch1;
		sendingOutFetchFinal <= sendingOutFetch1;
		
		acceptingForFetchFirst <= acceptingOutFetch1;
		
	
	-- Hword buffer		
	SUBUNIT_HBUFFER: entity work.SubunitHbuffer(Behavioral) port map(
		clk => clk, reset => resetSig, en => enSig,
		
		prevSending => sendingOutFetchFinal,	
		nextAccepting => acceptingOut0,
		stageDataIn => stageDataOutFetchFinal,
		fetchBlock => fetchBlockFinal,
		
		acceptingOut => acceptingOutHbuffer,
		sendingOut => sendingOutHbuffer,
		stageDataOut => stageDataOutHbuffer,
		
		-- from event part
		--frontEvents =>	frontEvents,
			killIn => killVector(3)
	);		
	
	-- Decode stage		
	SUBUNIT_DECODE: entity work.SubunitDecode(Behavioral) port map(
		clk => clk, reset => resetSig, en => enSig,
		
		prevSending => sendingOutHbuffer,	
		nextAccepting => renameAccepting,
		stageDataIn => stageDataOutHbuffer,
		
		acceptingOut => acceptingOut0,
		sendingOut => sendingOut0,
		stageDataOut => stageDataOut0,

		-- from event part
		--frontEvents =>	frontEvents,
			killIn => killVector(4),
		-- to event part
		stageEventsOut => stage0Events
	);				
			
	-- from later stages
	dataLastLiving <= stageDataOut0;
	lastSending <= sendingOut0;
	
	frontAccepting <= acceptingOutFetch;
	stage0EventsOut <= stage0Events;
end Behavioral;

