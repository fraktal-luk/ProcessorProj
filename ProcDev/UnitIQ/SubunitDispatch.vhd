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

		prevSending: in std_logic;
	 	nextAccepting: in std_logic;

		input: in SchedulerEntrySlot;
		
		acceptingOut: out std_logic;
		output: out SchedulerEntrySlot;
		
		execEventSignal: in std_logic;
		lateEventSignal: in std_logic;
		execCausing: in InstructionState;
		
		resultTags: in PhysNameArray(0 to N_RES_TAGS-1);
		resultVals: in MwordArray(0 to N_RES_TAGS-1);
		regValues: in MwordArray(0 to 2)		
	);
end SubunitDispatch;


architecture Alternative of SubunitDispatch is
	signal inputDataWithArgs, dispatchDataUpdated, inputDataWithArgs_T, dispatchDataUpdated_T:
						SchedulerEntrySlot := DEFAULT_SCH_ENTRY_SLOT;
	signal lockSend: std_logic := '0';
	
	signal sendingOut: std_logic := '0';
	signal stageDataSaved: InstructionSlot := DEFAULT_INSTRUCTION_SLOT;	

	signal argState: SchedulerState := DEFAULT_SCHEDULER_STATE;
	--	signal ch0: std_logic := '0';
		
begin

	inputDataWithArgs <= getDispatchArgValues(input.ins, input.state, resultTags, resultVals, USE_IMM);
	
	BASIC_LOGIC: entity work.GenericStageMulti(Behavioral)
	generic map(
		COMPARE_TAG => '1'
	)
	port map(
		clk => clk, reset => reset, en => en,
		
		prevSending => prevSending,
		nextAccepting => nextAccepting,
		
		stageDataIn2(0) => (prevSending, inputDataWithArgs.ins),
		acceptingOut => acceptingOut,
		sendingOut => sendingOut,
		stageDataOut2(0) => stageDataSaved,
		
		execEventSignal => execEventSignal,
		lateEventSignal => lateEventSignal,
		execCausing => execCausing
	);

		
	SAVE_SCH_STATE: process(clk)
	begin
		if rising_edge(clk) then
			argState <= inputDataWithArgs.state; 
		end if;
	end process;

	dispatchDataUpdated <= updateDispatchArgs(stageDataSaved.ins, argState,
															resultVals(0 to 2),--N_NEXT_RES_TAGS-1),
															regValues);

	-- CAREFUL: this does nothing. To make it work:
	--											nextAcceptingEffective <= nextAccepting and not lockSend
	lockSend <= BLOCK_ISSUE_WHEN_MISSING and isNonzero(dispatchDataUpdated.state.argValues.missing);
	output <= (sendingOut, dispatchDataUpdated.ins, dispatchDataUpdated.state);
end Alternative;


