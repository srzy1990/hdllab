module mem_arbiter (
	input logic			clk_i,
	input logic			rst_i,

	input logic 		instr_mem_en_i,
	input logic [31:0]	instr_mem_addr_i,

	input logic			data_mem_re_i,
	input logic			data_mem_we_i,			
	input logic [31:0]	data_mem_addr_i,
	input logic [15:0]	data_mem_write_i,
	
	// mem value red from mem
	input logic [15:0]	data_i,
	
	// values back to stages
	output logic		instr_mem_en_o,
	output logic [15:0] mem_value_o,
	
	// values going to mem
	output logic [11:0]	mem_addr_o,
	output logic		mem_re_o,
	output logic		mem_we_o,
	output logic [15:0]	data_mem_write_o
);

logic data_mem_en;
assign data_mem_en = data_mem_re_i | data_mem_we_i;

always_comb begin

	mem_we_o <= 0;
	data_mem_write_o <= 16'b0;
	mem_value_o <= {data_i[7:0], data_i[15:8]};
	
	if (rst_i) begin
		mem_addr_o <= 32'b0;
		mem_re_o <= 0;
	end
	else begin
		// data mem has priority
		if (data_mem_en) begin
			mem_addr_o <= data_mem_addr_i >> 1;
			mem_we_o <= data_mem_we_i;
			mem_re_o <= data_mem_re_i;
			
			if (data_mem_we_i)
				data_mem_write_o <= {data_mem_write_i[7:0],data_mem_write_i[15:8]};
		end
		else if (instr_mem_en_i) begin
			mem_addr_o <= instr_mem_addr_i >> 1;
			mem_re_o <= 1;
		end
	end
end

always_ff @(posedge clk_i) begin
	if (rst_i) 
		instr_mem_en_o <= 0;
	
	else instr_mem_en_o <= instr_mem_en_i & (~data_mem_en);
end

endmodule
