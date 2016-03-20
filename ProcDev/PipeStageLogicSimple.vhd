----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    02:09:54 12/29/2015 
-- Design Name: 
-- Module Name:    PipeStageLogicSimple - Behavioral 
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

--use work.TEMP_DEV.all;
--use work.CommonRouting.all;


entity PipeStageLogicSimple is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           en : in  STD_LOGIC;
			  
					lockAccept: in std_logic;
					lockSend: in std_logic;				  
			  kill: in std_logic;
			  
           prevSending : in  std_logic;
           nextAccepting : in  std_logic;
			  
			  isNew: out std_logic;
			  
			  full: out std_logic;
			  living: out std_logic;				  
			  
           accepting : out  std_logic;
			  sending: out std_logic
			  
			  -- Some control from pipe stage content and other state info:
			  
			  
			  -- 			  
			  );
end PipeStageLogicSimple;


architecture Behavioral of PipeStageLogicSimple is
		signal isNewSig: std_logic := '0';
		signal fullSig: std_logic := '0';
		signal livingSig: std_logic := '0';		
		
		signal canAccept: std_logic := '0';
		signal wantSend: std_logic := '0';
		signal acceptingSig: std_logic := '0';
		signal sendingSig: std_logic := '0';	

		signal afterSending: std_logic := '0';
		signal afterReceiving: std_logic := '0';	
begin
		livingSig <= fullSig and not kill; -- TODO: fix killing mechanism!

		canAccept <= not lockAccept; -- TEMP_defaultCanAcceptSimple(livingSig);
		wantSend <= livingSig and not lockSend; -- TEMP_defaultWantSendSimple(livingSig);
		
		-- Determine what will be sent
		sendingSig <= TEMP_calcSendingSimple(nextAccepting, wantSend);
		afterSending <= TEMP_stateAfterSendingSimple(livingSig, sendingSig);

		-- Determine what will be received
		acceptingSig <= TEMP_calcAcceptingSimple(canAccept, afterSending);	
		afterReceiving <= TEMP_stateAfterReceivingSimple(afterSending, prevSending);
				
		CLOCKED: process(clk)
		begin
			if rising_edge(clk) then
				if reset = '1' then
					fullSig <= '0';
					isNewSig <= '0';
				elsif en = '1' then
					assert (livingSig or not sendingSig) = '1' 
							report "Try to send from empty?" severity warning;
					assert (afterSending and prevSending) = '0' 
							report "Trying to receive into full slot" severity warning;
					fullSig <= afterReceiving;
					isNewSig <= prevSending;					
				end if;
			end if;
		end process;
		
		sending <= sendingSig;
		accepting <= acceptingSig;
		full <= fullSig;	
		living <= livingSig;	
		isNew <= isNewSig;
end Behavioral;


