----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:18:34 03/03/2016 
-- Design Name: 
-- Module Name:    TestFrontPart0 - Behavioral 
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


entity TestFrontPart0 is
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
end TestFrontPart0;

-- TODO: add feature for invalid "instruction": when (not ivalid), cancel fetched instruction and 
--			jump back to repeat fetching (or cause exception etc)
architecture Behavioral2 of TestFrontPart0 is
	signal fetchBlock: HwordArray(0 to FETCH_BLOCK_SIZE-1);
	signal resetSig, enabled: std_logic := '0';			
																										
	signal dummyKillSignal: std_logic := '0';
	signal controlChange: std_logic := '0';
	
	signal partialKillMask0: std_logic_vector(0 to PIPE_WIDTH-1) := (others=>'0');
	signal partialKillMaskHbuffer: std_logic_vector(0 to HBUFFER_SIZE-1) := (others=>'0');		
	signal frontEvents, fe1, fe2, fe3: FrontEventInfo;	-- TEMP: fe2			
	signal frontStagesToKill: std_logic_vector(0 to 4) := (others=>'0');	

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
	PC_STAGE: block
		signal stageDataPC, stageDataPCNext, stageDataPCNew: StageDataPC := INITIAL_DATA_PC;
		
		signal flowDrivePC: FlowDriveSimple := (others=>'0');
		signal flowResponsePC: FlowResponseSimple := (others=>'0');	
	begin 	
		stageDataPCNew <= newPCData(stageDataPC, frontEvents);
		stageDataPCNext <= stagePCNext(stageDataPC, stageDataPCNew, 
												flowResponsePC.living, flowResponsePC.sending, flowDrivePC.prevSending);
		FRONT_CLOCKED: process(clk)
		begin					
			if rising_edge(clk) then
				if resetSig = '1' then
					
				elsif enabled = '1' then
					stageDataPC <= stageDataPCNext;
				end if;					
			end if;
		end process;

		SIMPLE_SLOT_LOGIC_PC: SimplePipeLogic port map(
			clk => clk, reset => resetSig, en => en,
			flowDrive => flowDrivePC,
			flowResponse => flowResponsePC
		);		

		flowDrivePC.prevSending <= flowResponsePC.accepting; -- CAREFUL! This way it never gets hungry
		flowDrivePC.nextAccepting <= acceptingOutFetch; -- flowResponseFetch.accepting;	

		flowDrivePC.kill <= frontStagesToKill(0);		

		stageDataOutPC <= stageDataPC;
		acceptingOutPC <= flowResponsePC.accepting; -- ?? Used anywhere?
		sendingOutPC <= flowResponsePC.sending;
	end block;													
												
	-- Fetch stage	
	FETCH_STAGE: block
		-- CAREFUL! Here using PC type cause is adequate.		
		signal stageDataFetch, stageDataFetchNext: StageDataPC := DEFAULT_DATA_PC;	
		
		signal flowDriveFetch: FlowDriveSimple := (others=>'0');
		signal flowResponseFetch: FlowResponseSimple := (others=>'0');		
	begin	
		-- stageDataFetchNew <= stageDataPCLiving; // in practice this means just stageDataPC?
		stageDataFetchNext <= stageFetchNext(stageDataFetch, stageDataOutPC,
						flowResponseFetch.living, flowResponseFetch.sending, flowDriveFetch.prevSending);
						
		FRONT_CLOCKED: process(clk)
		begin					
			if rising_edge(clk) then
				if resetSig = '1' then
					
				elsif enabled = '1' then
					stageDataFetch <= stageDataFetchNext;
				end if;					
			end if;
		end process;	

		SIMPLE_SLOT_LOGIC_FETCH: SimplePipeLogic port map(
			clk => clk, reset => resetSig, en => en,
			flowDrive => flowDriveFetch,
			flowResponse => flowResponseFetch
		);			
		
		flowDriveFetch.prevSending <= sendingOutPC; 
		flowDriveFetch.nextAccepting <= acceptingOutHbuffer; 				
		flowDriveFetch.lockAccept <= fetchLockCommand;	

		flowDriveFetch.kill <= frontStagesToKill(1);

		stageDataOutFetch <= stageDataFetch;
		acceptingOutFetch <= flowResponseFetch.accepting;		
		sendingOutFetch <= flowResponseFetch.sending;		
	end block;
	
	-- Hword buffer		
	HBUFFER_STAGE: block
		signal hbufferDataA, hbufferDataANext: AnnotatedHwordArray(0 to HBUFFER_SIZE-1);
		signal hbufferDataANew: AnnotatedHwordArray(0 to 2*PIPE_WIDTH-1);	
		
		signal hbufferDrive: FlowDriveBuffer := (killAll => '0', lockAccept => '0', lockSend => '0',
																	others=>(others=>'0'));
		signal hbufferResponse: FlowResponseBuffer := (others=>(others=>'0'));
		-- Below: state visible to further (downstream) stages, compatible with their interface.
		--			CAREFUL! Not guaranteed to contain more than needed by next stage
		signal hbufferDriveDown: FlowDriveBuffer := (killAll => '0', lockAccept => '0', lockSend => '0',
																	others=>(others=>'0'));
		signal hbufferResponseDown: FlowResponseBuffer := (others=>(others=>'0'));		

		signal shortOpcodes: std_logic_vector(0 to HBUFFER_SIZE-1) := (others=>'0');-- DEPREC but used as dummy
		signal fullMaskHbuffer, livingMaskHbuffer: std_logic_vector(0 to HBUFFER_SIZE-1) := (others=>'0');
		signal hbuffOut: HbuffOutData 
					:= (sd => DEFAULT_STAGE_DATA_MULTI, nOut=>(others=>'0'), nHOut=>(others=>'0'));
					
		signal flowDriveHBuff: FlowDriveSimple := (others=>'0');
		signal flowResponseHbuff: FlowResponseSimple := (others=>'0');		
	begin
		hbufferDataANew <= getAnnotatedHwords(stageDataOutFetch, fetchBlock);
		hbufferDataANext <= bufferAHNext(hbufferDataA, hbufferDataANew,	
											stageDataOutFetch,
											binFlowNum(hbufferResponse.living), 
											binFlowNum(hbufferResponse.sending), binFlowNum(hbufferDrive.prevSending));						
		fullMaskHbuffer <= setToOnes(shortOpcodes, binFlowNum(hbufferResponse.full));	
		livingMaskHbuffer <= setToOnes(shortOpcodes, binFlowNum(hbufferResponse.living)); -- TEMP?
		hbuffOut <= newFromHbuffer(hbufferDataA, livingMaskHbuffer);
		
		FRONT_CLOCKED: process(clk)
		begin					
			if rising_edge(clk) then
				if resetSig = '1' then
					
				elsif enabled = '1' then
					hbufferDataA <= hbufferDataANext;
				end if;					
			end if;
		end process;	

		SLOT_HBUFF: entity work.BufferPipeLogic(Behavioral) 
		generic map(
			CAPACITY => HBUFFER_SIZE, -- PIPE_WIDTH*2*2
			MAX_OUTPUT => PIPE_WIDTH*2,
			MAX_INPUT => PIPE_WIDTH*2
		)		
		port map(
			clk => clk, reset => resetSig, en => en,
			flowDrive => hbufferDrive,
			flowResponse => hbufferResponse
		);		
		
		hbufferDrive.prevSending <= stageDataOutFetch.nH when sendingOutFetch = '1'
									else 	(others=>'0');
		hbufferDrive.nextAccepting <= hbuffOut.nHOut when acceptingOut0 = '1'
										else (others=>'0');			
								
		hbufferDriveDown.nextAccepting <= num2flow(PIPE_WIDTH, false) when acceptingOut0 = '1'
											else 	(others=>'0');	
		-- CAREFUL! If in future using lockSend for Hbuff, it must be used also here, giving 0 for sending!								
		hbufferResponseDown.sending <= hbuffOut.nOut when acceptingOut0 = '1'
										 else (others=>'0');
		hbufferDrive.killAll <= flowDriveHbuff.kill;

		flowResponseHbuff.accepting <= 
						'1' when binFlowNum(hbufferResponse.accepting) >= binFlowNum(stageDataOutFetch.nH) else '0';			
		flowResponseHbuff.sending <= isNonzero(hbufferResponseDown.sending);	
											  --isNonzero(hbuffOut.nOut) and flowResponse0.accepting;

		hbufferDrive.kill <=	num2flow(countOnes(fullMaskHbuffer and partialKillMaskHbuffer), false);


		flowDriveHbuff.kill <= frontStagesToKill(2);

		stageDataOutHbuffer <= hbuffOut.sd;				
		acceptingOutHbuffer <= flowResponseHbuff.accepting;	
		sendingOutHbuffer <= flowResponseHbuff.sending;		
	end block;
	
	-- Decode stage
	DECODE_STAGE: block 
		signal stageData0, stageData0Living, stageData0Next, stageData0New:
															StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

		signal newDecoded: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

		signal flowDrive0: FlowDriveSimple := (others=>'0');	
		signal flowResponse0: FlowResponseSimple := (others=>'0');	
	begin	
		newDecoded <= decodeMulti(stageDataOutHbuffer);		
		stageData0New <= newDecoded;
		stageData0Next <= stageMultiNext(stageData0Living, stageData0New,		
									flowResponse0.living, flowResponse0.sending, flowDrive0.prevSending);				
		stageData0Living <= stageMultiHandleKill(stageData0, flowDrive0.kill, partialKillMask0);
		
		FRONT_CLOCKED: process(clk)
		begin					
			if rising_edge(clk) then
				if resetSig = '1' then
					
				elsif enabled = '1' then
					stageData0 <= stageData0Next;
				end if;					
			end if;
		end process;

		SIMPLE_SLOT_LOGIC_0: SimplePipeLogic port map(
			clk => clk, reset => resetSig, en => en,
			flowDrive => flowDrive0,
			flowResponse => flowResponse0
		);		

		-- Local event detection
		stage0Events <= stageMultiEvents(stageData0, flowResponse0.isNew);								
		partialKillMask0 <= stage0Events.partialKillMask;

		flowDrive0.kill <= frontStagesToKill(3);

		flowDrive0.prevSending <= sendingOutHbuffer;
		flowDrive0.nextAccepting <= renameAccepting;

		stageDataOut0 <= stageData0Living;
		acceptingOut0 <= flowResponse0.accepting;
		sendingOut0 <= flowResponse0.sending;	
	end block;
										
	FRONT_EVENT_CIRCUIT: block
	begin					
		-- Front pipe exception/branch detection:
		-- PC: branch predicted from PC?
		-- Fetch: failed fetch?
		-- Hbuff: early branch/decode exceptions
		-- 0: branch/decode exceptions
		-- 1: should never happen	
						
		controlChange <= frontEvents.eventOccured; -- execEventSignal or frontEventSignal;							
		frontEvents <= getFrontEvents(stage0Events, intSignal, execEventSignal, execCausing);
		frontStagesToKill <= frontEvents.affectedVec;		
	end block;
				
	----------------------------------------------
	iadr <= stageDataOutPC.pcBase; 
	iadrvalid <= sendingOutPC; 
	----------------------------------------------	
	fetchLockRequest <= '0'; -- TEMP?
	dataLastLiving <= stageDataOut0;
	lastSending <= sendingOut0;
	----------------------------------------------	
end Behavioral2;

