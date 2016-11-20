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
	parameter integer STACK_SIZE = 64;
	
	reg [5:0] stack [0:STACK_SIZE-1];	
	reg [5:0] front, back;

	reg [5:0] readTakeReg0, readTakeReg1, readTakeReg2, readTakeReg3,
					readTagsReg0, readTagsReg1, readTagsReg2, readTagsReg3;
	

	wire [2:0] nTake, nPut;

	integer i;
	
	assign nTake = take[0] + take[1] + take[2] + take[3],
			 nPut = put[0] + put[1] + put[2] + put[3];
		
	initial begin
		front = 0;	// -WIDTH
		back = 32;	// 32 - WIDTH;
		for (i=0; i < 32; i=i+1) begin
			stack[i] = i + 32;
		end;
		for (i=32; i < STACK_SIZE; i=i+1) begin
			stack[i] = 0;
		end;
		
			readTakeReg0 = 0;
			readTakeReg1 = 0;
			readTakeReg2 = 0;
			readTakeReg3 = 0;
			
			readTagsReg0 = 0;
			readTagsReg1 = 0;
			readTagsReg2 = 0;
			readTagsReg3 = 0;
	end;
	
	always @(posedge clk) begin
		if (rewind) begin
			front <= writeTag;
		end;
		
		if (enableTake) begin
				readTakeReg0 <= stack[(front + 0) % STACK_SIZE];
				readTakeReg1 <= stack[(front + 1) % STACK_SIZE];
				readTakeReg2 <= stack[(front + 2) % STACK_SIZE];
				readTakeReg3 <= stack[(front + 3) % STACK_SIZE];
				
				readTagsReg0 <= (front + 0) % STACK_SIZE;
				readTagsReg1 <= (front + 1) % STACK_SIZE;
				readTagsReg2 <= (front + 2) % STACK_SIZE;
				readTagsReg3 <= (front + 3) % STACK_SIZE;
			
			front <= //front + nTake;
						(front + WIDTH) % STACK_SIZE;
		end;
		
		if (enablePut) begin
			if (WIDTH >= 1)
				stack[(back + 0) % STACK_SIZE] <= writePut0;
			if (WIDTH >= 2)	
				stack[(back + put[0]) % STACK_SIZE] <= writePut1;
			if	(WIDTH >= 3)
				stack[(back + put[0] + put[1]) % STACK_SIZE] <= writePut2;
			if (WIDTH >= 4)
				stack[(back + put[0] + put[1] + put[2]) % STACK_SIZE] <= writePut3;
			
			back <= (back + nPut) % STACK_SIZE;
		end;
		
	end;
	
	// CAREFUL, TODO: bit sizes and N of regs are hard-coded, can result in error in the future!
//	assign readTake0 = stack[(front+0) % STACK_SIZE],
//			 readTake1 = stack[(front+1) % STACK_SIZE],
//			 readTake2 = stack[(front+2) % STACK_SIZE],
//			 readTake3 = stack[(front+3) % STACK_SIZE];
	
	assign readTags0 = (front + 0) % STACK_SIZE,
			 readTags1 = (front + 1) % STACK_SIZE,
			 readTags2 = (front + 2) % STACK_SIZE,
			 readTags3 = (front + 3) % STACK_SIZE;
	
	
		assign 
				readTake0 = readTakeReg0, readTake1 = readTakeReg1,
				readTake2 = readTakeReg2, readTake3 = readTakeReg3;
	
	/*	
		assign 
				readTags0 = readTagsReg0, readTags1 = readTagsReg1
				readTags2 = readTagsReg2, readTags3 = readTagsReg3;				
	*/
	
endmodule

