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

use work.CommonRouting.all;
use work.TEMP_DEV.all;

use work.ProcComponents.all;

use work.ProcLogicFront.all;


entity SubunitDecode is
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
		
		prevSending: in std_logic;
		nextAccepting: in std_logic;
		--frontEvents: in FrontEventInfo;
			killIn: in std_logic;		
		stageDataIn: in StageDataMulti;		
		acceptingOut: out std_logic;
		sendingOut: out std_logic;
		stageDataOut: out StageDataMulti;
		stageEventsOut: out StageMultiEventInfo
	);
end SubunitDecode;

architecture Behavioral of SubunitDecode is
	signal stageData0, stageData0Living, stageData0Next, stageData0New:
														StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

	signal newDecoded, newDecodedWithTargets: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;

	signal flowDrive0: FlowDriveSimple := (others=>'0');	
	signal flowResponse0: FlowResponseSimple := (others=>'0');	
	
	signal stageEvents: StageMultiEventInfo;
	signal partialKillMask0: std_logic_vector(0 to PIPE_WIDTH-1) := (others=>'0');	

	signal targets: MwordArray(0 to PIPE_WIDTH-1) := (others => (others => '0'));	

	constant EARLY_TARGET_ENABLE: boolean := false;	
begin	

	newDecoded <= decodeMulti(stageDataIn);
	
	newDecodedWithTargets.fullMask <= newDecoded.fullMask;
	
	CALC_TARGETS: for i in 0 to PIPE_WIDTH-1 generate
		signal aai0, aai1, aai2: Mword := (others => '0');
	begin	
		aai0 <= newDecoded.data(i).basicInfo.ip;
		aai1 <= newDecoded.data(i).constantArgs.imm;
		
		TARGET_ADDER: entity work.VerilogALU32 port map(
			clk => '0', reset => '0', en => '0', allow => '0',
			funcSelect => "000001", -- addition
			dataIn0 => aai0,
			dataIn1 => aai1,
			dataIn2 => aai2, -- Ignored
			c0 => "00000", c1 => "00000", 
			dataOut0 => open, carryOut => open, exceptionOut => open, 
			dataOut0Pre => targets(i), carryOutPre => open, exceptionOutPre => open
		);
			
		newDecodedWithTargets.data(i) <= setInstructionTarget(newDecoded.data(i), targets(i));
																								--targets(i) xor targets(i));
	end generate;
	
	stageData0New <= newDecodedWithTargets when EARLY_TARGET_ENABLE
					else newDecoded;
	stageData0Next <= stageMultiNext(stageData0Living, stageData0New,		
								flowResponse0.living, flowResponse0.sending, flowDrive0.prevSending);				
	stageData0Living <= stageMultiHandleKill(stageData0, flowDrive0.kill, partialKillMask0);
	
	FRONT_CLOCKED: process(clk)
	begin					
		if rising_edge(clk) then
			if reset = '1' then
				
			elsif en = '1' then
				stageData0 <= stageData0Next;
			end if;					
		end if;
	end process;

	SIMPLE_SLOT_LOGIC_0: SimplePipeLogic port map(
		clk => clk, reset => reset, en => en,
		flowDrive => flowDrive0,
		flowResponse => flowResponse0
	);		

	-- Local event detection
	stageEvents <= stageMultiEvents(stageData0, flowResponse0.isNew);								
	partialKillMask0 <= stageEvents.partialKillMask;

	flowDrive0.kill <= killIn; --frontEvents.affectedVec(4);

	flowDrive0.prevSending <= prevSending;
	flowDrive0.nextAccepting <= nextAccepting;

	stageDataOut <= clearTempControlInfoMulti(stageData0Living);
	acceptingOut <= flowResponse0.accepting;
	sendingOut <= flowResponse0.sending;	
	stageEventsOut <= stageEvents;
end Behavioral;

