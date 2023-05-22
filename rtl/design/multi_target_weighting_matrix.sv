module multi_target_weighting_matrix #(
    parameter WIDTH = 32,               /* Width of an scalar element */

    parameter NUM_PIXELS = 4096,        /* Number of total pixels in image */
    parameter NUM_CHANNELS = 4,       /* Number of spectral channels in input hyperspectral image*/
    parameter NUM_SIGNATURES = 5,      /* Number of signatures to detect */
    parameter NUM_OUTPUT_CHANNELS = 3,  /* Number of channels in output image */
    
    // Latencies

    parameter MEMORY_LATENCY = 2,
    parameter MULTIPLIER_LATENCY = 8,
    parameter ADDER_LATENCY = 11,
    parameter DIVIDER_LATENCY = 28,

    parameter PIPELINE_ADDER_TREE = 1,

    // Introduce a set of registers after the multiplication and before the adder tree if set to 1
    // If set to 0, then directly connect the adder tree
    parameter PIPELINE_BETWEEN_MULT_AND_ADDER_TREE = 1,

    // If PIPELINE_BETWEEN_MULT_AND_ADDER_TREE = 1
    parameter USE_RESET_FOR_REGISTERS_INSTEAD_OF_MUX = 1,

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
    localparam W_COL_ADDR_WIDTH = $clog2(W_NUM_COLS)
) (
    input logic clk,
    input logic rst,

    output logic finished,

    /* ----------------------------------------------------------- */
    //                   PIXELS DATA STREAM BUS
    /* ----------------------------------------------------------- */

    output logic ds_next_data, /* If ds_next_data = 1, we are ready to accept a new data from the bus */
    input logic[WIDTH-1:0] ds_out,   /* Stream data from the bus */
    input logic ds_valid,      /* If ds_valid = 1, ds_out is valid */

    /* ----------------------------------------------------------- */
    //                       MATRIX PORTS
    /* ----------------------------------------------------------- */

    // Matrix T

    output logic [T_ROW_ADDR_WIDTH-1:0] t_row_addr,
    output logic t_row_addr_ready,
    input logic t_row_valid,
    input logic [T_ROW_SIZE-1:0] t_row_out,

    output logic [T_COL_ADDR_WIDTH-1:0] t_col_addr,
    output logic t_col_addr_ready,
    input logic t_col_valid,
    input logic [T_COL_SIZE-1:0] t_col_out,

    // Matrix C

    output logic [C_ROW_ADDR_WIDTH-1:0] c_row_addr,
    output logic c_row_addr_ready,
    input logic c_row_valid,
    input logic [C_ROW_SIZE-1:0] c_row_out,
    
    // Matrix W

    output logic [W_ROW_ADDR_WIDTH-1:0] w_write_row_addr,
    output logic [W_COL_ADDR_WIDTH-1:0] w_write_col_addr,
    output logic [WIDTH-1:0] w_write_data,
    output logic w_write_ready,


    /* ----------------------------------------------------------- */
    //           NUM_CHANNELS FP VECTOR MULT ALU PORTS
    /* ----------------------------------------------------------- */

    // We don't instantiate the NUM_CHANNELS FP Vector Mult ALU because it can be shared with pixel classification

    // If dot_product_mode = 1, the ALU will be configured to act as the dot product,
    // else, it will act as a vector multiplier
    output logic nc_dot_product_mode,
    output logic nc_vector_mult_alu_ready,

    output logic [WIDTH*NUM_CHANNELS-1:0] nc_vector_mult_in_a,
    output logic [WIDTH*NUM_CHANNELS-1:0] nc_vector_mult_in_b, 
    input logic [WIDTH*NUM_CHANNELS-1:0] nc_vector_mult_out,
    input logic nc_vector_mult_valid,

    output logic [WIDTH*NUM_CHANNELS-1:0] nc_dot_product_a,
    output logic [WIDTH*NUM_CHANNELS-1:0] nc_dot_product_b,
    output logic [WIDTH-1:0] nc_dot_product_c,

    input logic [WIDTH-1:0] nc_dot_product_out,
    output logic [NUM_CHANNELS-1:0] nc_dot_product_enable,

    input logic nc_dot_product_valid
);
    
/* ----------------------------------------------------------- */
//                   NUM_SIGNATURES ALU
/* ----------------------------------------------------------- */

// Dot product 
logic [NUM_SIGNATURES*WIDTH-1:0] ns_dot_product_a, ns_dot_product_b;
logic [NUM_SIGNATURES-1:0] ns_dot_product_enable;
logic [WIDTH-1:0] ns_dot_product_c, ns_dot_product_out;
logic ns_dot_product_valid;

// Vector mult

logic [NUM_SIGNATURES*WIDTH-1:0] ns_vector_mult_in_a, ns_vector_mult_in_b, ns_vector_mult_out;
logic ns_vector_mult_valid;

// Common

logic ns_vector_mult_alu_ready;
logic ns_dot_product_mode;

fp_vector_mult_alu 
#(
    .WIDTH                                  (WIDTH),
    .NUM_INPUTS                             (NUM_SIGNATURES),
    .MULT_LATENCY                           (MULTIPLIER_LATENCY),
    .SUM_LATENCY                            (ADDER_LATENCY)
)
u_fp_vector_mult_alu(
    .clk                (clk                ),
    .rst                (rst                ),
    .dot_product_a      (ns_dot_product_a      ),
    .dot_product_b      (ns_dot_product_b      ),
    .dot_product_c      (ns_dot_product_c      ),
    .dot_product_out    (ns_dot_product_out    ),
    .dot_product_enable (ns_dot_product_enable ),
    .vector_mult_in_a   (ns_vector_mult_in_a   ),
    .vector_mult_in_b   (ns_vector_mult_in_b   ),
    .vector_mult_out    (ns_vector_mult_out    ),
    .ready              (ns_vector_mult_alu_ready),
    .dot_product_valid  (ns_dot_product_valid  ),
    .vector_mult_valid  (ns_vector_mult_valid  ),
    .dot_product_mode   (ns_dot_product_mode   )
);


/* ----------------------------------------------------------- */
//                        MATRICES
/* ----------------------------------------------------------- */

// ROW MATRIX R

localparam R_NUM_ROWS = NUM_CHANNELS;
localparam R_NUM_COLS = NUM_CHANNELS;

localparam R_ROW_ADDR_WIDTH = $clog2(R_NUM_ROWS);
localparam R_ROW_SIZE = R_NUM_COLS * WIDTH;

localparam R_COL_ADDR_WIDTH = $clog2(R_NUM_COLS);
localparam R_COL_SIZE = R_NUM_ROWS * WIDTH;

// Row read
logic [R_ROW_ADDR_WIDTH-1:0] rr_row_addr;
logic rr_row_addr_ready, rr_row_valid;
logic [R_ROW_SIZE-1:0] rr_row_out;

// Write
logic rr_write_ready;
logic [R_ROW_SIZE-1:0] rr_write_data;
logic [R_ROW_ADDR_WIDTH-1:0] rr_write_row_addr;


row_matrix 
#(
    .NUM_ROWS       (R_NUM_ROWS),
    .NUM_COLS       (R_NUM_COLS),
    .SCALAR_BITS    (WIDTH),
    .MEMORY_LATENCY (MEMORY_LATENCY )
)
u_r_row_matrix(
    .clk            (clk            ),
    .rst            (rst            ),
    .row_addr       (rr_row_addr       ),
    .row_addr_ready (rr_row_addr_ready ),
    .row_valid      (rr_row_valid      ),
    .row_out        (rr_row_out        ),
    .write_row_addr (rr_write_row_addr ),
    .write_data     (rr_write_data     ),
    .write_ready    (rr_write_ready    )
);

// MATRIX R

logic [R_ROW_ADDR_WIDTH-1:0] r_row_addr;
logic r_row_addr_ready;
logic r_row_valid;
logic [R_ROW_SIZE-1:0] r_row_out;

logic [R_COL_ADDR_WIDTH-1:0] r_col_addr;
logic r_col_addr_ready;
logic r_col_valid;
logic [R_COL_SIZE-1:0] r_col_out;

logic [R_ROW_ADDR_WIDTH-1:0] r_write_row_addr;
logic [R_COL_ADDR_WIDTH-1:0] r_write_col_addr;
logic [WIDTH-1:0] r_write_data;
logic r_write_ready;

matrix 
#(
    .NUM_ROWS          (R_NUM_ROWS),
    .NUM_COLS          (R_NUM_COLS),
    .SCALAR_BITS       (WIDTH),
    .MEMORY_LATENCY    (MEMORY_LATENCY)
)
u_r_matrix(
    .clk            (clk            ),
    .rst            (rst            ),
    .row_addr       (r_row_addr       ),
    .row_addr_ready (r_row_addr_ready ),
    .row_valid      (r_row_valid      ),
    .row_out        (r_row_out        ),
    .col_addr       (r_col_addr       ),
    .col_addr_ready (r_col_addr_ready ),
    .col_valid      (r_col_valid      ),
    .col_out        (r_col_out        ),
    .write_row_addr (r_write_row_addr ),
    .write_col_addr (r_write_col_addr ),
    .write_data     (r_write_data     ),
    .write_ready    (r_write_ready    )
);


// MATRIX T1

localparam T1_NUM_ROWS = NUM_CHANNELS;
localparam T1_NUM_COLS = NUM_SIGNATURES;

localparam T1_ROW_ADDR_WIDTH = $clog2(T1_NUM_ROWS);
localparam T1_ROW_SIZE = T1_NUM_COLS * WIDTH;

localparam T1_COL_ADDR_WIDTH = $clog2(T1_NUM_COLS);
localparam T1_COL_SIZE = T1_NUM_ROWS * WIDTH;

logic [T1_ROW_ADDR_WIDTH-1:0] t1_row_addr;
logic t1_row_addr_ready;
logic t1_row_valid;
logic [T1_ROW_SIZE-1:0] t1_row_out;

logic [T1_COL_ADDR_WIDTH-1:0] t1_col_addr;
logic t1_col_addr_ready;
logic t1_col_valid;
logic [T1_COL_SIZE-1:0] t1_col_out;

logic [T1_ROW_ADDR_WIDTH-1:0] t1_write_row_addr;
logic [T1_COL_ADDR_WIDTH-1:0] t1_write_col_addr;
logic [WIDTH-1:0] t1_write_data;
logic t1_write_ready;

matrix 
#(
    .NUM_ROWS          (T1_NUM_ROWS),
    .NUM_COLS          (T1_NUM_COLS),
    .SCALAR_BITS       (WIDTH),
    .MEMORY_LATENCY    (MEMORY_LATENCY)
)
u_t1_matrix(
    .clk            (clk            ),
    .rst            (rst            ),
    .row_addr       (t1_row_addr       ),
    .row_addr_ready (t1_row_addr_ready ),
    .row_valid      (t1_row_valid      ),
    .row_out        (t1_row_out        ),
    .col_addr       (t1_col_addr       ),
    .col_addr_ready (t1_col_addr_ready ),
    .col_valid      (t1_col_valid      ),
    .col_out        (t1_col_out        ),
    .write_row_addr (t1_write_row_addr ),
    .write_col_addr (t1_write_col_addr ),
    .write_data     (t1_write_data     ),
    .write_ready    (t1_write_ready    )
);

// MATRIX T2

localparam T2_NUM_ROWS = NUM_SIGNATURES;
localparam T2_NUM_COLS = NUM_SIGNATURES;

localparam T2_ROW_ADDR_WIDTH = $clog2(T2_NUM_ROWS);
localparam T2_ROW_SIZE = T2_NUM_COLS * WIDTH;

localparam T2_COL_ADDR_WIDTH = $clog2(T2_NUM_COLS);
localparam T2_COL_SIZE = T2_NUM_ROWS * WIDTH;

logic [T2_ROW_ADDR_WIDTH-1:0] t2_row_addr;
logic t2_row_addr_ready;
logic t2_row_valid;
logic [T2_ROW_SIZE-1:0] t2_row_out;

logic [T2_COL_ADDR_WIDTH-1:0] t2_col_addr;
logic t2_col_addr_ready;
logic t2_col_valid;
logic [T2_COL_SIZE-1:0] t2_col_out;

logic [T2_ROW_ADDR_WIDTH-1:0] t2_write_row_addr;
logic [T2_COL_ADDR_WIDTH-1:0] t2_write_col_addr;
logic [WIDTH-1:0] t2_write_data;
logic t2_write_ready;

matrix 
#(
    .NUM_ROWS          (T2_NUM_ROWS),
    .NUM_COLS          (T2_NUM_COLS),
    .SCALAR_BITS       (WIDTH),
    .MEMORY_LATENCY    (MEMORY_LATENCY)
)
u_t2_matrix(
    .clk            (clk            ),
    .rst            (rst            ),
    .row_addr       (t2_row_addr       ),
    .row_addr_ready (t2_row_addr_ready ),
    .row_valid      (t2_row_valid      ),
    .row_out        (t2_row_out        ),
    .col_addr       (t2_col_addr       ),
    .col_addr_ready (t2_col_addr_ready ),
    .col_valid      (t2_col_valid      ),
    .col_out        (t2_col_out        ),
    .write_row_addr (t2_write_row_addr ),
    .write_col_addr (t2_write_col_addr ),
    .write_data     (t2_write_data     ),
    .write_ready    (t2_write_ready    )
);

// MATRIX T3

localparam T3_NUM_ROWS = NUM_SIGNATURES;
localparam T3_NUM_COLS = NUM_OUTPUT_CHANNELS;

localparam T3_ROW_ADDR_WIDTH = $clog2(T3_NUM_ROWS);
localparam T3_ROW_SIZE = T3_NUM_COLS * WIDTH;

localparam T3_COL_ADDR_WIDTH = $clog2(T3_NUM_COLS);
localparam T3_COL_SIZE = T3_NUM_ROWS * WIDTH;

logic [T3_COL_ADDR_WIDTH-1:0] t3_col_addr;
logic t3_col_addr_ready;
logic t3_col_valid;
logic [T3_COL_SIZE-1:0] t3_col_out;

logic [T3_ROW_ADDR_WIDTH-1:0] t3_write_row_addr;
logic [T3_COL_ADDR_WIDTH-1:0] t3_write_col_addr;
logic [WIDTH-1:0] t3_write_data;
logic t3_write_ready;

matrix_no_row 
#(
    .NUM_ROWS          (T3_NUM_ROWS),
    .NUM_COLS          (T3_NUM_COLS),
    .SCALAR_BITS       (WIDTH),
    .MEMORY_LATENCY    (MEMORY_LATENCY)
)
u_t3_matrix(
    .clk            (clk            ),
    .rst            (rst            ),
    .col_addr       (t3_col_addr       ),
    .col_addr_ready (t3_col_addr_ready ),
    .col_valid      (t3_col_valid      ),
    .col_out        (t3_col_out        ),
    .write_row_addr (t3_write_row_addr ),
    .write_col_addr (t3_write_col_addr ),
    .write_data     (t3_write_data     ),
    .write_ready    (t3_write_ready    )
);


/* ----------------------------------------------------------- */
//                     CORRELATION
/* ----------------------------------------------------------- */

logic corr_finished;
logic [R_ROW_ADDR_WIDTH-1:0] c_r_row_addr;
logic c_r_row_addr_ready, c_r_row_valid;
logic [R_ROW_SIZE-1:0] c_r_row_out;

logic c_dot_product_mode, c_vector_mult_valid, c_vector_mult_alu_ready;
logic [R_ROW_SIZE-1:0] c_vector_mult_in_a, c_vector_mult_in_b, c_vector_mult_out;

correlation_matrix 
#(
    .N                  (NUM_PIXELS),
    .M                  (NUM_CHANNELS),
    .WIDTH              (WIDTH              ),
    .MEMORY_LATENCY     (MEMORY_LATENCY     ),
    .MULTIPLIER_LATENCY (MULTIPLIER_LATENCY ),
    .ADDER_LATENCY      (ADDER_LATENCY      )
)
u_correlation_matrix(
    .clk                   (clk                   ),
    .rst                   (rst                   ),
    .finished              (corr_finished              ),
    .ds_next_data          (ds_next_data          ),
    .ds_out                (ds_out                ),
    .ds_valid              (ds_valid              ),
    .r_row_addr            (c_r_row_addr            ),
    .r_row_addr_ready      (c_r_row_addr_ready      ),
    .r_row_valid           (c_r_row_valid           ),
    .r_row_out             (c_r_row_out             ),
    .r_write_row_addr      (rr_write_row_addr      ),
    .r_write_data          (rr_write_data          ),
    .r_write_ready         (rr_write_ready         ),
    .dot_product_mode      (c_dot_product_mode      ),
    .vector_mult_alu_ready (c_vector_mult_alu_ready ),
    .vector_mult_in_a      (c_vector_mult_in_a      ),
    .vector_mult_in_b      (c_vector_mult_in_b      ),
    .vector_mult_out       (c_vector_mult_out       ),
    .vector_mult_valid     (c_vector_mult_valid     )
);

fp_vector_mult 
#(
    .WIDTH      (WIDTH      ),
    .NUM_INPUTS (NUM_CHANNELS),
    .LATENCY    (MULTIPLIER_LATENCY )
)
u_corr_vector_mult(
    .clk   (clk   ),
    .rst   (rst   ),
    .a     (c_vector_mult_in_a     ),
    .b     (c_vector_mult_in_b     ),
    .o     (c_vector_mult_out     ),
    .ready (c_vector_mult_alu_ready ),
    .valid (c_vector_mult_valid )
);

/* ----------------------------------------------------------- */
//                     TRANSLATOR
/* ----------------------------------------------------------- */

logic t_start, t_finished;

logic [R_ROW_ADDR_WIDTH-1:0] t_x_write_row_addr;
logic [R_COL_ADDR_WIDTH-1:0] t_x_write_col_addr;
logic [WIDTH-1:0] t_x_write_data;
logic t_x_write_ready;

logic [R_ROW_ADDR_WIDTH-1:0] t_a_row_addr;
logic t_a_row_addr_ready, t_a_row_valid;
logic [R_ROW_SIZE-1:0] t_a_row_out;

correlation_matrix_translator 
#(
    .N               (NUM_CHANNELS ),
    .NUM_SAMPLES     (NUM_PIXELS     ),
    .WIDTH           (WIDTH           ),
    .DIVIDER_LATENCY (DIVIDER_LATENCY ),
    .MEMORY_LATENCY  (MEMORY_LATENCY  )
)
u_correlation_matrix_translator(
    .clk              (clk              ),
    .rst              (rst              ),
    .start            (t_start            ),
    .finished         (t_finished         ),
    .a_row_addr       (t_a_row_addr       ),
    .a_row_addr_ready (t_a_row_addr_ready ),
    .a_row_valid      (t_a_row_valid      ),
    .a_row_out        (t_a_row_out        ),
    .x_write_row_addr (t_x_write_row_addr ),
    .x_write_col_addr (t_x_write_col_addr ),
    .x_write_data     (t_x_write_data     ),
    .x_write_ready    (t_x_write_ready    )
);

/* ----------------------------------------------------------- */
//                     LDL 1
/* ----------------------------------------------------------- */

logic l1_start, l1_finished;

logic l1_dot_product_valid, l1_dot_product_mode, l1_vector_mult_valid, l1_vector_mult_alu_ready;
logic [R_ROW_SIZE-1:0] l1_dot_product_a, l1_dot_product_b, l1_vector_mult_in_a, l1_vector_mult_in_b, l1_vector_mult_out;
logic [WIDTH-1:0] l1_dot_product_c, l1_dot_product_out;
logic [NUM_CHANNELS-1:0] l1_dot_product_enable;

logic [R_ROW_ADDR_WIDTH-1:0] l1_a_write_row_addr;
logic [R_COL_ADDR_WIDTH-1:0] l1_a_write_col_addr;
logic [WIDTH-1:0] l1_a_write_data;
logic l1_a_write_ready;

logic [T1_COL_ADDR_WIDTH-1:0] l1_x_col_addr;
logic l1_x_col_addr_ready;
logic l1_x_col_valid;
logic [T1_COL_SIZE-1:0] l1_x_col_out;


ldl_solver 
#(
    .N                  (NUM_CHANNELS),
    .M                  (NUM_SIGNATURES),
    .WIDTH              (WIDTH              ),
    .DIVIDER_LATENCY    (DIVIDER_LATENCY    ),
    .MEMORY_LATENCY     (MEMORY_LATENCY     )
)
u_ldl1_solver(
    .clk                   (clk                   ),
    .rst                   (rst                   ),
    .start                 (l1_start                 ),
    .finished              (l1_finished              ),
    .dot_product_a         (l1_dot_product_a         ),
    .dot_product_b         (l1_dot_product_b         ),
    .dot_product_c         (l1_dot_product_c         ),
    .dot_product_out       (l1_dot_product_out       ),
    .dot_product_enable    (l1_dot_product_enable    ),
    .dot_product_valid     (l1_dot_product_valid     ),
    .dot_product_mode      (l1_dot_product_mode      ),
    .vector_mult_alu_ready (l1_vector_mult_alu_ready ),
    .vector_mult_in_a      (l1_vector_mult_in_a      ),
    .vector_mult_in_b      (l1_vector_mult_in_b      ),
    .vector_mult_out       (l1_vector_mult_out       ),
    .vector_mult_valid     (l1_vector_mult_valid     ),
    .a_row_addr            (r_row_addr            ),
    .a_row_addr_ready      (r_row_addr_ready      ),
    .a_row_valid           (r_row_valid           ),
    .a_row_out             (r_row_out             ),
    .a_col_addr            (r_col_addr            ),
    .a_col_addr_ready      (r_col_addr_ready      ),
    .a_col_valid           (r_col_valid           ),
    .a_col_out             (r_col_out             ),
    .a_write_row_addr      (l1_a_write_row_addr      ),
    .a_write_col_addr      (l1_a_write_col_addr      ),
    .a_write_data          (l1_a_write_data          ),
    .a_write_ready         (l1_a_write_ready         ),
    .b_row_addr            (t_row_addr            ),
    .b_row_addr_ready      (t_row_addr_ready      ),
    .b_row_valid           (t_row_valid           ),
    .b_row_out             (t_row_out             ),
    .x_col_addr            (l1_x_col_addr            ),
    .x_col_addr_ready      (l1_x_col_addr_ready      ),
    .x_col_valid           (l1_x_col_valid           ),
    .x_col_out             (l1_x_col_out             ),
    .x_write_row_addr      (t1_write_row_addr      ),
    .x_write_col_addr      (t1_write_col_addr      ),
    .x_write_data          (t1_write_data          ),
    .x_write_ready         (t1_write_ready         )
);

/* ----------------------------------------------------------- */
//                     MULT 1
/* ----------------------------------------------------------- */

logic m1_start, m1_finished;

logic m1_dot_product_valid, m1_dot_product_mode, m1_vector_mult_valid, m1_vector_mult_alu_ready;
logic [WIDTH * NUM_CHANNELS-1:0] m1_dot_product_a, m1_dot_product_b, m1_vector_mult_in_a, m1_vector_mult_in_b, m1_vector_mult_out;
logic [WIDTH-1:0] m1_dot_product_c, m1_dot_product_out;
logic [NUM_CHANNELS-1:0] m1_dot_product_enable;

logic [T1_COL_ADDR_WIDTH-1:0] m1_b_col_addr;
logic m1_b_col_addr_ready;
logic m1_b_col_valid;
logic [T1_COL_SIZE-1:0] m1_b_col_out;

logic [T2_ROW_ADDR_WIDTH-1:0] m1_x_write_row_addr;
logic [T2_COL_ADDR_WIDTH-1:0] m1_x_write_col_addr;
logic [WIDTH-1:0] m1_x_write_data;
logic m1_x_write_ready;

matrix_multiplier 
#(
    .N                (NUM_SIGNATURES),
    .P                (NUM_CHANNELS),
    .M                (NUM_SIGNATURES),
    .WIDTH            (WIDTH)
)
u_matrix_multiplier1 (
    .rst                   (rst                   ),
    .clk                   (clk                   ),
    .start                 (m1_start                 ),
    .finished              (m1_finished              ),
    .dot_product_a         (m1_dot_product_a         ),
    .dot_product_b         (m1_dot_product_b         ),
    .dot_product_c         (m1_dot_product_c         ),
    .dot_product_out       (m1_dot_product_out       ),
    .dot_product_enable    (m1_dot_product_enable    ),
    .dot_product_valid     (m1_dot_product_valid     ),
    .dot_product_mode      (m1_dot_product_mode      ),
    .vector_mult_alu_ready (m1_vector_mult_alu_ready ),
    .a_row_addr            (t_col_addr            ),
    .a_row_addr_ready      (t_col_addr_ready      ),
    .a_row_valid           (t_col_valid           ),
    .a_row_out             (t_col_out             ),
    .b_col_addr            (m1_b_col_addr            ),
    .b_col_addr_ready      (m1_b_col_addr_ready      ),
    .b_col_valid           (m1_b_col_valid           ),
    .b_col_out             (m1_b_col_out             ),
    .x_write_row_addr      (m1_x_write_row_addr      ),
    .x_write_col_addr      (m1_x_write_col_addr      ),
    .x_write_data          (m1_x_write_data          ),
    .x_write_ready         (m1_x_write_ready         )
);

/* ----------------------------------------------------------- */
//                     LDL 2
/* ----------------------------------------------------------- */

logic l2_start, l2_finished;

logic l2_dot_product_valid, l2_dot_product_mode, l2_vector_mult_valid, l2_vector_mult_alu_ready;
logic [WIDTH * NUM_SIGNATURES-1:0] l2_dot_product_a, l2_dot_product_b, l2_vector_mult_in_a, l2_vector_mult_in_b, l2_vector_mult_out;
logic [WIDTH-1:0] l2_dot_product_c, l2_dot_product_out;
logic [NUM_SIGNATURES-1:0] l2_dot_product_enable;

logic [T2_ROW_ADDR_WIDTH-1:0] l2_a_write_row_addr;
logic [T2_COL_ADDR_WIDTH-1:0] l2_a_write_col_addr;
logic [WIDTH-1:0] l2_a_write_data;
logic l2_a_write_ready;

logic [T3_COL_ADDR_WIDTH-1:0] l2_x_col_addr;
logic l2_x_col_addr_ready;
logic l2_x_col_valid;
logic [T3_COL_SIZE-1:0] l2_x_col_out;

ldl_solver 
#(
    .N                  (NUM_SIGNATURES),
    .M                  (NUM_OUTPUT_CHANNELS),
    .WIDTH              (WIDTH              ),
    .DIVIDER_LATENCY    (DIVIDER_LATENCY    ),
    .MEMORY_LATENCY     (MEMORY_LATENCY     )
)
u_ldl2_solver(
    .clk                   (clk                   ),
    .rst                   (rst                   ),
    .start                 (l2_start                 ),
    .finished              (l2_finished              ),
    .dot_product_a         (l2_dot_product_a         ),
    .dot_product_b         (l2_dot_product_b         ),
    .dot_product_c         (l2_dot_product_c         ),
    .dot_product_out       (l2_dot_product_out       ),
    .dot_product_enable    (l2_dot_product_enable    ),
    .dot_product_valid     (l2_dot_product_valid     ),
    .dot_product_mode      (l2_dot_product_mode      ),
    .vector_mult_alu_ready (l2_vector_mult_alu_ready ),
    .vector_mult_in_a      (l2_vector_mult_in_a      ),
    .vector_mult_in_b      (l2_vector_mult_in_b      ),
    .vector_mult_out       (l2_vector_mult_out       ),
    .vector_mult_valid     (l2_vector_mult_valid     ),
    .a_row_addr            (t2_row_addr            ),
    .a_row_addr_ready      (t2_row_addr_ready      ),
    .a_row_valid           (t2_row_valid           ),
    .a_row_out             (t2_row_out             ),
    .a_col_addr            (t2_col_addr            ),
    .a_col_addr_ready      (t2_col_addr_ready      ),
    .a_col_valid           (t2_col_valid           ),
    .a_col_out             (t2_col_out             ),
    .a_write_row_addr      (l2_a_write_row_addr      ),
    .a_write_col_addr      (l2_a_write_col_addr      ),
    .a_write_data          (l2_a_write_data          ),
    .a_write_ready         (l2_a_write_ready         ),
    .b_row_addr            (c_row_addr            ),
    .b_row_addr_ready      (c_row_addr_ready      ),
    .b_row_valid           (c_row_valid           ),
    .b_row_out             (c_row_out             ),
    .x_col_addr            (l2_x_col_addr            ),
    .x_col_addr_ready      (l2_x_col_addr_ready      ),
    .x_col_valid           (l2_x_col_valid           ),
    .x_col_out             (l2_x_col_out             ),
    .x_write_row_addr      (t3_write_row_addr      ),
    .x_write_col_addr      (t3_write_col_addr      ),
    .x_write_data          (t3_write_data          ),
    .x_write_ready         (t3_write_ready         )
);

/* ----------------------------------------------------------- */
//                     MULT 2
/* ----------------------------------------------------------- */

logic m2_start, m2_finished;

logic m2_dot_product_valid, m2_dot_product_mode, m2_vector_mult_valid, m2_vector_mult_alu_ready;
logic [WIDTH * NUM_SIGNATURES-1:0] m2_dot_product_a, m2_dot_product_b, m2_vector_mult_in_a, m2_vector_mult_in_b, m2_vector_mult_out;
logic [WIDTH-1:0] m2_dot_product_c, m2_dot_product_out;
logic [NUM_SIGNATURES-1:0] m2_dot_product_enable;

logic [T3_COL_ADDR_WIDTH-1:0] m2_b_col_addr;
logic m2_b_col_addr_ready;
logic m2_b_col_valid;
logic [T3_COL_SIZE-1:0] m2_b_col_out;

matrix_multiplier 
#(
    .N                (NUM_CHANNELS),
    .P                (NUM_SIGNATURES),
    .M                (NUM_OUTPUT_CHANNELS),
    .WIDTH            (WIDTH)   
)
u_matrix_multiplier2(
    .rst                   (rst                   ),
    .clk                   (clk                   ),
    .start                 (m2_start                 ),
    .finished              (m2_finished              ),
    .dot_product_a         (m2_dot_product_a         ),
    .dot_product_b         (m2_dot_product_b         ),
    .dot_product_c         (m2_dot_product_c         ),
    .dot_product_out       (m2_dot_product_out       ),
    .dot_product_enable    (m2_dot_product_enable    ),
    .dot_product_valid     (m2_dot_product_valid     ),
    .dot_product_mode      (m2_dot_product_mode      ),
    .vector_mult_alu_ready (m2_vector_mult_alu_ready ),
    .a_row_addr            (t1_row_addr            ),
    .a_row_addr_ready      (t1_row_addr_ready      ),
    .a_row_valid           (t1_row_valid           ),
    .a_row_out             (t1_row_out             ),
    .b_col_addr            (m2_b_col_addr            ),
    .b_col_addr_ready      (m2_b_col_addr_ready      ),
    .b_col_valid           (m2_b_col_valid           ),
    .b_col_out             (m2_b_col_out             ),
    .x_write_row_addr      (w_write_row_addr      ),
    .x_write_col_addr      (w_write_col_addr      ),
    .x_write_data          (w_write_data          ),
    .x_write_ready         (w_write_ready         )
);

/* ----------------------------------------------------------- */
//                 NUM_SIGNATURES MULT2 DP
/* ----------------------------------------------------------- */

logic m2_vector_mult_in_ready, m2_vector_mult_out_valid;


fp_vector_mult 
#(
    .WIDTH      (WIDTH      ),
    .NUM_INPUTS (NUM_SIGNATURES ),
    .LATENCY    (MULTIPLIER_LATENCY    )
)
u_fp_vector_mult(
    .clk   (clk   ),
    .rst   (rst   ),
    .a     (m2_vector_mult_in_a     ),
    .b     (m2_vector_mult_in_b    ),
    .o     (m2_vector_mult_out     ),
    .ready (m2_vector_mult_in_ready ),
    .valid (m2_vector_mult_out_valid )
);


fp_dot_product 
#(
    .WIDTH                                  (WIDTH         ),
    .NUM_INPUTS                             (NUM_SIGNATURES),
    .MULT_LATENCY                           (MULTIPLIER_LATENCY),
    .SUM_LATENCY                            (ADDER_LATENCY                          ),
    .PIPELINE_ADDER_TREE                    (PIPELINE_ADDER_TREE                    ),
    .PIPELINE_BETWEEN_MULT_AND_ADDER_TREE   (PIPELINE_BETWEEN_MULT_AND_ADDER_TREE   ),
    .USE_RESET_FOR_REGISTERS_INSTEAD_OF_MUX (USE_RESET_FOR_REGISTERS_INSTEAD_OF_MUX )
)
u_fp_dot_product(
    .clk                   (clk             ),
    .rst                   (rst             ),
    .a                     (m2_dot_product_a),
    .b                     (m2_dot_product_b),
    .c                     (m2_dot_product_c),
    .out                   (m2_dot_product_out    ),
    .enable                (m2_dot_product_enable ),
    .ready                 (m2_vector_mult_alu_ready),
    .valid                 (m2_dot_product_valid  ),
    .vector_mult_in_a      (m2_vector_mult_in_a      ),
    .vector_mult_in_b      (m2_vector_mult_in_b      ),
    .vector_mult_out       (m2_vector_mult_out       ),
    .vector_mult_in_ready  (m2_vector_mult_in_ready  ),
    .vector_mult_out_valid (m2_vector_mult_out_valid )
);


/* ----------------------------------------------------------- */
//                     INPUT MULTIPLEXERS
/* ----------------------------------------------------------- */

typedef enum {corr, trans, ldl1, ldl2, mult1, mult2} module_running_t;
module_running_t module_running;

// NC ALU

typedef enum { nc_alu_ldl1, nc_alu_mult1, nc_alu_disabled } nc_alu_state_t;
nc_alu_state_t nc_alu_state;

always_comb begin
    unique case (module_running)
        ldl1:
            nc_alu_state = nc_alu_ldl1;
        corr:
            nc_alu_state = nc_alu_disabled;
        mult1:
            nc_alu_state = nc_alu_mult1; 
        default: 
            nc_alu_state = nc_alu_disabled;
    endcase
end

always_comb begin

    nc_vector_mult_in_a = l1_vector_mult_in_a;
    nc_vector_mult_in_b = l1_vector_mult_in_b; 

    if(nc_alu_state == nc_alu_ldl1) begin
        nc_dot_product_a = l1_dot_product_a;
        nc_dot_product_b = l1_dot_product_b;
        nc_dot_product_c = l1_dot_product_c;

        nc_dot_product_enable = l1_dot_product_enable;
        nc_dot_product_mode = l1_dot_product_mode;
    end else begin
        //nc_alu_mult1
        nc_dot_product_a = m1_dot_product_a;
        nc_dot_product_b = m1_dot_product_b;
        nc_dot_product_c = m1_dot_product_c;
            
        nc_dot_product_enable = m1_dot_product_enable;
        nc_dot_product_mode = m1_dot_product_mode;
    end

    unique case (nc_alu_state)
        nc_alu_ldl1: begin
            nc_vector_mult_alu_ready = l1_vector_mult_alu_ready;
        end
        nc_alu_mult1: begin
            nc_vector_mult_alu_ready = m1_vector_mult_alu_ready;
        end
        nc_alu_disabled: begin
            nc_vector_mult_alu_ready = 1'b0;
        end
    endcase
end

// NS ALU

// typedef enum { ns_alu_mult2, ns_alu_ldl2, ns_alu_disabled } ns_alu_state_t;
// ns_alu_state_t ns_alu_state;

// always_comb begin
//     unique case (module_running)
//         ldl2:
//             ns_alu_state = ns_alu_ldl2;
//         mult2:
//             ns_alu_state = ns_alu_mult2; 
//         default: 
//             ns_alu_state = ns_alu_disabled;
//     endcase
// end

assign  ns_vector_mult_in_a = l2_vector_mult_in_a;
assign  ns_vector_mult_in_b = l2_vector_mult_in_b; 

assign  ns_dot_product_a = l2_dot_product_a;
assign  ns_dot_product_b = l2_dot_product_b;
assign  ns_dot_product_c = l2_dot_product_c;

assign  ns_dot_product_enable = l2_dot_product_enable;
assign  ns_vector_mult_alu_ready = l2_vector_mult_alu_ready;
assign  ns_dot_product_mode = l2_dot_product_mode;

// always_comb begin

//     ns_vector_mult_in_a = l2_vector_mult_in_a;
//     ns_vector_mult_in_b = l2_vector_mult_in_b; 

//     unique case (ns_alu_state)
//         ns_alu_ldl2: begin
//             ns_dot_product_a = l2_dot_product_a;
//             ns_dot_product_b = l2_dot_product_b;
//             ns_dot_product_c = l2_dot_product_c;

//             ns_dot_product_enable = l2_dot_product_enable;
//             ns_vector_mult_alu_ready = l2_vector_mult_alu_ready;
//             ns_dot_product_mode = l2_dot_product_mode;
//         end
//         ns_alu_mult2: begin
//             ns_dot_product_a = m2_dot_product_a;
//             ns_dot_product_b = m2_dot_product_b;
//             ns_dot_product_c = m2_dot_product_c;
            
//             ns_dot_product_enable = m2_dot_product_enable;
//             ns_vector_mult_alu_ready = m2_vector_mult_alu_ready;
//             ns_dot_product_mode = m2_dot_product_mode;
//         end
//         ns_alu_disabled: begin
//             ns_dot_product_a = 'x;
//             ns_dot_product_b = 'x;
//             ns_dot_product_c = 'x;

//             ns_dot_product_enable = 'x;
//             ns_vector_mult_alu_ready = 1'b0;
//             ns_dot_product_mode = 'x;
//         end
//     endcase
// end

// Row matrix R

typedef enum { mrr_trans, mrr_corr, mrr_disabled } matrix_rr_state_t;

matrix_rr_state_t matrix_rr_state;

always_comb begin
    unique case (module_running)
        trans:
            matrix_rr_state = mrr_trans;
        corr:
            matrix_rr_state = mrr_corr;
        default: 
            matrix_rr_state = mrr_disabled;
    endcase
end


always_comb begin

    if (matrix_rr_state == mrr_trans) begin
        rr_row_addr = t_a_row_addr;
    end else begin
        //mrr_corr
        rr_row_addr = c_r_row_addr;
    end

    unique case (matrix_rr_state)
        mrr_trans: begin
            rr_row_addr_ready = t_a_row_addr_ready;
        end 
        mrr_corr: begin
            rr_row_addr_ready = c_r_row_addr_ready;
        end
        mrr_disabled: begin
            rr_row_addr_ready = 1'b0;
        end
    endcase
end

// Matrix R

typedef enum { mr_ldl1, mr_trans, mr_disabled } matrix_r_state_t;

matrix_r_state_t matrix_r_state;

always_comb begin
    unique case (module_running)
        trans:
            matrix_r_state = mr_trans;
        ldl1:
            matrix_r_state = mr_ldl1;
        default: 
            matrix_r_state = mr_disabled;
    endcase
end


always_comb begin

    if (matrix_r_state == mr_trans) begin
        r_write_row_addr = t_x_write_row_addr;
        r_write_col_addr = t_x_write_col_addr;
        r_write_data = t_x_write_data;
    end else begin
        //mr_ldl1
        r_write_row_addr = l1_a_write_row_addr;
        r_write_col_addr = l1_a_write_col_addr;
        r_write_data = l1_a_write_data;
    end

    unique case (matrix_r_state)
        mr_trans: begin
            r_write_ready = t_x_write_ready;
        end 
        mr_ldl1: begin            
            r_write_ready = l1_a_write_ready;
        end
        mr_disabled: begin
            r_write_ready = 1'b0;
        end
    endcase
end

// Matrix T1

typedef enum { mt1_ldl1, mt1_mult1, mt1_disabled } matrix_t1_state_t;

matrix_t1_state_t matrix_t1_state;

always_comb begin
    unique case (module_running)
        mult1:
            matrix_t1_state = mt1_mult1;
        ldl1:
            matrix_t1_state = mt1_ldl1;
        default: 
            matrix_t1_state = mt1_disabled;
    endcase
end


always_comb begin

    if (matrix_t1_state == mt1_ldl1) begin
        t1_col_addr = l1_x_col_addr;
    end else begin
        // mt1_mult1
        t1_col_addr = m1_b_col_addr;
    end

    unique case (matrix_t1_state)
        mt1_ldl1: begin
            t1_col_addr_ready = l1_x_col_addr_ready;
        end 
        mt1_mult1: begin
            t1_col_addr_ready = m1_b_col_addr_ready;
        end
        mt1_disabled: begin
            t1_col_addr_ready = 1'b0;
        end
    endcase
end


// Matrix T2

typedef enum { mt2_ldl2, mt2_mult1, mt2_disabled } matrix_t2_state_t;

matrix_t2_state_t matrix_t2_state;

always_comb begin
    unique case (module_running)
        mult1:
            matrix_t2_state = mt2_mult1;
        ldl2:
            matrix_t2_state = mt2_ldl2;
        default: 
            matrix_t2_state = mt2_disabled;
    endcase
end

always_comb begin
    
    if (matrix_t2_state == mt2_mult1) begin
        t2_write_row_addr = m1_x_write_row_addr;
        t2_write_col_addr = m1_x_write_col_addr;
        t2_write_data = m1_x_write_data;        
    end else begin
        // mt2_ldl2
        t2_write_row_addr = l2_a_write_row_addr;
        t2_write_col_addr = l2_a_write_col_addr;
        t2_write_data = l2_a_write_data;
    end
    
    unique case (matrix_t2_state)
        mt2_mult1: begin
            t2_write_ready = m1_x_write_ready;
        end 
        mt2_ldl2: begin
            t2_write_ready = l2_a_write_ready;
        end
        mt2_disabled: begin
            t2_write_ready = 1'b0;
        end
    endcase
end


// Matrix T3

typedef enum { mt3_ldl2, mt3_mult2, mt3_disabled } matrix_t3_state_t;

matrix_t3_state_t matrix_t3_state;

always_comb begin
    unique case (module_running)
        mult2:
            matrix_t3_state = mt3_mult2;
        ldl2:
            matrix_t3_state = mt3_ldl2;
        default: 
            matrix_t3_state = mt3_disabled;
    endcase
end


always_comb begin

    if(matrix_t3_state == mt3_ldl2) begin
        t3_col_addr = l2_x_col_addr;
    end else begin
        //mt3_mult2
        t3_col_addr = m2_b_col_addr;
    end

    unique case (matrix_t3_state)
        mt3_ldl2: begin
            t3_col_addr_ready = l2_x_col_addr_ready;
        end 
        mt3_mult2: begin
            t3_col_addr_ready = m2_b_col_addr_ready;
        end
        mt3_disabled: begin
            t3_col_addr_ready = 1'b0;
        end
    endcase
end

/* ----------------------------------------------------------- */
//                HARDWARE WIRE CONNECTIONS
/* ----------------------------------------------------------- */

//////////////////////////////
//          LDL1
//////////////////////////////

assign l1_x_col_out = t1_col_out;
assign l1_x_col_valid = t1_col_valid;

assign l1_dot_product_out = nc_dot_product_out;
assign l1_dot_product_valid = nc_dot_product_valid;

assign l1_vector_mult_out = nc_vector_mult_out;
assign l1_vector_mult_valid = nc_vector_mult_valid;

//////////////////////////////
//          LDL2
//////////////////////////////

assign l2_x_col_out = t3_col_out;
assign l2_x_col_valid = t3_col_valid;

assign l2_dot_product_out = ns_dot_product_out;
assign l2_dot_product_valid = ns_dot_product_valid;

assign l2_vector_mult_out = ns_vector_mult_out;
assign l2_vector_mult_valid = ns_vector_mult_valid;

//////////////////////////////
//          MULT1
//////////////////////////////

assign m1_b_col_out = t1_col_out;
assign m1_b_col_valid = t1_col_valid;

assign m1_dot_product_out = nc_dot_product_out;
assign m1_dot_product_valid = nc_dot_product_valid;

//////////////////////////////
//          MULT3
//////////////////////////////

assign m2_b_col_out = t3_col_out;
assign m2_b_col_valid = t3_col_valid;

// assign m2_dot_product_out = ns_dot_product_out;
// assign m2_dot_product_valid = ns_dot_product_valid;

//////////////////////////////
//          CORR
//////////////////////////////

// assign c_vector_mult_out = nc_vector_mult_out;
// assign c_vector_mult_valid = nc_vector_mult_valid;

assign c_r_row_out = rr_row_out;
assign c_r_row_valid = rr_row_valid;

//////////////////////////////
//          TRANSLATOR
//////////////////////////////

assign t_a_row_out = rr_row_out;
assign t_a_row_valid = rr_row_valid;

/* ----------------------------------------------------------- */
//                      STATE MACHINE
/* ----------------------------------------------------------- */

logic start;
assign start = ds_valid;

typedef enum { s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12 } state_t;
state_t state_reg, state_next;
  
always_ff @( posedge clk ) begin
    if (rst) begin
        state_reg <= s0;
    end else begin
        state_reg <= state_next;
    end
end

//next_state
always_comb begin
    unique case (state_reg)
       s0:
        if(start)
            state_next = s1;
        else
            state_next = s0;
    s1:
        if(corr_finished)
            state_next = s2;
        else
            state_next = s1;
    s2:
        state_next = s3;
    s3: 
        if(t_finished)
            state_next = s4;
        else
            state_next = s3;
    s4:
        state_next = s5;
    s5:
        if (l1_finished)
            state_next = s6;
        else
            state_next = s5;
    s6:
        state_next = s7;
    s7:
        if(m1_finished)
            state_next = s8;
        else
            state_next = s7;
    s8:
        state_next = s9;
    s9:
        if(l2_finished)
            state_next = s10;
        else
            state_next = s9;
    s10:
        state_next = s11;
    s11:
        if(m2_finished)
            state_next = s12;
        else
            state_next = s11;
    s12:
        state_next = s0;
    endcase
end

// Outputs
always_comb begin
    finished = 0;
    module_running = corr;
    t_start = 1'b0;
    l1_start = 1'b0;
    m1_start = 1'b0;
    l2_start = 1'b0;
    m2_start = 1'b0;

    unique case (state_reg)
    s0: begin
        finished = 0;
        module_running = corr;
    end
    s1: begin
        module_running = corr;
    end
    s2: begin
        module_running = trans;
        t_start = 1'b1;
    end
    s3: begin
        module_running = trans;
    end
    s4: begin
        module_running = ldl1;
        l1_start = 1'b1;
    end
    s5: begin
        module_running = ldl1;
    end
    s6: begin
        module_running = mult1;
        m1_start = 1'b1;
    end
    s7: begin
        module_running = mult1;
    end
    s8: begin
        module_running = ldl2;
        l2_start = 1'b1;
    end
    s9: begin
        module_running = ldl2;
    end
    s10: begin
        module_running = mult2;
        m2_start = 1'b1; 
    end
    s11: begin
        module_running = mult2;
    end
    s12: begin
        finished = 1'b1;
        module_running = corr;
    end
    endcase
end
endmodule