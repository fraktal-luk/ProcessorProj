`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    01:34:33 10/09/2015 
// Design Name: 
// Module Name:    TempVerilogFreeList 
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
module TempVerilogFreeList(
	 input clk,
    input reset,
    input en,
			
	 //input commitAllow,
	 input rewind,
	 
	 input [5:0] writeTag,
	 
	 input take,			// Command to take reg from list, even if instruction doesnt want it
	 input enableTake,	//	When instruction really wants to get new reg
	 output [5:0] readTake,
	 output [5:0] readTag,
	 
	 input put,				// Command to commit registers, even if nothing to commit
	 input enablePut,		//	When instuciton really has sth to commit
	 input [5:0] writePut
	 
    );
		
	reg [5:0] stack [0:63];	
	reg [5:0] front, back;

	integer i;

	initial begin
		front = 0;
		back = 32;
		for (i=0; i < 32; i=i+1) begin
			stack[i] = i + 32;
		end;
		for (i=32; i<64; i=i+1) begin
			stack[i] = 0;
		end;
	end;
	
	always @(posedge clk) begin
		if (rewind) begin
			front <= writeTag;
		end;
		
		if (take && enableTake) begin
			front <= front + 1;
		end;
		
		if (put && enablePut) begin
			stack[back] <= writePut;
			back <= back + 1;
		end;
		
	end;
	
	assign readTake = stack[front];
	assign readTag = take? front+1: front;
	
endmodule
