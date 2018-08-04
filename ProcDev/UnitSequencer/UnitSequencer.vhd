----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:06:59 04/24/2016 
-- Design Name: 
-- Module Name:    UnitFront - Behavioral 
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
use work.ProcHelpers.all;

use work.ProcInstructionsNew.all;

use work.NewPipelineData.all;

use work.GeneralPipeDev.all;

use work.TEMP_DEV.all;

use work.ProcComponents.all;

use work.ProcLogicFront.all;
use work.ProcLogicRenaming.all;

use work.ProcLogicSequence.all;


entity UnitSequencer is
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;

		-- System reg interface
		sysRegReadSel: in slv5;
		sysRegReadValue: out Mword;
	
		-- Event/state interface						
		intSignal: in std_logic;
		execEventSignal: in std_logic;
		execCausing: in InstructionState;		
		
		frontEventSignal: in std_logic;
		frontCausing: in InstructionState;
		
		execOrIntEventSignalOut: out std_logic;
		execOrIntCausingOut: out InstructionState;	
		lateEventOut: out std_logic;
		lateEventSetPC: out std_logic;
		lateCausing : out InstructionState;
		
		-- Interface PC <-> front pipe
		frontAccepting: in std_logic;
		pcSending: out std_logic;		
		pcDataLiving: out InstructionState;
		
		-- Interface Rename <-> Front 	
		frontDataLastLiving: in StageDataMulti;
		frontLastSending: in std_logic;		
		renameAccepting: out std_logic;		
		
		-- Interface from Rename with IQ	
		iqAccepts: in std_logic;
		renamedDataLiving: out StageDataMulti;
		renamedSending: out std_logic;

		-- Interface with ROB
		commitAccepting: out std_logic;
		robDataLiving: in StageDataMulti;
		sendingFromROB: in std_logic;
		
		dataFromBQV: in StageDataMulti;
		
		dataFromSB: in InstructionState;
		sbEmpty: in std_logic;
		sbSending: in std_logic;
		
		sysStoreAllow: in std_logic;
		sysStoreAddress: in slv5; 
		sysStoreValue: in Mword;		
		
		-- Counter outputs
		commitGroupCtrOut: out InsTag;		
		commitGroupCtrIncOut: out InsTag;
		
		committedSending: out std_logic;
		committedDataOut: out StageDataMulti;
	
		renameLockEndOut: out std_logic;
	
		newPhysDestsIn: in PhysNameArray(0 to PIPE_WIDTH-1);
		newPhysDestPointerIn: in SmallNumber;
		newPhysSourcesIn: in PhysNameArray(0 to 3*PIPE_WIDTH-1);
		
		intAllowOut: out std_logic;
		intAckOut: out std_logic;
		
		start: in std_logic	-- TODO: change to reset interrupt
	);
end UnitSequencer;


architecture Behavioral of UnitSequencer is
	signal resetSig, enSig: std_logic := '0';							

	signal pcNext: Mword := (others => '0');

	signal stageDataToPC, stageDataOutPC: InstructionState := DEFAULT_INSTRUCTION_STATE;
	signal sendingToPC, sendingOutPC, acceptingOutPC: std_logic := '0';

	signal tmpPcIn, tmpPcOut: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

	signal linkInfo: InstructionState := DEFAULT_INSTRUCTION_STATE;
	signal excInfoUpdate, intInfoUpdate: std_logic := '0';

	signal execOrIntEventSignal: std_logic := '0';
	signal execOrIntCausing: InstructionState := defaultInstructionState;

	signal stageDataRenameIn: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	signal stageDataOutRename: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	signal sendingOutRename, acceptingOutRename: std_logic:= '0';

	signal sendingToCommit, sendingOutCommit, acceptingOutCommit: std_logic := '0';
	signal stageDataToCommit, stageDataOutCommit: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;						

	signal renameCtr, renameCtrNext, commitCtr, commitCtrNext: InsTag := (others => '1');
	signal renameGroupCtr, renameGroupCtrNext, commitGroupCtr, commitGroupCtrNext: InsTag := INITIAL_GROUP_TAG;
	signal commitGroupCtrInc: InsTag := (others => '0');
	
	signal effectiveMask: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
	
	signal renameLockCommand, renameLockRelease, renameLockState, renameLockEnd: std_logic := '0';	
				
	signal dataToLastEffective, dataToLastEffective2, dataFromLastEffective, dataFromLastEffective2, NEW_eiCausing:
														StageDataMulti := DEFAULT_STAGE_DATA_MULTI;	
	signal insToLastEffective: InstructionState := DEFAULT_INSTRUCTION_STATE;	

	signal lateCausingSig: InstructionState := DEFAULT_INSTRUCTION_STATE;
			
	signal lateTargetIns: InstructionState := DEFAULT_INSTRUCTION_STATE;		
			
	signal gE_eventOccurred, gE_killPC, ch0, ch1: std_logic := '0';

	signal committingEvt, newEvt, evtPhase0, evtPhase1, evtPhase2, evtWaiting: std_logic := '0';
	signal intPhase0, intPhase1, intPhase2, intWaiting, addDbEvent, intAllow, intAck: std_logic := '0';
	signal dbtrapOn: std_logic := '0';

	constant HAS_RESET_SEQ: std_logic := '0';
	constant HAS_EN_SEQ: std_logic := '0';
begin	 
	resetSig <= reset and HAS_RESET_SEQ;
	enSig <= en or not HAS_EN_SEQ;

	EVENTS: block
	begin	
			gE_killPC <= evtPhase0;
			gE_eventOccurred <= evtPhase0 or execEventSignal or frontEventSignal;

			lateEventOut <= evtPhase0;
			lateEventSetPC <= evtPhase2;
		execOrIntEventSignal <= evtPhase0 or execEventSignal;
		execOrIntCausing <= lateCausingSig when evtPhase0 = '1' else execCausing;
		lateCausing <= lateCausingSig;

		execOrIntEventSignalOut <= execOrIntEventSignal;	-- $MODULE_OUT
		execOrIntCausingOut <= execOrIntCausing; -- $MODULE_OUT
	end block;

	pcNext <= getNextPC(stageDataOutPC.ip, (others => '0'), '0');

	stageDataToPC <= newPCData(evtPhase2, lateCausingSig,
										execEventSignal, execCausing,
										frontEventSignal, frontCausing,
										pcNext);
			
	sendingToPC <= 
			sendingOutPC or (gE_eventOccurred and not gE_killPC) or (evtPhase2 and not isHalt(lateCausingSig));
										-- CAREFUL: Because of the above, PC is not updated in phase2 of halt instruction,
										--				so the PC of a halted logical processor is not defined.

		tmpPcIn <= makeSDM((0 => (sendingToPC, stageDataToPC)));

		SUBUNIT_PC: entity work.GenericStageMulti(Behavioral) port map(
			clk => clk, reset => resetSig, en => enSig,
					
			prevSending => sendingToPC,

			nextAccepting => '1', -- CAREFUL: front should always accet - if can't, there will be refetch not stall
										 --	  		 In multithreaded implementation it should be '1' for selected thread 
			stageDataIn => tmpPcIn,
			
			acceptingOut => acceptingOutPC,
			sendingOut => sendingOutPC,
			stageDataOut => tmpPcOut,
			
			execEventSignal => gE_eventOccurred,
			lateEventSignal => evtPhase0,
			execCausing => DEFAULT_INSTRUCTION_STATE,
			lockCommand => '0'		
		);			

		stageDataOutPC.ip <= tmpPcOut.data(0).ip;
		stageDataOutPC.target <= pcNext; -- CAREFUL: Attaching next address from line predictor. Correct?

	excInfoUpdate <= evtPhase1 and (lateCausingSig.controlInfo.hasException
												or lateCausingSig.controlInfo.dbtrap);
	intInfoUpdate <= evtPhase1 and lateCausingSig.controlInfo.hasInterrupt;
	
	----------------------------------------------------------------------
	
	SYS_REGS: block
		signal sysRegArray: MwordArray(0 to 31) := (0 => PROCESSOR_ID, others => (others => '0'));	

		alias currentState is sysRegArray(1);
		alias linkRegExc is sysRegArray(2);
		alias linkRegInt is sysRegArray(3);
		alias savedStateExc is sysRegArray(4);
		alias savedStateInt is sysRegArray(5);
	begin
		linkInfo <= getLinkInfo(dataFromLastEffective2.data(0), currentState);
	
		CLOCKED: process(clk)
		begin					
			if rising_edge(clk) then
				-- Reading sys regs
				sysRegReadValue <= sysRegArray(slv2u(sysRegReadSel));			

				-- Write from system write instruction
				if sysStoreAllow = '1' then
					sysRegArray(slv2u(sysStoreAddress)) <= sysStoreValue;
				end if;

				-- Writing specialized fields on events
				if evtPhase1 = '1' then
					currentState <= lateTargetIns.result;
					currentState(15 downto 10) <= (others => '0');
					currentState(7 downto 2) <= (others => '0');
				end if;
				
				-- NOTE: writing to link registers after sys reg writing gives priority to the former,
				--			but committing a sysMtc shouldn't happen in parallel with any control event
				-- Writing exc status registers
				if excInfoUpdate = '1' then
					linkRegExc <= linkInfo.ip;
					savedStateExc <= linkInfo.result;
				end if;
				
				-- Writing int status registers
				if intInfoUpdate = '1' then
					linkRegInt <= linkInfo.ip;
					savedStateInt <= linkInfo.result;
				end if;
				
				-- Enforcing content of read-only registers
				sysRegArray(0) <= PROCESSOR_ID;
				
				-- Only some number of system regs exists		
				for i in 6 to 31 loop
					sysRegArray(i) <= (others => '0');
				end loop;				
			end if;	
		end process;

		
		-- CAREFUL: this counts at phase1 --------------------------------------------------
		lateTargetIns <= getLatePCData(lateCausingSig,
													currentState,
													linkRegExc, linkRegInt,
													savedStateExc, savedStateInt);

			NEW_eiCausing.fullMask(0) <= '1';
			NEW_eiCausing.data(0) <= clearControlEvents(
												setInstructionTarget(dataFromLastEffective2.data(0), lateTargetIns.ip));
		-------------------------------------------------------------------------------------
		dbtrapOn <= currentState(25);
	end block;

	pcDataLiving <= stageDataOutPC;
	pcSending <= sendingOutPC;	

	-- Rename stage
	stageDataRenameIn <= renameGroup(frontDataLastLiving, newPhysSourcesIn, newPhysDestsIn, renameCtr,
														renameGroupCtrNext, newPhysDestPointerIn, dbtrapOn);

	SUBUNIT_RENAME: entity work.GenericStageMulti(Behavioral)--Renaming)
	generic map(
		USE_CLEAR => '0'
	)
	port map(
		clk => clk, reset => resetSig, en => enSig,
		
		-- Interface with front
		prevSending => frontLastSending,	
		stageDataIn => stageDataRenameIn, --readyRegFlagsV),
		acceptingOut => acceptingOutRename,
		
		-- Interface with IQ
		nextAccepting => iqAccepts,
		sendingOut => sendingOutRename,
		stageDataOut => stageDataOutRename,
		
		-- Event interface
		execEventSignal => execOrIntEventSignal,
		lateEventSignal => evtPhase0,		
		execCausing => execOrIntCausing,
		lockCommand => '0'--renameLockState		
	);

	COMMON_STATE: block
	begin
		renameGroupCtrNext <= nextCtr(renameGroupCtr, execOrIntEventSignal,
												execOrIntCausing.tags.renameIndex and i2slv(-PIPE_WIDTH, TAG_SIZE),
												frontLastSending, ALL_FULL);
		renameCtrNext <= nextCtr(renameCtr, execOrIntEventSignal, execOrIntCausing.tags.renameSeq,
										 frontLastSending, frontDataLastLiving.fullMask);
		commitGroupCtrNext <= nextCtr(commitGroupCtr, '0', (others => '0'), sendingToCommit, ALL_FULL);
		commitCtrNext <= nextCtr(commitCtr, '0', (others => '0'), sendingToCommit, effectiveMask);

		commitGroupCtrInc <= i2slv(slv2u(commitGroupCtr) + PIPE_WIDTH, TAG_SIZE);

		-- Re-allow renaming when everything from rename/exec is committed - reg map will be well defined now
		renameLockRelease <= '1' when commitGroupCtr = renameGroupCtr else '0';
			-- CAREFUL, CHECK: when the counters are equal, renaming can be resumed, but renameLockRelease
			-- 					 takes effect in next cycle, so before tha cycle renaming is still stopped.
			--						 Should compare to commitCtrNext instead?
			--						 But remember that rewinding GPR map needs a cycle, and before it happens,
			--						 renaming can't be done! So this delay may be caused by this problem.

		renameLockEnd <= renameLockState and renameLockRelease;

		effectiveMask <= getEffectiveMask(stageDataToCommit);
			
		COMMON_SYNCHRONOUS: process(clk) 	
		begin
			if rising_edge(clk) then
				renameCtr <= renameCtrNext;
				commitCtr <= commitCtrNext;					
				renameGroupCtr <= renameGroupCtrNext;
				commitGroupCtr <= commitGroupCtrNext;

				-- Lock when exec part causes event
				if execOrIntEventSignal = '1' then -- CAREFUL
					renameLockState <= '1';	
				elsif renameLockRelease = '1' then
					renameLockState <= '0';
				end if;					
			end if;	
		end process;		
	end block;

	sendingToCommit <= sendingFromROB;

	-- Commit stage: in order again				
	SUBUNIT_COMMIT: entity work.GenericStageMulti(Behavioral)
	port map(
		clk => clk, reset => resetSig, en => enSig,
		
		-- Interface with CQ
		prevSending => sendingToCommit,
		stageDataIn => stageDataToCommit,
		acceptingOut => open, -- unused but don't remove
		
		-- Interface with hypothetical further stage
		nextAccepting => '1',
		sendingOut => sendingOutCommit,
		stageDataOut => stageDataOutCommit,
		
		-- Event interface
		execEventSignal => '0', -- CAREFUL: committed cannot be killed!
		lateEventSignal => '0',	
		execCausing => execOrIntCausing,		

		lockCommand => '0'
	);

		-- Tracking of target:
		--			'target' field of last effective will hold the address of next instruction
		--			to commit after lastEffective; it will be known with certainty because lastEffective is 
		--			already committed. 
		--			When committing a taken branch -> fill with target from BQ output
		--			When committing normal op -> increment by length of the op 
		--			
		--			The 'target' field will be used to update return address for exc/int
		stageDataToCommit <= recreateGroup(robDataLiving, dataFromBQV, dataFromLastEffective2.data(0).target);
		insToLastEffective <= getLastEffective(stageDataToCommit);	
		dataToLastEffective <= makeSDM((0 => (sendingToCommit, insToLastEffective)));

			lateCausingSig <= setInterrupt3(dataFromLastEffective2.data(0), intPhase1, start);

			dataToLastEffective2 <= dataToLastEffective when (evtPhase1) = '0' else NEW_eiCausing;

			LAST_EFFECTIVE_SLOT: entity work.GenericStageMulti(Behavioral)
			port map(
				clk => clk, reset => resetSig, en => enSig,
				
				-- Interface with CQ
				prevSending => sendingToCommit or evtPhase1,
				stageDataIn => dataToLastEffective2,-- TMPpre_lastEffective,
				acceptingOut => open, -- unused but don't remove
				
				-- Interface with hypothetical further stage
				nextAccepting => '1',
				sendingOut => open,
				stageDataOut => dataFromLastEffective2,--TMP_lastEffective,
				
				-- Event interface
				execEventSignal => '0', -- CAREFUL: committed cannot be killed!
				lateEventSignal => '0',	
				execCausing => DEFAULT_INSTRUCTION_STATE,--interruptCause,		

				lockCommand => '0'
			);

			EV_PHASES: block
			begin
				evtPhase0 <= newEvt or (intSignal);
				evtPhase1 <= (evtPhase0 and sbEmpty)
							or  (evtWaiting and sbEmpty);

				committingEvt <= sendingToCommit and dataToLastEffective2.data(0).controlInfo.newEvent;
				-- CAREFUL: when committingEvt, it is forbidden to indicate interrupt in next cycle! 
				
				-- CAREFUL: probably not used, because dbtrap will be a normal exc, overridden by "real" exceptions
				addDbEvent <= committingEvt and dataToLastEffective2.data(0).controlInfo.dbtrap;
													-- Forces int controller to insert a DB interrupt and issue it ASAP 

				intPhase0 <= intSignal;
				intPhase1 <= (intPhase0 and sbEmpty)	-- TODO: intPhase1 serves as int ACK
							or	 (intWaiting and sbEmpty);
				
				intAllow <= not (committingEvt or evtPhase0 or (evtWaiting and not evtPhase1));
				--			int can be asserted by int controller in next cycle if intAllow = '1'
				
				intAck <= intPhase1;
				
				process (clk)
				begin
					if rising_edge(clk) then
						if (newEvt and (intSignal)) = '1' then
							report "Not allowed to interrupt while causing synchronous exception!" severity error;
						end if;

						newEvt <= committingEvt;

						if newEvt = '1' then
							newEvt <= '0';
						end if;
					
						if evtPhase0 = '1' and evtPhase1 = '0' then
							evtWaiting <= '1';
						elsif evtPhase1 = '1' then
							evtWaiting <= '0';
							evtPhase2 <= '1';
						elsif evtPhase2 = '1' then
							evtPhase2 <= '0';
						end if;
						
						if intPhase0 = '1' and intPhase1 = '0' then
							intWaiting <= '1';
						elsif intPhase1 = '1' then
							intWaiting <= '0';
							intPhase2 <= '1';
						elsif intPhase2 = '1' then
							intPhase2 <= '0';
						end if;
					end if;
				end process;
			end block;	
	
	intAllowOut <= intAllow;
	intAckOut <= intAck;
	
	renameAccepting <= acceptingOutRename and not renameLockState;
	renamedDataLiving <= stageDataOutRename;
	renamedSending <= sendingOutRename;
	
	commitGroupCtrOut <= commitGroupCtr;
	commitGroupCtrIncOut <= commitGroupCtrInc;

	renameLockEndOut <= renameLockEnd;
	commitAccepting <= '1';
	committedSending <= sendingOutCommit;
	committedDataOut <= stageDataOutCommit;
end Behavioral;

