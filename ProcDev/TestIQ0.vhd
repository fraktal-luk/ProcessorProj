----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:26:00 02/29/2016 
-- Design Name: 
-- Module Name:    TestIQ0 - Behavioral 
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

use work.ProcLogicIQ.all;

use work.ProcComponents.all;


entity TestIQ0 is
	generic(
		IQ_SIZE: natural := 2--;
		--N_RESULT_TAGS: natural := 1
	);
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;		
		
		resultTags: in PhysNameArray(0 to N_RES_TAGS-1);
		nextResultTags: in PhysNameArray(0 to N_RES_TAGS-1);
		dummyVals: in MwordArray(0 to N_RES_TAGS-1);
		readyRegs: in std_logic_vector(0 to N_PHYSICAL_REGS-1);				
			-- TEMP!
			ra: in std_logic_vector(0 to 31); -- := (others=>'0'); -- CAREFUL: dummy		
		prevSending: in SmallNumber;
		prevSendingOK: in std_logic;		
		nextAccepting: in std_logic; -- from exec			
		newData: in StageDataMulti;			
		
		execCausing: in InstructionState;
		execEventSignal: in std_logic;		
			-- TEMP!
			tmpPN0, tmpPN1, tmpPN2: out PhysName;		
		accepting: out SmallNumber;
		dataOutIQ: out InstructionState;
		flowResponseOutIQ: out flowResponseSimple		
	);

end TestIQ0;

architecture Behavioral of TestIQ0 is
	signal raSig: std_logic_vector(0 to 31) := (others=>'0');

	signal resetSig: std_logic := '0';
	signal enabled: std_logic := '0'; 
												
	signal aiDispatch: ArgStatusInfo;
	signal asDispatch: ArgStatusStruct;		
	
	signal aiArray: ArgStatusInfoArray(0 to IQ_SIZE-1);
	signal asArray: ArgStatusStructArray(0 to IQ_SIZE-1);
					
	signal stepData: IQStepData; -- CAREFUL, TODO: uses type with explicit reference to IQ_[ABCD]_SIZE

	-- Interface between queue and dispatch
	signal dispatchAccepting: std_logic := '0';		
	signal queueSending: std_logic := '0';
	
	-------
	function extractReadyRegBits(bits: std_logic_vector; data: InstructionStateArray)
	return std_logic_vector is
		variable res: std_logic_vector(0 to 31) := (others=>'0');
	begin
		for i in 0 to data'length-1 loop
			res(3*i + 0) := bits(slv2u(data(i).physicalArgs.s0));
			res(3*i + 1) := bits(slv2u(data(i).physicalArgs.s1));
			res(3*i + 2) := bits(slv2u(data(i).physicalArgs.s2));					
		end loop;		
		return res;
	end function;
			
begin	
	resetSig <= reset;
	enabled <= en;
		
	-- The queue	
	QUEUE_PART: block
		signal queueData, queueDataUpdated: PipeStageDataU(0 to IQ_SIZE-1) := (others=>defaultInstructionState);
		signal queueDataLiving, queueDataNext: PipeStageDataU(0 to IQ_SIZE-1) := (others=>defaultInstructionState);
		signal queueDataNew: PipeStageDataU(0 to PIPE_WIDTH-1) := (others=>defaultInstructionState);	
		
		signal emptyMask, fullMask, killMask, livingMask, readyMask, sendingMask: --, remainingMask: 
									std_logic_vector(0 to IQ_SIZE-1) := (others=>'0');				
					signal b0, b1: std_logic := '0';
					signal truncLiving: SmallNumber := (others=>'0');	
		signal flowDriveQ: FlowDriveBuffer 
					:= (killAll => '0', lockAccept => '0', lockSend => '0', others=>(others=>'0'));
		signal flowResponseQ: FlowResponseBuffer 
					:= (others => (others=> '0'));						
	begin	
		raSig <= extractReadyRegBits(readyRegs, queueData);
			
		flowDriveQ.prevSending <= prevSending;		
		
		QUEUE_SYNCHRONOUS: process(clk) 	
		begin
			if rising_edge(clk) then
				if reset = '1' then
					
				elsif en = '1' then	
					queueData <= queueDataNext;
					fullMask <= stepData.iqFullMaskNext;					
				end if;	
			end if;
		end process;	
			
		flowDriveQ.kill <= num2flow(countOnes(killMask), false);		
		queueDataLiving <= queueDataUpdated; -- TEMP?
		queueDataNew <= newData.data;									
		queueDataNext <= stepData.iqDataNext;
															
		--fullMask <= setToOnes(emptyMask, binFlowNum(flowResponseQ.full));	
		livingMask <= fullMask and not killMask;
			
		-- CAREFUL: quick fix to prevent larger 'living' than queue size		
		--truncLiving(LOG2_PIPE_WIDTH+1 downto 0) <= flowResponseQ.living(LOG2_PIPE_WIDTH + 1 downto 0);
		truncLiving <= flowResponseQ.living;
		
		stepData <= iqStep(queueDataLiving, newData, livingMask, readyMask, dispatchAccepting, 
										binFlowNum( truncLiving ),
										binFlowNum(flowResponseQ.sending),
										binFlowNum(flowDriveQ.prevSending),
										prevSendingOK);	
												
		flowDriveQ.nextAccepting <= num2flow(1, false) 
				when (stepData.sends = '1') -- and flowResponseDispatch.accepting) = '1'				
								else num2flow(0, false);															
		
		------- Scheduling logic 	
		-- Finding args already available 
		--		!! Here we need data from IQ and info from forwarding network; result goes back to IQ
		aiArray <= getArgInfoArray(queueData, dummyVals, resultTags, nextResultTags);
		queueDataUpdated <= updateIQData(queueData, aiArray);	-- Filling arg fields		
		-- Info about args avalable now, or next cycle, or not
		asArray <= getArgStatusArray(aiArray, livingMask, raSig);
		readyMask <= extractReadyMask(asArray); -- setting readyMask - directly used by flow logic
		--------------
		
		SLOT_IQ_A: entity work.BufferPipeLogic(Behavioral) -- IQ)
		generic map(
			CAPACITY => IQ_A_SIZE, -- PIPE_WIDTH * 4
			MAX_OUTPUT => 1,	-- CAREFUL! When can send to 2 different units at once, it must change to 2!
			MAX_INPUT => PIPE_WIDTH				
		)
		port map(
			clk => clk, reset =>  resetSig, en => en,
			flowDrive => flowDriveQ,
			flowResponse => flowResponseQ
		);

		KILL_MASK_A: for i in killMask'range generate
			signal before: std_logic;
			signal a, b: std_logic_vector(7 downto 0);
		begin
			a <= execCausing.numberTag;	-- execCausing: $INPUT
			b <= queueData(i).numberTag;
			IQ_KILLER: entity work.CompareBefore8 port map(
				inA =>  a,
				inB =>  b,
				outC => before
			);		
			killMask(i) <= 		before and fullMask(i)
								and 	execEventSignal; 			
		end generate;	
		
		accepting <= flowResponseQ.accepting;	

		queueSending <= flowResponseQ.sending(0); 
								-- CAREFUL: this assumes that flowResponseQ.sending is binary: [0,1]
			-- TEMP: 
			tmpPN0 <= queueData(0).physicalArgs.s0; 
			tmpPN1 <= queueData(0).physicalArgs.s1; 
			tmpPN2 <= queueData(0).physicalArgs.s2;		
	end block;

	-- Dispatch stage
	DISPATCH_PART: block
		signal dispatchData, dispatchDataNext, dispatchDataUpdated: InstructionState := defaultInstructionState;

		signal flowDriveDispatch: FlowDriveSimple := (others=>'0');											
		signal flowResponseDispatch: FlowResponseSimple := (others=>'0');

		signal dispatchArgsUpdated: InstructionArgValues := defaultArgValues;	
	begin	
		dispatchAccepting <= flowResponseDispatch.accepting;
		flowDriveDispatch.prevSending <= queueSending;
											
		DISPATCH_SYNCHRONOUS: process(clk)
		begin
			if rising_edge(clk) then
				if en = '1' then
					dispatchData <= dispatchDataNext;							
				end if;				
			end if;
		end process;
		
		dispatchDataNext <= stageSimpleNext(dispatchDataUpdated, stepData.dispatchDataNew, --dataASel(0),
															flowResponseDispatch.living,
															flowResponseDispatch.sending, 
															flowDriveDispatch.prevSending);																			
		-- Finding ready args
		aiDispatch <= getForwardingStatusInfo(dispatchData.argValues, dispatchData.physicalArgs, 
														dummyVals, resultTags, nextResultTags);
		-- Filling ready args														
					dispatchArgsUpdated <= updateArgValues(	
								dispatchData.argValues, dispatchData.physicalArgs, aiDispatch.ready, aiDispatch.vals);												
		dispatchDataUpdated <= updateInstructionArgValues(dispatchData, dispatchArgsUpdated);
		-- Info about readiness now
		asDispatch <= getArgStatus(aiDispatch, "000", "000",		
					-- CAREFUL! "'1' or" below is to look like prev version of send locking					
					'1' or flowResponseDispatch.living, "000");							
		-- Don't allow exec if args somehow are not actualy ready!		
		flowDriveDispatch.lockSend <= not asDispatch.readyAll;
		
		-- Dispatch pipe logic
		SIMPLE_SLOT_LOGIC_DISPATCH_A: SimplePipeLogic port map(
			clk => clk, reset => resetSig, en => en,
			flowDrive => flowDriveDispatch,
			flowResponse => flowResponseDispatch
		);	
			
		DISPATCH_A_KILL: block
			signal before: std_logic;
			signal a, b: std_logic_vector(7 downto 0);
		begin
			a <= execCausing.numberTag;
			b <= dispatchData.numberTag;
			DISPATCH_KILLER: entity work.CompareBefore8 port map(
				inA => a, 
				inB => b, 
				outC => before
			);		
			flowDriveDispatch.kill <= before and execEventSignal; 	
		end block;			
					
		dataOutIQ <= dispatchDataUpdated;
		flowResponseOutIQ <= flowResponseDispatch;

		flowDriveDispatch.nextAccepting <= nextAccepting; --
	end block;	
							
end Behavioral;
