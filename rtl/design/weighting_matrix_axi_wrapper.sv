module weighting_matrix_axi_wrapper #(
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
    localparam T_NUM_COLS = NUM_SIGNATURES,

    localparam C_NUM_ROWS = NUM_SIGNATURES,
    localparam C_NUM_COLS = NUM_OUTPUT_CHANNELS,

    localparam W_NUM_ROWS = NUM_CHANNELS,
    localparam W_NUM_COLS = NUM_OUTPUT_CHANNELS,

    // Matrix port parameters

    localparam T_ROW_ADDR_WIDTH = $clog2(T_NUM_ROWS),
    localparam T_COL_ADDR_WIDTH = $clog2(T_NUM_COLS),
    localparam T_ROW_SIZE = T_NUM_COLS * WIDTH,
    localparam T_COL_SIZE = T_NUM_ROWS * WIDTH,

    localparam C_ROW_ADDR_WIDTH = $clog2(C_NUM_ROWS),
    localparam C_COL_ADDR_WIDTH = $clog2(C_NUM_COLS),
    localparam C_ROW_SIZE = C_NUM_COLS * WIDTH,
    localparam C_COL_SIZE = C_NUM_ROWS * WIDTH,

    localparam W_ROW_ADDR_WIDTH = $clog2(W_NUM_ROWS),
    localparam W_COL_ADDR_WIDTH = $clog2(W_NUM_COLS),
    localparam W_ROW_SIZE = W_NUM_COLS * WIDTH,
    localparam W_COL_SIZE = W_NUM_ROWS * WIDTH
) (
    input logic clk_in1_p,
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
    output logic axis_t_load_ready,
    input logic[WIDTH-1:0] axis_t_load_data,
    input logic axis_t_load_valid,

    output finished_loading_t,

    /* ----------------------------------------------------------- */
    //                   C MATRIX LOAD
    /* ----------------------------------------------------------- */

    // AXI STREAM BUS FOR LOADING C
    output logic axis_c_load_ready,
    input logic[WIDTH-1:0] axis_c_load_data,
    input logic axis_c_load_valid,

    output finished_loading_c,

    /* ----------------------------------------------------------- */
    //                   W MATRIX READ
    /* ----------------------------------------------------------- */
    
    input logic axis_w_ready,
    output logic[WIDTH-1:0] axis_w_data,
    output logic axis_w_valid,
    output logic axis_w_last
);

logic clk;
assign clk = clk_in1_p;

// Matrix T

logic [T_ROW_ADDR_WIDTH-1:0] t_row_addr;
logic t_row_addr_ready;
logic t_row_valid;
logic [T_ROW_SIZE-1:0] t_row_out;

logic [T_COL_ADDR_WIDTH-1:0] t_col_addr;
logic t_col_addr_ready;
logic t_col_valid;
logic [T_COL_SIZE-1:0] t_col_out;

// Element writing port
logic [T_ROW_ADDR_WIDTH-1:0] t_write_row_addr;
logic [T_COL_ADDR_WIDTH-1:0] t_write_col_addr;
logic [WIDTH-1:0] t_write_data;
logic t_write_ready;

matrix 
#(
    .NUM_ROWS          (T_NUM_ROWS          ),
    .NUM_COLS          (T_NUM_COLS          ),
    .SCALAR_BITS       (WIDTH       ),
    .MEMORY_LATENCY    (MEMORY_LATENCY    )
)
u_t_matrix(
    .clk            (clk            ),
    .rst            (rst            ),
    .row_addr       (t_row_addr       ),
    .row_addr_ready (t_row_addr_ready ),
    .row_valid      (t_row_valid      ),
    .row_out        (t_row_out        ),
    .col_addr       (t_col_addr       ),
    .col_addr_ready (t_col_addr_ready ),
    .col_valid      (t_col_valid      ),
    .col_out        (t_col_out        ),
    .write_row_addr (t_write_row_addr ),
    .write_col_addr (t_write_col_addr ),
    .write_data     (t_write_data     ),
    .write_ready    (t_write_ready    )
);

// Matrix C

logic [C_ROW_ADDR_WIDTH-1:0] c_row_addr;
logic c_row_addr_ready;
logic c_row_valid;
logic [C_ROW_SIZE-1:0] c_row_out;

// Element writing port
logic [C_ROW_ADDR_WIDTH-1:0] c_write_row_addr;
logic [C_COL_ADDR_WIDTH-1:0] c_write_col_addr;
logic [WIDTH-1:0] c_write_data;
logic c_write_ready;

matrix_no_col
#(
    .NUM_ROWS          (C_NUM_ROWS          ),
    .NUM_COLS          (C_NUM_COLS          ),
    .SCALAR_BITS       (WIDTH       ),
    .MEMORY_LATENCY    (MEMORY_LATENCY    )
)
u_c_matrix(
    .clk            (clk            ),
    .rst            (rst            ),
    .row_addr       (c_row_addr       ),
    .row_addr_ready (c_row_addr_ready ),
    .row_valid      (c_row_valid      ),
    .row_out        (c_row_out        ),
    .write_row_addr (c_write_row_addr ),
    .write_col_addr (c_write_col_addr ),
    .write_data     (c_write_data     ),
    .write_ready    (c_write_ready    )
);

// Matrix W

logic [W_ROW_ADDR_WIDTH-1:0] w_row_addr;
logic w_row_addr_ready;
logic w_row_valid;
logic [W_ROW_SIZE-1:0] w_row_out;

logic [W_COL_ADDR_WIDTH-1:0] w_col_addr;
logic w_col_addr_ready;
logic w_col_valid;
logic [W_COL_SIZE-1:0] w_col_out;

// Element writing port
logic [W_ROW_ADDR_WIDTH-1:0] w_write_row_addr;
logic [W_COL_ADDR_WIDTH-1:0] w_write_col_addr;
logic [WIDTH-1:0] w_write_data;
logic w_write_ready;

matrix 
#(
    .NUM_ROWS          (W_NUM_ROWS          ),
    .NUM_COLS          (W_NUM_COLS          ),
    .SCALAR_BITS       (WIDTH       ),
    .MEMORY_LATENCY    (MEMORY_LATENCY    )
)
u_w_matrix(
    .clk            (clk            ),
    .rst            (rst            ),
    .row_addr       (w_row_addr       ),
    .row_addr_ready (w_row_addr_ready ),
    .row_valid      (w_row_valid      ),
    .row_out        (w_row_out        ),
    .col_addr       (w_col_addr       ),
    .col_addr_ready (w_col_addr_ready ),
    .col_valid      (w_col_valid      ),
    .col_out        (w_col_out        ),
    .write_row_addr (w_write_row_addr ),
    .write_col_addr (w_write_col_addr ),
    .write_data     (w_write_data     ),
    .write_ready    (w_write_ready    )
);

// ALU

logic [WIDTH*NUM_CHANNELS-1:0] nc_dot_product_a;
logic [WIDTH*NUM_CHANNELS-1:0] nc_dot_product_b;
logic [WIDTH-1:0] nc_dot_product_c;
logic [WIDTH-1:0] nc_dot_product_out;
logic [NUM_CHANNELS-1:0] nc_dot_product_enable;
logic [WIDTH*NUM_CHANNELS-1:0] nc_vector_mult_in_a;
logic [WIDTH*NUM_CHANNELS-1:0] nc_vector_mult_in_b; 
logic [WIDTH*NUM_CHANNELS-1:0] nc_vector_mult_out;
logic nc_vector_mult_alu_ready;
logic nc_dot_product_valid;
logic nc_vector_mult_valid;
logic nc_dot_product_mode;

fp_vector_mult_alu 
#(
    .WIDTH                                  (WIDTH),
    .NUM_INPUTS                             (NUM_CHANNELS)
)
u_fp_vector_mult_alu_nc(
    .clk                (clk                ),
    .rst                (rst                ),
    .dot_product_a      (nc_dot_product_a      ),
    .dot_product_b      (nc_dot_product_b      ),
    .dot_product_c      (nc_dot_product_c      ),
    .dot_product_out    (nc_dot_product_out    ),
    .dot_product_enable (nc_dot_product_enable ),
    .vector_mult_in_a   (nc_vector_mult_in_a   ),
    .vector_mult_in_b   (nc_vector_mult_in_b   ),
    .vector_mult_out    (nc_vector_mult_out    ),
    .ready              (nc_vector_mult_alu_ready),
    .dot_product_valid  (nc_dot_product_valid  ),
    .vector_mult_valid  (nc_vector_mult_valid  ),
    .dot_product_mode   (nc_dot_product_mode   )
);

// Weighting matrix

multi_target_weighting_matrix 
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
u_multi_target_weighting_matrix(
    .clk                      (clk                      ),
    .rst                      (rst                      ),
    .finished                 (finished                 ),
    .ds_next_data             (axis_p_ready             ),
    .ds_out                   (axis_p_data                   ),
    .ds_valid                 (axis_p_valid                 ),
    .t_row_addr               (t_row_addr               ),
    .t_row_addr_ready         (t_row_addr_ready         ),
    .t_row_valid              (t_row_valid              ),
    .t_row_out                (t_row_out                ),
    .t_col_addr               (t_col_addr               ),
    .t_col_addr_ready         (t_col_addr_ready         ),
    .t_col_valid              (t_col_valid              ),
    .t_col_out                (t_col_out                ),
    .c_row_addr               (c_row_addr               ),
    .c_row_addr_ready         (c_row_addr_ready         ),
    .c_row_valid              (c_row_valid              ),
    .c_row_out                (c_row_out                ),
    .w_write_row_addr         (w_write_row_addr         ),
    .w_write_col_addr         (w_write_col_addr         ),
    .w_write_data             (w_write_data             ),
    .w_write_ready            (w_write_ready            ),
    .nc_dot_product_mode      (nc_dot_product_mode      ),
    .nc_vector_mult_alu_ready (nc_vector_mult_alu_ready ),
    .nc_vector_mult_in_a      (nc_vector_mult_in_a      ),
    .nc_vector_mult_in_b      (nc_vector_mult_in_b      ),
    .nc_vector_mult_out       (nc_vector_mult_out       ),
    .nc_vector_mult_valid     (nc_vector_mult_valid     ),
    .nc_dot_product_a         (nc_dot_product_a         ),
    .nc_dot_product_b         (nc_dot_product_b         ),
    .nc_dot_product_c         (nc_dot_product_c         ),
    .nc_dot_product_out       (nc_dot_product_out       ),
    .nc_dot_product_enable    (nc_dot_product_enable    ),
    .nc_dot_product_valid     (nc_dot_product_valid     )
);

// T Matrix loader

stream_matrix_loader 
#(
    .NUM_ROWS       (T_NUM_ROWS       ),
    .NUM_COLS       (T_NUM_COLS       ),
    .WIDTH          (WIDTH          )
)
u_stream_matrix_loader_t(
    .rst              (rst              ),
    .clk              (clk              ),
    .finished_loading (finished_loading_t ),
    .ds_next_data     (axis_t_load_ready     ),
    .ds_out           (axis_t_load_data     ),
    .ds_valid         (axis_t_load_valid      ),
    .write_row_addr   (t_write_row_addr   ),
    .write_col_addr   (t_write_col_addr   ),
    .write_data       (t_write_data       ),
    .write_ready      (t_write_ready      )
);

// C Matrix loader

stream_matrix_loader 
#(
    .NUM_ROWS       (C_NUM_ROWS       ),
    .NUM_COLS       (C_NUM_COLS       ),
    .WIDTH          (WIDTH          )
)
u_stream_matrix_loader_c (
    .rst              (rst              ),
    .clk              (clk              ),
    .finished_loading (finished_loading_c ),
    .ds_next_data     (axis_c_load_ready     ),
    .ds_out           (axis_c_load_data     ),
    .ds_valid         (axis_c_load_valid      ),
    .write_row_addr   (c_write_row_addr   ),
    .write_col_addr   (c_write_col_addr   ),
    .write_data       (c_write_data       ),
    .write_ready      (c_write_ready      )
);

// W Matrix reader

stream_matrix_reader 
#(
    .WIDTH          (WIDTH          ),
    .NUM_ROWS       (W_NUM_ROWS       ),
    .NUM_COLS       (W_NUM_COLS       ),
    .MEMORY_LATENCY (MEMORY_LATENCY )
)
u_stream_matrix_reader(
    .clk            (clk            ),
    .rst            (rst            ),
    .start          (finished       ),
    .ds_next_data   (axis_w_ready   ),
    .ds_out         (axis_w_data         ),
    .ds_valid       (axis_w_valid       ),
    .ds_last        (axis_w_last        ),
    .row_addr       (w_row_addr       ),
    .row_addr_ready (w_row_addr_ready ),
    .row_valid      (w_row_valid      ),
    .row_out        (w_row_out        )
);

endmodule