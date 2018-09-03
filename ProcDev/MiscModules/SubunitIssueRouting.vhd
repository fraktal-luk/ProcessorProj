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
use work.ProcLogicIQ.all;


entity SubunitIssueRouting is
	port(
		renamedDataLiving: in StageDataMulti;

		fni: ForwardingInfo;
		readyRegFlags: in std_logic_vector(0 to 3*PIPE_WIDTH-1);

		acceptingVecA: in std_logic_vector(0 to PIPE_WIDTH-1);
		acceptingVecB: in std_logic_vector(0 to PIPE_WIDTH-1);
		acceptingVecC: in std_logic_vector(0 to PIPE_WIDTH-1);
		--acceptingVecD: in std_logic_vector(0 to PIPE_WIDTH-1);
		acceptingVecE: in std_logic_vector(0 to PIPE_WIDTH-1);
		
		acceptingA: in std_logic;
		acceptingB: in std_logic;
		acceptingC: in std_logic;
		acceptingE: in std_logic;
		
		acceptingROB: in std_logic;
		acceptingSQ: in std_logic;
		acceptingLQ: in std_logic;
		acceptingBQ: in std_logic;
		
		renamedSendingIn: in std_logic; -- Let's route it through this for clarity
		
		renamedSendingOut: out std_logic; -- Forward to IQ's
		iqAccepts: out std_logic;

		--dataOutA: out StageDataMulti;
		--dataOutB: out StageDataMulti;
		--dataOutC: out StageDataMulti;
		--dataOutD: out StageDataMulti;
		--dataOutE: out StageDataMulti;

			arrOutA: out SchedulerEntrySlotArray(0 to PIPE_WIDTH-1);
			arrOutB: out SchedulerEntrySlotArray(0 to PIPE_WIDTH-1);
			arrOutC: out SchedulerEntrySlotArray(0 to PIPE_WIDTH-1);
			--dataOutD: out StageDataMulti;
			arrOutE: out SchedulerEntrySlotArray(0 to PIPE_WIDTH-1);

		dataOutSQ: out StageDataMulti;
		dataOutLQ: out StageDataMulti;
		dataOutBQ: out StageDataMulti
	);
end SubunitIssueRouting;


architecture Behavioral of SubunitIssueRouting is	
	signal srcVecA, srcVecB, srcVecC, srcVecD, srcVecE: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
	signal storeVec, loadVec: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
	signal issueRouteVec: IntArray(0 to PIPE_WIDTH-1) := (others => 0);
		
		signal arrOutA_2: SchedulerEntrySlotArray(0 to PIPE_WIDTH-1) := (others => DEFAULT_SCH_ENTRY_SLOT);
		signal ch0, ch1, ch2: std_logic := '0';

	signal iqAcceptingA, iqAcceptingB, iqAcceptingC, iqAcceptingE: std_logic := '0';
	signal dataToA, dataToB, dataToC, dataToE, dataToSQ: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	signal renamedSending: std_logic := '0';
	signal invA, invB, invC, invE: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
	signal schedArray, arrE: SchedulerEntrySlotArray(0 to PIPE_WIDTH-1) := (others => DEFAULT_SCH_ENTRY_SLOT);
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
	srcVecA <= (findByNumber(issueRouteVec, 0) or srcVecD) and renamedDataLiving.fullMask;
	srcVecB <= findByNumber(issueRouteVec, 1) and renamedDataLiving.fullMask;
	srcVecC <= (findByNumber(issueRouteVec, 2) or storeVec or loadVec) and renamedDataLiving.fullMask;
	srcVecD <= findByNumber(issueRouteVec, 3) and not storeVec and not loadVec and renamedDataLiving.fullMask;
	srcVecE <= storeVec and renamedDataLiving.fullMask;

	ARGS_COMMON: if true generate -- Route after checking args
			schedArray <= updateForWaitingArrayNewFNI(getSchedData(renamedDataLiving.data, renamedDataLiving.fullMask),
																		readyRegFlags xor readyRegFlags, --readyRegFlags, 
																		fni);

			arrOutA <= squeezeSSA(schedArray, srcVecA);
			arrOutB <= squeezeSSA(schedArray, srcVecB);
			arrOutC <= prepareSSAForAGU(squeezeSSA(schedArray, srcVecC));
				arrE <= prepareForStoreSSA(squeezeSSA(schedArray, storeVec));

			arrOutE <= arrE;
			
			dataToSQ.data <= extractData(arrE);
			dataToSQ.fullMask <= extractFullMask(arrE);
			
			dataOutLQ.data <= extractData(squeezeSSA(schedArray, loadVec));
			dataOutLQ.fullMask <= extractFullMask(squeezeSSA(schedArray, loadVec));
	end generate;
--		ch0 <= bool2std(squeezeSSA(schedArray, srcVecA) = arrOutA_2);

	ARGS_PER_IQ: if false generate -- Check args for ech IQ after routing
		dataToA <= routeToIQ(renamedDataLiving, srcVecA);
		dataToB <= routeToIQ(renamedDataLiving, srcVecB);
		dataToC <= routeToIQ(prepareForAGU(renamedDataLiving), srcVecC);
		dataToE <= prepareForStoreData(dataToSQ);

		arrOutA <= updateForWaitingArrayNewFNI(getSchedData(dataToA.data, dataToA.fullMask),
																	readyRegFlags xor readyRegFlags, --readyRegFlags, 
																	fni);
		arrOutB <= updateForWaitingArrayNewFNI(getSchedData(dataToB.data, dataToB.fullMask),
																	readyRegFlags xor readyRegFlags, --readyRegFlags, 
																	fni);
		arrOutC <= updateForWaitingArrayNewFNI(getSchedData(dataToC.data, dataToC.fullMask),
																	readyRegFlags xor readyRegFlags, --readyRegFlags, 
																	fni);
		arrOutE <= updateForWaitingArrayNewFNI(getSchedData(dataToE.data, dataToE.fullMask),
																	readyRegFlags xor readyRegFlags, --readyRegFlags, 
																	fni);

		dataToSQ <= routeToIQ(renamedDataLiving, storeVec);
		
		dataOutLQ <= routeToIQ(renamedDataLiving, loadVec);	
		
	end generate;

	dataOutSQ <= dataToSQ;
	dataOutBQ <= trgForBQ(routeToIQ(renamedDataLiving, srcVecD)); -- TEMP! Contains system instructions!

	invA <= invertVec(acceptingVecA);
	invB <= invertVec(acceptingVecB);
	invC <= invertVec(acceptingVecC);
	--invD <= invertVec(acceptingVecD);
	invE <= invertVec(acceptingVecE);

	iqAcceptingA <= not isNonzero(not invA);
	iqAcceptingB <= not isNonzero(not invB);
	iqAcceptingC <= not isNonzero(not invC);
	--iqAcceptingD <= not isNonzero(not invD);
	iqAcceptingE <= not isNonzero(not invE);
		
	iqAccepts <= --iqAcceptingA and iqAcceptingB and iqAcceptingC and iqAcceptingE
						acceptingA and acceptingB and acceptingC and acceptingE
						and acceptingROB and acceptingSQ and acceptingLQ and acceptingBQ;

	--dataOutA <= dataToA;
	--dataOutB <= dataToB;
	--dataOutC <= dataToC;
	--dataOutD <= dataToD;
	--dataOutE <= dataToE;
	
	renamedSendingOut <= renamedSending;
end Behavioral;

