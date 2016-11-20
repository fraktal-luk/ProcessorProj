
architecture Behavioral of RegisterMap0 is
	signal reserveMW, commitMW: std_logic_vector(0 to MAX_WIDTH-1) := (others=>'0');
	signal selectReserveMW, selectCommitMW, selectStableMW: RegNameArray(0 to MAX_WIDTH-1) 
				:= (others=>(others=>'0'));
	signal selectNewestMW: RegNameArray(0 to 3*MAX_WIDTH-1) := (others=>(others=>'0'));
	
	signal writeReserveMW, writeCommitMW, readStableMW: PhysNameArray(0 to 3*MAX_WIDTH-1)
				:= (others=>(others=>'0'));	
	signal readNewestMW: PhysNameArray(0 to 3*MAX_WIDTH-1) := (others=>(others=>'0'));
	
	
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
	reserveMW(0 to WIDTH-1) <= reserve;
	commitMW(0 to WIDTH-1) <= commit;
	
	selectReserveMW(0 to WIDTH-1) <= selectReserve;
	selectCommitMW(0 to WIDTH-1) <= selectCommit;
	selectNewestMW(0 to 3*WIDTH-1) <= selectNewest;
	selectStableMW(0 to WIDTH-1) <= selectStable;
	
	writeReserveMW(0 to WIDTH-1) <= writeReserve;
	writeCommitMW(0 to WIDTH-1) <= writeCommit;
	readNewest <= readNewestMW(0 to 3*WIDTH-1);
	readStable <= readStableMW(0 to WIDTH-1);
	
	
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
			if reset = '1' then
			
			elsif en = '1' then
				-- Rewind if commanded
				if rewind = '1' then
					newestMap <= stableMap;
				end if;
				
				-- Write
				if reserveAllow = '1' and rewind = '0' then
					for i in 0 to reserveMW'length-1 loop
						if reserveMW(i) = '1' then
							newestMap(slv2u(selectReserveMW(i))) <= writeReserveMW(i);
						end if;
					end loop;	
				end if;

				if commitAllow = '1' then -- and rewind = '0' then -- block when rewinding??
					for i in 0 to commitMW'length-1 loop
						if commitMW(i) = '1' then
							stableMap(slv2u(selectCommitMW(i))) <= writeCommitMW(i);
						end if;
					end loop;	
				end if;
				
			end if;
		end if;
	end process;
	
end Behavioral;
