
use work.SimLogicROB.all;

architecture Behavioral of ReorderBuffer is
	signal stageData, stageDataLiving, stageDataNext, stageDataUpdated: 
							StageDataROB := (fullMask => (others => '0'),
												  data => (others => DEFAULT_STAGE_DATA_MULTI));
	signal flowDrive: FlowDriveBuffer	:= (killAll => '0', lockAccept => '0', lockSend => '0',
																others=>(others=>'0'));
	signal flowResponse: FlowResponseBuffer := (others => (others=> '0'));

	signal resetSig, enSig: std_logic := '0';	
	
	signal isSending: std_logic := '0';
	
	signal nFull, nFullNext, nKilled, nLiving, nRemaining, nSending, nReceiving: integer := 0;
	
	
	constant ROB_HAS_RESET: std_logic := '0';
	constant ROB_HAS_EN: std_logic := '0';
begin
	resetSig <= reset and ROB_HAS_RESET;
	enSig <= en or not ROB_HAS_EN;

	-- CAREFUL! fullMask before kills is used along with fullMask after killing!
	stageDataNext <= stageROBNextSim(stageDataUpdated, stageData.fullMask, inputData, 
											--binFlowNum(flowResponse.living),
												nLiving,
											isSending,
											prevSending);
	
	-- This is before shifting!
	stageDataUpdated <= setCompleted(stageDataLiving, commitGroupCtr, execEnds, execReady);
	
	stageDataLiving <=
					killInROBSim(stageData, commitGroupCtr, execCausing.groupTag, execEventSignal);
	
	
	ROB_SYNCHONOUS: process (clk)
	begin
		if rising_edge(clk) then
			if resetSig = '1' then
			
			elsif enSig = '1' then
				stageData <= stageDataNext;
					nFull <= nFullNext;
			end if;
		end if;		
	end process;
	
			-- Flow numbers
			nSending <= 1 when isSending = '1' else 0;
				
			nReceiving <= 1 when prevSending = '1' else 0;
				
			nLiving <= nFull - nKilled;
			nRemaining <= nLiving - nSending;
			nFullNext <= nRemaining + nReceiving;

			nKilled <= 	( --slv2s(flowResponse.full)
								nFull
						+	integer(slv2u(commitGroupCtr(SMALL_NUMBER_SIZE-1 downto LOG2_PIPE_WIDTH)))
						- 	integer(slv2u(execCausing.groupTag(SMALL_NUMBER_SIZE-1 downto LOG2_PIPE_WIDTH)))
							) mod (256/PIPE_WIDTH)
							when execEventSignal = '1'
					else 0;
				
	isSending <= --isNonzero(flowResponse.sending);
						stageDataLiving.fullMask(0) and groupCompleted(stageDataLiving.data(0));
	-- TODO: allow accepting also when queue full but sending, that is freeing a place.
	acceptingOut <= '1' when nLiving < ROB_SIZE else '0';
						--	not stageData.fullMask(ROB_SIZE-1);
	outputData <= stageData.data(0);
	sendingOut <= isSending;
end Behavioral;

