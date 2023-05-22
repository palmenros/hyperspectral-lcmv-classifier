module weighting_matrix_golden_test #(
    parameter WIDTH=32
) (
    input logic clk,
    input logic rst,

    // Result from axis_comparator
    output logic[2:0] result
);


logic[WIDTH-1:0] axis_p_data;
logic axis_p_ready;
logic axis_p_valid;
logic axis_p_last;

logic start_axis_p;

axis_test_rom_reader 
#(
    .ROM_NAME           ("test_x_1"),
    .DEPTH              (550),
    .WIDTH              (WIDTH)
)
u_axis_test_rom_reader_x_1(
    .clk          (clk          ),
    .rst          (rst          ),
    .start        (start_axis_p),
    
    .ds_next_data (axis_p_ready),
    .ds_out       (axis_p_data),
    .ds_valid     (axis_p_valid),
    .ds_last      (axis_p_last)
);


logic one_shot_start;

typedef enum { s0, s1, s2} one_shot_state_t;

one_shot_state_t state;
one_shot_state_t next_state;

always_ff @( posedge clk ) begin
    if(rst) begin
        state <= s0;
    end else begin
        state <= next_state;
    end
end

always_comb begin
    unique case(state)
    s0: begin
        one_shot_start = 1'b0;
        next_state = s1;    
    end
    s1: begin
        one_shot_start = 1'b1;
        next_state = s2;            
    end
    s2: begin
        one_shot_start = 1'b0;
        next_state = s2;                
    end
    endcase 
end

logic[WIDTH-1:0] axis_tc_data;
logic axis_tc_ready;
logic axis_tc_valid;
logic axis_tc_last;


axis_test_rom_reader 
#(
    .ROM_NAME           ("test_tc_1"),
    .DEPTH              (70),
    .WIDTH              (WIDTH)
)
u_axis_test_rom_reader_tc_1(
    .clk          (clk          ),
    .rst          (rst          ),
    .start        (one_shot_start),
    
    .ds_next_data (axis_tc_ready),
    .ds_out       (axis_tc_data),
    .ds_valid     (axis_tc_valid),
    .ds_last      (axis_tc_last)
);

logic computed_axis_w_last;
logic computed_axis_w_valid;
logic[WIDTH-1:0] computed_axis_w_data;
logic computed_axis_w_ready;

weighting_matrix_tc_axi_wrapper 
#(
    .WIDTH(WIDTH),
    .NUM_PIXELS(50),        /* Number of total pixels in image */
    .NUM_CHANNELS(11),       /* Number of spectral channels in input hyperspectral image*/
    .NUM_SIGNATURES(5),      /* Number of signatures to detect */
    .NUM_OUTPUT_CHANNELS(3)  /* Number of channels in output image */
) u_weighting_matrix_tc_axi_wrapper(
    .clk                (clk),
    .rst                (rst),
    .finished           (),

    .axis_p_ready       (axis_p_ready       ),
    .axis_p_data        (axis_p_data        ),
    .axis_p_valid       (axis_p_valid       ),

    .axis_tc_load_ready (axis_tc_ready ),
    .axis_tc_load_data  (axis_tc_data  ),
    .axis_tc_load_valid (axis_tc_valid ),
    .axis_tc_last       (axis_tc_last       ),
    
    .finished_loading   (start_axis_p),
    
    .axis_w_ready       (computed_axis_w_ready),
    .axis_w_data        (computed_axis_w_data),
    .axis_w_valid       (computed_axis_w_valid),
    .axis_w_last        (computed_axis_w_last)
);


logic[WIDTH-1:0] rom_axis_w_data;
logic rom_axis_w_ready;
logic rom_axis_w_valid;
logic rom_axis_w_last;


axis_test_rom_reader 
#(
    .ROM_NAME           ("test_w_1"),
    .DEPTH              (33),
    .WIDTH              (WIDTH)
)
u_axis_test_rom_reader_w_1(
    .clk          (clk          ),
    .rst          (rst          ),
    .start        (one_shot_start),
    
    .ds_next_data (rom_axis_w_ready),
    .ds_out       (rom_axis_w_data),
    .ds_valid     (rom_axis_w_valid),
    .ds_last      (rom_axis_w_last)
);


axis_comparator 
#(
    .DATA_WIDTH (WIDTH )
)
u_axis_comparator(
    .clk           (clk           ),
    .rst           (rst           ),
    .input_valid_1 (computed_axis_w_valid ),
    .input_ready_1 (computed_axis_w_ready ),
    .input_last_1  (computed_axis_w_last  ),
    .input_data_1  (computed_axis_w_data  ),

    .input_valid_2 (rom_axis_w_valid ),
    .input_ready_2 (rom_axis_w_ready ),
    .input_last_2  (rom_axis_w_last  ),
    .input_data_2  (rom_axis_w_data  ),
    
    .result        (result)
);


endmodule
