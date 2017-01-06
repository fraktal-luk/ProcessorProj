----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:01:16 12/10/2016 
-- Design Name: 
-- Module Name:    SimpleAlu - Behavioral 
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


entity SimpleAlu is
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
		
		prevSending: in std_logic;
		nextAccepting: in std_logic;


		stageDataIn: in StageDataMulti;		
		acceptingOut: out std_logic;
		sendingOut: out std_logic;
		stageDataOut: out StageDataMulti;
		
		execEventSignal: in std_logic;
		execCausing: in InstructionState;
		lockCommand: in std_logic;
		
		stageEventsOut: out StageMultiEventInfo		
	);
end SimpleAlu;


architecture Behavioral of SimpleAlu is
	signal inputData: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	signal aluOut: InstructionState := defaultInstructionState;				
	signal aluResult: Mword := (others => '0');
	signal aluCarry: std_logic := '0';
	signal aluException: std_logic_vector(3 downto 0) := (others => '0');	
begin
	inputData.data(0) <= aluOut; -- Output of ALU
	inputData.fullMask <= stageDataIn.fullMask;
	
	STAGE_0: entity work.GenericStageMulti(SingleTagged)
	port map(
		clk => clk, reset => reset, en => en,
		
		prevSending => prevSending,
		nextAccepting => nextAccepting, --flowResponseAPost.accepting,
		
		stageDataIn => inputData, 
		acceptingOut => acceptingOut,
		sendingOut => sendingOut,
		stageDataOut => stageDataOut,
		
		execEventSignal => execEventSignal,
		execCausing => execCausing,
		lockCommand => lockCommand,
		
		stageEventsOut => stageEventsOut					
	);

	INT_ALU: entity work.IntegerAlu
	port map(
		inputInstruction => stageDataIn.data(0),
		result => aluResult,
		exc => aluException
	);
	
	aluOut <= setExecState(stageDataIn.data(0), aluResult, '0', aluException);
end Behavioral;


architecture BehavioralAGU of SimpleAlu is
	signal inputData: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	signal aluOut: InstructionState := defaultInstructionState;				
	signal aluResult: Mword := (others => '0');
	signal aluCarry: std_logic := '0';
	signal aluException: std_logic_vector(3 downto 0) := (others => '0');	
begin
	inputData.data(0) <= aluOut; -- Output of ALU
	inputData.fullMask <= stageDataIn.fullMask;
	
	STAGE_0: entity work.GenericStageMulti(SingleTagged)
	port map(
		clk => clk, reset => reset, en => en,
		
		prevSending => prevSending,
		nextAccepting => nextAccepting, --flowResponseAPost.accepting,
		
		stageDataIn => inputData, 
		acceptingOut => acceptingOut,
		sendingOut => sendingOut,
		stageDataOut => stageDataOut,
		
		execEventSignal => execEventSignal,
		execCausing => execCausing,
		lockCommand => lockCommand,
		
		stageEventsOut => stageEventsOut					
	);

--	INT_ALU: entity work.IntegerAlu
--	port map(
--		inputInstruction => stageDataIn.data(0),
--		result => aluResult,
--		exc => aluException
--	);

				NEW_ADDRESS_ADDER: entity work.IntegerAdder
				port map(
					inA => stageDataIn.data(0).argValues.arg0,
					inB => stageDataIn.data(0).argValues.arg1,
					output => aluResult
				);
	
	aluOut <= setExecState(stageDataIn.data(0), aluResult, '0', (others => '0'));
end BehavioralAGU;
