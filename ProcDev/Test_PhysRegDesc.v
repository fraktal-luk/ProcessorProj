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
module Test_PhysRegDesc(
    input clk,
    input reset,
    input en,
			
	 input commitAllow,
	 
	 input [0:2] readAck,
	 
	 input [5:0] readSelect0,
	 input [5:0] readSelect1,
	 input [5:0] readSelect2,
	 
	 input [0:2] readAckHi,
	 
	 input [5:0] readSelect3,
	 input [5:0] readSelect4,
	 input [5:0] readSelect5,	 

	 input [5:0] readSelect6,
	 input [5:0] readSelect7,
	 input [5:0] readSelect8,
	 
	 input [5:0] readSelect9,
	 input [5:0] readSelect10,
	 input [5:0] readSelect11,
	 
	 
	 input [0:2] writeAck,
	 
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
	integer i;
	reg [2:0] pr[0:63];
	//reg [31:0] pr2[1:0][0:15];

	reg [0:2] writeAckPrev;
	reg [5:0] writeSelect0prev;
	reg [5:0] writeSelect1prev;
	
	initial begin
		//integer i;
		for (i = 0; i < 64; i = i + 1)
		begin
			pr[i] = 0;
			//	pr2[i] = 0;
		end		
	end;

	always @(posedge clk)
	begin
		//pr2 <= pr;
			writeAckPrev = writeAck;
			
			writeSelect0prev = writeSelect0;
			writeSelect1prev = writeSelect1;
			
		if (commitAllow) begin
			// Writing	
			if (1) begin
				pr[writeSelect0[5:0]] <= writeData0;
			end;

			if (1) begin
				pr[writeSelect1[5:0]] <= writeData1;
			end;

			if (1) begin
				pr[writeSelect2[5:0]] <= writeData2;	
			end;
			
			if (1) begin
				pr[writeSelect3[5:0]] <= writeData3;	
			end;		
//			

		end;	
	end;

	assign readData0 = pr[readSelect0];
	assign readData1 = pr[readSelect1];
	assign readData2 = pr[readSelect2];

	assign readData3 = pr[readSelect3];
//	assign readData4 = pr[readSelect4];
//	assign readData5 = pr[readSelect5];
//
//	assign readData6 = pr[readSelect6];
//	assign readData7 = pr[readSelect7];
//	assign readData8 = pr[readSelect8];
//	
//	assign readData9 = pr[readSelect9];
//	assign readData10 = pr[readSelect10];
//	assign readData11 = pr[readSelect11];	

endmodule
