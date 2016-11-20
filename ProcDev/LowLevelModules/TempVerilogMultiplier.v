`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    01:32:04 10/14/2015 
// Design Name: 
// Module Name:    TempVerilogMultiplier 
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
module TempVerilogMultiplier(
	 input clk,
    input reset,
    input en,
			
	 input [31:0] in0,	
	 input [31:0] in1,
	 input [31:0] in2,	
	
	 input signedOp,
	
	 output [63:0] out0,
	 output [63:0] out0Pre
    );

//	parameter s = 01;
	wire s;

//		assign in0 = 27;
//		assign in1 = -31;
//
//		reg clk2;
//		initial begin
//			clk2 = 1;
//			#1 clk2 = 0;
//			#1 clk2 = 1;
//			#1 clk2 = 0;
//			#1 clk2 = 1;
//		end;

	reg [63:0] result;
	wire [63:0] resultPre;

	wire [63:0] level0 [0:31]; 
	reg [63:0] level1 [0:7];
	reg [63:0] level2 [0:1];
	
	integer i;
	genvar j;
	
	assign s = signedOp;
	
	assign out0 = result;
	assign out0Pre = resultPre;
	//assign out0[31:0] = result;
	//assign out0[63:32] = 0;
	
	initial begin			
		for (i=0; i<8; i=i+1)
			level1[i] = 0;

		for (i=0; i<2; i=i+1)
			level2[i] = 0;			
	end;
	
	generate 
		for (j=0; j<31; j=j+1) begin
			assign level0[j] =  (({sign32(in1,s), in1}) << j) & duplicate(in0[j]);
		end;
		
		for (j=31; j<32; j=j+1) begin
			assign level0[j] =  -(({sign32(in1,s), in1}) << j) & duplicate(in0[j]);
		end;
		
	endgenerate;
		
	
	always @(posedge clk) begin
		for (i=0; i<8; i=i+1) begin
			level1[i] <= level0[i] + level0[i+8] + level0[i+16] + level0[i+24];
		end;
		
		for (i=0; i<2; i=i+1) begin
			level2[i] <= level1[i] + level1[i+2] + level1[i+4] + level1[i+6];
		end;		
		
		result <= resultPre; 
	end;
	
	assign resultPre = level2[0] + level2[1];
	
	function [63:0] duplicate(b);
		integer k;
	begin
		for (k=0; k<64; k=k+1)
			duplicate[k] = b;
	end;	
	endfunction;

	function [31:0] sign32(input [31:0] b, input s);
		integer k;
	begin
		for (k=0; k<32; k=k+1)
			sign32[k] = b[31] & s;
	end;	
	endfunction;
	
endmodule
