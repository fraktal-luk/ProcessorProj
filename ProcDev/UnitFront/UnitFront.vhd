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
use work.ProcHelpers.all;

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
										
		iin: in InsGroup;
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
		
		execCausing: in InstructionState;
		lateCausing: in InstructionState;
		
		execEventSignal: in std_logic;
		lateEventSignal: in std_logic;
		lateEventSetPC: in std_logic		
	);
end UnitFront;


architecture Behavioral of UnitFront is
	signal resetSig, enSig: std_logic := '0';							

	signal stageDataOutHbuffer, stageDataOut0: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;	
	signal sendingOutFetch, sendingOutHbuffer, sendingOut0: std_logic := '0';	
	signal acceptingOutFetch, acceptingOutHbuffer, acceptingOut0: std_logic := '0';
	
	signal ivalid1, ivalidFinal: std_logic := '0';
	signal sendingOutFetch1, sendingOutFetchFinal: std_logic := '0';	
	signal acceptingOutFetch1: std_logic := '0';	

	signal fetchBlock, fetchBlock1: HwordArray(0 to FETCH_BLOCK_SIZE-1) := (others => (others => '0'));

	signal fetchBlockFinal, fetchBlockBP: HwordArray(0 to FETCH_BLOCK_SIZE-1) := (others => (others => '0'));
	
	signal acceptingForFetchFirst, earlyBranchAccepting, earlyBranchSending, earlyBranchMultiSending
						: std_logic := '0'; -- earlyBranchAccepting always true?
	
	signal hbufferDataIn, stallCausing: InstructionState := DEFAULT_INSTRUCTION_STATE;

	signal frontBranchEvent, killAll, frontKill, stallEventSig: std_logic := '0';

	signal earlyBranchMultiDataIn: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

	signal sendingToEarlyBranch, fetchStall: std_logic := '0'; 
	signal pcSendingDelayed0, pcSendingDelayed1, pcSendingDelayedFinal: std_logic := '0';
	
	signal frontCausingSig, earlyBranchIn, earlyBranchDataOut: InstructionState := DEFAULT_INSTRUCTION_STATE;
	signal predictedAddress: Mword := (others => '0');

	signal newDecoded, stageDataDecodeNew: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

	signal stageDataOutFetchA, stageDataoutFetch1a, earlyBranchDataOutA:
				InstructionSlotArray(0 to 0) := (others => DEFAULT_INSTRUCTION_SLOT);

	signal earlyBranchMultiDataInA, earlyBranchMultiDataOutA, stageDataDecodeInA, stageDataDecodeOutA:
								InstructionSlotArray(0 to PIPE_WIDTH-1) := (others => DEFAULT_INSTRUCTION_SLOT);

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

	SUBUNIT_FETCH_0: entity work.GenericStageMulti(Behavioral)
	generic map(
		WIDTH => 1 --PIPE_WIDTH
	)
	port map(
		clk => clk, reset => resetSig, en => enSig,
				
		prevSending => pcSending,	
		nextAccepting => acceptingForFetchFirst,
		stageDataIn2(0) => (pcSending, pcDataLiving),
		
		acceptingOut => acceptingOutFetch,
		sendingOut => sendingOutFetch,
		stageDataOut2 => stageDataOutFetchA,
		
		execEventSignal => killAll or frontKill,
		lateEventSignal => killAll,
		execCausing => DEFAULT_INSTRUCTION_STATE
	);
			
	FETCH_DELAY: process (clk)
	begin
		if rising_edge(clk) then
			pcSendingDelayed0 <= pcSending;
			pcSendingDelayed1 <= pcSendingDelayed0;
			
			ivalid1 <= ivalid;
			fetchBlock1 <= fetchBlock;
			fetchBlockBP <= fetchBlockFinal;
		end if;	
	end process;				

	pcSendingDelayedFinal <= pcSendingDelayed1 when FETCH_DELAYED else pcSendingDelayed0;
	ivalidFinal <= ivalid1 when FETCH_DELAYED else ivalid;
	fetchBlockFinal <= fetchBlock1 when FETCH_DELAYED else fetchBlock;
	
	SUBUNIT_FETCH_1: entity work.GenericStageMulti(Bypassed)
	generic map(
		WIDTH => 1 --PIPE_WIDTH
	)
	port map(
		clk => clk, reset => resetSig, en => enSig,
				
		prevSending => sendingOutFetch,	
		nextAccepting => earlyBranchAccepting,
		stageDataIn2 => stageDataOutFetchA,
		acceptingOut => acceptingOutFetch1,
		sendingOut => sendingOutFetch1,
		stageDataOut2 => stageDataoutFetch1a,
		
		execEventSignal => killAll or frontKill,
		lateEventSignal => killAll,
		execCausing => DEFAULT_INSTRUCTION_STATE
	);	

	sendingOutFetchFinal <= sendingOutFetch1;
	acceptingForFetchFirst <= acceptingOutFetch1;
	sendingToEarlyBranch <= sendingOutFetchFinal;
				
	earlyBranchMultiDataIn <= getFrontEventMulti(predictedAddress, stageDataOutFetch1a(0).ins,
																pcSendingDelayedFinal, ivalidFinal, '1', fetchBlockFinal);
	earlyBranchMultiDataInA <= makeSlotArray(earlyBranchMultiDataIn.data, earlyBranchMultiDataIn.fullMask);
	
	SUBUNIT_EARLY_BRANCH_MULTI: entity work.GenericStageMulti(Behavioral)
	generic map(
		WIDTH => PIPE_WIDTH
	)
	port map(
		clk => clk, reset => resetSig, en => enSig,
				
		prevSending => sendingToEarlyBranch,	
		nextAccepting => '1',
		stageDataIn2 => earlyBranchMultiDataInA,
		
		acceptingOut => open,
		sendingOut => earlyBranchMultiSending,
		stageDataOut2 => earlyBranchMultiDataOutA,
		
		execEventSignal => killAll, -- CAREFUL: not killing on stall, because is sent to void
		lateEventSignal => killAll,
		execCausing => DEFAULT_INSTRUCTION_STATE
	);

	earlyBranchIn <=
		setInstructionIP(findEarlyTakenJump(stageDataOutFetch1a(0).ins, earlyBranchMultiDataIn), predictedAddress);
										
	SUBUNIT_EARLY_BRANCH: entity work.GenericStageMulti(Behavioral)
	port map(
		clk => clk, reset => resetSig, en => enSig,
				
		prevSending => sendingToEarlyBranch,	
		nextAccepting => '1',
		stageDataIn2(0) => (sendingOutFetchFinal, earlyBranchIn),
			
		acceptingOut => earlyBranchAccepting,
		sendingOut => earlyBranchSending,
		stageDataOut2 => earlyBranchDataOutA,
		
		execEventSignal => killAll, -- CAREFUL: not killing on stall, because is sent to void
		lateEventSignal => killAll,
		execCausing => DEFAULT_INSTRUCTION_STATE
	);

	earlyBranchDataOut <= earlyBranchDataOutA(0).ins;
	frontBranchEvent <= earlyBranchDataOut.controlInfo.newEvent;

	stallEventSig <= fetchStall;
	stallCausing <= setInstructionTarget(earlyBranchDataOut, earlyBranchDataOut.ip);
	frontKill <= frontBranchEvent or fetchStall;
	fetchStall <= earlyBranchSending and not acceptingOutHbuffer;

	SAVE_PRED_TARGET: process(clk)
	begin
		if rising_edge(clk) then
			if lateEventSetPC = '1' then				
				predictedAddress <= lateCausing.target;
			elsif execEventSignal = '1' then
				predictedAddress <= execCausing.target;
			elsif (stallEventSig or frontBranchEvent) = '1' then -- CAREFUL: must equal frontEventSignal
				predictedAddress <= frontCausingSig.target; -- ?
			elsif sendingToEarlyBranch = '1' then
				predictedAddress <= earlyBranchIn.target; -- ??
			end if;
		end if;
	end process;
	
	-- Hword buffer
	hbufferDataIn <= earlyBranchDataOut;
	
	SUBUNIT_HBUFFER: entity work.SubunitHbuffer(Implem)
	port map(
		clk => clk, reset => resetSig, en => enSig,
		
		prevSending => earlyBranchSending and not fetchStall,
		nextAccepting => acceptingOut0,
		stageDataIn => hbufferDataIn,
		stageDataInMulti => makeSDM(earlyBranchMultiDataOutA),
		fetchBlock => fetchBlockBP,
		
		acceptingOut => acceptingOutHbuffer,
		sendingOut => sendingOutHbuffer,
		stageDataOut => stageDataOutHbuffer,
		
		execEventSignal => killAll,--killVector(3),
		execCausing => DEFAULT_INSTRUCTION_STATE		
	);

-- Decode stage
	newDecoded <= decodeMulti(stageDataOutHbuffer);
	stageDataDecodeNew <= fillTargetsAndLinks(newDecoded);
	
	stageDataDecodeInA <= makeSlotArray(stageDataDecodeNew.data, stageDataDecodeNew.fullMask);
	
	SUBUNIT_DECODE: entity work.GenericStageMulti(Behavioral)
		generic map(
			WIDTH => PIPE_WIDTH
		)
		port map(
		clk => clk, reset => resetSig, en => enSig,
		
		prevSending => sendingOutHbuffer,	
		nextAccepting => renameAccepting,
		stageDataIn2 => stageDataDecodeInA,
		
		acceptingOut => acceptingOut0,
		sendingOut => sendingOut0,
		stageDataOut2 => stageDataDecodeOutA,

		execEventSignal => killAll,
		lateEventSignal => killAll,
		execCausing => DEFAULT_INSTRUCTION_STATE
	);	
	
	-- from later stages
	dataLastLiving <= clearTempControlInfoMulti(makeSDM(stageDataDecodeOutA));
	lastSending <= sendingOut0;
	
	frontAccepting <= acceptingOutFetch;
	
	frontEventSignal <= stallEventSig or frontBranchEvent;
	frontCausingSig <= stallCausing when stallEventSig = '1' else earlyBranchDataOut;
	frontCausing <= frontCausingSig;
end Behavioral;

