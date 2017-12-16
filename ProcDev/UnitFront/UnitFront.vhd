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

use work.TEMP_DEV.all;

use work.ProcComponents.all;

use work.ProcLogicFront.all;

use work.ProcLogicSequence.all;


entity UnitFront is
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
										
		iin: in InsGroup; --WordArray(0 to PIPE_WIDTH-1);
		ivalid: in std_logic;		

		-- Interface PC to front
		pcDataLiving: in InstructionState;
		pcSending: in std_logic;
		frontAccepting: out std_logic;

		-- Interface front to renaming
		renameAccepting: in std_logic;		
		dataLastLiving: out StageDataMulti; 
		lastSending: out std_logic;
		-------
		
		frontEventSignal: out std_logic;
		frontCausing: out InstructionState;
		
		execEventSignal: in std_logic;
		lateEventSignal: in std_logic		
	);
end UnitFront;


architecture Behavioral of UnitFront is
	signal resetSig, enSig: std_logic := '0';							
		
	signal stage0Events: StageMultiEventInfo;	-- from later stages

	-- Interfaces between stages:														
	signal stageDataOutFetch: InstructionState := DEFAULT_DATA_PC;
	signal stageDataOutHbuffer, stageDataOut0: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;	
	signal sendingOutFetch, sendingOutHbuffer, sendingOut0: std_logic := '0';	
	signal acceptingOutFetch, acceptingOutHbuffer, acceptingOut0: std_logic := '0';
	
	signal fetchBlock: HwordArray(0 to FETCH_BLOCK_SIZE-1) := (others => (others => '0'));
	
		signal ivalid1: std_logic := '0';
		signal stageDataOutFetch1: InstructionState := DEFAULT_DATA_PC;
		signal sendingOutFetch1: std_logic := '0';	
		signal acceptingOutFetch1: std_logic := '0';	

		signal fetchBlock1, fetchBlockBP: HwordArray(0 to FETCH_BLOCK_SIZE-1) := (others => (others => '0'));
	
		signal ivalidFinal: std_logic := '0';
		signal fetchBlockFinal: HwordArray(0 to FETCH_BLOCK_SIZE-1) := (others => (others => '0'));
		signal stageDataOutFetchFinal:  InstructionState := DEFAULT_DATA_PC;
		signal sendingOutFetchFinal: std_logic := '0';
		
		signal acceptingForFetchFirst, earlyBranchAccepting, earlyBranchSending: std_logic := '0';
		
		signal hbufferDataIn, stallCausing: InstructionState := DEFAULT_INSTRUCTION_STATE;
	
		signal killAll, frontKill, stallEventSig: std_logic := '0';
	
		signal earlyBranchDataIn, earlyBranchDataOut: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	
		signal sendingToEarlyBranch, stallAtFetchLast, fetchStall: std_logic := '0'; 
		signal pcSendingDelayed0, pcSendingDelayed1, pcSendingDelayedFinal: std_logic := '0';
	
	constant HAS_RESET_FRONT: std_logic := '0';
	constant HAS_EN_FRONT: std_logic := '0';	
begin	 
	resetSig <= reset and HAS_RESET_FRONT;
	enSig <= en or not HAS_EN_FRONT;
			
		killAll <= execEventSignal or lateEventSignal;
			
	-- Fetched bits: input from instruction bus 
	FETCH_BLOCK: for i in 0 to PIPE_WIDTH-1 generate
		fetchBlock(2*i)	<= iin(i)(31 downto 16);
		fetchBlock(2*i+1) <= iin(i)(15 downto 0);
	end generate;			
	
	-- Fetch stage				
	STAGE_FETCH_0: block
		signal f0input, f0output: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	begin
		f0input.fullMask(0) <= pcSending;
		f0input.data(0) <= pcDataLiving;
	
		SUBUNIT_FETCH_0: entity work.GenericStageMulti(Behavioral) port map(
			clk => clk, reset => resetSig, en => enSig,
					
			prevSending => pcSending,	
			nextAccepting => acceptingForFetchFirst,
			stageDataIn => f0input,
			
			acceptingOut => acceptingOutFetch,
			sendingOut => sendingOutFetch,
			stageDataOut => f0output,
			
			execEventSignal => killAll or frontKill,--killVector(1),
			lateEventSignal => killAll,
			execCausing => DEFAULT_INSTRUCTION_STATE,
			lockCommand => '0'		
		);	
		
		stageDataOutFetch <= f0output.data(0);
	end block;
			
	FETCH_DELAY: process (clk)
	begin
		if rising_edge(clk) then
			--if sendingOutFetch = '1' then
				pcSendingDelayed0 <= pcSending;
				pcSendingDelayed1 <= pcSendingDelayed0;
				
				ivalid1 <= ivalid;
				fetchBlock1 <= fetchBlock;

				fetchBlockBP <= fetchBlockFinal;
			--end if;
		end if;	
	end process;				

	pcSendingDelayedFinal <= pcSendingDelayed1 when FETCH_DELAYED else pcSendingDelayed0;
	ivalidFinal <= ivalid1 when FETCH_DELAYED else ivalid;
	fetchBlockFinal <= fetchBlock1 when FETCH_DELAYED else fetchBlock;
	
	-- CAREFUL: this part must be bypassed (architecture Bypassed) when
	--				FETCH_DELAYED is false. If true, this should be normal.		
	STAGE_FETCH_1: block
		signal f1input, f1output: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	begin
		f1input.fullMask(0) <= sendingOutFetch;
		f1input.data(0) <= stageDataOutFetch;
	
		SUBUNIT_FETCH_1: entity work.GenericStageMulti(Bypassed) port map(
			clk => clk, reset => resetSig, en => enSig,
					
			prevSending => sendingOutFetch,	
			nextAccepting => earlyBranchAccepting,
			stageDataIn => f1input,
			
			acceptingOut => acceptingOutFetch1,
			sendingOut => sendingOutFetch1,
			stageDataOut => f1output,
			
			execEventSignal => killAll or frontKill, --killVector(1),
			lateEventSignal => killAll,
			execCausing => DEFAULT_INSTRUCTION_STATE,
			lockCommand => '0'		
		);	
		
		stageDataOutFetch1 <= f1output.data(0);
	end block;	

	stageDataOutFetchFinal <= stageDataOutFetch1;
	sendingOutFetchFinal <= sendingOutFetch1;
	
	acceptingForFetchFirst <= acceptingOutFetch1;
	
	hbufferDataIn <= checkIvalid(earlyBranchDataOut.data(0), '1');
	
			earlyBranchDataIn.data(0) <= getFrontEvent(stageDataOutFetchFinal,
															pcSendingDelayedFinal, ivalidFinal, '1',
															fetchBlockFinal);
			earlyBranchdataIn.fullMask(0) <= pcSendingDelayedFinal;
			
			sendingToEarlyBranch <= sendingOutFetchFinal;
											
			SUBUNIT_EARLY_BRANCH: entity work.GenericStageMulti(Behavioral)
			port map(
					clk => clk, reset => resetSig, en => enSig,
							
					prevSending => sendingToEarlyBranch,	
					nextAccepting => '1',--acceptingOutHbuffer,
					stageDataIn => earlyBranchDataIn,
					
					acceptingOut => earlyBranchAccepting,
					sendingOut => earlyBranchSending,
					stageDataOut => earlyBranchDataOut,
					
					execEventSignal => killAll, -- CAREFUL: not killing on stall, because is sent to void
					lateEventSignal => killAll,
					execCausing => DEFAULT_INSTRUCTION_STATE,
					lockCommand => '0',

					stageEventsOut => stage0Events
			);	
	
			stallEventSig <= fetchStall;
			stallCausing <= setInstructionTarget(earlyBranchDataOut.data(0),
															 earlyBranchDataOut.data(0).basicInfo.ip);
			frontKill <= stage0Events.eventOccured or fetchStall;
			fetchStall <= earlyBranchSending and not acceptingOutHbuffer;
	
	-- Hword buffer		
	SUBUNIT_HBUFFER: entity work.SubunitHbuffer(Implem)
	port map(
		clk => clk, reset => resetSig, en => enSig,
		
		prevSending => earlyBranchSending and not fetchStall,
		nextAccepting => acceptingOut0,
		stageDataIn => hbufferDataIn,
		fetchBlock => fetchBlockBP,
		
		acceptingOut => acceptingOutHbuffer,
		sendingOut => sendingOutHbuffer,
		stageDataOut => stageDataOutHbuffer,
		
		execEventSignal => killAll,--killVector(3),
		execCausing => DEFAULT_INSTRUCTION_STATE		
	);		
	
	
	-- Decode stage				
	STAGE_DECODE: block
		signal newDecoded, newDecodedWithTargets, stageDataDecodeNew, stageDataDecodeOut: StageDataMulti
				:= DEFAULT_STAGE_DATA_MULTI;
		signal targets, links: MwordArray(0 to PIPE_WIDTH-1) := (others => (others => '0'));				
	begin	
		newDecoded <= decodeMulti(stageDataOutHbuffer);

		newDecodedWithTargets.fullMask <= newDecoded.fullMask;
		
		CALC_TARGETS: for i in 0 to PIPE_WIDTH-1 generate
		begin	
			newDecodedWithTargets.data(i) <=
				setInsResult(setInstructionTarget(newDecoded.data(i), targets(i)), links(i));

			targets(i) <= addMwordFaster(newDecoded.data(i).basicInfo.ip, newDecoded.data(i).constantArgs.imm);		
			links(i) <= addMwordBasic(newDecoded.data(i).basicInfo.ip, getAddressIncrement(newDecoded.data(i)));			
		end generate;	

		stageDataDecodeNew <= newDecodedWithTargets when EARLY_TARGET_ENABLE
								else newDecoded;	
		SUBUNIT_DECODE: entity work.GenericStageMulti(Behavioral)
			port map(
			clk => clk, reset => resetSig, en => enSig,
			
			prevSending => sendingOutHbuffer,	
			nextAccepting => renameAccepting,
			stageDataIn => stageDataDecodeNew,
			
			acceptingOut => acceptingOut0,
			sendingOut => sendingOut0,
			stageDataOut => stageDataDecodeOut,

			execEventSignal => killAll,
			lateEventSignal => killAll,
			execCausing => DEFAULT_INSTRUCTION_STATE,
			lockCommand => '0',
			-- to event part
			stageEventsOut => open--stage0Events
		);	
		
		stageDataOut0 <= clearTempControlInfoMulti(stageDataDecodeOut);
	end block;	
		
	-- from later stages
	dataLastLiving <= stageDataOut0;
	lastSending <= sendingOut0;
	
	frontAccepting <= acceptingOutFetch;
	
		frontEventSignal <= stallEventSig or stage0Events.eventOccured;
		frontCausing <= stallCausing when stallEventSig = '1' else stage0Events.causing;
end Behavioral;

