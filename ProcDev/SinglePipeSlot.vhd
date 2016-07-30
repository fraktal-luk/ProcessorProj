----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:13:10 12/09/2015 
-- Design Name: 
-- Module Name:    SinglePipeSlot - Behavioral 
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
use work.ProcInstructionsNew.all;

use work.NewPipelineData.all;

use work.GeneralPipeDev.all;

entity SinglePipeSlot is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           en : in  STD_LOGIC;
			  
			  kill : in  STD_LOGIC;
           prevAuxState : in  SingleStageAuxState := (others=>(others=>'0'));
           nextAuxState : in  SingleStageAuxState := (others=>(others=>'0'));
           prevData : in  SingleStageData;
			  
           auxStateOut : out  SingleStageAuxState;
           dataOut : out  SingleStageData
           );
end SinglePipeSlot;

architecture Behavioral of SinglePipeSlot is
	signal state: SingleStageState := (others=>(others=>'0'));
	signal statePrev, stateNext: SingleStageState; -- NOTE: Should be irrelevenat!
	
	signal stateAux: SingleStageAuxState := (others=>(others=>'0'));
	signal data: SingleStageData := (others=>defaultInstructionState);
	
	signal newData: SingleStageData;
	
	function getAuxState(state: SingleStageState; data: SingleStageData;
								prevAuxState: SingleStageAuxState; nextAuxState: SinglestageAuxState;
								kill: std_logic) return SingleStageAuxState
	is
		variable stateAuxVar, prevAuxStateVar, nextAuxStateVar: SingleStageAuxState;
		variable statePrevVar, stateNextVar: SingleStageState; -- NOTE: Should be irrelevenat! 	
	begin
				stateAuxVar := (others=>(others=>'0'));-- stateAux;
				prevAuxStateVar := prevAuxState;
				nextAuxStateVar := nextAuxState;
				
				-- Apply kill signal
				if kill = '1' then
					stateAuxVar(0).killed := '1';
					stateAuxVar(0).living := '0';
				else
					stateAuxVar(0).killed := '0';
					stateAuxVar(0).living := state(0).full;				
				end if;			
					
				-- Set flow declarations
				DUMMY_setFlowDeclarationsDefault(stateAuxVar);
				
				-- Propagate state
				propagateState(state, statePrevVar, stateNextVar, 
									stateAuxVar, prevAuxStateVar, nextAuxStateVar);
									
				-- Determine action
				determineAction(state(0), stateAuxVar(0));
		
		
		return stateAuxVar;
	end function; 
	
begin
	
	newData <= prevData; -- TEMP!
	
	stateAux <= getAuxState(state, data, prevAuxState, nextAuxState, kill);
	
	SYNCHRONOUS:
	process (clk)
		variable stateAuxVar, prevAuxStateVar, nextAuxStateVar: SingleStageAuxState;
		
		variable stateVar: SingleStageState;
	begin
		if rising_edge(clk) then
			if en = '1' then
--				stateAuxVar := stateAux;
--				prevAuxStateVar := prevAuxState;
--				nextAuxStateVar := nextAuxState;
--				
--				-- Apply kill signal
--				if kill = '1' then
--					stateAuxVar(0).killed := '1';
--					stateAuxVar(0).living := '0';
--				else
--					stateAuxVar(0).killed := '0';
--					stateAuxVar(0).living := state(0).full;				
--				end if;			
--					
--				-- Set flow declarations
--				DUMMY_setFlowDeclarationsDefault(stateAuxVar);
--				
--				-- Propagate state
--				propagateState(state, statePrev, stateNext, 
--									stateAuxVar, prevAuxStateVar, nextAuxStateVar);
--									
--				-- Determine action
--				determineAction(state(0), stateAuxVar(0));

				stateVar := state;
				-- Set 'full' bit
				if stateAux(0).tf = '1' then
					stateVar(0).full := '1';
				elsif stateAux(0).te = '1' then
					stateVar(0).full := '0';
				end if;
							
				-- Apply action	
				if stateAux(0).tf = '1' then
					data(0) <= newData(0);
				elsif stateAux(0).te = '1' then
					data(0) <= defaultInstructionState;
				else -- stall
					--data(0).controlInfo.unseen <= '0';
				end if;
				
				state <= stateVar;
--				stateAux <= stateAuxVar;
			end if; -- en	
		end if;
	end process;
	
	dataOut <= data;
	auxStateOut <= stateAux;
	
end Behavioral;

