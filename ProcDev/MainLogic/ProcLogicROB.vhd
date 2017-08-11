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


use work.ProcBasicDefs.all;
use work.Helpers.all;

use work.ProcInstructionsNew.all;
use work.NewPipelineData.all;

use work.TEMP_DEV.all;
use work.GeneralPipeDev.all;

use work.BasicCheck.all;

use std.textio.all;


package ProcLogicROB is

-- pragma synthesis off
procedure logROBImplem(sd, sdl: StageDataROB; fr: FlowResponseBuffer;
								filename: string; desc: string);
-- pragma synthesis on

procedure logROB(signal sd, sdl: StageDataROB; fr: FlowResponseBuffer);

procedure checkROB(sd, sdn: StageDataROB; flowDrive: FlowDriveBuffer; flowResponse: FlowResponseBuffer);


function groupCompleted(insVec: StageDataMulti) return std_logic;

function stageROBNext(content: StageDataROB; fullMask: std_logic_vector; newContent: StageDataMulti;
		nFull: integer; sending, receiving: std_logic)
return StageDataROB;

function stageROBNext_Circular(content: StageDataROB; fullMask: std_logic_vector; newContent: StageDataMulti;
		nFull: integer; sending, receiving: std_logic; ind: SmallNumber)
return StageDataROB;


function setCompleted(content: StageDataROB; refTag: SmallNumber;
							execEnds: InstructionStateArray; execReady: std_logic_vector;
							execEnds2: InstructionStateArray; execReady2: std_logic_vector;
							killSignal: std_logic; fromCommitted: std_logic)							
return StageDataROB;


function setCompleted_Circular(content: StageDataROB; refTag: SmallNumber;
							execEnds: InstructionStateArray; execReady: std_logic_vector;
							execEnds2: InstructionStateArray; execReady2: std_logic_vector;
							killSignal: std_logic; fromCommitted: std_logic)							
return StageDataROB;


--													CAREFUL: tags in future change to InsTag
function getNumKilled(full: SmallNumber; tagCausing, tagRef: SmallNumber; evt: std_logic)
return SmallNumber is
	variable res: SmallNumber := (others => '0');
		variable num: SmallNumber := (others => '0');
begin
	if evt = '1' then
		num := addSN(full, getTagHighSN(tagRef));
		num := subSN(num, getTagHighSN(tagCausing));
		num(SMALL_NUMBER_SIZE-1 downto SMALL_NUMBER_SIZE-LOG2_PIPE_WIDTH) := (others => '0');
	end if;
	res := num;		
	return res;
end function;


		function calcGroupSelect(selTag, refTag: SmallNumber) return std_logic_vector is
			variable res: std_logic_vector(0 to ROB_SIZE-1) := (others => '0');
			
			variable vs, vr, ve: SmallNumber := (others => '0');
		begin
			vs(SMALL_NUMBER_SIZE-1-LOG2_PIPE_WIDTH downto 0) := selTag(SMALL_NUMBER_SIZE-1 downto LOG2_PIPE_WIDTH);
			vr(SMALL_NUMBER_SIZE-1-LOG2_PIPE_WIDTH downto 0) := refTag(SMALL_NUMBER_SIZE-1 downto LOG2_PIPE_WIDTH);

			-- Formula:  indH - indRef - 1 = indH + (-1 - indRef) = indH + not indRef
			ve := addSN(vs, not vr);
			-- CAREFUL: This is to enable comparison in wrapping arithmetic 
			ve(ve'high downto ve'high - LOG2_PIPE_WIDTH) := (others => '0');

			for i in 0 to ROB_SIZE-1 loop
				if i2slv(i, SMALL_NUMBER_SIZE) = ve then
					res(i) := '1';
					exit;
				end if;
			end loop;
			
			return res;
		end function;


		function calcGroupSelectCircular(selTag, refTag: SmallNumber) return std_logic_vector is
			variable res: std_logic_vector(0 to ROB_SIZE-1) := (others => '0');
				constant MASK_NUM: SmallNumber := i2slv(ROB_SIZE-1, SMALL_NUMBER_SIZE);
			variable vs, vr, ve: SmallNumber := (others => '0');
		begin
			vs(SMALL_NUMBER_SIZE-1-LOG2_PIPE_WIDTH downto 0) := selTag(SMALL_NUMBER_SIZE-1 downto LOG2_PIPE_WIDTH);
			vr(SMALL_NUMBER_SIZE-1-LOG2_PIPE_WIDTH downto 0) := refTag(SMALL_NUMBER_SIZE-1 downto LOG2_PIPE_WIDTH);

				vs := vs and MASK_NUM;
				vr := vr and MASK_NUM;

			-- Formula:  indH - indRef - 1 = indH + (-1 - indRef) = indH + not indRef
			ve := addSN(vs, not vr);
			-- CAREFUL: This is to enable comparison in wrapping arithmetic 
			ve(ve'high downto ve'high - LOG2_PIPE_WIDTH) := (others => '0');
				ve := ve and MASK_NUM;
				
				
			for i in 0 to ROB_SIZE-1 loop
				if i2slv(i, SMALL_NUMBER_SIZE) = ve then
					res(i) := '1';
					exit;
				end if;
			end loop;
			
			return res;
		end function;


function getSlotFromROB(stageData: StageDataROB; slot: SmallNumber) return StageDataMulti is
	variable res: StageDataMulti := DEFAULT_STAGE_DATA_MULTI;
	variable ind: SmallNumber := (others => '0');
	constant MASK_NUM: SmallNumber := i2slv(ROB_SIZE-1, SMALL_NUMBER_SIZE);
begin
	ind := slot and MASK_NUM;
	res := stageData.data(slv2u(ind));
	return res;
end function;

function getBitFromROBMask(stageData: StageDataROB; slot: SmallNumber) return std_logic is
	variable res: std_logic := '0';
	variable ind: SmallNumber := (others => '0');
	constant MASK_NUM: SmallNumber := i2slv(ROB_SIZE-1, SMALL_NUMBER_SIZE);
begin
	ind := slot and MASK_NUM;
	res := stageData.fullMask(slv2u(ind));
	return res;
end function;

function getBitFromROBMaskPre(stageData: StageDataROB; slot: SmallNumber) return std_logic is
	variable res: std_logic := '0';
	variable ind: SmallNumber := (others => '0');
	constant MASK_NUM: SmallNumber := i2slv(ROB_SIZE-1, SMALL_NUMBER_SIZE);
	constant ONE: SmallNumber := i2slv(1, SMALL_NUMBER_SIZE);
begin
	ind := subSN(slot, ONE);
	ind := ind and MASK_NUM;
	res := stageData.fullMask(slv2u(ind));
	return res;
end function;



end ProcLogicROB;



package body ProcLogicROB is

function groupCompleted(insVec: StageDataMulti) return std_logic is
begin
	for i in 0 to PIPE_WIDTH-1 loop
		if insVec.fullMask(i) = '1' and 
				(insVec.data(i).controlInfo.completed = '0'
			or	 insVec.data(i).controlInfo.completed2 = '0')
		then
			return '0'; 
		end if;
	end loop;
	return '1';
end function;


function stageROBNext(content: StageDataROB; fullMask: std_logic_vector; newContent: StageDataMulti;
		nFull: integer; sending, receiving: std_logic)
return StageDataROB is
	variable res: StageDataROB := (fullMask => (others => '0'), 
														data => (others => DEFAULT_STAGE_DATA_MULTI));
	constant CLEAR_EMPTY_SLOTS_ROB: boolean := false;
	variable newFull: integer := nFull;
	variable bPrev, bCurrent: std_logic := '0';
	variable basicFullMask: std_logic_vector(0 to ROB_SIZE-1) := fullMask;
begin
	-- CAREFUL: even when not clearing empty slots, result tags probably should be cleared!
	--				It's to prevent reading of fake results from empty slots
	res := content;
		
	if sending = '1' then	
		-- shift by 1
		res.fullMask(0 to ROB_SIZE-2) := res.fullMask(1 to ROB_SIZE-1);
		res.fullMask(ROB_SIZE-1) := '0'; -- CAREFUL, TODO: This may be incorrect (?) if we allow receiving
													-- 					into full buffer when it's sending...											
		basicFullMask(0 to ROB_SIZE-2) := basicFullMask(1 to ROB_SIZE-1);											
		basicFullMask(ROB_SIZE-1) := '0';
			
		res.data(0 to ROB_SIZE-2) := res.data(1 to ROB_SIZE-1);		
		newFull := nFull-1;
	end if;
		
	-- Accept new content
	if receiving = '1' then
		bPrev := '1';
		for i in 0 to ROB_SIZE-1 loop	-- Trick to avoid transitional out of bounds value of index
			bCurrent := basicFullMask(i);
			if (bCurrent = '0' and bPrev = '1') then
				res.fullMask(i) := '1';
				res.data(i) := newContent;
			end if;
			bPrev := bCurrent;
		end loop;
		
		newFull := newFull + 1;				
	end if;
	
	-- CAREFUL! Clearing tags in empty slots, to avoid incorrect info about available results!
	for i in 0 to res.fullMask'length-1 loop
		if res.fullMask(i) = '0' then
			for j in 0 to PIPE_WIDTH-1 loop
				res.data(i).data(j).physicalDestArgs.d0 := (others => '0');
			end loop;	
		end if;	
	end loop;
	
	if CLEAR_EMPTY_SLOTS_ROB then	
		for i in 0 to content.data'length-1 loop -- to livingContent'length - nOut - 1 loop
			if i >= newFull then
				res.data(i) := DEFAULT_STAGE_DATA_MULTI;	
			end if;		
		end loop;
	end if;	
	
	return res;		
end function;



function stageROBNext_Circular(content: StageDataROB; fullMask: std_logic_vector; newContent: StageDataMulti;
		nFull: integer; sending, receiving: std_logic; ind: SmallNumber)
return StageDataROB is
	variable res: StageDataROB := (fullMask => (others => '0'), 
														data => (others => DEFAULT_STAGE_DATA_MULTI));
	constant CLEAR_EMPTY_SLOTS_ROB: boolean := false;
	variable newFull: integer := nFull;
	variable bPrev, bCurrent: std_logic := '0';
	variable basicFullMask: std_logic_vector(0 to ROB_SIZE-1) := fullMask;
begin
	-- CAREFUL: even when not clearing empty slots, result tags probably should be cleared!
	--				It's to prevent reading of fake results from empty slots
	res := content;
		
	if sending = '1' then	
		-- shift by 1
		res.fullMask(0 to ROB_SIZE-2) := res.fullMask(1 to ROB_SIZE-1);
		res.fullMask(ROB_SIZE-1) := '0'; -- CAREFUL, TODO: This may be incorrect (?) if we allow receiving
													-- 					into full buffer when it's sending...											
		basicFullMask(0 to ROB_SIZE-2) := basicFullMask(1 to ROB_SIZE-1);											
		basicFullMask(ROB_SIZE-1) := '0';
			
		res.data(0 to ROB_SIZE-2) := res.data(1 to ROB_SIZE-1);		
		newFull := nFull-1;
	end if;
		
	-- Accept new content
	if receiving = '1' then
		--bPrev := basicFullMask(ROB_SIZE-1); -- CAREFUL: difference from basic function version
		for i in 0 to ROB_SIZE-1 loop	-- Trick to avoid transitional out of bounds value of index
			--bCurrent := basicFullMask(i);
			if --(bCurrent = '0' and bPrev = '1') then
				i2slv(i, SMALL_NUMBER_SIZE) = ind then
				
				res.fullMask(i) := '1';
				res.data(i) := newContent;
			end if;
			bPrev := bCurrent;
		end loop;
		
		newFull := newFull + 1;				
	end if;
	
	-- CAREFUL! Clearing tags in empty slots, to avoid incorrect info about available results!
	for i in 0 to res.fullMask'length-1 loop
		if res.fullMask(i) = '0' then
			for j in 0 to PIPE_WIDTH-1 loop
				res.data(i).data(j).physicalDestArgs.d0 := (others => '0');
			end loop;	
		end if;	
	end loop;
	
	if CLEAR_EMPTY_SLOTS_ROB then	
		for i in 0 to content.data'length-1 loop -- to livingContent'length - nOut - 1 loop
			if i >= newFull then
				res.data(i) := DEFAULT_STAGE_DATA_MULTI;	
			end if;		
		end loop;
	end if;	
	
	return res;		
end function;


function setCompleted(content: StageDataROB; refTag: SmallNumber;
							execEnds: InstructionStateArray; execReady: std_logic_vector;
							execEnds2: InstructionStateArray; execReady2: std_logic_vector;
							killSignal: std_logic; fromCommitted: std_logic)							
return StageDataROB is
	variable res: StageDataROB := content;
		variable ihr, il, ih, ind: SmallNumber := (others => '0');
	constant CLEAR_EMPTY_SLOTS_ROB: boolean := false;	
	variable matched, TMP_elem: boolean := false;
	
	variable TMP_s0, TMP_s1: SmallNumber := (others => '0');
	
		variable groupSelect: std_logic_vector(0 to ROB_SIZE-1) := (others => '0');
		variable TMP_found: boolean := false;		
begin
	ihr := getTagHighSN(refTag);
	for i in 0 to execEnds'length-1 loop
		il := getTagLowSN(execEnds(i).groupTag);
		groupSelect := calcGroupSelect(execEnds(i).groupTag, refTag);			
		for j in 0 to ROB_SIZE-1 loop
			if groupSelect(j) = '1' and execReady(i) = '1' then	
				for k in 0 to PIPE_WIDTH-1 loop
					TMP_s0 := i2slv(k, SMALL_NUMBER_SIZE);
					if TMP_s0 = il then							
						if execEnds(i).controlInfo.hasException = '1' then
							TMP_elem := true;
								res.data(j).data(k).controlInfo.newEvent := '1'; --- !!!
							res.data(j).data(k).controlInfo.hasException := '1';
						end if;
						res.data(j).data(k).controlInfo.completed := '1';								
					end if;													
				end loop;
			end if;	
		end loop;
	end loop;

	-- CAREFUL: setting completed2
	for i in 0 to execEnds2'length-1 loop
		il := getTagLowSN(execEnds2(i).groupTag);
		groupSelect := calcGroupSelect(execEnds2(i).groupTag, refTag);				
		for j in 0 to ROB_SIZE-1 loop
			if groupSelect(j) = '1' and execReady2(i) = '1' then
				-----
				for k in 0 to PIPE_WIDTH-1 loop
					TMP_s0 := i2slv(k, SMALL_NUMBER_SIZE);
					if TMP_s0 = il then							
						if execEnds2(i).controlInfo.hasException = '1' then
							TMP_elem := true;
								res.data(j).data(k).controlInfo.newEvent := '1'; --- !!!
							res.data(j).data(k).controlInfo.hasException := '1';
						end if;
							
						if execEnds2(i).controlInfo.hasBranch = '1' then
							TMP_elem := true;
								res.data(j).data(k).controlInfo.newEvent := '1'; --- !!!
							res.data(j).data(k).controlInfo.hasBranch := '1';
						end if;
						
						res.data(j).data(k).controlInfo.completed2 := '1';								
					end if;						
				end loop;
			end if;
		end loop;	
	end loop;

	-- Propagate killed/squashed
			for j in 0 to ROB_SIZE-1 loop
				TMP_found := false;
				for k in 0 to PIPE_WIDTH-1 loop
					if TMP_found then
						if res.data(j).fullMask(k) = '1' then
							res.data(j).data(k).controlInfo.squashed := '1';
						end if;
						res.data(j).fullMask(k) := '0';
					end if;				
					if res.data(j).data(k).controlInfo.newEvent = '1' then
						-- CAREFUL: kill subsequent ones when this has excpetion or new branch, but not a branch 
						--				set in front pipe!
						res.data(j).data(k).controlInfo.newEvent := '0'; -- CAREFUL: clear to leave blank for late evts
						TMP_found := true;
					end if;
				end loop;
			end loop;

	if killSignal = '0' then
		return res;
	end if;

	if fromCommitted = '1' then
		matched := true;
	end if;
	
	for i in 0 to ROB_SIZE-1 loop
		-- For slots after the affected one
		if matched then
			res.fullMask(i) := '0';
			if CLEAR_EMPTY_SLOTS_ROB then
				res.data(i) := DEFAULT_STAGE_DATA_MULTI;
			end if;				
		end if;
			
		if groupSelect(i) = '1' then	
			matched := true;
		end if;
				
	end loop;
	
	return res;
end function;



function setCompleted_Circular(content: StageDataROB; refTag: SmallNumber;
							execEnds: InstructionStateArray; execReady: std_logic_vector;
							execEnds2: InstructionStateArray; execReady2: std_logic_vector;
							killSignal: std_logic; fromCommitted: std_logic)							
return StageDataROB is
	variable res: StageDataROB := content;
		variable ihr, il, ih, ind: SmallNumber := (others => '0');
	constant CLEAR_EMPTY_SLOTS_ROB: boolean := false;	
	variable matched, TMP_elem: boolean := false;
	
	variable TMP_s0, TMP_s1: SmallNumber := (others => '0');
	
		variable groupSelect: std_logic_vector(0 to ROB_SIZE-1) := (others => '0');
		variable TMP_found: boolean := false;
			variable refTag1: SmallNumber := (others => '0'); -- CAREFUL: must be -1 + tag of slot 0 
begin
	ihr := getTagHighSN(refTag);
	for i in 0 to execEnds'length-1 loop
		il := getTagLowSN(execEnds(i).groupTag);
		groupSelect := calcGroupSelectCircular(execEnds(i).groupTag, refTag1);			
		for j in 0 to ROB_SIZE-1 loop
			if groupSelect(j) = '1' and execReady(i) = '1' then	
				for k in 0 to PIPE_WIDTH-1 loop
					TMP_s0 := i2slv(k, SMALL_NUMBER_SIZE);
					if TMP_s0 = il then							
						if execEnds(i).controlInfo.hasException = '1' then
							TMP_elem := true;
								res.data(j).data(k).controlInfo.newEvent := '1'; --- !!!
							res.data(j).data(k).controlInfo.hasException := '1';
						end if;
						res.data(j).data(k).controlInfo.completed := '1';								
					end if;													
				end loop;
			end if;	
		end loop;
	end loop;

	-- CAREFUL: setting completed2
	for i in 0 to execEnds2'length-1 loop
		il := getTagLowSN(execEnds2(i).groupTag);
		groupSelect := calcGroupSelectCircular(execEnds2(i).groupTag, refTag1);				
		for j in 0 to ROB_SIZE-1 loop
			if groupSelect(j) = '1' and execReady2(i) = '1' then
				-----
				for k in 0 to PIPE_WIDTH-1 loop
					TMP_s0 := i2slv(k, SMALL_NUMBER_SIZE);
					if TMP_s0 = il then							
						if execEnds2(i).controlInfo.hasException = '1' then
							TMP_elem := true;
								res.data(j).data(k).controlInfo.newEvent := '1'; --- !!!
							res.data(j).data(k).controlInfo.hasException := '1';
						end if;
							
						if execEnds2(i).controlInfo.hasBranch = '1' then
							TMP_elem := true;
								res.data(j).data(k).controlInfo.newEvent := '1'; --- !!!
							res.data(j).data(k).controlInfo.hasBranch := '1';
						end if;
						
						res.data(j).data(k).controlInfo.completed2 := '1';								
					end if;						
				end loop;
			end if;
		end loop;	
	end loop;

	-- Propagate killed/squashed
			for j in 0 to ROB_SIZE-1 loop
				TMP_found := false;
				for k in 0 to PIPE_WIDTH-1 loop
					if TMP_found then
						if res.data(j).fullMask(k) = '1' then
							res.data(j).data(k).controlInfo.squashed := '1';
						end if;
						res.data(j).fullMask(k) := '0';
					end if;				
					if res.data(j).data(k).controlInfo.newEvent = '1' then
						-- CAREFUL: kill subsequent ones when this has excpetion or new branch, but not a branch 
						--				set in front pipe!
						res.data(j).data(k).controlInfo.newEvent := '0'; -- CAREFUL: clear to leave blank for late evts
						TMP_found := true;
					end if;
				end loop;
			end loop;

	if killSignal = '0' then
		return res;
	end if;

	if fromCommitted = '1' then
		matched := true;
	end if;
	
	for i in 0 to ROB_SIZE-1 loop
		-- For slots after the affected one
		if matched then
			res.fullMask(i) := '0';
			if CLEAR_EMPTY_SLOTS_ROB then
				res.data(i) := DEFAULT_STAGE_DATA_MULTI;
			end if;				
		end if;
			
		if groupSelect(i) = '1' then	
			matched := true;
		end if;
				
	end loop;
	
	return res;
end function;




procedure logROB(signal sd, sdl: StageDataROB; fr: FlowResponseBuffer) is
begin
	if LOG_PIPELINE then
		-- pragma synthesis off
		logROBImplem(sd, sdl, fr, makeLogPath(sd'path_name), "");
		-- pragma synthesis on
	end if;
end procedure;


-- pragma synthesis off
procedure logROBImplem(sd, sdl: StageDataROB; fr: FlowResponseBuffer;
								filename: string; desc: string) is
	file outFile: text open append_mode is filename; --"simlog_rob.txt";
	variable fline: line;
	variable killed: boolean := false;
begin
	write(fline, time'image(now));
	writeline(outFile, fline);
	for i in 0 to sd.fullMask'length-1 loop
		--if sd.fullMask(i) = '0' then
		--	exit;
		--end if;
		if i >= slv2u(fr.full) then
			exit;
		end if;
		
		if i >= slv2u(fr.living) then
			killed := true;
		end if;
		
		for j in 0 to PIPE_WIDTH-1 loop	
			if sd.data(i).fullMask(j) = '0' then
				write(fline, "(-)");
			else
				if killed then
					write(fline, "x");
				end if;
				
				if sd.data(i).fullMask(j) = '1' and sdl.data(i).fullMask(j) = '0' then
					write(fline, "x");
				end if;
				
				write(fline, 
								 integer'image(slv2u(sd.data(i).data(j).groupTag))
					  & "@" & integer'image(slv2u(sd.data(i).data(j).basicInfo.ip)));
				write(fline, ", ");
			end if;
		end loop;
		writeline(outFile, fline);
	end loop;
end procedure;
-- pragma synthesis on

procedure checkROB(sd, sdn: StageDataROB; flowDrive: FlowDriveBuffer; flowResponse: FlowResponseBuffer) is
	variable sdShifted: StageDataROB
		:= (fullMask => (others => '0'), data => (others => DEFAULT_STAGE_DATA_MULTI));
	variable nFull, nLiving, nFullNext, nSending, nReceiving, nKilled: integer := 0;
	variable nCommon: integer := 0;
	variable nF1, nF2: integer := 0;
begin
	-- pragma synthesis off
	
	if not BASIC_CHECKS then
		return;
	end if;
	
	nFull := integer(slv2u(flowResponse.full));
	nLiving := integer(slv2u(flowResponse.living));
	nSending := integer(slv2u(flowResponse.sending));
	nReceiving := integer(slv2u(flowDrive.prevSending));
		
	nFullNext := nLiving + nReceiving - nSending;
	-- full, fullMask - agree?
	assert countOnes(sd.fullMask) = nFull report "ywwwy";
		assert countOnes(sd.fullMask(0 to nFull-1)) = nFull report "vgh"; -- checking continuity
	-- next full, fullMaskNext - agree?
	assert countOnes(sdn.fullMask) = nFullNext report "juuj";
		assert countOnes(sdn.fullMask(0 to nFullNext-1)) = nFullNext report "jdss";
	-- number of killed agrees?
		--??
	-- number of new agrees?
		-- ??
	-- ??
	
	-- Check if content is matching. Which one correspond in the 2 arrays?
		-- Get those that are living. Some of them will be shifted out (nSending),
		--	some remain. [nSending to nLiving-1] should be found in [0 to nLiving-nSending-1] in new array.
		-- 
	nCommon := nLiving - nSending;
	
	for i in 0 to nCommon - 1 loop	
		sdShifted.fullMask(i) := sd.fullMask(i + nSending);
		sdShifted.data(i) := sd.data(i + nSending);		
	end loop;
	
	-- CHECK: does it make sense to examine this? Should other kinds of data be compared?
	for i in 0 to nCommon-1 loop
		-- Check if fullMask is continuous:
		nF1 := countOnes(sdShifted.data(i).fullMask);
		assert countOnes(sdShifted.data(i).fullMask(0 to nF1-1)) = nF1 report "yyyu:";

		nF2 := countOnes(sdn.data(i).fullMask);
		assert countOnes(sdn.data(i).fullMask(0 to nF2-1)) = nF2 report "f6";
	
		if (i = nCommon-1) then -- and (nFull /= nLiving) then
									-- Some slots may have been killed
			-- In this case check if new mask is a contained in the beginning of old
			assert sdn.data(i).fullMask = (sdShifted.data(i).fullMask and sdn.data(i).fullMask) report "yy";
				--assert nF2 <= nF1; -- Or like this?
		else
			assert sdn.data(i).fullMask = sdShifted.data(i).fullMask report "jnhhh";
				--assert nF1 = nF2; -- Or like this?
		end if;
		
		for j in 0 to PIPE_WIDTH-1 loop
			if sdn.data(i).fullMask(j) = '0' then
				exit;
			end if;	
			assert sd.data(i).data(j).numberTag = sd.data(i).data(j).numberTag report "koho";
								-- TODO: is this the right tag field?
			assert sd.data(i).data(j).basicInfo.ip = sd.data(i).data(j).basicInfo.ip report "jor";
		end loop;
	end loop;
	
	-- pragma synthesis on
end procedure;

end ProcLogicROB;
