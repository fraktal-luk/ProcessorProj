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
module TestVerilogReadyRegTable64(
    input clk,
    input reset,
    input en,
			
	 //input commitAllow,
	 
	 //input [0:2] readAck,
	 
//	 input [5:0] readSelect0,
//	 input [5:0] readSelect1,
//	 input [5:0] readSelect2,
//	 
//	 //input [0:2] readAckHi,
//	 
//	 input [5:0] readSelect3,
//	 input [5:0] readSelect4,
//	 input [5:0] readSelect5,	 
//	 
//	 input [5:0] readSelect6,
//	 input [5:0] readSelect7,
//	 input [5:0] readSelect8,	 
//
//	 input [5:0] readSelect9,
//	 input [5:0] readSelect10,
//	 input [5:0] readSelect11,	 
//
//	 input [5:0] readSelect12,
//	 input [5:0] readSelect13,
//	 input [5:0] readSelect14,	 
//
//	 input [5:0] readSelect15,
//	 input [5:0] readSelect16,
//	 input [5:0] readSelect17,	 
	 
	 //input [0:3] writeAck,
		input [0:3] writeEnL,
	 input [5:0] writeSelect0,
	 input [5:0] writeSelect1,
	 input [5:0] writeSelect2,
	 input [5:0] writeSelect3,
		input [0:3] writeEnH,
	 input [5:0] writeSelect4,
	 input [5:0] writeSelect5,
	 input [5:0] writeSelect6,
	 input [5:0] writeSelect7,
	 
	 //input [1:0] writeData0,
	 //input [1:0] writeData1,
	 //input [1:0] writeData2,
	 //input [1:0] writeData3,	 
	 
//	 output readData0,
//	 output readData1,
//	 output readData2,
//	 
//	 output readData3,
//	 output readData4,
//	 output readData5,	 
//	 
//	 output readData6,
//	 output readData7,
//	 output readData8,
//	 
//	 output readData9,
//	 output readData10,
//	 output readData11,
//
//	 output readData12,
//	 output readData13,
//	 output readData14,
//
//	 output  readData15,
//	 output  readData16,
//	 output  readData17
		output [0:63] outputData
    );
	integer i;
	reg /*[0:0]*/ [0:63] pr;

	
	initial begin
		//integer i;
//		pr[0] = 1;
		for (i = 0; i < 64; i = i + 1)
		begin
			if (i <= 31) // Setting p0 : p31 to ready
				pr[i] = 1;
			else
				pr[i] = 0;
			//	pr2[i] = 0;
		end		
	end;

	always @(posedge clk)
	begin
					if (1) begin
						// Writing	
						if (writeEnL[0] && writeSelect0 != 0) begin
							pr[writeSelect0] <= 1; // writeData0;
						end;

						if (writeEnL[1] && writeSelect1 != 0) begin
							pr[writeSelect1] <= 1; // writeData1;	
						end;

						if (writeEnL[2] && writeSelect2 != 0) begin
							pr[writeSelect2] <= 1; // writeData1;	
						end;
						
						if (writeEnL[3] && writeSelect3 != 0) begin
							pr[writeSelect3] <= 1; // writeData3;	
						end;	


						if (writeEnH[0] && writeSelect4 != 0) begin
							pr[writeSelect4] <= 0; // writeData0;
						end;

						if (writeEnH[1] && writeSelect5 != 0) begin
							pr[writeSelect5] <= 0; // writeData1;	
						end;

						if (writeEnH[2] && writeSelect6 != 0) begin
							pr[writeSelect6] <= 0; // writeData1;	
						end;
						
						if (writeEnH[3] && writeSelect7 != 0) begin
							pr[writeSelect7] <= 0; // writeData3;	
						end;
					end;	
	end;

//	assign readData0 = pr[readSelect0];
//	assign readData1 = pr[readSelect1];
//	assign readData2 = pr[readSelect2];
//	assign readData3 = pr[readSelect3];
//	
//	assign readData4 = pr[readSelect4];
//	assign readData5 = pr[readSelect5];
//	assign readData6 = pr[readSelect6];
//	assign readData7 = pr[readSelect7];
//
//	assign readData8 = pr[readSelect8];
//	assign readData9 = pr[readSelect9];
//	assign readData10 = pr[readSelect10];
//	assign readData11 = pr[readSelect11];
//	
//	assign readData12 = pr[readSelect12];
//	assign readData13 = pr[readSelect13];
//	assign readData14 = pr[readSelect14];
//	assign readData15 = pr[readSelect15];
//	assign readData16 = pr[readSelect16];
//	assign readData17 = pr[readSelect17];
	assign outputData = pr;
endmodule
