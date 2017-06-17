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
	generic(
		INPUT_WIDTH: integer := 3;
		QUEUE_SIZE: integer := 3;
		OUTPUT_SIZE: integer := 1
	);
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;

		whichAcceptedCQ: out std_logic_vector(0 to 3) := (others=>'0');
		--cqWhichSend: in std_logic_vector(0 to 3);				
		--inputInstructions: in InstructionStateArray(0 to 3);
				maskIn: in std_logic_vector(0 to INPUT_WIDTH-1);
				dataIn: in InstructionStateArray(0 to INPUT_WIDTH-1);
		
		anySending: out std_logic;		

			cqMaskOut: out std_logic_vector(0 to OUTPUT_SIZE-1);
			cqDataOut: out InstructionStateArray(0 to OUTPUT_SIZE-1);
				
				bufferMaskOut: out std_logic_vector(0 to QUEUE_SIZE-1);
				bufferDataOut: out InstructionStateArray(0 to QUEUE_SIZE-1);
		
		execEventSignal: in std_logic;
		execCausing: in InstructionState -- Redundant cause we have inputs from all Exec ends? 		
	);
end TestCQPart0;


architecture Implem of TestCQPart0 is
	signal resetSig, enSig: std_logic := '0';

	signal flowDriveCQ: FlowDriveBuffer	:= (killAll => '0', lockAccept => '0', lockSend => '0',
																others=>(others=>'0'));
	signal flowResponseCQ: FlowResponseBuffer := (others => (others=> '0'));				
		
	signal stageDataCQNew: InstructionStateArray(0 to 3) := (others => defaultInstructionState);
	signal maskNew: std_logic_vector(0 to 3) := (others => '0');

	signal livingMaskRaw, livingMaskCQ: std_logic_vector(0 to QUEUE_SIZE-1) := (others=>'0');
		
		constant zeroMaskCQ: std_logic_vector(0 to QUEUE_SIZE-1) := (others=>'0');
		constant zeroInputMask: std_logic_vector(0 to 3) := (others=>'0');
		signal compareMaskCQ: std_logic_vector(0 to QUEUE_SIZE-1) := (others=>'0');
	
	signal stageDataCQ, stageDataCQLiving, stageDataCQNext,
									stageDataCQNextCheckOld, stageDataCQNextCheckNew
							: StageDataCommitQueue 
									:= (fullMask=>(others=>'0'), data=>(others=>defaultInstructionState));
			
	signal whichSendingFromCQ: std_logic_vector(0 to PIPE_WIDTH-1) := (others=>'0'); 
	signal whichAcceptedCQSig: std_logic_vector(0 to 3) := (others=>'0');

	constant HAS_RESET_CQ: std_logic := '0';
	constant HAS_EN_CQ: std_logic := '0';
begin
	resetSig <= reset and HAS_RESET_CQ;
	enSig <= en or not HAS_EN_CQ;

	CQ_SYNCHRONOUS: process(clk)
		variable fullMaskShifted: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
	begin
		if rising_edge(clk) then
			--if resetSig = '1' then
				
			--elsif enSig = '1' then	
				stageDataCQ <= stageDataCQNext;
				
				logBuffer(stageDataCQ.data, stageDataCQ.fullMask, livingMaskCQ,
								flowResponseCQ);

				if CQ_SINGLE_OUTPUT then				
					checkBuffer(stageDataCQ.data, stageDataCQ.fullMask,
									stageDataCQNext.data, stageDataCQNext.fullMask,
									flowDriveCQ, flowResponseCQ);	
					assert isNonzero(compareMaskCQ) = '0' report "Overwriting in CQ!";
				end if;
			--end if;
		end if;
	end process;
	
	stageDataCQLiving.data <= stageDataCQ.data;
	stageDataCQLiving.fullMask <= livingMaskCQ;
	stageDataCQNew(0 to INPUT_WIDTH-1) <= dataIn; --(0 to 2); -- Don't use branch result
	maskNew(0 to INPUT_WIDTH-1) <= maskIn;
	
	SINGLE_OUTPUT_REGS: if CQ_SINGLE_OUTPUT generate
		stageDataCQNext <= stageCQNext(stageDataCQ,
													compactData(stageDataCQNew, maskNew),
												livingMaskCQ,
													compactMask(stageDataCQNew, maskNew),
												PIPE_WIDTH,
												binFlowNum(flowResponseCQ.living),
												binFlowNum(flowResponseCQ.sending),
												binFlowNum(flowDriveCQ.prevSending));

		stageDataCQNextCheckOld <= stageCQNext(stageDataCQ,
													compactData(stageDataCQNew, maskNew),
												livingMaskCQ,
													compactMask(stageDataCQNew, zeroInputMask),
												PIPE_WIDTH,
												binFlowNum(flowResponseCQ.living),
												binFlowNum(flowResponseCQ.sending),
												binFlowNum(flowDriveCQ.prevSending));

		stageDataCQNextCheckNew <= stageCQNext(stageDataCQ,
													compactData(stageDataCQNew, maskNew),
												zeroMaskCQ,
													compactMask(stageDataCQNew, maskNew),
												PIPE_WIDTH,
												binFlowNum(flowResponseCQ.living),
												binFlowNum(flowResponseCQ.sending),
												binFlowNum(flowDriveCQ.prevSending));

		compareMaskCQ <= stageDataCQNextCheckOld.fullMask and stageDataCQNextCheckNew.fullMask;
		
												
		flowDriveCQ.prevSending <=	num2flow(countOnes(maskIn));
		flowDriveCQ.nextAccepting <= num2flow(countOnes(whichSendingFromCQ));												
	end generate;

	THREE_OUTPUTS_REGS: if CQ_THREE_OUTPUTS generate
		stageDataCQNext.fullMask(0 to 2) <= maskIn(0 to 2);
		stageDataCQNext.data(0 to 2) <= dataIn(0 to 2);
	end generate;

	whichAcceptedCQSig <= (others => '1');
													
	SLOT_CQ: entity work.BufferPipeLogic(BehavioralDirect)
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
	
	anySending <= whichSendingFromCQ(0); -- Because CQ(0) must be committing if any other is 
			
		bufferMaskOut <= stageDataCQLiving.fullMask;
		bufferDataOut <= stageDataCQLiving.data;
			
	whichAcceptedCQ <= whichAcceptedCQSig;	
	
	-- CAREFUL, TODO: this conditional generation seems to slow down timing without need, fix it!
	SINGLE_OUTPUT: if CQ_SINGLE_OUTPUT generate
		cqMaskOut <= (0 => whichSendingFromCQ(0), others => '0');
		cqDataOut <= (0 => stageDataCQLiving.data(0), others => DEFAULT_INSTRUCTION_STATE);
	end generate;

	THREE_OUTPUTS: if CQ_THREE_OUTPUTS generate
		cqMaskOut <= maskIn(0 to 2);
		cqDataOut <= dataIn(0 to 2);
	end generate;
	
end Implem;



architecture WriteBuffer of TestCQPart0 is
	signal resetSig, enSig: std_logic := '0';

	signal flowDriveCQ: FlowDriveBuffer	:= (killAll => '0', lockAccept => '0', lockSend => '0',
																others=>(others=>'0'));
	signal flowResponseCQ: FlowResponseBuffer := (others => (others=> '0'));				
		
	signal queueDataNext: InstructionSlotArray(0 to QUEUE_SIZE-1) := (others => DEFAULT_INSTRUCTION_SLOT);	
		
	signal stageData, stageDataNext:
								InstructionStateArray(0 to QUEUE_SIZE-1) := (others => defaultInstructionState);
	signal stageFullMask, stageFullMaskNext: std_logic_vector(0 to QUEUE_SIZE-1) := (others => '0');

	--signal livingMaskRaw, livingMaskCQ: std_logic_vector(0 to QUEUE_SIZE-1) := (others=>'0');
	signal isSending: std_logic := '0';
	
		constant zeroMaskCQ: std_logic_vector(0 to QUEUE_SIZE-1) := (others=>'0');
		--constant zeroInputMask: std_logic_vector(0 to 3) := (others=>'0');
		--signal compareMaskCQ: std_logic_vector(0 to QUEUE_SIZE-1) := (others=>'0');
	
	signal stageDataCQ, stageDataCQLiving, stageDataCQNext,
									stageDataCQNextCheckOld, stageDataCQNextCheckNew
							: StageDataCommitQueue 
									:= (fullMask=>(others=>'0'), data=>(others=>defaultInstructionState));
			
	signal whichSendingFromCQ: std_logic_vector(0 to PIPE_WIDTH-1) := (others=>'0'); 
	signal whichAcceptedCQSig: std_logic_vector(0 to 3) := (others=>'0');

	constant HAS_RESET_CQ: std_logic := '0';
	constant HAS_EN_CQ: std_logic := '0';
begin
	resetSig <= reset and HAS_RESET_CQ;
	enSig <= en or not HAS_EN_CQ;

	CQ_SYNCHRONOUS: process(clk)
	begin
		if rising_edge(clk) then
			--if resetSig = '1' then
				
			--elsif enSig = '1' then	
				stageData <= stageDataNext;
				stageFullMask <= stageFullMaskNext;
				
				logBuffer(stageData, stageFullMask, stageFullMask, flowResponseCQ);

					checkBuffer(stageData, stageFullMask,
									stageDataNext, stageFullMaskNext,
									flowDriveCQ, flowResponseCQ);	
			--end if;
		end if;
	end process;
		
		queueDataNext <= simpleQueueNext(stageData, dataIn,
													stageFullMask, maskIn,
													binFlowNum(flowResponseCQ.living),
													isSending);
			stageDataNext <= extractData(queueDataNext);
			stageFullMaskNext <= extractFullMask(queueDataNext);
				
		flowDriveCQ.prevSending <=	num2flow(countOnes(maskIn));
		flowDriveCQ.nextAccepting <= num2flow(1) when isSending = '1' else (others => '0');												

	whichAcceptedCQSig <= -- CAREFUL, TEMP: some simple condition: at least PIPE_WIDTH free slots
					(others => '1') when stageFullMask(QUEUE_SIZE - PIPE_WIDTH) = '0'
			 else (others => '0');
													
	SLOT_CQ: entity work.BufferPipeLogic(BehavioralDirect)
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
											
	--livingMaskRaw <= stageFullMask;	
	--livingMaskCQ <= stageFullMask;	
	
	isSending <= stageFullMask(0); -- CAREFUL: no 'nextAccepting' - introduce?
	
	anySending <= isSending; -- Because CQ(0) must be committing if any other is 
			
		bufferMaskOut <= stageFullMask;
		bufferDataOut <= stageData;
			
	whichAcceptedCQ <= whichAcceptedCQSig;	
	
		cqMaskOut <= (0 => isSending, others => '0');
		cqDataOut <= (0 => stageData(0), others => DEFAULT_INSTRUCTION_STATE);
	
end WriteBuffer;

