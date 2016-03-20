`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:15:44 03/15/2016 
// Design Name: 
// Module Name:    VerilogCQRouting0 
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
module VerilogCQRouting0(
		input [7:0] newBase,
		input [7:0] tagA,
		input [7:0] tagB,
		input [7:0] tagC,
		input [7:0] tagD,
		input [7:0] tagKill,
		input execEventSignal,
		
		output [0:SIZE-1] takeA,
		output [0:SIZE-1] takeB,
		output [0:SIZE-1] takeC,
		output [0:SIZE-1] takeD,
		
		output [0:SIZE-1] kill
    );

	parameter integer SIZE = 4;
	
	assign 	takeA = acceptingVec(tagA, newBase),
				takeB = acceptingVec(tagB, newBase),
				takeC = acceptingVec(tagC, newBase),
				takeD = acceptingVec(tagD, newBase),
				kill = acceptingVec(tagKill, newBase);				
			
	function [0:SIZE-1] acceptingVec(input [7:0] vec, input [7:0] base);
	begin
		acceptingVec = 0;
		acceptingVec[(vec-base-1) % 256] = 1;	
	end	
	endfunction
	
//	function [0:SIZE-1] killingVec(input [7:0] vec, input [7:0] base);
//		integer i = 0;
//		integer j;
//	begin
//		j = (vec-base) % 256;
//		killingVec = 0;
//		for (i = 0; i < SIZE; i = i + 1) begin
//			if ((i >= j)) killingVec[i] = 1;
//		end;
//	end	
//	endfunction
	
endmodule
