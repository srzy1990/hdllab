

module write_back_fetch (
	input logic clk_i,
	input logic rst_i,
	input logic [15:0] 	data_read_i, 
	input logic [31:0] 	data_calc_i,
	
	input logic			instr_mem_en_i,
	input logic 	 	mem_to_reg_i,
	input logic			stall_fetch_i,
	input logic			stall_pc_i,
	
	input logic [31:0] 	branch_pc_i,
	input logic 		branch_i,
	
	output logic [31:0] instr_mem_addr_o,
	output logic [31:0] next_pc_o,
	output logic [31:0] write_back_o,
	output logic 		instr_mem_re_o
);
	logic [15:0] low_reg;
	logic [31:0] read_data;
	logic [31:0] temp_pc;

	parameter ST_IDLE = 0;	
	parameter ST_R_HIGH = 1;
	
	logic [2:0] state;
	logic [2:0] next_state;
	
	logic [31:0] 	pc;
	logic [31:0]	pc_buffer;
	logic 			buff;
	
	// WRITEBACK STAGE
	always_ff @(posedge clk_i) begin
		if(rst_i) begin
			state = ST_IDLE;
			low_reg <= 0;
		end	else begin
			state <= next_state;

			if(next_state == ST_R_HIGH)
				low_reg <= data_read_i;	
		end
	end	

	always_comb begin
		read_data = 0;

		case(state)
			ST_IDLE : begin
				read_data = {16'h0, data_read_i}; 
				next_state <= ST_IDLE;

				if(mem_to_reg_i)					
					next_state <= ST_R_HIGH;//to do bedingung				
			end
			
			ST_R_HIGH : begin
				next_state <= ST_IDLE;
				read_data =  {data_read_i, low_reg};
			end
		endcase
	end
	
	assign write_back_o = mem_to_reg_i ? read_data : data_calc_i;
	
	// TODO: nicht schön -> aufräumen
	
	// FETCH STAGE
	assign instr_mem_re_o = ~stall_fetch_i;
	assign buff = ~ (branch_i || (instr_mem_en_i & ~stall_pc_i) /*& ~stall_fetch_i*/) ;
	assign temp_pc =  branch_i ? branch_pc_i : next_pc_o;
	assign pc = buff ? pc_buffer : temp_pc;
	assign instr_mem_addr_o = pc;
	
	always_ff @(posedge clk_i) begin
		if (rst_i) begin
			next_pc_o <= 0;
			pc_buffer <= 0;
		end
		else begin
			next_pc_o <= pc + 32'd2;
			pc_buffer <= pc;
		end
	end
endmodule
