----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:57:56 12/11/2016 
-- Design Name: 
-- Module Name:    MemoryUnit - Behavioral 
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

use work.ProcLogicFront.all;

use work.ProcLogicExec.all;
use work.ProcLogicMemory.all;

use work.BasicCheck.all;

use work.Queues.all;


entity MemoryUnit is
	generic(
		QUEUE_SIZE: integer := 4;
		CLEAR_COMPLETED: boolean := true;
		KEEP_INPUT_CONTENT: boolean := false
	);
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;

		acceptingOut: out std_logic;
		prevSending: in std_logic;
		dataIn: in StageDataMulti;

		storeAddressWr: in std_logic;
		storeValueWr: in std_logic;

		storeAddressDataIn: in InstructionState;
		storeValueDataIn: in InstructionState;

			compareAddressDataIn: in InstructionState;
			compareAddressReady: in std_logic;

			selectedDataOut: out InstructionState;
			selectedSending: out std_logic;

		committing: in std_logic;
		groupCtrInc: in SmallNumber;

		lateEventSignal: in std_logic;
		execEventSignal: in std_logic;
		execCausing: in InstructionState;
		
		nextAccepting: in std_logic;		
		sendingSQOut: out std_logic;
			dataOutV: out StageDataMulti
	);
end MemoryUnit;


architecture Behavioral of MemoryUnit is
	constant zeroMask: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');

	signal sendingSQ: std_logic := '0';							

	signal content, contentNext, contentUpdated:
					InstructionSlotArray(0 to QUEUE_SIZE-1) := (others => DEFAULT_INSTRUCTION_SLOT);
	signal contentData, contentDataNext,  TMP_content, TMP_contentNext: InstructionStateArray(0 to QUEUE_SIZE-1)
																			:= (others => DEFAULT_INSTRUCTION_STATE);
	signal fullMask, livingMask, killMask, contentMaskNext, matchingA, matchingD,
				TMP_mask, TMP_ckEnForInput, TMP_sendingMask, TMP_killMask, TMP_livingMask,
				TMP_maskNext,	TMP_maskA, TMP_maskD
								: std_logic_vector(0 to QUEUE_SIZE-1) := (others => '0'); 
	signal sqOutData, TMP_frontW, TMP_preFrontW, TMP_sendingData: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

	signal bufferDrive: FlowDriveBuffer := (killAll => '0', lockAccept => '0', lockSend => '0',
																others=>(others=>'0'));
	signal bufferResponse: FlowResponseBuffer := (others=>(others=>'0'));
	
		signal qs0, qs1: TMP_queueState := TMP_defaultQueueState;
		signal contentView, contentNextView:
					InstructionStateArray(0 to QUEUE_SIZE-1) := (others => DEFAULT_INSTRUCTION_STATE);
		signal maskView, liveMaskView, maskNextView: std_logic_vector(0 to QUEUE_SIZE-1) := (others => '0');
		
		signal inputIndices: SmallNumberArray(0 to QUEUE_SIZE-1) := (others => (others => '0'));

		signal cmpMask, newestMatch: std_logic_vector(0 to QUEUE_SIZE-1) := (others => '0');
		
		signal selectedData: InstructionState := DEFAULT_INSTRUCTION_STATE;
		signal selectedSendingSig: std_logic := '0';
		
		
		function compareAddress(content: InstructionStateArray; ins: InstructionState) return std_logic_vector is
			variable res: std_logic_vector(0 to QUEUE_SIZE-1) := (others => '0');
		begin
			for i in 0 to res'length-1 loop
				if ins.argValues.arg1 = content(i).argValues.arg1 then
					res(i) := '1';
				end if;
				
				if ins.argValues.arg1(4) = '1' then
					report "gaggagaa";
					report integer'image(slv2u(ins.argValues.arg1)) & ", " &
							 integer'image(slv2u(content(i).argValues.arg1));
				end if;
			end loop;
			
			return res;
		end function;
		
		function findNewestMatch(qs: TMP_queueState; cmpMask: std_logic_vector; ins: InstructionState)
		return std_logic_vector is
			variable res, older, before: std_logic_vector(0 to QUEUE_SIZE-1) := (others => '0');
			variable indices, rawIndices: SmallNumberArray(0 to QUEUE_SIZE-1) := (others => (others => '0'));
			variable matchBefore: std_logic := '0';
		begin
			-- From qs we must check which are older than ins
			indices := getQueueIndicesFrom(QUEUE_SIZE, qs.pStart);
			rawIndices := getQueueIndicesFrom(QUEUE_SIZE, (others => '0'));
			older := compareIndicesSmaller(indices, ins.groupTag);
			before := compareIndicesSmaller(rawIndices, ins.groupTag);
			-- Use priority enc. to find last in the older ones. But they may be divided:
			--		V  1 1 1 0 0 0 0 1 1 1 and cmp  V
			--		   0 1 0 0 0 0 0 1 0 1
			-- and then there are 2 runs of bits and those at the enc must be ignored (r older than first run)
			
			-- So, elems at the end are ignored when those conditions cooccur:
			--		pStart > ins.groupTag and [match exists that match.groupTag < ins.groupTag]
			matchBefore := isNonzero(cmpMask and before);
			
			if matchBefore = '1' then
				-- Ignore those after
				res := invertVec(getFirstOne(invertVec(cmpMask and before)));
			else
				-- Don't ignore any matches
				res := invertVec(getFirstOne(invertVec(cmpMask)));				
			end if;
			
			return res;
		end function;
		
		function chooseIns(content: InstructionStateArray; which: std_logic_vector)
		return InstructionState is
			variable res: InstructionState := DEFAULT_INSTRUCTION_STATE;
		begin
			for i in 0 to which'length-1 loop
				if which(i) = '1' then
					res := content(i);
					exit;
				end if;
			end loop;
			
			return res;
		end function;
		
begin				
	qs1 <= TMP_change(qs0, bufferDrive.nextAccepting, bufferDrive.prevSending,
							TMP_mask, TMP_killMask, lateEventSignal or execEventSignal, TMP_maskNext);
			
	inputIndices <= getQueueIndicesForInput(qs0, QUEUE_SIZE, PIPE_WIDTH);
	TMP_ckEnForInput <= getQueueEnableForInput(qs0, QUEUE_SIZE, bufferDrive.prevSending);
	-- in shifting queue this would be shfited by nSend
	TMP_sendingMask <= getQueueSendingMask(qs0, QUEUE_SIZE, bufferDrive.nextAccepting);
	TMP_killMask <= getKillMask(TMP_content, TMP_mask, execCausing, execEventSignal, lateEventSignal);
	TMP_livingMask <= TMP_mask and not TMP_killMask;			
				
	TMP_maskNext <= (TMP_livingMask and not TMP_sendingMask) or TMP_ckEnForInput;
	-- in shifting queue generated from (i < nFullNext)
	TMP_contentNext <=
				TMP_getNewContentUpdate(TMP_content, dataIn.data, TMP_ckEnForInput, inputIndices,
												TMP_maskA, TMP_maskD,
												storeAddressWr, storeValueWr, storeAddressDataIn, storeValueDataIn,
												CLEAR_COMPLETED, KEEP_INPUT_CONTENT);

	TMP_maskA <= findMatching(makeSlotArray(TMP_content, TMP_mask), storeAddressDataIn);
	TMP_maskD <= findMatching(makeSlotArray(TMP_content, TMP_mask), storeValueDataIn);

	-- View
	contentView <= normalizeInsArray(qs0, TMP_content);
	maskView <= normalizeMask(qs0, TMP_mask);
	liveMaskView <= normalizeMask(qs0, TMP_livingMask);
	contentNextView <= normalizeInsArray(qs1, TMP_contentNext);
	maskNextView <= normalizeMask(qs1, TMP_maskNext);
	------

	TMP_frontW <= getQueueFrontWindow(qs0, TMP_content, TMP_mask);
	TMP_preFrontW <= getQueuePreFrontWindow(qs0, TMP_content, TMP_mask);
	TMP_sendingData <= findCommittingSQ(TMP_frontW.data, TMP_frontW.fullMask, groupCtrInc, committing);
		
	sqOutData <= TMP_sendingData;
			
	sendingSQ <= isNonzero(sqOutData.fullMask);
	dataOutV <= sqOutData;
	contentData <= extractData(content);


		cmpMask <= compareAddress(TMP_content, compareAddressDataIn) and TMP_Mask;
		newestMatch <= findNewestMatch(qs0, cmpMask, compareAddressDataIn);
		selectedSendingSig <= isNonzero(newestMatch) and compareAddressReady;
		selectedData <= chooseIns(TMP_content, newestMatch);
	
	
	process (clk)
	begin
		if rising_edge(clk) then	
			qs0 <= qs1;
			TMP_mask <= TMP_maskNext;	
			TMP_content <= TMP_contentNext;
			
			logBuffer(contentView, maskView, liveMaskView, bufferResponse);					
			
			-- NOTE: below has no info about flow constraints. It just checks data against
			--			flow numbers, while the validity of those numbers is checked by slot logic	
			checkBuffer(contentView, maskView, contentNextView, maskNextView, bufferDrive, bufferResponse);
		end if;
	end process;
			
	SLOT_BUFF: entity work.BufferPipeLogic(BehavioralDirect)
	generic map(
		CAPACITY => QUEUE_SIZE, -- PIPE_WIDTH*2*2
		MAX_OUTPUT => PIPE_WIDTH,
		MAX_INPUT => PIPE_WIDTH
	)
	port map(
		clk => clk, reset => reset, en => en,
		flowDrive => bufferDrive,
		flowResponse => bufferResponse
	);						

	bufferDrive.prevSending <=num2flow(countOnes(dataIn.fullMask)) when prevSending = '1' else (others => '0');
	bufferDrive.kill <= num2flow(countOnes(TMP_killMask));
	bufferDrive.nextAccepting <= num2flow(countOnes(sqOutData.fullMask));
					
	acceptingOut <= not TMP_preFrontW.fullMask(0);
	
	sendingSQOut <= sendingSQ;
	
	selectedDataOut <= selectedData;
	selectedSending <= selectedSendingSig;
end Behavioral;

