----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:07:11 01/07/2017 
-- Design Name: 
-- Module Name:    RegisterMappingUnit - Behavioral 
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

use work.ProcLogicRenaming.all;



entity RegisterMappingUnit is
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
		
		rewind: in std_logic;
		causingInstruction: in InstructionState; -- CAREFUL: not used now, mapping restored from stable
		
		sendingToReserve: in std_logic;
		stageDataToReserve: in StageDataMulti;
		newPhysDests: in PhysNameArray(0 to PIPE_WIDTH-1); -- to write to newest map

		sendingToCommit: in std_logic;
		stageDataToCommit: in StageDataMulti;
		physCommitDests_TMP: in PhysNameArray(0 to PIPE_WIDTH-1); -- to write to stable map
		
		prevNewPhysDests: out PhysNameArray(0 to PIPE_WIDTH-1);
		newPhysSources: out PhysNameArray(0 to 3*PIPE_WIDTH-1);
		
		prevStablePhysDests: out PhysNameArray(0 to PIPE_WIDTH-1);
		stablePhysSources: out PhysNameArray(0 to 3*PIPE_WIDTH-1)
	
		--readyRegFlagsNext: out std_logic_vector(0 to 3*PIPE_WIDTH-1) -- MAYBE IN THE FUTURE		
	);
end RegisterMappingUnit;



architecture Behavioral of RegisterMappingUnit is
		constant	WIDTH: natural := PIPE_WIDTH;
		constant MAX_WIDTH: natural := MW;

		signal virtDests, virtCommitDests: RegNameArray(0 to PIPE_WIDTH-1) := (others=>(others=>'0'));
		signal virtSources: RegNameArray(0 to 3*PIPE_WIDTH-1) := (others=>(others=>'0'));
	
		signal gprReserveReq, gprCommitReq: RegisterMapRequest := DEFAULT_REGISTER_MAP_REQUEST;

			signal physCommitDests: PhysNameArray(0 to PIPE_WIDTH-1) := (others=>(others=>'0'));
	signal reserveMW, commitMW: std_logic_vector(0 to MAX_WIDTH-1) := (others=>'0');
	signal selectReserveMW, selectCommitMW, selectStableMW: RegNameArray(0 to MAX_WIDTH-1) 
				:= (others=>(others=>'0'));
	signal selectNewestMW: RegNameArray(0 to 3*MAX_WIDTH-1) := (others=>(others=>'0'));
	
	signal writeReserveMW, writeCommitMW, readStableMW: PhysNameArray(0 to 3*MAX_WIDTH-1)
				:= (others=>(others=>'0'));	
	signal readNewestMW: PhysNameArray(0 to 3*MAX_WIDTH-1) := (others=>(others=>'0'));
	
		signal readyTableReadNewestMW: std_logic_vector(0 to 3*MAX_WIDTH-1) := (others => '0');
	
	function initMap return PhysNameArray;
	
	signal newestMap, stableMap: PhysNameArray(0 to 31) := initMap;

	function initMap return PhysNameArray is
		variable res: PhysNameArray(0 to 31) := (others => (others=> '0'));
	begin
		for i in 0 to 31 loop
			res(i) := i2slv(i, PhysName'length);
		end loop;
		return res;
	end function;

begin	

	reserveMW(0 to WIDTH-1) <= gprReserveReq.sel;
	commitMW(0 to WIDTH-1) <= gprCommitReq.sel;
	
	selectReserveMW(0 to WIDTH-1) <= gprReserveReq.index;
	selectCommitMW(0 to WIDTH-1) <= gprCommitReq.index;
	selectNewestMW(0 to 3*WIDTH-1) <= virtSources;
	selectStableMW(0 to WIDTH-1) <= virtCommitDests;
	
	writeReserveMW(0 to WIDTH-1) <= gprReserveReq.value;
	writeCommitMW(0 to WIDTH-1) <= gprCommitReq.value;
	
	newPhysSources <= readNewestMW(0 to 3*WIDTH-1); 
	prevStablePhysDests <= readStableMW(0 to WIDTH-1);

		virtSources <= getVirtualArgs(stageDataToReserve);
		virtDests <= getVirtualDests(stageDataToReserve); -- // UNUSED?
			
		gprReserveReq <= getRegMapRequest(stageDataToReserve, newPhysDests);	
		gprCommitReq <= getRegMapRequest(stageDataToCommit, physCommitDests);

		virtCommitDests <= getVirtualDests(stageDataToCommit);
		physCommitDests <= getPhysicalDests(stageDataToCommit);


	-- Read
	READ_NEWEST: for i in 0 to selectNewestMW'length-1 generate
		readNewestMW(i) <= newestMap(slv2u(selectNewestMW(i)));		
	end generate;

	READ_STABLE: for i in 0 to selectStableMW'length-1 generate
		readStableMW(i) <= stableMap(slv2u(selectStableMW(i)));
	end generate;
			
	SYNCHRONOUS: process(clk)
	begin
		if rising_edge(clk) then
			-- Rewind if commanded
			if rewind = '1' then
				newestMap <= stableMap;
			end if;
			
			-- Write
			if sendingToReserve = '1' and rewind = '0' then
				for i in 0 to reserveMW'length-1 loop
					if reserveMW(i) = '1' then
						newestMap(slv2u(selectReserveMW(i))) <= writeReserveMW(i);
							assert isNonzero(writeReserveMW(i)) = '1' report "Mapping a speculative register to p0!";
					end if;
				end loop;	
			end if;

			if sendingToCommit = '1' then -- and rewind = '0' then -- block when rewinding??		
				for i in 0 to commitMW'length-1 loop
					if commitMW(i) = '1' then
						stableMap(slv2u(selectCommitMW(i))) <= writeCommitMW(i);
							assert isNonzero(writeCommitMW(i)) = '1' report "Mapping a stable register to p0!";						
					end if;
				end loop;	
			end if;
		end if;
	end process;
end Behavioral;

