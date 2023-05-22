module matrix_multiplier #(
 /* 
        Sizes N, P, M such that

        A is a matrix [n, p]
        B is a matrix [p, m]
        X is a matrix [n, m]
     */
    parameter N = 4,
    parameter P = 5, 
    parameter M = 3,

    parameter WIDTH = 32, /* Size in bits of each scalar of the matrix */

    // Defining indices sizes
    parameter I_REGISTER_WIDTH = $clog2(N),
    parameter J_REGISTER_WIDTH = $clog2(M),

    // Defining matrix parameters
    localparam A_NUM_ROWS = N,
    localparam A_NUM_COLS = P,

    localparam A_ROW_ADDR_WIDTH = $clog2(A_NUM_ROWS),
    localparam A_COL_ADDR_WIDTH = $clog2(A_NUM_COLS),
    localparam A_ROW_SIZE = A_NUM_COLS * WIDTH,
    localparam A_COL_SIZE = A_NUM_ROWS * WIDTH,

    localparam B_NUM_ROWS = P,
    localparam B_NUM_COLS = M,

    localparam B_ROW_ADDR_WIDTH = $clog2(B_NUM_ROWS),
    localparam B_COL_ADDR_WIDTH = $clog2(B_NUM_COLS),
    localparam B_ROW_SIZE = B_NUM_COLS * WIDTH,
    localparam B_COL_SIZE = B_NUM_ROWS * WIDTH,

    localparam X_NUM_ROWS = N,
    localparam X_NUM_COLS = M,

    localparam X_ROW_ADDR_WIDTH = $clog2(X_NUM_ROWS),
    localparam X_COL_ADDR_WIDTH = $clog2(X_NUM_COLS),
    localparam X_ROW_SIZE = X_NUM_COLS * WIDTH,
    localparam X_COL_SIZE = X_NUM_ROWS * WIDTH
) (
    input logic rst,
    input logic clk,

    input logic start,
    output logic finished,

    /* ----------------------------------------------------------- */
    //                  FP VECTOR MULT ALU PORTS
    /* ----------------------------------------------------------- */

    // This module does NOT instantiate a fp vector multiplication ALU, it gets ports to interact 
    // with an already instantiated fp vector multiplication ALU

    output logic [WIDTH*P-1:0] dot_product_a,
    output logic [WIDTH*P-1:0] dot_product_b,
    output logic [WIDTH-1:0] dot_product_c,

    // dot_product_out = a*b+c
    input logic [WIDTH-1:0] dot_product_out,

    // We don't have to sum all the entries of the vectors, we have a logic per element that tells us
    // if we need to take into account that element for the dot product
    output logic [P-1:0] dot_product_enable,

    input logic dot_product_valid,

    // If dot_product_mode = 1, the ALU will be configured to act as the dot product,
    // else, it will act as a vector multiplier
    output logic dot_product_mode,
    output logic vector_mult_alu_ready,

    // We don't need the vector elementwise multiplication ports
    // output logic [WIDTH*N-1:0] vector_mult_in_a,
    // output logic [WIDTH*N-1:0] vector_mult_in_b, 
    // input logic [WIDTH*N-1:0] vector_mult_out,
    // input logic vector_mult_valid,

    /* ----------------------------------------------------------- */
    //                  MATRIX A PORTS
    /* ----------------------------------------------------------- */

    // This module does NOT instantiate a matrix memory, it gets ports to interact 
    // with an already instantiated matrix

    output logic [A_ROW_ADDR_WIDTH-1:0] a_row_addr,
    output logic a_row_addr_ready,
    input logic a_row_valid,
    input logic [A_ROW_SIZE-1:0] a_row_out,

    // output logic [A_COL_ADDR_WIDTH-1:0] a_col_addr,
    // output logic a_col_addr_ready,
    // input logic a_col_valid,
    // input logic [A_COL_SIZE-1:0] a_col_out,

    // Element writing port
    // output logic [A_ROW_ADDR_WIDTH-1:0] a_write_row_addr,
    // output logic [A_COL_ADDR_WIDTH-1:0] a_write_col_addr,
    // output logic [WIDTH-1:0] a_write_data,
    // output logic a_write_ready,

    /* ----------------------------------------------------------- */
    //                  MATRIX B PORTS
    /* ----------------------------------------------------------- */

    // This module does NOT instantiate a matrix memory, it gets ports to interact 
    // with an already instantiated matrix

    // output logic [B_ROW_ADDR_WIDTH-1:0] b_row_addr,
    // output logic b_row_addr_ready,
    // input logic b_row_valid,
    // input logic [B_ROW_SIZE-1:0] b_row_out,

    output logic [B_COL_ADDR_WIDTH-1:0] b_col_addr,
    output logic b_col_addr_ready,
    input logic b_col_valid,
    input logic [B_COL_SIZE-1:0] b_col_out,

    // Element writing port
    // output logic [ROW_ADDR_WIDTH-1:0] write_row_addr,
    // output logic [COL_ADDR_WIDTH-1:0] write_col_addr,
    // output logic [WIDTH-1:0] write_data,
    // output logic write_ready,

        /* ----------------------------------------------------------- */
    //                  MATRIX X PORTS
    /* ----------------------------------------------------------- */

    // This module does NOT instantiate a matrix memory, it gets ports to interact 
    // with an already instantiated matrix

    // output logic [X_COL_ADDR_WIDTH-1:0] x_col_addr,
    // output logic x_col_addr_ready,
    // input logic x_col_valid,
    // input logic [X_COL_SIZE-1:0] x_col_out,

    // Element writing port
    output logic [X_ROW_ADDR_WIDTH-1:0] x_write_row_addr,
    output logic [X_COL_ADDR_WIDTH-1:0] x_write_col_addr,
    output logic [WIDTH-1:0] x_write_data,
    output logic x_write_ready

    /* The module does not need to read matrices row by row */

    // output logic [ROW_ADDR_WIDTH-1:0] row_addr,
    // output logic row_addr_ready,
    // input logic row_valid,
    // input logic [ROW_SIZE-1:0] row_out,
);

/* ----------------------------------------------------------- */
//                  REGISTERS AND COUNTERS
/* ----------------------------------------------------------- */

// I counter

logic i_rst_cnt, i_up, i_max;
logic [I_REGISTER_WIDTH-1:0] i_out;

counter_mod 
#(
    .MOD   (X_NUM_ROWS)
)
i_cnt (
    .rst         (rst         ),
    .clk         (clk         ),
    .reset_count (i_rst_cnt),
    .up          (i_up          ),
    .max         (i_max         ),
    .out         (i_out         )
);

// I write counter

logic i_w_rst_cnt, i_w_up, i_w_max;
logic [I_REGISTER_WIDTH-1:0] i_w_out;

counter_mod 
#(
    .MOD   (X_NUM_ROWS)
)
i_w_cnt (
    .rst         (rst         ),
    .clk         (clk         ),
    .reset_count (i_w_rst_cnt),
    .up          (i_w_up          ),
    .max         (i_w_max         ),
    .out         (i_w_out         )
);

// J counter

logic j_rst_cnt, j_up, j_max;
logic [J_REGISTER_WIDTH-1:0] j_out;

counter_mod 
#(
    .MOD   (X_NUM_COLS)
)
j_cnt (
    .rst         (rst         ),
    .clk         (clk         ),
    .reset_count (j_rst_cnt),
    .up          (j_up          ),
    .max         (j_max         ),
    .out         (j_out         )
);

// I write counter

logic j_w_rst_cnt, j_w_up, j_w_max;
logic [J_REGISTER_WIDTH-1:0] j_w_out;

counter_mod 
#(
    .MOD   (X_NUM_COLS)
)
j_w_cnt (
    .rst         (rst         ),
    .clk         (clk         ),
    .reset_count (j_w_rst_cnt),
    .up          (j_w_up          ),
    .max         (j_w_max         ),
    .out         (j_w_out         )
);

/* ----------------------------------------------------------- */
//                  DELAY REGISTERS
/* ----------------------------------------------------------- */

logic[WIDTH-1:0] data_delay_in, data_delay_out;

register_delay_no_rst 
#(
    .REG_WIDTH    (WIDTH),
    .DELAY_CYCLES (1)
)
u_data_register_delay(
    .clk (clk ),
    .in  (data_delay_in  ),
    .out (data_delay_out )
);

logic valid_delay_in, valid_delay_out;

register_delay 
#(
    .REG_WIDTH    (1),
    .DELAY_CYCLES (1)
)
u_valid_register_delay(
    .clk (clk ),
    .rst (rst ),
    .in  (valid_delay_in  ),
    .out (valid_delay_out )
);

/* ----------------------------------------------------------- */
//                HARDWARE WIRE CONNECTIONS
/* ----------------------------------------------------------- */

typedef enum { s0, s1, s2, s3 } state_t;
state_t state_reg, state_next;

// Declare control wires

logic process_item;
logic finished_issuing;
logic finished_writing;

assign i_up = process_item;
assign j_up = i_max;

assign finished_issuing = i_max && j_max;

assign a_row_addr = i_out;
assign a_row_addr_ready = process_item;

assign b_col_addr = j_out;
assign b_col_addr_ready = process_item;

assign dot_product_a = a_row_out;
assign dot_product_b = b_col_out;
assign dot_product_c = '0;
assign dot_product_enable = '1;
assign dot_product_mode = 1'b1;
assign vector_mult_alu_ready = b_col_valid && state_reg != 0;

assign data_delay_in = dot_product_out;
assign valid_delay_in = dot_product_valid && state_reg != 0;

assign i_w_up = valid_delay_out;
assign j_w_up = i_w_max;

assign finished_writing = i_w_max && j_w_max;

assign x_write_row_addr = i_w_out;
assign x_write_col_addr = j_w_out;
assign x_write_ready = valid_delay_out;
assign x_write_data = data_delay_out;

    /* ----------------------------------------------------------- */
    //                  STATE MACHINE
    /* ----------------------------------------------------------- */

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
            if (start == 1'b1)
                state_next = s1;
            else
                state_next = s0;
        s1:
            if (finished_issuing)
                state_next = s2;
            else
                state_next = s1;
        s2:
            if (finished_writing) 
                state_next = s3;
            else
                state_next = s2;
        s3:
            state_next = s0;
        endcase
    end

     //outputs
    always_comb begin
        
        finished = 1'b0;
        process_item = 1'b0;
        i_rst_cnt = 1'b0;
        i_w_rst_cnt = 1'b0;
        j_rst_cnt = 1'b0;
        j_w_rst_cnt = 1'b0;
        
        unique case (state_reg)
        s0: begin
            finished = 1'b0;
            i_rst_cnt = 1'b1;
            i_w_rst_cnt = 1'b1;
            j_rst_cnt = 1'b1;
            j_w_rst_cnt = 1'b1;
        end
        s1: begin
            process_item = 1'b1;
        end
        s2: begin
            // Nothing here
        end
        s3: begin
            finished = 1'b1;
        end
        endcase
    end



endmodule