module BCD (
    input [3:0] data,
    output [6:0] X
);

	assign X[0] = ~((~data[2] & ~data[1] & ~data[0]) | 
						(~data[3] & data[2] & data[0]) |
						(data[3] & ~data[2] & ~data[1]) |
						(~data[3] & data[1])); 
	
	assign X[1] = ~((~data[3] & ~data[2]) |
						(~data[2] & ~data[1]) |
						(~data[3] & ~data[1] & ~data[0]) |
						(~data[3] & data[1] & data[0]));
	
	assign X[2] = ~((~data[3] & data[2]) |
						(~data[2] & ~data[1]) |
						(~data[3] & data[0]));
						
	assign X[3] = ~((~data[3] & ~data[2] & ~data[0]) |
						(~data[3] & ~data[2] & data[1]) |
						(~data[3] & data[1] & ~data[0]) |
						(data[3] & ~data[2] & ~data[1]) |
						(~data[3] & data[2] & ~data[1] & data[0]));
						
	assign X[4] = ~((~data[2] & ~data[1] & ~data[0]) |
						(~data[3] & data[1] & ~data[0]));
						
	assign X[5] = ~((~data[3] & data[2] & ~data[1]) |
						(~data[3] & data[2] & ~data[0]) |
						(~data[3] & ~data[1] & ~data[0]) |
						(data[3] & ~data[2] & ~data[1]));
						
	assign X[6] = ~((~data[3] & data[2] & ~data[1]) |
						(data[3] & ~data[2] & ~data[1]) |
						(~data[3] & ~data[2] & data[1]) |
						(~data[3] & data[1] & ~data[0]));
endmodule
