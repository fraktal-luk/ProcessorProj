
architecture Behavioral5 of NewCore0 is	
	signal resetSig, enSig: std_logic := '0';				
				
	signal pcDataSig: InstructionState := DEFAULT_INSTRUCTION_STATE;
	signal pcSendingSig: std_logic := '0';

	signal acceptingOutFront: std_logic := '0';
	
	signal frontDataLastLiving: StageDataMulti;
	signal frontLastSending, renameAccepting: std_logic := '0';

	signal frontEventSignal: std_logic := '0';
	signal frontCausing: InstructionState := DEFAULT_INSTRUCTION_STATE;

---------------------------------
	signal renamedDataLiving: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;	-- INPUT			
	signal renamedSending, iqAccepts: std_logic := '0';

	-- Sys reg interface	
	signal sysRegReadSel: slv5 := (others => '0'); -- OUTPUT  -- Doesn't need to be a port of OOO part
	signal sysRegReadValue: Mword := (others => '0'); -- INPUT

	-- Mem interface
	signal memLoadAddress, memLoadValue: Mword := (others => '0');  -- OUTPUT, INPUT
	signal memLoadAllow, memLoadReady: std_logic := '0';  -- OUTPUT, INPUT

	-- evt
	signal execEventSignal, lateEventSignal, lateEventSetPC: std_logic := '0';	-- OUTPUT/SIG, INPUT 	
	signal execCausing, lateCausing: InstructionState := defaultInstructionState; -- OUTPUT/SIG

	-- Hidden to some degree, but may be useful for sth
	signal commitGroupCtrSig, commitGroupCtrNextSig: InsTag := (others => '0'); -- INPUT
	signal commitGroupCtrIncSig: InsTag := (others => '0');	-- INPUT
												
	-- ROB interface	
	signal robSending: std_logic := '0';		-- OUTPUT
	signal dataOutROB: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;		-- OUTPUT

	signal commitAccepting: std_logic := '0'; -- INPUT

	signal dataOutBQV: StageDataMulti := DEFAULT_STAGE_DATA_MULTI; -- OUTPUT
	signal dataOutSQ: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;	-- OUTPUT
-------------------------------------------------------

	signal execOrIntCausing: InstructionState := defaultInstructionState;
	signal execOrIntEventSignal: std_logic := '0';

	signal newPhysDests: PhysNameArray(0 to PIPE_WIDTH-1) := (others => (others => '0'));
	signal newPhysDestPointer: SmallNumber := (others => '0');
	signal newPhysSources: PhysNameArray(0 to 3*PIPE_WIDTH-1) := (others => (others => '0'));
		
	signal committedSending, renameLockEnd: std_logic := '0';
	signal committedDataOut: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

	signal sbEmpty, sbSending: std_logic := '0';
	signal dataFromSB: InstructionState := DEFAULT_INSTRUCTION_STATE;

	signal sysStoreAllow: std_logic := '0';
	signal sysStoreAddress: slv5 := (others => '0'); 
	signal sysStoreValue: Mword := (others => '0');
	
	signal memStoreAddress, memStoreValue: Mword := (others => '0');
	signal memStoreAllow: std_logic := '0';
		
	signal sqCommittedOutput: InstructionSlot := DEFAULT_INSTRUCTION_SLOT;
	signal sqCommittedEmpty: std_logic := '0';
	
	signal cacheFill: InstructionSlot := DEFAULT_INSTRUCTION_SLOT;

	constant HAS_RESET: std_logic := '0';
	constant HAS_EN: std_logic := '0';
begin
	resetSig <= reset and HAS_RESET;
	enSig <= en or not HAS_EN;

	cacheFill.full <= fillready;
	cacheFill.ins <= setStoredArg1(DEFAULT_INSTRUCTION_STATE, filladr);

	SEQUENCING_PART: entity work.UnitSequencer(Behavioral)
	port map (
		clk => clk, reset => resetSig, en => enSig,
		
		-- sys reg interface
		sysRegReadSel => sysRegReadSel,
		sysRegReadValue => sysRegReadValue,	
		sysStoreAllow => sysStoreAllow,
		sysStoreAddress => sysStoreAddress,
		sysStoreValue => sysStoreValue,

		-- to front pipe
		frontAccepting => acceptingOutFront,
		pcDataLiving => pcDataSig,
		pcSending => pcSendingSig,
		
		intAllowOut => intallow,
		intAckOut => intack,
		-- Events in
		intSignal => int0,
		start => int1,		
		execEventSignal => execEventSignal,
		execCausing => execCausing,
		
		frontEventSignal => frontEventSignal,
		frontCausing => frontCausing,
		
		-- Events out
		execOrIntEventSignalOut => execOrIntEventSignal,
		execOrIntCausingOut => execOrIntCausing,
		lateEventOut => lateEventSignal,
		lateEventSetPC => lateEventSetPC,
		lateCausing => lateCausing,
		-- Data from front pipe interface		
		renameAccepting => renameAccepting, -- to frontend
		frontLastSending => frontLastSending,
		frontDataLastLiving => frontDataLastLiving,

		-- Interface from register mapping
		newPhysDestsIn => newPhysDests,
		newPhysDestPointerIn => newPhysDestPointer,
		newPhysSourcesIn => newPhysSources,

		-- Interface with IQ
		iqAccepts => iqAccepts,
		renamedDataLiving => renamedDataLiving, -- !!!
		renamedSending => renamedSending,
		
		-- Interface from ROB
		commitAccepting => commitAccepting,
		sendingFromROB => robSending,	
		robDataLiving => dataOutROB,

		---
		dataFromBQV => dataOutBQV,

		sbSending => sbSending,
		dataFromSB => dataFromSB,
		sbEmpty => sbEmpty,

		-- Interface from committed stage
		committedSending => committedSending,
		committedDataOut => committedDataOut,
		renameLockEndOut => renameLockEnd,
				
		commitGroupCtrOut => commitGroupCtrSig,
		commitGroupCtrIncOut => commitGroupCtrIncSig
	);
		
	iadr <= pcDataSig.ip;
	iadrvalid <= pcSendingSig;
		
	FRONT_PART: entity work.UnitFront(Behavioral)
	port map(
		clk => clk, reset => resetSig, en => enSig,
		
		iin => iin,
		ivalid => ivalid,
					
		pcDataLiving => pcDataSig,
		pcSending => pcSendingSig,	
		frontAccepting => acceptingOutFront,

		renameAccepting => renameAccepting,			
		dataLastLiving => frontDataLastLiving,
		lastSending => frontLastSending,
		
		frontEventSignal => frontEventSignal,
		frontCausing => frontCausing,
		
		execCausing => execCausing,
		lateCausing => lateCausing,
		
		execEventSignal => execEventSignal,
		lateEventSignal => lateEventSignal,
		lateEventSetPC => lateEventSetPC
	);

	--------------------------------
	--- Out of order domain
	OUTER_OOO_AREA: block
		signal cqMaskOut: std_logic_vector(0 to 0) := (others => '0');
		signal cqDataOut: InstructionStateArray(0 to 0) := (others => DEFAULT_INSTRUCTION_STATE);
		signal cqOutput: InstructionSlotArray(0 to 0) := (others => DEFAULT_INSTRUCTION_SLOT);
		signal readyRegFlags: std_logic_vector(0 to 3*PIPE_WIDTH-1) := (others => '0');		
		signal readyRegFlagsNext: std_logic_vector(0 to 3*PIPE_WIDTH-1) := (others => '0');					
	begin

		OOO_BOX: entity work.OutOfOrderBox(Behavioral)
		port map(
		   clk => clk, reset => resetSig, en => enSig,
		
		   renamedDataLiving => renamedDataLiving,--: in StageDataMulti;	-- INPUT			
		   renamedSending => renamedSending,--: in std_logic;
		  
		   iqAccepts => iqAccepts,

		-- Sys reg interface	
			sysRegReadSel => sysRegReadSel,
			sysRegReadValue => sysRegReadValue,--: in Mword; -- INPUT

		-- Mem interface
			memLoadAddressOut => memLoadAddress,
			memLoadValue => memLoadValue,--: in Mword;
			memLoadAllow => memLoadAllow,
			memLoadReady => memLoadReady,--: in std_logic;
		-- evt
			execEventSignalOut => execEventSignal,
			lateEventSignal => lateEventSignal,--: in std_logic;
			execCausingOut => execCausing,
											
		-- Hidden to some degree, but may be useful for sth
			commitGroupCtrSig => commitGroupCtrSig,--: in SmallNumber;
			commitGroupCtrIncSig => commitGroupCtrIncSig,--: in SmallNumber;	-- INPUT
													
		-- ROB interface	
			robSendingOut => robSending,
			dataOutROB => dataOutROB,

			commitAccepting => commitAccepting,--: in std_logic; -- INPUT

			sbSending => sbSending,
			cacheFillInput => cacheFill,

			dataOutBQV => dataOutBQV,
			dataOutSQ => dataOutSQ,
			readyRegFlags => readyRegFlags,
			cqOutput => cqOutput,
				
			sqCommittedOutput => sqCommittedOutput,
			sqCommittedEmpty => sqCommittedEmpty
		);

		cqMaskOut <= extractFullMask(cqOutput);
		cqDataOut <= extractData(cqOutput);

		INT_READY_TABLE: entity work.ReadyRegisterTable(Behavioral)
		generic map(
			WRITE_WIDTH => 1
		)
		port map(
			clk => clk, reset => resetSig, en => enSig, 
			
			sendingToReserve => frontLastSending,
			stageDataToReserve => frontDataLastLiving,
				
			newPhysDests => newPhysDests,	-- FOR MAPPING
			stageDataReserved => renamedDataLiving, --stageDataOutRename,
				
			-- TODO: change to ins slot based
			writingMask => cqMaskOut,
			writingData => cqDataOut,
			readyRegFlagsNext => readyRegFlagsNext -- FOR IQs
		);

		READY_REGS_SYNCHRONOUS: process(clk) 	
		begin
			if rising_edge(clk) then
				readyRegFlags <= readyRegFlagsNext;
			end if;
		end process;
			
		INT_REG_MAPPING: block
			signal physStable, physStableDelayed: PhysNameArray(0 to PIPE_WIDTH-1) := (others=>(others=>'0'));
		begin
			INT_MAPPER: entity work.RegisterMappingUnit(Behavioral)
			port map(
				clk => clk,
				reset => resetSig,
				en => enSig,
				
				rewind => renameLockEnd,	-- FROM SEQ
				causingInstruction => DEFAULT_INSTRUCTION_STATE,
				
				sendingToReserve => frontLastSending,
				stageDataToReserve => frontDataLastLiving,
				newPhysDests => newPhysDests,	-- MAPPING (from FREE LIST)

				sendingToCommit => robSending,
				stageDataToCommit => dataOutROB,
				physCommitDests_TMP => (others => (others => '0')), -- CAREFUL: useless input?
				
				prevNewPhysDests => open,
				newPhysSources => newPhysSources,	-- TO SEQ
				
				prevStablePhysDests => physStable,  -- FOR MAPPING (to FREE LIST)
				stablePhysSources => open							
			);

			LAST_COMMITTED_SYNCHRONOUS: process(clk) 	
			begin
				if rising_edge(clk) then
					physStableDelayed <= physStable;
				end if;
			end process;
	
			INT_FREE_LIST: entity work.RegisterFreeList(Behavioral)
			port map(
				clk => clk,
				reset => resetSig,
				en => enSig,
				
				rewind => execOrIntEventSignal,
				causingPointer => execOrIntCausing.tags.intPointer,
				
				sendingToReserve => frontLastSending, 
				takeAllow => frontLastSending,	-- FROM SEQ
				auxTakeAllow => renameLockEnd,
				stageDataToReserve => frontDataLastLiving,
				
				newPhysDests => newPhysDests,			-- TO SEQ
				newPhysDestPointer => newPhysDestPointer, -- TO SEQ

				sendingToRelease => committedSending,  -- FROM SEQ
				stageDataToRelease => committedDataOut,  -- FROM SEQ
				
				physStableDelayed => physStableDelayed -- FOR MAPPING (from MAP)
			);		

		end block;
	
	end block; -- OUTER_OOO
				
	sbSending <= sqCommittedOutput.full;
	sbEmpty <= sqCommittedEmpty;
	dataFromSB <= sqCommittedOutput.ins;

-----------------------------------------
----- Mem signals -----------------------
	MEMORY_INTERFACE: block
		signal sysStoreAddressW: Mword := (others => '0');
	begin
		memStoreAddress <= getStoredArg1(dataFromSB);
		memStoreValue <= getStoredArg2(dataFromSB);
		memStoreAllow <= sbSending and isStore(dataFromSB);
				
		sysStoreAllow <= sbSending and isSysRegWrite(dataFromSB);

		sysStoreAddressW <= getStoredArg1(dataFromSB);
		sysStoreAddress <= sysStoreAddressW(4 downto 0);
		sysStoreValue <= getStoredArg2(dataFromSB);			

		dadr <= memLoadAddress;
		doutadr <= memStoreAddress;
		dread <= memLoadAllow;
		dwrite <= memStoreAllow;
		dout <= memStoreValue;
		memLoadValue <= din;
		memLoadReady <= dvalid;
	end block;
---------------------------------------------
end Behavioral5;

