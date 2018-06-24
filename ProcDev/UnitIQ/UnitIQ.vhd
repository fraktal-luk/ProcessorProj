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

		prevSendingOK: in std_logic;
		acceptingVec: out std_logic_vector(0 to PIPE_WIDTH-1);
		issueAccepting: in std_logic;
		newData: in StageDataMulti;		
	
		queueOutput: out SchedulerEntrySlot;

		readyRegFlags: in std_logic_vector(0 to 3*PIPE_WIDTH-1);
		
		execCausing: in InstructionState;
		execEventSignal: in std_logic;		
		lateEventSignal: in std_logic;
			
		fni: in ForwardingInfo
	);

end UnitIQ;


architecture Behavioral of UnitIQ is
	signal resetSig, enSig: std_logic := '0';
												
	signal aiDispatch: ArgStatusInfo;
	
	signal aiArray: ArgStatusInfoArray(0 to IQ_SIZE-1);
	signal aiNew: ArgStatusInfoArray(0 to PIPE_WIDTH-1);
			
	-- Interface between queue and dispatch
	signal dispatchAccepting, queueSending: std_logic := '0';		

	signal iqData: InstructionStateArray(0 to IQ_SIZE-1) := (others => defaultInstructionState);
	signal dispatchDataSig, toDispatch: InstructionState := defaultInstructionState;

		signal writtenTagsZ: PhysNameArray(0 to PIPE_WIDTH-1) := (others => (others => '0'));		

	signal eventCausing: InstructionState := DEFAULT_INSTRUCTION_STATE;

	constant HAS_RESET_IQ: std_logic := '0';
	constant HAS_EN_IQ: std_logic := '0';	
begin	
	resetSig <= reset and HAS_RESET_IQ;
	enSig <= en or not HAS_EN_IQ;
		
	eventCausing <= execCausing;
		
	-- The queue	
	QUEUE_MAIN_LOGIC: entity work.SubunitIQBuffer(Implem)
	generic map(
		IQ_SIZE => IQ_SIZE
	)
	port map(
	 	clk => clk, reset => resetSig, en => enSig,
	 	prevSendingOK => prevSendingOK,
	 	newData => newData,
	 	nextAccepting => issueAccepting,
		lateEventSignal => lateEventSignal,
		execEventSignal => execEventSignal,
		execCausing => eventCausing,
		--aiArray => aiArray,
		--aiNew => aiNew,
		fni => fni,
		readyRegFlags => readyRegFlags,
		acceptingVec => acceptingVec,
		schedulerOut => queueOutput
		--queueSending => queueSending,
		--iqDataOut => iqData
		--newDataOut => toDispatch
	);

	aiNew <= getArgInfoArrayD2(newData.data, 
											fni.resultTags, fni.resultTags, fni.resultTags,
											fni.nextResultTags, fni.writtenTags);

	aiArray <= getArgInfoArrayD2(iqData, 
											fni.resultTags, fni.resultTags, fni.resultTags,
											fni.nextResultTags, writtenTagsZ);
	
	--queueOutput <= (queueSending, toDispatch, DEFAULT_SCHED_STATE);
end Behavioral;

