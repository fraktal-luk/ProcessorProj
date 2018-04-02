`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:18:58 10/11/2015 
// Design Name: 
// Module Name:    VerilogALU32 
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
module VerilogALU32(
		input clk,
		input reset,
		input en,
		
		input allow,
		
		input [5:0] funcSelect,
		
		input [31:0] dataIn0,
		input [31:0] dataIn1,
		input [31:0] dataIn2,
		
		input [4:0] c0,
		input [4:0] c1,
		
		output [31:0] dataOut0,
		output carryOut,		
		output [3:0] exceptionOut,
		
		output [31:0] dataOut0Pre,
		output carryOutPre,		
		output [3:0] exceptionOutPre		
    );

	reg [31:0] result;
	reg carry;
	reg [3:0] exc;

	wire [31:0] resultPre;
	wire carryPre;
	wire [3:0] excPre;

	assign dataOut0 = result;
	assign carryOut = carry;
	assign exceptionOut = exc;

	assign dataOut0Pre = resultPre,
			 carryOutPre = carryPre,
			 exceptionOutPre = excPre;	
	
	assign {excPre, carryPre, resultPre} = calculate(funcSelect, dataIn0, dataIn1, dataIn2, c0, c1);			
	
	initial begin
		result = 0;
		carry = 0;
		exc = 0;
	end;
	
	always @(posedge clk) begin
		if (allow) begin
			result <= resultPre;
			carry <= carryPre;
			exc <= excPre;
		end;
	end;
	
	reg [5:0] 
			logicAnd = 4;
	reg [5:0]		
			logicOr = 5;
	reg [5:0]					
			logicXor = 8;
	reg [5:0]		
			arithAdd = 1;
	reg [5:0]		
			arithSub = 2;
	reg [5:0]		
			logicShl = 6;
	reg [5:0]		
			logicShrl = 7;
	reg [5:0]		
			arithShra = 3;
	
	// 
	function [(4+1+31):0] calculate(
		input [5:0] funcSel,
		input [31:0] in0,
		input [31:0] in1,
		input [31:0] in2,
		input [4:0] c0,
		input [4:0] c1);
		
		reg [32:0] tempResult;	
		reg ov;
	begin	
		calculate = 0;
		
		case (funcSel)
			logicAnd:
				calculate = {4'b0000, 1'b0, in0 & in1};
				//calculate[31:0] = in0 & in1;
			logicOr:
				calculate = {4'b0000, 1'b0, in0 | in1};
				//calculate[31:0] = in0 | in1;				
			logicXor:
				calculate = {4'b0000, 1'b0, in0 ^ in1};			
			arithAdd: begin
				tempResult = {1'b0,in0} + {1'b0,in1};
				calculate[32:0] = tempResult;
				ov = (in0[31] == in1[31]) && (in0[31] != tempResult[31]);
				calculate[36:33] = {3'b0, ov};
			end
			arithSub: begin
				tempResult = {1'b0,in0} - {1'b0,in1};
				calculate[32:0] = tempResult;
				ov = (in0[31] != in1[31]) && (in0[31] != tempResult[31]);
				calculate[36:33] = {3'b0, ov};
			end
			
			logicShl:
				calculate = {4'b0000, 1'b0, in0 << c0};
				
			logicShrl:
				// CAREFUL, TODO: specify behavior - shift 0-31 or 1-32 for left/right etc
				calculate = {4'b0000, 1'b0, in0 >> c0};

			arithShra:
				// CAREFUL, TODO: fix behavior of sign bit
				calculate = {4'b0000, 1'b0, in0 >> c0};

			default: // Exc: unknown
				calculate = {4'b1000, 1'b0, 31'b0};

		endcase;
	end;		
	endfunction;
	
endmodule
