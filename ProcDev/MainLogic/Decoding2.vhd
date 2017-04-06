--
--	Package File Template
--

--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
  
use work.ProcBasicDefs.all;
use work.ProcInstructionsNew.all;

use work.NewPipelineData.all;

package Decoding2 is
	
		type InsFieldNew is (opcode, opcont, none,  qa, qb, qc, qd, zero, one, 
									leftImm, imm10, imm16, imm21, imm26
									);		
	
		type InsFieldTableNew is array (InsFieldNew) of integer;
		type InsFieldTableNewW is array (InsFieldNew) of word;	
	
		subtype QuintetSrc is InsFieldNew range none to one; 	
	
		type ImmFormat is (imm26, imm21, imm16, imm10, none);
	
		-- TODO: Standardize jump conditions and handling them
		constant COND_NONE: slv5 := "11111";
		constant COND_Z: slv5 := "00000";
		constant COND_NZ: slv5 := "00001";


		type QuintetArgName is (d0, d1, s0, s1, s2, c0, c1);
		type QuintetSrcArray is array (QuintetArgName range d0 to c1) of QuintetSrc; 
		type QuintetValArray is array (QuintetArgName range d0 to c1) of slv5;
		type QuintetSelect is array (QuintetArgName range d0 to c1) of std_logic;

		type ArgFormatStruct is record
			quintets: 	QuintetSrcArray;
			immSize: 	ImmFormat;
			immSign: 	std_logic;
			hasLeftImm: std_logic;
			leftImmSign: std_logic;
		end record;

		-- result would be like this:
		type OpFieldStruct is record
			opcode:			ProcOpcode;
			opcont: 			ProcOpcont;	
				unit:		ExecUnit;
				func:		ExecFunc;
			quintetSel:		QuintetSelect;
			quintetValues: QuintetValArray;
			hasLeftImm: 	std_logic;
			leftImm: 		word;
			hasImm: 			std_logic;
			imm: 				word;
		end record;		

				type OpFieldStructW is record
					opcode:			slv6;
					opcont: 			slv6;	
						unit:		ExecUnit;
						func:		ExecFunc;
					quintetSel:		QuintetSelect;
					quintetValues: QuintetValArray;
					hasLeftImm: 	std_logic;
					leftImm: 		word;
					hasImm: 			std_logic;
					imm: 				word;
				end record;	


		type InsDefNew is record
			opcd: ProcOpcode;
			opct: ProcOpcont;
			unit: ExecUnit;
			func: ExecFunc;
			fmt:	ArgFormatStruct;	
		end record;
		
		type InsDefArrayNew is array (natural range <>) of InsDefNew;

		
		type InsDefNewW is record
			opcd: slv6;
			opct: slv6;
			unit: ExecUnit;
			func: ExecFunc;
			fmt:	ArgFormatStruct;	
		end record;
		
		type InsDefArrayNewW is array (natural range <>) of InsDefNewW;		
		
		function parseWordNewW(w: word) return InsFieldTableNewW;

			constant fmtUndef: ArgFormatStruct :=
					((others=>none), none, '0','0','0');

			constant fmtImm: ArgFormatStruct := 
					((d0=>qa, d1=>none, s0=>qb, s1=>none, s2=>none, c0=>none, c1=>none), imm16, '0', '0', '0');
			constant fmtReg2: ArgFormatStruct := 
					((d0=>qa, d1=>none, s0=>qb, s1=>qc, s2=>none, c0=>none, c1=>none), none, '0', '0', '0');
			constant fmtReg3: ArgFormatStruct := 
					((d0=>qa, d1=>none, s0=>qb, s1=>qc, s2=>qd, c0=>none, c1=>none), none, '0', '0', '0');					

			constant fmtLoadImm: ArgFormatStruct := 
					((d0=>qa, d1=>none, s0=>qb, s1=>none, s2=>none, c0=>none, c1=>none), imm10, '1', '0', '0');
			constant fmtStoreImm: ArgFormatStruct := 
					((d0=>zero, d1=>none, s0=>qb, s1=>none, s2=>qa, c0=>none, c1=>none), imm10, '1', '0', '0');					

			-- Careful! In c1 we have to put condition! Temporary: zero Z, one NZ (but wont translate properly!)
				--								Let 'none' mean jumping always (to distinguish certain from conditional)
			constant fmtJumpLong: ArgFormatStruct := 
					((d0=>zero, d1=>none, s0=>zero, s1=>none, s2=>none, c0=>none, c1=> none), imm26, '1', '0', '0');					
			constant fmtJumpLink: ArgFormatStruct := 
					((d0=>qa, d1=>none, s0=>zero, s1=>none, s2=>none, c0=>none, c1=> none), imm21, '1', '0', '0');					
			constant fmtJumpCondZ: ArgFormatStruct := 
					((d0=>zero, d1=>none, s0=>qa, s1=>none, s2=>none, c0=>none, c1=> zero), imm21, '1', '0', '0');					
			constant fmtJumpCondNZ: ArgFormatStruct := 
					((d0=>zero, d1=>none, s0=>qa, s1=>none, s2=>none, c0=>none, c1=> one), imm21, '1', '0', '0');					
			constant fmtJumpRZ: ArgFormatStruct := 
					((d0=>qa, d1=>none, s0=>qb, s1=>qc, s2=>none, c0=>none, c1=> zero), none, '0', '0', '0');					
			constant fmtJumpRNZ: ArgFormatStruct := 
					((d0=>qa, d1=>none, s0=>qb, s1=>qc, s2=>none, c0=>none, c1=> one), none, '0', '0', '0');	
					
			constant fmtShiftC: ArgFormatStruct :=		
					((d0=>qa, d1=>none, s0=>qb, s1=>none, s2=>none, c0=>qc, c1=>none), none, '0', '0', '0');					
			
			constant fmtNoArgs: ArgFormatStruct :=		
					((others=>none), none, '0', '0', '0');			
			
				constant fmtMFC_TEMP: ArgFormatStruct := 
					((d0=>qa, c1=>qd, others=>none), none, '0','0','0');
				constant fmtMTC_TEMP: ArgFormatStruct := 
					((s0=>qb, c0=>qc, others=>none), none, '0','0','0');			
		
		constant undefInsDef: InsDefNewW := (opcode2slv(ext2), opcont2slv(ext2, undef),
																				System, sysUndef, fmtUndef);
		
		constant decodeTableNew: InsDefArrayNew(0 to 25) := (
				0 => (andI, none, Alu, logicAnd, fmtImm),
				1 => (orI,  none, Alu, logicOr,  fmtImm),
				2 => (addI, none, Alu, arithAdd, fmtImm),
				3 => (subI, none, Alu, arithSub, fmtImm),
				
				4 => (ext1, load,	Memory,load,	fmtLoadImm),
				5 => (ext1, store,Memory,store,	fmtStoreImm),

				6 => (j, 	none, Jump, jump, fmtJumpLong),
				7 => (jl, 	none, Jump, jump,	fmtJumpLink),
				8 => (jz, 	none, Jump, jump, fmtJumpCondZ),
				9 => (jnz, 	none, Jump, jump, fmtJumpCondNZ),
				
				10=> (ext0, muls, Mac, mulS, fmtReg3),
				11=> (ext0, mulu, Mac, mulU, fmtReg3),

				12 => (ext0, shlC,  Alu,  logicShl,	fmtShiftC),
				13 => (ext0, shrlC, Alu,  logicShrl,fmtShiftC),
				14 => (ext0, shraC, Alu,  arithShra,fmtShiftC), 

				15=> (ext2, mfc,	System, sysMFC, fmtMFC_TEMP),
				16=> (ext2, mtc, 	System, sysMTC, fmtMTC_TEMP),		
							
				17=> (ext0, addR, Alu, arithAdd, fmtReg2),
				18=> (ext0, subR, Alu, arithSub, fmtReg2),
				19=> (ext0, andR, Alu, logicAnd, fmtReg2),
				20=> (ext0, orR,  Alu, logicOr,  fmtReg2),
					
				21=> (ext1, jzR,  Jump, jump, fmtJumpRZ),
				22=> (ext1, jnzR, Jump, jump, fmtJumpRNZ),

					23 => (ext1, loadFP,		Memory,load,	fmtLoadImm),
					24 => (ext1, storeFP,	Memory,store,	fmtStoreImm),
				
				others => (ext2, undef, System, sysUndef, fmtUndef)
				);
		
			function toTableW(dt: InsDefArrayNew) return InsDefArrayNewW;		
			constant decodeTableNewW: InsDefArrayNewW(decodeTableNew'range) := toTableW(decodeTableNew);
		
		
		function TEMP_getLargeTable(decodeTableNewW: InsDefArrayNewW) return InsDefArrayNewW;
		
		constant TEMP_largeTable: InsDefArrayNewW(0 to 4095) := TEMP_getLargeTable(decodeTableNewW);
		
		function TEMP_find(opcd, opct: slv6) return InsDefNewW;
		
			function getOpFields(w: word) return OpFieldStruct;

			-- WARNING: classInfo may be actually created at later part, here being just a placeholder 
			procedure ofsInfo(ofs: in OpFieldStruct;
									op: out BinomialOp;
									ci: out InstructionClassInfo;
									ca: out InstructionConstantArgs;
									va: out InstructionVirtualArgs;
									vda: out InstructionVirtualDestArgs);
		
end Decoding2;


package body Decoding2 is
	 
	procedure ofsInfo(ofs: in OpFieldStruct;
							op: out BinomialOp;
							ci: out InstructionClassInfo;
							ca: out InstructionConstantArgs;
							va: out InstructionVirtualArgs;
							vda: out InstructionVirtualDestArgs)
	is		
		variable num: integer;
	begin		
		vda.sel(0) := ofs.quintetSel(d0);	
		vda.d0 := ofs.quintetValues(d0);
		
		va.sel := ofs.quintetSel(s0) & ofs.quintetSel(s1) & ofs.quintetSel(s2);
		va.s0 := ofs.quintetValues(s0);
		va.s1 := ofs.quintetValues(s1);
		va.s2 := ofs.quintetValues(s2);
		
		ca.immSel := ofs.hasImm;
		ca.imm := ofs.imm;
		ca.c0 := ofs.quintetValues(c0);
		ca.c1 := ofs.quintetValues(c1);

	--				-- CAREFUL! Here e use c1 to store condition
	--				if idef.unit = Jump then
	--					res.cond := ConditionType'val(1 + slv2u(ofs.quintetValues(c1)));
	--							--	report integer'image(
	--				else
	--					res.cond := unknown;
	--				end if;	

		op := BinomialOp'(ofs.unit, ofs.func); 					

		-- WARNING: classInfo will be determined by HW-specific part.
	end procedure;

		------------------------------------------
		function e32(v: std_logic_vector) return word is
			variable res: word := (others=>'0');
			variable a, b: integer;
		begin
			a := v'high;
			b := v'low;
			res(a-b downto 0) := v;
			return res;
		end function;
		

		function parseWordNewW(w: word) return InsFieldTableNewW is
			variable res: InsFieldTableNewW := (others=>(others=>'0'));
		begin
			res := (none => (others=>'1'),
					  opcode => e32(w(31 downto 26)),
					  opcont => e32(w(15 downto 10)),
					  leftImm => e32(w(26 downto 16)),
					  --xr => slv2u(w(9 downto 0)),
					  qa => e32(w(25 downto 21)),
					  qb => e32(w(20 downto 16)),
					  qc => e32(w(9 downto 5)),
					  qd => e32(w(4 downto 0)),
					  imm26 => w,
					  imm21 => e32(w(20 downto 0)),
					  imm16 => e32(w(15 downto 0)),
					  imm10 => e32(w(9 downto 0)),
					  zero => (others=>'0'),
					  one => (0=>'1', others=>'0')
					  );
			return res;
		end function;
		


		function getOpFieldStructW(tab: InsFieldTableNewW;-- fmt: ArgFormatStruct; 
											idef: InsDefNewW)
		return OpFieldStruct is
			variable res: OpFieldStruct;
			variable fmt: ArgFormatStruct := idef.fmt;
			variable iw: word := tab(imm26);
		begin
			res.opcode := slv2opcode(tab(opcode)(5 downto 0));
			res.opcont := slv2opcont(tab(opcode)(5 downto 0), tab(opcont)(5 downto 0));

			-- Dispatch quintets
			for i in d0 to c1 loop
				if fmt.quintets(i) = none then
					res.quintetSel(i) := '0';
					res.quintetValues(i) := "00000";
				elsif fmt.quintets(i) = zero then
					res.quintetSel(i) := '1';
					res.quintetValues(i) := "00000";
				elsif fmt.quintets(i) = one then	
					res.quintetSel(i) := '1';
					res.quintetValues(i) := "00001";					
				else
					res.quintetSel(i) := '1';
					res.quintetValues(i) := tab(fmt.quintets(i))(4 downto 0);
				end if;	
			end loop;
			
			-- Handle imm value (and leftImm)		
			res.imm := iw;
			case fmt.immSize is
				when none =>
					res.hasImm := '0';
					res.imm := (others => '0');
				when imm10 =>
					res.hasImm := '1';
					res.imm(31 downto 10) := (others => iw(9) and fmt.immSign);	
				when imm16 =>
					res.hasImm := '1';		
					res.imm(31 downto 16) := (others => iw(15) and fmt.immSign);
				when imm21 =>
					res.hasImm := '1';	
					res.imm(31 downto 21) := (others => iw(20) and fmt.immSign);
				when imm26 =>
					res.hasImm := '1';	
					res.imm(31 downto 26) := (others => iw(25) and fmt.immSign);					
				when others =>
					report "bad imm format specification" severity error;
			end case;
			
			if fmt.hasLeftImm = '1' then
				res.hasLeftImm := '1';
				iw := tab(leftImm);
				res.leftImm := iw;
				res.leftImm(31 downto 10) := (others => iw(10) and fmt.leftImmSign);
			else
				res.hasLeftImm := '0';
				res.leftImm := (others => '0');
			end if;
			
			res.unit := idef.unit;
			res.func := idef.func;
			
			return res;
		end function;

		
		function findInstructionNewW(opcode, opcont: slv6) return integer is
			variable tempInt: integer;
		begin
			tempInt := -- -1;
							decodeTableNewW'right;
			for i in decodeTableNewW'range loop
				if 		decodeTableNewW(i).opcd = opcode 
					and (not hasOpcont(slv2opcode(opcode)) or (decodeTableNewW(i).opct = opcont))
					-- If not hasOpcont, maybe just compare if none is really none, so no additional code needed?
				--	and (not hasOpcont(idef.opcd) or  
				then
					tempInt := i;
					exit;
				end if;
			end loop;
			return tempInt;
		end function;

		function findInstructionDirect(opcode, opcont: slv6) return InsDefNewW is
			variable res: InsDefNewW := undefInsDef;
		begin
			for i in decodeTableNewW'range loop
				if 		decodeTableNewW(i).opcd = opcode 
					and (not hasOpcont(slv2opcode(opcode)) or (decodeTableNewW(i).opct = opcont))
					-- If not hasOpcont, maybe just compare if none is really none, so no additional code needed?
				--	and (not hasOpcont(idef.opcd) or  
				then
					res := decodeTableNewW(i);
					exit;
				end if;
			end loop;
			return res;
		end function;		


		function getOpFields(w: word) return OpFieldStruct is
			variable num: integer;
			variable parts: InsFieldTableNewW;
			variable ofs: OpFieldStruct;
			variable opcd: slv6; --ProcOpcode;
			variable opct: slv6; --ProcOpcont;
			variable match: InsDefNewW;			
		begin
			parts := parseWordNewW(w);
			opcd := parts(opcode)(5 downto 0);
			opct := parts(opcont)(5 downto 0);	
						
			if false then
				-- This activates "large table" decoding
				match := TEMP_find(opcd, opct);
				ofs := getOpFieldStructW(parts, match);
			else
				num := findInstructionNewW(opcd, opct);
				match := decodeTableNewW(num);
				ofs := getOpFieldStructW(parts, decodeTableNewW(num));						
			end if;

			return ofs;
		end function;


		function toTableW(dt: InsDefArrayNew) return InsDefArrayNewW is
			variable res: InsDefArrayNewW(dt'range);
		begin
			for i in dt'range loop
				res(i) := (opcode2slv(dt(i).opcd), opcont2slv(dt(i).opcd, dt(i).opct),
								dt(i).unit, dt(i).func, dt(i).fmt);
			end loop;		
			return res;
		end function;


function TEMP_getLargeTable(decodeTableNewW: InsDefArrayNewW) return InsDefArrayNewW is
	variable res: InsDefArrayNewW(0 to 4095) := (others => undefInsDef);
	variable currentDef: InsDefNewW := undefInsDef;
	variable fullOpcode: std_logic_vector(0 to 11);
	variable index: natural := 0;
begin
	for i in decodeTableNewW'range loop
		currentDef := decodeTableNewW(i);
		fullOpcode(0 to 5) := currentDef.opcd;
		-- CAREFUL! If this opcode has no opcont, all possible bits on opcont position must lead to 
		--				the same definition!
		if hasOpcont(slv2opcode(currentDef.opcd)) then
			fullOpcode(6 to 11) := currentDef.opct;
			index := slv2u(fullOpcode);
			res(index) := currentDef;		
		else 
			for j in 0 to 63 loop
				fullOpcode(6 to 11) := i2slv(j, 6);
				index := slv2u(fullOpcode);
				res(index) := currentDef;				
			end loop;
		end if;
	end loop;
	
	return res;
end function;


function TEMP_find(opcd, opct: slv6) return InsDefNewW is
	variable fullOpcode: std_logic_vector(0 to 11);
	variable index: natural := 0;	
begin
	fullOpcode(0 to 5) := opcd;
	fullOpcode(6 to 11) := opct;
	index := slv2u(fullOpcode);
	return TEMP_largeTable(index);
end function;


end Decoding2;
