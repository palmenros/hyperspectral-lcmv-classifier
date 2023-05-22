module weighting_matrix_tc_axi_wrapper #(
    parameter WIDTH = 32,               /* Width of an scalar element */

    parameter NUM_PIXELS = 4096,        /* Number of total pixels in image */
    parameter NUM_CHANNELS = 169,       /* Number of spectral channels in input hyperspectral image*/
    parameter NUM_SIGNATURES = 15,      /* Number of signatures to detect */
    parameter NUM_OUTPUT_CHANNELS = 3,  /* Number of channels in output image */
    
    // Latencies

    parameter MEMORY_LATENCY = 2,
    parameter MULTIPLIER_LATENCY = 8,
    parameter ADDER_LATENCY = 11,
    parameter DIVIDER_LATENCY = 28,

    // Matrix sizes

    localparam T_NUM_ROWS = NUM_CHANNELS,
    localparam T_NUM_COLS = NUM_SIGNATURES
) (
    input logic clk,
    input logic rst,

    output logic finished,

    /* ----------------------------------------------------------- */
    //                   PIXELS DATA STREAM BUS
    /* ----------------------------------------------------------- */

    // AXI STREAM BUS FOR LOADING PIXELS
    output logic axis_p_ready,
    input logic[WIDTH-1:0] axis_p_data,
    input logic axis_p_valid,

    /* ----------------------------------------------------------- */
    //                   T MATRIX LOAD
    /* ----------------------------------------------------------- */

    // AXI STREAM BUS FOR LOADING
    output logic axis_tc_load_ready,
    input logic[WIDTH-1:0] axis_tc_load_data,
    input logic axis_tc_load_valid,
    input logic axis_tc_last,

    output finished_loading,

    /* ----------------------------------------------------------- */
    //                   W MATRIX READ
    /* ----------------------------------------------------------- */
    
    input logic axis_w_ready,
    output logic[WIDTH-1:0] axis_w_data,
    output logic axis_w_valid,
    output logic axis_w_last
);

    // T matrix

    logic axis_t_load_ready;
    logic[WIDTH-1:0] axis_t_load_data;
    logic axis_t_load_valid;

    // C matrix

    logic axis_c_load_ready;
    logic[WIDTH-1:0] axis_c_load_data;
    logic axis_c_load_valid;


    stream_splitter 
    #(
        .WIDTH                     (WIDTH                  ),
        .NUM_ELEMENTS_FIRST_OUTPUT (T_NUM_COLS * T_NUM_ROWS)
    )
    u_stream_splitter(
    	.clk                (clk               ),
        .rst                (rst               ),
        .ds_in_next_data    (axis_tc_load_ready),
        .ds_in_out          (axis_tc_load_data),
        .ds_in_valid        (axis_tc_load_valid),
        .ds_in_last         (axis_tc_last),
    
        .ds_out_a_next_data (axis_t_load_ready),
        .ds_out_a           (axis_t_load_data),
        .ds_out_a_valid     (axis_t_load_valid),
        .ds_out_a_last      (),
    
        .ds_out_b_next_data (axis_c_load_ready ),
        .ds_out_b           (axis_c_load_data   ),
        .ds_out_b_valid     (axis_c_load_valid  ),
        .ds_out_b_last      ()
    );
    

    weighting_matrix_axi_wrapper 
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
    u_weighting_matrix_axi_wrapper(
    	.clk_in1_p          (clk                ),
        .rst                (rst                ),
        .finished           (finished           ),
        .axis_p_ready       (axis_p_ready       ),
        .axis_p_data        (axis_p_data        ),
        .axis_p_valid       (axis_p_valid       ),
        .axis_t_load_ready  (axis_t_load_ready  ),
        .axis_t_load_data   (axis_t_load_data   ),
        .axis_t_load_valid  (axis_t_load_valid  ),
        .finished_loading_t (),
        .axis_c_load_ready  (axis_c_load_ready  ),
        .axis_c_load_data   (axis_c_load_data   ),
        .axis_c_load_valid  (axis_c_load_valid  ),
        .finished_loading_c (finished_loading),
        .axis_w_ready       (axis_w_ready       ),
        .axis_w_data        (axis_w_data        ),
        .axis_w_valid       (axis_w_valid       ),
        .axis_w_last        (axis_w_last        )
    );
    


endmodule
