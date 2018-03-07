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
use work.ProcLogicRouting.all;


entity SubunitIssueRouting is
	port(
		renamedDataLiving: in StageDataMulti;

		acceptingVecA: in std_logic_vector(0 to PIPE_WIDTH-1);
		acceptingVecB: in std_logic_vector(0 to PIPE_WIDTH-1);
		acceptingVecC: in std_logic_vector(0 to PIPE_WIDTH-1);
		acceptingVecD: in std_logic_vector(0 to PIPE_WIDTH-1);
		acceptingVecE: in std_logic_vector(0 to PIPE_WIDTH-1);
		
		acceptingROB: in std_logic;
		acceptingSQ: in std_logic;
		acceptingLQ: in std_logic;
		acceptingBQ: in std_logic;
		
		renamedSendingIn: in std_logic; -- Let's route it through this for clarity
		
		renamedSendingOut: out std_logic; -- Forward to IQ's
		iqAccepts: out std_logic;

		dataOutA: out StageDataMulti;
		dataOutB: out StageDataMulti;
		dataOutC: out StageDataMulti;
		dataOutD: out StageDataMulti;
		dataOutE: out StageDataMulti;
		
		dataOutSQ: out StageDataMulti;
		dataOutLQ: out StageDataMulti;
		dataOutBQ: out StageDataMulti
	);
end SubunitIssueRouting;


architecture Behavioral of SubunitIssueRouting is	
	signal srcVecA, srcVecB, srcVecC, srcVecD, srcVecE: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
	signal storeVec, loadVec: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
	signal issueRouteVec: IntArray(0 to PIPE_WIDTH-1) := (others => 0);

	signal iqAcceptingA: std_logic := '0';						
	signal iqAcceptingB, iqAcceptingC, iqAcceptingD, iqAcceptingE: std_logic := '0';

	signal dataToA, dataToB, dataToC, dataToD, dataToE, dataToSQ: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

	signal renamedSending: std_logic := '0';
	
	signal invA, invB, invC, invD, invE: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
begin	
	renamedSending <= renamedSendingIn;

		storeVec <= findStores(renamedDataLiving) and renamedDataLiving.fullMask;
		loadVec <= findLoads(renamedDataLiving) and renamedDataLiving.fullMask;

		-- Routing to queues
		ROUTE_VEC_GEN: for i in 0 to PIPE_WIDTH-1 generate
			issueRouteVec(i) <= unit2queue(renamedDataLiving.data(i).operation.unit);		 
		end generate;
	
	-- New concept for IQ routing.  {renamedData, srcVec*} -> (StageDataMulti){A,B,C,D}
	-- Based on "push left" of each destination type, generating "New" StageDataMulti data for each one
	-- dataToA <= [func](stageData1Living, srcVecA); -- s.d.1.l includes fullMask!		
		srcVecA <= (findByNumber(issueRouteVec, 0) or srcVecD) and renamedDataLiving.fullMask;
		srcVecB <= findByNumber(issueRouteVec, 1) and renamedDataLiving.fullMask;
		srcVecC <= (findByNumber(issueRouteVec, 2)
								or storeVec or loadVec) and renamedDataLiving.fullMask;
		srcVecD <= (findByNumber(issueRouteVec, 3)
								and not storeVec and not loadVec) and renamedDataLiving.fullMask;
		srcVecE <= storeVec and renamedDataLiving.fullMask;

		dataToA <= routeToIQ2(renamedDataLiving, srcVecA);
		dataToB <= routeToIQ2(renamedDataLiving, srcVecB);
		dataToC <= routeToIQ2(prepareForAGU(renamedDataLiving), srcVecC);
		--dataToD <= routeToIQ2(prepareForBranch(renamedDataLiving), srcVecD);
		dataToE <= --routeToIQ2(prepareForStoreData(renamedDataLiving), srcVecE);
						prepareForStoreData(dataToSQ);
	
		dataOutSQ <= dataToSQ;
		dataToSQ <= routeToIQ(renamedDataLiving, storeVec);
		dataOutLQ <= routeToIQ(renamedDataLiving, loadVec);	
			dataOutBQ <= trgForBQ(routeToIQ(renamedDataLiving, srcVecD)); -- TEMP! Contains system instructions!
	
		invA <= invertVec(acceptingVecA);
		invB <= invertVec(acceptingVecB);
		invC <= invertVec(acceptingVecC);
		invD <= invertVec(acceptingVecD);
		invE <= invertVec(acceptingVecE);
	
		iqAcceptingA <= --not isNonzero(dataToA.fullMask and not invA);
								not isNonzero(not invA);
		iqAcceptingB <= --not isNonzero(dataToB.fullMask and not invB);							 
								not isNonzero(not invB);
		iqAcceptingC <= --not isNonzero(dataToC.fullMask and not invC);							 
								not isNonzero(not invC);
		iqAcceptingD <= --not isNonzero(dataToD.fullMask and not invD);							 
								not isNonzero(not invD);
		iqAcceptingE <= --not isNonzero(dataToE.fullMask and not invE);							 
								not isNonzero(not invE);
			
		iqAccepts <= iqAcceptingA and iqAcceptingB and iqAcceptingC and iqAcceptingD and iqAcceptingE
							and acceptingROB and acceptingSQ and acceptingLQ and acceptingBQ;

	dataOutA <= dataToA;
	dataOutB <= dataToB;
	dataOutC <= dataToC;
	dataOutD <= dataToD;
	dataOutE <= dataToE;
	
	renamedSendingOut <= renamedSending;
end Behavioral;

