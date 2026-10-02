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
	
	// ---- 3. ALU ----
	reg [15:0]alu_a;
	reg [15:0]alu_b;
	reg [2:0] alu_op;
	wire [15:0] alu_result;
	integer alu_tests = 0, alu_errors = 0;
	
	ALU test_ALU(
		.input_a(alu_a),
		.input_b(alu_b),
		.alu_op(alu_op),
		.result(alu_result)
	);
	
	task check_alu;
		input [15:0] expected;
		begin
			alu_tests = alu_tests + 1;
			if (alu_result !== expected)
			begin
				alu_errors = alu_errors + 1;
				$display("FAIL [ALU]: input a = %b, input b = %b, operator = %b, expected = %b, got = %b", alu_a, alu_b, alu_op, expected, alu_result);
			end
			else
			begin
				$display("PASS [ALU]: input a = %b, input b = %b, operator = %b, expected = %b, got = %b", alu_a, alu_b, alu_op, expected, alu_result);
			end     
		end
	endtask
	
	// ---- 4. Multiplexer ----
	reg [15:0] mux_r0, mux_r1, mux_r2, mux_r3, mux_r4, mux_r5, mux_r6, mux_r7;
	reg [15:0] mux_G;
	reg [15:0] mux_SignExt;
	reg [3:0] mux_sel;
	wire [15:0] mux_out;
	integer mux_tests = 0, mux_errors = 0;
	
	multiplexer tests_mux(
		.R0(mux_r0), 
		.R1(mux_r1), 
		.R2(mux_r2), 
		.R3(mux_r3), 
		.R4(mux_r4), 
		.R5(mux_r5), 
		.R6(mux_r6), 
		.R7(mux_r7),
		.G(mux_G),
		.SignExtDin(mux_SignExt),
		.sel(mux_sel),
		.Bus(mux_out)
	);
	
	task check_mux;
		input [15:0] expected;
		begin
			mux_tests = mux_tests + 1;
			if (mux_out !== expected)
			begin
				mux_errors = mux_errors + 1;
				$display("FAIL [MUX]: selector bits = %b, expected = %b, got = %b", mux_sel, expected, mux_out);
			end
			else
			begin
				$display("PASS [MUX]: selector bits = %b, expected = %b, got = %b", mux_sel, expected, mux_out);
			end     
		end
	endtask
	
	// ---- 5. Register ----
	reg  [15:0] reg_din;
	reg         reg_rin, reg_rst;
	wire [15:0] reg_q;
	integer reg_tests = 0, reg_errors = 0;
			
	register_n tests_register(
		.data_in(reg_din),
		.r_in(reg_rin),
		.clk(clk),
		.rst(reg_rst),
		.Q(reg_q)
	);
	
	task check_reg;
		input [15:0] expected;
		begin
			reg_tests = reg_tests + 1;
			if (reg_q !== expected)
			begin
				reg_errors = reg_errors + 1;
				$display("FAIL [Register]: data_in = %b, r_in = %b, reset = %b, expected = %b, got = %b", reg_din, reg_rin, reg_rst, expected, reg_q);
			end
			else
			begin
				$display("PASS [Register]: data_in = %b, r_in = %b, reset = %b, expected = %b, got = %b", reg_din, reg_rin, reg_rst, expected, reg_q);
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
		
		// ---- TEST: ALU multiplication (000) ----   Author: <name>
		alu_a = 16'd3; alu_b = 16'd4; alu_op = 3'b000;
		#10;
		check_alu(16'd12);
		
		//anything * 0
		alu_a = 16'd3; alu_b = 16'd0; alu_op = 3'b000;
		#10;
		check_alu(16'b0);
		//overflow: a product bigger than 16 bits.
		alu_a = 16'd256; alu_b = 16'd256; alu_op = 3'b000;
		#10;
		check_alu(16'd0);
		
		//a negative number (two's complement) times a positive one
		alu_a = 16'd3; alu_b = -16'd4; alu_op = 3'b000;
		#10;
		check_alu(-16'd12);
		// ---- TEST: ALU addition (001) ----   Author: <name>
		//simple sum
		alu_a = 16'd3; alu_b = 16'd4; alu_op = 3'b001;
		#10;
		check_alu(16'd7);
		//carry out
		alu_a = 16'hFFFF; alu_b = 16'b1; alu_op = 3'b001;
		#10;
		check_alu(16'd0);
		//a negative plus a positive
		alu_a = 16'd4; alu_b = -16'd3; alu_op = 3'b001;
		#10;
		check_alu(16'd1);

		// ---- TEST: ALU subtraction (010) ----   Author: <name>
		//simple difference
		alu_a = 16'd4; alu_b = 16'd3; alu_op = 3'b010;
		#10;
		check_alu(16'd1);
		//a negative result
		alu_a = 16'd3; alu_b = 16'd5; alu_op = 3'b010;
		#10;
		check_alu(-16'd2);
		

		// ---- TEST: ALU signed shift (011) ----   Author: <name>
		//positive amount   
		alu_a = 16'd2; alu_b = 16'b1; alu_op = 3'b011;
		#10;
		check_alu(16'b100);
		//zero amount      
		alu_a = 16'd0; alu_b = 16'b1; alu_op = 3'b011;
		#10;
		check_alu(16'b1);
		// negative amount
		alu_a = -16'd2; alu_b = 16'b100; alu_op = 3'b011;
		#10;
		check_alu(16'b1);
		//large amount (16 or more)
		alu_a = 16'd16; alu_b = 16'hFFFF; alu_op = 3'b011;
		#10;
		check_alu(16'd0);
		
		// ---- TEST: Mux ---- 
		mux_r0 = 16'd0; mux_r1 = 16'd1; mux_r2 = 16'd2; mux_r3 = 16'd3; mux_r4 = 16'd4; mux_r5 = 16'd5; mux_r6 = 16'd6; mux_r7 = 16'd7; mux_G = 16'd8; mux_SignExt = 16'd9;
		
		mux_sel = 4'b0000;
		#10;
		check_mux(mux_SignExt);
		
		mux_sel = 4'b0001;
		#10;
		check_mux(mux_r0);
		
		mux_sel = 4'b0010;
		#10;
		check_mux(mux_r1);
		
		mux_sel = 4'b0011;
		#10;
		check_mux(mux_r2);
		
		mux_sel = 4'b0100;
		#10;
		check_mux(mux_r3);
		
		mux_sel = 4'b0101;
		#10;
		check_mux(mux_r4);
		
		mux_sel = 4'b0110;
		#10;
		check_mux(mux_r5);
		
		mux_sel = 4'b0111;
		#10;
		check_mux(mux_r6);
		
		mux_sel = 4'b1000;
		#10;
		check_mux(mux_r7);
		
		mux_sel = 4'b1001;
		#10;
		check_mux(mux_G);
		
		//Error
		mux_sel = 4'b1000;
		#10;
		check_mux(16'b0);
		
		// ---- TEST: Register ----
		// test reset 
		reg_din = 16'b1;
		@(negedge clk);
		reg_rst = 1; reg_rin = 0;
		
		@(posedge clk); #1;
		check_reg(16'b0);
		
		// test functionality
		@(negedge clk);#1;
		reg_rst = 0; reg_rin = 1;
		
		@(posedge clk); #1;
		check_reg(reg_din);
		
		//test hold
		@(negedge clk);#1;
		reg_rst = 0; reg_rin = 0;
		reg_din = 16'hFFFF; 
		
		@(posedge clk); #1;
		check_reg(16'b1);
		
		//test reset priority
		@(negedge clk);#1;
		reg_rst = 1; reg_rin = 1;
		
		@(posedge clk); #1;
		check_reg(16'b0);
		
		
		$display("Sign extender tests = %d|Errors = %d", se_tests, se_errors);
		$display("Tick FSM tests = %d|Errors = %d", tick_tests, tick_errors);
		$display("ALU tests = %d|Errors = %d", alu_tests, alu_errors);
		$display("Multiplexer tests = %d|Errors = %d", mux_tests, mux_errors);
		$display("Register tests = %d|Errors = %d", reg_tests, reg_errors);
		$finish;
	end

endmodule
