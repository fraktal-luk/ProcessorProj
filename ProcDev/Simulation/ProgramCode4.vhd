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
	
package ProgramCode4 is

		type WordMem is array (0 to 511 + 512) of word;

		constant mainProgram: WordMem := (
								  0 => ins655H(addI, r3, r0, 1022),
										 --X"12345678",
								  1 => ins655H(addI,  r7, r3, 33),
								  2 => ins655655(ext0,  r11, r3, addR, r7, 0),	
								  3 => ins655655(ext0,  r12, r3, muls, r3, 0),	
								  4 => ins655655(ext0,  r13, r3, muls, r7, 0),	
								  
								  5 => --ins655H(addI, r5, r13, 333),
										  ins655655(ext0, r5, r13, addR, r10, 0),
								  6 => ins655H(addI,  r7, r3, 34),
								  7 => 	
										 ins65J(jnz, r0, 4* (-6)), 
										 --ins65J(jl, r30, 4*(-6)),
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
				--25 => ins655655(ext0, r0, r21, addR, r21, 0), -- Overflow
			
					30-1 => X"ffffffff",
						
						40 => ins655H(subI, r30, r0, 7),
						41 => ins655H(andI, r31, r30, 15),
						42 => ins655H(subI, r15, r0, 10),
						43 => ins655655(ext0, r14, r30, subR, r15, 0),
						44 => ins655H(andI, r16, r14, 6),
						45 => ins655655(ext0, r17, r16, addR, r28, 0),
						46 => ins655655(ext0, r0, r20, addR, r3, 0),
							
				54 => ins65J(jz, r0, 4*(-20)),
					
			--206 => ins655655(ext2, 2, 3, mtc,  0, 0),
			64 + 12 => ins655655(ext2, r20, 0, mfc, 0, 2), -- 2: ELR
			64 + 13 => ins655655(ext2, r21, 0, mfc, 0, 4), -- 4: Exc saved state

			64 + 14 => ins655655(ext2, 0, r21, mtc, 1, 0),   -- 1: current state			
			
			-- Return form exception implemented as jump to register, after restoring program state
			64 + 15 => --ins655655(ext2, 0, 0, rete, 0, 0),
							ins655655(ext1, r0, r0, jzR, r20, 0),
			
			
			--75 + 10 => ins655655(ext2, 0, 0, reti, 0, 0),
				-- When there are more than 512 elements - for testing int return
				
				130 => ins655655(ext2, r20, 0, mfc, 0, 3), -- 3: ILR
				131 => ins655655(ext2, r21, 0, mfc, 0, 5), -- 5: Int saved state
				132 => ins655655(ext2, 0, r21, mtc, 1, 0),   -- 1: current state
				133 => ins655655(ext1, r0, r0, jzR, r20, 0),
				
			others=> ins655H(orI, r28, r28,479)	
			--others=>(others=>'0')
		);		

	
		constant prog0: WordMem := (
			0 => ins655H(orI, r1, r0, 2),
			1 => ins655H(orI, r2, r0, 4),
			2 => ins655655(ext0, r3, r1, muls, r2, 0),
			3 => ins655H(orI, r4, r3, 8),
			
			4 => ins6556X(ext1, r4, r0, store, 100),
			5 => ins6556X(ext1, r4, r0, store, 100),
			6 => ins6556X(ext1, r4, r0, store, 100),
			7 => ins6556X(ext1, r4, r0, store, 100),
			8 => ins6556X(ext1, r4, r0, store, 100),
			9 => ins6556X(ext1, r4, r0, store, 100),
			10 => ins6556X(ext1, r4, r0, store, 100),
			11 => ins6556X(ext1, r4, r0, store, 100),
			12 => ins6556X(ext1, r4, r0, store, 100),
			13 => ins655655(ext0, r5, r0, muls, r0, 0), -- delays the jump, some yuger stores bypass it
			14 => ins65J(jz, r5, 4* (-8)), -- r5 = 0, so jumping and flushing younger stores
			15 => ins6556X(ext1, r4, r0, store, 100),
			--16 => ins6556X(ext1, r4, r0, store, 100),
			--17 => ins6556X(ext1, r4, r0, store, 100),
			--18 => ins6556X(ext1, r4, r0, store, 100),
			--19 => ins6556X(ext1, r4, r0, store, 100),
			
			
			others => ins655655(ext0, r0, r0, orR, r0, 0)
		);

		constant prog1: WordMem := ( -- mem load testing 
			0 => ins655H(orI, r1, r0, 2),
			1 => ins655H(orI, r2, r0, 4),
			2 => ins655655(ext0, r3, r1, muls, r2, 0),
			3 => ins655H(orI, r4, r3, 8),
			
			4 => ins6556X(ext1, r4, r0, load, 100),
			5 => ins6556X(ext1, r4, r0, load, 100),
			6 => ins6556X(ext1, r4, r0, load, 100),
			7 => ins6556X(ext1, r4, r0, load, 100),
			8 => ins6556X(ext1, r4, r0, load, 100),
			9 => ins6556X(ext1, r4, r0, load, 100),
			10 => ins6556X(ext1, r4, r0, load, 100),
			11 => ins6556X(ext1, r4, r0, load, 100),
			12 => ins6556X(ext1, r4, r0, load, 100),
			13 => ins655655(ext0, r5, r0, muls, r0, 0), -- delays the jump, some yuger stores bypass it
			14 => ins65J(jz, r5, 4* (-8)), -- r5 = 0, so jumping and flushing younger stores
			15 => ins6556X(ext1, r4, r0, load, 100),
			--16 => ins6556X(ext1, r4, r0, store, 100),
			--17 => ins6556X(ext1, r4, r0, store, 100),
			--18 => ins6556X(ext1, r4, r0, store, 100),
			--19 => ins6556X(ext1, r4, r0, store, 100),
			
			
			others => ins655655(ext0, r0, r0, orR, r0, 0)
		);
	

		constant testProg0: WordMem := ( -- mem load testing 
			-- Check passing result to subsequent instructions as src1 by all paths for single subpipe
			0 => ins655H(addI, r1, r0, 300),
			1 => ins655655(ext0, r2, r0, addR, r1, 0),
			2 => ins655655(ext0, r3, r0, addR, r1, 0),
			3 => ins655655(ext0, r4, r0, addR, r1, 0),
			4 => ins655655(ext0, r5, r0, addR, r1, 0),
			5 => ins655655(ext0, r6, r0, addR, r1, 0),
			6 => ins655655(ext0, r7, r0, addR, r1, 0),

			-- Check passing result to subsequent instructions as src0 by all paths for single subpipe			
			10 => ins655H(addI, r11, r0, 400),
			11 => ins655655(ext0, r12, r11, addR, r0, 0),
			12 => ins655655(ext0, r13, r11, addR, r0, 0),
			13 => ins655655(ext0, r14, r11, addR, r0, 0),
			14 => ins655655(ext0, r15, r11, addR, r0, 0),
			15 => ins655655(ext0, r16, r11, addR, r0, 0),
			16 => ins655655(ext0, r17, r11, addR, r0, 0),
			
			-- Save registers to memory 0-31
			20 => ins6556X(ext1, r0, r0, store, 0),
			21 => ins6556X(ext1, r1, r0, store, 1),
			22 => ins6556X(ext1, r2, r0, store, 2),
			23 => ins6556X(ext1, r3, r0, store, 3),
			24 => ins6556X(ext1, r4, r0, store, 4),
			25 => ins6556X(ext1, r5, r0, store, 5),
			26 => ins6556X(ext1, r6, r0, store, 6),
			27 => ins6556X(ext1, r7, r0, store, 7),
			28 => ins6556X(ext1, r8, r0, store, 8),
			29 => ins6556X(ext1, r9, r0, store, 9),
			30 => ins6556X(ext1, r10, r0, store, 10),
			31 => ins6556X(ext1, r11, r0, store, 11),
			32 => ins6556X(ext1, r12, r0, store, 12),
			33 => ins6556X(ext1, r13, r0, store, 13),
			34 => ins6556X(ext1, r14, r0, store, 14),
			35 => ins6556X(ext1, r15, r0, store, 15),			
			36 => ins6556X(ext1, r16, r0, store, 16),
			37 => ins6556X(ext1, r17, r0, store, 17),
			38 => ins6556X(ext1, r18, r0, store, 18),
			39 => ins6556X(ext1, r19, r0, store, 19),
			40 => ins6556X(ext1, r20, r0, store, 20),
			41 => ins6556X(ext1, r21, r0, store, 21),
			42 => ins6556X(ext1, r22, r0, store, 22),
			43 => ins6556X(ext1, r23, r0, store, 23),
			44 => ins6556X(ext1, r24, r0, store, 24),
			45 => ins6556X(ext1, r25, r0, store, 25),
			46 => ins6556X(ext1, r26, r0, store, 26),
			47 => ins6556X(ext1, r27, r0, store, 27),
			48 => ins6556X(ext1, r28, r0, store, 28),
			49 => ins6556X(ext1, r29, r0, store, 29),
			50 => ins6556X(ext1, r30, r0, store, 30),
			51 => ins6556X(ext1, r31, r0, store, 31),			

			-- Increment a number and save to a range in memory (in a loop)
			60 => ins655H(addI, r1, r0, 0), -- value in r1
			61 => ins655H(addI, r2, r0, 50), -- address in r2
			62 => ins6556X(ext1, r1, r2, store, 0), -- store
			63 => ins655H(addI, r1, r1, 1), -- inc value
			64 => ins655H(addI, r2, r2, 1), -- inc address
			65 => ins655H(subI, r3, r1, 8), -- comp value to 8
			66 => ins65J(jnz, r3, 4* (-4)), -- if not equal, repeat
			

			others => ins655655(ext0, r0, r0, orR, r0, 0)
		);
		
	
end ProgramCode4;



package body ProgramCode4 is


 
end ProgramCode4;
