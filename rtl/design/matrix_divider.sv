module matrix_divider #(
    parameter NUM_ROWS = 4,
    parameter NUM_COLS = 3,
    parameter WIDTH = 32,
    parameter DIVIDER_LATENCY = 28,
    parameter MEMORY_LATENCY  = 2,

    localparam ROW_ADDR_WIDTH = $clog2(NUM_ROWS),
    localparam COL_ADDR_WIDTH = $clog2(NUM_COLS),
    localparam ROW_SIZE = NUM_COLS * WIDTH,
    localparam COL_SIZE = NUM_ROWS * WIDTH
) (
    input logic clk,
    input logic rst,

    input logic start,
    output logic finished,

    /* ----------------------------------------------------------- */
    //                  MATRIX PORTS
    /* ----------------------------------------------------------- */

    // This module does NOT instantiate a matrix memory, it gets ports to interact 
    // with an already instantiated matrix

    output logic [ROW_ADDR_WIDTH-1:0] mat_row_addr,
    output logic mat_row_addr_ready,
    input logic mat_row_valid,
    input logic [ROW_SIZE-1:0] mat_row_out,

    // We don't need the column port 

    // output logic [COL_ADDR_WIDTH-1:0] col_addr,
    // output logic col_addr_ready,
    // input logic col_valid,
    // input logic [COL_SIZE-1:0] col_out,

    // Element writing port
    output logic [ROW_ADDR_WIDTH-1:0] mat_write_row_addr,
    output logic [COL_ADDR_WIDTH-1:0] mat_write_col_addr,
    output logic [WIDTH-1:0] mat_write_data,
    output logic mat_write_ready,

    /* ----------------------------------------------------------- */
    //                  D VECTOR REGISTER PORTS
    /* ----------------------------------------------------------- */
    
    // This module does NOT instantiate the vector register for the 
    // output D, it gets ports to interact with an already instantiated
    // vector register

    // input logic[ROW_SIZE-1:0] d_out,

    // We won't load any value onto the d register, we'll write element by element

    // output logic d_load,
    // output logic[ROW_SIZE-1:0] d_in,

    // Slicing read
    output logic[ROW_ADDR_WIDTH-1:0] d_read_index,
    input logic[WIDTH-1:0] d_slice_out

    // Slicing write
    // output logic[ROW_ADDR_WIDTH-1:0] d_write_index,
    // output logic[WIDTH-1:0] d_slice_in,
    // output logic d_write_slice
);
    
    typedef enum { s0, s1, s2, s3 } state_t;
    state_t state_reg, state_next;

    /* ----------------------------------------------------------- */
    //                      COUNTERS
    /* ----------------------------------------------------------- */

    logic col_rst_count, col_up, col_max;

    counter_mod 
    #(
        .MOD   (NUM_COLS)
    )
    u_counter_col(
    	.rst         (rst         ),
        .clk         (clk         ),
        .reset_count (col_rst_count),
        .up          (col_up      ),
        .max         (col_max     ),
        .out         ()
    );
    
    logic row_rst_count, row_up, row_max;
    logic[ROW_ADDR_WIDTH-1:0] row_out;

    counter_mod 
    #(
        .MOD   (NUM_ROWS)
    )
    u_counter_row(
    	.rst         (rst         ),
        .clk         (clk         ),
        .reset_count (row_rst_count),
        .up          (row_up       ),
        .max         (row_max      ),
        .out         (row_out      )
    );
     
    logic col_f_rst_count, col_f_up, col_f_max;
    logic[COL_ADDR_WIDTH-1:0] col_f_out;

    counter_mod 
    #(
        .MOD   (NUM_COLS)
    )
    u_counter_col_f(
    	.rst         (rst         ),
        .clk         (clk         ),
        .reset_count (col_f_rst_count ),
        .up          (col_f_up          ),
        .max         (col_f_max         ),
        .out         (col_f_out         )
    );

    logic row_f_rst_count, row_f_up, row_f_max;
    logic[ROW_ADDR_WIDTH-1:0] row_f_out;

    counter_mod 
    #(
        .MOD   (NUM_ROWS)
    )
    u_counter_row_f(
        .rst         (rst         ),
        .clk         (clk         ),
        .reset_count (row_f_rst_count ),
        .up          (row_f_up          ),
        .max         (row_f_max         ),
        .out         (row_f_out         )
    );
    
    logic col_memout_rst_count, col_memout_up, col_memout_max;
    logic[COL_ADDR_WIDTH-1:0] col_memout_out;

    counter_mod 
    #(
        .MOD   (NUM_COLS)
    )
    u_counter_col_memout(
        .rst         (rst         ),
        .clk         (clk         ),
        .reset_count (col_memout_rst_count ),
        .up          (col_memout_up          ),
        .max         (col_memout_max         ),
        .out         (col_memout_out         )
    );

    logic row_memout_rst_count, row_memout_up, row_memout_max;
    logic[ROW_ADDR_WIDTH-1:0] row_memout_out;

    counter_mod 
    #(
        .MOD   (NUM_ROWS)
    )
    u_counter_row_memout(
        .rst         (rst         ),
        .clk         (clk         ),
        .reset_count (row_memout_rst_count ),
        .up          (row_memout_up          ),
        .max         (row_memout_max         ),
        .out         (row_memout_out         )
    );

    /* ----------------------------------------------------------- */
    //                    ARITHMETIC HARDWARE
    /* ----------------------------------------------------------- */

    logic div_ready, div_valid;
    logic [WIDTH-1:0] div_a, div_b, div_o;

    fp_divider 
    #(
        .WIDTH   (WIDTH   ),
        .LATENCY (DIVIDER_LATENCY )
    )
    u_fp_divider(
    	.clk   (clk   ),
        .rst   (rst   ),
        .a     (div_a  ),
        .b     (div_b  ),
        .o     (div_o  ),
        .ready (div_ready ),
        .valid (div_valid )
    );

    /* ----------------------------------------------------------- */
    //                HARDWARE WIRE CONNECTIONS
    /* ----------------------------------------------------------- */

    
    // Declare control wires

    logic process_item;
    logic finished_writing;
    logic finished_issuing;

    assign col_up = process_item;
    assign row_up = col_max;

    assign finished_issuing = col_max && row_max;

    assign mat_row_addr = row_out;
    assign mat_row_addr_ready = process_item;

    assign mat_write_row_addr = row_f_out;
    assign mat_write_col_addr = col_f_out;
    assign mat_write_data = div_o;
    assign mat_write_ready = div_valid;

    assign col_memout_up = mat_row_valid && state_reg != s0;
    
    // assign div_ready = mat_row_valid && state_reg != s0;
    register_delay 
    #(
        .REG_WIDTH    (1'b1),
        .DELAY_CYCLES (MEMORY_LATENCY )
    )
    u_register_delay(
    	.clk (clk ),
        .rst (rst ),
        .in  (col_memout_up),
        .out (div_ready )
    );

    // assign div_a = mat_row_out[col_memout_out*WIDTH +: WIDTH]
    register_delay_no_rst 
    #(
        .REG_WIDTH    (WIDTH),
        .DELAY_CYCLES (MEMORY_LATENCY )
    )
    u_register_delay_no_rst(
    	.clk (clk ),
        .in  (mat_row_out[col_memout_out*WIDTH +: WIDTH] ),
        .out (div_a )
    );
    
    assign div_b = d_slice_out;

    assign col_f_up = div_valid;
    assign row_f_up = col_f_max;
    assign finished_writing = row_f_max && col_f_max;

    assign row_memout_up = col_memout_max;
    assign d_read_index = row_memout_out;

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
        
        col_f_rst_count = 1'b0;
        col_memout_rst_count = 1'b0;
        col_rst_count = 1'b0;
        finished = 1'b0;
        process_item = 1'b0;
        row_f_rst_count = 1'b0;
        row_memout_rst_count = 1'b0;
        row_rst_count = 1'b0;

        unique case (state_reg)
        s0: begin
            finished = 1'b0;
            row_rst_count = 1'b1;
            col_rst_count = 1'b1;
            row_f_rst_count = 1'b1;
            col_f_rst_count = 1'b1;
            row_memout_rst_count = 1'b1;
            col_memout_rst_count = 1'b1;
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