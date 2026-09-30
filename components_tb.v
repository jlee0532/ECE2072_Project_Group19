`timescale 1ns/1ns
/*
Monash University ECE2072: Assignment 
This file contains a Verilog test bench to test the correctness of the individual 
    components used in the processor.

Please enter your student ID:

*/
module components_tb;

	// TODO: Implement the logic of your testbench here
	
	// ---- 1. Sign extender ----
	reg  [8:0]  se_in;     
	wire [15:0] se_ext;
	integer se_tests = 0, se_errors = 0;

	sign_extend test_sign_extend (
		 .in (se_in),
		 .ext(se_ext)
	);
	
	task check_se;
		input [15:0] expected;
		begin
			se_tests = se_tests + 1;
			if (se_ext !== expected)
			begin
				se_errors = se_errors + 1;
				$display("FAIL: input = %b, expected = %b, output = %b", se_in, expected, se_ext);
			end
			else
			begin
				$display("PASS: input = %b, output = %b", se_in, se_ext);
			end
		end
	endtask
	
	initial begin
		se_in = 9'b1;
		#10;
		check_se(16'b1);
		
		se_in = 9'b100000001;
		#10;
		check_se(16'b1111111100000001);
		
		se_in = 9'b1;
		#10;
		check_se(16'b0);
		
		$display("Total tests = %d|Errors = %d", se_tests, se_errors);
		$finish;
	end

endmodule
