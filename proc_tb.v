`timescale 1ns/1ns
/*
Monash University ECE2072: Assignment 
This file contains a Verilog test bench to test the correctness of the processor.

Please enter your student ID: Jerome Lee Cheng Zhe (36538310) 
										Lee Ze Hon (36303968)

*/
module proc_tb;

	// setup wires/registers:
	reg [8:0] SW;
	reg [1:0] KEY;

	wire [15:0] bus;
	wire [15:0] R0, R1, R2, R3, R4, R5, R6, R7;
	
	wire clk;
	assign clk = ~KEY[1];
	
	reg [4:0] pass_count;
	reg [4:0] fail_count;
	reg [18:1] test_result;
	integer test_count;
	
	// instantiate module
	simple_proc test(.clk(clk), 
							.rst(~KEY[0]), 
							.din(SW[8:0]), 
							.bus(bus), 
							.R0(R0), .R1(R1), .R2(R2), .R3(R3), .R4(R4), .R5(R5), .R6(R6), .R7(R7));
		
	// setup clock signal
	always begin
		#5;
		KEY[1] = ~KEY[1];
	end
	
initial begin

	pass_count = 0;
	fail_count = 0;
	test_result = 18'b0;
	
	SW = 9'b000000000;
	KEY = 2'b00;

	// Reset processor
	KEY[0] = 1'b0;
	#12;
	KEY[0] = 1'b1;
	

	// Testing the move immediate instruction (movi)
	// Test 1: movi R3, 7 (positive value)
		$display("");
		$display("TEST 1: movi R3, 7");

		// Reset processor
		KEY[0] = 1'b0;
		#12;
		KEY[0] = 1'b1;

		// T1: instruction
		// opcode=111, Rx=011, unused
		SW = 9'b111011000;

		@(posedge clk);

		// T2: immediate value 7
		SW = 9'b000000111;

		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		// Check result
		if (R3 == 16'd7) begin
			$display("PASS: R3 = %d", R3);
			pass_count = pass_count + 1;
			test_result[1] = 1'b1;
		end
		else begin
			$display("FAIL: R3 = %d, expected 7", R3);
			fail_count = fail_count + 1;
			test_result[1] = 1'b0;
		end
	
	// Testing the move immediate instruction (movi)
	// Test 2: movi R7, -11 (negative value)
		$display("");
		$display("TEST 2: movi R7, -11");
		
		// Reset processor
		KEY[0] = 1'b0;
		#12;
		KEY[0] = 1'b1;

		// T1: instruction
		// opcode=111, Rx=111, unused
		SW = 9'b111111000;

		@(posedge clk);

		// T2: immediate value -11
		SW = 9'b111110101;

		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		// Check result
		if (R7 == ~(16'd11) + 1'b1) begin
			$display("PASS: R7 = -%d", (~(R7)+1'b1));
			pass_count = pass_count + 1;
			test_result[2] = 1'b1;
		end
		else begin
		  $display("FAIL: R7 = %d, expected -11", (~(R7)+1'b1));
		  fail_count = fail_count + 1;
			test_result[2] = 1'b0;
		end
		
		
	// Testing the add instruction (add)
	// Test 3: add R2, R4 (positive + positive = positive)
	// Set R2 = 8, R4 = 9
		$display("");
		$display("TEST 3: add R2, R4 | Set R2 = 8, R4 = 9");
		
		//Reset processor
		KEY[0] = 1'b0;
		#12
		KEY[0] = 1'b1;
		
		// movi R2, 8
		SW = 9'b111010000;
		@(posedge clk);
		SW = 9'b000001000;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// movi R4, 9
		SW = 9'b111100000;
		@(posedge clk);
		SW = 9'b000001001;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// check before add
		$display("BEFORE ADD: R2 = %d, R4 = %d", R2, R4);
		
		// T1: instruction
		// opcode=001, Rx=010, Ry=100
		SW = 9'b001010100;
		
		// wait for all 4 ticks process
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		#1; // Small delay for the register to update

		// Check result
		if (R2 == 16'd17) begin
			$display("PASS: R2 = %d", R2);
			pass_count = pass_count + 1;
			test_result[3] = 1'b1;
		end
		else begin
			$display("FAIL: R2 = %d, expected 17", R2);
			fail_count = fail_count + 1;
			test_result[3] = 1'b0;
		end
		
		
	// Testing the add instruction (add)
	// Test 4: add R3, R5 (negative + positive = positive)
	// Set R3 = -3, R5 = 5
		$display("");
		$display("TEST 4: add R3, R5 | Set R3 = -3, R4 = 5");
		
		//Reset processor
		KEY[0] = 1'b0;
		#12
		KEY[0] = 1'b1;
		
		// movi R3, -3
		SW = 9'b111011000;
		@(posedge clk);
		SW = 9'b111111101;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// movi R5, 5
		SW = 9'b111101000;
		@(posedge clk);
		SW = 9'b000000101;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// check before add
		$display("BEFORE ADD: R3 = -%d, R5 = %d", (~(R3)+1'b1), R5);
		
		// T1: instruction
		// opcode=001, Rx=011, Ry=101
		SW = 9'b001011101;
		
		// wait for all 4 ticks process
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		#1;

		// Check result
		if (R3 == 16'd2) begin
			$display("PASS: R3 = %d", R3);
			pass_count = pass_count + 1;
			test_result[4] = 1'b1;
		end
		else begin
			$display("FAIL: R3 = %d, expected 2", R3);
			fail_count = fail_count + 1;
			test_result[4] = 1'b0;
		end
		
		
	// Testing the add instruction (add)
	// Test 5: add R4, R6 (negative + positive = negative)
	// Set R4 = -13, R6 = 3
		$display("");
		$display("TEST 5: add R4, R6 | Set R4 = -13, R6 = 3");
		
		//Reset processor
		KEY[0] = 1'b0;
		#12
		KEY[0] = 1'b1;
		
		// movi R4, -13
		SW = 9'b111100000;
		@(posedge clk);
		SW = 9'b111110011;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// movi R6, 3
		SW = 9'b111110000;
		@(posedge clk);
		SW = 9'b000000011;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// check before add
		$display("BEFORE ADD: R4 = -%d, R6 = %d", (~(R4)+1'b1), R6);
		
		// T1: instruction
		// opcode=001, Rx=100, Ry=110
		SW = 9'b001100110;
		
		// wait for all 4 ticks process
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		#1;

		// Check result
		if (R4 == ~(16'd10) + 1'b1) begin
			$display("PASS: R4 = -%d", (~(R4)+1'b1));
			pass_count = pass_count + 1;
			test_result[5] = 1'b1;
		end
		else begin
			$display("FAIL: R4 = %d, expected -10", (~(R4)+1'b1));
			fail_count = fail_count + 1;
			test_result[5] = 1'b0;
		end
		
		
	// Testing the add instruction (add)
	// Test 6: add R5, R7 (negative + negative = negative)
	// Set R5 = -13, R7 = -3
		$display("");
		$display("TEST 6: add R5, R7 | Set R5 = -13, R7 = -3");
		
		//Reset processor
		KEY[0] = 1'b0;
		#12
		KEY[0] = 1'b1;
		
		// movi R5, -13
		SW = 9'b111101000;
		@(posedge clk);
		SW = 9'b111110011;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		// movi R7, -3
		SW = 9'b111111000;
		@(posedge clk);
		SW = 9'b111111101;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// check before add
		$display("BEFORE ADD: R5 = -%d, R7 = -%d", (~(R5)+1'b1), (~(R7)+1'b1));
		
		// T1: instruction
		// opcode=001, Rx=101, Ry=111
		SW = 9'b001101111;
		
		// wait for all 4 ticks process
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		#1;

		// Check result
		if (R5 == ~(16'd16) + 1'b1) begin
			$display("PASS: R5 = -%d", (~(R5)+1'b1));
			pass_count = pass_count + 1;
			test_result[6] = 1'b1;
		end
		else begin
			$display("FAIL: R5 = %d, expected -16", (~(R5)+1'b1));
			fail_count = fail_count + 1;
			test_result[6] = 1'b0;
		end

		
	// Testing the add immediate instruction (addi)
	// Test 7: addi R0, 4 (positive + positive = positive)
	// Set R0 = 6
		$display("");
		$display("TEST 7: addi R0, 4 | Set R0 = 6");
		
		// Reset processor
		KEY[0] = 1'b0;
		#12;
		KEY[0] = 1'b1;
		
		// movi R0, 6
		SW = 9'b111000000;
		@(posedge clk);
		SW = 9'b000000110;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// check before add
		$display("BEFORE ADD: R0 = %d", R0);
		
		// T1: instruction
		// opcode=010, Rx=000, Ry=000
		SW = 9'b010000000;
		
		@(posedge clk);
		
		// T2: immediate value 4
		SW = 9'b000000100;
		
		// Wait for T2, T3 and T4
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		#1;
		
		// Check result
		if (R0 == 16'd10) begin
			$display("PASS: R0 = %d", R0);
			pass_count = pass_count + 1;
			test_result[7] = 1'b1;
		end
		else begin
			$display("FAIL: R0 = %d, expected 10", R0);
			fail_count = fail_count + 1;
			test_result[7] = 1'b0;
		end
		
	
	// Testing the add immediate instruction (addi)
	// Test 8: addi R0, -7 (positive + negative = negative)
	// Set R0 = 6
		$display("");
		$display("TEST 8: addi R0, -7 | Set R0 = 6");
		
		// Reset processor
		KEY[0] = 1'b0;
		#12;
		KEY[0] = 1'b1;
		
		// movi R0, 6
		SW = 9'b111000000;
		@(posedge clk);
		SW = 9'b000000110;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// check before add
		$display("BEFORE ADD: R0 = %d", R0);
		
		// T1: instruction
		// opcode=010, Rx=000, Ry=000
		SW = 9'b010000000;
		
		@(posedge clk);
		
		// T2: immediate value -7
		SW = 9'b111111001;
		
		// Wait for T2, T3 and T4
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		#1;
		
		// Check result
		if (R0 == ~(16'd1) + 1'b1) begin
			$display("PASS: R0 = -%d", (~(R0)+1'b1));
			pass_count = pass_count + 1;
			test_result[8] = 1'b1;
		end
		else begin
			$display("FAIL: R0 = -%d, expected -1", (~(R0)+1'b1));
			fail_count = fail_count + 1;
			test_result[8] = 1'b0;
		end
		
		
	// Testing the add immediate instruction (addi)
	// Test 9: addi R0, -7 (positive + negative = positive)
	// Set R0 = 21
		$display("");
		$display("TEST 9: addi R0, -7 | Set R0 = 21");
		
		// Reset processor
		KEY[0] = 1'b0;
		#12;
		KEY[0] = 1'b1;
		
		// movi R0, 21
		SW = 9'b111000000;
		@(posedge clk);
		SW = 9'b000010101;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// check before add
		$display("BEFORE ADD: R0 = %d", R0);
		
		// T1: instruction
		// opcode=010, Rx=000, Ry=000
		SW = 9'b010000000;
		
		@(posedge clk);
		
		// T2: immediate value -7
		SW = 9'b111111001;
		
		// Wait for T2, T3 and T4
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		#1;
		
		// Check result
		if (R0 == 16'd14) begin
			$display("PASS: R0 = %d", R0);
			pass_count = pass_count + 1;
			test_result[9] = 1'b1;
		end
		else begin
			$display("FAIL: R0 = %d, expected 14", R0);
			fail_count = fail_count + 1;
			test_result[9] = 1'b0;
		end

	
	// Testing the add immediate instruction (addi)
	// Test 10: addi R0, -7 (negative + negative = negative)
	// Set R0 = -21
		$display("");
		$display("TEST 10: addi R0, -7 | Set R0 = -21");
		
		// Reset processor
		KEY[0] = 1'b0;
		#12;
		KEY[0] = 1'b1;
		
		// movi R0, -21
		SW = 9'b111000000;
		@(posedge clk);
		SW = 9'b111101011;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		// check before add
		$display("BEFORE ADD: R0 = -%d", (~(R0)+1'b1));
		
		// T1: instruction
		// opcode=010, Rx=000, Ry=000
		SW = 9'b010000000;
		
		@(posedge clk);
		
		// T2: immediate value -7
		SW = 9'b111111001;
		
		// Wait for T2, T3 and T4
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		
		#1;
		
		// Check result
		if (R0 == (~(16'd28)+1'b1)) begin
			$display("PASS: R0 = -%d", (~(R0)+1'b1));
			pass_count = pass_count + 1;
			test_result[10] = 1'b1;
		end
		else begin
			$display("FAIL: R0 = %d, expected -28", (~(R0)+1'b1));
			fail_count = fail_count + 1;
			test_result[10] = 1'b0;
		end
		
		
		
	// Testing the subtract instruction (sub)
	// Test 11: sub R1, R2 (positive - positive = positive)
	// Set R1 = 10, R2 = 3
		$display("");
		$display("TEST 11: sub R1, R2 | Set R1 = 10, R2 = 3");

		// Reset processor
		KEY[0] = 1'b0;
		#12;
		KEY[0] = 1'b1;

		// movi R1, 10
		SW = 9'b111001000;
		@(posedge clk);
		SW = 9'b000001010;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		// movi R2, 3
		SW = 9'b111010000;
		@(posedge clk);
		SW = 9'b000000011;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		// check before sub
		$display("BEFORE SUB: R1 = %d, R2 = %d", R1, R2);

		// T1: instruction
		// opcode=011, Rx=001, Ry=010
		SW = 9'b011001010;

		// wait for all 4 ticks process
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		#1;

		// Check result
		if (R1 == 16'd7) begin
			$display("PASS: R1 = %d", R1);
			pass_count = pass_count + 1;
			test_result[11] = 1'b1;
		end
		else begin
			$display("FAIL: R1 = %d, expected 7", R1);
			fail_count = fail_count + 1;
			test_result[11] = 1'b0;
		end
		
		
	// Testing the subtract instruction (sub)
	// Test 12: sub R1, R2 (positive - positive = negative)
	// Set R1 = 3, R2 = 10
		$display("");
		$display("TEST 12: sub R1, R2 | Set R1 = 3, R2 = 10");

		// Reset processor
		KEY[0] = 1'b0;
		#12;
		KEY[0] = 1'b1;

		// movi R1, 3
		SW = 9'b111001000;
		@(posedge clk);
		SW = 9'b000000011;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		// movi R2, 10
		SW = 9'b111010000;
		@(posedge clk);
		SW = 9'b000001010;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		// check before sub
		$display("BEFORE SUB: R1 = %d, R2 = %d", R1, R2);

		// T1: instruction
		// opcode=011, Rx=001, Ry=010
		SW = 9'b011001010;

		// wait for all 4 ticks process
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		#1;

		// Check result
		if (R1 == ~(16'd7) + 1'b1) begin
			$display("PASS: R1 = -%d", (~(R1)+1'b1));
			pass_count = pass_count + 1;
			test_result[12] = 1'b1;
		end
		else begin
			$display("FAIL: R1 = %d, expected -7", (~(R1)+1'b1));
			fail_count = fail_count + 1;
			test_result[12] = 1'b0;
		end
		
		
	// Testing the subtract instruction (sub)
	// Test 13: sub R1, R2 (negative - positive = negative)
	// Set R1 = -10, R2 = 3
		$display("");
		$display("TEST 13: sub R1, R2 | Set R1 = -10, R2 = 3");

		// Reset processor
		KEY[0] = 1'b0;
		#12;
		KEY[0] = 1'b1;

		// movi R1, -10
		SW = 9'b111001000;
		@(posedge clk);
		SW = 9'b111110110;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		// movi R2, 3
		SW = 9'b111010000;
		@(posedge clk);
		SW = 9'b000000011;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		// check before sub
		$display("BEFORE SUB: R1 = -%d, R2 = %d", (~(R1)+1'b1), R2);

		// T1: instruction
		// opcode=011, Rx=001, Ry=010
		SW = 9'b011001010;

		// wait for all 4 ticks process
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		#1;

		// Check result
		if (R1 == ~(16'd13) + 1'b1) begin
			$display("PASS: R1 = -%d", (~(R1)+1'b1));
			pass_count = pass_count + 1;
			test_result[13] = 1'b1;
		end
		else begin
			$display("FAIL: R1 = %d, expected -13", (~(R1)+1'b1));
			fail_count = fail_count + 1;
			test_result[13] = 1'b0;
		end
		
		
	// Testing the subtract instruction (sub)
	// Test 14: sub R1, R2 (positive - negative = positive)
	// Set R1 = 10, R2 = -3
		$display("");
		$display("TEST 14: sub R1, R2 | Set R1 = 10, R2 = -3");

		// Reset processor
		KEY[0] = 1'b0;
		#12;
		KEY[0] = 1'b1;

		// movi R1, 10
		SW = 9'b111001000;
		@(posedge clk);
		SW = 9'b000001010;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		// movi R2, -3
		SW = 9'b111010000;
		@(posedge clk);
		SW = 9'b111111101;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		// check before sub
		$display("BEFORE SUB: R1 = %d, R2 = -%d", R1, (~(R2)+1'b1));

		// T1: instruction
		// opcode=011, Rx=001, Ry=010
		SW = 9'b011001010;

		// wait for all 4 ticks process
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		#1;

		// Check result
		if (R1 == 16'd13) begin
			$display("PASS: R1 = %d", R1);
			pass_count = pass_count + 1;
			test_result[14] = 1'b1;
		end
		else begin
			$display("FAIL: R1 = %d, expected 13", R1);
			fail_count = fail_count + 1;
			test_result[14] = 1'b0;
		end
		
		
	// Testing the subtract instruction (sub)
	// Test 15: sub R1, R2 (negative - negative = positive)
	// Set R1 = -3, R2 = -10
		$display("");
		$display("TEST 15: sub R1, R2 | Set R1 = -3, R2 = -10");

		// Reset processor
		KEY[0] = 1'b0;
		#12;
		KEY[0] = 1'b1;

		// movi R1, -3
		SW = 9'b111001000;
		@(posedge clk);
		SW = 9'b111111101;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		// movi R2, -10
		SW = 9'b111010000;
		@(posedge clk);
		SW = 9'b111110110;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		// check before sub
		$display("BEFORE SUB: R1 = -%d, R2 = -%d",
		         (~(R1)+1'b1), (~(R2)+1'b1));

		// T1: instruction
		// opcode=011, Rx=001, Ry=010
		SW = 9'b011001010;

		// wait for all 4 ticks process
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		#1;

		// Check result
		if (R1 == 16'd7) begin
			$display("PASS: R1 = %d", R1);
			pass_count = pass_count + 1;
			test_result[15] = 1'b1;
		end
		else begin
			$display("FAIL: R1 = %d, expected 7", R1);
			fail_count = fail_count + 1;
			test_result[15] = 1'b0;
		end
		
		
	// Testing the subtract instruction (sub)
	// Test 16: sub R1, R2 (negative - negative = negative)
	// Set R1 = -10, R2 = -3
		$display("");
		$display("TEST 16: sub R1, R2 | Set R1 = -10, R2 = -3");

		// Reset processor
		KEY[0] = 1'b0;
		#12;
		KEY[0] = 1'b1;

		// movi R1, -10
		SW = 9'b111001000;
		@(posedge clk);
		SW = 9'b111110110;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		// movi R2, -3
		SW = 9'b111010000;
		@(posedge clk);
		SW = 9'b111111101;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		// check before sub
		$display("BEFORE SUB: R1 = -%d, R2 = -%d",
		         (~(R1)+1'b1), (~(R2)+1'b1));

		// T1: instruction
		// opcode=011, Rx=001, Ry=010
		SW = 9'b011001010;

		// wait for all 4 ticks process
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		#1;

		// Check result
		if (R1 == ~(16'd7) + 1'b1) begin
			$display("PASS: R1 = -%d", (~(R1)+1'b1));
			pass_count = pass_count + 1;
			test_result[16] = 1'b1;
		end
		else begin
			$display("FAIL: R1 = %d, expected -7", (~(R1)+1'b1));
			fail_count = fail_count + 1;
			test_result[16] = 1'b0;
		end
		
	
	// Testing to overwrite the register using movi instruction
	// Set R4 = 20 then R4 = 7
		$display("");
		$display("TEST 17: overwrite R4 | Set R4 = 20 then R4 = 7");

		// Reset processor
		KEY[0] = 1'b0;
		#12;
		KEY[0] = 1'b1;

		// movi R4, 20
		SW = 9'b111100000;
		@(posedge clk);
		SW = 9'b000010100;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		$display("After first movi: R4 = %d", R4);

		// movi R4, 7
		SW = 9'b111100000;
		@(posedge clk);
		SW = 9'b000000111;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		$display("After second movi: R4 = %d", R4);

		// Check result
		if (R4 == 16'd7) begin
			$display("PASS: R4 = %d", R4);
			pass_count = pass_count + 1;
			test_result[17] = 1'b1;
		end
		else begin
			$display("FAIL: R4 = %d, expected 7", R4);
			fail_count = fail_count + 1;
			test_result[17] = 1'b0;
		end


	// Testing a multi-instruction sequence
	// Test 18:
	// movi R6, 227
	// movi R7, 138
	// add R6, R7
	// addi R7, -128
	// sub R6, R7
		$display("");
		$display("TEST 18: Multi-instruction sequence");
		$display("movi R6, 227");
		$display("movi R7, 138");
		$display("add R6, R7");
		$display("addi R7, -128");
		$display("sub R6, R7");

		// Reset processor
		KEY[0] = 1'b0;
		#12;
		KEY[0] = 1'b1;

		// movi R6, 227
		SW = 9'b111110000;
		@(posedge clk);
		SW = 9'b011100011;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		// movi R7, 138
		SW = 9'b111111000;
		@(posedge clk);
		SW = 9'b010001010;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		// Check values before operations
		$display("BEFORE OPERATIONS: R6 = %d, R7 = %d", R6, R7);

		// add R6, R7
		// opcode=001, Rx=110, Ry=111
		SW = 9'b001110111;

		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		#1;

		$display("AFTER ADD: R6 = %d, R7 = %d", R6, R7);

		// addi R7, -128
		// opcode=010, Rx=111, unused
		SW = 9'b010111000;

		@(posedge clk);

		// T2: immediate value -128
		SW = 9'b110000000;

		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		#1;

		$display("AFTER ADDI: R6 = %d, R7 = %d", R6, R7);

		// sub R6, R7
		// opcode=011, Rx=110, Ry=111
		SW = 9'b011110111;

		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		#1;

		// Check final result
		if ((R6 == 16'd355) && (R7 == 16'd10)) begin
			$display("PASS: R6 = %d, R7 = %d", R6, R7);
			pass_count = pass_count + 1;
			test_result[18] = 1'b1;
		end
		else begin
			$display("FAIL: R6 = %d, R7 = %d, expected R6 = 355, R7 = 10", R6, R7);
			fail_count = fail_count + 1;
			test_result[18] = 1'b0;
		end	
		
		
	// Final Test Summary
		$display("");
		$display("*********************************************************************");
		$display("                          TEST SUMMARY");
		$display("*********************************************************************");

		$display("Total tests : %d", pass_count + fail_count);
		$display("Total PASS  : %d", pass_count);
		$display("Total FAIL  : %d", fail_count);

		if (fail_count == 0) begin
			$display("All tests PASS!!! ^^");
		end
		else begin
			$display("");
			$display("Failed tests:");

			for (test_count = 1; test_count <= 18; test_count = test_count + 1) begin
				if (test_result[test_count] == 1'b0)
					$display("  TEST %0d FAIL ;(", test_count);
			end
		end

		$display("_____________________________________________________________________");

		$stop;		
		
	end
endmodule