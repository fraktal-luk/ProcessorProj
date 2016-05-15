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

use work.CommonRouting.all;
use work.TEMP_DEV.all;

use work.ProcLogicCQ.all;

use work.ProcComponents.all;


entity TestCQPart0 is
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
		
		intSignal: in std_logic;
		execEventSignal: in std_logic;
		execCausing: in InstructionState; -- Redundant cause we have inputs from all Exec ends? 
		
		commitCtrNext: in SmallNumber;
		
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


architecture Behavioral of TestCQPart0 is
	signal resetSig, enabled: std_logic := '0';

	signal flowDriveCQ: FlowDriveBuffer	:= (killAll => '0', lockAccept => '0', lockSend => '0',
																others=>(others=>'0'));
	signal flowResponseCQ: FlowResponseBuffer := (others => (others=> '0'));				
		
	signal cqRoutes: IntArray(0 to 3) := (others=>0);		
	signal stageDataCQNew: PipeStageDataU(0 to 3);
	-- NOTE: emptyMask means vector of 0s
	signal emptyMaskCQ, killMaskCQ, fullMaskCQ, fullMaskCQNew, livingMaskRaw, livingMaskCQ: 
							std_logic_vector(0 to CQ_SIZE-1) := (others=>'0');
	signal killMaskRaw, killMaskNeutralize: std_logic_vector(0 to CQ_SIZE-1) := (others=>'0');					
	signal stageDataCQ, stageDataCQLiving, stageDataCQNext: StageDataCommitQueue 
									:= (fullMask=>(others=>'0'), data=>(others=>defaultInstructionState));
									
	signal whichSendingFromCQ: std_logic_vector(0 to PIPE_WIDTH-1) := (others=>'0'); 

	signal 
		killVec, takeAVec, takeBVec, takeCVec, takeDVec: std_logic_vector(0 to CQ_SIZE-1) := (others=>'0');
	signal tagA, tagB, tagC, tagD, tagKill: SmallNumber := (others=>'0');

	signal whichAcceptedCQSig: std_logic_vector(0 to 3) := (others=>'0');				
begin
	resetSig <= reset;
	enabled <= en;

	CQ_SYNCHRONOUS: process(clk) 	
	begin
		if rising_edge(clk) then
			if reset = '1' then
				
			elsif en = '1' then	
				stageDataCQ <= stageDataCQNext;					
			end if;
		end if;
	end process;		

	tagA <= inputInstructions(0).numberTag;
	tagB <= inputInstructions(1).numberTag;
	tagC <= inputInstructions(2).numberTag;
	tagD <= inputInstructions(3).numberTag;
	tagKill <= execCausing.numberTag;
	
	TEST_VR: entity work.VerilogCQRouting0 
	generic map(
		SIZE => CQ_SIZE
	)
	port map(
		newBase => commitCtrNext,
		tagA => tagA,
		tagB => tagB,
		tagC => tagC,
		tagD => tagD,
		tagKill => tagKill,
		execEventSignal => execEventSignal,
		
		takeA => takeAVec,
		takeB => takeBVec,
		takeC => takeCVec,
		takeD => takeDVec,
		kill => killVec
	);
		
	flowDriveCQ.prevSending <=	num2flow(countOnes(cqWhichSend), false);
	
	stageDataCQLiving.data <= stageDataCQ.data;
	stageDataCQLiving.fullMask <= livingMaskCQ;
	stageDataCQNew <= inputInstructions;
			
	stageDataCQNext <= stageCQNext2(stageDataCQLiving, stageDataCQNew, livingMaskCQ, cqWhichSend,
												takeAVec, takeBVec, takeCVec, takeDVec,  
												binFlowNum(flowResponseCQ.living), 
												binFlowNum(flowResponseCQ.sending),
												binFlowNum(flowDriveCQ.prevSending));	
														
	whichAcceptedCQSig <=  (isNonzero(takeAVec) and selectedToCQ(0),
									isNonzero(takeBVec) and selectedToCQ(1),
									isNonzero(takeCVec) and selectedToCQ(2),
									isNonzero(takeDVec) and selectedToCQ(3)); 								
													
	SLOT_CQ: entity work.BufferPipeLogic(Behavioral)
	generic map(
		CAPACITY => CQ_SIZE,
		MAX_OUTPUT => PIPE_WIDTH,	
		MAX_INPUT => 4				
	)
	Port map(
		clk => clk, reset =>  reset, en => en,
		flowDrive => flowDriveCQ,
		flowResponse => flowResponseCQ
	);			
											
	killMaskRaw <= (others=>'1') when intSignal = '1' 	-- CAREFUL: when "spare almost committed",
																		--		this must disappear?
				else setFromFirstOne(killVec) and not killVec when execEventSignal = '1'
				else (others=>'0');
	--killMaskNeutralize(0 to PIPE_WIDTH-1) <= whichSendingFromCQ;	
					-- ^ NOTE: for sparing "almost committed"		
	killMaskCQ <= killMaskRaw and not killMaskNeutralize;				
	-- NOTE: if 'whichSendingFromCQ' neutralized killMask bits and execCausing was from
	--			lastCommittedNext (not from current one), we'd spare some ops form killing!	
	livingMaskRaw <= stageDataCQ.fullMask and not killMaskRaw;	
	livingMaskCQ <= stageDataCQ.fullMask and not killMaskCQ;	
	
	flowDriveCQ.kill <= num2flow(countOnes(killMaskCQ and stageDataCQ.fullMask), false);
	
	flowDriveCQ.nextAccepting <= num2flow(countOnes(whichSendingFromCQ), false);
	
	-- CAREFUL: using "raw" living mask, cause it prevents a comb. loop when implementing
	--				the feature: Spare "almost committed".
	--				Otherwise loop would happen: whichSending depends on livingMask, and livingMask
	--				on next commitCtr, and commitCtr OFC depends on whichSending! 
	whichSendingFromCQ <= getSendingFromCQ(livingMaskRaw);
	
	cqOut.fullMask <= whichSendingFromCQ;
	cqOut.data <= stageDataCQLiving.data(0 to PIPE_WIDTH-1); -- ??(some may be killed? careful)			
	
	anySending <= whichSendingFromCQ(0); -- Because CQ(0) must be committing if any other is 		
	dataCQOut <= stageDataCQLiving;	
			
	whichAcceptedCQ <= whichAcceptedCQSig;	
end Behavioral;

