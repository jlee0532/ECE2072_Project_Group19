    module proc_top_level(
    input  [9:0] SW,
    input  [1:0] KEY,
    output [9:0] LEDR,
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
);

	wire [15:0] bus;
	wire [15:0] hex_value;   // value held in register H
	wire [3:0]  tick_state;  // the processor's own tick

	simple_proc test(.clk(~KEY[1]), 
	                 .rst(~KEY[0]), 
	                 .enable(SW[9]),
	                 .din(SW[8:0]), 
	                 .bus(bus), 
	                 .R0(), .R1(), .R2(), .R3(), .R4(), .R5(), .R6(), .R7(),
	                 .HEX(hex_value),
	                 .tick(tick_state));

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
	
	BCD bcd0(.data(outHEX0), .X(HEX0));
	BCD bcd1(.data(outHEX1), .X(HEX1));
	BCD bcd2(.data(outHEX2), .X(HEX2));
	BCD bcd3(.data(outHEX3), .X(HEX3));
	BCD bcd5(.data(outHEX5), .X(HEX5));

	// ---- HEX4: minus sign if negative, otherwise the ten-thousands digit ----
	wire [6:0] digit4_seg;
	BCD bcd4(.data(outHEX4), .X(digit4_seg));
	assign HEX4 = is_neg ? 7'b0111111 : digit4_seg;   // only segment g on = "-"
	
endmodule