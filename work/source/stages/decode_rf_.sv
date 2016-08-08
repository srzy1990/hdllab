
module decode_rf (
	input logic 		clk_i,
	input logic			rst_i,
	input logic			stall_i,
	input logic [15:0]	instr_i,
	input logic [31:0]  next_programm_counter_i,
	input logic [31:0]  write_back_i,
	input logic [3:0] 	alu_status_i,
	input logic [31:0]  wb_sp_i,
	input logic			instr_en_i,

	output logic [31:0]  reg_a_o,
	output logic [31:0]  reg_b_o,
	output logic [31:0]  next_programm_counter_o,
	output logic [31:0]  immidiate_value_o,
	output logic [1:0] 	 ALU_op_Out_o,
	output logic 		 shift_immidiate_o,
	output logic 		 PC_to_ALU_o,
	output logic    	 cu_mem_load_en_o,
	output logic 		 cu_mem_write_en_o,
	output logic		 cu_set_ALU_cond_o,
	output logic		 cu_branch_o,
	output logic 	 	 exec_sp_dec_o,
	output logic		 mem2Reg_o,
	
	output logic		 x_imm_to_alu_o,
	output logic 		 cu_stall_o,
	output logic 		 end_program_o,
	output logic		 cu_stall_self_instruct_o,

	input logic [3:0] 	rf_wr_select_i,
	input logic 	  	rf_wr_en_i,
	input logic 	  	rf_sp_wr_en_i,
		
	output logic [3:0] 	rf_wr_select_o,
	output logic 	   	rf_wr_en_o,
	output logic 	   	rf_sp_wr_en_o,
	output logic		stall_pc_o,
	output logic		sign_extend_en_o		
);
	//register_file logic
	logic [3:0] 	rf_rd0_sel;
	logic [3:0] 	rf_rd1_sel;
	logic [3:0] 	rf_wr_sel;
	logic 			cu_rf_wr_en;
	logic			sp_wr_en;

	logic [7:0] 	immOut;
	logic 			PCtoALU;
	logic 			shift_imm;
	logic [1:0]		ALUopOut;
	logic 			use_immidiate;
	logic [31:0]	reg_a;
	logic [31:0]	reg_b;

	register_file rf(
		.clk (clk_i),
		.rst (rst_i),	
		.stall_i (stall_i),			// stall values for the second memory access of execute stage
		.rd0_select (rf_rd0_sel),
		.rd1_select (rf_rd1_sel),
		.write_en (rf_wr_en_i),
		.wr_select (rf_wr_select_i),
		.data_in (write_back_i),
		.sp_in (wb_sp_i),
		.data_out0 (reg_a),
		.data_out1 (reg_b),
		.sp_write_en (rf_sp_wr_en_i)
	);

	logic 			cu_mem_load_en;
	logic 			cu_mem_write_en;
	logic 			cu_set_ALU_cond;
	logic 			cu_branch;
	logic 			self_instruct_en;
	logic [15:0]	self_instruct;

	logic [15:0]	instruct_cu;
	logic [15:0]	instruct_cu_buffer;
	logic			instruct_cu_en_buffer;
	logic 			mem2Reg;
	logic			cu_end_program;
	logic			cu_sign_extend;

	controlunit cu (
		.alu_status_i(alu_status_i),
		.in (instruct_cu),
		.cu_input_en_i (1'b1),
		.immediate (use_immidiate),
		.PCtoALU (PCtoALU),
		.shiftImm(shift_imm),
		.immOut (immOut),
		.opOut (ALUopOut),
		.src1Reg (rf_rd0_sel),
		.src2Reg (rf_rd1_sel),
		.destReg (rf_wr_sel),
		.mem_load (cu_mem_load_en),
		.mem_write (cu_mem_write_en),
		.setConditionCodes(cu_set_ALU_cond),
		.branch (cu_branch),
		.self_instruct_o (self_instruct),
		.self_instruct_en_o(self_instruct_en),
		.sp_dec_o(exec_sp_dec_o),
		.sp_write_en_o (sp_wr_en),
		.mem2Reg_o (mem2Reg),
		.rf_write_en_o (cu_rf_wr_en),
		.end_program_o (cu_end_program),	
		.sign_extend_en_o (cu_sign_extend)	
	);
	
	always_comb begin
		// we have a branch instruction, so we are going to Flush the pipeline stages
		if (cu_branch_o)
			instruct_cu = 16'hffff;
		// use the stored instruction from the either the last stall or the self-instruction first
		else if (instruct_cu_en_buffer) 
			instruct_cu = instruct_cu_buffer;
			
		else if (instr_en_i)
			instruct_cu = instr_i;

		else instruct_cu = 16'hffff;
	end
	
	
	assign cu_stall_o = cu_mem_load_en || cu_mem_write_en;

	// we do not want to use the next PC if this is a load instruction (cannot fetch)
	assign stall_pc_o = cu_mem_load_en & ~stall_i; // || cu_mem_write_en;
	assign cu_stall_self_instruct_o = self_instruct_en;
	assign reg_a_o = reg_a; 
	assign reg_b_o = reg_b;
	assign next_programm_counter_o = next_programm_counter_i;
	
	always_ff @ (posedge clk_i) begin
		if(rst_i) 
			instruct_cu_en_buffer <= 1'b0;
		
		else begin		
			if(~stall_i) begin	
				immidiate_value_o <= {24'd0, immOut};
				
				
				if (self_instruct_en) begin
					instruct_cu_en_buffer <= 1'b1;
					instruct_cu_buffer <= self_instruct;
				end
				else instruct_cu_en_buffer <= 1'b0;
				
				cu_mem_load_en_o <= cu_mem_load_en;
				cu_mem_write_en_o <= cu_mem_write_en;
				cu_set_ALU_cond_o <= cu_set_ALU_cond;
				cu_branch_o <= cu_branch;
		
				x_imm_to_alu_o <= use_immidiate;
				mem2Reg_o <= mem2Reg;
				
				rf_wr_select_o <= rf_wr_sel;
				rf_wr_en_o <= cu_rf_wr_en;
				rf_sp_wr_en_o <= sp_wr_en;
				ALU_op_Out_o <= ALUopOut;
				shift_immidiate_o <= shift_imm;
				PC_to_ALU_o <= PCtoALU;
			
				end_program_o <= cu_end_program;
				sign_extend_en_o <= cu_sign_extend;
			end
			else if (~instruct_cu_en_buffer & instr_en_i) begin
				// if we fetched an instruction and are going to stall, we have to save it for the next clock cycle
				instruct_cu_en_buffer <= 1'b1;
				instruct_cu_buffer <= instr_i;
			end
		end
	end
	
endmodule
