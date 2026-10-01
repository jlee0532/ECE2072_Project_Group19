module proc_top_level(
    input [8:0] SW,
    input [1:0] KEY,
    output [9:0] LEDR,
    output [6:0] HEX5
);

	wire [15:0] bus;

	simple_proc test(.clk(~KEY[1]), 
							.rst(~KEY[0]), 
							.din(SW[8:0]), 
							.bus(bus), 
							R0, R1, R2, R3, R4, R5, R6, R7);

	assign LEDR[9:0] = bus[9:0];

	wire [3:0] tick_state;

	tick_FSM tick_display(.clk(~KEY[1]),
									.rst(~KEY[0]),
									.enable(1'b1),
									.tick(tick_state));

	BCD bcd5(.data(tick_state), .X(HEX5));
	
endmodule