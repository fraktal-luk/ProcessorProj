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

use work.GeneralPipeDev.all;

use work.TEMP_DEV.all;

use work.ProcComponents.all;

use work.BasicCheck.all;


entity TestCQPart0 is
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
		
		execEventSignal: in std_logic;
		execCausing: in InstructionState; -- Redundant cause we have inputs from all Exec ends? 
				
		inputInstructions: in InstructionStateArray(0 to 3);
		
		selectedToCQ: in std_logic_vector(0 to 3) := (others=>'0');
		whichAcceptedCQ: out std_logic_vector(0 to 3) := (others=>'0');	
		cqWhichSend: in std_logic_vector(0 to 3);
		anySending: out std_logic; 
		
		cqOut: out StageDataMulti;
		-- NOTE: cqOut is for data to commit, dataCQOut is for forwarding info
		dataCQOut: out StageDataCommitQueue	
	);
end TestCQPart0;


architecture Implem of TestCQPart0 is
	signal resetSig, enSig: std_logic := '0';

	signal flowDriveCQ: FlowDriveBuffer	:= (killAll => '0', lockAccept => '0', lockSend => '0',
																others=>(others=>'0'));
	signal flowResponseCQ: FlowResponseBuffer := (others => (others=> '0'));				
		
	signal stageDataCQNew: InstructionStateArray(0 to 3) := (others => defaultInstructionState);

	signal livingMaskRaw, livingMaskCQ: std_logic_vector(0 to CQ_SIZE-1) := (others=>'0');
	signal stageDataCQ, stageDataCQLiving, stageDataCQNext: StageDataCommitQueue 
									:= (fullMask=>(others=>'0'), data=>(others=>defaultInstructionState));
			
	signal whichSendingFromCQ: std_logic_vector(0 to PIPE_WIDTH-1) := (others=>'0'); 
	signal whichAcceptedCQSig: std_logic_vector(0 to 3) := (others=>'0');

	constant HAS_RESET_CQ: std_logic := '1';
	constant HAS_EN_CQ: std_logic := '1';
begin
	resetSig <= reset and HAS_RESET_CQ;
	enSig <= en or not HAS_EN_CQ;

	CQ_SYNCHRONOUS: process(clk) 	
	begin
		if rising_edge(clk) then
			if resetSig = '1' then
				
			elsif enSig = '1' then	
				stageDataCQ <= stageDataCQNext;
				
				logBuffer(stageDataCQ.data, stageDataCQ.fullMask, livingMaskCQ,
								flowResponseCQ);
				checkBuffer(stageDataCQ.data, stageDataCQ.fullMask, stageDataCQNext.data, stageDataCQNext.fullMask,
								flowDriveCQ, flowResponseCQ);				
			end if;
		end if;
	end process;
		
	flowDriveCQ.prevSending <=	num2flow(countOnes(cqWhichSend));
	
	stageDataCQLiving.data <= stageDataCQ.data;
	stageDataCQLiving.fullMask <= livingMaskCQ;
	stageDataCQNew(0 to 3) <= inputInstructions; --(0 to 2); -- Don't use branch result
												
		stageDataCQNext <= stageCQNext(stageDataCQ,
													compactData(stageDataCQNew, cqWhichSend),
												livingMaskCQ,
													compactMask(stageDataCQNew, cqWhichSend),
												PIPE_WIDTH,
												binFlowNum(flowResponseCQ.living),
												binFlowNum(flowResponseCQ.sending),
												binFlowNum(flowDriveCQ.prevSending));	

											
	whichAcceptedCQSig <= (others => '1');
													
	SLOT_CQ: entity work.BufferPipeLogic(Behavioral)
	generic map(
		CAPACITY => CQ_SIZE,
		MAX_OUTPUT => PIPE_WIDTH,	
		MAX_INPUT => 4				
	)
	Port map(
		clk => clk, reset =>  resetSig, en => enSig,
		flowDrive => flowDriveCQ,
		flowResponse => flowResponseCQ
	);			
											
	livingMaskRaw <= stageDataCQ.fullMask;	
	livingMaskCQ <= stageDataCQ.fullMask;	
	
	whichSendingFromCQ <= getSendingFromCQ(livingMaskRaw);
	
	flowDriveCQ.nextAccepting <= num2flow(countOnes(whichSendingFromCQ));

	cqOut.fullMask <= whichSendingFromCQ;
	cqOut.data <= stageDataCQLiving.data(0 to PIPE_WIDTH-1); -- ??(some may be killed? careful)			
	
	anySending <= whichSendingFromCQ(0); -- Because CQ(0) must be committing if any other is 

	-- CAREFUL: don't propagate here result tags from empty slots!	
	--				Clearing result tags for empty slots handled in CQ step function 
	dataCQOut <= stageDataCQLiving;	
			
	whichAcceptedCQ <= whichAcceptedCQSig;	
end Implem;

