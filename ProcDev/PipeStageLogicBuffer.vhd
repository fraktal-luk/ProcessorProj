----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    01:49:41 01/10/2016 
-- Design Name: 
-- Module Name:    PipeStageLogicBuffer - Behavioral 
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

use work.GeneralPipeDev.all;


entity PipeStageLogicBuffer is
	generic (
		CAPACITY: natural := 1;
		MAX_OUTPUT: natural := 1;
		MAX_INPUT: natural := 1
	);	
	
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           en : in  STD_LOGIC;
			  
					lockAccept: in std_logic;
					lockSend: in std_logic;					
			  killAll: in std_logic;
			  kill: in SmallNumber;
			  
           prevSending : in  SmallNumber;
           nextAccepting : in  SmallNumber;
			  
			  isNew: out SmallNumber;
			  
			  full: out SmallNumber;
			  living: out SmallNumber;				  
			  
           accepting : out  SmallNumber;
			  sending: out SmallNumber
		);
end PipeStageLogicBuffer;


architecture Behavioral of PipeStageLogicBuffer is
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
begin
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
		
		sending <= sendingSig;
		accepting <= acceptingSig;
		full <= fullSig;	
		living <= livingSig;	

end Behavioral;

