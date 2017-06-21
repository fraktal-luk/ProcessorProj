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

use work.TEMP_DEV.all;

use work.ProcComponents.all;

use work.ProcLogicFront.all;

use work.ProcLogicExec.all;


entity BranchUnit is
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
		-- NOTE: up to here the ports are equiv. to GenericStageMulti
		--	sysRegSel: out slv5;
		--	sysRegValue: in Mword
	);
end BranchUnit;


architecture Behavioral of BranchUnit is
	signal inputData: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	signal branchResolved: InstructionState := DEFAULT_INSTRUCTION_STATE;
begin
	inputData.data(0) <= branchResolved;
	inputData.fullMask <= stageDataIn.fullMask;
	
	STAGE_0: entity work.GenericStageMulti(Branch)
	port map(
		clk => clk, reset => reset, en => en,
		
		prevSending => prevSending,
		nextAccepting => nextAccepting,
		
		stageDataIn => inputData, 
		acceptingOut => acceptingOut,
		sendingOut => sendingOut,
		stageDataOut => stageDataOut,
		
		execEventSignal => execEventSignal,
		execCausing => execCausing,
		lockCommand => lockCommand,
		
		stageEventsOut => stageEventsOut					
	);

	branchResolved <= basicBranch(setInstructionTarget(stageDataIn.data(0),
			stageDataIn.data(0).constantArgs.imm),
											(others => '0'),--sysRegValue,
											stageDataIn.data(0).result);
	--sysRegSel <= stageDataIn.data(0).constantArgs.c1;
end Behavioral;

