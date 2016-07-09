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


package ProcLogicRenaming is

function baptizeVec(sd: StageDataMulti; tags: SmallNumberArray) 
return StageDataMulti;
		

	
function renameRegs(insVec: StageDataMulti; takeVec, destMask: std_logic_vector;
								psVec, pdVec: PhysNameArray; gprTags: SmallNumberArray) 		
return StageDataMulti;
		
-- Not used yet		
function renameAndBaptize(insVec: StageDataMulti; psVec, pdVec: PhysNameArray;
									gprTags: SmallNumberArray;
									baseNum: integer) 
return StageDataMulti; 

end ProcLogicRenaming;



package body ProcLogicRenaming is

function baptizeVec(sd: StageDataMulti; tags: SmallNumberArray) 
return StageDataMulti is
	variable res: StageDataMulti := sd;
begin
	for i in res.data'range loop
		if true or res.fullMask(i) = '1' then
			res.data(i).numberTag := tags(i);
		end if;
	end loop;
	return res;
end function;



function renameRegs(insVec: StageDataMulti; takeVec, destMask: std_logic_vector;
							psVec, pdVec: PhysNameArray; gprTags: SmallNumberArray) 
return StageDataMulti is
	variable res: StageDataMulti := insVec;
	variable k: natural := 0;					
begin
	for i in insVec.fullMask'range loop		
		res.data(i).gprTag := gprTags(i); -- ???
		res.data(i).physicalArgs.sel := res.data(i).virtualArgs.sel;
		res.data(i).physicalArgs.s0 := psVec(3*i+0);	
		res.data(i).physicalArgs.s1 := psVec(3*i+1);			
		res.data(i).physicalArgs.s2 := psVec(3*i+2);							
		for j in insVec.fullMask'range loop	
			-- Is s0 equal to prev instruction's dest?				
			if j = i then exit; end if;				
			if insVec.data(i).virtualArgs.s0 = insVec.data(j).virtualDestArgs.d0
				and isNonzero(insVec.data(i).virtualArgs.s0) = '1' -- CAREFUL: don't copy dummy dest for r0
			then
				res.data(i).physicalArgs.s0 := res.data(j).physicalDestArgs.d0;
			end if;		
			if 	 insVec.data(i).virtualArgs.s1 = insVec.data(j).virtualDestArgs.d0
				and isNonzero(insVec.data(i).virtualArgs.s1) = '1' -- CAREFUL: don't copy dummy dest for r0
			then	
				res.data(i).physicalArgs.s1 := res.data(j).physicalDestArgs.d0;						
			end if;	
			if 	 insVec.data(i).virtualArgs.s2 = insVec.data(j).virtualDestArgs.d0 
				and isNonzero(insVec.data(i).virtualArgs.s2) = '1' -- CAREFUL: don't copy dummy dest for r0
			then
				res.data(i).physicalArgs.s2 := res.data(j).physicalDestArgs.d0;						
			end if;						
		end loop;
		res.data(i).physicalDestArgs.sel(0) := destMask(i);
		if takeVec(i) = '1' then
			res.data(i).physicalDestArgs.d0 := pdVec(k);
			k := k + 1;
		end if;	
		
		-- CAREFUL! Set 'missing' flags for register args and fill immediate if relevant
		res.data(i).argValues.missing(0) := 	res.data(i).physicalArgs.sel(0) 
														and isNonzero(res.data(i).virtualArgs.s0);
		res.data(i).argValues.missing(1) := 	res.data(i).physicalArgs.sel(1) 
														and isNonzero(res.data(i).virtualArgs.s1);
		res.data(i).argValues.missing(2) := 	res.data(i).physicalArgs.sel(2) 
														and isNonzero(res.data(i).virtualArgs.s2);
		if res.data(i).constantArgs.immSel = '1' then
			res.data(i).argValues.missing(1) := '0';
			res.data(i).argValues.arg1 := res.data(i).constantArgs.imm;					
		end if;	
	end loop;			

	return res;
end function;

-- CAREFUL: probably invalid
function renameAndBaptize(insVec: StageDataMulti; psVec, pdVec: PhysNameArray;
									gprTags: SmallNumberArray;
									baseNum: integer) 
return StageDataMulti is
	variable res: StageDataMulti := insVec;
	variable k: natural := 0;	
begin
				
	for i in insVec.fullMask'range loop	
		-- Baptizing
			--if res.fullMask(i) = '1' then -- NOTE: if renaming ignores fullMask, maybe here also? 
				res.data(i).numberTag := i2slv(baseNum + i + 1, SMALL_NUMBER_SIZE);
			--end if;				
	
		-- Renaming (CAREFUL: shouldn't it also depend on fullMask?)
			res.data(i).gprTag := gprTags(i); -- ???
		res.data(i).physicalArgs.sel := res.data(i).virtualArgs.sel;
		res.data(i).physicalArgs.s0 := psVec(3*i+0);	
		res.data(i).physicalArgs.s1 := psVec(3*i+1);			
		res.data(i).physicalArgs.s2 := psVec(3*i+2);							
		for j in insVec.fullMask'range loop	
			-- Is s0 equal to prev instruction's dest?				
			if j = i then exit; end if;				
			if insVec.data(i).virtualArgs.s0 = insVec.data(j).virtualDestArgs.d0 then
				res.data(i).physicalArgs.s0 := pdVec(j);
			end if;		
			if insVec.data(i).virtualArgs.s1 = insVec.data(j).virtualDestArgs.d0 then
				res.data(i).physicalArgs.s1 := pdVec(j);
			end if;	
			if insVec.data(i).virtualArgs.s2 = insVec.data(j).virtualDestArgs.d0 then
				res.data(i).physicalArgs.s2 := pdVec(j);
			end if;						
		end loop;
		res.data(i).physicalDestArgs.sel(0) := res.data(i).virtualDestArgs.sel(0)
							-- CAREFUL: maybe just flag writing to r0 as no output, like this?
												and isNonzero(res.data(i).virtualDestArgs.d0);				
		-- CAREFUL! Here we don't assign PR's for r0
		if (res.data(i).virtualDestArgs.sel(0) and isNonzero(res.data(i).virtualDestArgs.d0)) = '1' then
			res.data(i).physicalDestArgs.d0 := pdVec(k);
			k := k + 1;
		end if;	
		
		-- CAREFUL! Set 'missing' flags for register args and fill immediate if relevant
		res.data(i).argValues.missing(0) := 	res.data(i).physicalArgs.sel(0) 
														and isNonzero(res.data(i).virtualArgs.s0);
		res.data(i).argValues.missing(1) := 	res.data(i).physicalArgs.sel(1) 
														and isNonzero(res.data(i).virtualArgs.s1);
		res.data(i).argValues.missing(2) := 	res.data(i).physicalArgs.sel(2) 
														and isNonzero(res.data(i).virtualArgs.s2);
		if res.data(i).constantArgs.immSel = '1' then
			res.data(i).argValues.missing(1) := '0';
			res.data(i).argValues.arg1 := res.data(i).constantArgs.imm;					
		end if;	
	end loop;			
		
	return res;
end function;

end ProcLogicRenaming;
