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



package BasicFlow is

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

		type ContentStateSimple is record
			isFull: std_logic;
			isNew: std_logic;
		end record;

constant DEFAULT_FD_SIMPLE: FlowDriveSimple := FlowDriveSimple'(others => '0');
constant DEFAULT_FR_SIMPLE: FlowResponseSimple := FlowResponseSimple'(others => '0');
constant DEFAULT_CS_SIMPLE: ContentStateSimple := ContentStateSimple'(others => '0');

		-- CAREFUL: below functions for Simple slot have some duplicate code
		function nextContentState(cs: ContentStateSimple; drive: FlowDriveSimple; reset, en: std_logic)
		return ContentStateSimple is
			variable res: ContentStateSimple := cs;
			variable isNewSig: std_logic := '0';
			variable fullSig: std_logic := '0';
			variable livingSig: std_logic := '0';		
			
			variable canAccept: std_logic := '0';
			variable wantSend: std_logic := '0';
			variable acceptingSig: std_logic := '0';
			variable sendingSig: std_logic := '0';	

			variable afterSending: std_logic := '0';
			variable afterReceiving: std_logic := '0';			
		begin
			if reset = '1' then
				res.isFull := '0';
				res.isNew := '0';
			elsif en = '0' then -- If no enable, don't change
				return res;
			end if;
			
			livingSig := cs.isFull and not drive.kill; -- CHECK: killing mechanism correct?

			canAccept := not drive.lockAccept;
			wantSend := livingSig and not drive.lockSend;
			
			-- Determine what will be sent
			sendingSig := drive.nextAccepting and wantSend;
			afterSending := livingSig and not sendingSig;

			-- Determine what will be received
			acceptingSig := canAccept and not afterSending;	
			afterReceiving := afterSending or drive.prevSending;
			
			res.isFull := afterReceiving;
			res.isNew := drive.prevSending;
			
			return res;
		end function;
		
		
		function getResponse(cs: ContentStateSimple; drive: FlowDriveSimple) return FlowResponseSimple is
			variable res: FlowResponseSimple;
			variable isNewSig: std_logic := '0';
			variable fullSig: std_logic := '0';
			variable livingSig: std_logic := '0';		
			
			variable canAccept: std_logic := '0';
			variable wantSend: std_logic := '0';
			variable acceptingSig: std_logic := '0';
			variable sendingSig: std_logic := '0';	

			variable afterSending: std_logic := '0';
			variable afterReceiving: std_logic := '0';			
		begin

			livingSig := cs.isFull and not drive.kill; -- CHECK: killing mechanism correct?

			canAccept := not drive.lockAccept;
			wantSend := livingSig and not drive.lockSend;
			
			-- Determine what will be sent
			sendingSig := drive.nextAccepting and wantSend;
			afterSending := livingSig and not sendingSig;

			-- Determine what will be received
			acceptingSig := canAccept and not afterSending;	
			afterReceiving := afterSending or drive.prevSending;

			res.sending := sendingSig;
			res.accepting := acceptingSig;
			res.full := cs.isFull;	
			res.living := livingSig;	
			res.isNew := cs.isNew;
					
			return res;
		end function;


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


end BasicFlow;



package body BasicFlow is


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

end BasicFlow;
