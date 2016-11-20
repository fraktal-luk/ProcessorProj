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


package SimLogicROB is

function stageROBNextSim(content: StageDataROB; fullMask: std_logic_vector; newContent: StageDataMulti;
		nFull: integer; sending, receiving: std_logic)
return StageDataROB;

function killInROBSim(content: StageDataROB; refTag: SmallNumber; killTag: SmallNumber;
						killSignal: std_logic)
return StageDataROB;

end SimLogicROB;



package body SimLogicROB is

function stageROBNextSim(content: StageDataROB; fullMask: std_logic_vector; newContent: StageDataMulti;
		nFull: integer; sending, receiving: std_logic)
return StageDataROB is
	variable res: StageDataROB := (fullMask => (others => '0'), 
														data => (others => DEFAULT_STAGE_DATA_MULTI));
		constant CLEAR_EMPTY_SLOTS_ROB: boolean := true;
		variable newFull: integer := nFull;
			variable bPrev, bCurrent: std_logic := '0';
			variable basicFullMask: std_logic_vector(0 to ROB_SIZE-1) := fullMask;
begin
	-- CAREFUL: even when not clearing empty slots, result tags probably should be cleared!
	--				It's to prevent reading of fake results from empty slots
	res := content;
	
			if nFull > ROB_SIZE then
				report "Incorrect number of full slots in ROB!";
				return res;
			end if;
	
			if nFull = ROB_SIZE and sending = '0' and receiving = '1' then
				report "Receiving into full ROB!";
				return res;
			end if;
			
	if sending = '1' then
			if nFull <= 0 then
				report "Trying to send from empty ROB!";
				return res;
			end if;
		
		-- shift by 1
		res.fullMask(0 to ROB_SIZE-2) := res.fullMask(1 to ROB_SIZE-1);
			res.fullMask(ROB_SIZE-1) := '0'; -- CAREFUL, TODO: This may be incorrect (?) if we allow receiving
														-- 					into full buffer when it's sending...
														
		--	basicFullMask(0 to ROB_SIZE-2) := basicFullMask(1 to ROB_SIZE-1);											
		--	basicFullMask(ROB_SIZE-1) := '0';
			
		res.data(0 to ROB_SIZE-2) := res.data(1 to ROB_SIZE-1);		
		newFull := nFull-1;
		res.fullMask(newFull) := '0';
	end if;
	
		-- Clear empty slots
		for i in 0 to content.data'length-1 loop -- to livingContent'length - nOut - 1 loop
			if i >= newFull then
				res.data(i) := DEFAULT_STAGE_DATA_MULTI;	
			end if;		
		end loop;
	
	-- Accept new content
	if receiving = '1' then		
		res.fullMask(newFull) := '1';
		res.data(newFull) := newContent;		
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
	
	return res;		
end function;


function killInROBSim(content: StageDataROB; refTag: SmallNumber; killTag: SmallNumber;
						killSignal: std_logic)
return StageDataROB is
	variable res: StageDataROB := content;
	variable indH, indL, indRef, index, indexP1: integer;
	variable tmpV8: SmallNumber := (others => '0');
	
	constant CLEAR_EMPTY_SLOTS_ROB: boolean := true;
begin
	if killSignal = '0' then
		return res;
	end if;

	indH := integer(slv2u(killTag(SMALL_NUMBER_SIZE-1 downto LOG2_PIPE_WIDTH))); -- signed, to subtract
			tmpV8 := i2slv(PIPE_WIDTH-1, SMALL_NUMBER_SIZE);
			tmpV8 := tmpV8 and killTag;
	indL := --slv2s(execEnds(i).groupTag(LOG2_PIPE_WIDTH-1 downto 0));
			slv2s(tmpV8);
	indRef := integer(slv2u(refTag(SMALL_NUMBER_SIZE-1 downto LOG2_PIPE_WIDTH)));

	index := (indH - indRef - 1) mod 2**(SMALL_NUMBER_SIZE - LOG2_PIPE_WIDTH);
		-- report integer'image(indH - indRef - 1) severity warning;
		
		-- just index+1
		indexP1 := (indH - indRef) mod 2**(SMALL_NUMBER_SIZE - LOG2_PIPE_WIDTH);
			--		report "What inds: " & integer'image(indH) & " " & integer'image(indRef);
	
			--	report integer'image(indH - indRef - 1);
	
	for i in 0 to ROB_SIZE-1 loop
		if i + 1 = indexP1 then
			for j in 0 to PIPE_WIDTH-1 loop
				if j > indL then
					res.data(i).fullMask(j) := '0';
					if CLEAR_EMPTY_SLOTS_ROB then
						res.data(i).data(j) := defaultInstructionState;
					end if;	
				end if;
			end loop;
		elsif i + 1 > indexP1 then
			res.fullMask(i) := '0';
			if CLEAR_EMPTY_SLOTS_ROB then
				res.data(i) := DEFAULT_STAGE_DATA_MULTI;
			end if;	
		end if;
	end loop;
	return res;
end function;


end SimLogicROB;
