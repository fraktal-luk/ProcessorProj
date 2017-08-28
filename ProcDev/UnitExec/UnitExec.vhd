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
		sendingIQD: in std_logic;
	  
		whichAcceptedCQ: in std_logic_vector(0 to 3);

		dataIQA: in InstructionState;
		dataIQB: in InstructionState;
		dataIQD: in InstructionState;		

		execAcceptingA: out std_logic;
		execAcceptingB: out std_logic;
		execAcceptingD: out std_logic;
			
			acceptingNewBQ: out std_logic;
			sendingOutBQ: out std_logic;
				dataOutBQV: out StageDataMulti;
			prevSendingToBQ: in std_logic;
			dataNewToBQ: in StageDataMulti;
			
			lateEventSignal: in std_logic; 
			
			committing: in std_logic;
			
			groupCtrNext: in SmallNumber;
			groupCtrInc: in SmallNumber;
			
		outputA: out InstructionSlot;
		outputB: out InstructionSlot;
		outputD: out InstructionSlot;
			
		outputOpPreB: out InstructionState;

		execEvent: out std_logic;
		execCausingOut: out InstructionState;
		
		execOrIntEventSignalIn: in std_logic;
		execOrIntCausingIn: in InstructionState
	);
end UnitExec;


architecture Implem of UnitExec is
	signal resetSig, enSig: std_logic := '0';
	signal execEventSignal, eventSignal: std_logic := '0';
	signal execCausing: InstructionState := defaultInstructionState;
	signal activeCausing: InstructionState := defaultInstructionState;
	
	signal sysRegValue, sysRegValueReg: Mword := (others => '0');
	signal sysRegReadSel: slv5 := (others => '0');

		signal sysRegData: InstructionState := DEFAULT_INSTRUCTION_STATE;

	signal dataA0, dataB0, dataB1, dataB2, dataC0, dataC1, dataC2, dataD0: InstructionState
					:= DEFAULT_INSTRUCTION_STATE;

	signal execSendingA, execSendingB, execSendingC, execSendingD, execSendingE,
			execSendingEffectiveD: std_logic := '0';
	signal execAcceptingASig, execAcceptingBSig, execAcceptingCSig, execAcceptingDSig, execAcceptingESig:
											std_logic := '0';
	signal eventsD: StageMultiEventInfo;
		signal inputDataA, outputDataA: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
		signal inputDataD, outputDataD: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

			signal ch0, ch1: std_logic := '0';

	constant HAS_RESET_EXEC: std_logic := '1';
	constant HAS_EN_EXEC: std_logic := '1';	
begin		
		resetSig <= reset and HAS_RESET_EXEC;
		enSig <= en or not HAS_EN_EXEC; 


					inputDataA.data(0) <= --dataIQA;
												 executeAlu(dataIQA);					
					inputDataA.fullMask(0) <= sendingIQA;
					
					dataA0 <= outputDataA.data(0);
					
					SUBPIPE_A: entity work.GenericStageMulti(--BasicAlu)
																			SingleTagged)
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
					
					lateEventSignal => lateEventSignal, -- CAREFUL: seems unneeded because activeCausing has the info
					execEventSignal => eventSignal,
					execCausing => activeCausing,
					lockCommand => '0'					
				);
				
------------------------------------------------
-- Branch
					inputDataD.data(0) <= dataIQD;
					inputDataD.fullMask(0) <= sendingIQD;
					
					dataD0 <= outputDataD.data(0);
					
					SUBPIPE_D: entity work.GenericStageMulti(BranchUnit)
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
						
						stageEventsOut => eventsD						
					);	

-----------------------------------
	BQ_BLOCK: block
		signal storeTargetWrSig: std_logic := '0';
		signal storeTargetDataSig: InstructionState := DEFAULT_INSTRUCTION_STATE;
			signal storeTargetDataSRSig: InstructionState := DEFAULT_INSTRUCTION_STATE;		
	begin
		sysRegData <= setInsResult(dataD0, sysRegValueReg);
	
		storeTargetDataSig <= trgToResult(dataD0);		
		storeTargetDataSRSig <= trgToSR(dataD0);

		storeTargetWrSig <= execSendingD and
										((dataD0.controlInfo.hasBranch and --dataD0.classInfo.branchReg)
																					  not dataD0.constantArgs.immSel)
									or   dataD0.controlInfo.hasReturn);

			BRANCH_QUEUE: entity work.MemoryUnit(Behavioral)
			generic map(
				QUEUE_SIZE => BQ_SIZE,
				KEEP_INPUT_CONTENT => true
			)
			port map(
				clk => clk,
				reset => reset,
				en => en,
				
					acceptingOut => acceptingNewBQ,
					prevSending => prevSendingToBQ,
					dataIn => dataNewToBQ,
				
				storeAddressWr => storeTargetWrSig,
				storeValueWr => storeTargetWrSig,

				storeAddressDataIn => storeTargetDataSig,
				storeValueDataIn => storeTargetDataSRSig,
				
					committing => committing,
					groupCtrNext => groupCtrNext,
						groupCtrInc => groupCtrInc,
						
				lateEventSignal => lateEventSignal,
				execEventSignal => eventSignal,
				execCausing => execCausing,
				
				nextAccepting => '1',
				
				sendingSQOut => sendingOutBQ, -- OUTPUT
					dataOutV => dataOutBQV,
				dataOutSQ => open--dataOutBQ
			);
			
			SYS_REG_FF: process(clk)
			begin
				if rising_edge(clk) then
					sysRegValueReg <= sysRegValue;
				end if;
			end process;
			
	end block;
-------------------------------------

		-- Data from sysreg reads goes to load pipe
		-- CAREFUL: Don't send the same thing from both subpipes:
		execSendingEffectiveD <= execSendingD;

		execEventSignal <= eventsD.eventOccured;
		execCausing <= eventsD.causing;

		eventSignal <= execOrIntEventSignalIn;	
		activeCausing <= --execOrIntCausingIn;
								setInterrupt(execCausing, lateEventSignal);

		execAcceptingA <= execAcceptingASig;
		execAcceptingB <= execAcceptingBSig;
		execAcceptingD <= execAcceptingDSig;

		outputA.ins <= clearTempControlInfoSimple(dataA0);	
		outputA.full <= execSendingA; 
		outputB.ins <= clearTempControlInfoSimple(dataB2);	
		outputB.full <= execSendingB;
		outputD.ins <= clearTempControlInfoSimple(dataD0);	
		outputD.full <= execSendingEffectiveD;
		
		outputOpPreB <= dataB1;
				
	execEvent <= execEventSignal;
	execCausingOut <= execCausing;
end Implem;

