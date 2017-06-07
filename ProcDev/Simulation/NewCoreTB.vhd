--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   22:20:29 12/07/2015
-- Design Name:   
-- Module Name:   C:/Users/frakt_000/Dropbox/ProcDev/NewCoreTB.vhd
-- Project Name:  ProcDev
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: FrontPipe0
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;

	use work.ProcBasicDefs.all;
	use work.Helpers.all;	
	
	use work.ProcInstructionsNew.all;
	
	use work.NewPipelineData.all;
 
	use work.TEMP_DEV.all;
	use work.GeneralPipeDev.all;		
--	use work.CommonRouting.all;
 
	use work.ProgramCode4.all; 
 
ENTITY NewCoreTB IS
END NewCoreTB;
 
ARCHITECTURE behavior OF NewCoreTB IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT NewCore0 -- FrontPipe0
    PORT(
         clk : IN  std_logic;
         reset : IN  std_logic;
         en : IN  std_logic;
         iadrvalid : OUT  std_logic;
         iadr : OUT  std_logic_vector(31 downto 0);
         ivalid : IN  std_logic;
         iin : IN  InsGroup;
			
			  dread: out std_logic;
			  dwrite: out std_logic;
           dadr : out  Mword;
			  doutadr: out Mword;
			  dvalid: in std_logic;
           din : in  Mword;
           dout : out  Mword;			
						
         int0 : IN  std_logic;
         int1 : IN  std_logic;
         iaux : IN  std_logic_vector(31 downto 0);
         oaux : OUT  std_logic_vector(31 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal en : std_logic := '0';
   signal ivalid : std_logic := '0';
   signal iin : InsGroup := (others => (others => '0'));
   signal int0 : std_logic := '0';
   signal int1 : std_logic := '0';
   signal iaux : std_logic_vector(31 downto 0) := (others => '0');

			signal dread: std_logic;
			signal dwrite: std_logic;
      signal     dadr : Mword;
			signal	doutadr: Mword;
		signal	  dvalid: std_logic;
      signal     din :  Mword;
      signal     dout : Mword;


 	--Outputs
   signal iadrvalid : std_logic;
   signal iadr : std_logic_vector(31 downto 0);
   signal oaux : std_logic_vector(31 downto 0);
	
		signal memReadDone, memReadDonePrev, memWriteDone: std_logic := '0';
		signal memReadValue, memReadValuePrev, memWriteAddress, memWriteValue: Mword := (others => '0');

		signal dataMem: WordArray(0 to 255) := (
					72 => X"00000064",
						250 => X"00000055",
					others => (others => '0'));

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
	for uut: NewCore0 use entity work.NewCore0(Behavioral5);
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: NewCore0 PORT MAP (
          clk => clk,
          reset => reset,
          en => en,
          iadrvalid => iadrvalid,
          iadr => iadr,
          ivalid => ivalid,
          iin => iin,
			 
					dread => dread,
					dwrite => dwrite,
				dadr => dadr,
					doutadr => doutadr,
				dvalid => dvalid,
				din => din,
				dout => dout,			 
			 			 
          int0 => int0,
          int1 => int1,
          iaux => iaux,
          oaux => oaux
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '1';
		wait for clk_period/2;
		clk <= '0';
		wait for clk_period/2;
   end process;
 
	--reset <= '1' after 65 ns, '0' after 75 ns; 
	
	en <= '1' after 105 ns;
	
   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for clk_period*10;

      -- insert stimulus here 

      wait;
   end process;

	INT0_ASSERT: process
	begin
		wait for 3000 ns;
						--	510 ns  -- at undefined instruction
							--	- 10 ns;  -- just before committing the exception
							--	+ 10 ns;  -- after exception takes effect, but overriding it
							--	+ 20 ns;  -- 
							--	+ 100 ns; -- after excpetion handler commits first instruction
		wait until rising_edge(clk);
		int0 <= '1';
		wait until rising_edge(clk);
		int0 <= '0';
		wait;	
		
	end process;	
	
	-- Reset interrupt
	INT1_ASSERT: process
	begin		
		wait for 100 ns;
		wait until rising_edge(clk);
		int1 <= '1';
		wait until rising_edge(clk);
		int1 <= '0';
		wait;
		
	end process;

	PROGRAM_MEM: process (clk)
		constant PM_SIZE: natural := WordMem'length; --programMem'length; 	
	begin
		if rising_edge(clk) then
			if en = '1' then -- TEMP! It shouldn't exist here
					if iadrvalid = '1' then
						assert iadr(31 downto 4) & "1111" /= X"ffffffff" 
							report "Illegal address!" severity error;
						
												
						-- CAREFUL! don't fetch if adr not valid, cause it may ovewrite previous, valid fetch block.
						--				If fetch block is valid but cannot be sent further (pipe stall etc.),
						--				it must remain in fetch buffer until it can be sent.
						--				So we can't get new instruction bits when Fetch stalls, cause they'd destroy
						--				stalled content in fetch buffer!
						for i in 0 to PIPE_WIDTH-1 loop
							iin(i) <= --mainProgram --programMem
										 --prog0 -- CAREFUL! if using prog0, PM_SIZE may be wrong
										 --prog1
										 testProg1
										(slv2u(iadr(10 downto 2)) + i); -- CAREFUL! 2 low bits unused (32b memory) 									
						end loop;
					end if;
					
					if iadrvalid = '1' and countOnes(iadr(iadr'high downto 10)) = 0 then
						ivalid <= '1';					
					else
						ivalid <= '0';	
					end if;			
			end if;
		end if;	
	end process;	


	DATA_MEM: process (clk)
	begin
		if rising_edge(clk) then
			if en = '1' then
				if dwrite = '1' then
					assert doutadr /= X"000000ff" 
						report "Store to address 255 - illegal!" severity error;
				end if;
			
				-- TODO: define effective address exact size
			
				-- Reading
				memReadDone <= dread;
				memReadDonePrev <= memReadDone;
				memReadValue <= dataMem(slv2u(dadr(MWORD_SIZE-1 downto 2))) ;-- CAREFUL: pseudo-byte addressing 
				memReadValuePrev <= memReadValue;	
				
				-- Writing
				memWriteDone <= dwrite;
				memWriteValue <= dout;
				memWriteAddress <= doutadr;
				if memWriteDone = '1' then
					dataMem(slv2u(memWriteAddress(MWORD_SIZE-1 downto 2))) -- CAREFUL: pseudo-byte addressing
											<= memWriteValue;
				end if;
				
			end if;
		end if;	
	end process;
	
	din <= memReadValue; --Prev;
	dvalid <= memReadDone; --Prev;
	
END;
