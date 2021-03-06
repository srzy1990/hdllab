module sign_extender #(parameter width = 8)(
	input logic [width-1:0] data_i,
	output logic [31:0] data_o
);
	logic [31-width:0] data_sign;

	assign data_sign = {(32-width){data_i[width-1]}};
	assign data_o = {data_sign, data_i};

endmodule
