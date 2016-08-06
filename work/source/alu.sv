module alu (
	input logic [31:0] data1_i,
	input logic [31:0] data2_i,
	input logic [1:0] opcode_i,			// wieviele bit brauchen mer? 
	input logic signed_i,
	input logic set_status_i,

	output logic [31:0] data_o,
	output logic [3:0] status_o
);

	parameter ADD = 0, SUB = 1, CMP  = 2, LSL = 3 ;
	logic overflow;

	always_comb begin
		status_o = 4'd0;
		overflow = 1'b0;
		data_o = 32'd0;
		
		case (opcode_i) 
			ADD: {overflow, data_o} = data1_i + data2_i;
			CMP: {overflow, data_o} = data1_i - data2_i; 
			SUB: {overflow, data_o} = data1_i - data2_i;
			LSL: {overflow, data_o} = data1_i << data2_i;
			//LSR: data_o = data_1 >> data_2;
			//ASR: data_o = data_1 >>> data_2;
			//MUL: {overflow, data_o} = data_1 * data_2;
			default:  data_o = 32'bX;
		endcase

		// set status flags
		if(set_status_i) begin	
			// zero condition code flag
			status_o[2] = ~| data_o;

			// negative condition code flag			
			status_o[3] = data_o[31];	

			// overflow condition code flag	
			if(signed_i) begin
				status_o[0] = overflow;
				status_o[1] = 0;
			end else begin // carry condition flag
				status_o[1] = overflow;
				status_o[0] = 0;
			end
		end
	end
endmodule	

