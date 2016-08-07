
module cpu #(
	parameter ADDR_WIDTH =8
) (
	input logic 					clk_i,
	input logic						rst_i,
	input logic [15:0] 				mem_value_i,
	output logic [ADDR_WIDTH-1:0]	mem_addr_o,
	output logic [15:0] 			mem_value_o,
	output logic 					mem_enable_o,
	output logic					mem_wr_en_o, 
	output logic 					mem_rd_en_o,
	output logic 					end_program_o								
	);

	
	counter clock (
		.clk_i (clk_i),
		.rst_i (rst_i)
	);
	
	assign mem_enable_o = mem_wr_en_o || mem_rd_en_o;
	
	// Memory Arbiter
	logic [31:0]	wbf2a_instr_mem_addr;
	logic			wbf2a_instr_mem_en;
	logic [31:0]	x2a_data_mem_addr;
	logic			x2a_data_mem_re;
	logic			x2a_data_mem_we;
	logic [15:0]	x2a_data_mem_write;
	logic [15:0]	a2stages_data;
	logic			a2d_instr_en;
	logic			a2d_data_en;
	
	mem_arbiter arbiter (
		.clk_i (clk_i),
		.rst_i (rst_i),
		.instr_mem_en_i (wbf2a_instr_mem_en),
		.instr_mem_addr_i (wbf2a_instr_mem_addr),
		.data_mem_re_i (x2a_data_mem_re), 
		.data_mem_we_i (x2a_data_mem_we),			// 0 is read
		.data_mem_addr_i (x2a_data_mem_addr),
		.data_mem_write_i (x2a_data_mem_write),
		.data_i (mem_value_i),
	
	
		.instr_mem_en_o (a2d_instr_en),
		.data_mem_en_o (a2d_data_en),
		.data_mem_write_o (mem_value_o),
		.mem_value_o (a2stages_data),
		.mem_addr_o (mem_addr_o),
		.mem_re_o (mem_rd_en_o),
		.mem_we_o (mem_wr_en_o)
	);
	
	//Write_back_fetch_logic
	//inputs
	
	logic [31:0] 	wbf_data_calc;
	logic 			wbf_mem_to_reg;
	logic 			wbf_read_high;
	logic 			wbf_read_low;
	logic [31:0] 	wbf_branch_pc;
	logic 			wbf_branch;
	//outputs
	
	logic [31:0]	wbf_next_pc;
	logic [31:0]	wbf_write_back;
	logic [31:0]	wbf_act_pc;
	
	logic			hdu2wbf_stall_fetch;
	
	write_back_fetch wbf (
		
		.clk_i (clk_i),
		.rst_i (rst_i),
		.data_read_i (a2stages_data),
		.data_calc_i (wbf_data_calc),
		.mem_to_reg_i (wbf_mem_to_reg),
		.instr_mem_en_i (a2d_instr_en), // TODO braucht der den wirklich?
		.stall_fetch_i (hdu2wbf_stall_fetch),
		
		.branch_pc_i (wbf_branch_pc),
		.branch_i (wbf_branch),
		.instr_mem_addr_o (wbf2a_instr_mem_addr),
		.next_pc_o (wbf_next_pc),
		.write_back_o (wbf_write_back),
		.instr_mem_re_o (wbf2a_instr_mem_en),
		.pc_out (wbf_act_pc)		
	);

	logic [31:0]	d_rf2x_reg_a;
	logic [31:0]	d_rf2x_reg_b;
	logic [31:0]	d_rf2x_immidiate_value;
	logic [1:0] 	d_rf2x_ALU_op_Out;
	logic 			d_rf2x_shift_immidiate;
	logic 			d_rf2x_imm_to_alu;
	logic [31:0]	d_rf2x_pc;
	logic [31:0]	d_rf2x_next_pc;
	logic [3:0] 	x2d_rf_alu_status;
 	logic			cu_2_x_mem_load;
	logic 		 	cu_2_x_mem_write;
	logic 		 	cu_2_x_set_ALU_status;
	logic [31:0] 	x2d_wb_sp;
	logic			x2d_wb_sp_dec;
	logic 		 	d_rf2x_pc_to_alu;
	logic 			d_rf2x_mem2Reg;
	logic [3:0]		d_rf2x_rf_wr_select;
	logic 			d_rf2x_rf_wr_en;
	logic 			d_rf2x_rf_sp_wr_en;
	logic [3:0]		x2d_rf_rf_wr_select;
	logic 			x2d_rf_rf_wr_en;
	logic 			x2d_rf_rf_sp_wr_en;	
	
	// neue stalls
	logic 			cu2hdu_stall;		
	//logic 			hdu2cu_stall;
	logic			cu2hdu_stall_si;
	logic			hdu2drf_stall_decode;

	decode_rf d_rf (
		.clk_i (clk_i),
		.rst_i (rst_i),
		.stall_i (hdu2drf_stall_decode),
		.instr_i (a2stages_data),
		.instr_en_i (a2d_instr_en),
		.programm_counter_i (wbf_act_pc),
		.next_programm_counter_i (wbf_next_pc),
		.write_back_i (wbf_write_back),
		.alu_status_i(x2d_rf_alu_status),
		.wb_sp_i (x2d_wb_sp),
		.rf_wr_select_i (x2d_rf_rf_wr_select),
		.rf_wr_en_i (x2d_rf_rf_wr_en),
		.rf_sp_wr_en_i (x2d_rf_rf_sp_wr_en),
		//.cu_stall_i (hdu2cu_stall),
		
		.reg_a_o (d_rf2x_reg_a),
		.reg_b_o (d_rf2x_reg_b),
		.programm_counter_o (d_rf2x_pc),
		.next_programm_counter_o (d_rf2x_next_pc),
		.immidiate_value_o (d_rf2x_immidiate_value),
		.ALU_op_Out_o (d_rf2x_ALU_op_Out),
		.shift_immidiate_o (d_rf2x_shift_immidiate),
		.PC_to_ALU_o  (d_rf2x_pc_to_alu),
		.cu_mem_load_en_o (cu_2_x_mem_load),
		.cu_mem_write_en_o (cu_2_x_mem_write),
		.cu_set_ALU_cond_o (cu_2_x_set_ALU_status),
		.cu_branch_o(wbf_branch),
		.cu_stall_o (cu2hdu_stall),
		.cu_stall_self_instruct_o (cu2hdu_stall_si),
		.x_imm_to_alu_o (d_rf2x_imm_to_alu),
		.exec_sp_dec_o (x2d_wb_sp_dec),
		.mem2Reg_o(d_rf2x_mem2Reg),
		.rf_wr_select_o (d_rf2x_rf_wr_select),
		.rf_wr_en_o (d_rf2x_rf_wr_en),
		.rf_sp_wr_en_o (d_rf2x_rf_sp_wr_en),
		.end_program_o(end_program_o)
	);

	logic			x2hdu_stall;
	logic 			x2hdu_stall_d_rf;
	logic			x2hdu_release;
	logic			x2hdu_stall_pc;

	execute_mem x (
		.pc_i(d_rf2x_pc),
		.reg_a_i (d_rf2x_reg_a),
		.reg_b_i (d_rf2x_reg_b),
		.imm_i (d_rf2x_immidiate_value),
		.next_pc_i (d_rf2x_next_pc),
		.clk_i(clk_i),
		.rst_i(rst_i),
		.pc_to_alu (d_rf2x_pc_to_alu),
		.imm_to_alu (d_rf2x_imm_to_alu),
		.s_imm_to_alu (d_rf2x_shift_immidiate),
		.opcode_i (d_rf2x_ALU_op_Out),
		.signed_i (),
		.mem_re_i (cu_2_x_mem_load),
		.mem_we_i (cu_2_x_mem_write),
		.set_alu_status_i (cu_2_x_set_ALU_status),
		.sp_inc_i (x2d_wb_sp_dec),
		.mem_to_reg_i (d_rf2x_mem2Reg),
		.rf_wr_select_i(d_rf2x_rf_wr_select),
		.rf_wr_en_i (d_rf2x_rf_wr_en),
		.rf_sp_wr_en_i (d_rf2x_rf_sp_wr_en),
	
		.branch_o (wbf_branch_pc),
		.data_calc_o (wbf_data_calc),
		.data_mem_addr_o (x2a_data_mem_addr),
		.data_mem_o (x2a_data_mem_write),
		.alu_status_out (x2d_rf_alu_status),
		.stall_d_o (x2hdu_stall_d_rf),
		.mem_re_o (x2a_data_mem_re),
		.mem_we_o (x2a_data_mem_we),
		.sp_o (x2d_wb_sp),
		.mem_to_reg_o (wbf_mem_to_reg),
		.rf_wr_select_o(x2d_rf_rf_wr_select),
		.rf_wr_en_o (x2d_rf_rf_wr_en),
		.rf_sp_wr_en_o (x2d_rf_rf_sp_wr_en),
		.release_fetch_o (x2hdu_release),
		.stall_pc_o (x2hdu_stall_pc)
	);

	hdu hdu1 (
		.clk_i(clk_i),
		.rst_i (rst_i),
		.x_stall_pc_i(x2hdu_stall_pc),
		.cu_stall_i(cu2hdu_stall),
		.cu_stall_si_i (cu2hdu_stall_si),
		.x_stall_d_i (x2hdu_stall_d_rf),
		.x_release_f_i (x2hdu_release),

		.stall_fetch_o(hdu2wbf_stall_fetch),
		.stall_decode_o(hdu2drf_stall_decode)
	);
	
endmodule
