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
--use work.FrontPipeDev.all;

use work.CommonRouting.all;
use work.TEMP_DEV.all;

--use work.FrontPipeDevViewing.all;

--use work.Renaming1.all;



entity TestIQ0 is
	generic(
		IQ_SIZE: natural := 2--;
		--N_RESULT_TAGS: natural := 1
	);
	port(
		-- $INPUT: clk, reset, en
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
		
		--dataToA: in StageDataMulti;
		
		resultTags: in PhysNameArray(0 to N_RES_TAGS-1);
		nextResultTags: in PhysNameArray(0 to N_RES_TAGS-1);
		dummyVals: in MwordArray(0 to N_RES_TAGS-1);
		readyRegs: in std_logic_vector(0 to N_PHYSICAL_REGS-1);		
		
			-- TEMP!
			ra: in std_logic_vector(0 to 31); -- := (others=>'0'); -- CAREFUL: dummy
		
		prevSendingA: in SmallNumber; --std_logic;
		prevSendingOK: in std_logic;
		
		nextAccepting: in std_logic; -- from exec	
		
		newData: in StageDataMulti; -- dataToA ??			
		
		execCausing: in InstructionState;
		execEventSignal: in std_logic;
		
			-- TEMP!
			tmpPN0, tmpPN1, tmpPN2: out PhysName;
		
		-- $OUTPUT
		acceptingA: out SmallNumber;
		--dispatchDataOut: 
		dataOutIQA: out InstructionState;
		--dispatchSendingOut: 
		flowResponseOutIQA: out flowResponseSimple --std_logic			
	);

end TestIQ0;

architecture Behavioral of TestIQ0 is
		signal raSig: std_logic_vector(0 to 31) := (others=>'0');

		signal resetSig: std_logic := '0';
		signal enabled: std_logic := '0'; 

		signal flowDriveA: FlowDriveBuffer 
					:= (killAll => '0', lockAccept => '0', lockSend => '0', others=>(others=>'0'));
		signal flowResponseA: FlowResponseBuffer 
					:= (others => (others=> '0'));					
		signal flowDriveDispatchA, flowDriveAPre, flowDriveAPost: FlowDriveSimple := (others=>'0');											
		signal flowResponseDispatchA, flowResponseAPre: FlowResponseSimple := (others=>'0');
			-- $output
						
						
		signal dataA, dataUpdatedA: PipeStageDataU(0 to IQ_SIZE-1) := (others=>defaultInstructionState);
		signal dataALiving, dataANext: PipeStageDataU(0 to IQ_SIZE-1) := (others=>defaultInstructionState);
		signal dataNewA: PipeStageDataU(0 to PIPE_WIDTH-1) := (others=>defaultInstructionState);
		--signal dataASel: PipeStageDataU(0 to IQ_A_SIZE-1) := (others=>defaultInstructionState);
		signal dispatchDataA, dispatchDataANext, dispatchAUpdated: InstructionState := defaultInstructionState;		
			
		signal aiA: ArgStatusInfo;
		signal asA: ArgStatusStruct;		
		
		signal aiArrayA: ArgStatusInfoArray(0 to IQ_SIZE-1);
		signal asArrayA: ArgStatusStructArray(0 to IQ_SIZE-1);

		signal emptyMaskA, fullMaskA, killMaskA, livingMaskA, readyMaskA, sendingMaskA: --, remainingMaskA: 
									std_logic_vector(0 to IQ_SIZE-1) := (others=>'0');				
		signal stepData: IQStepData;
		
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
		
		--raSig <= ra;
			raSig <= extractReadyRegBits(readyRegs, dataA);
		
		--------	A	
		flowDriveA.prevSending <= prevSendingA;		
		
		QUEUE_SYNCHRONOUS: process(clk) 	
		begin
			if rising_edge(clk) then
				if reset = '1' then
					
				elsif en = '1' then	
					dataA <= dataANext;
					fullMaskA <= stepData.iqFullMaskNext;					
					dispatchDataA <= dispatchDataANext;		
				end if;	
			end if;
		end process;	
			
		flowDriveA.kill <= num2flow(countOnes(killMaskA), false);		
		dataALiving <= dataUpdatedA; -- dataA; -- TEMP!
		dataNewA <= newData.data; --dataToA.data;									
		dataANext <= stepData.iqDataNext;
															
		--fullMaskA <= setToOnes(emptyMaskA, binFlowNum(flowResponseA.full));	
		livingMaskA <= fullMaskA and not killMaskA; --setToOnes(fullMaskA, binFlowNum(livingA));
		
		dispatchDataANext <= stageSimpleNext(dispatchAUpdated, stepData.dispatchDataNew, --dataASel(0),
															flowResponseDispatchA.living,
															flowResponseDispatchA.sending, 
															flowDriveDispatchA.prevSending);		
			-- iqStep scheme:
			--	[d.ALiving, d.ANew, fullMask, readyMask, fRA.living, fRA.sending, fDA.prevSending] 
			--		-> [d.ANext, fullMaskANext?, dispatchANew] ??
			stepData <= iqStep(dataALiving, newData, livingMaskA, readyMaskA, flowResponseDispatchA.accepting, 
														binFlowNum(flowResponseA.living),
														binFlowNum(flowResponseA.sending),
														binFlowNum(flowDriveA.prevSending),
														prevSendingOK);									
		
				--b0 <= '1' when stepData.iqDataNext = dataANext else '0';
				--b1 <= '1' when stepData.dispatchDataNew = dataASel(0) else '0';
		
		flowDriveA.nextAccepting <= num2flow(1, false) 
				--when (countOnes(sendingMaskA) = 1 and flowResponseDispatchA.accepting = '1')
				--when (isNonzero(readyMaskA) and flowResponseDispatchA.accepting) = '1'
				when (stepData.wantSend = '1') -- and flowResponseDispatchA.accepting) = '1'				
								else num2flow(0, false);						
		-- IQ A	
		aiArrayA <= getArgInfoArray(dataA, dummyVals, resultTags); -- $INPUT: dummyVals, resultTags
		dataUpdatedA <= updateIQData(dataA, aiArrayA);
		asArrayA <= getArgStatusArray(aiArrayA,		-- $INPUT: nextResultTags
									dataA, dataUpdatedA, livingMaskA, raSig, resultTags, nextResultTags, dummyVals);
		readyMaskA <= extractReadyMask(asArrayA); -- setting readyMask

		-- Dispatch A
		aiA <= getForwardingStatusInfo(dispatchDataA.argValues, dispatchDataA.physicalArgs, 
														dummyVals, resultTags);	
		dispatchAUpdated <= updateInstructionArgValues(dispatchDataA, updateArgValues(	
							dispatchDataA.argValues, dispatchDataA.physicalArgs, aiA.ready, aiA.vals));
		asA <= getArgStatus(aiA,	-- CAREFUL! "'1' or" below is to look like prev version of send locking
					dispatchDataA, dispatchAUpdated, '1' or flowResponseDispatchA.living,
										"000", resultTags, ("000000","000000"), dummyVals);
										
--------------------------------------------------------------------------------------																																	
		flowDriveDispatchA.prevSending <= flowResponseAPre.sending; -- ??
			
		flowResponseAPre.sending <= isNonzero(flowResponseA.sending);
											--stepData.wantSend; -- CAREFUL: Should be '1' iff actually sending?
																		-- !!!! And increased utilizaton!
		-- Dispatch pipe logic
		SIMPLE_SLOT_LOGIC_DISPATCH_A: SimplePipeLogic port map(
				clk => clk, reset => resetSig, en => en,
				flowDrive => flowDriveDispatchA,
				flowResponse => flowResponseDispatchA
			);	
			
		DISPATCH_A_KILL: block
			signal before: std_logic;
			signal a, b: std_logic_vector(7 downto 0);
		begin
			a <= execCausing.numberTag;
			b <= dispatchDataA.numberTag;
			DISPATCH_KILLER: entity work.CompareBefore8 port map(
				inA => a, 
				inB => b, 
				outC => before
			);		
			flowDriveDispatchA.kill <= before and execEventSignal; 	
		end block;			
			
		KILL_MASK_A: for i in killMaskA'range generate
			signal before: std_logic;
			signal a, b: std_logic_vector(7 downto 0);
		begin
			a <= execCausing.numberTag;	-- execCausing: $INPUT
			b <= dataA(i).numberTag;
			IQ_KILLER: entity work.CompareBefore8 port map(
				inA =>  a,
				inB =>  b,
				outC => before
			);		
			killMaskA(i) <= 		before and fullMaskA(i)
								and 	execEventSignal; 			
		end generate;	
----------------------------------------------------------------------------										
					SLOT_IQ_A: BufferPipeLogic -- IQ)
					generic map(
							CAPACITY => IQ_A_SIZE, -- PIPE_WIDTH * 4
							MAX_OUTPUT => 1,	-- CAREFUL! When can send to 2 different units at once, it must change to 2!
							MAX_INPUT => PIPE_WIDTH				
					)
					Port map(
						  clk => clk, reset =>  resetSig, en => en,
							flowDrive => flowDriveA,
							flowResponse => flowResponseA
						  );			

		-- Don't allow exec if args somehow are not actualy ready!		
		flowDriveDispatchA.lockSend <= not asA.readyAll;
		
		acceptingA <= flowResponseA.accepting;		
		dataOutIQA <= dispatchAUpdated;
		flowResponseOutIQA <= flowResponseDispatchA;

		flowDriveDispatchA.nextAccepting <= nextAccepting; --
		
			-- TEMP: 
			tmpPN0 <= dataA(0).physicalArgs.s0; 
			tmpPN1 <= dataA(0).physicalArgs.s1; 
			tmpPN2 <= dataA(0).physicalArgs.s2;			
end Behavioral;

