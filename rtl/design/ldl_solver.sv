module ldl_solver #(
    parameter N = 5,        // N is the size of the symmetric matrix 
    parameter M = 4,        // This module will solve A*X = B, where size(A)=[N, N] and size(X)=size(B)=[N, M]
    parameter WIDTH = 32,
    parameter DIVIDER_LATENCY = 28,
    parameter MEMORY_LATENCY = 2,

    // Defining matrix parameters
    localparam A_NUM_ROWS = N,
    localparam A_NUM_COLS = N,

    localparam A_ROW_ADDR_WIDTH = $clog2(A_NUM_ROWS),
    localparam A_COL_ADDR_WIDTH = $clog2(A_NUM_COLS),
    localparam A_ROW_SIZE = A_NUM_COLS * WIDTH,
    localparam A_COL_SIZE = A_NUM_ROWS * WIDTH,

    localparam B_NUM_ROWS = N,
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
    input logic clk,
    input logic rst,

    input logic start,
    output logic finished,

    /* ----------------------------------------------------------- */
    //                  FP VECTOR MULT ALU PORTS
    /* ----------------------------------------------------------- */

    // This module does NOT instantiate a fp vector multiplication ALU, it gets ports to interact 
    // with an already instantiated fp vector multiplication ALU

    output logic [WIDTH*N-1:0] dot_product_a,
    output logic [WIDTH*N-1:0] dot_product_b,
    output logic [WIDTH-1:0] dot_product_c,

    // dot_product_out = a*b+c
    input logic [WIDTH-1:0] dot_product_out,

    // We don't have to sum all the entries of the vectors, we have a logic per element that tells us
    // if we need to take into account that element for the dot product
    output logic [N-1:0] dot_product_enable,

    input logic dot_product_valid,

    // If dot_product_mode = 1, the ALU will be configured to act as the dot product,
    // else, it will act as a vector multiplier
    output logic dot_product_mode,
    output logic vector_mult_alu_ready,

    output logic [WIDTH*N-1:0] vector_mult_in_a,
    output logic [WIDTH*N-1:0] vector_mult_in_b, 
    input logic [WIDTH*N-1:0] vector_mult_out,
    input logic vector_mult_valid,

    /* ----------------------------------------------------------- */
    //                  MATRIX A PORTS
    /* ----------------------------------------------------------- */

    // This module does NOT instantiate a matrix memory, it gets ports to interact 
    // with an already instantiated matrix

    output logic [A_ROW_ADDR_WIDTH-1:0] a_row_addr,
    output logic a_row_addr_ready,
    input logic a_row_valid,
    input logic [A_ROW_SIZE-1:0] a_row_out,

    output logic [A_COL_ADDR_WIDTH-1:0] a_col_addr,
    output logic a_col_addr_ready,
    input logic a_col_valid,
    input logic [A_COL_SIZE-1:0] a_col_out,

    // Element writing port
    output logic [A_ROW_ADDR_WIDTH-1:0] a_write_row_addr,
    output logic [A_COL_ADDR_WIDTH-1:0] a_write_col_addr,
    output logic [WIDTH-1:0] a_write_data,
    output logic a_write_ready,

       /* ----------------------------------------------------------- */
    //                  MATRIX B PORTS
    /* ----------------------------------------------------------- */

    // This module does NOT instantiate a matrix memory, it gets ports to interact 
    // with an already instantiated matrix

    output logic [B_ROW_ADDR_WIDTH-1:0] b_row_addr,
    output logic b_row_addr_ready,
    input logic b_row_valid,
    input logic [B_ROW_SIZE-1:0] b_row_out,

    /* The module does not need to read matrices column by column nor write to this matrix */

    //output logic [COL_ADDR_WIDTH-1:0] col_addr,
    //output logic col_addr_ready,
    //input logic col_valid,
    //input logic [COL_SIZE-1:0] col_out,

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

    output logic [X_COL_ADDR_WIDTH-1:0] x_col_addr,
    output logic x_col_addr_ready,
    input logic x_col_valid,
    input logic [X_COL_SIZE-1:0] x_col_out,

    // Element writing port
    output logic [X_ROW_ADDR_WIDTH-1:0] x_write_row_addr,
    output logic [X_COL_ADDR_WIDTH-1:0] x_write_col_addr,
    output logic [WIDTH-1:0] x_write_data,
    output logic x_write_ready

    /* The module does not need to read matrices row by row */

    // output logic [ROW_ADDR_WIDTH-1:0] row_addr,
    // output logic row_addr_ready,
    // input logic row_valid,
    // input logic [ROW_SIZE-1:0] row_out
);

/* ----------------------------------------------------------- */
//                      W MATRIX
/* ----------------------------------------------------------- */


localparam W_NUM_ROWS = N;
localparam W_NUM_COLS = M;

localparam W_ROW_ADDR_WIDTH = $clog2(W_NUM_ROWS);
localparam W_COL_ADDR_WIDTH = $clog2(W_NUM_COLS);
localparam W_ROW_SIZE = W_NUM_COLS * WIDTH;
localparam W_COL_SIZE = W_NUM_ROWS * WIDTH; 

logic [W_ROW_ADDR_WIDTH-1:0] w_row_addr;
logic w_row_addr_ready;
logic w_row_valid;
logic [W_ROW_SIZE-1:0] w_row_out;

logic [W_COL_ADDR_WIDTH-1:0] w_col_addr;
logic w_col_addr_ready;
logic w_col_valid;
logic [W_COL_SIZE-1:0] w_col_out;

logic [W_ROW_ADDR_WIDTH-1:0] w_write_row_addr;
logic [W_COL_ADDR_WIDTH-1:0] w_write_col_addr;
logic [WIDTH-1:0] w_write_data;
logic w_write_ready;

matrix 
#(
    .NUM_ROWS          (W_NUM_ROWS),
    .NUM_COLS          (W_NUM_COLS),
    .SCALAR_BITS       (WIDTH),
    .MEMORY_LATENCY (MEMORY_LATENCY)
)
u_matrix_w(
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

/* ----------------------------------------------------------- */
//                     D VECTOR REG
/* ----------------------------------------------------------- */
    
    localparam D_VECTOR_LENGTH = N;
    localparam D_VECTOR_ADDR_SIZE = $clog2(D_VECTOR_LENGTH);

    logic[D_VECTOR_LENGTH*WIDTH-1:0] d_out;

    logic[D_VECTOR_ADDR_SIZE-1:0] d_read_index;
    logic[WIDTH-1:0] d_slice_out;

    logic[D_VECTOR_ADDR_SIZE-1:0] d_write_index;
    logic[WIDTH-1:0] d_slice_in;
    logic d_write_slice;

    vector_reg_no_load
    #(
        .SCALAR_BITS (WIDTH),
        .LENGTH      (D_VECTOR_LENGTH)
    )
    u_vector_reg(
        .clk         (clk         ),
        .out         (d_out         ),
        .read_index  (d_read_index  ),
        .slice_out   (d_slice_out   ),
        .write_index (d_write_index ),
        .slice_in    (d_slice_in    ),
        .write_slice (d_write_slice )
    );

/* ----------------------------------------------------------- */
//                    D VECTOR REG MEMORY
/* ----------------------------------------------------------- */

logic[D_VECTOR_ADDR_SIZE-1:0] d_mem_read_index;
logic[WIDTH-1:0] d_mem_slice_out;

simple_dual_port_mem 
#(
    .DEPTH      (D_VECTOR_LENGTH),
    .DATA_WIDTH (WIDTH ),
    .LATENCY    (MEMORY_LATENCY)
)
u_simple_dual_port_mem(
    .clka  (clk),
    .ena   (1'b1),
    .wea   (d_write_slice),
    .addra (d_write_index),
    .dina  (d_slice_in),

    .clkb  (clk),
    .enb   (1'b1),
    .addrb (d_mem_read_index),
    .doutb (d_mem_slice_out)
);


/* ----------------------------------------------------------- */
//                          DIVIDER
/* ----------------------------------------------------------- */

logic div_start, div_finished;

logic [W_ROW_ADDR_WIDTH-1:0] div_mat_row_addr;
logic div_mat_row_addr_ready;
logic div_mat_row_valid;
logic [W_ROW_SIZE-1:0] div_mat_row_out;

logic [W_COL_ADDR_WIDTH-1:0] div_mat_col_addr;
logic div_mat_col_addr_ready;
logic div_mat_col_valid;
logic [W_COL_SIZE-1:0] div_mat_col_out;

logic [W_ROW_ADDR_WIDTH-1:0] div_mat_write_row_addr;
logic [W_COL_ADDR_WIDTH-1:0] div_mat_write_col_addr;
logic [WIDTH-1:0] div_mat_write_data;
logic div_mat_write_ready;

logic[D_VECTOR_ADDR_SIZE-1:0] div_d_read_index;
logic[WIDTH-1:0] div_d_slice_out;

matrix_divider 
#(
    .NUM_ROWS        (W_NUM_ROWS),
    .NUM_COLS        (W_NUM_COLS)
)
u_matrix_divider(
    .clk                (clk                ),
    .rst                (rst                ),
    .start              (div_start              ),
    .finished           (div_finished           ),
    .mat_row_addr       (div_mat_row_addr       ),
    .mat_row_addr_ready (div_mat_row_addr_ready ),
    .mat_row_valid      (div_mat_row_valid      ),
    .mat_row_out        (div_mat_row_out        ),
    .mat_write_row_addr (div_mat_write_row_addr ),
    .mat_write_col_addr (div_mat_write_col_addr ),
    .mat_write_data     (div_mat_write_data     ),
    .mat_write_ready    (div_mat_write_ready    ),
    .d_read_index       (div_d_read_index       ),
    .d_slice_out        (div_d_slice_out        )
);

/* ----------------------------------------------------------- */
//                      TRI_SOLVER
/* ----------------------------------------------------------- */

logic lower_triangular, t_start, t_finished;

logic [WIDTH*N-1:0] t_dot_product_a;
logic [WIDTH*N-1:0] t_dot_product_b;
logic [WIDTH-1:0] t_dot_product_c;
logic [WIDTH-1:0] t_dot_product_out;
logic [N-1:0] t_dot_product_enable;
logic t_vector_mult_alu_ready;
logic t_dot_product_valid;
logic t_dot_product_mode;


logic [A_ROW_ADDR_WIDTH-1:0] t_a_row_addr;
logic t_a_row_addr_ready;
logic t_a_row_valid;
logic [A_ROW_SIZE-1:0] t_a_row_out;

logic [A_COL_ADDR_WIDTH-1:0] t_a_col_addr;
logic t_a_col_addr_ready;
logic t_a_col_valid;
logic [A_COL_SIZE-1:0] t_a_col_out;

logic [B_ROW_ADDR_WIDTH-1:0] t_b_row_addr;
logic t_b_row_addr_ready;
logic t_b_row_valid;
logic [B_ROW_SIZE-1:0] t_b_row_out;

logic [X_COL_ADDR_WIDTH-1:0] t_x_col_addr;
logic t_x_col_addr_ready;
logic t_x_col_valid;
logic [X_COL_SIZE-1:0] t_x_col_out;

logic [X_ROW_ADDR_WIDTH-1:0] t_x_write_row_addr;
logic [X_COL_ADDR_WIDTH-1:0] t_x_write_col_addr;
logic [WIDTH-1:0] t_x_write_data;
logic t_x_write_ready;

tri_solver 
#(
    .N                 (N    ),
    .M                 (M    ),
    .WIDTH             (WIDTH)
)
u_tri_solver(
    .clk                    (clk                    ),
    .rst                    (rst                    ),
    .start                  (t_start                  ),
    .finished               (t_finished               ),
    .lower_triangular_input (lower_triangular ),
    .dot_product_a          (t_dot_product_a          ),
    .dot_product_b          (t_dot_product_b          ),
    .dot_product_c          (t_dot_product_c          ),
    .dot_product_out        (t_dot_product_out        ),
    .dot_product_enable     (t_dot_product_enable     ),
    .dot_product_valid      (t_dot_product_valid      ),
    .dot_product_mode       (t_dot_product_mode       ),
    .vector_mult_alu_ready  (t_vector_mult_alu_ready  ),
    .a_row_addr             (t_a_row_addr             ),
    .a_row_addr_ready       (t_a_row_addr_ready       ),
    .a_row_valid            (t_a_row_valid            ),
    .a_row_out              (t_a_row_out              ),
    .a_col_addr             (t_a_col_addr             ),
    .a_col_addr_ready       (t_a_col_addr_ready       ),
    .a_col_valid            (t_a_col_valid            ),
    .a_col_out              (t_a_col_out              ),
    .b_row_addr             (t_b_row_addr             ),
    .b_row_addr_ready       (t_b_row_addr_ready       ),
    .b_row_valid            (t_b_row_valid            ),
    .b_row_out              (t_b_row_out              ),
    .x_col_addr             (t_x_col_addr             ),
    .x_col_addr_ready       (t_x_col_addr_ready       ),
    .x_col_valid            (t_x_col_valid            ),
    .x_col_out              (t_x_col_out              ),
    .x_write_row_addr       (t_x_write_row_addr       ),
    .x_write_col_addr       (t_x_write_col_addr       ),
    .x_write_data           (t_x_write_data           ),
    .x_write_ready          (t_x_write_ready          )
);

/* ----------------------------------------------------------- */
//                      LDL_DECOMPOSER
/* ----------------------------------------------------------- */

logic l_start, l_finished;

logic [WIDTH*N-1:0] l_dot_product_a;
logic [WIDTH*N-1:0] l_dot_product_b;
logic [WIDTH-1:0] l_dot_product_c;
logic [WIDTH-1:0] l_dot_product_out;
logic [N-1:0] l_dot_product_enable;
logic [WIDTH*N-1:0] l_vector_mult_in_a;
logic [WIDTH*N-1:0] l_vector_mult_in_b; 
logic [WIDTH*N-1:0] l_vector_mult_out;
logic l_vector_mult_alu_ready;
logic l_dot_product_valid;
logic l_vector_mult_valid;
logic l_dot_product_mode;

logic[A_ROW_SIZE-1:0] l_d_out;
logic[A_ROW_ADDR_WIDTH-1:0] l_d_read_index;
logic[WIDTH-1:0] l_d_slice_out;
logic[A_ROW_ADDR_WIDTH-1:0] l_d_write_index;
logic[WIDTH-1:0] l_d_slice_in;
logic l_d_write_slice;

// Column reading port

logic [A_ROW_ADDR_WIDTH-1:0] l_row_addr;
logic l_row_addr_ready;
logic l_row_valid;
logic [A_ROW_SIZE-1:0] l_row_out;
logic [A_ROW_ADDR_WIDTH-1:0] l_write_row_addr;
logic [A_ROW_ADDR_WIDTH-1:0] l_write_col_addr;
logic [WIDTH-1:0] l_write_data;
logic l_write_ready;

ldl_decomposer 
#(
    .NUM_ROWS             (N),
    .WIDTH                (WIDTH                ),
    .DIVIDER_LATENCY      (DIVIDER_LATENCY      )
)
u_ldl_decomposer(
    .rst                   (rst                   ),
    .clk                   (clk                   ),
    .start                 (l_start                 ),
    .finished              (l_finished              ),
    .row_addr              (l_row_addr              ),
    .row_addr_ready        (l_row_addr_ready        ),
    .row_valid             (l_row_valid             ),
    .row_out               (l_row_out               ),
    .write_row_addr        (l_write_row_addr        ),
    .write_col_addr        (l_write_col_addr        ),
    .write_data            (l_write_data            ),
    .write_ready           (l_write_ready           ),
    .dot_product_a         (l_dot_product_a         ),
    .dot_product_b         (l_dot_product_b         ),
    .dot_product_c         (l_dot_product_c         ),
    .dot_product_out       (l_dot_product_out       ),
    .dot_product_enable    (l_dot_product_enable    ),
    .vector_mult_in_a      (l_vector_mult_in_a      ),
    .vector_mult_in_b      (l_vector_mult_in_b      ),
    .vector_mult_out       (l_vector_mult_out       ),
    .vector_mult_alu_ready (l_vector_mult_alu_ready ),
    .dot_product_valid     (l_dot_product_valid     ),
    .vector_mult_valid     (l_vector_mult_valid     ),
    .dot_product_mode      (l_dot_product_mode      ),
    .d_out                 (l_d_out                 ),
    .d_read_index          (l_d_read_index          ),
    .d_slice_out           (l_d_slice_out           ),
    .d_write_index         (l_d_write_index         ),
    .d_slice_in            (l_d_slice_in            ),
    .d_write_slice         (l_d_write_slice         )
);

/* ----------------------------------------------------------- */
//                HARDWARE WIRE CONNECTIONS
/* ----------------------------------------------------------- */

//////////////////////////////
// LDL_decomposer
//////////////////////////////

assign l_row_valid = a_row_valid;
assign l_row_out = a_row_out;

assign l_d_out = d_out;
assign l_d_slice_out = d_slice_out;

assign l_dot_product_out = dot_product_out;
assign l_dot_product_valid = dot_product_valid;

assign l_vector_mult_out = vector_mult_out;
assign l_vector_mult_valid = vector_mult_valid;

//////////////////////////////
// Divider
//////////////////////////////

assign div_mat_row_valid = w_row_valid;
assign div_mat_row_out = w_row_out;

assign d_mem_read_index = div_d_read_index;
assign div_d_slice_out = d_mem_slice_out;

//////////////////////////////
// Tri_solver
//////////////////////////////

assign t_a_row_valid = a_row_valid;
assign t_a_row_out = a_row_out;

assign t_a_col_valid = a_col_valid;
assign t_a_col_out = a_col_out;

// tri_solve_a_x_w = 1 if solving A * X = W
// tri_solve_a_x_w = 1 if solving A * W = B
logic tri_solve_a_x_w;

assign tri_solve_a_x_w = !lower_triangular;

assign t_b_row_valid = tri_solve_a_x_w ? w_row_valid : b_row_valid;
assign t_b_row_out = tri_solve_a_x_w ? w_row_out : b_row_out;

assign t_x_col_valid = tri_solve_a_x_w ? x_col_valid : w_col_valid;
assign t_x_col_out = tri_solve_a_x_w ? x_col_out : w_col_out;

assign t_dot_product_out = dot_product_out;
assign t_dot_product_valid = dot_product_valid;

//////////////////////////////
//   MATRIX A
//////////////////////////////
typedef enum { ma_t, ma_l, ma_disabled } matrix_a_state_t;

matrix_a_state_t matrix_a_state;

always_comb begin

    a_col_addr = t_a_col_addr;
    a_write_row_addr = l_write_row_addr;
    a_write_col_addr = l_write_col_addr;
    a_write_data = l_write_data;

    if(matrix_a_state == ma_t) begin
        a_row_addr = t_a_row_addr;
    end else begin
        //ma_l
        a_row_addr = l_row_addr;
    end

    unique case (matrix_a_state)
        ma_t: begin
            a_col_addr_ready = t_a_col_addr_ready;

            a_row_addr_ready = t_a_row_addr_ready;

            a_write_ready = 1'b0;
        end 
        ma_l: begin
            a_col_addr_ready = 1'b0;

            a_row_addr_ready = l_row_addr_ready;

            a_write_ready = l_write_ready;
        end
        ma_disabled: begin
            a_col_addr_ready = 1'b0;

            a_row_addr_ready = 1'b0;

            a_write_ready = 1'b0;
        end
    endcase
end

//////////////////////////////
//   MATRIX B
//////////////////////////////

logic running_t;

assign b_row_addr = t_b_row_addr;
assign b_row_addr_ready = (running_t && !tri_solve_a_x_w) ? t_b_row_addr_ready : 1'b0;

//////////////////////////////
//   MATRIX X
//////////////////////////////

assign x_col_addr = t_x_col_addr;
assign x_col_addr_ready = (running_t && tri_solve_a_x_w) ? t_x_col_addr_ready : 1'b0;

assign x_write_row_addr = t_x_write_row_addr;
assign x_write_col_addr = t_x_write_col_addr;
assign x_write_data = t_x_write_data;
assign x_write_ready = (running_t && tri_solve_a_x_w) ? t_x_write_ready : 1'b0;

//////////////////////////////
//   MATRIX W
//////////////////////////////

typedef enum { mw_t, mw_div, mw_disabled } matrix_w_state_t;
matrix_w_state_t matrix_w_state;

always_comb begin
    w_col_addr = t_x_col_addr;
    
    if (matrix_w_state == mw_t) begin
        w_row_addr = t_b_row_addr;
        w_write_col_addr = t_x_write_col_addr;
        w_write_row_addr = t_x_write_row_addr;
        w_write_data = t_x_write_data;
    end else begin
        // mw_div
        w_row_addr = div_mat_row_addr;
        w_write_col_addr = div_mat_write_col_addr;
        w_write_row_addr = div_mat_write_row_addr;
        w_write_data = div_mat_write_data;
    end


    unique case (matrix_w_state)
        mw_t: begin
            
            if (tri_solve_a_x_w) begin
                w_col_addr_ready = 1'b0;

                w_row_addr_ready = t_b_row_addr_ready;

                w_write_ready = 1'b0; 
            end else begin
                w_col_addr_ready = t_x_col_addr_ready;

                w_row_addr_ready = 1'b0;

                w_write_ready = t_x_write_ready;  
            end
        end 
        mw_div: begin
                w_col_addr_ready = 1'b0;

                w_row_addr_ready = div_mat_row_addr_ready;

                w_write_ready = div_mat_write_ready; 
        end
        mw_disabled: begin
                w_col_addr_ready = 1'b0;
                w_row_addr_ready = 1'b0;
                w_write_ready = 1'b0;  
        end
    endcase
end

//////////////////////////////
//          ALU
//////////////////////////////

typedef enum { alu_t, alu_l, alu_disabled } alu_state_t;
alu_state_t alu_state;

always_comb begin
    vector_mult_in_a = l_vector_mult_in_a;
    vector_mult_in_b = l_vector_mult_in_b; 

    if(alu_state == alu_l) begin
        dot_product_a = l_dot_product_a;
        dot_product_b = l_dot_product_b;
        dot_product_c = l_dot_product_c;

        dot_product_enable = l_dot_product_enable;
        dot_product_mode = l_dot_product_mode;

    end else begin
        // alu_t
        dot_product_a = t_dot_product_a;
        dot_product_b = t_dot_product_b;
        dot_product_c = t_dot_product_c;

        dot_product_enable = t_dot_product_enable;
        dot_product_mode = t_dot_product_mode;
    end

    unique case (alu_state)
        alu_l: begin
            vector_mult_alu_ready = l_vector_mult_alu_ready;
        end
        alu_t: begin
            vector_mult_alu_ready = t_vector_mult_alu_ready;
        end
        alu_disabled: begin
            vector_mult_alu_ready = 1'b0;
        end
    endcase
end

//////////////////////////////
//     Vector register D
//////////////////////////////
// typedef enum { vd_l, vd_div, vd_disabled } vector_d_state_t;
// vector_d_state_t vector_d_state;


// always_comb begin
//     d_write_index = l_d_write_index;
//     d_slice_in = l_d_slice_in;

//     unique case (vector_d_state)
//         vd_l: begin                
//                 d_read_index = l_d_read_index;
                
//                 d_write_slice = l_d_write_slice;
//         end
//         vd_div: begin                
//                 d_read_index = div_d_read_index;
                
//                 d_write_slice = 1'b0;
//         end
//         vd_disabled: begin
//                 d_read_index = 'x;
//                 d_write_slice = 1'b0;
//         end
//     endcase
// end

assign d_write_index = l_d_write_index;
assign d_slice_in = l_d_slice_in;
assign d_read_index = l_d_read_index;
assign d_write_slice = l_d_write_slice;

/* ----------------------------------------------------------- */
//                      STATE MACHINE
/* ----------------------------------------------------------- */

typedef enum { s0, s1, s2, s3, s4, s5, s6, s7, s8, s9 } state_t;
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
            state_next = s2;
        s2:
            if(l_finished)
                state_next = s3;
            else
                state_next = s2;
        s3:
            state_next = s4;
        s4:
            if(t_finished)
                state_next = s5;
            else
                state_next = s4;
        s5:
            state_next = s6;
        s6:
            if(div_finished)
                state_next = s7;
            else
                state_next = s6;
        s7:
            state_next = s8;
        s8:
            if(t_finished)
                state_next = s9;
            else
                state_next = s8;
        s9:
            state_next = s0;
        endcase
    end

    // Outputs
    always_comb begin
        alu_state = alu_disabled;
        div_start = 1'b0; 
        finished = 1'b0;
        l_start = 1'b0;
        lower_triangular = 1'b0;
        matrix_a_state = ma_disabled;
        matrix_w_state = mw_disabled;
        running_t = 1'b0;
        t_start = 1'b0;
        // vector_d_state = vd_disabled;

        unique case (state_reg)
        s0: begin
            // State disabled
            matrix_a_state = ma_disabled;
            matrix_w_state = mw_disabled;
            alu_state = alu_disabled;
            // vector_d_state = vd_disabled;
            running_t = 1'b0;
            lower_triangular = 1'b0;
        end
        s1: begin
            l_start = 1'b1;

            // State l
            matrix_a_state = ma_l;
            matrix_w_state = mw_disabled;
            alu_state = alu_l;
            // vector_d_state = vd_l;
            running_t = 1'b0;
        end
        s2: begin
            // State l
            matrix_a_state = ma_l;
            matrix_w_state = mw_disabled;
            alu_state = alu_l;
            // vector_d_state = vd_l;
            running_t = 1'b0;
        end
        s3: begin
            t_start = 1'b1;

            // state t
            matrix_a_state = ma_t;
            matrix_w_state = mw_t;
            alu_state = alu_t;
            // vector_d_state = vd_disabled;
            running_t = 1'b1;
            
            lower_triangular = 1'b1;
        end
        s4: begin
            // State t
            matrix_a_state = ma_t;
            matrix_w_state = mw_t;
            alu_state = alu_t;
            // vector_d_state = vd_disabled;
            running_t = 1'b1;

            lower_triangular = 1'b1;
        end
        s5: begin
            div_start = 1'b1;

            // State d
            matrix_a_state = ma_disabled;
            matrix_w_state = mw_div;
            alu_state = alu_disabled;
            // vector_d_state = vd_div;
            running_t = 1'b0;
        end
        s6: begin
            // State d
            matrix_a_state = ma_disabled;
            matrix_w_state = mw_div;
            alu_state = alu_disabled;
            // vector_d_state = vd_div;
            running_t = 1'b0;
        end
        s7: begin
            t_start = 1'b1;

            // state t
            matrix_a_state = ma_t;
            matrix_w_state = mw_t;
            alu_state = alu_t;
            // vector_d_state = vd_disabled;
            running_t = 1'b1;
            
            lower_triangular = 1'b0;
        end
        s8: begin      
            // state t
            matrix_a_state = ma_t;
            matrix_w_state = mw_t;
            alu_state = alu_t;
            // vector_d_state = vd_disabled;
            running_t = 1'b1;
            
            lower_triangular = 1'b0;
        end
        s9: begin
            finished = 1'b1;
        end
        endcase
    end

endmodule