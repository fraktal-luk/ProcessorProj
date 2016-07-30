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
		ivalid: in std_logic;
		renameAccepting: in std_logic;
		execEventSignal: in std_logic;
		execCausing: in InstructionState;
		fetchLockCommand: in std_logic; 
						
		intSignal: in std_logic;
		intCausing: in InstructionState;
			sysRegReadSel: in slv5;
			sysRegReadValue: out Mword;
		
			sysRegWriteAllow: in std_logic;
			sysRegWriteSel: in slv5;
			sysRegWriteValue: in Mword;		
	-- Outputs:
		iadr: out Mword;
		iadrvalid: out std_logic;
		dataLastLiving: out StageDataMulti; 
		--flowResponse0// ?? of just - 
		lastSending: out std_logic;
		fetchLockRequest: out std_logic;
			frontEventSig: out std_logic
			
				-- TEMP
			--	eventCausingForExec: out InstructionState
	--	ilrOut: out Mword;
	--	elrOut: out Mword	
	);
end UnitFront;

-- TODO: add feature for invalid "instruction": when (not ivalid), cancel fetched instruction and 
--			jump back to repeat fetching (or cause exception etc)
architecture Behavioral of UnitFront is
	signal fetchBlock: HwordArray(0 to FETCH_BLOCK_SIZE-1);
	signal resetSig, enSig: std_logic := '0';			
													
	signal frontEvents: FrontEventInfo;
		signal frontEvents_C: FrontEventInfo;	
	signal stage0Events: StageMultiEventInfo;	

	-- Interfaces between stages:													
	signal stageDataOutPC, stageDataOutFetch: StageDataPC := DEFAULT_DATA_PC;
	signal stageDataOutHbuffer, stageDataOut0: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	signal sendingOutPC, sendingOutFetch, sendingOutHbuffer, sendingOut0: std_logic := '0';
	signal acceptingOutPC, acceptingOutFetch, acceptingOutHbuffer, acceptingOut0: std_logic := '0';
	
	signal eventInsArray: InstructionSlotArray(0 to 6) := (others => DEFAULT_INSTRUCTION_SLOT);
	signal eventCauseArrayS: InstructionSlotArray(0 to 6) := (others => DEFAULT_INSTRUCTION_SLOT);
	signal eventCauseArray: InstructionStateArray(0 to 6) := (others => defaultInstructionState);

	
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
								
	-- PC stage															
	SUBUNIT_PC: entity work.SubunitPC(Behavioral) port map(
		clk => clk, reset => resetSig, en => enSig,
		
		nextAccepting => acceptingOutFetch,
					
		acceptingOut => acceptingOutPC,
		sendingOut => sendingOutPC,
		stageDataOut => stageDataOutPC,
		
		sysRegWriteAllow => sysRegWriteAllow,
		sysRegWriteSel => sysRegWriteSel,
		sysRegWriteValue => sysRegWriteValue,

		sysRegReadSel => sysRegReadSel,
		sysRegReadValue => sysRegReadValue,
		
		frontEvents =>	frontEvents		
	);
		
	-- Fetch stage		
	SUBUNIT_FETCH: entity work.SubunitFetch(Behavioral) port map(
		clk => clk, reset => resetSig, en => enSig,
				
		prevSending => sendingOutPC,	
		nextAccepting => acceptingOutHbuffer,
		stageDataIn => stageDataOutPC,
		ivalid => ivalid,
		
		acceptingOut => acceptingOutFetch,
		sendingOut => sendingOutFetch,
		stageDataOut => stageDataOutFetch,
		
		frontEvents =>	frontEvents,
		fetchLockCommand => fetchLockCommand		
	);	
	
	-- Hword buffer		
	SUBUNIT_HBUFFER: entity work.SubunitHbuffer(Behavioral) port map(
		clk => clk, reset => resetSig, en => enSig,
		
		prevSending => sendingOutFetch,	
		nextAccepting => acceptingOut0,
		stageDataIn => stageDataOutFetch,
		fetchBlock => fetchBlock,
		
		acceptingOut => acceptingOutHbuffer,
		sendingOut => sendingOutHbuffer,
		stageDataOut => stageDataOutHbuffer,
		
		frontEvents =>	frontEvents		
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

		frontEvents =>	frontEvents,		
		stageEventsOut => stage0Events
	);	
					
			frontEvents_C <= getFrontEvents(stage0Events, intSignal, execEventSignal, execCausing);
		
	frontEvents <= getFrontEvents2(eventInsArray);
--		eventCauseArray <= (defaultInstructionState,
--												defaultInstructionState,
--												defaultInstructionState,
--												stage0Events.causing,
--												defaultInstructionState,
--												execCausing,
--												intCausing
--												);
			eventCauseArrayS(3) <= (stage0Events.eventOccured, stage0Events.causing);
			
			eventCauseArrayS(5) <= (execEventSignal, execCausing);
			eventCauseArrayS(6) <= (intSignal, intCausing);
		
		eventInsArray <= TEMP_events(eventCauseArrayS); --);
		
		
		fetchLockRequest <= 
				  	 frontEvents.eventOccured 
--				and frontEvents.causing.controlInfo.fetchLockSignal
--				and not frontEvents.fromInt; -- CAREFUL: Don't allow locking by diffrent events involving the
--														--  			instrucitons later in the pipeline!
				and frontEvents.causing.controlInfo.newFetchLock;
														
		frontEventSig <= frontEvents.eventOccured; -- ???
	----------------------------------------------
	iadr <= stageDataOutPC.pcBase; 
	iadrvalid <= sendingOutPC; 
	----------------------------------------------	

	dataLastLiving <= stageDataOut0;
	lastSending <= sendingOut0;
--			eventCausingForExec <= eventInsArray(6).ins;
	----------------------------------------------	
end Behavioral;

