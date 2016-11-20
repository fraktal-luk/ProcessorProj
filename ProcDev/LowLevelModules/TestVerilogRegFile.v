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
module TestVerilogRegFile(
    input clk,
    input reset,
    input en,
			
	 input commitAllow,
	 
	 input [0:2] readAck,
	 input [5:0] readSelect0,
	 input [5:0] readSelect1,
	 input [5:0] readSelect2,
	 input [0:2] writeAck,
	 input [5:0] writeSelect0,
	 input [5:0] writeSelect1,
	 
	 input [31:0] writeData0,
	 input [31:0] writeData1,
	 
	 output [31:0] readData0,
	 output [31:0] readData1,
	 output [31:0] readData2	
	 
    );
	integer i;
	reg [0:0] pr[0:63];

	reg [1:0] ro0, ro1, ro2;

	initial begin
		//integer i;
		ro0 = 0;
		ro1 = 0;
		ro2 = 0;
		
		for (i = 0; i < 64; i = i + 1)
			pr[i] = 0;
	end;

	always @(posedge clk)
	begin
		ro0 <= pr[readSelect0];
		ro1 <= pr[readSelect1];
		ro2 <= pr[readSelect2];		
	
		if (commitAllow) begin
			// Writing	
			if (writeAck[0] && (writeSelect0 != 6'b0)) begin
				pr[writeSelect0] <= writeData0;
				//pr[23] = 66;	
			end;

			if (writeAck[1] && writeSelect1 != 6'b0) begin
				pr[writeSelect1] <= writeData1;	
			end;
			
//			if (0   && writeAck[2] && writeSelect2 != 0) begin
//				pr[writeSelect2] = writeData2;	
//			end;		
		
		end;	
	end;

	assign readData0 = ro0; //pr[readSelect0];
	assign readData1 = ro1; //pr[readSelect1];
	assign readData2 = ro2; //pr[readSelect2];

//	always begin
//		if (readAck[0] && readSelect[0] != 0) begin
//			readData[0] = pr[readSelect[0]];	
//		end
//		else begin
//			readData[0] <= 0;
//		end;
//		
//		if (readAck[1] && readSelect[1] != 0) begin
//			readData[1] <= pr[readSelect[1]];	
//		end
//		else begin
//			readData[1] <= 0;
//		end;		
//		
//		if (readAck[2] && readSelect[2] != 0) begin
//			readData[2] <= pr[readSelect[2]];	
//		end
//		else begin
//			readData[2] <= 0;
//		end;		
//	end;

endmodule
