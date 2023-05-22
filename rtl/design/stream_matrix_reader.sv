module stream_matrix_reader #(
    parameter WIDTH = 32,
    parameter NUM_ROWS = 11,
    parameter NUM_COLS = 3,

    parameter MEMORY_LATENCY = 2,

    localparam ROW_ADDR_WIDTH = $clog2(NUM_ROWS),
    localparam COL_ADDR_WIDTH = $clog2(NUM_COLS),
    localparam ROW_SIZE = NUM_COLS * WIDTH,
    localparam COL_SIZE = NUM_ROWS * WIDTH
) (
    input logic clk,
    input logic rst,

    input logic start,  /* Must only be active for a cycle. After start=1, the bus will be ready to read the matrix */

    /* ----------------------------------------------------------- */
    //                   DATA STREAM BUS
    /* ----------------------------------------------------------- */

    input logic ds_next_data, /* If ds_next_data = 1, we are ready to accept new data from the bus */
    output logic[WIDTH-1:0] ds_out,   /* Stream data from the bus */
    output logic ds_valid,      /* If ds_valid = 1, ds_out is valid */
    output logic ds_last,        /* If ds_last = 1, this is the last element of the matrix (asserted in the same cycle that its respective ds_out and ds_valid) */

    /* ----------------------------------------------------------- */
    //                   MATRIX PORT
    /* ----------------------------------------------------------- */

    output logic [ROW_ADDR_WIDTH-1:0] row_addr,
    output logic row_addr_ready,
    input logic row_valid,
    input logic [ROW_SIZE-1:0] row_out
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

// Delay lasts

logic del_last_in, del_last_out;

register_delay 
#(
    .REG_WIDTH    (1),
    .DELAY_CYCLES (MEMORY_LATENCY-1)
)
u_register_delay_last (
    .clk (clk ),
    .rst (rst ),
    .in  (del_last_in  ),
    .out (del_last_out )
);

// Delay col

logic [COL_ADDR_WIDTH-1:0] del_col_in, del_col_out;

register_delay 
#(
    .REG_WIDTH    (COL_ADDR_WIDTH),
    .DELAY_CYCLES (MEMORY_LATENCY)
)
u_register_delay_col (
    .clk (clk ),
    .rst (rst ),
    .in  (del_col_in  ),
    .out (del_col_out )
);

logic del_start_in, del_start_out;

register_delay 
#(
    .REG_WIDTH    (1),
    .DELAY_CYCLES (1)
)
u_register_delay_start (
    .clk (clk ),
    .rst (rst ),
    .in  (del_start_in  ),
    .out (del_start_out )
);

logic del_sr_in, del_sr_out;

register_delay 
#(
    .REG_WIDTH    (1),
    .DELAY_CYCLES (MEMORY_LATENCY)
)
u_register_delay_sr (
    .clk (clk ),
    .rst (rst ),
    .in  (del_sr_in  ),
    .out (del_sr_out )
);

/* ----------------------------------------------------------- */
//                    SET RESET REGISTER
/* ----------------------------------------------------------- */

logic sr_set, sr_reset, sr_out;

set_reset_reg u_set_reset_reg(
    .clk   (clk   ),
    .rst   (rst   ),
    .set   (sr_set   ),
    .reset (sr_reset ),
    .out   (sr_out   )
);

logic sr_last_set, sr_last_reset, sr_last_out;

set_reset_reg u_set_reset_reg_last(
    .clk   (clk   ),
    .rst   (rst   ),
    .set   (sr_last_set   ),
    .reset (sr_last_reset ),
    .out   (sr_last_out   )
);


/* ----------------------------------------------------------- */
//                  HARDWARE CONNECTIONS
/* ----------------------------------------------------------- */

logic transaction_made;

assign ds_out = row_out[del_col_out*WIDTH +: WIDTH];

assign r_reset_count = start;
assign r_up = c_max;

assign c_reset_count = start;
assign c_up = transaction_made;

assign del_col_in = c_out;

assign row_addr = r_out;
assign row_addr_ready = 1'b1;

assign del_sr_in = del_start_out || (transaction_made && !r_max);

assign del_start_in = start;

assign sr_set = del_sr_out;
assign sr_reset = transaction_made || start || r_max;

assign ds_valid = sr_out;
assign transaction_made = ds_valid && ds_next_data;

assign ds_last = sr_last_out;
assign del_last_in = (r_out == NUM_ROWS - 1) && (c_out == NUM_COLS - 1) && !r_max;

assign sr_last_reset = sr_reset;
assign sr_last_set = del_last_out && !r_max;

endmodule