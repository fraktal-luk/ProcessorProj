`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:43:21 10/08/2015 
// Design Name: 
// Module Name:    TempVerilogRegistersVirtual 
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
module TempVerilogRegistersVirtual(
    input clk,
    input reset,
    input en,
			
	 //input commitAllow,
	 input rewind,
	 
	 input reserve,
	 input allowReserve, // for specific channel
	 input [4:0] selectReserve,
	 input [5:0] writeReserve,
	 
	 input commit,
	 input allowCommit, // for specific channel
	 input [4:0] selectCommit,
	 input [5:0] writeCommit,
	 
	 input [4:0] select0,
	 input [4:0] select1,
	 input [4:0] select2,
	 
	 output [5:0] read0,
	 output [5:0] read1,
	 output [5:0] read2,

	 input [4:0] selectStable,

	 output [5:0] readStable	
    );

	integer i;
	reg [5:0] stable [0:31];
	reg [5:0] newest [0:31];
	
	initial begin
		for (i=0; i < 32; i = i+1) begin
			stable[i] = i;
			newest[i] = i;
		end;
	end;
	
	// It has to contain: (stable, newest) 
	// 3 ports for renaming: regName -> table[regName].newest
	//	1 port to set newest: table[regName].newest = physName
	// 1 port to set stable 
	// signal to set for all: newest = stable
	
	always @(posedge clk) begin
		if (rewind) begin
			for (i=0; i < 32; i = i+1) begin
				newest[i] <= stable[i];
			end;			
		end;
				
		if (reserve && allowReserve && (selectReserve != 5'b0))  begin
			newest[selectReserve] <= writeReserve;
		end;
		
		if (commit && allowCommit && (selectCommit != 5'b0)) begin
			stable[selectCommit] <= writeCommit;
		end;
	end;
	
	assign read0 = newest[select0];
	assign read1 = newest[select1];
	assign read2 = newest[select2];	
	
	assign readStable = stable[selectStable];
	
endmodule
