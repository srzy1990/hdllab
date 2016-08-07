module hdu (
input logic 	clk_i,
input logic 	rst_i,
input logic  	x_stall_pc_i,
input logic  	cu_stall_i,
input logic		cu_stall_si_i,
input logic  	x_stall_d_i,
input logic		x_release_f_i,

output logic	stall_fetch_o,
output logic	stall_decode_o
//output logic 	cu_stall_o
);

always_comb begin

	// we do not want to fetch the next instruction if we have a self-instruct
	stall_fetch_o = cu_stall_si_i;
	
	// stall decode for the second memory access within execute stage
	stall_decode_o = x_stall_d_i;
end 


endmodule

