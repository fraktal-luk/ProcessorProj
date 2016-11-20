----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:12:19 04/24/2016 
-- Design Name: 
-- Module Name:    SubunitHbuffer - Behavioral 
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


architecture Behavioral of SubunitHbuffer is
	signal hbufferDataA, hbufferDataA_C, hbufferDataANext: InstructionStateArray(0 to HBUFFER_SIZE-1)
			:= (others => DEFAULT_ANNOTATED_HWORD);
	signal hbufferDataANew: InstructionStateArray(0 to 2*PIPE_WIDTH-1) := (others => DEFAULT_ANNOTATED_HWORD);	
	
	signal stageData, stageDataLiving, stageDataNext: InstructionSlotArray(0 to HBUFFER_SIZE-1) 
								:= (others => DEFAULT_INSTRUCTION_SLOT);
	signal fetchData, stageDataNew: InstructionSlotArray(0 to 2*PIPE_WIDTH-1)
						:= (others => DEFAULT_INSTRUCTION_SLOT);
	
	signal hbufferDrive: FlowDriveBuffer := (killAll => '0', lockAccept => '0', lockSend => '0',
																others=>(others=>'0'));
	signal hbufferResponse: FlowResponseBuffer := (others=>(others=>'0'));
	-- Below: state visible to further (downstream) stages, compatible with their interface.
	--			CAREFUL! Not guaranteed to contain more than needed by next stage
	signal hbufferDriveDown: FlowDriveBuffer := (killAll => '0', lockAccept => '0', lockSend => '0',
																others=>(others=>'0'));
	signal hbufferResponseDown: FlowResponseBuffer := (others=>(others=>'0'));		

	signal shortOpcodes: std_logic_vector(0 to HBUFFER_SIZE-1) := (others=>'0');-- DEPREC but used as dummy
	signal fullMaskHbuffer, livingMaskHbuffer: std_logic_vector(0 to HBUFFER_SIZE-1) := (others=>'0');
		signal fullMask2, fullMask2Next, livingMask2: std_logic_vector(0 to HBUFFER_SIZE-1) := (others=>'0');
	signal hbuffOut: HbuffOutData 
				:= (sd => DEFAULT_STAGE_DATA_MULTI, nOut=>(others=>'0'), nHOut=>(others=>'0'));
				
	signal flowDriveHBuff: FlowDriveSimple := (others=>'0');
	signal flowResponseHbuff: FlowResponseSimple := (others=>'0');	

	signal partialKillMaskHbuffer: std_logic_vector(0 to HBUFFER_SIZE-1) := (others=>'0');

	-- CAREFUL: numbers in hwords!
	signal nFull, nFullNext, nKilled, nLiving, nRemaining, nSending, nReceiving, nShift: integer := 0;
	signal nSendingIns: integer := 0; -- number in instructions, to match later stages
	signal nHIn: SmallNumber := (others => '0');
begin
	nHIn <= i2slv(FETCH_BLOCK_SIZE - (slv2u(stageDataIn.basicInfo.ip(ALIGN_BITS-1 downto 1))),
					  SMALL_NUMBER_SIZE);

	hbufferDataANew <= getAnnotatedHwords(stageDataIn.basicInfo, fetchBlock);
		
		-- TODO: handle possibility of partial killing by partialKillMask!
		livingMask2 <= fullMask2 when execEventSignal = '0' else (others => '0');
		
	hbuffOut <= newFromHbuffer(hbufferDataA, livingMask2);
	
	
		stageDataLiving <= moveQueue(stageData, stageData,
											  nLiving, 0, 0);
		fullMask2 <= extractFullMask(stageData);

		PACK_INTO_SLOTS: for i in 0 to 2*PIPE_WIDTH-1 generate
			fetchData(i).full <= '1';
			fetchData(i).ins.bits(31 downto 16) <= hbufferDataANew(i).bits;
			fetchData(i).ins.bits(15 downto 0) <= (others => '0');
			fetchData(i).ins.basicInfo <= hbufferDataANew(i).basicInfo;			
		end generate;
		
		UNPACK_FROM_SLOTS: for i in 0 to HBUFFER_SIZE-1 generate
			hbufferDataA(i).bits <= stageDataLiving(i).ins.bits(31 downto 16);
			hbufferDataA(i).basicInfo <= stageDataLiving(i).ins.basicInfo;
		end generate;		
		
		nShift <= (2*PIPE_WIDTH - binFlowNum(nHIn));
		-- remove nShift elements form left
		stageDataNew <= moveQueue(fetchData, fetchData, -- second fetchData is dummy
										  2*PIPE_WIDTH, nShift, 0); 
		
		stageDataNext <= moveQueue(stageDataLiving, stageDataNew,
											nLiving, nSending, nReceiving);
	
			-- Flow numbers
			nSending <= binFlowNum(hbuffOut.nHOut) when nextAccepting = '1'
					 else 0;
				
			nReceiving <= binFlowNum(nHIn) when prevSending = '1'
						else 0;
														
			nLiving <= nFull - nKilled;
			nRemaining <= nLiving - nSending;
			nFullNext <= nRemaining + nReceiving;
	
				nKilled <= nFull when execEventSignal = '1'
						else countOnes(fullMask2 and partialKillMaskHbuffer);
	
	FRONT_CLOCKED: process(clk)
	begin					
		if rising_edge(clk) then
			if reset = '1' then
				
			elsif en = '1' then
				stageData <= stageDataNext;
				nFull <= nFullNext;
			end if;					
		end if;
	end process;	

	stageDataOut <= hbuffOut.sd;				
	acceptingOut <= '1' when nFull + FETCH_BLOCK_SIZE <= HBUFFER_SIZE else '0';
	sendingOut <= nextAccepting and isNonzero(hbuffOut.nHOut);
end Behavioral;

