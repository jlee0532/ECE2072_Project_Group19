`timescale 1ns/1ns
/*
Monash University ECE2072: Assignment 
This file contains a Verilog test bench to test the correctness of the individual 
    components used in the processor.

Please enter your student ID:

*/
module components_tb;

	// TODO: Implement the logic of your testbench here
	
	reg clk;
	initial clk = 0;
	always #5 clk = ~clk; 
	
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
	
	// ---- 2. Tick FSM ----
	reg        tick_rst, tick_en;
	wire [3:0] tick_out;
	integer tick_tests = 0, tick_errors = 0;

	tick_FSM test_tick (
		.rst(tick_rst),
		.clk(clk),
		.enable(tick_en),
		.tick(tick_out)
	);

	task check_tick;
		input [3:0] expected;
		begin
			tick_tests = tick_tests + 1;
			if (tick_out !== expected)
			begin
				tick_errors = tick_errors + 1;
				$display("FAIL [Tick FSM]: rst = %b, en = %b, expected = %b, got = %b", tick_rst, tick_en, expected, tick_out);
			end
			else
			begin
				$display("PASS [Tick FSM]: rst = %b, en = %b, expected = %b, got = %b", tick_rst, tick_en, expected, tick_out);
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
		
		// ---- TEST: Tick FSM reset ----        
		@(negedge clk);
		tick_rst = 1; tick_en = 0;
		
		@(posedge clk); #1;
		check_tick(4'b0001);
		
		// ---- TEST: Tick FSM advance + wraparound ----
		@(negedge clk);
		tick_rst = 0; tick_en = 1;
		
		@(posedge clk); #1;
		check_tick(4'b0010);
		
		@(posedge clk); #1;
		check_tick(4'b0100);
		
		@(posedge clk); #1;
		check_tick(4'b1000);
		
		@(posedge clk); #1;
		check_tick(4'b0001);
		
		// ---- TEST: Tick FSM hold (enable = 0) ----
		@(posedge clk); #1;
		check_tick(4'b0010);
		
		@(negedge clk); #1;
		tick_rst = 0; tick_en = 0;
		
		@(posedge clk); #1;
		check_tick(4'b0010);
		
		// ---- TEST: Tick FSM reset priority ----
		@(negedge clk); #1;
		tick_rst = 1; tick_en = 1;
		
		@(posedge clk); #1;
		check_tick(4'b0001);
		
		$display("Sign extender tests = %d|Errors = %d", se_tests, se_errors);
		$display("Tick FSM tests = %d|Errors = %d", tick_tests, tick_errors);
		$finish;
	end

endmodule
