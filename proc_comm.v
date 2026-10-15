/*
Monash University ECE2072: Assignment
Bonus task: x72 processor with communication (tx instruction + RX register).

Built on the Task 4 processor (proc_memory.v). Every change for the bonus task
is marked "// BONUS".

Design decisions:
  * tx Rx is encoded as   000 Rx 001   (opcode 000 with Ry = 001).
      - disp Rx is still  000 Rx 000   (the compiler already puts Ry = 000 for disp),
        so no existing instruction changes and no pseudo-instructions are needed.
  * R7 is replaced by the read-only RX register. It can be read like any other
    register (bus select 1000, the zero detector, disp, add, ...), but writes to it
    are ignored.
  * tx copies Rx into a TX register in tick 2 and flips tx_toggle on the same clock
    edge. The UART (running on CLOCK_50) sends a frame whenever tx_toggle changes.
    A toggle (instead of a pulse) is used so that pausing with SW[9] can never
    send the same value twice.

Please enter your student ID:

*/

 module simple_proc(enable, clk, rst, din, bus, R0, R1, R2, R3, R4, R5, R6, R7, HEX, tick, PC,
                    tx_data, tx_toggle, rx_data);                                   // BONUS: new ports

	// TODO: Declare inputs and outputs:
	input enable;
	input clk;
	input rst;
	input [8:0] din;
	output [15:0] bus;
	output [15:0] R0, R1, R2, R3, R4, R5, R6, R7;
	output [15:0] HEX;             // value held in register H
	output [3:0]  tick;            // current tick, for HEX5
	output [15:0] PC;

	output [15:0] tx_data;         // BONUS: value to transmit (TX register)
	output reg    tx_toggle = 0;   // BONUS: flips once per tx instruction
	input  [15:0] rx_data;         // BONUS: last value received by the UART

	// TODO: declare wires:
	reg [2:0] opcode;
	reg [2:0] Rx;
	reg [2:0] Ry;

	reg R0_in, R1_in, R2_in, R3_in, R4_in, R5_in, R6_in, R7_in, IR_in;
	wire [15:0] din_16;
	reg [3:0] bus_control;

	reg A_in, G_in, H_in, PC_in, PC_load;
	reg TX_in;                     // BONUS: load the TX register
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

	// BONUS: R7 is now the read-only RX register. There is no reg_R7 any more, so
	// R7_in has nothing to load and writes to R7 are ignored.
	assign R7 = rx_data;

	register_n #(.N(9)) reg_IR(.data_in(din), .r_in(IR_in), .clk(clk), .Q(control_in), .rst(rst));

	register_n reg_H(.data_in(bus), .r_in(H_in), .clk(clk), .Q(HEX), .rst(rst));

	pc_register reg_PC(.clk(clk), .rst(rst), .pc_in(PC_in), .pc_load(PC_load), .data_in(bus), .Q(PC));

	// BONUS: TX register - holds the value being sent
	register_n reg_TX(.data_in(bus), .r_in(TX_in), .clk(clk), .Q(tx_data), .rst(rst));

	// BONUS: flip tx_toggle on the same edge the TX register loads.
	// (Not reset on purpose: a reset would flip it and send a bogus frame.)
	always @(posedge clk) begin
		if (TX_in == 1)
			tx_toggle <= ~tx_toggle;
	end

	// TODO: instantiate Multiplexer:
	sign_extend sign_ext(.in(din), .ext(din_16));

	multiplexer multi(.SignExtDin(din_16),
	.R0(R0), .R1(R1), .R2(R2), .R3(R3), .R4(R4), .R5(R5), .R6(R6), .R7(R7),
	.G(G_out), .PC(PC), .sel(bus_control), .Bus(bus));

	// TODO: instantiate ALU:
	register_n reg_A(.data_in(bus), .r_in(A_in), .clk(clk), .Q(A_out), .rst(rst));

	ALU Alu(.input_a(A_out), .input_b(bus), .alu_op(ALU_op), .result(ALU_out));

	register_n reg_G(.data_in(ALU_out), .r_in(G_in), .clk(clk), .Q(G_out), .rst(rst));

	// TODO: instantiate tick counter:
	tick_FSM tick_counter(.rst(rst), .clk(clk), .enable(enable), .tick(tick_state));

	// ---------- zero detector for bez ----------
	reg [15:0] Rx_value;               // the value stored in register Rx
	always @(*) begin
		case (control_in[5:3])         // the Rx field of the instruction
			3'b000: Rx_value = R0;
			3'b001: Rx_value = R1;
			3'b010: Rx_value = R2;
			3'b011: Rx_value = R3;
			3'b100: Rx_value = R4;
			3'b101: Rx_value = R5;
			3'b110: Rx_value = R6;
			3'b111: Rx_value = R7;     // BONUS: R7 = RX, so "bez r7" tests the received value
		endcase
	end

	wire Rx_zero = (Rx_value == 16'd0);  // 1 when Rx holds zero

	// TODO: define control unit:
	always @(*) begin
		// Turn off all control signals:
		{R0_in, R1_in, R2_in, R3_in, R4_in, R5_in, R6_in, R7_in, IR_in} = 9'b000000000;
		{A_in, G_in, H_in, PC_in, PC_load, TX_in} = 6'b000000;       // BONUS: TX_in added
		bus_control = 4'b0000;
		ALU_op = 3'b000;

		opcode = control_in[8:6];
		Rx = control_in[5:3];
		Ry = control_in[2:0];

		if (enable == 1) begin
		case (tick_state)
			/* Tick 1 */
			4'b0001:
			begin
				IR_in = 1;
				PC_in = 1;
			end

			/* Tick 2 */
			4'b0010:
			begin
				PC_in = 1;
				case (opcode)
					3'b000: begin
						bus_control = 4'b0001 + Rx;     // Rx onto the bus
						if (Ry == 3'b001)               // BONUS: tx Rx (000 Rx 001)
							TX_in = 1;                  //   TX register <- Rx, frame is sent
						else                            // disp Rx (000 Rx 000)
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

					3'b110: begin // bez Rx, Immi -> A <- imm
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
					3'b000: begin // disp / tx (idle)
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

					3'b110: begin // bez -> G <- (A x 2) + PC
						bus_control = 4'b1010;   // PC onto the bus
						ALU_op = 3'b100;         // branch-target operation
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
				if ((opcode == 3'b110) && (Rx_zero == 1)) begin   // bez taken
					bus_control = 4'b1001;   // G (the target) onto the bus
					PC_load = 1;             // PC <- target
				end
			end

			default:
			begin
			end

		endcase
		end
	end

endmodule
