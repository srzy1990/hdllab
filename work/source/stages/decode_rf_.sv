
module decode_rf (
	input logic 		clk_i,
	input logic			rst_i,
	input logic [15:0]	instr_i,
	input logic [31:0]  programm_counter_i,
	input logic [31:0]  next_programm_counter_i,
	input logic [31:0]  write_back_i,
	input logic [3:0] 	alu_status_i,
	input logic [31:0]  wb_sp_i,
	//input logic 		cu_stall_i,
	input logic			instr_en_i,

	output logic [31:0]  reg_a_o,
	output logic [31:0]  reg_b_o,
	output logic [31:0]	 programm_counter_o,
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


	//
	input logic [3:0] rf_wr_select_i,
	input logic 	  rf_wr_en_i,
	input logic 	  rf_sp_wr_en_i,
		
	output logic [3:0] rf_wr_select_o,
	output logic 	   rf_wr_en_o,
	output logic 	   rf_sp_wr_en_o		
);
	//register_file logic
	
	

	logic [3:0] rf_rd0_sel;
	
	logic [3:0] rf_rd1_sel;
	logic rf_wr_en;
	logic [3:0] rf_wr_sel;


	logic [7:0] immOut;
	logic 		PCtoALU;
	logic 		shift_imm;
	logic [1:0]	ALUopOut;
	logic 		use_immidiate;
	logic [31:0]		reg_a;
	logic [31:0]		reg_b;

	logic		sp_wr_en;

	logic  o_2rf_wr_en;
	assign o_2rf_wr_en = rf_wr_en_i;

	register_file rf(
		.clk (clk_i),
		.rst (rst_i),	
		.stall_i (~instr_en_i),			// stall values from RegFile if we don't have a new instruction
		.rd0_select (rf_rd0_sel),
		.rd1_select (rf_rd1_sel),
		.write_en (o_2rf_wr_en),
		.wr_select (rf_wr_select_i),
		.data_in (write_back_i),
		.sp_in (wb_sp_i),
		.data_out0 (reg_a),
		.data_out1 (reg_b),
		.sp_write_en (rf_sp_wr_en_i)
	);

	logic cu_mem_load_en;
	logic cu_mem_write_en;
	logic cu_set_ALU_cond;
	logic cu_branch;
	logic self_instruct_en;
	logic [15:0]	self_instruct;
	logic [15:0]	self_instruct_buffer_1;
	logic self_instruct_en_buffer_1;
	logic [15:0]	self_instruct_buffer_2;
	logic self_instruct_en_buffer_2;

	logic [15:0]	instruct_cu;
	logic 			mem2Reg;
	logic 			sp_wr_en_buffer;

	controlunit cu (
		.alu_status_i(alu_status_i),
		.in (instruct_cu),
		.cu_input_en_i (1/*~cu_stall_i | self_instruct_en_buffer_2*/),
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
		.rf_write_en_o (rf_wr_en),
		.end_program_o (end_program_o)
		
	);
	
	always_comb begin
		if (self_instruct_en_buffer_2)
			instruct_cu = self_instruct_buffer_2;
			
		else if (instr_en_i) begin
			instruct_cu = instr_i;
		end
		
		else instruct_cu = 16'b1111;
	end
	
	assign cu_stall_o = cu_mem_load_en || cu_mem_write_en;
	assign cu_stall_self_instruct_o = self_instruct_en; //self_instruct_en_buffer_2;
	assign reg_a_o = reg_a; 
	assign reg_b_o =  reg_b;

	always_ff @ (posedge clk_i) begin
		if(rst_i) begin
			self_instruct_en_buffer_2 <= 0;
			self_instruct_en_buffer_1 <= 0;
		end 
		else begin		
			if(instr_en_i) begin
				self_instruct_en_buffer_1 <= self_instruct_en;
				self_instruct_buffer_1 <= self_instruct;
				self_instruct_en_buffer_2 <= self_instruct_en_buffer_1;
				self_instruct_buffer_2 <= self_instruct_buffer_1;				

				immidiate_value_o <= {24'd0, immOut};
				programm_counter_o <= programm_counter_i;
				next_programm_counter_o <= next_programm_counter_i;

				
		
				
				cu_mem_load_en_o <= cu_mem_load_en;
				cu_mem_write_en_o <= cu_mem_write_en;
				cu_set_ALU_cond_o <= cu_set_ALU_cond;
				cu_branch_o <= cu_branch;
		
				x_imm_to_alu_o <= use_immidiate;
				mem2Reg_o <= mem2Reg;
				
				rf_wr_select_o <= rf_wr_sel;
				rf_wr_en_o <= rf_wr_en;
				rf_sp_wr_en_o <= sp_wr_en_buffer;
				sp_wr_en_buffer <= sp_wr_en;
				ALU_op_Out_o <= ALUopOut;
				shift_immidiate_o <= shift_imm;
				PC_to_ALU_o <= PCtoALU;
			
			end
			else begin
				self_instruct_en_buffer_1 <= 0;
				self_instruct_buffer_1 <= 0;

				
			end
		end
	end
	
endmodule
