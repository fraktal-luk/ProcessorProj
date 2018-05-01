`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:09:39 09/25/2015 
// Design Name: 
// Module Name:    TestVerilogModule 
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
module TestVerilogModule(
    input [31:0] inA,
    input [31:0] inB,
    output [31:0] outA
    );

	assign outA = inA + inB;

endmodule
