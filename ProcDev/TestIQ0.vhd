----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:26:00 02/29/2016 
-- Design Name: 
-- Module Name:    TestIQ0 - Behavioral 
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


entity TestIQ0 is
	generic(
		IQ_SIZE: natural := 2--;
		--N_RESULT_TAGS: natural := 1
	);
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;		
		
		resultTags: in PhysNameArray(0 to N_RES_TAGS-1);
		nextResultTags: in PhysNameArray(0 to N_RES_TAGS-1);
		dummyVals: in MwordArray(0 to N_RES_TAGS-1);
		readyRegs: in std_logic_vector(0 to N_PHYSICAL_REGS-1);				
			-- TEMP!
			ra: in std_logic_vector(0 to 31); -- := (others=>'0'); -- CAREFUL: dummy		
		prevSending: in SmallNumber;
		prevSendingOK: in std_logic;		
		nextAccepting: in std_logic; -- from exec			
		newData: in StageDataMulti;			
		
		execCausing: in InstructionState;
		execEventSignal: in std_logic;		
			-- TEMP!
			tmpPN0, tmpPN1, tmpPN2: out PhysName;		
		accepting: out SmallNumber;
		dataOutIQ: out InstructionState;
		flowResponseOutIQ: out flowResponseSimple		
	);

end TestIQ0;

architecture Behavioral of TestIQ0 is
	signal raSig: std_logic_vector(0 to 3*IQ_SIZE-1) := (others => '0'); -- 31) := (others=>'0');

	signal resetSig: std_logic := '0';
	signal enabled: std_logic := '0'; 
												
	signal aiDispatch: ArgStatusInfo;
	signal asDispatch: ArgStatusStruct;		
	
	signal aiArray: ArgStatusInfoArray(0 to IQ_SIZE-1);
	signal asArray: ArgStatusStructArray(0 to IQ_SIZE-1); -- UNUSED
			
	-- Interface between queue and dispatch
	signal dispatchAccepting: std_logic := '0';		
	signal queueSending: std_logic := '0';
	
	-- UNUSED, but prob. useful in future
	signal physSourcesQ: PhysNameArray(0 to 3*IQ_SIZE-1) := (others => (others => '0'));
	signal missingQ: std_logic_vector(0 to 3*IQ_SIZE-1) := (others => '0');
	signal physSourcesDispatch: PhysNameArray(0 to 2) := (others => (others => '0'));
	signal missingDispatch: std_logic_vector(0 to 2) := (others => '0');	
	--------------------
	
	signal iqData: InstructionStateArray(0 to IQ_SIZE-1) := (others => defaultInstructionState);
	
	signal dispatchDataSig: InstructionState := defaultInstructionState;	
	
	signal toDispatch: InstructionState := defaultInstructionState;	
begin	
	resetSig <= reset;
	enabled <= en;
		
	-- The queue	
	QUEUE_MAIN_LOGIC: entity work.SubunitIQBuffer(Behavioral)
	generic map(
		IQ_SIZE => IQ_SIZE
	)
	port map(
	 	clk => clk, reset => reset, en => en,
	 	prevSending => prevSending,
	 	prevSendingOK => prevSendingOK,
	 	newData => newData,
	 	nextAccepting => dispatchAccepting,
		execEventSignal => execEventSignal,
		execCausing => execCausing,
		aiArray => aiArray,
		regsAllow => raSig,
		accepting => accepting,
		queueSending => queueSending,
		iqDataOut => iqData,
		newDataOut => toDispatch
	);

	QUEUE_TAG_MATCHER: entity work.QueueTagMatcher(Behavioral) 
	generic map(IQ_SIZE => IQ_SIZE)
	port map(
		queueData => iqData,
		resultTags => resultTags,
		nextResultTags => nextResultTags,
		vals => dummyVals,
		readyRegs => readyRegs,
		aiArray => aiArray,
		regsAllow => raSig
	);
	

	-- Dispatch stage			
	DISPATCH_MAIN_LOGIC: entity work.SubunitDispatch(Behavioral)
	port map(
	 	clk => clk, reset => reset, en => en,
	 	prevSending => queueSending,
	 	nextAccepting => nextAccepting,
		execEventSignal => execEventSignal,
		execCausing => execCausing,
		ai => aiDispatch,
	 	stageDataIn => toDispatch,		
		acceptingOut => dispatchAccepting,
		--sendingOut => queueSending,
		flowResponseOut => flowResponseOutIQ,		
		dispatchDataOut => dispatchDataSig, -- before arg updating
		stageDataOut => dataOutIQ
	);
		
	DISPATCH_TAG_MATCHER: entity work.DispatchTagMatcher(Behavioral)
	port map(
		dispatchData => dispatchDataSig,
		resultTags => resultTags,
		--nextResultTags => nextResultTags,
		vals => dummyVals,
		--readyRegs => readyRegs,
		ai => aiDispatch
		--regsAllow => raSig		
	);
	
end Behavioral;
