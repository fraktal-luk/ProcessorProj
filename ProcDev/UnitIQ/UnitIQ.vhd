----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:32:05 05/15/2016 
-- Design Name: 
-- Module Name:    UnitIQ - Behavioral 
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


entity UnitIQ is
	generic(
		IQ_SIZE: natural := 2--;
		--N_RESULT_TAGS: natural := 1
	);
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;		
		
		resultTags: in PhysNameArray(0 to N_RES_TAGS-1);
		nextResultTags: in PhysNameArray(0 to N_NEXT_RES_TAGS-1);
		resultVals: in MwordArray(0 to N_RES_TAGS-1);
		readyRegs: in std_logic_vector(0 to N_PHYSICAL_REGS-1);				

		prevSending: in SmallNumber;
		prevSendingOK: in std_logic;		
		nextAccepting: in std_logic; -- from exec			
		newData: in StageDataMulti;			
		
		execCausing: in InstructionState;
		execEventSignal: in std_logic;		
			
			-- Phys regs to read - only for "full read ports" configuration 
			regsForDispatch: out PhysNameArray(0 to 2);
			
		accepting: out SmallNumber;
		dataOutIQ: out InstructionState;
		flowResponseOutIQ: out flowResponseSimple		
	);

end UnitIQ;

architecture Behavioral of UnitIQ is
	signal raSig: std_logic_vector(0 to 3*IQ_SIZE-1) := (others => '0'); -- 31) := (others=>'0');

	signal resetSig: std_logic := '0';
	signal enSig: std_logic := '0'; 
												
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

	constant HAS_RESET_IQ: std_logic := '1';
	constant HAS_EN_IQ: std_logic := '1';	
begin	
	resetSig <= reset and HAS_RESET_IQ;
	enSig <= en or not HAS_EN_IQ;
		
	-- The queue	
	QUEUE_MAIN_LOGIC: entity work.SubunitIQBuffer(Behavioral)
	generic map(
		IQ_SIZE => IQ_SIZE
	)
	port map(
	 	clk => clk, reset => resetSig, en => enSig,
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
		vals => resultVals,
		readyRegs => readyRegs,
		aiArray => aiArray,
		regsAllow => raSig
	);
	

	-- Dispatch stage			
	DISPATCH_MAIN_LOGIC: entity work.SubunitDispatch(Behavioral)
	port map(
	 	clk => clk, reset => resetSig, en => enSig,
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
		vals => resultVals,
		--readyRegs => readyRegs,
		ai => aiDispatch
		--regsAllow => raSig		
	);
	
		-- TEMP!
		regsForDispatch <= (others => (others => '0'));
		
end Behavioral;

