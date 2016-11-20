
architecture Behavioral of TestCQPart0 is
	signal resetSig, enSig: std_logic := '0';

	signal flowDriveCQ: FlowDriveBuffer	:= (killAll => '0', lockAccept => '0', lockSend => '0',
																others=>(others=>'0'));
	signal flowResponseCQ: FlowResponseBuffer := (others => (others=> '0'));				
		
	signal cqRoutes: IntArray(0 to 3) := (others=>0);		
	signal stageDataCQNew: InstructionStateArray(0 to 3) := (others => defaultInstructionState);
	-- NOTE: emptyMask means vector of 0s
	signal emptyMaskCQ, killMaskCQ, fullMaskCQ, fullMaskCQNew, livingMaskRaw, livingMaskCQ: 
							std_logic_vector(0 to CQ_SIZE-1) := (others=>'0');
	signal killMaskRaw, killMaskNeutralize: std_logic_vector(0 to CQ_SIZE-1) := (others=>'0');					
	signal stageDataCQ, stageDataCQLiving, stageDataCQNext: StageDataCommitQueue 
									:= (fullMask=>(others=>'0'), data=>(others=>defaultInstructionState));
									
		signal stageDataCQ_N, stageDataCQLiving_N, stageDataCQNext_N: StageDataCommitQueue 
										:= (fullMask=>(others=>'0'), data=>(others=>defaultInstructionState));
							
		signal stageDataIS, stageDataISNext, stageDataISNew: InstructionSlotArray(0 to CQ_SIZE-1)
					:= (others => DEFAULT_INSTRUCTION_SLOT);
							
	signal whichSendingFromCQ: std_logic_vector(0 to PIPE_WIDTH-1) := (others=>'0'); 

	signal 
		killVec, takeAVec, takeBVec, takeCVec, takeDVec: std_logic_vector(0 to CQ_SIZE-1) := (others=>'0');
	signal tagA, tagB, tagC, tagD, tagKill: SmallNumber := (others=>'0');

	signal whichAcceptedCQSig: std_logic_vector(0 to 3) := (others=>'0');

	signal nFull, nFullNext, nKilled, nLiving, nRemaining, nSending, nReceiving: integer := 0;


	constant HAS_RESET_CQ: std_logic := '1';
	constant HAS_EN_CQ: std_logic := '1';
begin
	resetSig <= reset and HAS_RESET_CQ;
	enSig <= en or not HAS_EN_CQ;

	CQ_SYNCHRONOUS: process(clk) 	
	begin
		if rising_edge(clk) then
			if resetSig = '1' then
				
			elsif enSig = '1' then	
				--stageDataCQ <= stageDataCQNext;
					stageDataIS <= stageDataISNext;
					nFull <= nFullNext;
			end if;
		end if;
	end process;
		
	--flowDriveCQ.prevSending <=	num2flow(countOnes(cqWhichSend));
	
	--stageDataCQLiving.data <= stageDataCQ.data;
		stageDataCQLiving_N.data <= extractData(stageDataIS);
		
	--stageDataCQLiving.fullMask <= livingMaskCQ;
	stageDataCQNew <= inputInstructions;
		
		
		
--		stageDataCQNext <= stageCQNext3(stageDataCQ,
--													compactData(stageDataCQNew, cqWhichSend),
--												livingMaskCQ,
--													compactMask(stageDataCQNew, cqWhichSend),
--												PIPE_WIDTH,
--												binFlowNum(flowResponseCQ.living),
--												binFlowNum(flowResponseCQ.sending),
--												binFlowNum(flowDriveCQ.prevSending));	


		stageDataISNew <= makeSlotArray(
					compactData(inputInstructions, cqWhichSend), compactMask(inputInstructions, cqWhichSend));
		
		stageDataISNext <= moveQueue(stageDataIS, stageDataISNew,
											  nLiving, nSending, nReceiving);

			-- Flow numbers
			nSending <= PIPE_WIDTH when nLiving >= PIPE_WIDTH else nLiving;
				
			nReceiving <= countOnes(cqWhichSend);
				
			nLiving <= nFull - nKilled;
			nRemaining <= nLiving - nSending;
			nFullNext <= nRemaining + nReceiving;

			--nKilled <= countOnes(killMask);

											
	whichAcceptedCQSig <= selectedToCQ;	-- Accepting all



--	SLOT_CQ: entity work.BufferPipeLogic(Behavioral)
--	generic map(
--		CAPACITY => CQ_SIZE,
--		MAX_OUTPUT => PIPE_WIDTH,	
--		MAX_INPUT => 4				
--	)
--	Port map(
--		clk => clk, reset =>  resetSig, en => enSig,
--		flowDrive => flowDriveCQ,
--		flowResponse => flowResponseCQ
--	);			
											
	livingMaskRaw <= --stageDataCQ.fullMask;
						  extractFullMask(stageDataIS);
	livingMaskCQ <= --stageDataCQ.fullMask;	
						  extractFullMask(stageDataIS);
	
	whichSendingFromCQ <= getSendingFromCQ(livingMaskRaw);
	
	--flowDriveCQ.nextAccepting <= num2flow(countOnes(whichSendingFromCQ));
	
	-- CAREFUL: using "raw" living mask, cause it prevents a comb. loop when implementing
	--				the feature: Spare "almost committed".
	--				Otherwise loop would happen: whichSending depends on livingMask, and livingMask
	--				on next commitCtr, and commitCtr OFC depends on whichSending! 
	
	cqOut.fullMask <= whichSendingFromCQ;
	cqOut.data <= --stageDataCQLiving.data(0 to PIPE_WIDTH-1); -- ??(some may be killed? careful)			
						stageDataCQLiving_N.data(0 to PIPE_WIDTH-1);
	
	anySending <= whichSendingFromCQ(0); -- Because CQ(0) must be committing if any other is 

	-- CAREFUL: don't propagate here result tags from empty slots!	
	--				Clearing result tags for empty slots handled in CQ step function 
	dataCQOut <= --stageDataCQLiving;
						stageDataCQLiving_N;
			
	whichAcceptedCQ <= whichAcceptedCQSig;		
end Behavioral;
