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
use work.ProcLogicRenaming.all;
use work.TEMP_DEV.all;


entity SubunitIssueRouting is
	port(
		renamedDataLiving: in StageDataMulti;
		--acceptingA: in PipeFlow;
		--acceptingB: in PipeFlow;
		--acceptingC: in PipeFlow;
		--acceptingD: in PipeFlow;
		--acceptingE: in PipeFlow;
		
			acceptingVecA: in std_logic_vector(0 to PIPE_WIDTH-1);
			acceptingVecB: in std_logic_vector(0 to PIPE_WIDTH-1);
			acceptingVecC: in std_logic_vector(0 to PIPE_WIDTH-1);
			acceptingVecD: in std_logic_vector(0 to PIPE_WIDTH-1);
			acceptingVecE: in std_logic_vector(0 to PIPE_WIDTH-1);
		
		renamedSendingIn: in std_logic; -- Let's route it through this for clarity
		
		renamedSendingOut: out std_logic; -- Forward to IQ's
		iqAccepts: out std_logic;
		sendingA: out PipeFlow;
		sendingB: out PipeFlow;
		sendingC: out PipeFlow;
		sendingD: out PipeFlow;
				sendingE: out PipeFlow;
		dataOutA: out StageDataMulti;
		dataOutB: out StageDataMulti;
		dataOutC: out StageDataMulti;
		dataOutD: out StageDataMulti;
				dataOutE: out StageDataMulti;
			dataOutSQ: out StageDataMulti;
			dataOutLQ: out StageDataMulti	
	);
end SubunitIssueRouting;


architecture Behavioral of SubunitIssueRouting is	
	signal srcVecA, srcVecB, srcVecC, srcVecD, srcVecE: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
	signal storeVec: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
	signal issueRouteVec: IntArray(0 to PIPE_WIDTH-1) := (others => 0);
	signal nToA, nToB, nToC, nToD, nToE: natural := 0;	
	signal iqAcceptingA: std_logic := '0';						
	signal iqAcceptingB, iqAcceptingC, iqAcceptingD, iqAcceptingE: std_logic := '0';

	signal dataToA, dataToB, dataToC, dataToD, dataToE, dataToSQ: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

	signal renamedSending: std_logic := '0';
	
		signal invA, invB, invC, invD, invE: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
begin	
	renamedSending <= renamedSendingIn;

		storeVec <= findStores(renamedDataLiving);

		-- Routing to queues
		ROUTE_VEC_GEN: for i in 0 to PIPE_WIDTH-1 generate
			issueRouteVec(i) <= unit2queue(renamedDataLiving.data(i).operation.unit);
				--srcVecE(i) <= '1' when renamedDataLiving.data(i).operation.unit = Memory
				--						 and renamedDataLiving.data(i).operation.func = store
				--						 and renamedDataLiving.fullMask(i) = '1'
				--			else '0';			 
		end generate;
		
		srcVecE <= storeVec and renamedDataLiving.fullMask;
		
	-- New concept for IQ routing.  {renamedData, srcVec*} -> (StageDataMulti){A,B,C,D}
	-- Based on "push left" of each destination type, generating "New" StageDataMulti data for each one
	-- dataToA <= [func](stageData1Living, srcVecA); -- s.d.1.l includes fullMask!	
	
	-- Selection of flow into IQ's
		srcVecA <= (findByNumber(issueRouteVec, 0) or findBranchLink(renamedDataLiving))
								and renamedDataLiving.fullMask;
		srcVecB <= findByNumber(issueRouteVec, 1) and renamedDataLiving.fullMask;
		srcVecC <= findByNumber(issueRouteVec, 2) and renamedDataLiving.fullMask;
		srcVecD <= findByNumber(issueRouteVec, 3) and renamedDataLiving.fullMask;
			--srcVecE <= findByNumber(issueRouteVec, 3) and renamedDataLiving.fullMask;

		dataToA <= routeToIQ2(prepareForAlu(renamedDataLiving), srcVecA);
		dataToB <= routeToIQ2(renamedDataLiving, srcVecB);
		dataToC <= routeToIQ2(prepareForAGU(renamedDataLiving), srcVecC);
		dataToD <= routeToIQ2(prepareForBranch(renamedDataLiving), srcVecD);
		dataToE <= --routeToIQ2(prepareForStoreData(renamedDataLiving), srcVecE);
						prepareForStoreData(dataToSQ);
	
		dataOutSQ <= dataToSQ;
		dataToSQ <= routeToIQ(renamedDataLiving, storeVec);
		dataOutLQ <= routeToIQ(renamedDataLiving, findLoads(renamedDataLiving));	
	
				invA <= invertVec(acceptingVecA);
				invB <= invertVec(acceptingVecB);
				invC <= invertVec(acceptingVecC);
				invD <= invertVec(acceptingVecD);
				invE <= invertVec(acceptingVecE);
	
		nToA	<= countOnes(dataToA.fullMask);
		iqAcceptingA <= --'1' when PIPE_WIDTH <= binFlowNum(acceptingA) else '0';
							 --acceptingA(0);
							 not isNonzero(dataToA.fullMask and not invA);
		sendingA <= num2flow(nToA) when renamedSending = '1' else (others=>'0');
			
		nToB	<= countOnes(dataToB.fullMask);
		iqAcceptingB <= --'1' when PIPE_WIDTH <= binFlowNum(acceptingB) else '0';
							 --acceptingB(0);	
							 not isNonzero(dataToB.fullMask and not invB);							 
		sendingB <= num2flow(nToB) when renamedSending = '1' else (others=>'0');

		nToC	<= countOnes(dataToC.fullMask);
		iqAcceptingC <= --'1' when PIPE_WIDTH <= binFlowNum(acceptingC) else '0';
							 --acceptingC(0);		
							 not isNonzero(dataToC.fullMask and not invC);							 
		sendingC <= num2flow(nToC) when renamedSending = '1' else (others=>'0');

		nToD	<= countOnes(dataToD.fullMask);
		iqAcceptingD <= --'1' when PIPE_WIDTH <= binFlowNum(acceptingD) else '0';
							 --acceptingD(0);		
							 not isNonzero(dataToD.fullMask and not invD);							 
		sendingD <= num2flow(nToD) when renamedSending = '1' else (others=>'0');				

		nToE	<= countOnes(dataToE.fullMask);
		iqAcceptingE <= --'1' when PIPE_WIDTH <= binFlowNum(acceptingE) else '0';
							 --acceptingE(0);	
							 not isNonzero(dataToE.fullMask and not invE);							 
		sendingE <= num2flow(nToE) when renamedSending = '1' else (others=>'0');
			
		iqAccepts <= iqAcceptingA and iqAcceptingB and iqAcceptingC and iqAcceptingD and iqAcceptingE;

	dataOutA <= dataToA;
	dataOutB <= dataToB;
	dataOutC <= dataToC;
	dataOutD <= dataToD;
	dataOutE <= dataToE;
	
	renamedSendingOut <= renamedSending;
end Behavioral;

