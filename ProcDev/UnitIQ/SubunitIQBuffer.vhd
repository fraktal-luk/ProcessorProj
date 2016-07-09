----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:07:12 05/05/2016 
-- Design Name: 
-- Module Name:    SubunitIQBuffer - Behavioral 
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


entity SubunitIQBuffer is
	generic(
		IQ_SIZE: natural := 2
	);
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
		
		prevSending: in SmallNumber;
		prevSendingOK: in std_logic;
		newData: in StageDataMulti;
		nextAccepting: in std_logic;
		execEventSignal: in std_logic;
		execCausing: in InstructionState;
		aiArray: in ArgStatusInfoArray(0 to IQ_SIZE-1);
		regsAllow: in std_logic_vector(0 to 3*IQ_SIZE-1);
		
		accepting: out SmallNumber;
		queueSending: out std_logic;
		iqDataOut: out InstructionStateArray(0 to IQ_SIZE-1);
		newDataOut: out InstructionState
	);
end SubunitIQBuffer;


architecture Behavioral of SubunitIQBuffer is
	signal queueData, queueDataUpdated: InstructionStateArray(0 to IQ_SIZE-1) 
								:= (others=>defaultInstructionState);
	signal queueDataLiving, queueDataNext: InstructionStateArray(0 to IQ_SIZE-1)
								:= (others=>defaultInstructionState);
	signal queueDataNew: InstructionStateArray(0 to PIPE_WIDTH-1) := (others=>defaultInstructionState);	
	
	signal emptyMask, fullMask, killMask, livingMask, readyMask, sendingMask: 
								std_logic_vector(0 to IQ_SIZE-1) := (others=>'0');				
		signal truncLiving: SmallNumber := (others=>'0');	
	signal flowDriveQ: FlowDriveBuffer 
				:= (killAll => '0', lockAccept => '0', lockSend => '0', others=>(others=>'0'));
	signal flowResponseQ: FlowResponseBuffer 
				:= (others => (others=> '0'));

	signal asArray: ArgStatusStructArray(0 to IQ_SIZE-1);	

	-- NOTE: queueContent UNUSED as of now 
	signal queueContent, queueContentNext: InstructionSlotArray(-1 to IQ_SIZE-1)
																:= (others => DEFAULT_INSTRUCTION_SLOT);
																
	signal iqFullMaskNext: std_logic_vector(0 to IQ_SIZE-1) := (others => '0');
	signal iqDataNext: InstructionStateArray(0 to IQ_SIZE-1) := (others => defaultInstructionState);
	signal sends: std_logic := '0';
	signal dispatchDataNew: InstructionState := defaultInstructionState;
begin
	flowDriveQ.prevSending <= prevSending;		
	
	QUEUE_SYNCHRONOUS: process(clk) 	
	begin
		if rising_edge(clk) then
			if reset = '1' then
				
			elsif en = '1' then	
				queueData <= queueDataNext;
				fullMask <= iqFullMaskNext;
			end if;	
		end if;
	end process;	
		
	flowDriveQ.kill <= num2flow(countOnes(killMask));		
	queueDataLiving <= queueDataUpdated; -- TEMP?
	queueDataNew <= newData.data;									
	queueDataNext <= iqDataNext;										
									
	--fullMask <= setToOnes(emptyMask, binFlowNum(flowResponseQ.full));	
	livingMask <= fullMask and not killMask;
		
	-- CAREFUL: quick fix to prevent larger 'living' than queue size		
	--truncLiving(LOG2_PIPE_WIDTH+1 downto 0) <= flowResponseQ.living(LOG2_PIPE_WIDTH + 1 downto 0);
	truncLiving <= flowResponseQ.living;
				
	iqFullMaskNext <= iqExtractFullMask(queueContentNext(0 to IQ_SIZE-1));
	iqDataNext <= iqExtractData(queueContentNext(0 to IQ_SIZE-1));
	sends <= queueContentNext(-1).full;
	dispatchDataNew <= queueContentNext(-1).ins;
			
	queueContentNext <= iqContentNext2(queueDataLiving, newData, livingMask, readyMask,
													nextAccepting,
													binFlowNum( truncLiving ),
													binFlowNum(flowResponseQ.sending),
													binFlowNum(flowDriveQ.prevSending),
													prevSendingOK);			
		
	flowDriveQ.nextAccepting <=  num2flow(1) when (nextAccepting and isNonzero(readyMask)) = '1'			
									else num2flow(0);															
	
	--physSourcesQ <= extractPhysSources(queueData);
	--missingQ <= extractMissing(queueData);
	
	queueDataUpdated <= updateIQData(queueData, aiArray);	-- Filling arg fields		
	-- Info about args avalable now, or next cycle, or not
	asArray <= getArgStatusArray(aiArray, livingMask, regsAllow);
	readyMask <= extractReadyMask(asArray); -- setting readyMask - directly used by flow logic
	
	--------------
	
	SLOTS_IQ: entity work.BufferPipeLogic(Behavioral) -- IQ)
	generic map(
		CAPACITY => IQ_SIZE,
		MAX_OUTPUT => 1,	-- CAREFUL! When can send to 2 different units at once, it must change to 2!
		MAX_INPUT => PIPE_WIDTH				
	)
	port map(
		clk => clk, reset =>  reset, en => en,
		flowDrive => flowDriveQ,
		flowResponse => flowResponseQ
	);

	KILL_MASK: for i in killMask'range generate
		signal before: std_logic;
		signal a, b: std_logic_vector(7 downto 0);
	begin
		a <= execCausing.numberTag;
		b <= queueData(i).numberTag;
		IQ_KILLER: entity work.CompareBefore8 port map(
			inA =>  a,
			inB =>  b,
			outC => before
		);		
		killMask(i) <= 		before and fullMask(i)
							and 	execEventSignal; 			
	end generate;	
	
	accepting <= flowResponseQ.accepting;	

	queueSending <= flowResponseQ.sending(0); 
							-- CAREFUL: this assumes that flowResponseQ.sending is binary: [0,1]
	iqDataOut <= queueData;						
	newDataOut <= dispatchDataNew;
end Behavioral;

