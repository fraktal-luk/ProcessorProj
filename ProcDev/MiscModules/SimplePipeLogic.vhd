----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:27:46 01/04/2016 
-- Design Name: 
-- Module Name:    SimplePipeLogic - Behavioral 
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

use work.NewPipelineData.all;
use work.BasicFlow.all;
use work.GeneralPipeDev.all;

--use work.TEMP_DEV.all;
--use work.CommonRouting.all;


entity SimplePipeLogic is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           en : in  STD_LOGIC;
				flowDrive: in FlowDriveSimple;
				flowResponse: out FlowResponseSimple			  
			  );
end SimplePipeLogic;

--
--architecture Behavioral_OLD of SimplePipeLogic is
--
--begin
--	IMPLEM: entity work.PipeStageLogicSimple(Behavioral) port map(
--		clk => clk, reset => reset, en => en,
--			lockAccept => flowDrive.lockAccept,
--			lockSend => flowDrive.lockSend,		
--		kill => flowDrive.kill,
--		prevSending => flowDrive.prevSending,
--		nextAccepting => flowDrive.nextAccepting,
--		
--		isNew => flowResponse.isNew,
--		full => flowResponse.full,
--		living => flowResponse.living,
--		accepting => flowResponse.accepting,
--		sending => flowResponse.sending
--	);
--	
--end Behavioral_OLD;


architecture Behavioral of SimplePipeLogic is
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
		livingSig <= fullSig and not flowDrive.kill; -- CHECK: killing mechanism correct?

		canAccept <= not flowDrive.lockAccept;
		wantSend <= livingSig and not flowDrive.lockSend;
		
		-- Determine what will be sent
		sendingSig <= flowDrive.nextAccepting and wantSend;
		afterSending <= livingSig and not sendingSig;

		-- Determine what will be received
		acceptingSig <= canAccept and not afterSending;	
		afterReceiving <= afterSending or flowDrive.prevSending;
				
		CLOCKED: process(clk)
		begin
			if rising_edge(clk) then
				if reset = '1' then
					fullSig <= '0';
					isNewSig <= '0';
				elsif en = '1' then
					assert (livingSig or not sendingSig) = '1' 
							report "Try to send from empty?" severity warning;
					assert (afterSending and flowDrive.prevSending) = '0' 
							report "Trying to receive into full slot" severity warning;
					fullSig <= afterReceiving;
					isNewSig <= flowDrive.prevSending;					
				end if;
			end if;
		end process;
		
		flowResponse.sending <= sendingSig;
		flowResponse.accepting <= acceptingSig;
		flowResponse.full <= fullSig;	
		flowResponse.living <= livingSig;	
		flowResponse.isNew <= isNewSig;
		
		-- @clk ContentState = f(ContentState, FlowDrive);
		--	FlowResponse <= g(ContentState, FlowDrive)
	
		-- ContentState {
		-- isFull
		-- isNew
		--}
	
end Behavioral;
