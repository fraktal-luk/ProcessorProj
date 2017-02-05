
architecture Behavioral_C of RegisterFile0 is
	signal resetSig, enSig: std_logic := '0';

	signal writeVecMW: std_logic_vector(0 to MAX_WIDTH-1) := (others => '0');
	signal selectWriteMW: PhysNameArray(0 to MAX_WIDTH-1) := (others => (others => '0'));
	signal writeValuesMW: MwordArray(0 to MAX_WIDTH-1) := (others => (others => '0'));
	signal selectReadMW: PhysNameArray(0 to 3*MAX_WIDTH-1) := (others => (others => '0'));	
	signal readValuesMW: MwordArray(0 to 3*MAX_WIDTH-1) := (others => (others => '0'));	

			signal readValuesMW_C: MwordArray(0 to 3*MAX_WIDTH-1) := (others => (others => '0'));	

		signal content: MwordArray(0 to N_PHYSICAL_REGS-1) := (others => (others => '0'));

	constant HAS_RESET_REGFILE: std_logic := '1';
	constant HAS_EN_REGFILE: std_logic := '1';
begin
	resetSig <= reset and HAS_RESET_REGFILE;
	enSig <= en or not HAS_EN_REGFILE;

	writeVecMW(0 to WIDTH-1) <= writeVec; -- when writeAllow = '1' else (others => '0');
		writeVecMW(WIDTH to MAX_WIDTH-1) <= (others => '0');
	selectWriteMW(0 to WIDTH-1) <= selectWrite;
	writeValuesMW(0 to WIDTH-1) <= writeValues;
	
	selectReadMW(0 to 3*WIDTH-1) <= selectRead;
	readValues <= readValuesMW(0 to 3*WIDTH-1);


	SYNCHRONOUS: process(clk)
	begin
		if rising_edge(clk) then
			-- Reading
			--for i in 0 to readValuesMW'length - 1 loop
				if readAllowT0 = '1' then
					readValuesMW(0) <= content(slv2u(selectReadMW(0)));
					readValuesMW(1) <= content(slv2u(selectReadMW(1)));
					readValuesMW(2) <= content(slv2u(selectReadMW(2)));					
				end if;
				
				if readAllowT1 = '1' then
					readValuesMW(3) <= content(slv2u(selectReadMW(3)));
					readValuesMW(4) <= content(slv2u(selectReadMW(4)));
					readValuesMW(5) <= content(slv2u(selectReadMW(5)));
				end if;

				if readAllowT2 = '1' then
					readValuesMW(6) <= content(slv2u(selectReadMW(6)));
					readValuesMW(7) <= content(slv2u(selectReadMW(7)));
					readValuesMW(8) <= content(slv2u(selectReadMW(8)));					
				end if;

				if readAllowT3 = '1' then
					readValuesMW(9) <= content(slv2u(selectReadMW(9)));
					readValuesMW(10) <= content(slv2u(selectReadMW(10)));
					readValuesMW(11) <= content(slv2u(selectReadMW(11)));					
				end if;				
			--end loop;
			
			-- Writing
			if writeAllow = '1' then
				for i in 0 to --writeVecMW'length - 1 loop
									WRITE_WIDTH-1 loop
					if writeVecMW(i) = '1' then
						content(slv2u(selectWriteMW(i))) <= writeValuesMW(i);
					end if;
				end loop;
			end if;
		end if;
	end process;
	
end Behavioral_C;

