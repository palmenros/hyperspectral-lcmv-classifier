module tri_solver #(
    /* 
        Sizes M and N such that

        A is a matrix [n, n]
        B is a matrix [n, m]
        X is a matrix [n, m]
     */
    parameter N = 4,
    parameter M = 3, 

    parameter WIDTH = 32, /* Size in bits of each scalar of the matrix */

    // Defining indices sizes
    parameter I_REGISTER_WIDTH = $clog2(N),
    parameter K_REGISTER_WIDTH = $clog2(M),
    parameter K_F_COUNTER_WIDTH = $clog2(M + 1),

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

    // If lower_triangular = 1, this module will solve for L*X=B, where L = tril(A). (It will assume the diagonal of A is all ones)
    // If lower_triangular = 0, this module will solve for L'*X=B, where L = tril(A). (It will assume the diagonal of A is all ones)
    input logic lower_triangular_input,

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

    output logic [A_COL_ADDR_WIDTH-1:0] a_col_addr,
    output logic a_col_addr_ready,
    input logic a_col_valid,
    input logic [A_COL_SIZE-1:0] a_col_out,

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
    // input logic [ROW_SIZE-1:0] row_out,
);

    typedef enum { s0, s1, s2, s3, s4 } state_t;
    state_t state_reg, state_next;

    
    /* ----------------------------------------------------------- */
    //                  REGISTERS AND COUNTERS
    /* ----------------------------------------------------------- */

    // Lower triangular
    logic lower_triangular_load;
    logic lower_triangular;

    register 
    #(
        .WIDTH (1 )
    )
    u_register(
    	.clk  (clk  ),
        .rst  (rst  ),
        .load (lower_triangular_load),
        .in   (lower_triangular_input),
        .out  (lower_triangular  )
    );
    

    // K

    logic k_rst_zero, k_up;
    logic[K_REGISTER_WIDTH-1:0] k_out;

    counter 
    #(
        .WIDTH (K_REGISTER_WIDTH)
    )
    k_cnt(
    	.clk         (clk        ),
        .rst         (rst        ),
        .reset_count (k_rst_zero ),
        .up          (k_up       ),
        .out         (k_out      )
    );

    // K slice counter
    logic k_slice_rst_zero, k_slice_up;
    logic[K_REGISTER_WIDTH-1:0] k_slice_out;

    counter 
    #(
        .WIDTH (K_REGISTER_WIDTH)
    )
    u_k_slice(
    	.clk         (clk         ),
        .rst         (rst         ),
        .reset_count (k_slice_rst_zero ),
        .up          (k_slice_up          ),
        .out         (k_slice_out         )
    );

    assign k_slice_up = b_row_valid && state_reg != s0;
    

    // K_F

    logic k_f_rst_zero, k_f_up;
    logic[K_F_COUNTER_WIDTH-1:0] k_f_out;

    counter 
    #(
        .WIDTH (K_F_COUNTER_WIDTH)
    )
    k_f_counter(
    	.clk         (clk         ),
        .rst         (rst         ),
        .reset_count (k_f_rst_zero),
        .up          (k_f_up      ),
        .out         (k_f_out     )
    );

    // I
    logic i_load;
    logic [I_REGISTER_WIDTH-1:0] i_in, i_out;

    register 
    #(
        .WIDTH (I_REGISTER_WIDTH)
    )
    i_register(
    	.clk  (clk  ),
        .rst  (rst  ),
        .load (i_load ),
        .in   (i_in   ),
        .out  (i_out  )
    );
    
    // DP ENABLE DUAL SHIFT REGISTER

    logic sh_shift_in, sh_direction_right, sh_reset_zero, sh_shift;
    logic[N-1:0] sh_out;

    dual_shift_register 
    #(
        .WIDTH (N)
    )
    u_dual_shift_register(
    	.clk             (clk             ),
        .rst             (rst             ),
        .shift_in        (sh_shift_in        ),
        .direction_right (sh_direction_right ),
        .reset_zero      (sh_reset_zero      ),
        .shift           (sh_shift           ),
        .out             (sh_out             )
    );

    /* ----------------------------------------------------------- */
    //                    ARITHMETIC HARDWARE
    /* ----------------------------------------------------------- */

    // Inverter placed at the ALU output (do)

    logic[WIDTH-1:0] fp_inv_do_in, fp_inv_do_out;

    fp_inverter 
    #(
        .WIDTH (WIDTH )
    )
    u_fp_inverter_alu_out(
    	.in  (fp_inv_do_in  ),
        .out (fp_inv_do_out )
    );
    
    // Inverter placed at the ALU input (di)

    logic[WIDTH-1:0] fp_inv_di_in, fp_inv_di_out;

    fp_inverter 
    #(
        .WIDTH (WIDTH )
    )
    u_fp_inverter_alu_in(
    	.in  (fp_inv_di_in  ),
        .out (fp_inv_di_out )
    );
    
    /* ----------------------------------------------------------- */
    //                 DELAY REGISTERS
    /* ----------------------------------------------------------- */

    logic[WIDTH-1:0] delay_data_in, delay_data_out; 

    register_delay_no_rst 
    #(
        .REG_WIDTH    (WIDTH),
        .DELAY_CYCLES (1)
    )
    data_delay(
    	.clk (clk ),
        .in  (delay_data_in),
        .out (delay_data_out)
    );

    logic delay_valid_in, delay_valid_out;
    
    register_delay 
    #(
        .REG_WIDTH    (1),
        .DELAY_CYCLES (1)
    )
    valid_delay(
    	.clk (clk ),
        .rst (rst ),
        .in  (delay_valid_in),
        .out (delay_valid_out)
    );

    /* ----------------------------------------------------------- */
    //                HARDWARE WIRE CONNECTIONS
    /* ----------------------------------------------------------- */

    logic mat_load_ready;
    
    assign a_row_addr = i_out;
    assign a_row_addr_ready = lower_triangular && mat_load_ready;
    assign a_col_addr = i_out;
    assign a_col_addr_ready = !lower_triangular && mat_load_ready;

    assign dot_product_a = lower_triangular ? a_row_out : a_col_out;
    assign dot_product_b = x_col_out;
    assign dot_product_c = fp_inv_di_out;
    assign dot_product_enable = sh_out;
    assign dot_product_mode = 1'b1;
    assign vector_mult_alu_ready = x_col_valid && state_reg != s0;

    assign fp_inv_do_in = dot_product_out;
    assign fp_inv_di_in = b_row_out[k_slice_out*WIDTH +: WIDTH];

    assign delay_data_in = fp_inv_do_out;
    assign delay_valid_in = dot_product_valid && state_reg != s0;

    assign sh_shift_in = 1'b1;
    assign sh_direction_right = lower_triangular ? 0 : 1;

    assign x_col_addr = k_out;
    assign x_col_addr_ready = mat_load_ready;
    assign x_write_row_addr = i_out;
    assign x_write_col_addr = k_f_out;
    assign x_write_data = delay_data_out;
    assign x_write_ready = delay_valid_out;

    assign k_f_up = delay_valid_out;

    assign b_row_addr = i_out;
    assign b_row_addr_ready = mat_load_ready;

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
            if (k_out == M-1)
                state_next = s2;
            else
                state_next = s1;
        s2:
            if (k_f_out == M)
                state_next = s3;
            else
                state_next = s2;
        s3:
            if ((lower_triangular && i_out == N-1) || (!lower_triangular && i_out == 0) )
                state_next = s4;
            else
                state_next = s1;
        s4:
            state_next = s0;               
        endcase
    end

    //outputs
    always_comb begin

        finished = 1'b0;
        i_in = 0;
        i_load = 1'b0;
        k_f_rst_zero = 1'b0;
        k_slice_rst_zero = 1'b0;
        k_rst_zero = 1'b0;
        k_up = 1'b0;
        lower_triangular_load = 1'b0;
        mat_load_ready = 1'b0;
        sh_reset_zero = 1'b0;
        sh_shift = 1'b0;
            
        unique case (state_reg)
        s0: begin
            k_rst_zero = 1'b1;
            k_slice_rst_zero = 1'b1;
            i_load = 1'b1;
            i_in = lower_triangular_input ? 0 : N - 1;
            sh_reset_zero = 1'b1;
            lower_triangular_load = 1'b1;
            k_f_rst_zero = 1'b1;

        end
        s1: begin
            mat_load_ready = 1'b1;
            k_up = 1'b1;
        end
        s2: begin
            // Nothing here
        end
        s3: begin
            k_rst_zero = 1'b1;
            k_slice_rst_zero = 1'b1;
            i_load = 1'b1;
            i_in = i_out + (lower_triangular ? 1 : -1);
            k_f_rst_zero = 1'b1;
            sh_shift = 1'b1;
        end
        s4: begin
            finished = 1'b1;
        end
        endcase    
    end
endmodule