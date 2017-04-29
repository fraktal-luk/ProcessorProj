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

				9 => ins65J(jl, r20, 4*10),

			-- Check passing result to subsequent instructions as src0 by all paths for single subpipe			
			10 => ins655H(addI, r11, r0, 400),
			11 => ins655655(ext0, r12, r11, addR, r0, 0),
			12 => ins655655(ext0, r13, r11, addR, r0, 0),
			13 => ins655655(ext0, r14, r11, addR, r0, 0),
			14 => ins655655(ext0, r15, r11, addR, r0, 0),
			15 => ins655655(ext0, r16, r11, addR, r0, 0),
			16 => ins655655(ext0, r17, r11, addR, r0, 0),
				
				19 => ins6556X(ext1, r20, r0, store, 0),
			
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
		
		
		
		constant insRET: word := ins655655(ext1, r0, r0, jzR, r31, 0); -- j to r31
		constant insERROR: word := ins6556X(ext1, r0, r0, store, 255);
		
		constant insNOP: word := ins655H(addI, r0, r0, 0);
		function insCLEAR(reg: integer) return word is begin return ins655H(addI, reg, r0, 0); end function;
		function insSET(reg, num: integer) return word is
			begin return ins655H(addI, reg, r0, num); end function;		
		function insMOVE(rd, rs: integer) return word is begin return ins655H(addI, rd, rs, 0); end function;

		function insSTORE(ra, rb, num: integer) return word is
			begin return ins6556X(ext1, ra, rb, store, num); end function;
		function insLOAD(ra, rb, num: integer) return word is
			begin return ins6556X(ext1, ra, rb, load, num); end function;		

		
		constant testProg1: WordMem := ( -- mem load testing 
			0 => insNOP, --ins655H(addI, r1, r0, 300),
			1 => insNOP, --ins655H(subI, r30, r0, 1),
			2 => insNOP, 
			3 => insNOP,
			
			4 => ins65J(jl, r31, 4*(320-4)), -- Test result forwarding src1
			5 => ins65J(jl, r31, 4*(350-5)), -- Test result forwarding src0
			6 => ins65J(jl, r31, 4*(380-6)), -- Test 0+1 forwarding
			
			7 => ins65J(jl, r31, 4*(240-7)), -- Store registers to 0-31
			8 => insSET(r4, 16),					-- Arg in r4 for function call
			9 => ins65J(jl, r31, 4*(280-9)), -- Load registers from 16-48
			
			10 => ins65J(jz, r0, 4* (10)), -- Jump to ins 20 (@80)
			
			20 => insNOP,-- ins65J(jl, r31, 4*(320-20)), -- Test result forwarding src1
			21 => X"ffffffff", --ins65J(jl, r31, 4*(350-21)), -- Test result forwarding src0
			22 => insNOP,--ins65J(jl, r31, 4*(380-22)), -- Test 0+1 forwarding 
			23 => ins65J(jz, r0, 4* (-20)),
			
			-- On expception
			-- @256
			64 => insNOP, --		X"ffffffff",  -- == 256/4 -> exc handler
			65 => insNOP,
			66 => ins655655(ext2, r20, 0, mfc, 0, 2), -- 2: ELR
			67 => ins655655(ext2, r21, 0, mfc, 0, 4), -- 4: Exc saved state
			68 => ins655655(ext2, 0, r21, mtc, 1, 0),   -- 1: current state
			69 => ins655655(ext1, r0, r0, jzR, r20, 0),	-- Jump to saved link address	
			
			-- On interrupt
			-- @512
			128 => insNOP,
			129 => insNOP,	
			130 => ins655655(ext2, r20, 0, mfc, 0, 3), -- 3: ILR
			131 => ins655655(ext2, r21, 0, mfc, 0, 5), -- 5: Int saved state
			132 => ins655655(ext2, 0, r21, mtc, 1, 0),   -- 1: current state
			133 => ins655655(ext1, r0, r0, jzR, r20, 0),	-- Jump to saved link address	
			
			-- Clear registers
			-- @800
			200 => ins655H(addI, r0, r0, 0),
			201 => ins655H(addI, r1, r0, 0),
			202 => ins655H(addI, r2, r0, 0),
			203 => ins655H(addI, r3, r0, 0),
			204 => ins655H(addI, r4, r0, 0),
			205 => ins655H(addI, r5, r0, 0),
			206 => ins655H(addI, r6, r0, 0),
			207 => ins655H(addI, r7, r0, 0),
			208 => ins655H(addI, r8, r0, 0),
			209 => ins655H(addI, r9, r0, 0),
			210 => ins655H(addI, r10, r0, 0),
			211 => ins655H(addI, r11, r0, 0),
			212 => ins655H(addI, r12, r0, 0),
			213 => ins655H(addI, r13, r0, 0),
			214 => ins655H(addI, r14, r0, 0),
			215 => ins655H(addI, r15, r0, 0),
			216 => ins655H(addI, r16, r0, 0),
			217 => ins655H(addI, r17, r0, 0),
			218 => ins655H(addI, r18, r0, 0),
			219 => ins655H(addI, r19, r0, 0),
			220 => ins655H(addI, r20, r0, 0),
			221 => ins655H(addI, r21, r0, 0),
			222 => ins655H(addI, r22, r0, 0),
			223 => ins655H(addI, r23, r0, 0),
			224 => ins655H(addI, r24, r0, 0),
			225 => ins655H(addI, r25, r0, 0),
			226 => ins655H(addI, r26, r0, 0),
			227 => ins655H(addI, r27, r0, 0),
			228 => ins655H(addI, r28, r0, 0),
			229 => ins655H(addI, r29, r0, 0),
			230 => ins655H(addI, r30, r0, 0),
			231 => ins655H(addI, r31, r0, 0),
			232 => insRET, -- return
			
			-- Store registers in mem (word*)0:31
			-- @940
			240 => ins6556X(ext1, r0, r0, store, 0),
			241 => ins6556X(ext1, r1, r0, store, 1),
			242 => ins6556X(ext1, r2, r0, store, 2),
			243 => ins6556X(ext1, r3, r0, store, 3),
			244 => ins6556X(ext1, r4, r0, store, 4),
			245 => ins6556X(ext1, r5, r0, store, 5),
			246 => ins6556X(ext1, r6, r0, store, 6),
			247 => ins6556X(ext1, r7, r0, store, 7),
			248 => ins6556X(ext1, r8, r0, store, 8),
			249 => ins6556X(ext1, r9, r0, store, 9),
			250 => ins6556X(ext1, r10, r0, store, 10),
			251 => ins6556X(ext1, r11, r0, store, 11),
			252 => ins6556X(ext1, r12, r0, store, 12),
			253 => ins6556X(ext1, r13, r0, store, 13),
			254 => ins6556X(ext1, r14, r0, store, 14),
			255 => ins6556X(ext1, r15, r0, store, 15),			
			256 => ins6556X(ext1, r16, r0, store, 16),
			257 => ins6556X(ext1, r17, r0, store, 17),
			258 => ins6556X(ext1, r18, r0, store, 18),
			259 => ins6556X(ext1, r19, r0, store, 19),
			260 => ins6556X(ext1, r20, r0, store, 20),
			261 => ins6556X(ext1, r21, r0, store, 21),
			262 => ins6556X(ext1, r22, r0, store, 22),
			263 => ins6556X(ext1, r23, r0, store, 23),
			264 => ins6556X(ext1, r24, r0, store, 24),
			265 => ins6556X(ext1, r25, r0, store, 25),
			266 => ins6556X(ext1, r26, r0, store, 26),
			267 => ins6556X(ext1, r27, r0, store, 27),
			268 => ins6556X(ext1, r28, r0, store, 28),
			269 => ins6556X(ext1, r29, r0, store, 29),
			270 => ins6556X(ext1, r30, r0, store, 30),
			271 => ins6556X(ext1, r31, r0, store, 31),
			272 => insRET,
			
			-- Fill registers (from address in r4)
			-- @1120
			280 => ins6556X(ext1, r0, r4, load, 0),
			281 => ins6556X(ext1, r1, r4, load, 1),
			282 => ins6556X(ext1, r2, r4, load, 2),
			283 => ins6556X(ext1, r3, r4, load, 3),
			284 => ins6556X(ext1, r0, r4, load, 4), -- CAREFUL! to r0, because input arg is in r4
			285 => ins6556X(ext1, r5, r4, load, 5),
			286 => ins6556X(ext1, r6, r4, load, 6),
			287 => ins6556X(ext1, r7, r4, load, 7),
			288 => ins6556X(ext1, r8, r4, load, 8),
			289 => ins6556X(ext1, r9, r4, load, 9),
			290 => ins6556X(ext1, r10, r4, load, 10),
			291 => ins6556X(ext1, r11, r4, load, 11),
			292 => ins6556X(ext1, r12, r4, load, 12),
			293 => ins6556X(ext1, r13, r4, load, 13),
			294 => ins6556X(ext1, r14, r4, load, 14),
			295 => ins6556X(ext1, r15, r4, load, 15),			
			296 => ins6556X(ext1, r16, r4, load, 16),
			297 => ins6556X(ext1, r17, r4, load, 17),
			298 => ins6556X(ext1, r18, r4, load, 18),
			299 => ins6556X(ext1, r19, r4, load, 19),
			300 => ins6556X(ext1, r20, r4, load, 20),
			301 => ins6556X(ext1, r21, r4, load, 21),
			302 => ins6556X(ext1, r22, r4, load, 22),
			303 => ins6556X(ext1, r23, r4, load, 23),
			304 => ins6556X(ext1, r24, r4, load, 24),
			305 => ins6556X(ext1, r25, r4, load, 25),
			306 => ins6556X(ext1, r26, r4, load, 26),
			307 => ins6556X(ext1, r27, r4, load, 27),
			308 => ins6556X(ext1, r28, r4, load, 28),
			309 => ins6556X(ext1, r29, r4, load, 29),
			310 => ins6556X(ext1, r30, r4, load, 30),
			311 => ins6556X(ext1, r0, r4, load, 31), -- CAREFUL: to r0, because r31 has return address
			312 => ins6556X(ext1, r4, r4, load, 4), -- Finally reading into r4			
			313 => insRET,
			
			-- Test result forwarding as src1
			-- @1280
			320 => insNOP,
			321 => ins655H(addI, r1, r0, 300),
			322 => ins655655(ext0, r2, r0, addR, r1, 0),
			323 => ins655655(ext0, r3, r0, addR, r1, 0),
			324 => ins655655(ext0, r4, r0, addR, r1, 0),
			325 => ins655655(ext0, r5, r0, addR, r1, 0),
			326 => ins655655(ext0, r6, r0, addR, r1, 0),
			327 => ins655655(ext0, r7, r0, addR, r1, 0),			
			-- Now check that it was passed everywhere
			328 => insMOVE(r10, r1),
			329 => ins655H(subI, r10, r10, 300), -- result must be 0
			330 => ins65J(jnz, r10, 4*(1023 - 330)), -- if not, jump to illegal addr
			331 => insMOVE(r10, r2),
			332 => ins655H(subI, r10, r10, 300), -- result must be 0
			333 => ins65J(jnz, r10, 4*(1023 - 333)), -- if not, jump to illegal addr
			334 => insMOVE(r10, r3),
			335 => ins655H(subI, r10, r10, 300), -- result must be 0
			336 => ins65J(jnz, r10, 4*(1023 - 336)), -- if not, jump to illegal addr
			337 => insMOVE(r10, r4),
			338 => ins655H(subI, r10, r10, 300), -- result must be 0
			339 => ins65J(jnz, r10, 4*(1023 - 339)), -- if not, jump to illegal addr
			340 => insMOVE(r10, r5),
			341 => ins655H(subI, r10, r10, 300), -- result must be 0
			342 => ins65J(jnz, r10, 4*(1023 - 342)), -- if not, jump to illegal addr
			343 => insMOVE(r10, r6),
			344 => ins655H(subI, r10, r10, 300), -- result must be 0
			345 => ins65J(jnz, r10, 4*(1023 - 345)), -- if not, jump to illegal addr
			346 => insMOVE(r10, r7),
			347 => ins655H(subI, r10, r10, 300), -- result must be 0
			348 => ins65J(jnz, r10, 4*(1023 - 348)), -- if not, jump to illegal addr
			349 => insRET,
			
			-- Test forwarding as src0
			-- @1400
			350 => insNOP,
			351 => ins655H(addI, r11, r0, 400),
			352 => ins655655(ext0, r12, r11, addR, r0, 0),
			353 => ins655655(ext0, r13, r11, addR, r0, 0),
			354 => ins655655(ext0, r14, r11, addR, r0, 0),
			355 => ins655655(ext0, r15, r11, addR, r0, 0),
			356 => ins655655(ext0, r16, r11, addR, r0, 0),
			357 => ins655655(ext0, r17, r11, addR, r0, 0),
			-- Now check that it was passed everywhere
			358 => insMOVE(r10, r11),
			359 => ins655H(subI, r10, r10, 400), -- result must be 0
			360 => ins65J(jnz, r10, 4*(1023 - 360)), -- if not, jump to illegal addr
			361 => insMOVE(r10, r12),
			362 => ins655H(subI, r10, r10, 400), -- result must be 0
			363 => ins65J(jnz, r10, 4*(1023 - 363)), -- if not, jump to illegal addr
			364 => insMOVE(r10, r13),
			365 => ins655H(subI, r10, r10, 400), -- result must be 0
			366 => ins65J(jnz, r10, 4*(1023 - 366)), -- if not, jump to illegal addr
			367 => insMOVE(r10, r14),
			368 => ins655H(subI, r10, r10, 400), -- result must be 0
			369 => ins65J(jnz, r10, 4*(1023 - 369)), -- if not, jump to illegal addr
			370 => insMOVE(r10, r15),
			371 => ins655H(subI, r10, r10, 400), -- result must be 0
			372 => ins65J(jnz, r10, 4*(1023 - 372)), -- if not, jump to illegal addr
			373 => insMOVE(r10, r16),
			374 => ins655H(subI, r10, r10, 400), -- result must be 0
			375 => ins65J(jnz, r10, 4*(1023 - 375)), -- if not, jump to illegal addr
			376 => insMOVE(r10, r17),
			377 => ins655H(subI, r10, r10, 400), -- result must be 0
			378 => ins65J(jnz, r10, 4*(1023 - 378)), -- if not, jump to illegal addr
			379 => insRET,
			
			-- Test forwarding for 2 args
			-- @1520
			380 => insSET(r1,   91),
			381 => insSET(r2, 1002),
			382 => ins655655(ext0, r3, r1, addR, r2, 0),
			383 => ins655655(ext0, r4, r1, addR, r2, 0),
			384 => ins655655(ext0, r5, r4, addR, r1, 0), -- r4 + r1 = 2*r1 + r2 = 1184
			385 => ins655655(ext0, r6, r1, addR, r2, 0), 
			386 => ins655655(ext0, r7, r4, addR, r1, 0), -- r4 + r1 again
			387 => ins655655(ext0, r8, r1, addR, r2, 0),
			-- Now check
			388 => insMOVE(r10, r3),
			389 => ins655H(subI, r10, r10, 1093), -- result must be 0
			390 => ins65J(jnz, r10, 4*(1023 - 390)), -- if not, jump to illegal addr			
			391 => insMOVE(r10, r4),
			392 => ins655H(subI, r10, r10, 1093), -- result must be 0
			393 => ins65J(jnz, r10, 4*(1023 - 393)),
			394 => insMOVE(r10, r5),
			395 => ins655H(subI, r10, r10, 1184), -- result must be 0
			396 => ins65J(jnz, r10, 4*(1023 - 396)),
			397 => insMOVE(r10, r6),
			398 => ins655H(subI, r10, r10, 1093), -- result must be 0
			399 => ins65J(jnz, r10, 4*(1023 - 399)),			
			400 => insMOVE(r10, r7),
			401 => ins655H(subI, r10, r10, 1184), -- result must be 0
			402 => ins65J(jnz, r10, 4*(1023 - 402)), -- if not, jump to illegal addr			
			403 => insMOVE(r10, r8),
			404 => ins655H(subI, r10, r10, 1093), -- result must be 0
			405 => ins65J(jnz, r10, 4*(1023 - 405)),
			406 => insRET,
			
			
			others => insERROR -- undefined
		);
	
end ProgramCode4;



package body ProgramCode4 is


 
end ProgramCode4;
