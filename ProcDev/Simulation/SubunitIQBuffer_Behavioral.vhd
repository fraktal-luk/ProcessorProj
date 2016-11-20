
use work.SimLogicIQ.all;

architecture Behavioral of SubunitIQBuffer is
	signal queueData, queueDataUpdatedSel: InstructionStateArray(0 to IQ_SIZE-1) 
								:= (others=>defaultInstructionState);
	signal fullMask, fullMaskNext, killMask, livingMask, readyMask:
								std_logic_vector(0 to IQ_SIZE-1) := (others=>'0');				
	signal flowDriveQ: FlowDriveBuffer 
				:= (killAll => '0', lockAccept => '0', lockSend => '0', others=>(others=>'0'));
	signal flowResponseQ: FlowResponseBuffer := (others => (others=> '0'));


	signal stageData, stageDataLiving, stageDataSel, stageDataUpdated, stageDataRemaining, stageDataNext:
							InstructionSlotArray(0 to IQ_SIZE-1) := (others => DEFAULT_INSTRUCTION_SLOT);
	signal stageDataNew: InstructionSlotArray(0 to PIPE_WIDTH-1) := (others => DEFAULT_INSTRUCTION_SLOT);
	
	signal firstReadyPos: integer := -1;
	signal selected: InstructionSlot := DEFAULT_INSTRUCTION_SLOT;
	
	signal sends: std_logic := '0';
	signal dispatchDataNew: InstructionState := defaultInstructionState;
	
	signal nFull, nFullNext, nKilled, nLiving, nRemaining, nSending, nReceiving: integer := 0;
	
	constant zeroRRF: std_logic_vector(readyRegFlags'range) := (others => '0');
begin
	
	QUEUE_SYNCHRONOUS: process(clk) 	
	begin
		if rising_edge(clk) then
			if reset = '1' then
				
			elsif en = '1' then	
				stageData <= stageDataNext;
				
					nFull <= nFullNext;
			end if;	
		end if;
	end process;	
			
	livingMask <= fullMask and not killMask;
					
	sends <= selected.full;
	dispatchDataNew <= selected.ins;			

		-- Kill 
		stageDataLiving <= moveQueue(stageData, stageData, -- second stageData is dummy
											  nLiving, 0, 0);

		stageDataSel <= makeSlotArray(queueDataUpdatedSel, livingMask); -- form this we send further!
		stageDataUpdated <= makeSlotArray( -- this is for those remaining in the queue
														updateForWaitingArraySim(
															--queueDataUpdatedSel,
																extractData(stageDataLiving),
															readyRegFlags,
															aiArray, '0'),
														
														livingMask);

		firstReadyPos <= getFirstOnePosition(readyMask);
		selected <= selectFromQueue(stageDataSel, firstReadyPos) when nextAccepting = '1'
				 else DEFAULT_INSTRUCTION_SLOT;
		
		stageDataRemaining <= removeFromQueue(stageDataUpdated, firstReadyPos);
		
		stageDataNew <= makeSlotArray(updateForWaitingArraySim(newData.data, readyRegFlags, aiNew, '1'),
												--	updateForSelectionArraySim(newData.data, zeroRRF, aiNew),
												newData.fullMask);
		
		stageDataNext <= moveQueue(stageDataRemaining, stageDataNew,
											nRemaining,
											0,
											nReceiving);
			
	queueData <= extractData(stageData);	
	fullMask <= extractFullMask(stageData);
	
	queueDataUpdatedSel <=  
			--updateForWaitingArraySim(		
					updateForSelectionArraySim(extractData(stageDataLiving), readyRegFlags, aiArray) --,
			--		aiArray, '0'	
			--		);
			;
	
	readyMask <= extractReadyMaskNew(queueDataUpdatedSel) and livingMask;	
	
	-- Flow numbers
	nSending <= 1 when (nextAccepting and isNonzero(readyMask)) = '1'			
			 else 0;
		
	nReceiving <= binFlowNum(prevSending);
		
	nLiving <= nFull - nKilled;
	nRemaining <= nLiving - nSending;
	nFullNext <= nRemaining + nReceiving;

	nKilled <= countOnes(killMask);	


	KILL_MASK: for i in killMask'range generate
		signal before: std_logic;
		signal a, b: std_logic_vector(7 downto 0);
	begin
		a <= execCausing.numberTag;
		b <= stageData(i).ins.numberTag;
		before <= tagBefore(a, b);
		killMask(i) <= killByTag(before, execEventSignal, intSignal) -- before and execEventSignal
								and fullMask(i); 			
	end generate;	
		
	accepting <= num2flow(IQ_SIZE - nRemaining) when IQ_SIZE - nRemaining <= PIPE_WIDTH
			 else  num2flow(PIPE_WIDTH);
						
	queueSending <= sends;
	iqDataOut <= queueData;
	newDataOut <= dispatchDataNew;
end Behavioral;
