----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:48:52 08/07/2016 
-- Design Name: 
-- Module Name:    ReorderBuffer - Behavioral 
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

use work.ProcLogicROB.all;



entity ReorderBuffer is
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
		
		intSignal: in std_logic;
		execEventSignal: in std_logic;
		execCausing: in InstructionState; -- Redundant cause we have inputs from all Exec ends? 
		
		commitGroupCtr: in SmallNumber;
		commitGroupCtrNext: in SmallNumber;
		execEnds: in InstructionStateArray(0 to 3);
		execReady: in std_logic_vector(0 to 3);
		
			execEnds2: in InstructionStateArray(0 to 3);
			execReady2:  in std_logic_vector(0 to 3);
		
		inputData: in StageDataMulti;
		prevSending: in std_logic;
		acceptingOut: out std_logic;
		
			nextAccepting: in std_logic;
		sendingOut: out std_logic; 
		
		outputData: out StageDataMulti
	);	
end ReorderBuffer;



architecture Implem of ReorderBuffer is
	signal stageData, stageDataLiving, stageDataNext, stageDataUpdated: 
							StageDataROB := (fullMask => (others => '0'),
												  data => (others => DEFAULT_STAGE_DATA_MULTI));
	signal flowDrive: FlowDriveBuffer	:= (killAll => '0', lockAccept => '0', lockSend => '0',
																others=>(others=>'0'));
	signal flowResponse: FlowResponseBuffer := (others => (others=> '0'));

	signal resetSig, enSig: std_logic := '0';	
	
	signal isSending: std_logic := '0';
	
		signal fromCommitted: std_logic := '0';
		signal lateFetchLock: std_logic := '0'; -- DEPREC
	
	constant ROB_HAS_RESET: std_logic := '0';
	constant ROB_HAS_EN: std_logic := '0';
begin
	resetSig <= reset and ROB_HAS_RESET;
	enSig <= en or not ROB_HAS_EN;
	
	-- This is before shifting!
	stageDataLiving <= killInROB(stageData, commitGroupCtr, execCausing.groupTag,
												execEventSignal, fromCommitted);
	
		-- TODO: add execEnds2, execReady2
	stageDataUpdated <= setCompleted(stageDataLiving, commitGroupCtr,
												execEnds, execReady,
												execEnds2, execReady2);
	
	-- CAREFUL! fullMask before kills is used along with fullMask after killing!
	stageDataNext <= stageROBNext(stageDataUpdated, stageData.fullMask, inputData, 
											binFlowNum(flowResponse.living),
											isSending,
											prevSending);
											
	ROB_SYNCHRONOUS: process (clk)
	begin
		if rising_edge(clk) then
			if resetSig = '1' then
			
			elsif enSig = '1' then
				stageData <= stageDataNext;
				
				logROB(stageData, stageDataLiving, flowResponse);
				checkROB(stageData, stageDataNext, flowDrive, flowResponse);
			end if;
		end if;		
	end process;
	

	SLOT_ROB: entity work.BufferPipeLogic(--Behavioral)
														BehavioralDirect)
	generic map(
		CAPACITY => ROB_SIZE,
		MAX_OUTPUT => 1,	
		MAX_INPUT => 1				
	)
	Port map(
		clk => clk, reset => resetSig, en => enSig,
		flowDrive => flowDrive,
		flowResponse => flowResponse
	);			
	
	flowDrive.prevSending <= num2flow(1) when prevSending = '1' else num2flow(0);
	flowDrive.nextAccepting <= num2flow(1) when isSending = '1'
								else  (others => '0');
	
	flowDrive.kill <=
				i2slv((
					slv2s(flowResponse.full)
					+	integer(slv2u(tagHigh(commitGroupCtr)))
					- 	integer(slv2u(tagHigh(execCausing.groupTag)))
						) mod 2**(SMALL_NUMBER_SIZE - LOG2_PIPE_WIDTH), --(256/PIPE_WIDTH
					SMALL_NUMBER_SIZE)
				when execEventSignal = '1'
		else (others => '0');
		
	isSending <= stageData.fullMask(0)
				and groupCompleted(stageData.data(0))
				and not fromCommitted
							and nextAccepting;

	--	lateFetchLock <= '1' when LATE_FETCH_LOCK else '0';
	fromCommitted <= execEventSignal and 	
							(	execCausing.controlInfo.newInterrupt 
							or execCausing.controlInfo.newException
							or execCausing.controlInfo.specialAction
							or '0');--(execCausing.controlInfo.hasFetchLock and lateFetchLock));
						
	-- TODO: allow accepting also when queue full but sending, that is freeing a place.
	acceptingOut <= --'1' when binFlowNum(flowResponse.full) < ROB_SIZE else '0';
							not stageData.fullMask(ROB_SIZE-1);
	outputData <= stageData.data(0);
	sendingOut <= isSending;
end Implem;

