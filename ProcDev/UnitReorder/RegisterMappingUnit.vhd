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
		stablePhysSources: out PhysNameArray(0 to 3*PIPE_WIDTH-1);
		
		--	sendingToWrite: in std_logic;
		--	stageDataToWrite: in StageDataMulti;

		--		stageDataToWritePre: in StageDataMulti;
			
			readyRegFlagsNext: out std_logic_vector(0 to 3*PIPE_WIDTH-1) -- MAYBE IN THE FUTURE		
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


--	signal setVecMW, failVecMW,
--				clearVecMW: std_logic_vector(0 to MAX_WIDTH-1) := (others=>'0'); 
--	signal selectSetVirtualMW, selectClearMW: RegNameArray(0 to MAX_WIDTH-1) := (others=>(others=>'0'));
--	signal selectSetPhysicalMW: PhysNameArray(0 to MAX_WIDTH-1) := (others=>(others=>'0'));
--	
--	--signal readyTableNewest, readyTableStable: std_logic_vector(0 to 31) := (others => '1');
--	

		--		signal selectSetVirtualPreMW: RegNameArray(0 to MAX_WIDTH-1) := (others=>(others=>'0'));
--
--
--		signal readyTableClearAllow: std_logic := '0';
--		signal readyTableClearSel: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
--		signal readyTableSetAllow: std_logic := '1';
--		signal readyTableSetSel,
--					readyTableFailSel: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
--		signal readyTableSetVirtualTags: RegNameArray(0 to PIPE_WIDTH-1) := (others => (others =>'0'));
--		signal readyTableSetPhysicalTags: PhysNameArray(0 to PIPE_WIDTH-1) := (others => (others =>'0'));
--
--			signal readyTableSetVirtualPreTags: RegNameArray(0 to PIPE_WIDTH-1) := (others => (others =>'0'));
--
--		signal readyRegsSig: std_logic_vector(0 to N_PHYSICAL_REGS-1) := (0 to 31 => '1', others=>'0');

		--signal newPhysDests: PhysNameArray(0 to PIPE_WIDTH-1) := (others=>(others=>'0'));
	--		signal mapped: PhysNameArray(0 to 31) := (others => (others => '0')); -- TEMP
	--		signal mappingRead: PhysNameArray(0 to WIDTH-1) := (others => (others => '0'));
	
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
		
		--readyTableReadNewestMW(i) <= readyTableNewest(slv2u(selectNewestMW(i)));		
	end generate;

	READ_STABLE: for i in 0 to selectStableMW'length-1 generate
		readStableMW(i) <= stableMap(slv2u(selectStableMW(i)));
	end generate;
			
	SYNCHRONOUS: process(clk)
	begin
		if rising_edge(clk) then
			--if reset = '1' then
			
			--elsif en = '1' then
				-- Rewind if commanded
				if rewind = '1' then
					newestMap <= stableMap;
				end if;
				
				-- Write
				if sendingToReserve = '1' and rewind = '0' then
					for i in 0 to reserveMW'length-1 loop
						if reserveMW(i) = '1' then
							newestMap(slv2u(selectReserveMW(i))) <= writeReserveMW(i);
						end if;
					end loop;	
				end if;

				if sendingToCommit = '1' then -- and rewind = '0' then -- block when rewinding??
				
						--	report ":: " & integer'image(slv2u(commitMW)) & ", " &
						--						integer'image(slv2u(stageDataToCommit.fullMask)) & ", " 							
						--	&					integer'image(slv2u(getDestMask(stageDataToCommit))) & ", " 
						--	& 					integer'image(slv2u(findOverriddenDests(stageDataToCommit)));
									
					for i in 0 to commitMW'length-1 loop
						if commitMW(i) = '1' then
							stableMap(slv2u(selectCommitMW(i))) <= writeCommitMW(i);
						end if;
					end loop;	
				end if;
			--end if;				
		end if;
	end process;
--
--		-- for newest
--		readyTableClearAllow <= sendingToReserve;
--		readyTableClearSel <= getDestMask(stageDataToReserve);
--
--		selectClearMW(0 to WIDTH-1) <= getVirtualDests(stageDataToReserve);	
--		clearVecMW(0 to WIDTH-1) <= readyTableClearSel when readyTableClearAllow = '1' else (others => '0');
--	
--		-- for stable
--		readyTableSetSel <= getPhysicalDestMask(stageDataToWrite)
--						and 		stageDataToWrite.fullMask
--						and not getExceptionMask(stageDataToWrite);
--		readyTableFailSel <= getPhysicalDestMask(stageDataToWrite)
--						and 		stageDataToWrite.fullMask
--						and getExceptionMask(stageDataToWrite);
--						
--		readyTableSetPhysicalTags <= getPhysicalDests(stageDataToWrite); -- for ready table
--		readyTableSetVirtualTags <= getVirtualDests(stageDataToWrite); -- for ready table
--
--			readyTableSetVirtualPreTags <= getVirtualDests(stageDataToWritePre); -- for ready table
--	
--	setVecMW(0 to WIDTH-1) <= readyTableSetSel;-- when readyTableSetAllow = '1' else (others => '0');
--		failVecMW(0 to WIDTH-1) <= readyTableFailSel;-- when readyTableSetAllow = '1' else (others => '0');
--
--
--
--	selectSetVirtualMW(0 to WIDTH-1) <= readyTableSetVirtualTags;
--	selectSetPhysicalMW(0 to WIDTH-1) <= readyTableSetPhysicalTags;
--		
--
--		selectSetVirtualPreMW(0 to WIDTH-1) <= readyTableSetVirtualPreTags;
--
--	SYNCHRONOUS_READY_TABLE: process(clk)
--	begin
--		if rising_edge(clk) then
--
--					for i in 0 to WIDTH-1 loop
--						mappingRead(i) <= newestMap(slv2u(selectSetVirtualPreMW(i)));
--					end loop;
--			
--				if rewind = '1' then
--					readyTableNewest <= readyTableStable;
--				else						
--					-- For newest table
--					for i in 0 to WIDTH-1 loop
--						if setVecMW(i) = '1' then
--							-- set 
--							if selectSetPhysicalMW(i) = --newestMap(slv2u(selectSetVirtualMW(i))) then
--																	mappingRead(i) then
--								--true then
--								readyTableNewest(slv2u(selectSetVirtualMW(i))) <= '1';
--							end if;
--						end if;
--						
--						if clearVecMW(i) = '1' then
--							-- clear
--							readyTableNewest(slv2u(selectClearMW(i))) <= '0';						
--						end if;
--					end loop;
--				end if;
--		end if;
--	end process;
--
--	READ_NEWEST_READY: for i in 0 to selectNewestMW'length-1 generate
--		readyTableReadNewestMW(i) <= readyTableNewest(slv2u(selectNewestMW(i)));
--	end generate;
--
--	--readyRegFlagsNext <= readyTableReadNewestMW(0 to 3*PIPE_WIDTH-1); -- CAREFUL: output suppression

end Behavioral;

