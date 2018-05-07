

architecture WriteBuffer of TestCQPart0 is

	signal resetSig, enSig: std_logic := '0';



	signal flowDriveCQ: FlowDriveBuffer	:= (killAll => '0', lockAccept => '0', lockSend => '0',

																others=>(others=>'0'));

	signal flowResponseCQ: FlowResponseBuffer := (others => (others=> '0'));				

		

	signal queueDataNext: InstructionSlotArray(0 to QUEUE_SIZE-1) := (others => DEFAULT_INSTRUCTION_SLOT);	

		

	signal stageData, stageDataNext:

								InstructionStateArray(0 to QUEUE_SIZE-1) := (others => defaultInstructionState);

	signal stageFullMask, stageFullMaskNext: std_logic_vector(0 to QUEUE_SIZE-1) := (others => '0');



	signal isSending: std_logic := '0';

	

		constant zeroMaskCQ: std_logic_vector(0 to QUEUE_SIZE-1) := (others=>'0');

	signal stageDataCQ, stageDataCQLiving, stageDataCQNext,

									stageDataCQNextCheckOld, stageDataCQNextCheckNew

							: StageDataCommitQueue 

									:= (fullMask=>(others=>'0'), data=>(others=>defaultInstructionState));

			

	signal whichSendingFromCQ: std_logic_vector(0 to PIPE_WIDTH-1) := (others=>'0'); 

	signal whichAcceptedCQSig: std_logic_vector(0 to 3) := (others=>'0');



		signal maskIn: std_logic_vector(0 to INPUT_WIDTH-1) := (others => '0');

		signal dataIn: InstructionStateArray(0 to INPUT_WIDTH-1) := (others => DEFAULT_INSTRUCTION_STATE);



	constant HAS_RESET_CQ: std_logic := '0';

	constant HAS_EN_CQ: std_logic := '0';

begin

	resetSig <= reset and HAS_RESET_CQ;

	enSig <= en or not HAS_EN_CQ;



		maskIn <= extractFullMask(input);

		dataIn <= extractData(input);



	CQ_SYNCHRONOUS: process(clk)

	begin

		if rising_edge(clk) then	

				stageData <= stageDataNext;

				stageFullMask <= stageFullMaskNext;

				

				logBuffer(stageData, stageFullMask, stageFullMask, flowResponseCQ);



					checkBuffer(stageData, stageFullMask,

									stageDataNext, stageFullMaskNext,

									flowDriveCQ, flowResponseCQ);	

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



	isSending <= stageFullMask(0); -- CAREFUL: no 'nextAccepting' - introduce?

	

	anySending <= isSending; -- Because CQ(0) must be committing if any other is 

			

	bufferOutput <= makeSlotArray(stageData, stageFullMask);

			

	whichAcceptedCQ <= whichAcceptedCQSig;	

	

	cqOutput <= (0 => (isSending, stageData(0)), others => DEFAULT_INSTRUCTION_SLOT);	

end WriteBuffer;

