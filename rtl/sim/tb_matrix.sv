`timescale 1ns/10ps

module tb_matrix ();
    
    localparam NUM_ROWS = 5;
    localparam NUM_COLS = 3;
    localparam SCALAR_BITS = 32;

    localparam ROW_ADDR_WIDTH = $clog2(NUM_ROWS);
    localparam COL_ADDR_WIDTH = $clog2(NUM_COLS);
    localparam ROW_SIZE = NUM_COLS * SCALAR_BITS;
    localparam COL_SIZE = NUM_ROWS * SCALAR_BITS;

    logic clk, rst;

    // Row reading port
    logic [ROW_ADDR_WIDTH-1:0] row_addr;
    logic row_addr_ready;

    logic row_valid;
    logic [ROW_SIZE-1:0] row_out;

    // Column reading port

    logic [COL_ADDR_WIDTH-1:0] col_addr;
    logic col_addr_ready;

    logic col_valid;
    logic [COL_SIZE-1:0] col_out;

    // Element writing port
    logic [ROW_ADDR_WIDTH-1:0] write_row_addr;
    logic [COL_ADDR_WIDTH-1:0] write_col_addr;
    logic [SCALAR_BITS-1:0] write_data;
    logic write_ready;

    matrix 
    #(
        .NUM_ROWS       (NUM_ROWS ),
        .NUM_COLS       (NUM_COLS ),
        .SCALAR_BITS    (32)
    ) u_matrix(.*);

    localparam PERIOD = 10;

    always 
    begin
        clk = 1'b1;
        #(PERIOD/2);

        clk = 1'b0;
        #(PERIOD/2);    
    end

    initial begin
        rst = 1'b1;

        #(2.25*PERIOD);

        row_addr_ready = 1'b0;
        col_addr_ready = 1'b0;
        rst = 1'b0;

        // Fill up matrix

        for (int r = 0; r < NUM_ROWS; r++) begin
            for (int c = 0; c < NUM_COLS; c++) begin
                // Set (r, c) in matrix
                write_row_addr = r;
                write_col_addr = c;
                
                write_data = c + r * NUM_COLS;
                write_ready = 1'b1;

                #PERIOD;
            end 
        end

        write_ready = 1'b0;

        $display("Finished initializing matrix");

        // Read cols
        for (int c = 0; c < NUM_COLS; c++) begin
            col_addr = c;
            col_addr_ready = 1'b1;

            #PERIOD;
            col_addr_ready = 1'b0;

            wait(col_valid == 1'b1);
            #(0.25*PERIOD);

            $displayh("Col %d: %0h", c, col_out);
        end

        col_addr_ready = 1'b0;

        $display("Finished reading columns");

        // Read rows
        for (int r = 0; r < NUM_ROWS; r++) begin
            row_addr = r;
            row_addr_ready = 1'b1;

            #PERIOD;

            row_addr_ready = 1'b0;

            wait(row_valid == 1'b1);
            #(0.25*PERIOD);

            $displayh("Row %d: %0h", r, row_out);
        end

        row_addr_ready = 1'b0;

        $display("Finished reading rows");

    end

endmodule