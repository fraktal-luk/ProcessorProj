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
module Test_RegMap2stage(
    input clk,
    input reset,
    input en,
			
	 //input commitAllow,
	 input rewind,
	 
	 //input reserve,
	 //input allowReserve, // for specific channel
	 input [4:0] selectReserve,
	 input [5:0] writeReserve,
	 
			input [4:0] selectReserveN,
			input [5:0] writeReserveN,	 

			input [4:0] selectReserve2,
			input [5:0] writeReserve2,	
			
			input [4:0] selectReserve3,
			input [5:0] writeReserve3,				
	 
	 //input commit,
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
	 
	 output [5:0] read0,
	 output [5:0] read1,
	 output [5:0] read2,

	 input [4:0] selectStable,

	 output [5:0] readStable	
    );

	wire commit = 1, allowCommit = 1, reserve = 1, allowReserve = 1;

	integer i;
	reg [5:0] stable [0:31];
	reg [5:0] newest [0:31];
		reg [5:0] last [0:31];
	
	initial begin
		for (i=0; i < 32; i = i+1) begin
			stable[i] = i;
			newest[i] = i;
		end;
	end;
	
	parameter integer nb = 1;
	
	wire [4:0] selRes0; wire [4:0] selCom0; wire [4:0] selRes1; wire [4:0] selCom1;
	wire [4:0] selRes2; wire [4:0] selCom2; wire [4:0] selRes3; wire [4:0] selCom3; 
	
	reg [4:0] selRes0p;
	reg [4:0] selRes1p;
	reg [4:0] selRes2p;
	reg [4:0] selRes3p;

	
	assign selRes0 = selectReserve, selCom0 = selectCommit, 
			selRes1 = selectReserveN, selCom1 = selectCommit2,
			selRes2 = selectReserve2, selCom2 = selectCommit3,
			selRes3 = selectReserve3, selCom3 = selectCommitN;
	
	
	// It has to contain: (stable, newest) 
	// 3 ports for renaming: regName -> table[regName].newest
	//	1 port to set newest: table[regName].newest = physName
	// 1 port to set stable 
	// signal to set for all: newest = stable
	
	always @(posedge clk) begin
		if (rewind) begin
			for (i=0; i < 32; i = i+1) begin
				//newest[i] <= stable[i];
			end;			
		end;
		
			selRes0p <= selRes0;
			selRes1p <= selRes1;
			selRes2p <= selRes2;
			selRes3p <= selRes3;
		
		if (reserve && allowReserve)  begin
		newest[{0,0,selRes0[4:nb+1]}] <= writeReserve;
		end;
		
				if (commit && allowCommit) begin
					stable[selCom0] <= writeCommit;
				end;
		
				if (reserve && allowReserve)  begin
		newest[{0,1,selRes1[4:nb+1]}] <= writeReserveN;
				end;
				
				if (commit && allowCommit) begin
					stable[selCom1] <= writeCommitN;
				end;		
				
				if (reserve && allowReserve)  begin
		newest[{1,0,selRes2[4:nb+1]}] <= writeReserve2;
				end;
				
				if (commit && allowCommit) begin
					stable[selCom2] <= writeCommit2;
				end;	

				if (reserve && allowReserve)  begin
		newest[{1,1,selRes3[4:nb+1]}] <= writeReserve3;
				end;
				
				if (commit && allowCommit) begin
					stable[selCom3] <= writeCommit3;
				end;	

			
		last[selRes0p] <= newest[{0,0,selRes0p[4:nb+1]}];
		last[selRes1p] <= newest[{0,1,selRes1p[4:nb+1]}];
		last[selRes2p] <= newest[{1,0,selRes2p[4:nb+1]}];
		last[selRes3p] <= newest[{1,1,selRes3p[4:nb+1]}];
							
	end;
	
	assign read0 = last[select0];
	assign read1 = last[select1];
	assign read2 = last[select2];	
	
	//assign readStable = stable[selectStable];
	
endmodule
