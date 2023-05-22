module axi_stream_synchronizer
	#(
		parameter DATA_WIDTH_1=32,
		parameter DATA_WIDTH_2=32		
	)(
		input logic clk,
		input logic rst,
		
		input logic input_valid_1,
		output logic input_ready_1,
		input logic input_last_1,
		input logic[DATA_WIDTH_1-1:0] input_data_1,

		input logic input_valid_2,
		output logic input_ready_2,
		input logic input_last_2,
		input logic[DATA_WIDTH_2-1:0] input_data_2,
		
		output logic output_valid,
		input logic output_ready,
		output logic[DATA_WIDTH_1-1:0] output_data_1,		
		output logic[DATA_WIDTH_2-1:0] output_data_2,		
		output logic output_last_1,
		output logic output_last_2	
		);
	

	AXIS_SYNCHRONIZER_LATCHED_2 #(
			.DATA_WIDTH_0(DATA_WIDTH_1),
			.DATA_WIDTH_1(DATA_WIDTH_2),
			.USER_WIDTH(0)
		) u_AXIS_SYNCHRONIZER_LATCHED_2 (
		.clk          (clk),
		.rst          (rst),		
		
		.input_0_data (input_data_1),
		.input_0_last (input_last_1),
		.input_0_ready(input_ready_1),
		.input_0_user (),
		.input_0_valid(input_valid_1),
		
		.input_1_data (input_data_2),
		.input_1_last (input_last_2),
		.input_1_ready(input_ready_2),
		.input_1_user (),
		.input_1_valid(input_valid_2),
		
		.output_data_0(output_data_1),
		.output_data_1(output_data_2),
		.output_last_0(output_last_1),
		.output_last_1(output_last_2),
		.output_valid (output_valid),
		.output_ready (output_ready),
	
		.output_user_0(),
		.output_user_1()
	);
	
	
endmodule