/*
Monash University ECE2072: Assignment - Bonus task
UART-style serial link between two x72 processors.

Frame format (one frame per 16-bit register value), sent LSB first:

    idle (1) | start (0) | d0 d1 ... d15 | stop (1) | idle (1) ...

  * 18 bits per frame: 1 start + 16 data + 1 stop.
    (Standard UART sends 8 data bits; we send all 16 bits in one frame so a whole
     register arrives in one go and the receiver never has half a value.)
  * Both modules run on CLOCK_50. CLKS_PER_BIT = 50,000,000 / baud rate.
    Default 5208 -> 9600 baud -> one frame takes about 1.9 ms, far shorter than one
    processor tick (100 ms), so a frame always finishes before the next tx.
*/


// ============================================================
// Transmitter
// ============================================================
module uart_tx(clk, rst, start, data, tx, busy);
	parameter CLKS_PER_BIT = 5208;          // 9600 baud on a 50 MHz clock

	input clk;                              // CLOCK_50
	input rst;
	input start;                            // 1-cycle pulse: send "data"
	input [15:0] data;
	output reg tx = 1'b1;                   // serial line, idle high
	output busy;

	reg [17:0] frame = 18'h3FFFF;           // {stop, data, start}, shifted out from bit 0
	reg [4:0]  bits_left = 0;               // bits still to send (0 = idle)
	reg [15:0] count = 0;                   // clock cycles spent on the current bit

	assign busy = (bits_left != 0);

	always @(posedge clk) begin
		if (rst) begin
			tx <= 1'b1;
			bits_left <= 0;
			count <= 0;
		end
		else if (bits_left == 0) begin      // idle: line high, wait for start
			tx <= 1'b1;
			if (start) begin
				frame <= {1'b1, data, 1'b0};
				bits_left <= 5'd18;
				count <= 0;
			end
		end
		else begin                          // sending
			tx <= frame[0];
			if (count == CLKS_PER_BIT - 1) begin
				count <= 0;
				frame <= {1'b1, frame[17:1]};   // next bit
				bits_left <= bits_left - 1;
			end
			else begin
				count <= count + 1;
			end
		end
	end
endmodule


// ============================================================
// Receiver
// ============================================================
module uart_rx(clk, rst, rx, data, valid);
	parameter CLKS_PER_BIT = 5208;

	input clk;                              // CLOCK_50
	input rst;
	input rx;                               // serial line from the other board
	output reg [15:0] data = 0;             // last complete value received
	output reg valid = 0;                   // 1-cycle pulse when "data" updates

	// Two flip-flops bring the asynchronous rx line into the CLOCK_50 domain
	// (avoids metastability).
	reg rx_s1 = 1'b1, rx_s2 = 1'b1;
	always @(posedge clk) begin
		rx_s1 <= rx;
		rx_s2 <= rx_s1;
	end

	localparam IDLE = 2'd0, START = 2'd1, DATA = 2'd2, STOP = 2'd3;
	reg [1:0]  state = IDLE;
	reg [15:0] count = 0;
	reg [3:0]  index = 0;
	reg [15:0] shift = 0;

	always @(posedge clk) begin
		valid <= 1'b0;
		if (rst) begin
			state <= IDLE;
			count <= 0;
			data  <= 0;
		end
		else begin
			case (state)
				IDLE: begin                         // wait for the line to drop (start bit)
					count <= 0;
					if (rx_s2 == 1'b0)
						state <= START;
				end

				START: begin                        // go to the MIDDLE of the start bit
					if (count == CLKS_PER_BIT/2 - 1) begin
						count <= 0;
						if (rx_s2 == 1'b0) begin    // still low: a real start bit
							index <= 0;
							state <= DATA;
						end
						else
							state <= IDLE;          // just a glitch: ignore it
					end
					else
						count <= count + 1;
				end

				DATA: begin                         // sample each bit in its middle
					if (count == CLKS_PER_BIT - 1) begin
						count <= 0;
						shift <= {rx_s2, shift[15:1]};   // LSB arrives first
						if (index == 4'd15)
							state <= STOP;
						else
							index <= index + 1;
					end
					else
						count <= count + 1;
				end

				STOP: begin                         // check the stop bit, then deliver
					if (count == CLKS_PER_BIT - 1) begin
						count <= 0;
						state <= IDLE;
						if (rx_s2 == 1'b1) begin    // valid frame
							data  <= shift;
							valid <= 1'b1;
						end                         // bad stop bit: frame is dropped
					end
					else
						count <= count + 1;
				end
			endcase
		end
	end
endmodule


// ============================================================
// Starts a transmission whenever the processor's tx_toggle changes.
// tx_toggle comes from the slow (10 Hz) processor clock, so it is
// synchronised into the CLOCK_50 domain first.
// ============================================================
module tx_trigger(clk, toggle_in, start);
	input clk;                              // CLOCK_50
	input toggle_in;                        // tx_toggle from the processor
	output start;                           // 1-cycle pulse for uart_tx

	reg s1 = 0, s2 = 0, s3 = 0;
	always @(posedge clk) begin
		s1 <= toggle_in;
		s2 <= s1;
		s3 <= s2;
	end

	assign start = s2 ^ s3;                 // changed since last cycle -> send
endmodule
