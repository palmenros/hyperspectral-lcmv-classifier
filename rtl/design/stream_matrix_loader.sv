module stream_matrix_loader #(
    parameter NUM_ROWS = 4,
    parameter NUM_COLS = 5,
    parameter WIDTH = 32,

    localparam ROW_ADDR_WIDTH = $clog2(NUM_ROWS),
    localparam COL_ADDR_WIDTH = $clog2(NUM_COLS),
    localparam ROW_SIZE = NUM_COLS * WIDTH
) (
    input logic rst, 
    input logic clk,

    output logic finished_loading,

    /* ----------------------------------------------------------- */
    //                   DATA STREAM BUS
    /* ----------------------------------------------------------- */

    output logic ds_next_data, /* If ds_next_data = 1, we are ready to accept a new data from the bus */
    input[WIDTH-1:0] ds_out,   /* Stream data from the bus */
    input logic ds_valid,      /* If ds_valid = 1, ds_out is valid */

    /* ----------------------------------------------------------- */
    //                  MATRIX PORT
    /* ----------------------------------------------------------- */

    // This module does NOT instantiate a matrix memory, it gets ports to interact 
    // with an already instantiated matrix

    //  Element writing port
    output logic [ROW_ADDR_WIDTH-1:0] write_row_addr,
    output logic [COL_ADDR_WIDTH-1:0] write_col_addr,
    output logic [WIDTH-1:0] write_data,
    output logic write_ready
 
    /* The module does not need to read the matrix */

    // output logic [ROW_ADDR_WIDTH-1:0] row_addr,
    // output logic row_addr_ready,
    // input logic row_valid,
    // input logic [ROW_SIZE-1:0] row_out,

    //output logic [COL_ADDR_WIDTH-1:0] col_addr,
    //output logic col_addr_ready,
    //input logic col_valid,
    //input logic [COL_SIZE-1:0] col_out,
);

/* ----------------------------------------------------------- */
//                    COUNTERS
/* ----------------------------------------------------------- */

// R

logic r_reset_count, r_up, r_max;
logic [ROW_ADDR_WIDTH-1:0] r_out;

counter_mod 
#(
    .MOD   (NUM_ROWS)
)
u_r_counter_mod(
    .rst         (rst         ),
    .clk         (clk         ),
    .reset_count (r_reset_count ),
    .up          (r_up          ),
    .max         (r_max         ),
    .out         (r_out         )
);

// C

logic c_reset_count, c_up, c_max;
logic [COL_ADDR_WIDTH-1:0] c_out;

counter_mod 
#(
    .MOD   (NUM_COLS)
)
u_c_counter_mod(
    .rst         (rst         ),
    .clk         (clk         ),
    .reset_count (c_reset_count ),
    .up          (c_up          ),
    .max         (c_max         ),
    .out         (c_out         )
);

/* ----------------------------------------------------------- */
//                    REGISTER DELAY
/* ----------------------------------------------------------- */

logic delay_in, delay_out;

register_delay 
#(
    .REG_WIDTH    (1),
    .DELAY_CYCLES (1)
)
u_register_delay(
    .clk (clk ),
    .rst (rst ),
    .in  (delay_in  ),
    .out (delay_out )
);

/* ----------------------------------------------------------- */
//                   HARDWARE CONNECTIONS
/* ----------------------------------------------------------- */

assign finished_loading = delay_out;
assign delay_in = r_max;

assign r_reset_count = 1'b0;
assign r_up = c_max;

assign c_reset_count = 1'b0;
assign c_up = ds_valid;

assign write_row_addr = r_out;
assign write_col_addr = c_out;
assign write_data = ds_out;
assign write_ready = ds_valid;

assign ds_next_data = 1'b1;

endmodule