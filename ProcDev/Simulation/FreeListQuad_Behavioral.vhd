
architecture Behavioral_C of FreeListQuad is
	signal takeMW, putMW: std_logic_vector(0 to MAX_WIDTH-1) := (others=>'0');
	signal readTakeMW, writePutMW, readTagsMW: PhysNameArray(0 to MAX_WIDTH-1) := (others=>(others=>'0'));
	
	signal readTakeMW_C, readTagsMW_C: PhysNameArray(0 to MAX_WIDTH-1) := (others=>(others=>'0'));

	constant LIST_SIZE: integer := FREE_LIST_SIZE; --64; -- CAREFUL! 
	
	function initList return PhysNameArray;

	signal listContent: PhysNameArray(0 to LIST_SIZE-1) := initList;
	signal listPtrTake: SmallNumber := i2slv(0, SMALL_NUMBER_SIZE);
	signal listPtrPut: SmallNumber := i2slv(32, SMALL_NUMBER_SIZE);
	
	function initList return PhysNameArray is
		variable res: PhysNameArray(0 to LIST_SIZE-1) := (others => (others=> '0'));
	begin
		for i in 0 to 31 loop
			res(i) := i2slv(32 + i, PhysName'length);
		end loop;
		return res;
	end function;
	
begin
	takeMW(0 to WIDTH-1) <= take;
	putMW(0 to WIDTH-1) <= put;
	
	readTags <= readTagsMW(0 to WIDTH-1);
	
	readTake <= readTakeMW(0 to WIDTH-1);
	writePutMW(0 to WIDTH-1) <= writePut;
	
	
	READ_LIST: for i in 0 to WIDTH-1 generate
		readTagsMW(i) <= i2slv((slv2u(listPtrTake) + i) mod LIST_SIZE, readTagsMW(i)'length);
	end generate;
	
	SYNCHRONOUS: process(clk)
		variable indPut, indTake: integer := 0;
	begin
		if rising_edge(clk) then
			--if reset = '1' then
				
			--elsif en = '1' then
				indTake := slv2u(listPtrTake); 
				indPut := slv2u(listPtrPut);
								
				if rewind = '1' then
					listPtrTake(5 downto 0) <= writeTag; -- Indexing TMP
				end if;
				
				if enableTake = '1' and rewind = '0' then
					for i in 0 to WIDTH-1 loop
						-- indTake := slv2u(listPtrTake);
						-- 
						readTakeMW(i) <= listContent((slv2u(listPtrTake) + i) mod LIST_SIZE);
					end loop;
					indTake := (indTake + WIDTH) mod LIST_SIZE;					
					listPtrTake <= i2slv(indTake, listPtrTake'length);
				end if;
				
				if enablePut = '1' then
					for i in 0 to WIDTH-1 loop
						-- for each element of input vec
						if putMW(i) = '1' then
							listContent(indPut) <= writePutMW(i);
							indPut := (indPut + 1) mod LIST_SIZE;
						end if;
					end loop;
					listPtrPut <= i2slv(indPut, listPtrPut'length);	
				end if;
				
			--end if;
		end if;
	end process;

end Behavioral_C;

