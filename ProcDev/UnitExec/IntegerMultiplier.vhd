----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:14:24 12/11/2016 
-- Design Name: 
-- Module Name:    IntegerMultiplier - Behavioral 
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

use work.ProcComponents.all;

use work.ProcLogicFront.all;

use work.ProcLogicExec.all;

use work.TEMP_DEV.all;


entity IntegerMultiplier is
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
		
		prevSending: in std_logic;
		nextAccepting: in std_logic;
		input: in SchedulerEntrySlot;

		--dataIn: in InstructionState;		
		acceptingOut: out std_logic;
		sendingOut: out std_logic;
		
			dataOut: out InstructionState;	
			data1Prev: out InstructionState; -- stage before last
			data1PrevM2: out InstructionState; -- 2 before last
		
			lateEventSignal: in std_logic;
		execEventSignal: in std_logic;
		execCausing: in InstructionState;
		lockCommand: in std_logic
		
		--stageEventsOut: out StageMultiEventInfo;		
	);
end IntegerMultiplier;



architecture Behavioral of IntegerMultiplier is
	signal inputData, outputData: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	signal data0, data1: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

	signal data0a, data1a, outputDataA: InstructionSlotArray(0 to 0) := (others => DEFAULT_INSTRUCTION_SLOT);

	signal sending0, sending1, acc1, acc2: std_logic := '0';
	
	signal dataM: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
		signal eventCausing: InstructionState := DEFAULT_INSTRUCTION_STATE;
	signal multResult: dword := (others => '0');
begin
		eventCausing <= execCausing;

	--inputData.data(0) <= dataIn;
	--inputData.fullMask(0) <= prevSending;
	
	STAGE_0: entity work.GenericStageMulti(Behavioral)
	generic map(
		COMPARE_TAG => '1'
	)
	port map(
		clk => clk, reset => reset, en => en,
		
		prevSending => prevSending,
		nextAccepting => acc1,
		
		--stageDataIn => --inputData,
		--						makeSDM((0 => (input.full, input.ins))),
		stageDataIn2 => (0 => (input.full, input.ins)),
		acceptingOut => acceptingOut,
		sendingOut => sending0,
		--stageDataOut => data0,
		stageDataOut2 => data0a,
		execEventSignal => execEventSignal,
		lateEventSignal => lateEventSignal,
		execCausing => eventCausing
		--lockCommand => '0'
		
		--stageEventsOut => open					
	);
	
	STAGE_1: entity work.GenericStageMulti(Behavioral)
	generic map(
		COMPARE_TAG => '1'
	)
	port map(
		clk => clk, reset => reset, en => en,
		
		prevSending => sending0,
		nextAccepting => acc2, --flowResponseAPost.accepting,
		
		--stageDataIn => data0,
		stageDataIn2 => data0a,
		acceptingOut => acc1,
		sendingOut => sending1,
		--stageDataOut => data1,
		stageDataOut2 => data1a,
		
		execEventSignal => execEventSignal,
		lateEventSignal => lateEventSignal,
		execCausing => eventCausing
		--lockCommand => '0'
		
		--stageEventsOut => open					
	);
	
	 --dataM.data(0) <= execLogicXor(data1.data(0));
	 --dataM.fullMask(0) <= sending1;
		
	STAGE_2: entity work.GenericStageMulti(Behavioral)
	generic map(
		COMPARE_TAG => '1'
	)
	port map(
		clk => clk, reset => reset, en => en,
		
		prevSending => sending1,
		nextAccepting => nextAccepting, --flowResponseAPost.accepting,
		
		--stageDataIn => data1,
		stageDataIn2 => data1a,
		acceptingOut => acc2,
		sendingOut => sendingOut,
		--stageDataOut => outputData,
		stageDataOut2 => outputDataA,
		
		execEventSignal => execEventSignal,
		lateEventSignal => lateEventSignal,
		execCausing => eventCausing
		--lockCommand => '0'
		
		--stageEventsOut => open					
	);		
	
	data1PrevM2 <= data0a(0).ins;
	data1Prev <= --data1.data(0);
					data1a(0).ins;
	dataOut <= setInsResult(--outputData.data(0), multResult(31 downto 0));
									 outputDataA(0).ins, multResult(31 downto 0));
	
	-- CAREFUL, TODO: implement individual CK EN for ultiplier stages or disallow stalling mul pipe!!
	MP: entity work.NewMultiplierPipe(Behavioral)
	port map(
		clk => clk, reset => reset, en => en,
		inA => input.state.argValues.arg0,
		inB => input.state.argValues.arg1,
		inC => (others => '0'),
		result => multResult
	);
	
	
end Behavioral;

