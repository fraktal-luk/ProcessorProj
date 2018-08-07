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
	  
		whichAcceptedCQ: in std_logic_vector(0 to 3);

		inputA: in SchedulerEntrySlot;
		inputB: in SchedulerEntrySlot;
		inputD: in SchedulerEntrySlot;	

		execAcceptingA: out std_logic;
		execAcceptingB: out std_logic;
		execAcceptingD: out std_logic;
			
			acceptingNewBQ: out std_logic;
				dataOutBQV: out StageDataMulti;
			prevSendingToBQ: in std_logic;
			dataNewToBQ: in StageDataMulti;
			
			lateEventSignal: in std_logic; 
			
			committing: in std_logic;
			
			--groupCtrNext: in InsTag;
			groupCtrInc: in InsTag;
				
		outputA: out InstructionSlot;
		outputB: out InstructionSlot;
		outputD: out InstructionSlot;
			
		outputOpPreB: out InstructionState;

		execEvent: out std_logic;
		execCausingOut: out InstructionState;
		
		execOrIntEventSignalIn: in std_logic
	);
end UnitExec;


architecture Implem of UnitExec is
	signal resetSig, enSig: std_logic := '0';
	signal execEventSignal, eventSignal: std_logic := '0';
	signal execCausing: InstructionState := defaultInstructionState;

	signal dataA0, dataB0, dataB1, dataB2, dataC0, dataD0: InstructionState := DEFAULT_INSTRUCTION_STATE;
	signal execSendingA, execSendingB, execSendingD: std_logic := '0';
	signal execAcceptingASig, execAcceptingBSig, execAcceptingDSig: std_logic := '0';
	--signal eventsD: StageMultiEventInfo;
	--signal inputDataA, outputDataA: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	signal inputDataD: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

	signal branchData: InstructionState := DEFAULT_INSTRUCTION_STATE;
	
	signal branchQueueSelectedOut: InstructionState := DEFAULT_INSTRUCTION_STATE;
	signal branchQueueSelectedSending: std_logic := '0';

	signal storeTargetWrSig: std_logic := '0';
	signal storeTargetDataSig: InstructionState := DEFAULT_INSTRUCTION_STATE;
	
	signal bqSelectedOutput: InstructionSlot := DEFAULT_INSTRUCTION_SLOT;

	signal inputDataA2, outputDataA2, inputDataD2, outputDataD2:
			InstructionSlotArray(0 to 0) := (others => DEFAULT_INSTRUCTION_SLOT);

	constant HAS_RESET_EXEC: std_logic := '1';
	constant HAS_EN_EXEC: std_logic := '1';	
begin		
		resetSig <= reset and HAS_RESET_EXEC;
		enSig <= en or not HAS_EN_EXEC; 

		--inputDataA <= makeSDM((0 => (inputA.full, executeAlu(inputA.ins, inputA.state, branchQueueSelectedOut))));
		inputDataA2(0) <= (inputA.full, executeAlu(inputA.ins, inputA.state, branchQueueSelectedOut));

		dataA0 <= --outputDataA.data(0);
						outputDataA2(0).ins;
		
		SUBPIPE_A: entity work.GenericStageMulti(Behavioral)
		generic map(
			COMPARE_TAG => '1'
		)
		port map(
			clk => clk, reset => resetSig, en => enSig,
			
			prevSending => inputA.full,
			nextAccepting => whichAcceptedCQ(0),
			
			--stageDataIn => inputDataA,
			stageDataIn2 => inputDataA2,
			acceptingOut => execAcceptingASig,
			sendingOut => execSendingA,
			--stageDataOut => outputDataA,
			stageDataOut2 => outputDataA2,
			
			execEventSignal => eventSignal,
			lateEventSignal => lateEventSignal,
			execCausing => execCausing
			--lockCommand => '0'
			
			--stageEventsOut => open
		);

	SUBPIPE_B: entity work.IntegerMultiplier(Behavioral)
	port map(
		clk => clk, reset => resetSig, en => enSig,
		
		prevSending => inputB.full,
		
		nextAccepting => whichAcceptedCQ(1),
		input => inputB,
		acceptingOut => execAcceptingBSig,
		sendingOut => execSendingB,
		
		dataOut => dataB2,
		data1Prev => dataB1,
		
		lateEventSignal => lateEventSignal,
		execEventSignal => eventSignal,
		execCausing => execCausing,
		lockCommand => '0'					
	);
				
------------------------------------------------
-- Branch
		branchData <=  basicBranch(setInstructionTarget(inputA.ins, inputD.ins.constantArgs.imm),
												inputA.state,
											 branchQueueSelectedOut, branchQueueSelectedSending);					
		
		--inputDataD <= makeSDM((0 => (inputA.full and isBranch(inputA.ins), branchData)));
		inputDataD2(0) <= (inputA.full and isBranch(inputA.ins), branchData);
		
		dataD0 <=-- outputDataD.data(0);
					outputDataD2(0).ins;
		
		SUBPIPE_D: entity work.GenericStageMulti(Behavioral)
		generic map(
			COMPARE_TAG => '1'
		)
		port map(
			clk => clk, reset => resetSig, en => enSig,
			
			prevSending => inputDataD2(0).full, --fullMask(0),
			nextAccepting => '1',--whichAcceptedCQ(3),
			
			--stageDataIn => inputDataD,
			stageDataIn2 => inputDataD2,
			acceptingOut => execAcceptingDSig,
			sendingOut => execSendingD,
			--stageDataOut => outputDataD,
			stageDataOut2 => outputDataD2,
			execEventSignal => eventSignal,
			lateEventSignal => lateEventSignal,
			execCausing => execCausing
			--lockCommand => '0'
			
			--stageEventsOut => open-- eventsD						
		);	

		storeTargetDataSig <= dataD0;
		storeTargetWrSig <= execSendingD;

			BRANCH_QUEUE: entity work.MemoryUnit(Behavioral)
			generic map(
				QUEUE_SIZE => BQ_SIZE,
				KEEP_INPUT_CONTENT => true,
				MODE => branch,
				ACCESS_REG => false
			)
			port map(
				clk => clk,
				reset => reset,
				en => en,
				
				acceptingOut => acceptingNewBQ,
				prevSending => prevSendingToBQ,
				dataIn => dataNewToBQ,
				
					storeAddressInput => (storeTargetWrSig, storeTargetDataSig),
					storeValueInput => (storeTargetWrSig, DEFAULT_INSTRUCTION_STATE),
					compareAddressInput => (inputA.full and isBranch(inputA.ins), inputA.ins),
					
					selectedDataOutput => bqSelectedOutput,
	
				committing => committing,
				groupCtrInc => groupCtrInc,
						
				lateEventSignal => lateEventSignal,
				execEventSignal => eventSignal,
				execCausing => execCausing,
				
				nextAccepting => '1',
				
				sendingSQOut => open,
					dataOutV => dataOutBQV,
					
					committedOutput => open,
					committedEmpty => open
			);

			branchQueueSelectedSending <= bqSelectedOutput.full;
			branchQueueSelectedOut <= bqSelectedOutput.ins;

		execEventSignal <= --eventsD.eventOccured;
									dataD0.controlInfo.newEvent;
		execCausing <= --eventsD.causing;
								dataD0;

		eventSignal <= execOrIntEventSignalIn;	

		execAcceptingA <= execAcceptingASig;
		execAcceptingB <= execAcceptingBSig;
		execAcceptingD <= execAcceptingDSig;

		outputA <= (execSendingA, clearTempControlInfoSimple(dataA0));
		outputB <= (execSendingB, clearTempControlInfoSimple(dataB2));
		outputD <= (execSendingD, clearTempControlInfoSimple(dataD0));
		
		outputOpPreB <= dataB1;
				
	execEvent <= execEventSignal;
	execCausingOut <= execCausing;
end Implem;
