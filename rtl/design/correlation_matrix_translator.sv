// This module translates the output of the correlation_matrix module
// (a row_matrix with only the upper triangular part correct) to a matrix
// the ldl_solver understands, while also dividing each element by NUM_SAMPLES
module correlation_matrix_translator #(
    parameter N = 5, /* Size of the correlation matrix */ 
    parameter NUM_SAMPLES = 11, /* Total number of samples */
    parameter WIDTH = 32,
    parameter DIVIDER_LATENCY = 28,
    parameter MEMORY_LATENCY = 2,

    parameter NUM_ROWS = N,
    parameter NUM_COLS = N,

    localparam ROW_ADDR_WIDTH = $clog2(NUM_ROWS),
    localparam COL_ADDR_WIDTH = $clog2(NUM_COLS),
    localparam ROW_SIZE = NUM_COLS * WIDTH,
    localparam REGISTER_WIDTH = $clog2(N)
) (
    input logic clk,
    input logic rst,

    input logic start,
    output logic finished,

    /* ----------------------------------------------------------- */
    //                  ROW MATRIX A PORTS
    /* ----------------------------------------------------------- */
    
    // This module does NOT instantiate a matrix memory, it gets ports to interact 
    // with an already instantiated matrix

    // Row reading port
    output logic [ROW_ADDR_WIDTH-1:0] a_row_addr,
    output logic a_row_addr_ready,

    input logic a_row_valid,
    input logic [ROW_SIZE-1:0] a_row_out,

    // We don't need to write to matrix 

    //Row writing port
    // output logic [R_ROW_ADDR_WIDTH-1:0] r_write_row_addr,
    // output logic [R_ROW_SIZE-1:0] r_write_data,
    // output logic r_write_ready,

    /* ----------------------------------------------------------- */
    //                  MATRIX X PORTS
    /* ----------------------------------------------------------- */

    // This module does NOT instantiate a matrix memory, it gets ports to interact 
    // with an already instantiated matrix

    //  Element writing port
    output logic [ROW_ADDR_WIDTH-1:0] x_write_row_addr,
    output logic [COL_ADDR_WIDTH-1:0] x_write_col_addr,
    output logic [WIDTH-1:0] x_write_data,
    output logic x_write_ready
 
    /* The module does not need to read matrix X */

    // output logic [ROW_ADDR_WIDTH-1:0] x_row_addr,
    // output logic x_row_addr_ready,
    // input logic x_row_valid,
    // input logic [ROW_SIZE-1:0] x_row_out,

    //output logic [COL_ADDR_WIDTH-1:0] col_addr,
    //output logic col_addr_ready,
    //input logic col_valid,
    //input logic [COL_SIZE-1:0] col_out,
);

/* ----------------------------------------------------------- */
//                    ARITHMETIC HARDWARE
/* ----------------------------------------------------------- */

logic [WIDTH-1:0] div_a, div_b, div_o;
logic div_ready, div_valid;

fp_divider 
#(
    .WIDTH   (WIDTH   ),
    .LATENCY (DIVIDER_LATENCY)
)
u_fp_divider(
    .clk   (clk   ),
    .rst   (rst   ),
    .a     (div_a     ),
    .b     (div_b     ),
    .o     (div_o     ),
    .ready (div_ready ),
    .valid (div_valid )
);

logic [31:0] if_in;
logic [WIDTH-1:0] if_out;
logic if_ready, if_valid;

int_to_fp 
#(
    .INT_WIDTH    (32),
    .INT_UNSIGNED (1),
    .FP_WIDTH     (WIDTH)
)
u_int_to_fp(
    .clk   (clk   ),
    .rst   (rst   ),
    .in    (if_in    ),
    .out   (if_out   ),
    .ready (if_ready ),
    .valid (if_valid )
);

/* ----------------------------------------------------------- */
//                    LOGIC REGISTERS
/* ----------------------------------------------------------- */

// N_reg

logic n_load;
logic [WIDTH-1:0] n_in, n_out;

register 
#(
    .WIDTH (WIDTH)
)
n_reg(
    .clk  (clk  ),
    .rst  (rst  ),
    .load (n_load ),
    .in   (n_in   ),
    .out  (n_out  )
);

// N_valid_reg

logic n_valid_load, n_valid_in, n_valid_out;

register 
#(
    .WIDTH (1)
) n_valid_reg (
    .clk  (clk  ),
    .rst  (rst  ),
    .load (n_valid_load ),
    .in   (n_valid_in   ),
    .out  (n_valid_out  )
);

// Register delay

logic[REGISTER_WIDTH-1:0] delay_in, delay_out;

register_delay 
#(
    .REG_WIDTH    (REGISTER_WIDTH),
    .DELAY_CYCLES (MEMORY_LATENCY)
)
u_register_delay(
    .clk (clk ),
    .rst (rst ),
    .in  (delay_in  ),
    .out (delay_out )
);

/* ----------------------------------------------------------- */
//                         COUNTERS
/* ----------------------------------------------------------- */

// C counter

logic c_rst, c_max, c_up;
logic[REGISTER_WIDTH-1:0] c_out;

counter_mod 
#(
    .MOD   (N)
)
u_c_cnt_mod(
    .rst         (rst         ),
    .clk         (clk         ),
    .reset_count (c_rst ),
    .up          (c_up ),
    .max         (c_max),
    .out         (c_out)
);

// R counter

logic r_rst, r_max, r_up;
logic[REGISTER_WIDTH-1:0] r_out, r_last;

counter_up_to 
#(
    .WIDTH (REGISTER_WIDTH)
)
u_counter_up_to(
    .clk         (clk         ),
    .rst         (rst         ),
    .reset_count (r_rst ),
    .up          (r_up          ),
    .last        (r_last        ),
    .out         (r_out         ),
    .max         (r_max         )
);

// C write counter

logic c_write_rst, c_write_max, c_write_up;
logic[REGISTER_WIDTH-1:0] c_write_out;

counter_mod 
#(
    .MOD   (N)
)
u_c_write_cnt_mod(
    .rst         (rst         ),
    .clk         (clk         ),
    .reset_count (c_write_rst ),
    .up          (c_write_up ),
    .max         (c_write_max),
    .out         (c_write_out)
);

// R write counter

logic r_write_rst, r_write_max, r_write_up;
logic[REGISTER_WIDTH-1:0] r_write_out, r_write_last;

counter_up_to 
#(
    .WIDTH (REGISTER_WIDTH)
)
u_counter_write_up_to(
    .clk         (clk         ),
    .rst         (rst         ),
    .reset_count (r_write_rst ),
    .up          (r_write_up          ),
    .last        (r_write_last        ),
    .out         (r_write_out         ),
    .max         (r_write_max         )
);

/* ----------------------------------------------------------- */
//                HARDWARE WIRE CONNECTIONS
/* ----------------------------------------------------------- */

typedef enum { s0, s1, s2, s3, s4} state_t;
state_t state_reg, state_next;


assign div_a = a_row_out[delay_out*WIDTH +: WIDTH]; 
assign div_b = n_out;
assign div_ready = a_row_valid && state_reg != 0;

assign x_write_data = div_o;
assign x_write_ready = div_valid;

logic finished_writing;
assign finished_writing = c_write_max;
assign x_write_row_addr = c_write_out;

assign r_write_last = c_write_out;
assign r_write_up = div_valid;
assign x_write_col_addr = r_write_out;
assign c_write_up = r_write_max;

assign n_valid_load = 1'b1;
assign n_valid_in = if_valid;

assign n_in = if_out;
assign n_load = if_valid;

assign if_ready = 1'b1;
assign if_in = $unsigned(NUM_SAMPLES);

logic finished_issuing;

assign finished_issuing = c_max;
assign delay_in = c_out;
assign r_last = c_out;
assign c_up = r_max;

assign a_row_addr = r_out;

logic process_item;

assign a_row_addr_ready = process_item;
assign r_up = process_item;

/* ----------------------------------------------------------- */
//                      STATE MACHINE
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
        if (n_valid_out == 1'b1)
            state_next = s2;
        else
            state_next = s1;
    s2: 
        if(finished_issuing)
            state_next = s3;
        else
            state_next = s2;
    s3:
        if(finished_writing)
            state_next = s4;
        else
            state_next = s3;
    s4:
        state_next = s0;
    endcase
end

// Outputs
always_comb begin

    c_rst = 1'b0;
    c_write_rst = 1'b0;
    finished = 1'b0;
    process_item = 1'b0;
    r_rst = 1'b0;
    r_write_rst = 1'b0;

    unique case (state_reg)
    s0: begin
            finished = 1'b0;
            c_rst = 1'b1;
            r_rst = 1'b1;
            c_write_rst = 1'b1;
            r_write_rst = 1'b1;
        end
    s1: begin
        // Empty
    end
    s2: begin
        process_item = 1'b1;
    end
    s3: begin
        // Empty
    end
    s4: begin
        finished = 1'b1; 
    end
    endcase

end



endmodule