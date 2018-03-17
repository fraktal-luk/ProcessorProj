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


type RegisterMapRequest is record
	sel: std_logic_vector(0 to PIPE_WIDTH-1);
	index: RegNameArray(0 to PIPE_WIDTH-1);
	value: PhysNameArray(0 to PIPE_WIDTH-1);
end record;

constant DEFAULT_REGISTER_MAP_REQUEST: RegisterMapRequest := 
	(sel => (others => '0'), index => (others => (others => '0')), value => (others => (others => '0')));

function getRegMapRequest(sd: StageDataMulti; newPhys: PhysNameArray) return RegisterMapRequest;


function baptizeVec(sd: StageDataMulti; tags: SmallNumberArray) 
return StageDataMulti;

function renameRegs2(insVec: StageDataMulti; takeVec, destMask: std_logic_vector;
								psVec, pdVec: PhysNameArray) 		
return StageDataMulti;


function setArgStatus(insVec: StageDataMulti)--; readyRegFlagsVirtualNext: std_logic_vector) 
return StageDataMulti;



function getStableDestsParallel(insVec: StageDataMulti; pdVec: PhysNameArray) return PhysNameArray;

		function genNewNumberTags(renameCtr: SmallNumber) return SmallNumberArray;
		
		function genNewGprTags(newPhysDestPointer: SmallNumber; nToTake: integer) return SmallNumberArray;
		
		function renameGroup(insVec: StageDataMulti;
									newPhysSources: PhysNameArray;
									newPhysDests: PhysNameArray;
									renameCtr: SmallNumber;
									renameGroupCtrNext: SmallNumber;
									newPhysDestPointer: SmallNumber
									) return StageDataMulti;

function baptizeAll(insVec: StageDataMulti; numberTags: SmallNumberArray;
						  newGroupTag: SmallNumber; gprTags: SmallNumberArray)
return StageDataMulti;

-- Clears non-effective 'full' bits in group (after exception or specia)
function TMP_handleSpecial(sd: StageDataMulti) return StageDataMulti;

function findWhichTakeReg(sd: StageDataMulti) return std_logic_vector; -- USELESS? just fullMask
function findWhichPutReg(sd: StageDataMulti) return std_logic_vector;


function initList return PhysNameArray;

end ProcLogicRenaming;



package body ProcLogicRenaming is

function getRegMapRequest(sd: StageDataMulti; newPhys: PhysNameArray) return RegisterMapRequest is
	variable res: RegisterMapRequest;
begin
	-- Choose ops that have real virtual destination.
	-- Unselect mappings not written because of WAW dependency.
	res.sel := getDestMask(sd) and sd.fullMask 		-- have to be full!
					and not getExceptionMask(sd)			-- if exception, doesn't write
					and not findOverriddenDests(sd);
	for i in 0 to PIPE_WIDTH-1 loop
		res.index(i) := sd.data(i).--virtualDestArgs.d0;
											virtualArgSpec.dest(4 downto 0);
		res.value(i) := newPhys(i);
	end loop;
	return res;
end function;



		function genNewNumberTags(renameCtr: SmallNumber) return SmallNumberArray is
			variable res: SmallNumberArray(0 to PIPE_WIDTH-1) := (others => (others => '0'));
		begin
			for i in  0 to PIPE_WIDTH-1 loop
				res(i) := i2slv(slv2u(renameCtr) + i + 1, SMALL_NUMBER_SIZE);
			end loop;
			return res;
		end function;
		
		function genNewGprTags(newPhysDestPointer: SmallNumber; nToTake: integer) return SmallNumberArray is
			variable res: SmallNumberArray(0 to PIPE_WIDTH-1) := (others => (others => '0'));
		begin
			for i in  0 to PIPE_WIDTH-1 loop
				if FREE_LIST_COARSE_REWIND = '1' then
					res(i) := i2slv((slv2u(newPhysDestPointer) + nToTake) mod FREE_LIST_SIZE, SMALL_NUMBER_SIZE);
				else
					res(i) := i2slv((slv2u(newPhysDestPointer) + i + 1) mod FREE_LIST_SIZE, SMALL_NUMBER_SIZE);
				end if;
			end loop;
			return res;
		end function;
		
		function renameGroup(insVec: StageDataMulti;
									newPhysSources: PhysNameArray;
									newPhysDests: PhysNameArray;
									renameCtr: SmallNumber;
									renameGroupCtrNext: SmallNumber;
									newPhysDestPointer: SmallNumber
									) return StageDataMulti is
			variable res: StageDataMulti := insVec;
			variable reserveSelSig, takeVec: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0' );
			variable nToTake: integer := 0;
			variable newGprTags: SmallNumberArray(0 to PIPE_WIDTH-1) := (others=>(others=>'0'));	
			variable newNumberTags: SmallNumberArray(0 to PIPE_WIDTH-1) := (others=>(others=>'0'));
		begin
			reserveSelSig := getDestMask(insVec); -- Just full and having a destination?
			takeVec := findWhichTakeReg(insVec); -- REG ALLOC
			nToTake := countOnes(takeVec);
		
			newNumberTags := genNewNumberTags(renameCtr);
			newGprTags := genNewGprTags(newPhysDestPointer, nToTake);			
			
			res := baptizeAll(res, newNumberTags, renameGroupCtrNext, newGprTags);
			res := renameRegs2(res, takeVec, reserveSelSig, newPhysSources, newPhysDests);
			res := setArgStatus(res);
			res := TMP_handleSpecial(res);
			
			return res;
		end function;

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


function renameRegs2(insVec: StageDataMulti; takeVec, destMask: std_logic_vector;
							psVec, pdVec: PhysNameArray) 
return StageDataMulti is
	variable res: StageDataMulti := insVec;
	variable k: natural := 0;					
begin
	for i in insVec.fullMask'range loop
		-- Set physical dest
		res.data(i).physicalArgSpec.intDestSel := destMask(i);
		if takeVec(i) = '1' then
			res.data(i).physicalArgSpec.dest := pdVec(k);
			k := k + 1;
		end if;
	end loop;
	
	for i in insVec.fullMask'range loop	
		-- Set physical sources
		res.data(i).physicalArgSpec.intArgSel := res.data(i).virtualArgSpec.intArgSel;
		res.data(i).physicalArgSpec.args(0) := psVec(3*i+0);	
		res.data(i).physicalArgSpec.args(1) := psVec(3*i+1);			
		res.data(i).physicalArgSpec.args(2) := psVec(3*i+2);							
		-- Correct physical sources for group dependencies
		for j in insVec.fullMask'range loop	
			-- Is s0 equal to prev instruction's dest?				
			if j = i then exit; end if;				
			if insVec.data(i).virtualArgSpec.args(0)(4 downto 0) = insVec.data(j).--virtualDestArgs.d0
																				virtualArgSpec.dest(4 downto 0)
				and isNonzero(insVec.data(i).virtualArgSpec.args(0)(4 downto 0)) = '1' -- CAREFUL: don't copy dummy dest for r0
			then
				res.data(i).physicalArgSpec.args(0) := res.data(j).physicalArgSpec.dest;
			end if;		
			if 	 insVec.data(i).virtualArgSpec.args(1)(4 downto 0) = insVec.data(j).--virtualDestArgs.d0
																					virtualArgSpec.dest(4 downto 0)
				and isNonzero(insVec.data(i).virtualArgSpec.args(1)(4 downto 0)) = '1' -- CAREFUL: don't copy dummy dest for r0
			then	
				res.data(i).physicalArgSpec.args(1) := res.data(j).physicalArgSpec.dest;						
			end if;	
			if 	 insVec.data(i).virtualArgSpec.args(2)(4 downto 0) = insVec.data(j).--virtualDestArgs.d0
																					virtualArgSpec.dest(4 downto 0)
				and isNonzero(insVec.data(i).virtualArgSpec.args(2)(4 downto 0)) = '1' -- CAREFUL: don't copy dummy dest for r0
			then
				res.data(i).physicalArgSpec.args(2) := res.data(j).physicalArgSpec.dest;
			end if;						
		end loop;
		
	end loop;

	return res;
end function;


function setArgStatus(insVec: StageDataMulti)--; readyRegFlagsVirtualNext: std_logic_vector) 
return StageDataMulti is
	variable res: StageDataMulti := insVec;
begin
	for i in insVec.fullMask'range loop	
		-- Set state markers: "zero" bit		
		if isNonzero(res.data(i).virtualArgSpec.args(0)(4 downto 0)) = '0' then
			res.data(i).argValues.zero(0) := '1';
		end if;
		
		if isNonzero(res.data(i).virtualArgSpec.args(1)(4 downto 0)) = '0' then
			res.data(i).argValues.zero(1) := '1';
		end if;

		if isNonzero(res.data(i).virtualArgSpec.args(2)(4 downto 0)) = '0' then
			res.data(i).argValues.zero(2) := '1';
		end if;		
			
		-- Set 'missing' flags for non-const arguments
		res.data(i).argValues.missing := res.data(i).physicalArgSpec.intArgSel and not res.data(i).argValues.zero;
		
		-- Handle possible immediate arg
		if res.data(i).constantArgs.immSel = '1' then
			res.data(i).argValues.missing(1) := '0';
			res.data(i).argValues.immediate := '1';
			res.data(i).argValues.zero(1) := '0';
			res.data(i).argValues.arg1 := res.data(i).constantArgs.imm;					
		end if;
		
		res.data(i).argValues.readyBefore := not res.data(i).argValues.missing;

			res.data(i).controlInfo.completed := not res.data(i).classInfo.mainCluster;				
			res.data(i).controlInfo.completed2 := not res.data(i).classInfo.secCluster;
				
	end loop;	

	return res; -- CAREFUL: this must be removed if using virtual ready map
end function;


-- TODO: explain this
-- CAREFUL: if use bypassing (>> usage in top module), don't exclude overridden dests 
--				from selection in RegisterFreeList!
function getStableDestsParallel(insVec: StageDataMulti; pdVec: PhysNameArray) return PhysNameArray is
	variable res: PhysNameArray(0 to PIPE_WIDTH-1) := pdVec(0 to PIPE_WIDTH-1);
begin
		return res; -- no bypassing
		
	for i in insVec.fullMask'range loop
		for j in insVec.fullMask'range loop	
			-- Is s0 equal to prev instruction's dest?				
			if j = i then exit; end if;				
			if insVec.data(i).virtualArgSpec.dest(4 downto 0) = insVec.data(j).virtualArgSpec.dest(4 downto 0)		
				and isNonzero(insVec.data(i).virtualArgSpec.dest(4 downto 0)) = '1' -- CAREFUL: don't copy dummy dest for r0
			then
				res(i) := insVec.data(j).--physicalDestArgs.d0;
												 physicalArgSpec.dest;
			end if;		
		end loop;			
	end loop;

	return res;
end function;

	
function baptizeAll(insVec: StageDataMulti; numberTags: SmallNumberArray;
						  newGroupTag: SmallNumber; gprTags: SmallNumberArray)
return StageDataMulti is
	variable res: StageDataMulti := insVec;
begin
	for i in 0 to PIPE_WIDTH-1 loop
		res.data(i).groupTag := newGroupTag or i2slv(i, SMALL_NUMBER_SIZE);
		res.data(i).numberTag := numberTags(i);
		res.data(i).gprTag := gprTags(i); -- ???		
	end loop;
	return res;
end function;


function TMP_handleSpecial(sd: StageDataMulti) return StageDataMulti is
	variable res: StageDataMulti := sd;
	variable found: boolean := false;
begin
	-- If found special instruction, kill next ones
	for i in 0 to PIPE_WIDTH-1 loop
		if found then
			res.fullMask(i) := '0';
		end if;

		if 	res.data(i).controlInfo.specialAction = '1'
			or res.data(i).controlInfo.hasException = '1' -- CAREFUL
			--	TODO: include here also early branches? 
		then
			found := true;
		end if;
	end loop;
	
	return res;
end function;

function findWhichTakeReg(sd: StageDataMulti) return std_logic_vector is
	variable res: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
begin
	for i in 0 to PIPE_WIDTH-1 loop
		res(i) := sd.fullMask(i); -- CAREFUL, TEMP: every in the group (can be previosuly separated for rename, etc)
	end loop;
	
	return res;
end function;


function findWhichPutReg(sd: StageDataMulti) return std_logic_vector is
	variable res: std_logic_vector(0 to PIPE_WIDTH-1) := (others => '0');
begin
	for i in 0 to PIPE_WIDTH-1 loop
		res(i) :=	 sd.fullMask(i) 
					or  (sd.data(i).controlInfo.squashed and FREE_LIST_COARSE_REWIND); -- CAREFUL: for whole group
	end loop;
	
	return res;
end function;

function initList return PhysNameArray is
	variable res: PhysNameArray(0 to FREE_LIST_SIZE-1) := (others => (others=> '0'));
begin
	for i in 0 to N_PHYS - 32 - 1 loop
		res(i) := i2slv(32 + i, PhysName'length);
	end loop;
	return res;
end function;
			
end ProcLogicRenaming;
