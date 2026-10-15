/*
Monash University ECE2072: Assignment - Bonus task top level.

Same as the Task 4 top level (ROM + 10 Hz clock + processor + displays), plus a
UART link on the Arduino header:

    IO1  (UART_TXD, PIN_AB6) = TX out  -> wire to the OTHER board's IO0
    IO0  (UART_RXD, PIN_AB5) = RX in   <- wire from the OTHER board's IO1
    GND  (Arduino header GND)          -> wire to the OTHER board's GND

  Loopback test on one board: one wire from IO1 to IO0.

Load the SAME design (and the same memory.mif) onto both boards.
*/
module comm_top_level(
    input  CLOCK_50,
    input  [9:0] SW,
    input  [1:0] KEY,
    output [9:0] LEDR,
    output [7:0] HEX0, HEX1, HEX2, HEX3, HEX4,     // [7] = decimal point
    output [6:0] HEX5,
    output UART_TXD,                               // Arduino IO1: TX out
    input  UART_RXD                                // Arduino IO0: RX in
);

	wire [15:0] bus;
	wire [15:0] hex_value;
	wire [3:0]  tick_state;
	wire [15:0] pc;
	wire [8:0]  instr;
	wire        clk_10hz;
	wire        reset = ~KEY[0];

	// ---------- clock divider ----------
	clock_divider div(.clk_in(CLOCK_50), .clk_out(clk_10hz));

	// ---------- instruction memory ----------
	inst_rom rom(.address(pc[14:0]), .clock(CLOCK_50), .q(instr));

	// ---------- communication wires ----------
	wire [15:0] tx_data;
	wire        tx_toggle;
	wire        tx_start;
	wire        tx_line;
	wire [15:0] rx_data;
	wire        rx_line;
	wire        rx_valid;

	// ---------- processor ----------
	simple_proc proc(.clk(clk_10hz),
	                 .rst(reset),
	                 .enable(SW[9]),
	                 .din(instr),
	                 .bus(bus),
	                 .R0(), .R1(), .R2(), .R3(), .R4(), .R5(), .R6(), .R7(),
	                 .HEX(hex_value),
	                 .tick(tick_state),
	                 .PC(pc),
	                 .tx_data(tx_data),
	                 .tx_toggle(tx_toggle),
	                 .rx_data(rx_data));

	// ---------- UART link (runs on CLOCK_50) ----------
	tx_trigger trig(.clk(CLOCK_50), .toggle_in(tx_toggle), .start(tx_start));

	uart_tx transmitter(.clk(CLOCK_50), .rst(reset), .start(tx_start),
	                    .data(tx_data), .tx(tx_line), .busy());

	uart_rx receiver(.clk(CLOCK_50), .rst(reset), .rx(rx_line),
	                 .data(rx_data), .valid(rx_valid));

	assign UART_TXD = tx_line;    // drive the TX pin (IO1)
	assign rx_line  = UART_RXD;   // read the RX pin (IO0)

	// ---------- LEDs: bottom 10 bits of the bus ----------
	assign LEDR[9]   = tx_line;    // DEBUG: should be ON when idle (line high)
	assign LEDR[8]   = rx_line;    // DEBUG: should be ON when idle, if the wire is connected
	assign LEDR[7:0] = rx_data[7:0];  // DEBUG: last received value (123 = 01111011)

	// ---------- signed display (footnote 4: decimal points = negative) ----------
	wire is_neg = hex_value[15];
	wire [15:0] magnitude = is_neg ? (~hex_value + 16'd1) : hex_value;

	wire [3:0] outHEX0 = magnitude % 10;
	wire [3:0] outHEX1 = (magnitude / 10) % 10;
	wire [3:0] outHEX2 = (magnitude / 100) % 10;
	wire [3:0] outHEX3 = (magnitude / 1000) % 10;
	wire [3:0] outHEX4 = magnitude / 10000;

	reg [3:0] outHEX5;
	always @(*) begin
		case (tick_state)
			4'b0001: outHEX5 = 4'd1;
			4'b0010: outHEX5 = 4'd2;
			4'b0100: outHEX5 = 4'd3;
			4'b1000: outHEX5 = 4'd4;
			default: outHEX5 = 4'd15;   // blank
		endcase
	end

	BCD bcd0(.data(outHEX0), .X(HEX0[6:0]));
	BCD bcd1(.data(outHEX1), .X(HEX1[6:0]));
	BCD bcd2(.data(outHEX2), .X(HEX2[6:0]));
	BCD bcd3(.data(outHEX3), .X(HEX3[6:0]));
	BCD bcd4(.data(outHEX4), .X(HEX4[6:0]));
	BCD bcd5(.data(outHEX5), .X(HEX5));

	// decimal points: all on (active-low 0) when the number is negative
	assign HEX0[7] = ~is_neg;
	assign HEX1[7] = ~is_neg;
	assign HEX2[7] = ~is_neg;
	assign HEX3[7] = ~is_neg;
	assign HEX4[7] = ~is_neg;

endmodule