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

--use work.CommonRouting.all;
use work.TEMP_DEV.all;

use work.ProcComponents.all;

use work.ProcLogicFront.all;


entity SubunitPC is
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
		
		committingIn: in std_logic; -- *
		nextAccepting: in std_logic;		


		lastCommittedNextIn: in InstructionState;
		acceptingOut: out std_logic;
		sendingOut: out std_logic;
		stageDataOut: out InstructionState;		
		
		lockSendCommand: in std_logic;
				
		sysRegReadSel: in slv5;
		sysRegReadValue: out Mword;		
		
		sysRegWriteAllow: in std_logic;
		sysRegWriteSel: in slv5;
		sysRegWriteValue: in Mword;

		frontEvents: in FrontEventInfo;

		start: in std_logic	
	);
end SubunitPC;


architecture Implem of SubunitPC is	
	signal flowDrivePC: FlowDriveSimple := (others=>'0');
	signal flowResponsePC: FlowResponseSimple := (others=>'0');
	
	signal targetInfo, nextTargetInfo, excLinkInfo, intLinkInfo, newTargetInfo: InstructionBasicInfo
									:= defaultBasicInfo;
	signal targetPC: Mword := INITIAL_PC; --(others => '0');
	
	signal pcNext: Mword := (others => '0');
	signal pcBase: Mword := (others => '0'); 
	signal pcInc: Mword := (others => '0');
	
	signal causingNext: Mword := (others => '0');
	signal causingPC: Mword := (others => '0');
	signal causingInc: Mword := (others => '0');

	signal committingNext: Mword := (others => '0');
	signal committingPC: Mword := (others => '0');
	signal committingInc: Mword := (others => '0');
	
	signal sysRegArray: MwordArray(0 to 31) := (0 => PROCESSOR_ID, others => (others => '0'));	
	
	alias linkRegExc is sysRegArray(2);
	alias linkRegInt is sysRegArray(3);
	
	alias savedStateExc is sysRegArray(4);
	alias savedStateInt is sysRegArray(5);	
	
	alias currentState is sysRegArray(1);
		
	signal stageData, stageDataNext, stageDataNew: InstructionState := DEFAULT_INSTRUCTION_STATE;
	signal stageDataBasic: InstructionState := INITIAL_DATA_PC;
	--	signal stageDataBasic2: InstructionState := DEFAULT_INSTRUCTION_STATE;
	
	signal excInfoUpdate, intInfoUpdate: std_logic := '0';
	
	--signal stopped: std_logic := '1';
	signal pcAccepting, pcSending, pcPrevSending: std_logic := '0';
		--signal pcAccepting2, pcSending2, prevSendingPc: std_logic := '0';
	signal startCommand: std_logic := '0';
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
		
		pcBase <= stageData.basicInfo.ip and i2slv(-PIPE_WIDTH*4, MWORD_SIZE); -- Clearing low bits
		
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
		
		pcInc <= (ALIGN_BITS => '1', others => '0'); -- CAREFUL: incr even if not sending, coz INI_ADR < 0x0 
		
		
	excInfoUpdate <= committingIn and lastCommittedNextIn.controlInfo.hasException;
	intInfoUpdate <= frontEvents.eventOccured and frontEvents.causing.controlInfo.newInterrupt;
	
	excLinkInfo <= getLinkInfoNormal(lastCommittedNextIn, committingNext);
	intLinkInfo <= getLinkInfoSuper(frontEvents.causing, causingNext);
		
	SYS_REGS: block
	begin
		CLOCKED: process(clk)
		begin					
			if rising_edge(clk) then
				if reset = '1' then			
				elsif en = '1' then
					-- CAREFUL: writing to currentState BEFORE normal sys reg write gives priority to the latter;
					--				otherwise explicit setting of currentState wouln't work.
					--				So maybe other sys regs should have it done the same way, not conversely? 
					--				In any case, the requirement is that younger instructions must take effect later
					--				and override earlier content.

					-- Write currentState (control flow may be just changing it)					
					if pcPrevSending = '1' then
						currentState <= X"0000" & newTargetInfo.systemLevel & newTargetInfo.intLevel;						
					end if;
					
					-- Write from system write instruction
					if sysRegWriteAllow = '1' then
						sysRegArray(slv2u(sysRegWriteSel)) <= sysRegWriteValue;
					end if;
					
					-- NOTE: writing to link registers after sys reg writing gives priority to the former,
					--			but committing a sysMtc shouldn't happen in parallel with any control event
					-- Writing exc status registers
					if excInfoUpdate = '1' then
						linkRegExc <= excLinkInfo.ip;
						savedStateExc <= X"0000" & excLinkInfo.systemLevel & excLinkInfo.intLevel;							
					-- Writing int status registers
					elsif intInfoUpdate = '1' then
						linkRegInt <= intLinkInfo.ip;
						savedStateInt <= X"0000" & intLinkInfo.systemLevel & intLinkInfo.intLevel;
					end if;
					
					-- Enforcing content of read-only registers
					sysRegArray(0) <= PROCESSOR_ID;
					
					-- Only some number of system regs exists		
					for i in 6 to 31 loop
						sysRegArray(i) <= (others => '0');
					end loop;
				
				end if;
			end if;	
		end process;
	end block;
	
		newTargetInfo <= stageDataNew.basicInfo;

		startCommand <= start;

	FRONT_CLOCKED: process(clk)
	begin					
		if rising_edge(clk) then

			if reset = '1' then			
			elsif en = '1' then
					
			end if;					
		end if;
	end process;

	stageDataOut <= stageData;
	acceptingOut <= pcAccepting;
	sendingOut <= pcSending;
		stageData.basicInfo <= targetInfo; -- To have regular representation as InstructionState

		targetInfo <= (ip => stageDataBasic.basicInfo.ip,
							systemLevel => currentState(15 downto 8),
							intLevel => currentState(7 downto 0));
		
		TMP: block
			signal tmpPcIn, tmpPcOut: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
		begin		
			tmpPcIn.fullMask(0) <= pcPrevSending;
			tmpPcIn.data(0) <= stageDataNew;
			stageDataNew <= newPCData(stageData, frontEvents, pcNext, causingNext, startCommand);			
						
			-- CAREFUL: prevSending normally means that 'full' bit inside will be set, but
			--				when en = '0' this won't happen.
			--				To be fully correct, prevSending should not be '1' when receiving prevented.			
			pcPrevSending <= pcAccepting and (pcSending or frontEvents.eventOccured);
											
			TEMP_SUBUNIT: entity work.GenericStageMulti(Behavioral) port map(
				clk => clk, reset => reset, en => en,
						
				prevSending => pcPrevSending,

				nextAccepting => nextAccepting and not (lockSendCommand),
				stageDataIn => tmpPcIn,
				
				acceptingOut => pcAccepting,
				sendingOut => pcSending,
				stageDataOut => tmpPcOut,
				
				execEventSignal => frontEvents.affectedVec(0),
				execCausing => DEFAULT_INSTRUCTION_STATE,
				lockCommand => '0'		
			);			
			
			stageDataBasic <= tmpPcOut.data(0);
		end block;
		
	sysRegReadValue <= sysRegArray(slv2u(sysRegReadSel));							
end Implem;

