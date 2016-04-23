----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    01:55:58 01/10/2016 
-- Design Name: 
-- Module Name:    BufferPipeLogic - Behavioral 
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

--use work.GeneralPipeDev.all;

use work.NewPipelineData.all;

entity BufferPipeLogic is
	generic (
		CAPACITY: natural := 1;
		MAX_OUTPUT: natural := 1;
		MAX_INPUT: natural := 1
	);	
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           en : in  STD_LOGIC;
				flowDrive: in FlowDriveBuffer;
				flowResponse: out FlowResponseBuffer			  
			  );	
end BufferPipeLogic;



architecture Behavioral of BufferPipeLogic is

begin
	IMPLEM: entity work.PipeStageLogicBuffer(Behavioral) generic map(
		CAPACITY => CAPACITY,
		MAX_OUTPUT => MAX_OUTPUT,
		MAX_INPUT => MAX_INPUT
	)
	port map(
		clk => clk, reset => reset, en => en,
			lockAccept => flowDrive.lockAccept,
			lockSend => flowDrive.lockSend,
		killAll => flowDrive.killAll,
		kill => flowDrive.kill,
		prevSending => flowDrive.prevSending,
		nextAccepting => flowDrive.nextAccepting,
		
		isNew => flowResponse.isNew,
		full => flowResponse.full,
		living => flowResponse.living,
		accepting => flowResponse.accepting,
		sending => flowResponse.sending
	);

end Behavioral;

architecture BehavioralDirect of BufferPipeLogic is
		constant CAP: PipeFlow := num2flow(CAPACITY, false);
		constant MAX_IN: PipeFlow := num2flow(MAX_INPUT, false);
		constant MAX_OUT: PipeFlow := num2flow(MAX_OUTPUT, false);

		signal isNewSig: SmallNumber := (others=>'0');
		signal fullSig: SmallNumber := (others=>'0');
		signal livingSig: SmallNumber := (others=>'0');
		
		signal canAccept: SmallNumber := (others=>'0');
		signal wantSend: SmallNumber := (others=>'0');
		signal acceptingSig: SmallNumber := (others=>'0');
		signal sendingSig: SmallNumber := (others=>'0');

		signal afterSending: SmallNumber := (others=>'0');
		signal afterReceiving: SmallNumber := (others=>'0');
		
		--- interface signals
			signal lockAccept: std_logic;
			signal lockSend: std_logic;					
			signal killAll: std_logic;
			signal kill: SmallNumber;
			  
         signal prevSending: SmallNumber;
         signal nextAccepting: SmallNumber;
--			  
--			signal isNew: SmallNumber;
--			  
--			signal full: SmallNumber;
--			signal living: SmallNumber;				  
--			  
--         signal accepting: SmallNumber;
--			signal sending: SmallNumber;
begin
		lockAccept <= flowDrive.lockAccept;
		lockSend <= flowDrive.lockSend;
		killAll <= flowDrive.killAll;
		kill <= flowDrive.kill;
		prevSending <= flowDrive.prevSending;
		nextAccepting <= flowDrive.nextAccepting;

		flowResponse.isNew <= isNewSig;
		flowResponse.full <= fullSig;
		flowResponse.living <= livingSig;
		flowResponse.accepting <= acceptingSig;
		flowResponse.sending <= sendingSig;
			
		CLOCKED: process(clk)
		begin
			if rising_edge(clk) then
				if reset = '1' then
					fullSig <= (others=>'0');
				elsif en = '1' then
					assert binFlowNum(livingSig) >= binFlowNum(sendingSig) 
							report "Try to send more than available" severity warning;
					assert binFlowNum(afterSending) + binFlowNum(prevSending) <= binFlowNum(CAP)
							report "Trying to receive too much" severity warning;					
					fullSig <= afterReceiving;
					
				end if;
			end if;
		end process;
		
		IMPLEM: entity work.BufferCounter port map(
			capacity => CAP,
			maxInput => MAX_IN,
			maxOutput => MAX_OUT,
			
			full => fullSig,
				lockAccept => lockAccept,
				lockSend => lockSend,
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

end BehavioralDirect;



architecture BehavioralIQ of BufferPipeLogic is

begin
	IMPLEM: entity work.PipeStageLogicBuffer(BehavioralIQ) generic map(
		CAPACITY => CAPACITY,
		MAX_OUTPUT => MAX_OUTPUT,
		MAX_INPUT => MAX_INPUT
	)
	port map(
		clk => clk, reset => reset, en => en,
			lockAccept => flowDrive.lockAccept,
			lockSend => flowDrive.lockSend,
		killAll => flowDrive.killAll,
		kill => flowDrive.kill,
		prevSending => flowDrive.prevSending,
		nextAccepting => flowDrive.nextAccepting,
		
		isNew => flowResponse.isNew,
		full => flowResponse.full,
		living => flowResponse.living,
		accepting => flowResponse.accepting,
		sending => flowResponse.sending
	);

end BehavioralIQ;
