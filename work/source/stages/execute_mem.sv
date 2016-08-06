
module execute_mem (
	input logic 		clk_i,
	input logic			rst_i,

	input logic [31:0]	pc_i,
	input logic [31:0]	next_pc_i,
	input logic [31:0]	reg_a_i,
	input logic [31:0]	reg_b_i,
	input logic [31:0]	imm_i,

	input logic 		pc_to_alu,
	input logic 		imm_to_alu,
	input logic 		s_imm_to_alu,
	input logic 		sp_inc_i,
	input logic [1:0] 	opcode_i,			
	input logic 		signed_i,
	input logic 		mem_re_i,
	input logic 		mem_we_i,
	input logic 		set_alu_status_i,
	input logic 		mem_to_reg_i,
	input logic [3:0]	rf_wr_select_i,
	input logic 		rf_wr_en_i,
	input logic 		rf_sp_wr_en_i,

	output logic [31:0] branch_o,
	output logic [31:0] data_calc_o,
	output logic [31:0] data_mem_addr_o,
	output logic [31:0] sp_o,
	output logic [15:0] data_mem_o,
	output logic [3:0] alu_status_out,
	output logic stall_pc_o,				// going to do two writes
	output logic stall_d_o,
	output logic mem_re_o,
	output logic mem_we_o,
	output logic mem_to_reg_o,
	output logic release_fetch_o,
	output logic [3:0] rf_wr_select_o,
	output logic rf_wr_en_o,
	output logic rf_sp_wr_en_o
);

		// INTERNAL SIGNALS
	logic [31:0] alu_in1;
	logic [31:0] alu_in2;
	logic [31:0] alu_out;

	logic [31:0] s_imm; // shifted immediate

		
	//fsm
	parameter ST_OP_CODE_HANDLING = 1;
	parameter ST_RW_HIGH = 2;
	parameter ST_STALL_F = 3;
	parameter ST_STALL_D = 4;
	logic [2:0] state;
	logic [2:0] next_state;

	always_ff @(posedge clk_i) begin
		if(rst_i) 
			state <= ST_OP_CODE_HANDLING;
		else
		begin
			state <= next_state;

			data_calc_o <= alu_out;
			mem_to_reg_o <= mem_to_reg_i;
			rf_wr_select_o <= rf_wr_select_i;
			rf_wr_en_o <= rf_wr_en_i;
		end
	end
	
	always_comb begin
		stall_pc_o = 0;
		stall_d_o = 0;
		mem_we_o = mem_we_i;
		//sp_o = 0;
		release_fetch_o = 0;
		case (state)
			ST_OP_CODE_HANDLING: begin
				data_mem_o = reg_b_i[15:0];
				data_mem_addr_o = alu_out;
				next_state = ST_OP_CODE_HANDLING;

				if(mem_re_i|mem_we_i)begin
					stall_pc_o = 1;
					next_state = ST_RW_HIGH;
				end

				if(mem_we_i)
					data_mem_addr_o = alu_out + 32'd2;
			end
			ST_RW_HIGH: begin
				stall_pc_o = 1;

				next_state = ST_OP_CODE_HANDLING;
	
				data_mem_o = reg_b_i[31:16]; 
				if(mem_re_i)
					data_mem_addr_o = (alu_out + 32'd2);
				else if (mem_we_i)
					data_mem_addr_o = alu_out;
				if(sp_inc_i)
						sp_o <= alu_out + 32'd4;
					else sp_o <= alu_out;	

				stall_d_o = 1;
				
			end
			ST_STALL_F : begin
				stall_pc_o = 0;
				stall_d_o = 1;
				next_state = ST_STALL_D;	
				mem_we_o = 0;	

				// let fetch read the next instruction with the next clk
				if(mem_we_i)	
					release_fetch_o = 1;
			end
			ST_STALL_D : begin
				next_state = ST_OP_CODE_HANDLING;	
				mem_we_o = 0;	

				
				if (mem_re_i)
					stall_d_o = 1;
			end
		endcase
		
	end 
	

	// ALU INSTANTIATION
	alu alu32 (
		.data1_i (alu_in1),
		.data2_i (alu_in2),
		.opcode_i (opcode_i),
		.signed_i (signed_i),
		.data_o (alu_out),
		.status_o (alu_status_out),
		.set_status_i (set_alu_status_i)
	);
	assign rf_sp_wr_en_o = rf_sp_wr_en_i;
	assign s_imm = imm_i << 2;
	assign branch_o = s_imm + next_pc_i;

	assign mem_re_o = mem_re_i;	
	assign alu_in1 = pc_to_alu? {next_pc_i[31:2], 2'b00} : reg_a_i;
	assign alu_in2 = s_imm_to_alu? s_imm : (imm_to_alu? imm_i : reg_b_i);
endmodule