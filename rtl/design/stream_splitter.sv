module stream_splitter #(
    parameter WIDTH = 32,

    parameter NUM_ELEMENTS_FIRST_OUTPUT = 55
) (
    input logic clk,
    input logic rst,

    /* ----------------------------------------------------------- */
    //             INPUT DATA STREAM BUS A
    /* ----------------------------------------------------------- */

    output logic ds_in_next_data,       /* If ds_next_data = 1, we are ready to accept new data from the bus */
    input logic[WIDTH-1:0] ds_in_out,   /* Stream data from the bus */
    input logic ds_in_valid,            /* If ds_valid = 1, ds_out is valid */
    input logic ds_in_last,             /* If ds_last = 1, this is the last element of the matrix (asserted in the same cycle that its respective ds_out and ds_valid) */

    /* ----------------------------------------------------------- */
    //             OUTPUT DATA STREAM BUS A
    /* ----------------------------------------------------------- */

    input logic ds_out_a_next_data,       /* If ds_next_data = 1, we are ready to accept new data from the bus */
    output logic[WIDTH-1:0] ds_out_a,   /* Stream data from the bus */
    output logic ds_out_a_valid,            /* If ds_valid = 1, ds_out is valid */
    output logic ds_out_a_last,             /* If ds_last = 1, this is the last element of the matrix (asserted in the same cycle that its respective ds_out and ds_valid) */

    /* ----------------------------------------------------------- */
    //             OUTPUT DATA STREAM BUS B
    /* ----------------------------------------------------------- */

    input logic ds_out_b_next_data,       /* If ds_next_data = 1, we are ready to accept new data from the bus */
    output logic[WIDTH-1:0] ds_out_b,   /* Stream data from the bus */
    output logic ds_out_b_valid,            /* If ds_valid = 1, ds_out is valid */
    output logic ds_out_b_last             /* If ds_last = 1, this is the last element of the matrix (asserted in the same cycle that its respective ds_out and ds_valid) */
);

// Counter mod

logic cnt_rst_count, cnt_up, cnt_max;

counter_mod 
#(
    .MOD   (NUM_ELEMENTS_FIRST_OUTPUT)
)
u_counter_mod(
    .rst         (rst         ),
    .clk         (clk         ),
    .reset_count (cnt_rst_count ),
    .up          (cnt_up          ),
    .max         (cnt_max         ),
    .out         ()
);

    
typedef enum { ds_a, ds_b } out_ds_t;
out_ds_t out_ds;

// Real last (last and transaction made)
logic real_last = ds_in_last && ds_in_valid && ds_out_a_next_data;

always_ff @( posedge clk ) begin
    if (rst) begin
        out_ds <= ds_a;
    end else if (cnt_max) begin
        out_ds <= ds_b;
    end else if (real_last) begin
        out_ds <= ds_a;
    end
end

assign cnt_rst_count = real_last;
assign cnt_up = ds_out_a_next_data && ds_out_a_valid;

assign ds_out_a_last = cnt_max;
assign ds_out_a_valid = (out_ds == ds_a) && ds_in_valid;

assign ds_in_next_data = (out_ds == ds_a) ? ds_out_a_next_data : ds_out_b_next_data;

assign ds_out_b_last = ds_in_last;
assign ds_out_b_valid = (out_ds == ds_b) && ds_in_valid;


assign ds_out_a = ds_in_out;
assign ds_out_b = ds_in_out;

endmodule