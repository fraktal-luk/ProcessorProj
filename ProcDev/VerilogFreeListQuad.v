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
module VerilogFreeListQuad(
	 input clk,
    input reset,
    input en,
			
	 //input commitAllow,
	 input rewind,
	 
	 input [5:0] writeTag,
	 
	 input [0:3] take,			// Command to take reg from list, even if instruction doesnt want it
	 input enableTake,	//	When instruction really wants to get new reg
	 output [5:0] readTake0,
	 output [5:0] readTake1,
	 output [5:0] readTake2,
	 output [5:0] readTake3,
	 
	 output [5:0] readTags0,
	 output [5:0] readTags1,
	 output [5:0] readTags2,
	 output [5:0] readTags3,	 
	 
	 input [0:3] put,				// Command to commit registers, even if nothing to commit
	 input enablePut,		//	When instuciton really has sth to commit
	 input [5:0] writePut0,
	 input [5:0] writePut1,
	 input [5:0] writePut2,
	 input [5:0] writePut3	 
    );
		
	parameter //unsigned 
				 integer
				 WIDTH = 4;	
		
	reg [5:0] stack [0:63];	
	reg [5:0] front, back;

	wire [2:0] nTake, nPut;

	integer i;
	
	assign nTake = take[0] + take[1] + take[2] + take[3],
			 nPut = put[0] + put[1] + put[2] + put[3];
		
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
		
		if (enableTake) begin
			front <= front + nTake;
		end;
		
		if (enablePut) begin
			if (WIDTH >= 1)
				stack[(back + 0) % 64] <= writePut0;
			if (WIDTH >= 2)	
				stack[(back + put[0]) % 64] <= writePut1;
			if	(WIDTH >= 3)
				stack[(back + put[0] + put[1]) % 64] <= writePut2;
			if (WIDTH >= 4)
				stack[(back + put[0] + put[1] + put[2]) % 64] <= writePut3;
			back <= back + nPut;
		end;
		
	end;
	
	// CAREFUL, TODO: bit sizes and N of regs are hard-coded, can result in error in the future!
	assign readTake0 = stack[(front+0) % 64],
			 readTake1 = stack[(front+1) % 64],
			 readTake2 = stack[(front+2) % 64],
			 readTake3 = stack[(front+3) % 64];
	
	assign readTags0 = front + take[0],
			 readTags1 = front + take[0] + take[1],
			 readTags2 = front + take[0] + take[1] + take[2],
			 readTags3 = front + take[0] + take[1] + take[2] + take[3];
	
endmodule

