----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:03:19 05/05/2016 
-- Design Name: 
-- Module Name:    SubunitDispatch - Behavioral 
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

--use work.CommonRouting.all;
use work.TEMP_DEV.all;

use work.ProcLogicIQ.all;

use work.ProcComponents.all;


entity SubunitDispatch is
	generic(USE_IMM: boolean := true);
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;

	 	nextAccepting: in std_logic;
		
	 	--prevSending: in std_logic;		
	 	--stageDataIn: in InstructionState;
		input: in InstructionSlot;
		
		acceptingOut: out std_logic;
		--sendingOut: out std_logic;
		--stageDataOut: out InstructionState;
			output: out InstructionSlot;
		
		execEventSignal: in std_logic;
		lateEventSignal: in std_logic;
		execCausing: in InstructionState;
		
		resultTags: in PhysNameArray(0 to N_RES_TAGS-1);
		resultVals: in MwordArray(0 to N_RES_TAGS-1);
		regValues: in MwordArray(0 to 2)		
	);
end SubunitDispatch;


architecture Alternative of SubunitDispatch is
	signal stageDataM, stageDataStored: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	signal inputDataWithArgs, dispatchDataUpdated: InstructionState := defaultInstructionState;
	signal lockSend: std_logic := '0';
	signal nextResultTags: PhysNameArray(0 to N_NEXT_RES_TAGS-1) := (others => (others => '0'));
	signal writtenTags: PhysNameArray(0 to PIPE_WIDTH-1) := (others => (others => '0'));
	
	signal prevSending: std_logic := '0';		
	signal stageDataIn: InstructionState := DEFAULT_INSTRUCTION_STATE;
	signal sendingOut: std_logic := '0';
	signal stageDataOut: InstructionState := DEFAULT_INSTRUCTION_STATE;
begin
	prevSending <= input.full;
	stageDataIn <= input.ins;

	inputDataWithArgs <= getDispatchArgValues(stageDataIn, resultVals, USE_IMM);
	stageDataM.fullMask(0) <= prevSending;
	stageDataM.data(0) <= inputDataWithArgs;
	
	BASIC_LOGIC: entity work.GenericStageMulti(SingleTagged)
	port map(
		clk => clk, reset => reset, en => en,
		
		prevSending => prevSending,
		nextAccepting => nextAccepting,
		
		stageDataIn => stageDataM,
		acceptingOut => acceptingOut,
		sendingOut => sendingOut,
		stageDataOut => stageDataStored,
		
		execEventSignal => execEventSignal,
		lateEventSignal => lateEventSignal,
		execCausing => execCausing,
		lockCommand => '0'
	);

	dispatchDataUpdated <= updateDispatchArgs(stageDataStored.data(0), resultVals(0 to N_NEXT_RES_TAGS-1),
															regValues);

	-- CAREFUL: this does nothing. To make it work:
	--											nextAcceptingEffective <= nextAccepting and not lockSend
	lockSend <= BLOCK_ISSUE_WHEN_MISSING and isNonzero(dispatchDataUpdated.argValues.missing);
	
	stageDataOut <= dispatchDataUpdated;
	
	output <= (sendingOut, stageDataOut);
end Alternative;


