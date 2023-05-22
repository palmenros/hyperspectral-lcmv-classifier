module axis_test_rom_reader #(
    parameter string ROM_NAME = "test_w_1", 
    parameter DEPTH = 33,
    parameter WIDTH = 32,
    parameter ROM_MEMORY_LATENCY = 2
) (
    input logic clk,
    input logic rst,

    input logic start,  /* Must only be active for a cycle. After start=1, the bus will be ready to read the matrix */

    /* ----------------------------------------------------------- */
    //                   DATA STREAM BUS
    /* ----------------------------------------------------------- */

    input logic ds_next_data,
    output logic[WIDTH-1:0] ds_out,
    output logic ds_valid,
    output logic ds_last
);

localparam ROM_ADDR_WIDTH = $clog2(DEPTH);

typedef enum { waiting_for_start, running } state_t;
state_t state;

always_ff @( posedge clk ) begin
    if (rst) begin
        state <= waiting_for_start;
    end else begin
        state <= state;
        unique case (state)
            waiting_for_start:  begin
                if (start) begin
                    state <= running;
                end
            end
            running: begin
                if (ds_last) begin
                    state <= waiting_for_start;
                end
            end
        endcase 
        
    end
end

logic axis_transaction_made;
assign axis_transaction_made = ds_valid && ds_next_data;

logic[ROM_ADDR_WIDTH-1:0] cnt_out;

counter_mod 
#(
    .MOD   (DEPTH)
)
u_counter_mod(
    .rst         (rst         ),
    .clk         (clk         ),
    .reset_count (start),
    .up          (axis_transaction_made),
    .max         (ds_last),
    .out         (cnt_out)
);


logic rom_ready, rom_valid;

test_rom 
#(
    .DEPTH    (DEPTH),
    .ROM_NAME (ROM_NAME),
    .WIDTH (WIDTH),
    .MEMORY_LATENCY (ROM_MEMORY_LATENCY)
)
u_test_rom(
    .clk   (clk   ),
    .rst   (rst   ),
    .ready (rom_ready ),
    .valid (rom_valid ),
    .addr  (cnt_out  ),
    .dout  (ds_out  )
);

logic current_rom_output_valid;

logic delayed_axis_transaction_made;

logic reg_delay_input;
assign reg_delay_input = (state == running && axis_transaction_made && !ds_last) || (state == waiting_for_start && start == 1'b1);

register_delay 
#(
    .REG_WIDTH    (1),
    .DELAY_CYCLES (ROM_MEMORY_LATENCY)
)
u_register_delay(
    .clk (clk ),
    .rst (rst ),
    .in  (reg_delay_input),
    .out (delayed_axis_transaction_made )
);

set_reset_reg u_set_reset_reg(
    .clk   (clk   ),
    .rst   (rst   ),
    .set   (delayed_axis_transaction_made   ),
    .reset (axis_transaction_made),
    .out   (current_rom_output_valid)
);


assign ds_valid = (state == running) && current_rom_output_valid;

endmodule