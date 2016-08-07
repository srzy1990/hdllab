

module write_back_fetch (
	input logic clk_i,
	input logic rst_i,
	input logic [15:0] 	data_read_i, 
	input logic [31:0] 	data_calc_i,
	
	input logic			instr_mem_en_i,
	input logic 	 	mem_to_reg_i,
	input logic			stall_fetch_i,
	
	input logic [31:0] 	branch_pc_i,
	input logic 		branch_i,
	
	output logic [31:0] instr_mem_addr_o,
	output logic [31:0] next_pc_o,
	output logic [31:0] pc_out,
	output logic [31:0] write_back_o,
	output logic 		instr_mem_re_o
);
	
	logic [31:0] programm_counter;
	
	logic [15:0] low_reg;
	logic [31:0] read_data;
	logic [31:0] temp_pc;

	parameter ST_IDLE = 0;	
	parameter ST_R_HIGH = 1;
	
	logic [2:0] state;
	logic [2:0] next_state;

	always_ff @(posedge clk_i) begin
		if(rst_i) begin
			state = ST_IDLE;
			low_reg <= 0;
		end	else begin
			state <= next_state;

			if(next_state == ST_R_HIGH) begin
					low_reg <= data_read_i;	
			end
		end
	end	

	always_comb begin
		read_data =0;
		instr_mem_re_o = ~stall_fetch_i;

		case(state)
			ST_IDLE : begin
				read_data = {16'h0, data_read_i}; 
				next_state <= ST_IDLE;

				if(mem_to_reg_i) begin						
					next_state <= ST_R_HIGH;//to do bedingung				
				end	
			end
			
			ST_R_HIGH : begin
				next_state <= ST_IDLE;
				read_data =  {data_read_i, low_reg};
			end
		endcase
	end
	
	assign write_back_o = mem_to_reg_i ? read_data : data_calc_i;
	assign next_pc_o = temp_pc;
	
	assign temp_pc = branch_i ? branch_pc_i : programm_counter +32'd2;
	assign instr_mem_addr_o = programm_counter;
	assign pc_out = programm_counter;
	
	always_ff@(posedge clk_i) begin
		
		if(rst_i) begin
			programm_counter <=0;
			
		end
		// update the PC if successfully red the next instruction
		else begin 
			if(instr_mem_en_i)begin		
				programm_counter <= temp_pc;
			end
		end
	end
endmodule
