--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;

  --use work.ProcGeneral.all; 
  
	use work.ProcBasicDefs.all;
	use work.ProcInstructionsNew.all;
	
	use work.Decoding2.all;
	
package ProgramCode3 is

		type WordMem is array (0 to 511 + 512) of word;

		constant programMem: WordMem := (
								  0 => ins655H(addI, r3, r0, 1022),
										 --X"12345678",
								  1 => ins655H(addI,  r7, r3, 33),
								  2 => ins655655(ext0,  r11, r3, addR, r2, 0),	
								  3 => ins655655(ext0,  r12, r3, muls, r3, 0),	
								  4 => ins655655(ext0,  r13, r3, muls, r7, 0),	
								  
								  5 => ins655H(addI, r5, r13, 333),
								  6 => ins655H(addI,  r7, r3, 34),
								  7 => 	
										 ins65J(jnz, r0, 4* (-6)), 
										 --ins655655(ext1, r4, r3, jnzR, r0, 0), -- jmp to adr in register
								  8 => ins655655(ext0,  r12, r3, addR, r0, 0),	
								  9 => 
											ins6556X(ext1, r1, r0, load, 250),								  
								  10 => 
											ins6556X(ext1, r3, r0, store, 250),	
			11 => X"000000B0",
					--ins655655(ext2, 0, 0, mtc, 0, 0),
			
			
			12 => X"000000C0",
			13 => X"000000D0",
			14 => X"000000E0",
				-- This sequence is to cause overflow in addition at 25
				23 => ins655H(subI, r21, r0, 1),
				24 => ins655655(ext0, r21, r21, shrlC, 1, 0),
				25 => ins655655(ext0, r0, r21, addR, r21, 0), -- Overflow
			
					30-1 => X"ffffffff",
						
			--206 => ins655655(ext2, 2, 3, mtc,  0, 0),
			64 + 7 => ins655655(ext2, 2, 3, mfc, 1, 2),

			--64 + 9 => ins65J(jz, r0, 4* (-72)),			
			
			64 + 10 => ins655655(ext2, 0, 0, rete, 0, 0),
			
			75 + 10 => ins655655(ext2, 0, 0, reti, 0, 0),
				-- When there are more than 512 elements - for testing int return
				128 => ins655655(ext2, 0, 0, reti, 0, 0),	
			others=> ins655H(orI, r28, r28,479)	
			--others=>(others=>'0')
		);		

	
		constant prog0: WordMem := (
			0 => ins655H(orI, r1, r0, 2),
			1 => ins655H(orI, r2, r0, 4),
			2 => ins655655(ext0, r3, r1, muls, r2, 0),
			3 => ins655H(orI, r4, r3, 8),
			
			others => ins655655(ext0, r0, r0, orR, r0, 0)
		);
	
end ProgramCode3;



package body ProgramCode3 is


 
end ProgramCode3;
