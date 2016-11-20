----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:22:58 04/24/2016 
-- Design Name: 
-- Module Name:    SubunitDecode - Behavioral 
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

--use work.CommonRouting.all;
use work.TEMP_DEV.all;

use work.ProcComponents.all;

use work.ProcLogicRenaming.all;


entity SubunitRename is
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
		
		prevSending: in std_logic;
		nextAccepting: in std_logic;


		stageDataIn: in StageDataMulti;		
		acceptingOut: out std_logic;
		sendingOut: out std_logic;
		stageDataOut: out StageDataMulti;
		
		execEventSignal: in std_logic; -- TODO: unify with system used for killing in front stages?
		execCausing: in InstructionState;
		lockCommand: in std_logic;		
		
		newPhysSources: in PhysNameArray(0 to 3*PIPE_WIDTH-1);
		newPhysDests: in PhysNameArray(0 to PIPE_WIDTH-1);
		newGprTags: in SmallNumberArray(0 to PIPE_WIDTH-1);
		newNumberTags: in SmallNumberArray(0 to PIPE_WIDTH-1);
		
		newGroupTag: in SmallNumber
	);
end SubunitRename;


architecture Behavioral of SubunitRename is
	signal flowDrive1: FlowDriveSimple := (others=>'0');
	signal flowResponse1: FlowResponseSimple := (others=>'0');		
	signal stageData1, stageData1Living, stageData1Next, stageData1New:
														StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
															
	signal reserveSelSig, takeVec: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0' );															
	signal partialKillMask1: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');														
begin
	reserveSelSig <= getDestMask(stageDataIn);
	takeVec <= 		(others => '1') when ALLOC_REGS_ALWAYS
				else stageDataIn.fullMask;

	stageData1New <= 	
--							baptizeGroup(
--								renameRegs(baptizeVec(stageDataIn, newNumberTags),
--												takeVec, reserveSelSig, 											
--												newPhysSources, newPhysDests, newGprTags),
--								newGroupTag
--							);
							stageDataIn;	
								
										
	stageData1Next <= stageMultiNext(stageData1Living, stageData1New,
								flowResponse1.living, flowResponse1.sending, flowDrive1.prevSending);			
	stageData1Living <= stageMultiHandleKill(stageData1, flowDrive1.kill, partialKillMask1);

	PIPE_CLOCKED: process(clk) 	
	begin
		if rising_edge(clk) then
			if reset = '1' then			
			elsif en = '1' then	
				stageData1 <= stageData1Next;										
			end if;
		end if;
	end process;

	SIMPLE_SLOT_LOGIC_1: SimplePipeLogic port map(
		clk => clk, reset => reset, en => en,
		flowDrive => flowDrive1,
		flowResponse => flowResponse1
	);
	
	flowDrive1.prevSending <= prevSending;
	flowDrive1.nextAccepting <= nextAccepting;
	-- CAREFUL! Is it correct?
	flowDrive1.kill <= execEventSignal; -- Only later stages can kill Rename
	flowDrive1.lockAccept <= lockCommand;

	acceptingOut <= flowResponse1.accepting;		
	sendingOut <= flowResponse1.sending;
	stageDataOut <= stageData1Living;

end Behavioral;

