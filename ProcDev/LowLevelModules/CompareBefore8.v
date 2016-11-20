`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    02:43:57 01/07/2016 
// Design Name: 
// Module Name:    CompareBefore8 
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
module CompareBefore8(
    input [7:0] inA,
    input [7:0] inB,
    output outC
    );

	assign outC = isBefore(inA, inB);
	

	function isBefore(input [7:0] a, input [7:0] b);
		reg [7:0] c;
	begin
		c = a-b;
		isBefore = c[7];
	end;
	endfunction;

endmodule
