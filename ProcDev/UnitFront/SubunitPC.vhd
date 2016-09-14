----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:22:53 04/24/2016 
-- Design Name: 
-- Module Name:    SubunitPC - Behavioral 
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


entity SubunitPC is
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
		

		lastCommittedNextIn: in InstructionState;
		committingIn: in std_logic;
				
		acceptingOut: out std_logic;
		
		nextAccepting: in std_logic;		
		sendingOut: out std_logic;
		stageDataOut: out StageDataPC;

			sysRegReadSel: in slv5;
			sysRegReadValue: out Mword;		
		
			sysRegWriteAllow: in std_logic;
			sysRegWriteSel: in slv5;
			sysRegWriteValue: in Mword;

		frontEvents: in FrontEventInfo		
	);
end SubunitPC;


architecture Behavioral of SubunitPC is
	signal dataPC, dataPCNext, dataPCNew: StageDataPC := INITIAL_DATA_PC;
	
	signal flowDrivePC: FlowDriveSimple := (others=>'0');
	signal flowResponsePC: FlowResponseSimple := (others=>'0');
	
		signal targetInfo: InstructionBasicInfo := defaultBasicInfo;
		signal targetPC: Mword := INITIAL_DATA_PC.pc; --(others => '0');
	
	signal pcNext: Mword := (others => '0');
	signal pcBase: Mword := (others => '0'); 
	constant pcInc: Mword := (ALIGN_BITS => '1', others => '0');
	
	signal causingNext: Mword := (others => '0');
	signal causingPC: Mword := (others => '0');
	signal causingInc: Mword := (others => '0');

	signal committingNext: Mword := (others => '0');
	signal committingPC: Mword := (others => '0');
	signal committingInc: Mword := (others => '0');
	
		signal sysRegArray: MwordArray(0 to 31) := (others => (others => '0'));	
	
	alias linkRegExc is sysRegArray(2);
	alias linkRegInt is sysRegArray(3);
	
	alias savedStateExc is sysRegArray(4);
	alias savedStateInt is sysRegArray(5);	
	
	alias currentState is sysRegArray(1);
			signal qqq: std_logic := '0'; -- TEMP, testing
begin
	committingPC <= lastCommittedNextIn.basicInfo.ip;
	committingInc <= getAddressIncrement(lastCommittedNextIn);
	
	causingPC <= frontEvents.causing.basicInfo.ip;
	causingInc <= getAddressIncrement(frontEvents.causing);
	
		EXC_ADDER: entity work.VerilogALU32 port map(
			clk => '0', reset => '0', en => '0', allow => '0',
			funcSelect => "000001", -- addition
			dataIn0 => committingPC,
			dataIn1 => committingInc,
			dataIn2 => committingInc, -- Ignored
			c0 => "00000", c1 => "00000", 
			dataOut0 => open, carryOut => open, exceptionOut => open, 
			dataOut0Pre => committingNext, carryOutPre => open, exceptionOutPre => open
		);	
	
		TARGET_ADDER: entity work.VerilogALU32 port map(
			clk => '0', reset => '0', en => '0', allow => '0',
			funcSelect => "000001", -- addition
			dataIn0 => causingPC,
			dataIn1 => causingInc,
			dataIn2 => causingInc, -- Ignored
			c0 => "00000", c1 => "00000", 
			dataOut0 => open, carryOut => open, exceptionOut => open, 
			dataOut0Pre => causingNext, carryOutPre => open, exceptionOutPre => open
		);
		
		pcBase <= dataPC.pcBase;
		INC_ADDER: entity work.VerilogALU32 port map(
			clk => '0', reset => '0', en => '0', allow => '0',
			funcSelect => "000001", -- addition
			dataIn0 => pcBase,
			dataIn1 => pcInc,
			dataIn2 => pcInc, -- Ignored
			c0 => "00000", c1 => "00000", 
			dataOut0 => open, carryOut => open, exceptionOut => open, 
			dataOut0Pre => pcNext, carryOutPre => open, exceptionOutPre => open
		);
		
	dataPCNew <= newPCData(dataPC, frontEvents, pcNext, causingNext);--, linkInfoExc, linkInfoInt);
	dataPCNext <= stagePCNext(dataPC, dataPCNew, 
											flowResponsePC.living, flowResponsePC.sending, flowDrivePC.prevSending);
	FRONT_CLOCKED: process(clk)
		variable linkInfoExcVar, linkInfoIntVar: InstructionBasicInfo := defaultBasicInfo;	
		variable targetInfoVar: InstructionBasicInfo := defaultBasicInfo;
	begin					
		if rising_edge(clk) then
			if reset = '1' then			
			elsif en = '1' then
				-- CAREFUL: writing to currentState BEFORE normal sys reg write gives priority to the latter;
				--				otherwise explicit setting of currentState wouln't work.
				--				So maybe other sys regs should have it done the same way, not conversely? 
				--				In any case, the requirement is that younger instructions must take effect later
				--				and override earlier content. 	
				targetInfoVar := dataPCNext.basicInfo;
				targetPC <= targetInfoVar.ip;
				currentState <= X"0000" & targetInfoVar.systemLevel & targetInfoVar.intLevel;
				
				if sysRegWriteAllow = '1' then
					sysRegArray(slv2u(sysRegWriteSel)) <= sysRegWriteValue;
				end if;
				
				-- NOTE: writing to link registers after sys reg writing gives priority to the former,
				--			but committing a sysMtc shouldn't happen in parallel with any control event
				if committingIn = '1' and lastCommittedNextIn.controlInfo.hasException = '1' then
						linkInfoExcVar := getLinkInfoJ(lastCommittedNextIn, committingNext);
						linkRegExc <= linkInfoExcVar.ip;
						savedStateExc <= X"0000" & linkInfoExcVar.systemLevel & linkInfoExcVar.intLevel;						
						
				elsif	(frontEvents.eventOccured and frontEvents.causing.controlInfo.newInterrupt) = '1' then
					linkInfoIntVar := getLinkInfoE(frontEvents.causing, causingNext);
					linkRegInt <= getSyncFlowInstructionAddress(frontEvents.causing, causingNext);
					savedStateInt <= X"0000" & linkInfoIntVar.systemLevel & linkInfoIntVar.intLevel;						
				end if;
				
				sysRegArray(0) <= PROCESSOR_ID;
				
				-- Only some number of system regs exists		
				for i in 6 to 31 loop
					sysRegArray(i) <= (others => '0');
				end loop;							
			end if;					
		end if;
	end process;

	SIMPLE_SLOT_LOGIC_PC: SimplePipeLogic port map(
		clk => clk, reset => reset, en => en,
		flowDrive => flowDrivePC,
		flowResponse => flowResponsePC
	);		

		targetInfo <= (ip => targetPC,
							systemLevel => currentState(15 downto 8),
							intLevel => currentState(7 downto 0));		
		dataPC <= pcDataFromBasicInfo(targetInfo);							
				
	flowDrivePC.prevSending <= flowResponsePC.accepting; -- CAREFUL! This way it never gets hungry
	flowDrivePC.nextAccepting <= nextAccepting;	

	flowDrivePC.kill <= frontEvents.affectedVec(0);		

	stageDataOut <= dataPC;
	acceptingOut <= flowResponsePC.accepting; -- Used anywhere?
	sendingOut <= flowResponsePC.sending;
		
	sysRegReadValue <= sysRegArray(slv2u(sysRegReadSel));							
end Behavioral;

