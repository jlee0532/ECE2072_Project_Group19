module memory_top_level(
    input  CLOCK_50,                      // NEW: the board's 50 MHz clock
    input  [9:0] SW,
    input  [1:0] KEY,
    output [9:0] LEDR,
    output [7:0] HEX0, HEX1, HEX2, HEX3, HEX4,
	 output [6:0] HEX5
);

	wire [15:0] bus;
	wire [15:0] hex_value;
	wire [3:0]  tick_state;
	wire [15:0] pc;          // NEW: processor → ROM address
	wire [8:0]  instr;       // NEW: ROM → processor din
	wire        clk_10hz;    // NEW: clock divider → processor

	// ---------- NEW: clock divider ----------
	clock_divider div(.clk_in(CLOCK_50), .clk_out(clk_10hz));        // TODO row 1 + 2

	// ---------- NEW: instruction memory ----------
	inst_rom rom(.address(pc[14:0]), .clock(CLOCK_50), .q(instr));       // TODO rows 1, 3, 4

	// ---------- processor ----------
	simple_proc proc(.clk(clk_10hz),                                 // TODO row 2
	                 .rst(~KEY[0]),
	                 .enable(SW[9]),
	                 .din(instr),                                    // TODO row 4
	                 .bus(bus),
	                 .R0(), .R1(), .R2(), .R3(), .R4(), .R5(), .R6(), .R7(),
	                 .HEX(hex_value),
	                 .tick(tick_state),
	                 .PC(pc));                                     // TODO row 3

	// ---------- everything below is copied from your Task 3 top level ----------

	// (copy your is_neg / magnitude / outHEX0..4 / outHEX5 case / BCD instances here)
	assign LEDR[9:0] = bus[9:0];

	// ---- signed: take the sign bit, then work with the magnitude ----
	wire is_neg = hex_value[15];
	wire [15:0] magnitude = is_neg ? (~hex_value + 16'd1) : hex_value;

	// ---- magnitude -> 5 decimal digits ----
	wire [3:0] outHEX0 = magnitude % 10;
	wire [3:0] outHEX1 = (magnitude / 10) % 10;
	wire [3:0] outHEX2 = (magnitude / 100) % 10;
	wire [3:0] outHEX3 = (magnitude / 1000) % 10;
	wire [3:0] outHEX4 = magnitude / 10000;

	// ---- one-hot tick -> 1..4 ----
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
	
	// ---- 7 segments: the magnitude's digits ----
	BCD bcd0(.data(outHEX0), .X(HEX0[6:0]));
	BCD bcd1(.data(outHEX1), .X(HEX1[6:0]));
	BCD bcd2(.data(outHEX2), .X(HEX2[6:0]));
	BCD bcd3(.data(outHEX3), .X(HEX3[6:0]));
	BCD bcd4(.data(outHEX4), .X(HEX4[6:0]));   // HEX4 is a normal digit again
	BCD bcd5(.data(outHEX5), .X(HEX5));

	// ---- decimal points: all ON when negative (active-low, so 0 = on) ----
	assign HEX0[7] = ~is_neg;
	assign HEX1[7] = ~is_neg;
	assign HEX2[7] = ~is_neg;
	assign HEX3[7] = ~is_neg;
	assign HEX4[7] = ~is_neg;
	
endmodule	