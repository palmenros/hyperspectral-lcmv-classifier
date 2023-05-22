module top_ldl_decomposer(
    input logic sys_clk_p,
    input logic rst,
    input logic start,

    output logic row_valid,
    
    input logic initializing,

    input logic [ROW_ADDR_WIDTH-1:0] ini_row_addr,
    input logic ini_row_addr_ready,

    input logic [ROW_ADDR_WIDTH-1:0] ini_write_row_addr,
    input logic [ROW_ADDR_WIDTH-1:0] ini_write_col_addr,
    input logic [WIDTH-1:0] ini_write_data,
    input logic ini_write_ready,

    input logic [ROW_ADDR_WIDTH-1:0] col_addr,
    input logic col_valid,
    output logic col_addr_ready,

    output logic row_out_or,
    output logic row_out_and,

    output logic col_out_or,
    output logic col_out_and,

    output logic d_out_or,
    output logic d_out_and,

    output logic finished
);
    localparam NUM_ROWS = 169;
    localparam WIDTH = 32;

    localparam ROW_ADDR_WIDTH = $clog2(NUM_ROWS);
    localparam ROW_SIZE = NUM_ROWS * WIDTH;

    logic clk;
    assign clk = sys_clk_p;

    logic [ROW_SIZE-1:0] row_out;
    logic [ROW_SIZE-1:0] col_out;

    assign row_out_or = |row_out;
    assign row_out_and = &row_out;

    assign col_out_or = |col_out;
    assign col_out_and = &col_out;

    assign d_out_or = |d_out;
    assign d_out_and = &d_out;

    // Row reading port
    logic [ROW_ADDR_WIDTH-1:0] row_addr;
    logic row_addr_ready;
    
    logic [ROW_ADDR_WIDTH-1:0] real_row_addr;
    logic real_row_addr_ready;
    
    assign real_row_addr = initializing ? ini_row_addr : row_addr;
    assign real_row_addr_ready = initializing ? ini_row_addr_ready : row_addr_ready;

    logic [ROW_ADDR_WIDTH-1:0] real_write_row_addr;
    logic [ROW_ADDR_WIDTH-1:0] real_write_col_addr;
    logic [WIDTH-1:0] real_write_data;
    logic real_write_ready;

    assign real_write_row_addr = initializing ? ini_write_row_addr : write_row_addr;
    assign real_write_col_addr = initializing ? ini_write_col_addr : write_col_addr;
    assign real_write_data = initializing ? ini_write_data : write_data;
    assign real_write_ready = initializing ? ini_write_ready : write_ready;

    // Element writing port
    logic [ROW_ADDR_WIDTH-1:0] write_row_addr;
    logic [ROW_ADDR_WIDTH-1:0] write_col_addr;
    logic [WIDTH-1:0] write_data;
    logic write_ready;

    matrix 
    #(
        .NUM_ROWS          (NUM_ROWS          ),
        .NUM_COLS          (NUM_ROWS          ),
        .SCALAR_BITS       (WIDTH       )
    )
    u_matrix(
    	.clk            (clk            ),
        .rst            (rst            ),
        .row_addr       (real_row_addr       ),
        .row_addr_ready (real_row_addr_ready ),
        .row_valid      (row_valid      ),
        .row_out        (row_out        ),
        .col_addr       (col_addr       ),
        .col_addr_ready (col_addr_ready ),
        .col_valid      (col_valid      ),
        .col_out        (col_out        ),
        .write_row_addr (real_write_row_addr ),
        .write_col_addr (real_write_col_addr ),
        .write_data     (real_write_data     ),
        .write_ready    (real_write_ready    )
    );

    logic [WIDTH*NUM_ROWS-1:0] dot_product_a;
    logic [WIDTH*NUM_ROWS-1:0] dot_product_b;
    logic [WIDTH-1:0] dot_product_c;
    logic [WIDTH-1:0] dot_product_out;
    logic [NUM_ROWS-1:0] dot_product_enable;
    logic [WIDTH*NUM_ROWS-1:0] vector_mult_in_a;
    logic [WIDTH*NUM_ROWS-1:0] vector_mult_in_b; 
    logic [WIDTH*NUM_ROWS-1:0] vector_mult_out;
    logic vector_mult_alu_ready;
    logic dot_product_valid;
    logic vector_mult_valid;
    logic dot_product_mode;

    fp_vector_mult_alu 
    #(
        .WIDTH                                  (WIDTH   ),
        .NUM_INPUTS                             (NUM_ROWS)
    )
    u_fp_vector_mult_alu(
    	.clk                (clk                ),
        .rst                (rst                ),
        .dot_product_a      (dot_product_a      ),
        .dot_product_b      (dot_product_b      ),
        .dot_product_c      (dot_product_c      ),
        .dot_product_out    (dot_product_out    ),
        .dot_product_enable (dot_product_enable ),
        .vector_mult_in_a   (vector_mult_in_a   ),
        .vector_mult_in_b   (vector_mult_in_b   ),
        .vector_mult_out    (vector_mult_out    ),
        .ready              (vector_mult_alu_ready),
        .dot_product_valid  (dot_product_valid  ),
        .vector_mult_valid  (vector_mult_valid  ),
        .dot_product_mode   (dot_product_mode   )
    );

    logic[ROW_SIZE-1:0] d_out;
    logic d_load;
    logic[ROW_SIZE-1:0] d_in;
    logic[ROW_ADDR_WIDTH-1:0] d_read_index;
    logic[WIDTH-1:0] d_slice_out;
    logic[ROW_ADDR_WIDTH-1:0] d_write_index;
    logic[WIDTH-1:0] d_slice_in;
    logic d_write_slice;

    vector_reg 
    #(
        .SCALAR_BITS (WIDTH ),
        .LENGTH      (NUM_ROWS)
    )
    u_vector_reg(
        .clk         (clk         ),
        .load        (d_load        ),
        .in          (d_in          ),
        .out         (d_out         ),
        .read_index  (d_read_index  ),
        .slice_out   (d_slice_out   ),
        .write_index (d_write_index ),
        .slice_in    (d_slice_in    ),
        .write_slice (d_write_slice )
    );

    ldl_decomposer 
    #(
        .NUM_ROWS             (NUM_ROWS             ),
        .WIDTH                (WIDTH                )
    )
    u_ldl_decomposer(
    	.rst                   (rst                   ),
        .clk                   (clk                   ),
        .start                 (start                 ),
        .finished              (finished              ),
        .row_addr              (row_addr              ),
        .row_addr_ready        (row_addr_ready        ),
        .row_valid             (row_valid             ),
        .row_out               (row_out               ),
        .write_row_addr        (write_row_addr        ),
        .write_col_addr        (write_col_addr        ),
        .write_data            (write_data            ),
        .write_ready           (write_ready           ),
        .dot_product_a         (dot_product_a         ),
        .dot_product_b         (dot_product_b         ),
        .dot_product_c         (dot_product_c         ),
        .dot_product_out       (dot_product_out       ),
        .dot_product_enable    (dot_product_enable    ),
        .vector_mult_in_a      (vector_mult_in_a      ),
        .vector_mult_in_b      (vector_mult_in_b      ),
        .vector_mult_out       (vector_mult_out       ),
        .vector_mult_alu_ready (vector_mult_alu_ready ),
        .dot_product_valid     (dot_product_valid     ),
        .vector_mult_valid     (vector_mult_valid     ),
        .dot_product_mode      (dot_product_mode      ),
        .d_out                 (d_out                 ),
        .d_read_index          (d_read_index          ),
        .d_slice_out           (d_slice_out           ),
        .d_write_index         (d_write_index         ),
        .d_slice_in            (d_slice_in            ),
        .d_write_slice         (d_write_slice         )
    );
endmodule