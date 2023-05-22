module weighting_matrix_tc_axi_mock #(
    parameter WIDTH = 32,               /* Width of an scalar element */

    parameter NUM_PIXELS = 4096,        /* Number of total pixels in image */
    parameter NUM_CHANNELS = 128,       /* Number of spectral channels in input hyperspectral image*/
    parameter NUM_SIGNATURES = 15,      /* Number of signatures to detect */
    parameter NUM_OUTPUT_CHANNELS = 3,  /* Number of channels in output image */
    
    // Latencies

    parameter MEMORY_LATENCY = 2,
    parameter MULTIPLIER_LATENCY = 8,
    parameter ADDER_LATENCY = 11,
    parameter DIVIDER_LATENCY = 28
) (
    input logic clk_in1_p,
    input logic rst_i,

    input logic[7:0] in,
    output logic[6:0] out
);

    /*output*/ logic finished;
    /*output*/ logic axis_p_ready;
    /*output*/ logic axis_tc_load_ready;
    /*output*/ logic finished_loading;
    /*output*/ logic[WIDTH-1:0] axis_w_data;
    /*output*/ logic axis_w_valid;
    /*output*/ logic axis_w_last;

    assign out = {finished, axis_p_ready, axis_tc_load_ready, finished_loading, ^axis_w_data, axis_w_valid, axis_w_last};

    /*input*/ logic[WIDTH-1:0] axis_p_data;
    /*input*/ logic[WIDTH-1:0] axis_tc_load_data;
    /*input*/ logic axis_p_valid;
    /*input*/ logic axis_tc_load_valid;
    /*input*/ logic axis_tc_last;
    /*input*/ logic axis_w_ready;

    assign axis_p_valid = in[0];
    assign axis_tc_load_valid = in[1];
    assign axis_tc_last = in[2];
    assign axis_w_ready = in[3];

    assign axis_p_data = {4{in}};
    assign axis_tc_load_data = {4{~in ^ 8'b10100010}};

    weighting_matrix_tc_axi_wrapper 
    #(
        .WIDTH               (WIDTH               ),
        .NUM_PIXELS          (NUM_PIXELS          ),
        .NUM_CHANNELS        (NUM_CHANNELS        ),
        .NUM_SIGNATURES      (NUM_SIGNATURES      ),
        .NUM_OUTPUT_CHANNELS (NUM_OUTPUT_CHANNELS ),
        .MEMORY_LATENCY      (MEMORY_LATENCY      ),
        .MULTIPLIER_LATENCY  (MULTIPLIER_LATENCY  ),
        .ADDER_LATENCY       (ADDER_LATENCY       ),
        .DIVIDER_LATENCY     (DIVIDER_LATENCY     )
    )
    u_weighting_matrix_tc_axi_wrapper(
    	.clk                (clk_in1_p          ),
        .rst                (rst_i              ),
        .finished           (finished           ),
        .axis_p_ready       (axis_p_ready       ),
        .axis_p_data        (axis_p_data        ),
        .axis_p_valid       (axis_p_valid       ),
        .axis_tc_load_ready (axis_tc_load_ready ),
        .axis_tc_load_data  (axis_tc_load_data  ),
        .axis_tc_load_valid (axis_tc_load_valid ),
        .axis_tc_last       (axis_tc_last       ),
        .finished_loading   (finished_loading   ),
        .axis_w_ready       (axis_w_ready       ),
        .axis_w_data        (axis_w_data        ),
        .axis_w_valid       (axis_w_valid       ),
        .axis_w_last        (axis_w_last        )
    );
    

endmodule
