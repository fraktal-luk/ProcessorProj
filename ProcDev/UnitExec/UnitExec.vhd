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
			dataOutBQ: out InstructionState;
			prevSendingToBQ: in std_logic;
			dataNewToBQ: in StageDataMulti;
			
			committing: in std_logic;
			
			groupCtrNext: in SmallNumber;
			groupCtrInc: in SmallNumber;
			
		outputA: out InstructionSlot;
		outputB: out InstructionSlot;
		outputD: out InstructionSlot;
			
		outputOpPreB: out InstructionState;
			
		sysRegSelect: out slv5;
		sysRegIn: in Mword;
		sysRegWriteSelOut: out slv5;
		sysRegWriteValueOut: out Mword;
				
		sysRegDataOut: out InstructionState;
		sysRegSending: out std_logic;

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
	
	signal sysRegValue: Mword := (others => '0');
	signal sysRegReadSel, sysRegWriteSel: slv5 := (others => '0');
	
	signal sysRegWriteValueStore: Mword := (others => '0');
	signal sysRegWriteSelStore: slv5 := (others => '0');
	
	signal execEndsSig, execEnds2Sig: InstructionStateArray(0 to 3) := (others => defaultInstructionState);

	signal execSending2Sig: std_logic_vector(0 to 3) := (others => '0');
		
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
				
------------------------------------------------
-- Branch/System
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

-----------------------------------
	BQ_BLOCK: block
		signal --acceptingNewBQ, 
					--prevSendingToBQ, 
					storeTargetWrSig--, sendingOutBQ
					: std_logic := '0';
		--signal dataNewToBQ: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
		signal storeTargetDataSig--, dataOutBQ
						: InstructionState := DEFAULT_INSTRUCTION_STATE;
		--signal committing: std_logic := '0';
		--signal groupCtrNext, groupCtrInc: SmallNumber := (others => '0');
		
		signal storingForMTC: std_logic := '0';
		
		function trgToResult(ins: InstructionState) return InstructionState is
			variable res: InstructionState := ins;
		begin
			-- CAREFUL! Here we use 'result' because it is the field copied to arg1 in mem queue!
			-- TODO: regularize usage of such fields, maybe remove 'target' from InstructionState?
			res.result := ins.target;
			return res;
		end function;
	begin
		storeTargetDataSig <= trgToResult(dataD0);
		storeTargetWrSig <= execSendingD and
										((dataD0.controlInfo.hasBranch and dataD0.classInfo.branchReg)
									or   dataD0.controlInfo.hasReturn
									or   storingForMTC);
									
			storingForMTC <= '1' when dataD0.operation.func = sysMtc and USE_BQ_FOR_MTC else '0';						
									
			BRANCH_QUEUE: entity work.MemoryUnit(Behavioral)
			generic map(
				QUEUE_SIZE => SQ_SIZE
			)
			port map(
				clk => clk,
				reset => reset,
				en => en,
				
					acceptingOut => acceptingNewBQ,
					prevSending => prevSendingToBQ,
					dataIn => dataNewToBQ,
				
				storeAddressWr => storeTargetWrSig,
				storeValueWr => '0',-- storeValueWrSig,

				storeAddressDataIn => storeTargetDataSig,
				storeValueDataIn => DEFAULT_INSTRUCTION_STATE,-- storeValueDataSig,
				
					committing => committing,
					groupCtrNext => groupCtrNext,
						groupCtrInc => groupCtrInc,
						
				execEventSignal => eventSignal,
				execCausing => activeCausing,
				
				nextAccepting => '1',
				
				--acceptingOutSQ => execAcceptingESig,
				sendingSQOut => sendingOutBQ, -- OUTPUT
				dataOutSQ => dataOutBQ -- OUTPUT
			);
	end block;
-------------------------------------

		-- Data from sysreg reads goes to load pipe
		sysRegDataOut <= dataD0;
		sysRegSending <= execSendingD when dataD0.operation = (System, sysMfc) else '0';
		-- CAREFUL: Don't send the same thing from both subpipes:
		execSendingEffectiveD <= execSendingD when dataD0.operation /= (System, sysMfc) else '0';

		execEventSignal <= eventsD.eventOccured;
		execCausing <= eventsD.causing;

		eventSignal <= execOrIntEventSignalIn;	
		activeCausing <= execOrIntCausingIn;	

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

		sysRegWriteSelOut <= sysRegWriteSelStore;
		sysRegWriteValueOut <= sysRegWriteValueStore;

end Implem;

