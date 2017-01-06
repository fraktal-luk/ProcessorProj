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
--use work.Renaming1.all;

package NewPipelineData is

	constant BASIC_CHECKS: boolean := true;
	constant LOG_PIPELINE: boolean := false;

	-- Configuration defs 
	constant MW: natural := 4; -- Max pipe width  

	constant LOG2_PIPE_WIDTH: natural := 0 ; -- + 2; -- Must match the width!
	constant PIPE_WIDTH: positive := 2**LOG2_PIPE_WIDTH; -- + 1 + 2; 
	constant ALIGN_BITS: natural := LOG2_PIPE_WIDTH + 2;

	constant FETCH_BLOCK_SIZE: natural := PIPE_WIDTH * 2;
	constant HBUFFER_SIZE: natural := PIPE_WIDTH * 4;
	
	-- TODO: eliminate, change to chained implementation
	constant N_EVENT_AREAS: natural := 8;-- How many distinct stages or groups of stages have own event signals
	-- PC, Fetch0, Fetch1, Hbuffer, Decode, Rename, OOO, Committed
	--	 0			1		  2 		  3		 4			5 	  6			 7	
	
	
	constant IQ_A_SIZE: natural := PIPE_WIDTH * 2;
	constant IQ_B_SIZE: natural := PIPE_WIDTH * 2;
	constant IQ_C_SIZE: natural := PIPE_WIDTH * 2;
	constant IQ_D_SIZE: natural := PIPE_WIDTH * 2;
	constant IQ_E_SIZE: natural := PIPE_WIDTH * 2;	
	
	constant CQ_SIZE: natural := PIPE_WIDTH * 4;
	
		constant ROB_SIZE: natural := 8; -- ??
	
		-- If true, physical registers are allocated even for empty slots in instruction group
		--		and later freed from them.
		constant ALLOC_REGS_ALWAYS: boolean := false;
		
		-- Allows to raise 'lockSend' for instruction before Exec when source which was 'readyNext'
		--	doesn't show in 'ready'	when expected	
		constant BLOCK_ISSUE_WHEN_MISSING: std_logic := '0';
		
	constant N_RES_TAGS: natural := 4 + CQ_SIZE; -- + PIPE_WIDTH; -- + 3*PIPE_WIDTH; 
						-- Above: num subpipe results + CQ slots + max commited slots + pre-IQ red ports
	constant N_NEXT_RES_TAGS: natural := 4; 
	
	constant zerosPW: std_logic_vector(0 to PIPE_WIDTH-1) := (others=>'0');	
	------

	-- TODO: move config info to general config file included in higher level definition files
	constant N_PHYSICAL_REGS: natural := 64;
	constant N_PHYS: natural := N_PHYSICAL_REGS;
	
	constant FREE_LIST_SIZE: natural := 64; -- ??
	
	subtype PhysName is slv6;
	type PhysNameArray is array(natural range <>) of PhysName;


subtype SmallNumber is byte;
type SmallNumberArray is array(integer range <>) of SmallNumber;
constant SMALL_NUMBER_SIZE: natural := SmallNumber'length;


constant PROCESSOR_ID: Mword := X"001100aa";

type ExecUnit is (General, ALU, MAC, Divide, Jump, Memory, System );
type ExecFunc is (unknown,	
										arithAdd, arithSub, arithShra,
										logicAnd, logicOr, logicShl, logicShrl,
										
										mulS, mulU, 
									
										divS, divU,
										
										load, store,
										
										jump,
										
										sysMTC, sysMFC, -- move to/from control
										sysUndef
							);	

	-- CAREFUL: is this needed and correct?
	type ExecStages is (	ExecA0, 
								ExecB0, ExecB1, ExecB2,
								ExecC0, ExecC1, ExecC2,
								ExecD0);
							
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
	completed: std_logic;
		completed2: std_logic;
	-- Momentary data:
	newEvent: std_logic; -- True if any new event appears
	newInterrupt: std_logic;
	newException: std_logic;
	newBranch: std_logic;
	newReturn: std_logic; -- going to normal next, as in cancelling a branch
	newFetchLock: std_logic;
	-- Persistent data:
	hasEvent: std_logic; -- Persistent 
	hasInterrupt: std_logic;
	hasException: std_logic;
	hasBranch: std_logic;
	hasReturn: std_logic;
	hasFetchLock: std_logic;
	exceptionCode: SmallNumber; -- Set when exception occurs, remains cause exception can be only 1 per op
end record;

type InstructionClassInfo is record
	short: std_logic;
		mainCluster: std_logic;
		secCluster: std_logic;
	branchAlways: std_logic; -- either taken or not (only constant branches are known at decoding)
	branchCond: std_logic;
	branchReg: std_logic;
	system: std_logic; -- ??
	--memory: std_logic; -- ??
	fetchLock: std_logic;
	--renameLock: std_logic; -- prob. cannot be here; maybe should in controlInfo
	--		short: std_logic;
	undef: std_logic;
	illegal: std_logic;
	privilege: SmallNumber;
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
	virtualArgs: InstructionVirtualArgs;
	virtualDestArgs: InstructionVirtualDestArgs;
	physicalArgs: InstructionPhysicalArgs;
	physicalDestArgs: InstructionPhysicalDestArgs;
	numberTag: SmallNumber;
	gprTag: SmallNumber;
	groupTag: SmallNumber;
	argValues: InstructionArgValues;
	result: Mword;
	target: Mword;
end record;

type InstructionStateArray is array(integer range <>) of InstructionState;
	
	constant INITIAL_GROUP_TAG: SmallNumber := (others => '0');
															-- i2slv(-PIPE_WIDTH, SMALL_NUMBER_SIZE)
	constant USE_GPR_TAG: boolean := false;
	
	
-- Number of words proper for fetch group size
subtype InsGroup is WordArray(0 to PIPE_WIDTH-1);

-- Flow definitions / CAREFUL, TODO: move to GeneralPipeDev?

-- Flow control: input structure
type FlowDriveSimple is record
	lockAccept: std_logic;
	lockSend: std_logic;
	kill: std_logic;
	prevSending: std_logic;
	nextAccepting: std_logic;	
end record;

-- Flow control: output structure
type FlowResponseSimple is record
	accepting: std_logic;
	sending: std_logic;
	isNew: std_logic;
	full: std_logic;
	living: std_logic;	
end record;


-- Input structure
type FlowDriveBuffer is record
	lockAccept: std_logic;
	lockSend: std_logic;
	killAll: std_logic;
	kill: SmallNumber;
	prevSending: SmallNumber;
	nextAccepting: SmallNumber;	
end record;

-- Output structure
type FlowResponseBuffer is record
	accepting: SmallNumber;
	sending: SmallNumber;
	isNew: SmallNumber;
	full: SmallNumber;
	living: SmallNumber;	
end record;

	subtype PipeFlow is SmallNumber;

-- Use this to convert PipeFlow to numbers 
function binFlowNum(flow: PipeFlow) return natural;
function num2flow(n: natural) return PipeFlow;


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

constant DEFAULT_INSTRUCTION_STATE: InstructionState := defaultInstructionState;
	
-- Created to enable *Array				
type InstructionSlot is record 
	full: std_logic;
	ins: InstructionState;
end record;
	
constant DEFAULT_INSTRUCTION_SLOT: InstructionSlot := ('0', defaultInstructionState);
	
-- NOTE: index can be negative to enable logical division into 2 different ranges 
type InstructionSlotArray is array(integer range <>) of InstructionSlot;


type StageDataMulti is record
	fullMask: std_logic_vector(0 to PIPE_WIDTH-1);
	data: InstructionStateArray(0 to PIPE_WIDTH-1);	
end record;

constant DEFAULT_STAGE_DATA_MULTI: StageDataMulti := (fullMask=>(others=>'0'),
																		data=>(others=>defaultInstructionState)
																		);	


type StageDataCommitQueue is record
	fullMask: std_logic_vector(0 to CQ_SIZE-1); 
	data: InstructionStateArray(0 to CQ_SIZE-1);
end record;

	type StageDataMultiArray is array (integer range <>) of StageDataMulti;

	type StageDataROB is record
		fullMask: std_logic_vector(0 to ROB_SIZE-1); 
		data: StageDataMultiArray(0 to ROB_SIZE-1);
	end record;


function initialPCData return InstructionState;

constant INITIAL_PC: Mword := i2slv(-PIPE_WIDTH*4, MWORD_SIZE);

constant INITIAL_BASIC_INFO: InstructionBasicInfo := (ip => INITIAL_PC,
																		systemLevel => (others => '0'),
																		intLevel => (others => '0'));																		

constant DEFAULT_DATA_PC: InstructionState := defaultInstructionState;
constant INITIAL_DATA_PC: InstructionState := initialPCData;

constant DEFAULT_ANNOTATED_HWORD: InstructionState := defaultInstructionState;
	
	type StageDataHbuffer is record
		fullMask: std_logic_vector(0 to HBUFFER_SIZE-1);
		data: InstructionStateArray(0 to HBUFFER_SIZE-1);
	end record;
	
	constant DEFAULT_STAGE_DATA_HBUFFER: StageDataHbuffer := 
		(fullMask => (others => '0'), data => (others => DEFAULT_ANNOTATED_HWORD));

type HbuffOutData is record
	sd: StageDataMulti;
	nOut: SmallNumber;
	nHOut: SmallNumber;
end record;


type FrontEventInfo is record
	eventOccured: std_logic;
	causing: InstructionState;
	affectedVec, causingVec: std_logic_vector(0 to 4);	
	fromExec, fromInt: std_logic;	
end record;

-- TODO: remove? Why another same type? 
type FrontEventInfo2 is record
	eventOccured: std_logic;
	causing: InstructionState;
	affectedVec, causingVec: std_logic_vector(0 to 4);	
	fromExec, fromInt: std_logic;	
end record;

-- 
type StageMultiEventInfo is record
	eventOccured: std_logic;
	causing: InstructionState;
	partialKillMask: std_logic_vector(0 to PIPE_WIDTH-1);
end record;

constant DEFAULT_STAGE_MULTI_EVENT_INFO: StageMultiEventInfo
													:= (eventOccured => '0',
														  causing => defaultInstructionState,
														  partialKillMask => (others => '0'));


type ExecRelTable is array (ExecStages'left to ExecStages'right) of ExecStages; 

type ExecDriveTable is array (ExecStages'left to ExecStages'right) of FlowDriveSimple;							
type ExecResponseTable is array (ExecStages'left to ExecStages'right) of FlowResponseSimple;
	
type ExecDataTable is array (ExecStages'left to ExecStages'right) of InstructionState;
	

	type InstructionResult is record
		full: std_logic;
		tag: SmallNumber;
		value: Mword;
	end record;

	constant DEFAULT_INSTRUCTION_RESULT: InstructionResult := ('0', (others => '0'), (others => '0'));
	
	type InstructionResultArray is array(integer range <>) of InstructionResult;
					
			type ArgStatusInfo is record
				stored: std_logic_vector(0 to 2); -- those that were already present in prev cycle	
				written: std_logic_vector(0 to 2);
				ready: std_logic_vector(0 to 2);
				locs: SmallNumberArray(0 to 2);
				vals: MwordArray(0 to 2);
				nextReady: std_logic_vector(0 to 2);
				nextLocs: SmallNumberArray(0 to 2);
			end record;

			type ArgStatusInfoArray is array(integer range <>) of ArgStatusInfo;

	function defaultLastComitted return InstructionState;

end NewPipelineData;



package body NewPipelineData is

function binFlowNum(flow: PipeFlow) return natural is
	variable vec: std_logic_vector(PipeFlow'length-1 downto 0) := flow;
begin
	return slv2u(vec);
end function;

function num2flow(n: natural) return PipeFlow is
	variable res: PipeFlow := (others=>'0');
	variable b: natural := n;
begin	
	res := i2slv(n, PipeFlow'length);
	return res;
end function;

 
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
												completed => '0',
													completed2 => '0',
												newEvent => '0',
												hasEvent => '0',
												newInterrupt => '0',
												hasInterrupt => '0',
												newException => '0',
												hasException => '0',
												newBranch => '0',
												hasBranch => '0',
												newReturn => '0',
												hasReturn => '0',												
												newFetchLock => '0',
												hasFetchLock => '0',
												
												exceptionCode => (others=>'0')
												);
end function;

function defaultClassInfo return InstructionClassInfo is
begin
	return InstructionClassInfo'( short => '0',
												mainCluster => '0',
												secCluster => '0',
											branchAlways => '0',
											branchCond => '0',
											branchReg => '0',
											system => '0',
											--memory: std_logic; -- ??
												-- ?? load => '0',
												-- ?? store => '0',
											fetchLock => '0',
											--renameLock => '0',
											
											undef => '0', --?
											illegal => '0',
											privilege => (others=>'1'));	
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
	return InstructionPhysicalArgs'("000", "000000", "000000", "000000");
end function;

function defaultPhysicalDestArgs return InstructionPhysicalDestArgs is
begin
	return InstructionPhysicalDestArgs'("0", "000000");
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
	res.virtualArgs := defaultVirtualArgs;
	res.virtualDestArgs := defaultVirtualDestArgs;
	res.physicalArgs := defaultPhysicalArgs;
	res.physicalDestArgs := defaultPhysicalDestArgs;
	res.numberTag := (others => '0'); -- '1');
	res.gprTag := (others => '0'); -- '1');
	res.groupTag := (others => '0');
	res.argValues := defaultArgValues;
	res.result := (others => '0');
	res.target := (others => '0');
	return res;
end function;


function initialPCData return InstructionState is
	variable res: InstructionState := defaultInstructionState;
begin
	res.basicInfo := INITIAL_BASIC_INFO;
	return res;
end function;


	function defaultLastComitted return InstructionState is
		variable res: InstructionState;
	begin
		res.controlInfo := defaultControlInfo;
		res.basicInfo := defaultBasicInfo;
		res.bits := (others=>'0');
		--res.operation := BinomialOp'(unknown, unknown);
		res.classInfo := defaultClassInfo;
		res.constantArgs := defaultConstantArgs;
		res.virtualArgs := defaultVirtualArgs;
		res.virtualDestArgs := defaultVirtualDestArgs;
		res.physicalArgs := defaultPhysicalArgs;
		res.physicalDestArgs := defaultPhysicalDestArgs;
		res.numberTag := (others => '1');
		res.gprTag := (others => '0');
		res.groupTag := --(others => '1');
							 --(others => '0');
								INITIAL_GROUP_TAG;
		res.argValues := defaultArgValues;
		res.result := (others => '0');
		res.target := (others => '0');
		return res;
	end function;


end NewPipelineData;
