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
--use work.FrontPipeDev.all;

use work.CommonRouting.all;
use work.TEMP_DEV.all;

--use work.FrontPipeDevViewing.all;

--use work.Renaming1.all;


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
architecture Behavioral of TestFrontPart0 is
		signal flowDrivePC, flowDriveFetch, flowDriveHBuff, flowDrive0: FlowDriveSimple := (others=>'0');
		signal flowResponsePC, flowResponseFetch, flowResponseHbuff,
					flowResponse0: FlowResponseSimple := (others=>'0');																								
		signal hbufferDrive: FlowDriveBuffer := (killAll => '0', lockAccept => '0', lockSend => '0',
																	others=>(others=>'0'));
		signal hbufferResponse: FlowResponseBuffer := (others=>(others=>'0'));
		-- Below: state visible to further (downstream) stages, compatible with their interface.
		--			CAREFUL! Not guaranteed to contain more than needed by next stage
		signal hbufferDriveDown: FlowDriveBuffer := (killAll => '0', lockAccept => '0', lockSend => '0',
																	others=>(others=>'0'));
		signal hbufferResponseDown: FlowResponseBuffer := (others=>(others=>'0'));		

		signal fetchBlock: HwordArray(0 to FETCH_BLOCK_SIZE-1);
		signal hbufferDataA, hbufferDataANext: AnnotatedHwordArray(0 to HBUFFER_SIZE-1);
		signal hbufferDataANew: AnnotatedHwordArray(0 to 2*PIPE_WIDTH-1);
		signal shortOpcodes: std_logic_vector(0 to HBUFFER_SIZE-1) := (others=>'0');	
		signal hbd: HwordBufferData;	
		signal decoded: PipeStageData;
		signal extractedFromHbuff: InstructionStateArray(0 to PIPE_WIDTH-1) := (others=>defaultInstructionState);
		signal fullMaskHbuffer: std_logic_vector(0 to HBUFFER_SIZE-1) := (others=>'0');

		signal stageData0, stageData0Living, stageData0Next, stageData0New:
															StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
		signal dummyKillSignal: std_logic := '0';
		signal dummyControlChange: std_logic := '0';				
		signal eventMaskPC, eventMaskFetch: std_logic := '0';
		signal eventMaskHbuffer: std_logic_vector(0 to HBUFFER_SIZE-1) := (others=>'0');
		signal eventMaskS0: std_logic_vector(0 to PIPE_WIDTH-1) := (others=>'0');
		signal partialKillMask0: std_logic_vector(0 to PIPE_WIDTH-1) := (others=>'0');
		signal partialKillMaskHbuffer: std_logic_vector(0 to HBUFFER_SIZE-1) := (others=>'0');		
		signal frontEvents: FrontEventInfo;				
		signal tempTargetInfo: InstructionBasicInfo;
			
		signal stageDataPC: TEMP_StageDataPC := INITIAL_DATA_PC;
		signal stageDataPCNext: TEMP_StageDataPC;
		signal stageDataFetch: TEMP_StageDataPC -- CAREFUL! Here using PC type cause is adequate.
															:= DEFAULT_DATA_PC;
		signal stageDataFetchNext: TEMP_StageDataPC; -- ^	

		signal resetSig, enabled: std_logic := '0';	
		
		constant hEndings: MwordArray(0 to 2*PIPE_WIDTH-1) := hwordAddressEndings;
		signal movedIP: Mword := (others => '0');
		constant pcInc: Mword := (ALIGN_BITS => '1', others=>'0');
		signal newTargetSize: PipeFlow := (others=>'0');
	begin	 
		resetSig <= reset;
		enabled <= en;
	
		FRONT_CLOCKED: process(clk)
		begin						-- $input
			if rising_edge(clk) then
				if resetSig = '1' then
					-- $input
					
				elsif enabled = '1' then
						-- $input
					stageDataPC <= stageDataPCNext;
					stageDataFetch <= stageDataFetchNext;
					
					hbufferDataA <= hbufferDataANext;

					stageData0 <= stageData0Next;
				end if;					
			end if;
		end process;			
	
		-- Fetched bits: input from instruction bus 
		FETCH_BLOCK: for i in 0 to PIPE_WIDTH-1 generate
			fetchBlock(2*i)	 <= iin(i)(31 downto 16);
			fetchBlock(2*i+1) <= iin(i)(15 downto 0);
		end generate;	
					
		-- PC stage
		movedIP <= i2slv(slv2u(stageDataPC.pcBase) + slv2u(pcInc), MWORD_SIZE);					
		tempTargetInfo <= nextTargetInfo(stageDataPC, frontEvents, movedIP);
		newTargetSize <= pc2size(tempTargetInfo.ip, ALIGN_BITS, num2flow(2*PIPE_WIDTH, false));
						
		stageDataPCNext <= stagePCNext(stageDataPC, tempTargetInfo, newTargetSize,
												flowResponsePC.living, flowResponsePC.sending, flowDrivePC.prevSending);		
		-- Fetch stage										
		stageDataFetchNext <= stageFetchNext(stageDataFetch, stageDataPC,
						flowResponseFetch.living, flowResponseFetch.sending, flowDriveFetch.prevSending);
							
		-- Hword buffer							
		hbufferDataANext <= bufferAHNext(hbufferDataA, hbufferDataANew,			
											binFlowNum(hbufferResponse.living), 
											binFlowNum(hbufferResponse.sending), binFlowNum(hbufferDrive.prevSending));
		hbufferDataANew <= getAnnotatedHwords(fetchBlock,
															stageDataFetch.pcBase, stageDataFetch.basicInfo, hEndings);														
				
		hbd <= wholeInstructionData(shortOpcodes, 
									binFlowNum(hbufferResponse.living), binFlowNum(hbufferDriveDown.nextAccepting));
		extractedFromHbuff <= extractFromAH(hbufferDataA, hbd.cumulSize, hbd.readyOps, hbd.shortInstructions);									
		fullMaskHbuffer <= setToOnes(shortOpcodes, binFlowNum(hbufferResponse.full));
				
		-- Decode stage						
		DECODING: for i in 0 to PIPE_WIDTH-1 generate
			decoded(i) <= decodeInstruction(extractedFromHbuff(i));
		end generate;	
						
		stageData0New <= (fullMask => hbd.readyOps, data=>InstructionStateArray(decoded));
		stageData0Next <= stageMultiNext(stageData0Living, stageData0New,		
									flowResponse0.living, flowResponse0.sending, flowDrive0.prevSending);				
		stageData0Living <= stageMultiHandleKill(stageData0, flowDrive0.kill, partialKillMask0);

			dummyControlChange <= dummyKillSignal;
		
		SIMPLE_SLOT_LOGIC_PC: SimplePipeLogic port map(
				clk => clk, reset => resetSig, en => en,
				flowDrive => flowDrivePC,
				flowResponse => flowResponsePC
			);			
		SIMPLE_SLOT_LOGIC_FETCH: SimplePipeLogic port map(
				clk => clk, reset => resetSig, en => en,
				flowDrive => flowDriveFetch,
				flowResponse => flowResponseFetch
			);			
		SLOT_HBUFF: BufferPipeLogic 
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

			hbufferDrive.kill <=	num2flow(countOnes(fullMaskHbuffer and partialKillMaskHbuffer), false);

		SIMPLE_SLOT_LOGIC_0: SimplePipeLogic port map(
				clk => clk, reset => resetSig, en => en,
				flowDrive => flowDrive0,
				flowResponse => flowResponse0
			);						
			
		FRONT_EVENT_CIRCUIT: block
			signal frontStagesToKill: std_logic_vector(0 to 4) := (others=>'0'); --FrontStages;		
		begin	
			frontStagesToKill <= frontEvents.affectedVec;
		
			flowDrivePC.kill <= frontStagesToKill(0);		
			flowDriveFetch.kill <= frontStagesToKill(1);
			flowDriveHbuff.kill <= frontStagesToKill(2);
			flowDrive0.kill <= frontStagesToKill(3);
			--flowDrive1.kill <= frontStagesToKill(4); 		
				
			-- Front pipe exception/branch detection:
			-- PC: branch predicted from PC?
			-- Fetch: failed fetch?
			-- Hbuff: early branch/decode exceptions
			-- 0: branch/decode exceptions
			-- 1: should never happen	
			
			partialKillMaskHbuffer <= frontEvents.pHbuff;
			partialKillMask0 <= frontEvents.p0;
			--partialKillMask1 <= frontEvents.p1;
					
			dummyKillSignal <= frontEvents.eventOccured; -- execEventSignal or frontEventSignal;	
							
			frontEvents <=	TEMP_frontEvents(
												stageDataPC, stageDataFetch, hbd, stageData0, stageData0,
																											-- [no 'stageData1']
												flowResponsePC.isNew, flowResponseFetch.isNew, 
												flowResponse0.isNew, '0', -- flowResponse1.isNew, [no 'flowResponse1']
												intSignal, execEventSignal, execCausing);
												-- $input			$input
		end block;
		
		-----------------------------------------------------------------------------------------------------	
		FRONT_FLOW_LINKS: block
		begin	
			hbufferDrive.prevSending <= stageDataFetch.nH when flowResponseFetch.sending = '1'
										else 	(others=>'0');
			hbufferDrive.nextAccepting <= getHwordNumber(hbufferResponseDown.sending, hbd.cumulSize);																
										
			hbufferDriveDown.nextAccepting <= num2flow(PIPE_WIDTH, false) when flowResponse0.accepting = '1'
										else 	(others=>'0');					
			hbufferResponseDown.sending <= num2flow(countOnes(hbd.readyOps), false);					
			
			hbufferDrive.killAll <= flowDriveHbuff.kill;

			
			flowDrivePC.prevSending <= flowResponsePC.accepting; -- CAREFUL! This way it never gets hungry
			flowDrivePC.nextAccepting <= flowResponseFetch.accepting;	
				
			flowDriveFetch.prevSending <= flowResponsePC.sending;
			flowDriveFetch.nextAccepting <= flowResponseHbuff.accepting;
					
				flowDriveFetch.lockAccept <= fetchLockCommand;	
					
			flowResponseHbuff.accepting <= 
							'1' when binFlowNum(hbufferResponse.accepting) >= binFlowNum(stageDataFetch.nH) else '0';			
			flowResponseHbuff.sending <= isNonzero(hbufferResponseDown.sending);	
			
			flowDrive0.prevSending <= flowResponseHbuff.sending;
			flowDrive0.nextAccepting <= renameAccepting; -- flowResponse1.accepting;			
												-- $input	
		end block;		
		
		----------------------------------------------
		iadr <= stageDataPC.pcBase;
			-- $output
		iadrvalid <= flowResponsePC.sending;	
			-- $output
		----------------------------------------------	
				fetchLockRequest <= '0'; -- TEMP
			dataLastLiving <= stageData0Living;
			lastSending <= flowResponse0.sending; -- ?
		----------------------------------------------	
end Behavioral;

