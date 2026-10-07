/*
Monash University ECE2072: Assignment 
This file contains Verilog code to implement the extended version of CPU.

Please enter your student ID:


*/
 // TODO: Copy and paste your task 2 into here
 
 module simple_proc(enable, clk, rst, din, bus, R0, R1, R2, R3, R4, R5, R6, R7, HEX, tick);

	// Note: The skeleton you are provided with includes output ports to output the values of the internal registers R0 - R7, for the purpose of test benching. 
	// 			When instantiating the processor to program your DE10-lite, you can leave these ports unused.

	// TODO: Declare inputs and outputs:
	input enable;
	input clk;
	input rst;
	input [8:0] din;
	output [15:0] bus;
	output [15:0] R0, R1, R2, R3, R4, R5, R6, R7;
	output [15:0] HEX;             // value held in register H
	output [3:0]  tick;            // current tick, for HEX5

	// TODO: declare wires:
	reg [2:0] opcode;
	reg [2:0] Rx;
	reg [2:0] Ry;

	reg R0_in, R1_in, R2_in, R3_in, R4_in, R5_in, R6_in, R7_in, IR_in;
	wire [15:0] din_16;
	reg [3:0] bus_control;

	reg A_in, G_in, H_in;
	reg [2:0] ALU_op;
	wire [15:0] ALU_out;
	wire [15:0] A_out, G_out;

	wire [3:0] tick_state;

	wire [8:0] control_in;

	assign tick = tick_state;

	// TODO: instantiate registers:
	register_n reg_R0(.data_in(bus), .r_in(R0_in), .clk(clk), .Q(R0), .rst(rst));

	register_n reg_R1(.data_in(bus), .r_in(R1_in), .clk(clk), .Q(R1), .rst(rst));

	register_n reg_R2(.data_in(bus), .r_in(R2_in), .clk(clk), .Q(R2), .rst(rst));

	register_n reg_R3(.data_in(bus), .r_in(R3_in), .clk(clk), .Q(R3), .rst(rst));

	register_n reg_R4(.data_in(bus), .r_in(R4_in), .clk(clk), .Q(R4), .rst(rst));

	register_n reg_R5(.data_in(bus), .r_in(R5_in), .clk(clk), .Q(R5), .rst(rst));

	register_n reg_R6(.data_in(bus), .r_in(R6_in), .clk(clk), .Q(R6), .rst(rst));

	register_n reg_R7(.data_in(bus), .r_in(R7_in), .clk(clk), .Q(R7), .rst(rst));

	register_n #(.N(9)) reg_IR(.data_in(din), .r_in(IR_in), .clk(clk), .Q(control_in), .rst(rst));
	
	register_n reg_H(.data_in(bus), .r_in(H_in), .clk(clk), .Q(HEX), .rst(rst));

	// TODO: instantiate Multiplexer:
	sign_extend sign_ext(.in(din), .ext(din_16));

	multiplexer multi(.SignExtDin(din_16), 
	.R0(R0), .R1(R1), .R2(R2), .R3(R3), .R4(R4), .R5(R5), .R6(R6), .R7(R7), 
	.G(G_out), .sel(bus_control), .Bus(bus));

	// TODO: instantiate ALU:
	register_n reg_A(.data_in(bus), .r_in(A_in), .clk(clk), .Q(A_out), .rst(rst));

	ALU Alu(.input_a(A_out), .input_b(bus), .alu_op(ALU_op), .result(ALU_out));	 

	register_n reg_G(.data_in(ALU_out), .r_in(G_in), .clk(clk), .Q(G_out), .rst(rst));

	// TODO: instantiate tick counter:
	tick_FSM tick_counter(.rst(rst), .clk(clk), .enable(enable), .tick(tick_state));

	// TODO: define control unit:
	always @(*) begin
		// TODO: Turn off all control signals:
		{R0_in, R1_in, R2_in, R3_in, R4_in, R5_in, R6_in, R7_in, IR_in} = 9'b000000000;
		{A_in, G_in, H_in} = 3'b000;
		bus_control = 4'b0000;
		ALU_op = 3'b000;  
				
		opcode = control_in[8:6];
		Rx = control_in[5:3];
		Ry = control_in[2:0];
		
		// TODO: Turn on specific control signals based on current tick:
		case (tick_state)
			/* Tick 1 */
			4'b0001:
			begin
				IR_in = 1;
			end

			/* Tick 2 */
			4'b0010:
			begin
				case (opcode)
					3'b000: begin // disp Rx
						bus_control = 4'b0001 + Rx;
					
						H_in = 1;
					end
					
					3'b001: begin // add Rx, Ry
						bus_control = 4'b0001 + Rx;
					
						A_in = 1;
					end
					
					3'b010: begin // addi Rx, Immi
						bus_control = 4'b0000;
					
						A_in = 1;
					end
				
					3'b011: begin // sub Rx, Ry
						bus_control = 4'b0001 + Rx;
					
						A_in = 1;
					end
					
					3'b100: begin // mul Rx, Ry
						bus_control = 4'b0001 + Rx;
						
						A_in = 1;
					end
					
					3'b101: begin // ssi Rx, Immi
						bus_control = 4'b0000;
						
						A_in = 1;
					end
				
					3'b111: begin // movi Rx, Immi
						bus_control = 4'b0000;
						
						case(Rx)
							3'b000: R0_in = 1;
							3'b001: R1_in = 1;
							3'b010: R2_in = 1;
							3'b011: R3_in = 1;
							3'b100: R4_in = 1;
							3'b101: R5_in = 1;
							3'b110: R6_in = 1;
							3'b111: R7_in = 1;
						endcase
					end
					
					default: begin
					end
					
				endcase
			end

			/* Tick 3 */
			4'b0100:
			begin
				case (opcode)
					3'b000: begin // disp Rx (idle)
					end
					
					3'b001: begin // add Rx, Ry
						bus_control = 4'b0001 + Ry;
						
						ALU_op = 3'b001;
						
						G_in = 1;
					end
					
					3'b010: begin // addi Rx, Immi
						bus_control = 4'b0001 + Rx;
						
						ALU_op = 3'b001;
						
						G_in = 1;
					end
					
					3'b011: begin // sub Rx, Ry
						bus_control = 4'b0001 + Ry;
						
						ALU_op = 3'b010;
						
						G_in = 1;
					end
					
					3'b100: begin // mul Rx, Ry
						bus_control = 4'b0001 + Ry;
						
						ALU_op = 3'b000;
						
						G_in = 1;
					end
					
					3'b101: begin // ssi Rx, Immi
						bus_control = 4'b0001 + Rx;
						
						ALU_op = 3'b011;
						
						G_in = 1;
					end
					
					3'b111: begin // movi Rx, Immi (idle)
					end
					
					default: begin 
					end
				endcase
			end

			/* Tick 4 */
			4'b1000:
			begin
				if ((opcode == 3'b001) || (opcode == 3'b010) || (opcode == 3'b011) || (opcode == 3'b100) || (opcode == 3'b101)) begin
					bus_control = 4'b1001;
					
					case(Rx)
						3'b000: R0_in = 1;
						3'b001: R1_in = 1;
						3'b010: R2_in = 1;
						3'b011: R3_in = 1;
						3'b100: R4_in = 1;
						3'b101: R5_in = 1;
						3'b110: R6_in = 1;
						3'b111: R7_in = 1;
					endcase
				end
			end
			
			default:
			begin
			end
			
		endcase
		
	end

endmodule