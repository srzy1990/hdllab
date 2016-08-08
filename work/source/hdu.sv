module hdu (
input logic		cu_stall_si_i,
input logic  	x_stall_d_i,
input logic 	d_stall_pc_i,

output logic	stall_fetch_o,
output logic	stall_decode_o,
output logic	stall_pc_o
);

always_comb begin

	// we do not want to fetch the next instruction if we have a self-instruct
	stall_fetch_o = cu_stall_si_i;
	
	// stall decode and PC for the second memory access within execute stage
	stall_decode_o = x_stall_d_i;
	stall_pc_o = x_stall_d_i & d_stall_pc_i;
end 


endmodule

