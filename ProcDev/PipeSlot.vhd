----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:19:52 12/19/2015 
-- Design Name: 
-- Module Name:    PipeSlot - Behavioral 
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

use work.GeneralPipeDev.all;

use work.TEMP_DEV.all;
use work.CommonRouting.all;


-- DEPREC
entity PipeSlot is
	generic (
		CAPACITY: natural := 1;
		MAX_OUTPUT: natural := 1;
		MAX_INPUT: natural := 1
	);	

    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           en : in  STD_LOGIC;
			  
			  killAll: in std_logic;
			  
			  kill: in PipeFlow;
			  
           prevSending : in  PipeFlow;
           nextAccepting : in  PipeFlow;
           accepting : out  PipeFlow;
			  
			  sending: out PipeFlow;
			  sendingAlt: out PipeFlow; -- WARNIGN! shoddy trick to see hwordSendingSig in hbuff
			  
			  full: out PipeFlow;
			  living: out PipeFlow	
			  -- Some control from pipe stage content and other state info:
			  
			  -- 			  
			  );
end PipeSlot;

--
--architecture Behavioral of PipeSlot is
--		constant CAP: PipeFlow := num2flow(CAPACITY, false);
--	
--		signal fullSig: PipeFlow := (others=>'0');
--		signal livingSig: PipeFlow := (others=>'0');		
--		
--		signal canAccept: PipeFlow := (others=>'0');
--		signal wantSend: PipeFlow := (others=>'0');
--		signal acceptingSig: PipeFlow := (others=>'0');
--		signal sendingSig: PipeFlow := (others=>'0');	
--
--		signal afterSending: PipeFlow := (others=>'0');
--		signal afterReceiving: PipeFlow := (others=>'0');	
--begin
--		livingSig <= fullSig and not kill; -- TODO: fix killing mechanism!
--
--		-- TODO: fix these, cause it needs to represent bounding conditions depedent on other state
--		canAccept <= TEMP_defaultCanAccept(CAP, livingSig);
--		wantSend <= TEMP_defaultWantSend(CAP, livingSig);
--		
--		-- Determine what will be sent
--		sendingSig <= TEMP_calcSendingZero(nextAccepting, wantSend);
--		afterSending <= TEMP_stateAfterSendingDefault(livingSig, sendingSig);
--
--		-- Determine the fate of data remaining at this stage: stalls/moves
--		-- TODO (establish some internal link that can transmit instructions to other places in this stage,
--		--				logic that processes stalled instructions if they require it, etc.)
--		
--		-- Determine what will be received
--		acceptingSig <= TEMP_calcAcceptingZero(canAccept, CAP, afterSending);	
--		afterReceiving <= TEMP_stateAfterReceivingDefault(afterSending, prevSending);
--		
--		CLOCKED: process(clk)
--		begin
--			if rising_edge(clk) then
--				if reset = '1' then
--					fullSig <= (others=>'0');
--				elsif en = '1' then
--					fullSig <= afterReceiving;
--				end if;
--			end if;
--		end process;
--		
--		sending <= sendingSig;
--		accepting <= acceptingSig;
--		full <= fullSig;	
--		living <= livingSig;	
--end Behavioral;
--
--architecture Behavioral2 of PipeSlot is
--		constant CAP: PipeFlow := num2flow(CAPACITY, false);
--	
--			-- TEMP!!
--		--	constant killSig: PipeFlow := (others=>'0');
--	
--		signal fullSig: PipeFlow := (others=>'0');
--		signal livingSig: PipeFlow := (others=>'0');		
--		
--		signal canAccept: PipeFlow := (others=>'0');
--		signal wantSend: PipeFlow := (others=>'0');
--		signal acceptingSig: PipeFlow := (others=>'0');
--		signal sendingSig: PipeFlow := (others=>'0');	
--
--		signal afterSending: PipeFlow := (others=>'0');
--		signal afterReceiving: PipeFlow := (others=>'0');	
--begin
--
--		livingSig <= fullSig and not kill;
--		-- TODO: fix these, cause it needs to represent bounding conditions depedent on other state
--		canAccept <= TEMP_defaultCanAccept(CAP, livingSig);
--		wantSend <= TEMP_defaultWantSend(CAP, livingSig);
--		
--		-- Determine what will be sent
--		sendingSig <= TEMP_calcSendingByPosition(nextAccepting, wantSend);
--		afterSending <= TEMP_stateAfterSendingByPosition(livingSig, sendingSig);
--	
--		-- Determine the fate of data remaining at this stage: stalls/moves
--		-- TODO (establish some internal link that can transmit instructions to other places in this stage,
--		--				logic that processes stalled instructions if they require it, etc.)
--		
--		-- Determine what will be received
--		acceptingSig <= TEMP_calcAcceptingZero(canAccept, CAP, afterSending);	
--		afterReceiving <= TEMP_stateAfterReceivingByPosition(afterSending, prevSending);
--		
--		CLOCKED: process(clk)
--		begin
--			if rising_edge(clk) then
--				if reset = '1' then
--					fullSig <= (others=>'0');
--				elsif en = '1' then
--					fullSig <= afterReceiving;
--				end if;
--			end if;
--		end process;
--		
--		sending <= sendingSig;
--		accepting <= acceptingSig;
--		full <= fullSig;		
--end Behavioral2;
--
--
--architecture BehavioralHbuff of PipeSlot is
--		constant CAP: PipeFlow := num2flow(CAPACITY, false);
--	
--			-- TEMP!!
--		--	constant killSig: PipeFlow := (others=>'0');
--	
--		signal fullSig: PipeFlow := (others=>'0');
--		signal livingSig: PipeFlow := (others=>'0');		
--		
--		signal canAccept: PipeFlow := (others=>'0');
--		signal wantSend: PipeFlow := (others=>'0');
--		signal acceptingSig: PipeFlow := (others=>'0');
--		signal sendingSig: PipeFlow := (others=>'0');	
--
--		signal afterSending: PipeFlow := (others=>'0');
--		signal afterReceiving: PipeFlow := (others=>'0');
--
--		--signal hbd: HwordBufferData;	
--		signal hwordSendingSig: PipeFlow;
--		
--		--signal hwords: HwordArray(0 to 7) := (others=>(others=>'0'));
--		
--		--signal shortInstructions: std_logic_vector(0 to 7) := "00000000";
--		
--		--constant COMPLEX_STUFF: boolean := false;
--begin
--		livingSig <= num2flow(binFlowNum(fullSig) - binFlowNum(kill), false);
--
--		-- TODO: fix these, cause it needs to represent bounding conditions depedent on other state
--		canAccept <= TEMP_defaultCanAccept(CAP, livingSig);
--		wantSend <= TEMP_defaultWantSend(CAP, livingSig);
--			
--		--------- *Complex Specific Stuff* -------	
----		CSS_TRUE: if COMPLEX_STUFF generate
----			hbd <= wholeInstructionData(hwords, shortInstructions, 
----																binFlowNum(livingSig), binFlowNum(nextAccepting));
----			-- Determine what will be sent
----			sendingSig <= num2flow(countOnes(hbd.readyOps), false);
----																
----			hwordSendingSig <= TEMP_sendingHwordNumber(sendingSig, hbd.cumulSize);
----		end generate;	
--		----------------------------
--		
--		-- CAREFUL! Here we could write:
--		-- sendingSig <= TEMP_calcSendingDefault(nextAccepting, wantSend);
--		-- And nextAccepting would be fed by 'hwordSendingSig', so that he thing NOW called 'sendingSig'
--		-- would be outside, and given to this module through 'nextAccepting', so the *Complex Specific
--		--	Stuff* would be external to this
--		--CSS_FALSE: if not COMPLEX_STUFF generate
--			hwordSendingSig <= nextAccepting;
--			
--		--end generate;
--		
--		sendingSig <= TEMP_calcSendingBuffer(nextAccepting, wantSend);		
--		afterSending <= TEMP_stateAfterSendingBuffer(livingSig, sendingSig);
--	
--		-- Determine the fate of data remaining at this stage: stalls/moves
--		-- TODO (establish some internal link that can transmit instructions to other places in this stage,
--		--				logic that processes stalled instructions if they require it, etc.)
--		
--		-- Determine what will be received
--		acceptingSig <= TEMP_calcAcceptingBuffer(canAccept, CAP, afterSending);	
--		afterReceiving <= TEMP_stateAfterReceivingBuffer(afterSending, prevSending);
--		
--		CLOCKED: process(clk)
--		begin
--			if rising_edge(clk) then
--				if reset = '1' then
--					fullSig <= (others=>'0');
--				elsif en = '1' then
--					fullSig <= afterReceiving;
--				end if;
--			end if;
--		end process;
--		
--		sending <= sendingSig; --
--		
--			sendingAlt <= hwordSendingSig;
--		
--		accepting <= acceptingSig;
--		full <= fullSig;	
--		living <= livingSig;	
--end BehavioralHbuff;
--
----
----architecture BehavioralPC of PipeSlot is
----		constant CAP: PipeFlow := num2flow(CAPACITY, false);
----	
----		-- CAREFUL! Before reset exists, we have to initialize PC to full
----		signal fullSig: PipeFlow :=  (others=>'0');
----												--num2flow(CAPACITY, false);
----		signal livingSig: PipeFlow := (others=>'0');		
----				
----		signal canAccept: PipeFlow := (others=>'0');
----		signal wantSend: PipeFlow := (others=>'0');
----		signal acceptingSig: PipeFlow := (others=>'0');
----		signal sendingSig: PipeFlow := (others=>'0');	
----
----		signal afterSending: PipeFlow := (others=>'0');
----		signal afterReceiving: PipeFlow := (others=>'0');	
----begin
----		livingSig <= fullSig and not kill;
----
----		-- TODO: fix these, cause it needs to represent bounding conditions depedent on other state
----		canAccept <= TEMP_defaultCanAccept(CAP, livingSig);
----		wantSend <= TEMP_defaultWantSend(CAP, livingSig);
----		
----		-- Determine what will be sent
----		sendingSig <= TEMP_calcSendingZero(nextAccepting, wantSend);
----		afterSending <= TEMP_stateAfterSendingDefault(livingSig, sendingSig);
----
----		-- Determine the fate of data remaining at this stage: stalls/moves
----		-- TODO (establish some internal link that can transmit instructions to other places in this stage,
----		--				logic that processes stalled instructions if they require it, etc.)
----		
----		-- Determine what will be received
----		acceptingSig <= TEMP_calcAcceptingZero(canAccept, CAP, afterSending);	
----		afterReceiving <= TEMP_stateAfterReceivingDefault(afterSending, prevSending);
----		
----		CLOCKED: process(clk)
----		begin
----			if rising_edge(clk) then
----				if reset = '1' then
----					fullSig <= (others=>'0');
----				elsif en = '1' then
----					fullSig <= afterReceiving;
----				end if;
----			end if;
----		end process;
----		
----		sending <= sendingSig;
----		accepting <= acceptingSig;
----		full <= fullSig;
----		living <= livingSig;	
----end BehavioralPC;
----
--
--
--architecture BehavioralIQ of PipeSlot is
--		constant CAP: PipeFlow := num2flow(CAPACITY, false);
--	
--		signal fullSig: PipeFlow := (others=>'0');
--		signal livingSig: PipeFlow := (others=>'0');		
--		
--		signal canAccept: PipeFlow := (others=>'0');
--		signal wantSend: PipeFlow := (others=>'0');
--		signal acceptingSig: PipeFlow := (others=>'0');
--		signal sendingSig: PipeFlow := (others=>'0');	
--
--		signal afterSending: PipeFlow := (others=>'0');
--		signal afterReceiving: PipeFlow := (others=>'0');	
--begin
--		livingSig <= num2flow(binFlowNum(fullSig) - binFlowNum(kill), false);
--
--		-- TODO: include here logic that takes accepting signals from exec units and info
--		--			about ops ready to issue. It'd generate 'sending' signal 
--		--	sendingA <= ... -- [where is the first ready ins for unit A, but all zeros if A not accepting] 
--		-- sendingB <= ... -- [likewise]
--		--	sendingConfirmed <= sendingA or sendingB;	-- !! needed for shift table to align content
--		-- sendingSig <= num2flow(countOnes(sendingConfirmed), false); -- or just add binary 'anySending' flags  
--		--		-- ?? Can we implement this outside? Here would be just numbers: number of sent ops
--		--		--		would be given in 'nextAccepting', and 'wantSend' = CAPACITY would cause it to
--		--		--		be just copied to 'sendingSig'	
--
--		canAccept <= num2flow(PIPE_WIDTH, false); -- TEMP_defaultCanAccept(CAPACITY, fullSig);
--		-- CAREFUL, TODO: wantSend shoulddepend on existence of ready instructions - 1 per relevant ExecUnit
--		wantSend <= num2flow(2, false); -- TEMP_defaultWantSend(CAPACITY, fullSig);
--		
--		-- Determine what will be sent
--		sendingSig <= TEMP_calcSendingBuffer(nextAccepting, wantSend);
--		afterSending <= TEMP_stateAfterSendingDefault(livingSig, sendingSig);
--		
--		-- Determine what will be received
--		acceptingSig <= TEMP_calcAcceptingBuffer(canAccept, CAP, afterSending);	
--		afterReceiving <= TEMP_stateAfterReceivingDefault(afterSending, prevSending);
--		
--		CLOCKED: process(clk)
--		begin
--			if rising_edge(clk) then
--				if reset = '1' then
--					fullSig <= (others=>'0');
--				elsif en = '1' then
--					fullSig <= afterReceiving;
--				end if;
--			end if;
--		end process;
--		
--		sending <= sendingSig;
--		accepting <= acceptingSig;
--		full <= fullSig;	
--		living <= livingSig;	
--end BehavioralIQ;
--
--
--architecture BehavioralCQ of PipeSlot is
--		constant CAP: PipeFlow := num2flow(CAPACITY, false);
--	
--		signal fullSig: PipeFlow := (others=>'0');
--		signal livingSig: PipeFlow := (others=>'0');		
--		
--		signal canAccept: PipeFlow := (others=>'0');
--		signal wantSend: PipeFlow := (others=>'0');
--		signal acceptingSig: PipeFlow := (others=>'0');
--		signal sendingSig: PipeFlow := (others=>'0');	
--
--		signal afterSending: PipeFlow := (others=>'0');
--		signal afterReceiving: PipeFlow := (others=>'0');	
--begin
--		livingSig <= 
--				num2flow(binFlowNum(fullSig) - binFlowNum(kill), false) when killAll = '0'
--		else	(others => '0');
--
--		--canAccept <= num2flow(PIPE_WIDTH, false); -- TEMP_defaultCanAccept(CAPACITY, fullSig);
--		--wantSend <= num2flow(PIPE_WIDTH, false); -- TEMP_defaultWantSend(CAPACITY, fullSig);
--		
--				canAccept <= TEMP_defaultCanAccept(num2flow(MAX_INPUT, false), livingSig);
--				wantSend <= TEMP_defaultWantSend(num2flow(MAX_OUTPUT, false), livingSig);		
--		
--		-- Determine what will be sent
--		sendingSig <= TEMP_calcSendingBuffer(nextAccepting, wantSend);
--		afterSending <= TEMP_stateAfterSendingDefault(livingSig, sendingSig);
--		
--		-- Determine what will be received
--		acceptingSig <= TEMP_calcAcceptingBuffer(canAccept, CAP, afterSending);	
--		afterReceiving <= TEMP_stateAfterReceivingDefault(afterSending, prevSending);
--		
--		CLOCKED: process(clk)
--		begin
--			if rising_edge(clk) then
--				if reset = '1' then
--					fullSig <= (others=>'0');
--				elsif en = '1' then
--					fullSig <= afterReceiving;
--				end if;
--			end if;
--		end process;
--		
--		sending <= sendingSig;
--		accepting <= acceptingSig;
--		full <= fullSig;	
--		living <= livingSig;	
--end BehavioralCQ;



architecture BehavioralBuffer of PipeSlot is
		constant CAP: PipeFlow := num2flow(CAPACITY, false);
	
		signal fullSig: PipeFlow := (others=>'0');
		signal livingSig: PipeFlow := (others=>'0');		
		
		signal canAccept: PipeFlow := (others=>'0');
		signal wantSend: PipeFlow := (others=>'0');
		signal acceptingSig: PipeFlow := (others=>'0');
		signal sendingSig: PipeFlow := (others=>'0');	

		signal afterSending: PipeFlow := (others=>'0');
		signal afterReceiving: PipeFlow := (others=>'0');	
begin
		livingSig <= 
				num2flow(binFlowNum(fullSig) - binFlowNum(kill), false) when killAll = '0'
		else	(others => '0');	

		canAccept <= TEMP_defaultCanAccept(num2flow(MAX_INPUT, false), livingSig);
		wantSend <= TEMP_defaultWantSend(num2flow(MAX_OUTPUT, false), livingSig);
		
		-- Determine what will be sent
		sendingSig <= TEMP_calcSendingBuffer(nextAccepting, wantSend);
		afterSending <= --TEMP_stateAfterSendingDefault(livingSig, sendingSig);
							TEMP_stateAfterSendingBuffer(livingSig, sendingSig);
		
		-- Determine what will be received
		acceptingSig <= TEMP_calcAcceptingBuffer(canAccept, CAP, afterSending);	
		afterReceiving <= --TEMP_stateAfterReceivingDefault(afterSending, prevSending);
								TEMP_stateAfterReceivingBuffer(afterSending, prevSending);		
		
		CLOCKED: process(clk)
		begin
			if rising_edge(clk) then
				if reset = '1' then
					fullSig <= (others=>'0');
				elsif en = '1' then
					fullSig <= afterReceiving;
				end if;
			end if;
		end process;
		
		sending <= sendingSig;
		accepting <= acceptingSig;
		full <= fullSig;	
		living <= livingSig;	
end BehavioralBuffer;


architecture BehavioralBuffer2 of PipeSlot is
		constant CAP: PipeFlow := num2flow(CAPACITY, false);
		constant MAX_IN: PipeFlow := num2flow(MAX_INPUT, false);
		constant MAX_OUT: PipeFlow := num2flow(MAX_OUTPUT, false);

	
		signal fullSig: PipeFlow := (others=>'0');
		signal livingSig: PipeFlow := (others=>'0');		
		
		signal canAccept: PipeFlow := (others=>'0');
		signal wantSend: PipeFlow := (others=>'0');
		signal acceptingSig: PipeFlow := (others=>'0');
		signal sendingSig: PipeFlow := (others=>'0');	

		signal afterSending: PipeFlow := (others=>'0');
		signal afterReceiving: PipeFlow := (others=>'0');	
begin
--		livingSig <= num2flow(binFlowNum(fullSig) - binFlowNum(kill), false);	
--
--		canAccept <= TEMP_defaultCanAccept(num2flow(MAX_INPUT, false), livingSig);
--		wantSend <= TEMP_defaultWantSend(num2flow(MAX_OUTPUT, false), livingSig);
--		
--		-- Determine what will be sent
--		sendingSig <= TEMP_calcSendingBuffer(nextAccepting, wantSend);
--		afterSending <= TEMP_stateAfterSendingDefault(livingSig, sendingSig);
--		
--		-- Determine what will be received
--		acceptingSig <= TEMP_calcAcceptingBuffer(canAccept, CAP, afterSending);	
--		afterReceiving <= TEMP_stateAfterReceivingDefault(afterSending, prevSending);
--		
		CLOCKED: process(clk)
		begin
			if rising_edge(clk) then
				if reset = '1' then
					fullSig <= (others=>'0');
				elsif en = '1' then
					fullSig <= afterReceiving;
				end if;
			end if;
		end process;
		
		IMPLEM: entity work.BufferCounter port map(
			capacity => CAP,
			maxInput => MAX_IN,
			maxOutput => MAX_OUT,
			
			full => fullSig,
			killAll => killAll,
			kill => kill,
			living => livingSig,
			nextAccepting => nextAccepting,
			prevSending => prevSending,
			wantSend => wantSend,
			canAccept => canAccept,
			sending => sendingSig,
			accepting => acceptingSig,
			afterSending => afterSending,
			afterReceiving => afterReceiving
			
		);
		
		sending <= sendingSig;
		accepting <= acceptingSig;
		full <= fullSig;	
		living <= livingSig;	
end BehavioralBuffer2;



--architecture WrappedSimple of PipeSlot is
--begin
--	IMPLEM: entity work.PipeStageLogicSimple port map(
--			  clk => clk,
--           reset => reset,
--           en => en,
--			  
--			  kill => kill(PipeFlow'right),
--			  
--           prevSending => prevSending(PipeFlow'right), --: in  std_logic;
--           nextAccepting => nextAccepting(PipeFlow'right), --: in  std_logic;
--           accepting => accepting(PipeFlow'right), --: out  std_logic;
--			  
--			  sending => sending(PipeFlow'right), --;
--			  
--			  full => full(PipeFlow'right),
--			  living => living(PipeFlow'right)			
--	);
--	
--end WrappedSimple;

