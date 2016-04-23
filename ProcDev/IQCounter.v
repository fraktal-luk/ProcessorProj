`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:54:42 01/05/2016 
// Design Name: 
// Module Name:    BufferCounter 
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
module IQCounter(
		input [7:0] capacity,
		input [7:0]	maxInput, 
		input [7:0] maxOutput,
	
		input [7:0] full,
			input lockAccept,
			input lockSend,
		input killAll,
		input [7:0] kill,
		
		input [7:0] nextAccepting,
		input [7:0] prevSending,
		
		output [7:0] living,
		
		output [7:0] wantSend,
		output [7:0] canAccept,
		
		output [7:0] sending,
		output [7:0] accepting,
		
		output [7:0] afterSending,
		output [7:0] afterReceiving
		
    );

	function [7:0] minByte(input [7:0] a, input [7:0] b, input c);
	begin
		if (c) begin
			minByte = 0;
		end
		else if (a > b) begin 
			minByte = b;
		end
		else begin
			minByte = a;
		end
	end;	
	endfunction;

	function [7:0] getLiving(input [7:0] a, input [7:0] b, input ka);
	begin
		if (ka) begin 
			getLiving = 0;
		end
		else begin
			getLiving = a - b;
		end
	end;	
	endfunction;
	
	//wire [7:0] 
	
//	always begin
//		if (killAll) 
//			living <= 0;
//		else
//			living <= full - kill;
//	end;
	
	assign living = getLiving(full, kill, killAll),
			 wantSend = minByte(maxOutput, living, lockSend),
			 canAccept = minByte(maxInput, capacity, lockAccept),

			 sending[0] = nextAccepting[0] && !lockSend, // minByte(nextAccepting, wantSend, 0),
			 afterSending = living - sending,	

			 accepting = minByte(canAccept, capacity - afterSending, 0),
			 afterReceiving = afterSending + prevSending;
			 
endmodule
