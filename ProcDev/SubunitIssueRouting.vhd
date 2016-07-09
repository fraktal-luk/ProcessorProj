----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:25:43 05/10/2016 
-- Design Name: 
-- Module Name:    SubunitIssueRouting - Behavioral 
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
--use work.FrontPipeDev.all;
use work.CommonRouting.all;
use work.TEMP_DEV.all;


entity SubunitIssueRouting is
	port(
		renamedDataLiving: in StageDataMulti;
		acceptingA: in PipeFlow;
		acceptingB: in PipeFlow;
		acceptingC: in PipeFlow;
		acceptingD: in PipeFlow;
		renamedSendingIn: in std_logic; -- Let's route it through this for clarity
		
		renamedSendingOut: out std_logic; -- Forward to IQ's
		iqAccepts: out std_logic;
		prevSendingA: out PipeFlow;
		prevSendingB: out PipeFlow;
		prevSendingC: out PipeFlow;
		prevSendingD: out PipeFlow;
		dataOutA: out StageDataMulti;
		dataOutB: out StageDataMulti;
		dataOutC: out StageDataMulti;
		dataOutD: out StageDataMulti		
	);
end SubunitIssueRouting;


architecture Behavioral of SubunitIssueRouting is	
	signal srcVecA, srcVecB, srcVecC, srcVecD: std_logic_vector(0 to PIPE_WIDTH-1);
	signal issueRouteVec: IntArray(0 to PIPE_WIDTH-1);
	signal nToA, nToB, nToC, nToD: natural := 0;	
	signal iqAcceptingA: std_logic := '0';						
	signal iqAcceptingB, iqAcceptingC, iqAcceptingD: std_logic := '0';

	signal dataToA, dataToB, dataToC, dataToD: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

	signal renamedSending: std_logic := '0';	
begin	
	renamedSending <= renamedSendingIn;

		-- Routing to queues
		ROUTE_VEC_GEN: for i in 0 to PIPE_WIDTH-1 generate
			issueRouteVec(i) <= unit2queue(renamedDataLiving.data(i).operation.unit);
		end generate;
		
	-- New concept for IQ routing.  {renamedData, srcVec*} -> (StageDataMulti){A,B,C,D}
	-- Based on "push left" of each destination type, generating "New" StageDataMulti data for each one
	-- dataToA <= [func](stageData1Living, srcVecA); -- s.d.1.l includes fullMask!	
	
	-- Selection of flow into IQ's
		srcVecA <= findByNumber(issueRouteVec, 0) and renamedDataLiving.fullMask;
		srcVecB <= findByNumber(issueRouteVec, 1) and renamedDataLiving.fullMask;
		srcVecC <= findByNumber(issueRouteVec, 2) and renamedDataLiving.fullMask;
		srcVecD <= findByNumber(issueRouteVec, 3) and renamedDataLiving.fullMask;
												
		dataToA <= routeToIQ(renamedDataLiving, srcVecA);
		dataToB <= routeToIQ(renamedDataLiving, srcVecB);
		dataToC <= routeToIQ(renamedDataLiving, srcVecC);
		dataToD <= routeToIQ(renamedDataLiving, srcVecD);
	
		nToA	<= countOnes(dataToA.fullMask);
		iqAcceptingA <= '1' when PIPE_WIDTH <= binFlowNum(acceptingA) else '0';	
		prevSendingA <= num2flow(nToA) when renamedSending = '1' else (others=>'0');		
			
		nToB	<= countOnes(dataToB.fullMask);
		iqAcceptingB <= '1' when PIPE_WIDTH <= binFlowNum(acceptingB) else '0';														
		prevSendingB <= num2flow(nToB) when renamedSending = '1' else (others=>'0');

		nToC	<= countOnes(dataToC.fullMask);
		iqAcceptingC <= '1' when PIPE_WIDTH <= binFlowNum(acceptingC) else '0';					
		prevSendingC <= num2flow(nToC) when renamedSending = '1' else (others=>'0');

		nToD	<= countOnes(dataToD.fullMask);
		iqAcceptingD <= '1' when PIPE_WIDTH <= binFlowNum(acceptingD) else '0';					
		prevSendingD <= num2flow(nToD) when renamedSending = '1' else (others=>'0');				
			
		iqAccepts <= iqAcceptingA and iqAcceptingB and iqAcceptingC and iqAcceptingD;

	dataOutA <= dataToA;
	dataOutB <= dataToB;
	dataOutC <= dataToC;
	dataOutD <= dataToD;
	
	renamedSendingOut <= renamedSending;
end Behavioral;

