----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:13:04 06/16/2016 
-- Design Name: 
-- Module Name:    UnitExec - Behavioral 
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

use work.ProcLogicExec.all;

use work.ProcComponents.all;


entity UnitExec is
    Port (	
		clk : in  STD_LOGIC;
		reset : in  STD_LOGIC;
		en : in  STD_LOGIC;
	  
		sendingIQA: in std_logic;
		sendingIQB: in std_logic;
		sendingIQC: in std_logic;
		sendingIQD: in std_logic;
		sendingIQE: in std_logic;
	  
		whichAcceptedCQ: in std_logic_vector(0 to 3);

		dataIQA: in InstructionState;
		dataIQB: in InstructionState;
		dataIQC: in InstructionState;
		dataIQD: in InstructionState;				
		dataIQE: in InstructionState;				


		execAcceptingA: out std_logic;
		execAcceptingB: out std_logic;
		execAcceptingC: out std_logic;
		execAcceptingD: out std_logic;
		execAcceptingE: out std_logic;

		execSending: out std_logic_vector(0 to 3);
		execSending2: out std_logic_vector(0 to 3);

		execPreEnds: out InstructionStateArray(0 to 3);
		execEnds: out InstructionStateArray(0 to 3);
		execEnds2: out InstructionStateArray(0 to 3);
		
		memLoadReady: in std_logic;
		memLoadValue: in Mword;
		memLoadAddress: out Mword;
		memStoreAddress: out Mword;
		memLoadAllow: out std_logic;
		memStoreAllow: out std_logic;
		memStoreValue: out Mword;
			
		sysRegSelect: out slv5;
		sysRegIn: in Mword;
		sysRegWriteSelOut: out slv5;
		sysRegWriteValueOut: out Mword;
				
		selectedToCQ: out std_logic_vector(0 to 3); -- DEPREC?

		execEvent: out std_logic;
		execCausingOut: out InstructionState;
		
		execOrIntEventSignalIn: in std_logic;
		execOrIntCausingIn: in InstructionState
	);
end UnitExec;



architecture Implem of UnitExec is
	signal resetSig, enSig: std_logic := '0';
	signal execEventSignal, eventSignal: std_logic := '0';
	signal execCausing, intCausing: InstructionState := defaultInstructionState;
	signal activeCausing: InstructionState := defaultInstructionState;

	signal dataToCache: InstructionState := DEFAULT_INSTRUCTION_STATE;
	signal sendingToCache: std_logic := '0';
	
	signal memLoadAllowSig, memStoreAllowSig, sendingDataToSQ: std_logic := '0';
	
	signal sysRegValue: Mword := (others => '0');
	signal sysRegReadSel, sysRegWriteSel: slv5 := (others => '0');
	
	signal sysRegWriteValueStore: Mword := (others => '0');
	signal sysRegWriteSelStore: slv5 := (others => '0');
	
	signal execEndsSig, execEnds2Sig: InstructionStateArray(0 to 3) := (others => defaultInstructionState);

	signal execSending2Sig: std_logic_vector(0 to 3) := (others => '0');
		
	signal dataA0, dataB0, dataB1, dataB2, dataC0, dataC1, dataC2, dataD0: InstructionState
					:= DEFAULT_INSTRUCTION_STATE;

	signal execSendingA, execSendingB, execSendingC, execSendingD, execSendingE: std_logic := '0';
	signal execAcceptingASig, execAcceptingBSig, execAcceptingCSig, execAcceptingDSig, execAcceptingESig:
											std_logic := '0';

	signal eventsD: StageMultiEventInfo;

		signal inputDataA, outputDataA: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

		signal inputDataC, outputDataC: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
		signal inputDataD, outputDataD: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

						signal sendingOutSQ, acceptingOutSQ: std_logic := '0';
						signal dataOutSQ: InstructionState := DEFAULT_INSTRUCTION_STATE;

						signal storeAddressWr, storeValueWr: std_logic := '0';
						signal storeAddressDataIn, storeValueDataIn: InstructionState := DEFAULT_INSTRUCTION_STATE;

	constant HAS_RESET_EXEC: std_logic := '1';
	constant HAS_EN_EXEC: std_logic := '1';	
begin		
		resetSig <= reset and HAS_RESET_EXEC;
		enSig <= en or not HAS_EN_EXEC; 


					inputDataA.data(0) <= dataIQA;
					inputDataA.fullMask(0) <= sendingIQA;
					
					dataA0 <= outputDataA.data(0);
					
					SUBPIPE_A: entity work.SimpleAlu(Behavioral)
					port map(
						clk => clk, reset => resetSig, en => enSig,
						
						prevSending => sendingIQA,
						nextAccepting => whichAcceptedCQ(0),
						
						stageDataIn => inputDataA, 
						acceptingOut => execAcceptingASig,
						sendingOut => execSendingA,
						stageDataOut => outputDataA,
						
						execEventSignal => eventSignal,
						execCausing => activeCausing,
						lockCommand => '0',
						
						stageEventsOut => open
					);
		
				SUBPIPE_B: entity work.IntegerMultiplier(Behavioral)
				port map(
					clk => clk, reset => resetSig, en => enSig,
					
					prevSending => sendingIQB,
					nextAccepting => whichAcceptedCQ(1),
					
					dataIn => dataIQB, 
					acceptingOut => execAcceptingBSig,
					sendingOut => execSendingB,
					
						dataOut => dataB2,
						data1Prev => dataB1,
					
					execEventSignal => eventSignal,
					execCausing => activeCausing,
					lockCommand => '0'					
				);
----------------------------------------------------------

			inputDataC.data(0) <= dataIQC;
			inputDataC.fullMask(0) <= sendingIQC;
					
			NEW_SUBPIPE_C: block
				signal inputData, outputData: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
			
				signal dataM: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;				
				signal stageDataAfterCache: InstructionState := defaultInstructionState;
				
				signal stageDataOutAGU: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
				signal sendingAGU: std_logic := '0';
					
				signal stageDataOutMem0, stageDataOutMem1: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
				signal acceptingMem0, acceptingMem1,
						 sendingMem0, sendingMem1: std_logic := '0';
			begin
					STAGE_AGU: entity work.SimpleAlu(BehavioralAGU)
					port map(
						clk => clk, reset => resetSig, en => enSig,
						
						prevSending => sendingIQC,
						nextAccepting => acceptingMem0,
						
						stageDataIn => inputDataC, 
						acceptingOut => execAcceptingCSig,
						sendingOut => sendingAGU,
						stageDataOut => stageDataOutAGU,
						
						execEventSignal => eventSignal,
						execCausing => activeCausing,
						lockCommand => '0',
						
						stageEventsOut => open
					);
				
				STAGE_MEM0: entity work.GenericStageMulti(SingleTagged)
				port map(
					clk => clk, reset => resetSig, en => enSig,
					
					prevSending => sendingAGU,
					nextAccepting => acceptingMem1,
					
					stageDataIn => stageDataOutAGU,
					acceptingOut => acceptingMem0,
					sendingOut => sendingMem0,
					stageDataOut => stageDataOutMem0,
					
					execEventSignal => eventSignal,
					execCausing => activeCausing,
					lockCommand => '0',
					
					stageEventsOut => open					
				);
				
				 dataM.data(0) <= stageDataAfterCache;
				 dataM.fullMask(0) <= sendingMem0;
				
				STAGE_MEM1: entity work.GenericStageMulti(SingleTagged)
				port map(
					clk => clk, reset => resetSig, en => enSig,
					
					prevSending => sendingMem0,
					nextAccepting => whichAcceptedCQ(2),
					
					stageDataIn => dataM, 
					acceptingOut => acceptingMem1,
					sendingOut => execSendingC,
					stageDataOut => outputData,
					
					execEventSignal => eventSignal,
					execCausing => activeCausing,
					lockCommand => '0',
					
					stageEventsOut => open					
				);	
				
				dataToCache <= stageDataOutAGU.data(0);
				sendingToCache <= sendingAGU;

				stageDataAfterCache <= setExecState(stageDataOutMem0.data(0), memLoadValue, '0', "0000");
				
				dataC0 <= stageDataOutAGU.data(0);
				dataC1 <= stageDataOutMem0.data(0);
				dataC2 <= outputData.data(0);				
			end block;		

		memLoadAllowSig <= sendingToCache when dataToCache.operation.func = load else '0';
		sendingDataToSQ <= sendingToCache when dataToCache.operation.func = store else '0';
		
		memLoadAddress <= dataToCache.result;
		
		memLoadAllow <= memLoadAllowSig;
		memStoreAllow <= memStoreAllowSig;
		

------------------------------------------------

				sysRegSelect <= sysRegReadSel;
				sysRegValue <= sysRegIn;
	
	
					inputDataD.data(0) <= dataIQD;
					inputDataD.fullMask(0) <= sendingIQD;
					
					dataD0 <= outputDataD.data(0);
					
					SUBPIPE_D: entity work.BranchUnit(Behavioral)
					port map(
						clk => clk, reset => resetSig, en => enSig,
						
						prevSending => sendingIQD,
						nextAccepting => whichAcceptedCQ(3),
						
						stageDataIn => inputDataD, 
						acceptingOut => execAcceptingDSig,
						sendingOut => execSendingD,
						stageDataOut => outputDataD,
						
						execEventSignal => eventSignal,
						execCausing => activeCausing,
						lockCommand => '0',
						
						stageEventsOut => eventsD,
						
						sysRegSel => sysRegreadSel,
						sysRegValue => sysRegValue,
						
						sysRegWriteSel => sysRegWriteSelStore,
						sysRegWriteValue => sysRegWriteValueStore
					);	
-------------------------------------------------------------------------------------------------
			-- Store data unit.
			NEW_SUBPIPE_E: block
				signal inputData, outputData: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
			begin
				inputData.data(0) <= dataIQE;
				inputData.fullMask(0) <= sendingIQE;
			end block;

				execSendingE <= sendingIQE;
				execAcceptingESig <= acceptingOutSQ;
				
				memStoreAllowSig <= sendingOutSQ;
				memStoreAddress <= dataOutSQ.argValues.arg1;
				memStoreValue <= dataOutSQ.argValues.arg2;				

				storeAddressWr <= sendingDataToSQ;
				storeValueWr <= sendingIQE;
			
				storeAddressDataIn <= dataToCache;
				storeValueDataIn <= dataIQE;	

			STORE_UNIT: entity work.MemoryUnit(Behavioral)
			port map(
				clk => clk,
				reset => resetSig,
				en => enSig,
				
				storeAddressWr => storeAddressWr,
				storeValueWr => storeValueWr,

				storeAddressDataIn => storeAddressDataIn,
				storeValueDataIn => storeValueDataIn,
				
				execEventSignal => eventSignal,
				execCausing => activeCausing,
								
				acceptingOutSQ => acceptingOutSQ,
				sendingOutSQ => sendingOutSQ,
				dataOutSQ => dataOutSQ
			);
										


		execEventSignal <= eventsD.eventOccured;
		execCausing <= eventsD.causing;

		eventSignal <= execOrIntEventSignalIn;	
		activeCausing <= execOrIntCausingIn;	

				execAcceptingA <= execAcceptingASig;
				execAcceptingB <= execAcceptingBSig;
				execAcceptingC <= execAcceptingCSig;
				execAcceptingD <= execAcceptingDSig;
				execAcceptingE <= execAcceptingESig;
		
		execSending <= 
				(0 => execSendingA, 1 => execSendingB, 2 => execSendingC, 3 => execSendingD, others => '0');				
						
			execSending2Sig <= (2 => execSendingE, others => '0');
			execSending2 <= execSending2Sig;
						
		execEndsSig <= (	
							0=> clearTempControlInfoSimple(dataA0),
							1=> clearTempControlInfoSimple(dataB2),
							2=> clearTempControlInfoSimple(dataC2),
							3=> clearTempControlInfoSimple(dataD0),
						others=> defaultInstructionState);
			execEnds2Sig <= (2 => dataIQE, others => DEFAULT_INSTRUCTION_STATE);
		
		execEnds <= execEndsSig;				
			execEnds2 <= execEnds2Sig;

		execPreEnds <= (
						1 => dataB1, 2 => dataC1,
						others=> defaultInstructionState);											
				
	execEvent <= execEventSignal;
	execCausingOut <= execCausing;

		sysRegWriteSelOut <= sysRegWriteSelStore;
		sysRegWriteValueOut <= sysRegWriteValueStore;

end Implem;

