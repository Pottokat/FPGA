module Divider
# (parameter DIVISOR = 28'd50000000)
(
	input sig_in,
	output sig_out
);
	reg[27:0] counter=28'd0;
	
	always @ (posedge sig_in) begin
		counter <= counter + 28'd1;
		if(counter>=(DIVISOR-1))
			counter <= 28'd0;
	end

	assign sig_out = (counter<DIVISOR/2) ? 1'b0 : 1'b1;
endmodule