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
use work.ProcInstructionsNew.all;

package NewPipelineData is

	constant BASIC_CHECKS: boolean := true;
	constant LOG_PIPELINE: boolean := false;
	constant LOG_FREE_LIST: boolean := false;

	constant REPORT_MEM_QUEUE_WRITES: boolean := false;
	constant REPORT_MEM_QUEUE_FORWARDING: boolean := false;

	-- Configuration defs 
	constant MW: natural := 4; -- Max pipe width  

	constant LOG2_PIPE_WIDTH: natural := 0 + 0; -- + 2; -- Must match the width!
	constant PIPE_WIDTH: positive := 2**LOG2_PIPE_WIDTH; -- + 1 + 2; 
	constant ALIGN_BITS: natural := LOG2_PIPE_WIDTH + 2;
	constant PC_INC: Mword := (ALIGN_BITS => '1', others => '0');	

	constant FETCH_BLOCK_SIZE: natural := PIPE_WIDTH * 2;
	constant FETCH_DELAYED: boolean := false; -- Additional fetch stage for slower caches
	
	constant HBUFFER_SIZE: natural := PIPE_WIDTH * 4;
	
	constant EARLY_TARGET_ENABLE: boolean := true; -- Calc branch targets in front pipe
	constant USE_LINE_PREDICTOR: boolean := true;
	
	constant CQ_SINGLE_OUTPUT: boolean := (LOG2_PIPE_WIDTH = 0);
	constant CQ_THREE_OUTPUTS: boolean := not CQ_SINGLE_OUTPUT;
	
	function getIntegerWriteWidth(so: boolean) return integer is
	begin
		if so then
			return 1;
		else
			return 3;
		end if;	
	end function;
	
	constant INTEGER_WRITE_WIDTH: integer := getIntegerWriteWidth(CQ_SINGLE_OUTPUT);
	
	constant IQ_A_SIZE: natural := PIPE_WIDTH * 2;
	constant IQ_B_SIZE: natural := PIPE_WIDTH * 2;
	constant IQ_C_SIZE: natural := PIPE_WIDTH * 2;
	constant IQ_D_SIZE: natural := PIPE_WIDTH * 2;
	constant IQ_E_SIZE: natural := PIPE_WIDTH * 2;	
	
	constant IQ_SIZES: IntArray(0 to 4) := (IQ_A_SIZE, IQ_B_SIZE, IQ_C_SIZE, IQ_D_SIZE,IQ_E_SIZE);
	
	constant SQ_SIZE: natural := 4;
	constant LQ_SIZE: natural := 4;
	constant LMQ_SIZE: natural := 4; -- !!!
	constant BQ_SIZE: natural := 4;
	
	constant CQ_SIZE: natural := PIPE_WIDTH * 3;
	
	constant SB_SIZE: natural := 4;
	
	constant ROB_SIZE: natural := 8; -- ??
	
		type MemQueueMode is (none, store, load, branch);
		
		-- Allows to raise 'lockSend' for instruction before Exec when source which was 'readyNext'
		--	doesn't show in 'ready'	when expected	
		constant BLOCK_ISSUE_WHEN_MISSING: std_logic := '0'; -- 
		
	constant N_RES_TAGS: natural := 4-1 + CQ_SIZE;
						-- Above: num subpipe results + CQ slots + max commited slots + pre-IQ red ports
	constant N_NEXT_RES_TAGS: natural := 2; 
	------

	-- TODO: move config info to general config file included in higher level definition files
	constant N_PHYSICAL_REGS: natural := 64;  -- CAREFUL: not more than 2**PHYS_NAME_SIZE!
	constant N_PHYS: natural := N_PHYSICAL_REGS;
	
	constant FREE_LIST_SIZE: natural := N_PHYS; -- CAREFUL: must be enough for N_PHYS-32
	constant FREE_LIST_COARSE_REWIND: std_logic := '0';
	
	constant PHYS_NAME_SIZE: integer := 6; -- CAREFUL: 2**PHYS_NAME_SIZE must be not less than n_PHYS!
	subtype PhysName is std_logic_vector(PHYS_NAME_SIZE-1 downto 0);
	type PhysNameArray is array(natural range <>) of PhysName;

	constant ENABLE_INT_OVERFLOW: boolean := false or true;

	constant PROCESSOR_ID: Mword := X"001100aa";

type ExecUnit is (General, ALU, MAC, Divide, Jump, Memory, System );
type ExecFunc is (unknown,

						arithAdd, arithSub, arithShra,
						logicAnd, logicOr, logicShl, logicShrl,
						
						mulS, mulU, 
					
						divS, divU,
						
						load, store,
						
						jump,
						
						sysRetI, sysRetE,
						sysHalt,
						sysSync, sysReplay,
						sysMTC, sysMFC, -- move to/from control
						sysError,
						
						sysUndef
						);	


constant TAG_SIZE: integer := 8;
subtype InsTag is std_logic_vector(TAG_SIZE-1 downto 0);

							
type BinomialOp is record
	unit: ExecUnit;
	func: ExecFunc;
end record;

type InstructionBasicInfo is record
	ip: Mword;
	--thread: SmallNumber;
	intLevel: SmallNumber;
	systemLevel: SmallNumber;
end record;

type InstructionControlInfo is record
		squashed: std_logic;
		skipped: std_logic;
	completed: std_logic;
		completed2: std_logic;
	newEvent: std_logic; -- True if any new event appears
		hasReset: std_logic;
	hasInterrupt: std_logic;
	hasException: std_logic;
	hasBranch: std_logic;
	hasReturn: std_logic;
		specialAction: std_logic;
		phase0, phase1, phase2: std_logic;
	exceptionCode: SmallNumber; -- Set when exception occurs, remains cause exception can be only 1 per op
end record;

type InstructionClassInfo is record
	short: std_logic;
		mainCluster: std_logic;
		secCluster: std_logic;
	branchCond: std_logic;
end record;


type InstructionConstantArgs is record
	immSel: std_logic;
	imm: word;
	c0: slv5;
	c1: slv5;
end record;

type InstructionVirtualArgs is record
	sel: std_logic_vector(0 to 2);
	s0: RegName;
	s1: RegName;
	s2: RegName;
end record;

type InstructionVirtualDestArgs is record
	sel: std_logic_vector(0 to 0);
	d0: RegName;
end record;

type InstructionPhysicalArgs is record
	sel: std_logic_vector(0 to 2);
	s0: PhysName;
	s1: PhysName;
	s2: PhysName;
end record;

type InstructionPhysicalDestArgs is record
	sel: std_logic_vector(0 to 0);
	d0: PhysName;
end record;


		type InstructionArgSpec is record
			intDestSel: std_logic;
			floatDestSel: std_logic;
			dest: SmallNumber;
			intArgSel: std_logic_vector(0 to 2);
			floatArgSel: std_logic_vector(0 to 2);
			args: SmallNumberArray(0 to 2);
		end record;

		type InstructionTags is record
			fetchCtr: word;	-- Ctr is never reset!
			decodeCtr: InsTag; -- Ctr is never reset!
			renameSeq: InsTag;
			renameGroup: InsTag;
			intPointer: SmallNumber;
			floatPointer: SmallNumber;
		end record;
		

type InstructionArgValues is record
	newInQueue: std_logic;
	immediate: std_logic;
	zero: std_logic_vector(0 to 2);
	readyBefore: std_logic_vector(0 to 2);
	readyNow: std_logic_vector(0 to 2);
	readyNext: std_logic_vector(0 to 2);
	locs: SmallNumberArray(0 to 2);
	nextLocs: SmallNumberArray(0 to 2);
	missing: std_logic_vector(0 to 2);
	arg0: Mword;
	arg1: Mword;
	arg2: Mword;
		-- pragma synthesis off
		hist0, hist1, hist2: string(1 to 3);
		-- pragma synthesis on
end record;

type InstructionState is record
	controlInfo: InstructionControlInfo;
	basicInfo: InstructionBasicInfo;
	bits: word; -- instruction word
	operation: BinomialOp;
	classInfo: InstructionClassInfo;
	constantArgs: InstructionConstantArgs;
	--virtualArgs: InstructionVirtualArgs;
	--virtualDestArgs: InstructionVirtualDestArgs;
	physicalArgs: InstructionPhysicalArgs;
	physicalDestArgs: InstructionPhysicalDestArgs;
		virtualArgSpec: InstructionArgSpec;
		physicalArgSpec: InstructionArgSpec;
	numberTag: SmallNumber;
	gprTag: SmallNumber;
	groupTag: SmallNumber;
	argValues: InstructionArgValues;
	result: Mword;
	target: Mword;
end record;

type InstructionStateArray is array(integer range <>) of InstructionState;
	
	
-- Number of words proper for fetch group size
subtype InsGroup is WordArray(0 to PIPE_WIDTH-1);


function defaultBasicInfo return InstructionBasicInfo;
function defaultControlInfo return InstructionControlInfo;
function defaultClassInfo return InstructionClassInfo;
function defaultConstantArgs return InstructionConstantArgs;
function defaultVirtualArgs return InstructionVirtualArgs;
function defaultVirtualDestArgs return InstructionVirtualDestArgs;
function defaultPhysicalArgs return InstructionPhysicalArgs;
function defaultPhysicalDestArgs return InstructionPhysicalDestArgs;
function defaultArgValues return InstructionArgValues;

function defaultInstructionState return InstructionState;

constant DEFAULT_BASIC_INFO: InstructionBasicInfo := defaultBasicInfo;
constant DEFAULT_CONTROL_INFO: InstructionControlInfo := defaultControlInfo;
constant DEFAULT_CLASS_INFO: InstructionClassInfo := defaultClassInfo;
constant DEFAULT_CONSTANT_ARGS: InstructionConstantArgs := defaultConstantArgs;
constant DEFAULT_VIRTUAL_ARGS: InstructionVirtualArgs := defaultVirtualArgs;
constant DEFAULT_VIRTUAL_DEST_ARGS: InstructionVirtualDestArgs := defaultVirtualDestArgs;
constant DEFAULT_PHYSICAL_ARGS: InstructionPhysicalArgs := defaultPhysicalArgs;
constant DEFAULT_PHYSICAL_DEST_ARGS: InstructionPhysicalDestArgs := defaultPhysicalDestArgs;
constant DEFAULT_ARG_VALUES: InstructionArgValues := defaultArgValues;

constant DEFAULT_ARG_SPEC: InstructionArgSpec := InstructionArgSpec'(
			intDestSel => '0',
			floatDestSel => '0',
			dest => (others => '0'),
			intArgSel => (others => '0'),
			floatArgSel => (others => '0'),
			args => ((others => '0'), (others => '0'), (others => '0'))
			);
			
constant DEFAULT_INSTRUCTION_STATE: InstructionState := defaultInstructionState;
constant DEFAULT_INS_STATE: InstructionState := defaultInstructionState;
	
-- Created to enable *Array				
type InstructionSlot is record 
	full: std_logic;
	ins: InstructionState;
end record;
	
constant DEFAULT_INSTRUCTION_SLOT: InstructionSlot := ('0', defaultInstructionState);
constant DEFAULT_INS_SLOT: InstructionSlot := ('0', defaultInstructionState);
	
-- NOTE: index can be negative to enable logical division into 2 different ranges 
type InstructionSlotArray is array(integer range <>) of InstructionSlot;

type StageDataMulti is record
	fullMask: std_logic_vector(0 to PIPE_WIDTH-1);
	data: InstructionStateArray(0 to PIPE_WIDTH-1);	
end record;

constant DEFAULT_STAGE_DATA_MULTI: StageDataMulti := (fullMask=>(others=>'0'),
																		data=>(others=>defaultInstructionState)
																		);

type StageDataMultiArray is array (integer range <>) of StageDataMulti;

					
type ArgStatusInfo is record
	stored: std_logic_vector(0 to 2); -- those that were already present in prev cycle	
	written: std_logic_vector(0 to 2);
	ready: std_logic_vector(0 to 2);
	locs: SmallNumberArray(0 to 2);
	--vals: MwordArray(0 to 2);
	nextReady: std_logic_vector(0 to 2);
	nextLocs: SmallNumberArray(0 to 2);
end record;

type ArgStatusInfoArray is array(integer range <>) of ArgStatusInfo;

end NewPipelineData;



package body NewPipelineData is
 
function defaultBasicInfo return InstructionBasicInfo is
begin
	return InstructionBasicInfo'( ip => (others=>'0'),		-- CAREFUL! '1' hinder constant propagation, but 
																			--				sometimes useful for debugging	
											intLevel => (others=>'0'),
											systemLevel => (others=>'0'));
end function;

function defaultControlInfo return InstructionControlInfo is
begin
	return InstructionControlInfo'(
													squashed => '0',
													skipped => '0',
												completed => '0',
													completed2 => '0',
												newEvent => '0',
												hasInterrupt => '0',
													hasReset => '0',
												hasException => '0',
												hasBranch => '0',
												hasReturn => '0',												
													specialAction => '0',
													phase0 => '0',
													phase1 => '0',
													phase2 => '0',
												exceptionCode => (others=>'0')
												);
end function;

function defaultClassInfo return InstructionClassInfo is
begin
	return InstructionClassInfo'( short => '0',
											mainCluster => '0',
											secCluster => '0',
											branchCond => '0'
											);	
end function;

function defaultConstantArgs return InstructionConstantArgs is
begin
	return InstructionConstantArgs'('0', (others=>'0'), "00000", "00000");
end function;

function defaultVirtualArgs return InstructionVirtualArgs is
begin
	return InstructionVirtualArgs'("000", "00000", "00000", "00000");
end function;


function defaultVirtualDestArgs return InstructionVirtualDestArgs is
begin
	return InstructionVirtualDestArgs'("0", "00000");
end function;

function defaultPhysicalArgs return InstructionPhysicalArgs is
begin
	return InstructionPhysicalArgs'("000", (others => '0'), (others => '0'), (others => '0'));
end function;

function defaultPhysicalDestArgs return InstructionPhysicalDestArgs is
begin
	return InstructionPhysicalDestArgs'("0", (others => '0'));
end function;

function defaultArgValues return InstructionArgValues is
begin
	return (newInQueue => '0',
			  immediate => '0',
			  zero => (others => '0'),
			  readyBefore => (others=>'0'),
			  readyNow => (others=>'0'),
			  readyNext => (others=>'0'),
			  locs => (others => (others => '0')),
			  nextLocs => (others => (others => '0')),
			  missing => (others=>'0'),
			  arg0 => (others=>'0'),
			  arg1 => (others=>'0'),
			  arg2 => (others=>'0')
					-- pragma synthesis off
					,
					hist0 => "   ",
					hist1 => "   ",
					hist2 => "   "
					-- pragma synthesis on
			  );
end function;

function defaultInstructionState return InstructionState is
	variable res: InstructionState;
begin 
	res.controlInfo := defaultControlInfo;
	res.basicInfo := defaultBasicInfo;
	res.bits := (others=>'0');
	--res.operation := BinomialOp'(unknown, unknown);
	res.classInfo := defaultClassInfo;
	res.constantArgs := defaultConstantArgs;
	--res.virtualArgs := defaultVirtualArgs;
	--res.virtualDestArgs := defaultVirtualDestArgs;
	res.physicalArgs := defaultPhysicalArgs;
	res.physicalDestArgs := defaultPhysicalDestArgs;
		res.virtualArgSpec := DEFAULT_ARG_SPEC;
		res.physicalArgSpec := DEFAULT_ARG_SPEC;
	res.numberTag := (others => '0'); -- '1');
	res.gprTag := (others => '0'); -- '1');
	res.groupTag := (others => '0');
	res.argValues := defaultArgValues;
	res.result := (others => '0');
	res.target := (others => '0');
	return res;
end function;

end NewPipelineData;
