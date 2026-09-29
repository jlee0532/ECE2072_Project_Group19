/*
Monash University ECE2072: Assignment 
This file contains Verilog code to implement individual components to be used in 
    the CPU.

Please enter your name and student ID: Jerome Lee Cheng Zhe (36538310) 
													Lee Ze Hon (36303968)

*/
module sign_extend(in, ext);
	/* 
	 * This module sign extends the 9-bit Din to a 16-bit output.
	 */
	 
	// TODO: Declare inputs and outputs
	input [8:0] in;
	output [15:0] ext;
	
	// TODO: implement logic
	assign ext = {in[8], in[8], in[8], in[8], in[8], in[8], in[8], in};
	
endmodule



module tick_FSM(rst, clk, enable, tick);
	/* 
	 * This module implements a tick FSM that will be used to
	 * control the actions of the control unit
	 */

	// TODO: Declare inputs and outputs
	input rst;
	input clk;
	input enable;
	output [3:0] tick;
	
	reg [3:0] cur_state;
	reg [3:0] next_state;
	
	// TODO: implement FSM
	always @(posedge clk) begin
		if (rst == 1) begin
			cur_state <= 4'b0001;
		end
		else begin
			cur_state <= next_state;
		end
	end
	
	always @(*) begin
		if (enable == 1) begin
			case(cur_state)
				4'b0001: next_state = 4'b0010;
				4'b0010: next_state = 4'b0100;
				4'b0100: next_state = 4'b1000;
				4'b1000: next_state = 4'b0001;
				default: begin
					next_state = 4'b0001;
				end
			endcase
		end
		else if (enable == 0) begin
			next_state = cur_state;
		end
	end
	
	assign tick = cur_state;
	
endmodule



module multiplexer(SignExtDin, R0, R1, R2, R3, R4, R5, R6, R7, G, sel, Bus);
	/* 
	 * This module takes 10 inputs and places the correct input onto the bus.
	 */
	// TODO: Declare inputs and outputs
	
	// TODO: implement logic


endmodule

module ALU (input_a, input_b, alu_op, result);
	/* 
	 * This module implements the arithmetic logic unit of the processor.
	 */
	 
	// TODO: declare inputs and outputs
	input [15:0] input_a;
	input [15:0] input_b;
	input [2:0] alu_op;
	output reg [15:0] result;

	reg [15:0] temp_a;
	
	// TODO: Implement ALU Logic:
	always @(*) begin
		case(alu_op) 
			3'b000: result = input_a * input_b;
			3'b001: result = input_a + input_b;
			3'b010: result = input_a - input_b;
			3'b011: begin
				if (input_a[15] == 0) begin
					result = input_b << input_a;
				end
				else begin
					temp_a = (~input_a) + 1;
					result = input_b >> temp_a;
				end
			end
			default: begin 
				result = 1'd0;
			end
		endcase
	end	
	
endmodule



module register_n(data_in, r_in, clk, Q, rst);


	// To set parameter N during instantiation, you can use:
	// register_n #(.N(num_bits)) reg_IR(.....), 
	// where num_bits is how many bits you want to set N to
	// and "..." is your usual input/output signals

	parameter N = 16;

	/* 
	 * This module implements registers that will be used in the processor.
	 */
	// TODO: Declare inputs, outputs, and parameter:
	
	// TODO: Implement register logic:
endmodule

