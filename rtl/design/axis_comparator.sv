// This module compares two AXIS signals

module axis_comparator #(
    parameter DATA_WIDTH = 32
) (
    input logic clk,
    input logic rst,
    
    input logic input_valid_1,
    output logic input_ready_1,
    input logic input_last_1,
    input logic[DATA_WIDTH-1:0] input_data_1,

    input logic input_valid_2,
    output logic input_ready_2,
    input logic input_last_2,
    input logic[DATA_WIDTH-1:0] input_data_2,    

    // Output:
    // 000 if comparison still is in progress
    // 001 if both streams are equal
    // 010 if one item differs in both streams
    // 100 if the streams have different length
    output logic[2:0] result
);

logic output_valid;
logic output_ready;
logic[DATA_WIDTH-1:0] output_data_1;
logic[DATA_WIDTH-1:0] output_data_2;
logic output_last_1;
logic output_last_2;

axi_stream_synchronizer 
#(
    .DATA_WIDTH_1 (DATA_WIDTH ),
    .DATA_WIDTH_2 (DATA_WIDTH )
)
u_axi_stream_synchronizer(
    .clk           (clk           ),
    .rst           (rst           ),
    .input_valid_1 (input_valid_1 ),
    .input_ready_1 (input_ready_1 ),
    .input_last_1  (input_last_1  ),
    .input_data_1  (input_data_1  ),
    
    .input_valid_2 (input_valid_2 ),
    .input_ready_2 (input_ready_2 ),
    .input_last_2  (input_last_2  ),
    .input_data_2  (input_data_2  ),

    .output_valid  (output_valid  ),
    .output_ready  (output_ready  ),
    .output_data_1 (output_data_1 ),
    .output_data_2 (output_data_2 ),
    .output_last_1 (output_last_1 ),
    .output_last_2 (output_last_2 )
);

logic elements_equal;
logic one_last_signal;
logic all_last_signals;

assign elements_equal = output_data_1 == output_data_2;

assign one_last_signal = output_last_1 || output_last_2;
assign all_last_signals = output_last_1 && output_last_2; 

typedef enum { comp_not_finished, comp_correct, comp_different_length, comp_not_equal_elements } comparison_state;

comparison_state state;
comparison_state state_next;

always_ff @( posedge clk ) begin
    if(rst) begin
        state <= comp_not_finished;
    end else begin
        state <= state_next;
    end
end

always_comb begin : next_state
    unique case(state)
        comp_not_finished: begin
            output_ready = 1'b1;
            state_next = comp_not_finished;

            if (output_ready && output_valid) begin
                // If there's a transaction on the bus

                if (!elements_equal) begin
                    state_next = comp_not_equal_elements;
                end else if (one_last_signal) begin
                if (all_last_signals) begin
                        state_next = comp_correct;
                end else begin
                        state_next = comp_different_length;
                end
                end
            end
        end
        comp_correct: begin
            state_next = comp_correct;
            output_ready = 1'b0;
        end
        comp_different_length: begin
            state_next = comp_different_length;
            output_ready = 1'b0;
        end
        comp_not_equal_elements: begin
            state_next = comp_not_equal_elements;
            output_ready = 1'b0;
        end
    endcase
end

always_comb begin : outputs
    unique case(state)
        comp_not_finished: begin
            result = 3'b000;
        end
        comp_correct: begin
            result = 3'b001;
        end
        comp_different_length: begin
            result = 3'b100;            
        end
        comp_not_equal_elements: begin
            result = 3'b010;
        end
    endcase
end


endmodule
