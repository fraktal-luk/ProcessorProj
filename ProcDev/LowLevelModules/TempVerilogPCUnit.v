`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:37:35 03/26/2016 
// Design Name: 
// Module Name:    TempVerilogPCUnit 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module TempVerilogPCUnit(
		input [MWORD_SIZE-1:0] INT_BASE,
		input [MWORD_SIZE-1:0] EXC_BASE,

		input [MWORD_SIZE-1:0] oldIPBase,
		
		input [MWORD_SIZE-1:0] insTarget,
		input [MWORD_SIZE-1:0] insResult,
		input [INT_CODE_SIZE-1:0] intCode,
		input [EXC_CODE_SIZE-1:0] excCode,
		
		input selectInt,
		input selectExc,
		input selectTarget,
		input selectResult,
		input selectMoved,
		
		output [MWORD_SIZE-1:0] newIP,
		output [SMALL_NUMBER_SIZE-1:0] newSize/*,	
		output [SMALL_NUMBER_SIZE-1:0] newShift /**/			
    );
parameter integer MWORD_SIZE = 32;
parameter integer SMALL_NUMBER_SIZE = 8;
parameter integer ALIGN_BITS = 2;
parameter integer INT_CODE_SIZE = SMALL_NUMBER_SIZE;
parameter integer EXC_CODE_SIZE = SMALL_NUMBER_SIZE;

//parameter [MWORD_SIZE-1:0] INT_BASE = 0;
//parameter [MWORD_SIZE-1:0] EXC_BASE = 0;


reg [MWORD_SIZE-1:0] pcInc;

initial begin 
	pcInc = 0;
	pcInc[ALIGN_BITS] = 1;
end

assign newIP = getPC(oldIPBase, pcInc, insTarget, insResult, intCode, excCode,
							selectInt, selectExc, selectTarget, selectResult/**/); // oldIPBase + pcInc;

assign newSize = (pcInc - newIP[ALIGN_BITS-1:0]) >> 1; 


function [MWORD_SIZE-1:0] getPC(
					input [MWORD_SIZE-1:0] oldIPBase, 
					input [MWORD_SIZE-1:0] pcInc,
					input [MWORD_SIZE-1:0] insTarget, 
					input [MWORD_SIZE-1:0] insResult, 
					input [SMALL_NUMBER_SIZE-1:0] intCode, 
					input [SMALL_NUMBER_SIZE-1:0] excCode, 
					input selectInt,
					input selectExc,
					input selectTarget,
					input selectResult/**/);										
begin
	if (selectInt) begin
		getPC = {INT_BASE[MWORD_SIZE-1:INT_CODE_SIZE], intCode}; //INT_BASE | {intCode, 2'b0};
	end	
	else if (selectExc) begin
		getPC = {EXC_BASE[MWORD_SIZE-1:EXC_CODE_SIZE], excCode}; //EXC_BASE | {excCode, 2'b0};
	end	
	else if (selectTarget)
		getPC = insTarget;
	else if (selectResult)
		getPC = insResult;
	else // Let's not rely on selectMoved, cause it'd create additional, incorrect control path 
		getPC = oldIPBase + pcInc;
				//{oldIPBase[MWORD_SIZE-1:ALIGN_BITS] + 1, oldIPBase[ALIGN_BITS-1:0]};		
end
endfunction

endmodule
