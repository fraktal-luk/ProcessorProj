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
		
		frontAccepting: in std_logic;		

		acceptingOut: out std_logic;
		sendingOut: out std_logic;
		stageDataOut: out InstructionState;		
		
		fetchLockState: in std_logic;
				
		sysRegReadSel: in slv5;
		sysRegReadValue: out Mword;		
		
		sysRegWriteAllow: in std_logic;
		sysRegWriteSel: in slv5;
		sysRegWriteValue: in Mword;

		generalEvents: in GeneralEventInfo
	);
end SubunitPC;


architecture Implem of SubunitPC is
	signal excLinkInfo, intLinkInfo, newTargetInfo: InstructionBasicInfo := defaultBasicInfo;
	
	signal pcBase: Mword := (others => '0');
	
	constant PC_INC: Mword := (ALIGN_BITS => '1', others => '0');

	signal pcNext: Mword := (others => '0');	
	signal causingNext: Mword := (others => '0');

	signal currentStateSig: Mword := (others => '0');
	
	signal stageDataToPC: InstructionState := DEFAULT_INSTRUCTION_STATE;
	signal stageDataBasicPC: InstructionState := INITIAL_DATA_PC;
	
	signal excInfoUpdate, intInfoUpdate: std_logic := '0';

	signal sendingToPC: std_logic := '0';
	

	signal stageDataOutPC: InstructionState := DEFAULT_INSTRUCTION_STATE; -- 	
	signal acceptingOutPC, sendingOutPC: std_logic := '0'; -- 
begin

	CAUSING_ADDER: entity work.IntegerAdder
	port map(
		inA => generalEvents.causing.basicInfo.ip,
		inB => getAddressIncrement(generalEvents.causing),
		output => causingNext
	);
		
	pcBase <= stageDataOutPC.basicInfo.ip and i2slv(-PIPE_WIDTH*4, MWORD_SIZE); -- Clearing low bits

	SEQ_ADDER: entity work.IntegerAdder
	port map(
		inA => pcBase,
		inB => PC_INC,
		output => pcNext
	);
		

	SYS_REGS: block
		signal sysRegArray: MwordArray(0 to 31) := (0 => PROCESSOR_ID, others => (others => '0'));	

		alias currentState is sysRegArray(1);
		
		alias linkRegExc is sysRegArray(2);
		alias linkRegInt is sysRegArray(3);
		
		alias savedStateExc is sysRegArray(4);
		alias savedStateInt is sysRegArray(5);			
	begin
		CLOCKED: process(clk)
		begin					
			if rising_edge(clk) then
				if reset = '1' then			
				elsif en = '1' then
					-- CAREFUL: writing to currentState BEFORE normal sys reg write gives priority to the latter;
					--				otherwise explicit setting of currentState wouldn't work.
					--				So maybe other sys regs should have it done the same way, not conversely? 
					--				In any case, the requirement is that younger instructions must take effect later
					--				and override earlier content.

					-- Write currentState (control flow may be just changing it)					
					if sendingToPC = '1' then
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
					end if;
					
					-- Writing int status registers
					if intInfoUpdate = '1' then
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
		
		currentStateSig <= currentState;
		sysRegReadValue <= sysRegArray(slv2u(sysRegReadSel));							
	end block;
	
	newTargetInfo <= stageDataToPC.basicInfo;

	excInfoUpdate <= generalEvents.eventOccured and generalEvents.causing.controlInfo.newException;
	intInfoUpdate <= generalEvents.eventOccured and generalEvents.causing.controlInfo.newInterrupt;
	
	excLinkInfo <= getLinkInfoNormal(generalEvents.causing, causingNext);
	intLinkInfo <= getLinkInfoSuper(generalEvents.causing, causingNext);

	
	stageDataOutPC.basicInfo <= 
						  (ip => stageDataBasicPC.basicInfo.ip,
							systemLevel => currentStateSig(15 downto 8),
							intLevel => currentStateSig(7 downto 0));
		
		TMP: block
			signal tmpPcIn, tmpPcOut: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
		begin		
			tmpPcIn.fullMask(0) <= sendingToPC;
			tmpPcIn.data(0) <= stageDataToPC;
			stageDataToPC <= newPCData(stageDataOutPC, generalEvents, pcNext, causingNext);			
						
			-- CAREFUL: prevSending normally means that 'full' bit inside will be set, but
			--				when en = '0' this won't happen.
			--				To be fully correct, prevSending should not be '1' when receiving prevented.			
			sendingToPC <= acceptingOutPC and (sendingOutPC or generalEvents.eventOccured);
											
			TEMP_SUBUNIT: entity work.GenericStageMulti(Behavioral) port map(
				clk => clk, reset => reset, en => en,
						
				prevSending => sendingToPC,

				nextAccepting => frontAccepting and not fetchLockState,
				stageDataIn => tmpPcIn,
				
				acceptingOut => acceptingOutPC,
				sendingOut => sendingOutPC,
				stageDataOut => tmpPcOut,
				
				execEventSignal => generalEvents.affectedVec(0),
				execCausing => DEFAULT_INSTRUCTION_STATE,
				lockCommand => '0'		
			);			
			
			stageDataBasicPC <= tmpPcOut.data(0);
		end block;


	stageDataOut <= stageDataOutPC; --
	acceptingOut <= acceptingOutPC; --
	sendingOut <= sendingOutPC;	  --
	
end Implem;

