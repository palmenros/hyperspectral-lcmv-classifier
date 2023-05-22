// Receives row by row (element by element) a matrix X
// After this module is finished, R = X' * X
module correlation_matrix #(    
    
    parameter N = 11, /* Number of total samples (pixels) */
    parameter M = 5,  /* Number of datapoints (channels) per sample (pixel) */

    parameter WIDTH = 32, /* Size in bits of each scalar of the matrix */
    parameter MEMORY_LATENCY = 2,
    parameter MULTIPLIER_LATENCY = 8,
    parameter ADDER_LATENCY = 11,

    parameter X_NUM_ROWS = N,
    parameter X_NUM_COLS = M,

    parameter R_NUM_ROWS = M,
    parameter R_NUM_COLS = M,

    localparam R_ROW_ADDR_WIDTH = $clog2(R_NUM_ROWS),
    localparam R_ROW_SIZE = R_NUM_COLS * WIDTH,

    localparam I_REGISTER_WIDTH = $clog2(N),
    localparam J_REGISTER_WIDTH = $clog2(M)
) (

    // Global clock
    input logic clk,
    input logic rst,

    output logic finished,

    /* ----------------------------------------------------------- */
    //                   DATA STREAM BUS
    /* ----------------------------------------------------------- */

    output logic ds_next_data, /* If ds_next_data = 1, we are ready to accept a new data from the bus */
    input logic[WIDTH-1:0] ds_out,   /* Stream data from the bus */
    input logic ds_valid,      /* If ds_valid = 1, ds_out is valid */

    /* ----------------------------------------------------------- */
    //                   MATRIX MEMORY PORTS
    /* ----------------------------------------------------------- */
    
    // This module does NOT instantiate a matrix memory, it gets ports to interact 
    // with an already instantiated matrix

    // Row reading port
    output logic [R_ROW_ADDR_WIDTH-1:0] r_row_addr,
    output logic r_row_addr_ready,

    input logic r_row_valid,
    input logic [R_ROW_SIZE-1:0] r_row_out,

    //Row writing port
    output logic [R_ROW_ADDR_WIDTH-1:0] r_write_row_addr,
    output logic [R_ROW_SIZE-1:0] r_write_data,
    output logic r_write_ready,

    /* ----------------------------------------------------------- */
    //                  FP VECTOR MULT ALU PORTS
    /* ----------------------------------------------------------- */

    // If dot_product_mode = 1, the ALU will be configured to act as the dot product,
    // else, it will act as a vector multiplier
    output logic dot_product_mode,
    output logic vector_mult_alu_ready,

    output logic [R_ROW_SIZE-1:0] vector_mult_in_a,
    output logic [R_ROW_SIZE-1:0] vector_mult_in_b, 
    input logic [R_ROW_SIZE-1:0] vector_mult_out,
    input logic vector_mult_valid

    // We don't need the dot product ports

    // This module does NOT instantiate a fp vector multiplication ALU, it gets ports to interact 
    // with an already instantiated fp vector multiplication ALU

    // output logic [WIDTH*N-1:0] dot_product_a,
    // output logic [WIDTH*N-1:0] dot_product_b,
    // output logic [WIDTH-1:0] dot_product_c,

    // dot_product_out = a*b+c
    // input logic [WIDTH-1:0] dot_product_out,

    // We don't have to sum all the entries of the vectors, we have a logic per element that tells us
    // if we need to take into account that element for the dot product
    // output logic [N-1:0] dot_product_enable,

    // input logic dot_product_valid,
);


/* ----------------------------------------------------------- */
//                  VECTOR REGISTERS
/* ----------------------------------------------------------- */

// d
localparam D_VECTOR_LENGTH = M;
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
//                    ARITHMETIC HARDWARE
/* ----------------------------------------------------------- */

logic [R_ROW_SIZE-1:0] va_a, va_b, va_out;
logic va_ready, va_valid;

fp_vector_adder 
#(
    .WIDTH      (WIDTH      ),
    .NUM_INPUTS (M),
    .LATENCY    (ADDER_LATENCY )
)
u_fp_vector_adder(
    .clk   (clk   ),
    .rst   (rst   ),
    .a     (va_a  ),
    .b     (va_b  ),
    .o     (va_out),
    .ready (va_ready ),
    .valid (va_valid )
);

logic[WIDTH-1:0] sv_in;
logic[R_ROW_SIZE-1:0] sv_out;

scalar_to_vector 
#(
    .WIDTH         (WIDTH),
    .VECTOR_LENGTH (M)
)
u_scalar_to_vector(
    .scalar_in  (sv_in ),
    .vector_out (sv_out)
);

/* ----------------------------------------------------------- */
//                CONTROL REGISTERS
/* ----------------------------------------------------------- */

logic lf_load, lf_in, lf_out;

register 
#(
    .WIDTH (1)
)
load_finished_reg(
    .clk  (clk  ),
    .rst  (rst  ),
    .load (lf_load ),
    .in   (lf_in   ),
    .out  (lf_out  )
);

logic mdi_load, mdi_in, mdi_out;

register 
#(
    .WIDTH (1)
)
u_register(
    .clk  (clk  ),
    .rst  (rst  ),
    .load (mdi_load ),
    .in   (mdi_in   ),
    .out  (mdi_out  )
);

logic reg_delay_in, reg_delay_out;

register_delay 
#(
    .REG_WIDTH    (1),
    .DELAY_CYCLES (MULTIPLIER_LATENCY - MEMORY_LATENCY )
)
u_register_delay(
    .clk (clk ),
    .rst (rst ),
    .in  (reg_delay_in  ),
    .out (reg_delay_out )
);


/* ----------------------------------------------------------- */
//                     INDEX REGISTERS
/* ----------------------------------------------------------- */

// i_cnt

logic i_rst, i_up, i_max;
logic[I_REGISTER_WIDTH-1:0] i_out;

counter_mod 
#(
    .MOD   (N)
)
i_cnt (
    .rst         (rst   ),
    .clk         (clk   ),
    .reset_count (i_rst ),
    .up          (i_up  ),
    .max         (i_max ),
    .out         (i_out )
);

// j_cnt

logic j_rst, j_up, j_max;
logic[J_REGISTER_WIDTH-1:0] j_out;

counter_mod 
#(
    .MOD   (M)
)
j_cnt (
    .rst         (rst   ),
    .clk         (clk   ),
    .reset_count (j_rst ),
    .up          (j_up  ),
    .max         (j_max ),
    .out         (j_out )
);

// j_mem_read_cnt

logic j_mem_read_rst, j_mem_read_up, j_mem_read_max;
logic[J_REGISTER_WIDTH-1:0] j_mem_read_out;

counter_mod 
#(
    .MOD   (M)
)
j_mem_read_cnt (
    .rst         (rst   ),
    .clk         (clk   ),
    .reset_count (j_mem_read_rst ),
    .up          (j_mem_read_up  ),
    .max         (j_mem_read_max ),
    .out         (j_mem_read_out )
);

// j_mem_out_cnt

logic j_mem_out_rst, j_mem_out_up, j_mem_out_max;
logic[J_REGISTER_WIDTH-1:0] j_mem_out_out;

counter_mod 
#(
    .MOD   (M)
)
j_mem_out_cnt (
    .rst         (rst   ),
    .clk         (clk   ),
    .reset_count (j_mem_out_rst ),
    .up          (j_mem_out_up  ),
    .max         (j_mem_out_max ),
    .out         (j_mem_out_out )
);

// j_mem_write_cnt

logic j_mem_write_rst, j_mem_write_up, j_mem_write_max;
logic[J_REGISTER_WIDTH-1:0] j_mem_write_out;

counter_mod 
#(
    .MOD   (M)
)
j_mem_write_cnt (
    .rst         (rst   ),
    .clk         (clk   ),
    .reset_count (j_mem_write_rst ),
    .up          (j_mem_write_up  ),
    .max         (j_mem_write_max ),
    .out         (j_mem_write_out )
);

// i_mem_write_cnt

logic i_mem_write_rst, i_mem_write_up, i_mem_write_max;
logic[I_REGISTER_WIDTH-1:0] i_mem_write_out;

counter_mod 
#(
    .MOD   (N)
)
i_mem_write_cnt (
    .rst         (rst   ),
    .clk         (clk   ),
    .reset_count (i_mem_write_rst ),
    .up          (i_mem_write_up  ),
    .max         (i_mem_write_max ),
    .out         (i_mem_write_out )
);

// stream_load_index_cnt

logic sl_rst, sl_up, sl_max;
logic[J_REGISTER_WIDTH-1:0] sl_out;

counter_mod 
#(
    .MOD   (M)
)
u_stream_load_index_cnt (
    .rst         (rst         ),
    .clk         (clk         ),
    .reset_count (sl_rst ),
    .up          (sl_up ),
    .max         (sl_max),
    .out         (sl_out)
);

/* ----------------------------------------------------------- */
//                HARDWARE WIRE CONNECTIONS
/* ----------------------------------------------------------- */

assign r_row_addr = j_mem_read_out;
assign r_row_addr_ready = reg_delay_out;
assign r_write_row_addr = j_mem_write_out;
assign r_write_ready = va_valid;
assign r_write_data = va_out;

assign j_mem_out_up = r_row_valid;
assign va_a = mdi_out ? '0 : r_row_out;

logic mdi_rst;
assign mdi_load = mdi_rst || j_mem_out_max;
assign mdi_in = mdi_rst;

assign j_mem_read_up = reg_delay_out;

assign va_b = vector_mult_out;
assign va_ready = vector_mult_valid;
assign j_mem_write_up = va_valid;

logic wrote_something;
assign wrote_something = j_mem_write_out != '0;

logic finished_writing_everything;
assign finished_writing_everything = j_mem_write_max && i_mem_write_max;
assign i_mem_write_up = j_mem_write_max;

logic process_item;

assign vector_mult_in_a = sv_out;
assign vector_mult_in_b = d_out;
assign vector_mult_alu_ready = process_item;
assign dot_product_mode = 1'b0;

assign sv_in = d_slice_out;
assign reg_delay_in = process_item;

assign i_up = j_max;

logic finished_issuing_batch;
assign finished_issuing_batch = j_max;

logic final_batch;
assign final_batch = i_max;
assign j_up = process_item;

assign d_read_index = j_out;
assign d_write_index = sl_out;
assign d_slice_in = ds_out;

assign d_write_slice = ds_valid && ds_next_data;
assign sl_up = ds_valid && ds_next_data;

logic should_load;
logic load_finished;

assign ds_next_data = should_load && !load_finished;

assign load_finished = lf_out;

logic lf_rst;

assign lf_in = lf_rst ? 0 : 1;
assign lf_load = lf_rst ? 1 : (sl_max && sl_up);

/* ----------------------------------------------------------- */
//                      STATE MACHINE
/* ----------------------------------------------------------- */

typedef enum { s0, s1, s2, s3, s4, s5} state_t;
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
        if (ds_valid) 
            state_next = s1;
        else
            state_next = s0;
    s1:
        if (load_finished) 
            state_next = s2;
        else
            state_next = s1;
    s2:
        if (finished_issuing_batch) begin
            if (final_batch)
                state_next = s3;
            else
                state_next = s5;
        end else begin
            state_next = s2;
        end   
    s3:
        if (finished_writing_everything)
            state_next = s4;
        else
            state_next = s3;
    s4:
        state_next = s0;
    s5:
        if(wrote_something)
            state_next = s1;
        else
            state_next = s5;
    endcase
end

// Outputs
always_comb begin
    
    finished = 1'b0;
    i_mem_write_rst = 1'b0;
    i_rst = 1'b0;
    j_mem_out_rst = 1'b0;
    j_mem_read_rst = 1'b0;
    j_mem_write_rst = 1'b0;
    j_rst = 1'b0;
    lf_rst = 1'b0;
    mdi_rst = 1'b0;
    process_item = 1'b0;
    should_load = 1'b0;
    sl_rst = 1'b0;

    unique case (state_reg)
    s0: begin
        i_mem_write_rst = 1'b1;
        i_rst = 1'b1;
        j_mem_out_rst = 1'b1;
        j_mem_read_rst = 1'b1;
        j_mem_write_rst = 1'b1;
        j_rst = 1'b1;
        lf_rst = 1'b1;
        mdi_rst = 1'b1;
        sl_rst = 1'b1;
    
        finished = 1'b0;
        should_load = 1'b0;
        end
    s1: begin
        should_load = 1'b1;
        lf_rst = load_finished;
    end
    s2: begin
        process_item = 1'b1;
        should_load = !final_batch;
    end
    s3: begin
        process_item = 1'b0;
        should_load = 1'b0;
    end
    s4: begin
        finished = 1'b1;
    end
    s5: begin
        process_item = 1'b0;
        should_load = 1'b1;
    end
    endcase

end

endmodule