
`timescale 1 ns / 1 ps

module register_file(
	rst,
	clk,
	stall_i,
	sp_write_en,
	write_en,
	rd0_select,
	rd1_select,
	wr_select,
	sp_in,
	data_in,
	data_out0,
	data_out1,
);

// PORTS
   input logic			rst;
   input logic	        clk;
   input logic			stall_i;
   input logic 			sp_write_en;
   input logic 			write_en;
   input logic [3:0] 		rd0_select;
   input logic [3:0] 		rd1_select;
   input logic [3:0]        wr_select;
   input logic [31:0]		sp_in;
   input logic [31:0]	 	data_in;
   output logic [31:0]	 	data_out0;
   output logic [31:0] 		data_out1;

// INTERNAL SIGNALS
logic [31:0] register[0:7];
logic [31:0] sp;
logic [31:0] lr;

// REGISTERED WRITE
always_ff@(negedge clk) begin
	if (rst == 1'b1) begin
		register[0] <= 32'h0;
		register[1] <= 32'h0;
		register[2] <= 32'h0;
		register[3] <= 32'h0;
		register[4] <= 32'h0;
		register[5] <= 32'h0;
		register[6] <= 32'h0;
		//	register[7] <= 32'h0;
		//	lr <= 32'h0;
		sp <= 32'h1ffe;
		register[7] <= 32'h01020707;
		lr <= 32'heeeeffff;	
	end
	else begin
		if (write_en==1'b1) begin
			if (wr_select < 32'h8) begin
				register[wr_select] <= data_in;
			end
			else if (wr_select == 32'he) begin
				lr <= data_in;
			end
		end
		if (sp_write_en==1'b1) begin
			sp <= sp_in;
		end
	end
end

// REGISTERED READ
always_ff@(posedge clk) begin
	if (rst == 1'b1) begin
		data_out0 <= 32'b0;
		data_out1 <= 32'b0;
	end
	else begin
		if (~stall_i) begin
			if (rd0_select < 32'h8) begin
				data_out0 <= register[rd0_select];
			end
			else if (rd0_select == 32'hd) begin
				data_out0 <= sp;
			end
			else if (rd0_select == 32'he) begin
				data_out0 <= lr;
			end
			if (rd1_select < 32'h8) begin
				data_out1 <= register[rd1_select];
			end
			else if (rd1_select == 32'hd) begin
				data_out1 <= sp;
			end
			else if (rd1_select == 32'he) begin
				data_out1 <= lr;
			end
		end
	end
end

endmodule
