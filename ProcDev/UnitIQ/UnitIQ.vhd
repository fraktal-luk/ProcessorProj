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

--use work.CommonRouting.all;
use work.TEMP_DEV.all;

use work.ProcLogicIQ.all;

use work.ProcComponents.all;


entity UnitIQ is
	generic(
		IQ_SIZE: natural := 2
	);
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;		

		writtenTags: PhysNameArray(0 to PIPE_WIDTH-1);		
		resultTags: in PhysNameArray(0 to N_RES_TAGS-1);
		nextResultTags: in PhysNameArray(0 to N_NEXT_RES_TAGS-1);
		resultVals: in MwordArray(0 to N_RES_TAGS-1);

		prevSending: in SmallNumber;
		prevSendingOK: in std_logic;		
		nextAccepting: in std_logic; -- from exec			
		newData: in StageDataMulti;			
		
		execCausing: in InstructionState;
		execEventSignal: in std_logic;		
		intSignal: in std_logic;	
			
			readyRegFlags: in std_logic_vector(0 to 3*PIPE_WIDTH-1);
			
			-- Phys regs to read - only for "full read ports" configuration 
			regsForDispatch: out PhysNameArray(0 to 2);
			regReadAllow: out std_logic;			
			
			regValues: in MwordArray(0 to 2);
			
		accepting: out SmallNumber;
		dataOutIQ: out InstructionState;
			sendingOut: out std_logic --;
		--flowResponseOutIQ: out flowResponseSimple		
	);

end UnitIQ;

architecture Behavioral of UnitIQ is
	signal raSig: std_logic_vector(0 to 3*IQ_SIZE-1) := (others => '0');

	signal resetSig: std_logic := '0';
	signal enSig: std_logic := '0'; 
												
	signal aiDispatch: ArgStatusInfo;
	--signal asDispatch: ArgStatusStruct;	-- UNUSED
	
	signal aiArray: ArgStatusInfoArray(0 to IQ_SIZE-1);
	signal aiNew: ArgStatusInfoArray(0 to PIPE_WIDTH-1);
	--signal asArray: ArgStatusStructArray(0 to IQ_SIZE-1); -- UNUSED
			
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

	constant HAS_RESET_IQ: std_logic := '0'; --'1';
	constant HAS_EN_IQ: std_logic := '0'; --'1';	
begin	
	resetSig <= reset and HAS_RESET_IQ;
	enSig <= en or not HAS_EN_IQ;
		
	-- The queue	
	QUEUE_MAIN_LOGIC: entity work.SubunitIQBuffer(--Behavioral) --
																	Implem)
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
		intSignal => intSignal,
		execCausing => execCausing,
		aiArray => aiArray,
			aiNew => aiNew,
		readyRegFlags => readyRegFlags,
		accepting => accepting,
		queueSending => queueSending,
		iqDataOut => iqData,
		newDataOut => toDispatch
	);

		NEW_DATA_TAG_MATCHER: entity work.QueueTagMatcher(Behavioral) 
		generic map(IQ_SIZE => PIPE_WIDTH)
		port map(
			queueData => newData.data,
			resultTags => resultTags,
			nextResultTags => nextResultTags,
			writtenTags => writtenTags,
			aiArray => aiNew
		);
		
	QUEUE_TAG_MATCHER: entity work.QueueTagMatcher(Behavioral) 
	generic map(IQ_SIZE => IQ_SIZE)
	port map(
		queueData => iqData,
		resultTags => resultTags,
		nextResultTags => nextResultTags,
		writtenTags => writtenTags,
		aiArray => aiArray
	);
	

	-- Dispatch stage			
	DISPATCH_MAIN_LOGIC: entity work.SubunitDispatch(--Behavioral)
																		Alternative)	
	port map(
	 	clk => clk, reset => resetSig, en => enSig,
	 	prevSending => queueSending,
	 	nextAccepting => nextAccepting,
		execEventSignal => execEventSignal,
		intSignal => intSignal,
		execCausing => execCausing,
		ai => aiDispatch,
			resultVals => resultVals,
			regValues => regValues,
	 	stageDataIn => toDispatch,		
		acceptingOut => dispatchAccepting,
		--flowResponseOut => open, --flowResponseOutIQ,
			sendingOut => sendingOut,
		dispatchDataOut => dispatchDataSig, -- before arg updating
		stageDataOut => dataOutIQ
	);
		
				--	updateInstructionArgValues2(dataOutIQ, aiPreDispatch, readyRegFlags);
		
--			PRE_DISPATCH_TAG_MATCHER: entity work.DispatchTagMatcher(Behavioral)
--			port map(
--				dispatchData => toDispatch,
--				resultTags => resultTags,
--				ai => aiPreDispatch
--			);
		
		
	DISPATCH_TAG_MATCHER: entity work.DispatchTagMatcher(Behavioral)
	port map(
		dispatchData => dispatchDataSig,
		resultTags => resultTags,
		ai => aiDispatch
	);
	
	regsForDispatch <=
			(0 => toDispatch.physicalArgs.s0, 1 => toDispatch.physicalArgs.s1, 2 => toDispatch.physicalArgs.s2);
	regReadAllow <= queueSending;
		
end Behavioral;

