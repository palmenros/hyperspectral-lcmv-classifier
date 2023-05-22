module matrix #(    
    parameter NUM_ROWS = 3, /* Number of rows this matrix will have */
    parameter NUM_COLS = 5, /* Number of columns this matrix will have */
    parameter SCALAR_BITS = 32, /* Size in bits of each scalar of the matrix */
    parameter MEMORY_LATENCY = 2, /* Latency in cycles of the memory */

    localparam ROW_ADDR_WIDTH = $clog2(NUM_ROWS),
    localparam COL_ADDR_WIDTH = $clog2(NUM_COLS),
    localparam ROW_SIZE = NUM_COLS * SCALAR_BITS,
    localparam COL_SIZE = NUM_ROWS * SCALAR_BITS
) (

    // Global clock
    input logic clk,
    input logic rst,

    // Row reading port
    input logic [ROW_ADDR_WIDTH-1:0] row_addr,
    input logic row_addr_ready,

    output logic row_valid,
    output logic [ROW_SIZE-1:0] row_out,

    // Column reading port

    input logic [COL_ADDR_WIDTH-1:0] col_addr,
    input logic col_addr_ready,

    output logic col_valid,
    output logic [COL_SIZE-1:0] col_out,

    // Element writing port
    input logic [ROW_ADDR_WIDTH-1:0] write_row_addr,
    input logic [COL_ADDR_WIDTH-1:0] write_col_addr,
    input logic [SCALAR_BITS-1:0] write_data,
    input logic write_ready
);

    // Row

    logic [NUM_COLS-1:0] write_enable_cols;

    genvar col;
    generate
        for (col = 0; col < NUM_COLS; col++) begin
            // Generate a column memory with:
            // - Data width: SCALAR_BITS
            // - Data depth: NUM_ROWS
            localparam COL_OUT_IDX_START = (col+1)*SCALAR_BITS-1;
            localparam COL_OUT_IDX_END = col*SCALAR_BITS;

            assign write_enable_cols[col] = ( write_col_addr == col ) ? 1'b1 : 1'b0;

            simple_dual_port_mem #(
                .DEPTH (NUM_ROWS),
                .DATA_WIDTH (SCALAR_BITS),
                .LATENCY (MEMORY_LATENCY)
            ) u_simple_dual_port_mem_cols (
                // Row reading port
                .clkb  (clk),
                .enb   (1'b1),
                .addrb (row_addr),
                .doutb ( row_out[COL_OUT_IDX_START:COL_OUT_IDX_END] ),

                // Element writing port
                .clka  (clk),
                .ena   (write_ready),
                .wea   (write_enable_cols[col]),
                .addra (write_row_addr),
                .dina  (write_data)
            );
        end
    endgenerate 
    
    register_delay 
    #(
        .REG_WIDTH    (1),
        .DELAY_CYCLES (MEMORY_LATENCY)
    )
    u_row_valid_delay(
    	.clk (clk ),
        .rst (rst ),
        .in  (row_addr_ready),
        .out (row_valid)
    );
    
    // Columns

    logic [NUM_ROWS-1:0] write_enable_rows;

    genvar row;
    generate
        for (row = 0; row < NUM_ROWS; row++) begin
            // Generate a column memory with:
            // - Data width: SCALAR_BITS
            // - Data depth: NUM_COLS
            localparam ROW_OUT_IDX_START = (row+1)*SCALAR_BITS-1;
            localparam ROW_OUT_IDX_END = row*SCALAR_BITS;

            assign write_enable_rows[row] = ( write_row_addr == row ) ? 1'b1 : 1'b0;

            simple_dual_port_mem #(
                .DEPTH (NUM_COLS),
                .DATA_WIDTH (SCALAR_BITS),
                .LATENCY (MEMORY_LATENCY)
            ) u_simple_dual_port_mem_rows (
                // Row reading port
                .clkb  (clk),
                .enb  (1'b1),
                .addrb (col_addr),
                .doutb (col_out[ROW_OUT_IDX_START:ROW_OUT_IDX_END] ),

                // Element writing port
                .clka  (clk),
                .ena   (write_ready),
                .wea   (write_enable_rows[row]),
                .addra (write_col_addr),
                .dina  (write_data)
            );
        end
    endgenerate 

    register_delay 
    #(
        .REG_WIDTH    (1),
        .DELAY_CYCLES (MEMORY_LATENCY)
    )
    u_col_valid_delay(
    	.clk (clk ),
        .rst (rst ),
        .in  (col_addr_ready),
        .out (col_valid)
    );
endmodule