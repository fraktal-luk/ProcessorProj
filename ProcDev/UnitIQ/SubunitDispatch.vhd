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

use work.CommonRouting.all;
use work.TEMP_DEV.all;

use work.ProcLogicIQ.all;

use work.ProcComponents.all;


entity SubunitDispatch is
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
		
	 	prevSending: in std_logic;
	 	nextAccepting: in std_logic;
		execEventSignal: in std_logic;
		execCausing: in InstructionState;
		ai: in ArgStatusInfo;
	 	stageDataIn: in InstructionState;		
		
		acceptingOut: out std_logic;
		--sendingOut: out std_logic;
		flowResponseOut: out FlowResponseSimple;				
		dispatchDataOut: out InstructionState;
		stageDataOut: out InstructionState		
	);
end SubunitDispatch;



architecture Behavioral of SubunitDispatch is
	signal dispatchData, dispatchDataNext, dispatchDataUpdated: InstructionState := defaultInstructionState;

	signal flowDriveDispatch: FlowDriveSimple := (others=>'0');											
	signal flowResponseDispatch: FlowResponseSimple := (others=>'0');

	signal dispatchArgsUpdated: InstructionArgValues := defaultArgValues;
			signal dispatchDataUpdated_N: InstructionState := defaultInstructionState;
			
	signal asDispatch: ArgStatusStruct;		
		constant dummyReadyRegs: std_logic_vector(0 to 2) := (others => '0');
begin	
	acceptingOut <= flowResponseDispatch.accepting;
	flowDriveDispatch.prevSending <= prevSending;
										
	DISPATCH_SYNCHRONOUS: process(clk)
	begin
		if rising_edge(clk) then
			if en = '1' then
				dispatchData <= dispatchDataNext;							
			end if;				
		end if;
	end process;
	
	dispatchDataNext <= stageSimpleNext(dispatchDataUpdated, stageDataIn,
														flowResponseDispatch.living,
														flowResponseDispatch.sending, 
														flowDriveDispatch.prevSending);
												
	-- Info about readiness now
	asDispatch <= getArgStatus(ai,		
				-- CAREFUL! "'1' or" below is to look like prev version of send locking					
				'1' or flowResponseDispatch.living, dummyReadyRegs);	

	dispatchDataUpdated <= updateInstructionArgValues2(dispatchData, ai);
	-- Don't allow exec if args somehow are not actualy ready!		
	flowDriveDispatch.lockSend <= not asDispatch.readyAll;
	
	-- Dispatch pipe logic
	SIMPLE_SLOT_LOGIC_DISPATCH_A: SimplePipeLogic port map(
		clk => clk, reset => reset, en => en,
		flowDrive => flowDriveDispatch,
		flowResponse => flowResponseDispatch
	);	
		
	DISPATCH_A_KILL: block
		signal before: std_logic;
		signal a, b: std_logic_vector(7 downto 0);
	begin
		a <= execCausing.numberTag;
		b <= dispatchData.numberTag;
		DISPATCH_KILLER: entity work.CompareBefore8 port map(
			inA => a, 
			inB => b, 
			outC => before
		);		
		flowDriveDispatch.kill <= before and execEventSignal; 	
	end block;			
				
	stageDataOut <= dispatchDataUpdated;
	flowResponseOut <= flowResponseDispatch;

	flowDriveDispatch.nextAccepting <= nextAccepting;
	
	dispatchDataOut <= dispatchData;
end Behavioral;

