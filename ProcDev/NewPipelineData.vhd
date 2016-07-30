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

	-- Configuration defs 
	constant MW: natural := 4; -- Max pipe width  

	constant LOG2_PIPE_WIDTH: natural := 0 ; -- + 2; -- Must match the width!
	constant PIPE_WIDTH: positive := 2**LOG2_PIPE_WIDTH; -- + 1 + 2; 
	constant ALIGN_BITS: natural := LOG2_PIPE_WIDTH + 2;

	constant FETCH_BLOCK_SIZE: natural := PIPE_WIDTH * 2;
	constant HBUFFER_SIZE: natural := PIPE_WIDTH * 4;
	
	constant IQ_A_SIZE: natural := PIPE_WIDTH * 2;
	constant IQ_B_SIZE: natural := PIPE_WIDTH * 2;
	constant IQ_C_SIZE: natural := PIPE_WIDTH * 2;
	constant IQ_D_SIZE: natural := PIPE_WIDTH * 2;
	constant CQ_SIZE: natural := PIPE_WIDTH * 4;
	
	-- CAREFUL! This selects the mode of reg reading. Should be false only if PIPE_WIDTH = 4 
	constant PRE_IQ_REG_READING: boolean := true;
	
	constant N_RES_TAGS: natural := 4 + CQ_SIZE + PIPE_WIDTH + 3*PIPE_WIDTH; 
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
										
										sysRetE, sysRetI,
										sysMTC, sysMFC, -- move to/from control
										sysUndef
							);	

	type FrontStages is (PC, Fetch, Hbuffer, Stage0, Stage1);

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
	-- Momentary data:
	newEvent: std_logic; -- True if any new event appears
	newInterrupt: std_logic;
	newException: std_logic;
	newBranch: std_logic;
	newReturn: std_logic; -- going to normal next, as in cancelling a branch
	newIntReturn: std_logic;
	newExcReturn: std_logic;
	newFetchLock: std_logic;
	-- Persistent data:
	hasEvent: std_logic; -- Persistent 
	hasInterrupt: std_logic;
	hasException: std_logic;
	hasBranch: std_logic;
	hasReturn: std_logic;
	hasIntReturn: std_logic;
	hasExcReturn: std_logic;
	hasFetchLock: std_logic;
	exceptionCode: SmallNumber; -- Set when exception occurs, remains cause exception can be only 1 per op
end record;

type InstructionClassInfo is record
	branchAlways: std_logic; -- either taken or not (only constant branches are known at decoding)
	branchCond: std_logic;
	branchReg: std_logic;
	system: std_logic; -- ??
	--memory: std_logic; -- ??
	fetchLock: std_logic;
	--renameLock: std_logic; -- prob. cannot be here; maybe should in controlInfo
	
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
	missing: std_logic_vector(0 to 2);
	arg0: Mword;
	arg1: Mword;
	arg2: Mword;
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
	argValues: InstructionArgValues;
	result: Mword;
	target: Mword;
end record;

type InstructionStateArray is array(integer range <>) of InstructionState;
	
	-- Number of words proper for fetch group size
	subtype InsGroup is WordArray(0 to PIPE_WIDTH-1);

	-- CAREFUL, TODO: try to stop using rising bit ordering in quantity type!
	subtype PipeFlow is --std_logic_vector(0 to 4+3); -- TEMP?
								SmallNumber;

-- Use this to convert PipeFlow to numbers 
function binFlowNum(flow: PipeFlow) return natural;
function num2flow(n: natural) return PipeFlow;


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

type StageDataPC is record
	basicInfo: InstructionBasicInfo;
	pc: Mword;
	pcBase: Mword;
	--nFull: natural;
	nH: PipeFlow; -- number of hwords 	
end record;

constant INITIAL_BASIC_INFO: InstructionBasicInfo := (ip => i2slv(-PIPE_WIDTH*4, MWORD_SIZE),
																		systemLevel => (others => '0'),
																		intLevel => (others => '0'));																		

constant DEFAULT_DATA_PC: StageDataPC := (			pc => (others=>'0'),
																		pcBase => (others=>'0'),
																		--nFull => 0,
																		nH => (others=>'0'),
																		basicInfo => defaultBasicInfo
																		);	
-- CAREFUL: this is PC "before" address 0 																		
constant INITIAL_DATA_PC: StageDataPC := (			pc => i2slv(-PIPE_WIDTH*4, MWORD_SIZE),
																		pcBase => i2slv(-PIPE_WIDTH*4, MWORD_SIZE),
																		--nFull => 0,
																		nH => i2slv(FETCH_BLOCK_SIZE, SMALL_NUMBER_SIZE),
																		basicInfo => --defaultBasicInfo
																						INITIAL_BASIC_INFO
																		);

type TEMP_StageDataFetch is record
	pc: Mword;
	pcBase: Mword; -- DEPREC?
	nFull: natural;	
end record;

type AnnotatedHword is record
	bits: hword;
	--ip: Mword; -- TODO, NOTE: redundant?
	basicInfo: InstructionBasicInfo;
		-- TODO: include a structure for storing hword decoding info?
		--			Maybe extend 'controlInfo' to hold it?
		shortIns: std_logic; -- This would be there
end record;

constant DEFAULT_ANNOTATED_HWORD: AnnotatedHword := (bits => (others=>'0'), --ip => (others=>'0'),
																	basicInfo => defaultBasicInfo, shortIns => '0');

type AnnotatedHwordArray is array (integer range <>) of AnnotatedHword;

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


type ExecRelTable is array (ExecStages'left to ExecStages'right) of ExecStages; 

type ExecDriveTable is array (ExecStages'left to ExecStages'right) of FlowDriveSimple;							
type ExecResponseTable is array (ExecStages'left to ExecStages'right) of FlowResponseSimple;
	
type ExecDataTable is array (ExecStages'left to ExecStages'right) of InstructionState;
								
	-- Created to enable *Array				
	type InstructionSlot is record 
		full: std_logic;
		ins: InstructionState;
	end record;
	
	constant DEFAULT_INSTRUCTION_SLOT: InstructionSlot := ('0', defaultInstructionState);
	
	-- NOTE: index can be negative to enable logical division into 2 different ranges 
	type InstructionSlotArray is array(integer range <>) of InstructionSlot;
					
			type ArgStatusInfo is record
					stored: std_logic_vector(0 to 2); -- those that were already present in prev cycle
				ready: std_logic_vector(0 to 2);
				locs: SmallNumberArray(0 to 2);
				vals: MwordArray(0 to 2);
					nextReady: std_logic_vector(0 to 2);
					nextLocs: SmallNumberArray(0 to 2);
			end record;
	
			type ArgStatusStruct is record
				readyAll: std_logic;
				readyNextAll: std_logic;
				ready: std_logic_vector(0 to 2);
				locs: SmallNumberArray(0 to 2);
				vals: MwordArray(0 to 2);
				missing: std_logic_vector(0 to 2);
					--C_missing: std_logic_vector(0 to 2);					
				readyReg: std_logic_vector(0 to 2);
				readyNow: std_logic_vector(0 to 2);
				readyNext: std_logic_vector(0 to 2);
				stillMissing: std_logic_vector(0 to 2);
					--C_stillMissing: std_logic_vector(0 to 2);
				nMissing: integer;
				nextMissing: std_logic_vector(0 to 2);
				nMissingNext: integer;					
			end record;

			type ArgStatusInfoArray is array(integer range <>) of ArgStatusInfo;
			type ArgStatusStructArray is array(integer range <>) of ArgStatusStruct;

		type ArgumentStatusInfo is record
			-- Basic state
			argStored: std_logic_vector(0 to 2); -- ready before
			argNew: std_logic_vector(0 to 2);   -- ready from this cycle
			argRegs: std_logic_vector(0 to 2);  -- can be read from reg for next cycle
			argNext: std_logic_vector(0 to 2);  -- expected in forw. network in next cycle
			-- Derived state
			readyNow: std_logic_vector(0 to 2);  -- stored/forw. netw.
			readyNext: std_logic_vector(0 to 2); -- forw. network next cycle
			notReady: std_logic_vector(0 to 2);  -- won't be ready in next cycle
			-- Scheduling status
			allReady: std_logic; -- can go to exec now
			allNext: std_logic;  -- can be dispatched now (to exec next cycle)
			-- Completion info
			filling: std_logic_vector(0 to 2); -- will be updated this cycle from forw. network/regs
			locs: SmallNumberArray(0 to 2);	  -- location in FN
			vals: MwordArray(0 to 2);			  -- arg values
			locsNext: SmallNumberArray(0 to 2);	
		end record;

		type ArgumentStatusInfoArray is array(integer range <>) of ArgumentStatusInfo;

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
												newIntReturn => '0',
												hasIntReturn => '0',
												newExcReturn => '0',
												hasExcReturn => '0',												
												newFetchLock => '0',
												hasFetchLock => '0',
												
												--	exception => '0',
												exceptionCode => (others=>'0')
												);
end function;

function defaultClassInfo return InstructionClassInfo is
begin
	return InstructionClassInfo'(
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
	return InstructionArgValues'("000", (others=>'0'), (others=>'0'), (others=>'0'));
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
	res.argValues := defaultArgValues;
	res.result := (others => '0');
	res.target := (others => '0');
	return res;
end function;

end NewPipelineData;
