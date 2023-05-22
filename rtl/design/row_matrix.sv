module row_matrix #(    
    parameter NUM_ROWS = 3, /* Number of rows this matrix will have */
    parameter NUM_COLS = 5, /* Number of columns this matrix will have */
    parameter SCALAR_BITS = 32, /* Size in bits of each scalar of the matrix */
    parameter MEMORY_LATENCY = 2, /* Latency in cycles of the memory */

    localparam ROW_ADDR_WIDTH = $clog2(NUM_ROWS),
    localparam ROW_SIZE = NUM_COLS * SCALAR_BITS
) (

    // Global clock
    input logic clk,
    input logic rst,

    // Row reading port
    input logic [ROW_ADDR_WIDTH-1:0] row_addr,
    input logic row_addr_ready,

    output logic row_valid,
    output logic [ROW_SIZE-1:0] row_out,

    //Row writing port
    input logic [ROW_ADDR_WIDTH-1:0] write_row_addr,
    input logic [ROW_SIZE-1:0] write_data,
    input logic write_ready
);

simple_dual_port_mem 
#(
    .DEPTH      (NUM_ROWS),
    .DATA_WIDTH (ROW_SIZE),
    .LATENCY    (MEMORY_LATENCY)
)
u_simple_dual_port_mem(
    .clka  (clk  ),
    .ena   (1'b1),
    .wea   (write_ready),
    .addra (write_row_addr),
    .dina  (write_data),

    .clkb  (clk  ),
    .enb   (1'b1),
    .addrb (row_addr),
    .doutb (row_out)
);

register_delay 
#(
    .REG_WIDTH    (1),
    .DELAY_CYCLES (MEMORY_LATENCY)
)
u_col_valid_delay(
    .clk (clk ),
    .rst (rst ),
    .in  (row_addr_ready),
    .out (row_valid)
);

endmodule