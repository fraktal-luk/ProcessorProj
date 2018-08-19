----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:48:03 03/05/2016 
-- Design Name: 
-- Module Name:    TestCQPart0 - Behavioral 
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
use work.BasicFlow.all;
use work.GeneralPipeDev.all;

use work.TEMP_DEV.all;

use work.ProcComponents.all;

use work.BasicCheck.all;


entity TestCQPart0 is
	generic(
		INPUT_WIDTH: integer := 3;
		QUEUE_SIZE: integer := 2;
		OUTPUT_SIZE: integer := 1
	);
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;

		whichAcceptedCQ: out std_logic_vector(0 to 3) := (others=>'0');

		input: in InstructionSlotArray(0 to INPUT_WIDTH-1);
		
		anySending: out std_logic;		

		cqOutput: out InstructionSlotArray(0 to OUTPUT_SIZE-1);
		bufferOutput: out InstructionSlotArray(0 to QUEUE_SIZE-1);
		
		execEventSignal: in std_logic;
		execCausing: in InstructionState -- Redundant cause we have inputs from all Exec ends? 		
	);
end TestCQPart0;


architecture Implem2 of TestCQPart0 is
	signal resetSig, enSig: std_logic := '0';
	
	signal stageDataCQ, stageDataCQNext: InstructionSlotArray(0 to 1) := (others => DEFAULT_INSTRUCTION_SLOT);

	function cqDataNext(stageData: InstructionSlotArray; input: InstructionSlotArray) 
	return InstructionSlotArray is
		variable res: InstructionSlotArray(0 to 1) := (others => DEFAULT_INSTRUCTION_SLOT);
	begin
		--  Slot 0
		if stageData(1).full = '1' then
			res(0):= stageData(1);
		elsif input(0).full = '1' then
			res(0) := input(0);
		elsif input(1).full = '1' then
			res(0) := input(1);
		else
			res(0).full := '0';
			res(0).ins.physicalArgSpec.dest := (others => '0');
		end if;
		
		-- Slot 1
		if stageData(1).full = '1' and input(1).full = '1' then
			res(1):= input(1);
		elsif input(2).full = '1' then
			res(1) := input(2);
		else
			res(1).full := '0';
			res(1).ins.physicalArgSpec.dest := (others => '0');
		end if;
		
		return res;
	end function;

	constant HAS_RESET_CQ: std_logic := '0';
	constant HAS_EN_CQ: std_logic := '0';
begin
	resetSig <= reset and HAS_RESET_CQ;
	enSig <= en or not HAS_EN_CQ;

	stageDataCQNext <= cqDataNext(stageDataCQ, input);

	CQ_SYNCHRONOUS: process(clk)
	begin
		if rising_edge(clk) then	
			stageDataCQ <= stageDataCQNext;
				
				--logBuffer(stageDataCQ.data, stageDataCQ.fullMask, livingMaskCQ,
				--				flowResponseCQ);
		end if;
	end process;

	cqOutput(0) <= stageDataCQ(0);
	anySending <= stageDataCQ(0).full;

	whichAcceptedCQ <= (others => '1');
	
	bufferOutput <= (0 => stageDataCQ(0), 1 => stageDataCQ(1), others => DEFAULT_INSTRUCTION_SLOT);
end Implem2;
