`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:54:00 01/23/2016 
// Design Name: 
// Module Name:    FlowCounter8 
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
module FlowCounter8(
    input clk,
	 input [7:0] value,
	 input loadEn,
    input [7:0] load,
	 input incEn,
    input [0:7] fullBits,
    output [7:0] newValue
    );
	
	//reg 
	//wire [7:0] content;

//	initial begin
//		content = 0;
//	end
	
	assign newValue = inc(value, incEn, fullBits, loadEn, load);
	
	//always @(posedge clk) begin
	function [7:0] inc(input [7:0] val, input incEn, input [0:7] fullBits, input loadEn, input [7:0] load);
		if (loadEn) 
			inc = load;
		else if (incEn)
			inc = val + fullBits[7] + fullBits[6] + fullBits[5]
									+ fullBits[4] + fullBits[3] + fullBits[2]
									+ fullBits[1] + fullBits[0];
		else
			inc = val;	
	endfunction
	//end
	
	//assign value = content;
endmodule
