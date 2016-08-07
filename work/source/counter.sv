module counter (input logic clk_i, input logic rst_i);
	logic [5:0] count;
	always_ff@(posedge clk_i) begin
		if (rst_i)
			count = 1;
			
		else count = count+1;
	end
endmodule