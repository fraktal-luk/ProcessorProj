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
module TempVerilogRegMap(
    input clk,
    input reset,
    input en,
			
	 input commitAllow,
	 input [0:3] commit,
	 
	 input rewind,
	 
	 input [0:3] reserve,
	 input reserveAllow, // for specific channel
	 
	 input [4:0] selectReserve,
	 input [5:0] writeReserve,
	 
			input [4:0] selectReserveN,
			input [5:0] writeReserveN,	 

			input [4:0] selectReserve2,
			input [5:0] writeReserve2,	
			
			input [4:0] selectReserve3,
			input [5:0] writeReserve3,				
	 
	 //input allowCommit, // for specific channel
	 input [4:0] selectCommit,
	 input [5:0] writeCommit,

			 input [4:0] selectCommitN,
			 input [5:0] writeCommitN,

			 input [4:0] selectCommit2,
			 input [5:0] writeCommit2,
			 
			 input [4:0] selectCommit3,
			 input [5:0] writeCommit3,			 
	 
	 input [4:0] select0,
	 input [4:0] select1,
	 input [4:0] select2,

	 input [4:0] select3,
	 input [4:0] select4,
	 input [4:0] select5,
	 
	 input [4:0] select6,
	 input [4:0] select7,
	 input [4:0] select8,
	 input [4:0] select9,
	 input [4:0] select10,
	 input [4:0] select11,	 
	 
	 output [5:0] read0,
	 output [5:0] read1,
	 output [5:0] read2,

	 output [5:0] read3,
	 output [5:0] read4,
	 output [5:0] read5,
	 output [5:0] read6,
	 output [5:0] read7,
	 output [5:0] read8,	 
	 output [5:0] read9,
	 output [5:0] read10,
	 output [5:0] read11,	 

	 input [4:0] selectStable,
	 input [4:0] selectStableN,
	 input [4:0] selectStable2,
	 input [4:0] selectStable3,
	
	 output [5:0] readStable,
	 output [5:0] readStableN,
	 output [5:0] readStable2,
	 output [5:0] readStable3
    );

	wire /*commit = 1,*/ allowCommit = 1, /*reserve = 1,*/ allowReserve = 1;

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
				newest[i] = stable[i];
			end;			
		end;
				
		if (reserve[0] && reserveAllow && (selectReserve != 5'b0))  begin
			newest[selectReserve] = writeReserve;
		end;
		
		if (commit[0] && commitAllow && (selectCommit != 5'b0)) begin
			stable[selectCommit] = writeCommit;
		end;
		
				if (reserve[1] && reserveAllow && (selectReserveN != 5'b0))  begin
					newest[selectReserveN] = writeReserveN;
				end;
				
				if (commit[1] && commitAllow && (selectCommitN != 5'b0)) begin
					stable[selectCommitN] = writeCommitN;
				end;		
				
				if (reserve[2] && reserveAllow && (selectReserve2 != 5'b0))  begin
					newest[selectReserve2] = writeReserve2;
				end;
				
				if (commit[2] && commitAllow && (selectCommit2 != 5'b0)) begin
					stable[selectCommit2] = writeCommit2;
				end;	

				if (reserve[3] && reserveAllow && (selectReserve3 != 5'b0))  begin
					newest[selectReserve3] = writeReserve3;
				end;
				
				if (commit[3] && commitAllow && (selectCommit3 != 5'b0)) begin
					stable[selectCommit3] = writeCommit3;
				end;					
	end;
	
	assign read0 = newest[select0];
	assign read1 = newest[select1];
	assign read2 = newest[select2];	
	
	assign read3 = newest[select3];
	assign read4 = newest[select4];
	assign read5 = newest[select5];

	assign read6 = newest[select6];
	assign read7 = newest[select7];
	assign read8 = newest[select8];

	assign read9 = newest[select9];
	assign read10 = newest[select10];
	assign read11 = newest[select11];	
	
	assign readStable = stable[selectStable],
			 readStableN = stable[selectStableN],
			 readStable2 = stable[selectStable2],
			 readStable3 = stable[selectStable3];
	
endmodule
