`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:32:34 10/11/2015 
// Design Name: 
// Module Name:    TempVerilogReservationList 
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
module TempVerilogReservationList(
	 input clk,
    input reset,
    input en,
	 
	 input rewind,
	 
	 input reserve,
	 input enableReserve,	 
	 input [5:0] selectReserve,
	 
	 input free,
	 input enableFree,
	 input [5:0] selectFree,
	 
	 input commit,
	 input enableCommit,	 
	 input [5:0] selectCommit,
	 
	 input [5:0] select0,
	 input [5:0] select1,
	 input [5:0] select2,
	 
	 // Ouputs: {used(i), ready(i)}
	 output [1:0] read0,
	 output [1:0] read1,
	 output [1:0] read2	 
    );
	
	reg used[0:63];
	reg ready[0:63];
	integer i, j;

	initial begin
		for (i=0; i<32; i=i+1) begin
			used[i] = 1;
			ready[i] = 1;
		end;
		for (i=32; i<64; i=i+1) begin
			used[i] = 0;
			ready[i] = 0;
		end;		
	end;
	
	always @(posedge clk) begin
		if (rewind) begin
			for (j=0; j<64; j=j+1) begin
				if (ready[j] == 0) 
					used[j] <= 0;
			end;
		end;
		
		if (reserve && enableReserve) begin
			used[selectReserve] <= 1;
		end;
		
		if (free && enableFree) begin
			used[selectFree] <= 0;
			ready[selectFree] <= 0;
			used[0] <= 1; // p0 always used!	
			ready[0] <= 1;
		end;
		
		if (commit && enableCommit) begin
			ready[selectCommit] <= 1;
		end;
		
	end;
	
	assign read0 = {used[select0], ready[select0]},
			 read1 = {used[select1], ready[select1]},
			 read2 = {used[select2], ready[select2]};

endmodule
