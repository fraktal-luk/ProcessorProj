`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:47:06 10/06/2015 
// Design Name: 
// Module Name:    TestVerilogRegFile 
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
module TestVerilogRegFile6P(
    input clk,
    input reset,
    input en,
			
	 input commitAllow,
	 
	 input [0:3] commitVec,
	 
		input readAllowT0,
		input readAllowT1,
		input readAllowT2,
		input readAllowT3,
	 
	 input [5:0] readSelect0,
	 input [5:0] readSelect1,
	 input [5:0] readSelect2,
	 	 
	 input [5:0] readSelect3,
	 input [5:0] readSelect4,
	 input [5:0] readSelect5,	 

	 input [5:0] readSelect6,
	 input [5:0] readSelect7,
	 input [5:0] readSelect8,
	 
	 input [5:0] readSelect9,
	 input [5:0] readSelect10,
	 input [5:0] readSelect11,
	 
	 
	 input [5:0] writeSelect0,
	 input [5:0] writeSelect1,
	 input [5:0] writeSelect2,
	 input [5:0] writeSelect3,
	 
	 input [31:0] writeData0,
	 input [31:0] writeData1,
	 input [31:0] writeData2,
	 input [31:0] writeData3,	 
	 
	 output [31:0] readData0,
	 output [31:0] readData1,
	 output [31:0] readData2,
	 
	 output [31:0] readData3,
	 output [31:0] readData4,
	 output [31:0] readData5,

	 output [31:0] readData6,
	 output [31:0] readData7,
	 output [31:0] readData8,

	 output [31:0] readData9,
	 output [31:0] readData10,
	 output [31:0] readData11	 
    );
	 
	//parameter integer N_READ = 3;
	parameter integer N_WRITE = 1;
	 
	integer i, j;
	reg [31:0] pr[0:63];
				
	reg [31:0] rd[0:11];
				
	initial begin
		//integer i;
		for (i = 0; i < 64; i = i + 1)
		begin
			pr[i] = 0;
			//	pr2[i] = 0;
		end

		for (j = 0; j < 12; j = j + 1)
		begin		
			rd[j] = 0;
		end
	end;

	always @(posedge clk)
	begin		

		// Synchronous reading
		if (readAllowT0) begin
			rd[0] <= pr[readSelect0];
			rd[1] <= pr[readSelect1];
			rd[2] <= pr[readSelect2];
		end;
		
		if (readAllowT1) begin
			rd[3] <= pr[readSelect3];
			rd[4] <= pr[readSelect4];
			rd[5] <= pr[readSelect5];
		end;
		
		if (readAllowT2) begin
			rd[6] <= pr[readSelect6];
			rd[7] <= pr[readSelect7];
			rd[8] <= pr[readSelect8];
		end;	
		
		if (readAllowT3) begin
			rd[9] <= pr[readSelect9];
			rd[10] <= pr[readSelect10];
			rd[11] <= pr[readSelect11];	
		end;
	
		if (commitAllow) begin
			// Writing	
			if (commitVec[0] && (N_WRITE > 0)) begin
				pr[writeSelect0[5:0]] <= writeData0;
			end;

			if (commitVec[1] && (N_WRITE > 1)) begin
				pr[writeSelect1[5:0]] <= writeData1;
			end;

			if (commitVec[2] && (N_WRITE > 2)) begin
				pr[writeSelect2[5:0]] <= writeData2;	
			end;
			
			if (commitVec[3] && (N_WRITE > 3)) begin
				pr[writeSelect3[5:0]] <= writeData3;	
			end;					
		end;	
		
		// CAREFUL! We resign from physically holding 0 value in p0,
		// cause the solution below creates huge logic.
		// But the value 0 can be provided by just the fact that 'missing' flag is cleared for r0 sources,
		// so register/FN value will not be accepted (the same case as with immediate arg)
		//pr[0] <= 0; 	// Important to keep always p0 = 0!		
	end;

	assign readData0 = rd[0];
	assign readData1 = rd[1];
	assign readData2 = rd[2];

	assign readData3 = rd[3];
	assign readData4 = rd[4];
	assign readData5 = rd[5];

	assign readData6 = rd[6];
	assign readData7 = rd[7];
	assign readData8 = rd[8];
	
	assign readData9 = rd[9];
	assign readData10 = rd[10];
	assign readData11 = rd[11];	

endmodule
