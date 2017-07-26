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

use work.Helpers.all;
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


architecture BehavioralDirect of BufferPipeLogic is
		constant CAP: PipeFlow := num2flow(CAPACITY);
		constant MAX_IN: PipeFlow := num2flow(MAX_INPUT);
		constant MAX_OUT: PipeFlow := num2flow(MAX_OUTPUT);

		signal isNewSig: SmallNumber := (others=>'0');
		signal fullSig: SmallNumber := (others=>'0');
		signal livingSig: SmallNumber := (others=>'0');
		
		signal canAccept: SmallNumber := (others=>'0');
		signal wantSend: SmallNumber := (others=>'0');
		signal acceptingSig: SmallNumber := (others=>'0');
		signal sendingSig: SmallNumber := (others=>'0');

		signal afterSending: SmallNumber := (others=>'0');
		signal afterReceiving, afterReceivingSig: SmallNumber := (others=>'0');
		
		--- interface signals
			signal lockAccept: std_logic;
			signal lockSend: std_logic;					
			signal killAll: std_logic;
			signal kill: SmallNumber;
			  
         signal prevSending: SmallNumber;
         signal nextAccepting: SmallNumber;
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
					fullSig <= afterReceivingSig;
						isNewSig <= prevSending;
				end if;
			end if;
		end process;
		
		afterReceivingSig <= afterReceiving;
		
			canAccept <= (others => '0') when lockAccept = '1'
					else uminSN(MAX_IN, CAP);
			acceptingSig <= uminSN(canAccept, subSN(CAP, afterSending));		

			livingSig <= (others => '0') when killAll = '1'
					else	 subSN(fullSig, kill);
			wantSend <= (others => '0') when lockSend = '1'
					else   uminSN(MAX_OUT, livingSig);
			sendingSig <= uminSN(nextAccepting, wantSend);
			afterSending <= subSN(livingSig, sendingSig);
			
			afterReceiving <= addSN(afterSending, prevSending);

end BehavioralDirect;



architecture BehavioralIQ of BufferPipeLogic is
		constant CAP: PipeFlow := num2flow(CAPACITY);
		constant MAX_IN: PipeFlow := num2flow(MAX_INPUT);
		constant MAX_OUT: PipeFlow := num2flow(MAX_OUTPUT);

		signal isNewSig: SmallNumber := (others=>'0');
		signal fullSig: SmallNumber := (others=>'0');
		signal livingSig: SmallNumber := (others=>'0');
		
		--signal canAccept: SmallNumber := (others=>'0');
		signal receivingSig: SmallNumber := (others=>'0');
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
begin
		lockAccept <= flowDrive.lockAccept;
		lockSend <= flowDrive.lockSend;
		killAll <= flowDrive.killAll;
		kill <= flowDrive.kill;
		prevSending <= flowDrive.prevSending;
		nextAccepting <= flowDrive.nextAccepting; -- will mean: IQ has ready AND next stage accepts

		flowResponse.isNew <= isNewSig;
		flowResponse.full <= fullSig;
		flowResponse.living <= livingSig;
		flowResponse.accepting <= acceptingSig;
		flowResponse.sending <= sendingSig;
			
		-- when sending and receiving: ...	
		-- when sending and not reveiving
		-- when sending and killed
		-- when not sending and {...}
		livingSig <= --num2flow(binFlowNum(fullSig) - binFlowNum(kill));
							subSN(fullSig, kill);
		sendingSig(0) <= nextAccepting(0);
		
		acceptingSig <= --num2flow(CAPACITY - binFlowNum(fullSig) + binFlowNum(sendingSig));
								addSN(subSN(num2flow(CAPACITY), fullSig), sendingSig);
		
		receivingSig <= --num2flow(-binFlowNum(kill)) 
							 subSN((others => '0'), kill)
													when isNonzero(kill) = '1' else 						
								prevSending;
								
		
		afterReceiving <= --num2flow( binFlowNum(fullSig) - binFlowNum(sendingSig)
								--				+ binFlowNum(receivingSig) );
								addSN(subSN(fullSig, sendingSig), receivingSig);				
												
									-- when receiving considers 'killed' num 
				
		CLOCKED: process(clk)
		begin
			if rising_edge(clk) then
				if reset = '1' then
					fullSig <= (others=>'0');
				elsif en = '1' then
					--assert binFlowNum(livingSig) >= binFlowNum(sendingSig) 
					--		report "Try to send more than available" severity warning;
					--assert binFlowNum(afterSending) + binFlowNum(prevSending) <= binFlowNum(CAP)
					--		report "Trying to receive too much" severity warning;					
					fullSig <= afterReceiving;
					
				end if;
			end if;
		end process;

end BehavioralIQ;
