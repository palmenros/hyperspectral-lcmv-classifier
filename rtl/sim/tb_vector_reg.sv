`timescale 1ns/10ps

module tb_vector_reg ();
    
    localparam NUM_ROWS = 3;
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

    // Vector reg logic
    logic reg_load, reg_write_slice;
    logic[ROW_SIZE-1:0] reg_out;
    logic[ROW_ADDR_WIDTH-1:0] reg_read_index, reg_write_index;
    logic[SCALAR_BITS-1:0] reg_slice_out, reg_slice_in;

    matrix 
    #(
        .NUM_ROWS          (NUM_ROWS),
        .NUM_COLS          (NUM_COLS),
        .SCALAR_BITS       (32 )
    )
    u_matrix(
    	.clk            (clk            ),
        .rst            (rst            ),
        .row_addr       (row_addr       ),
        .row_addr_ready (row_addr_ready ),
        .row_valid      (row_valid      ),
        .row_out        (row_out        ),
        .col_addr       (col_addr       ),
        .col_addr_ready (col_addr_ready ),
        .col_valid      (col_valid      ),
        .col_out        (col_out        ),
        .write_row_addr (write_row_addr ),
        .write_col_addr (write_col_addr ),
        .write_data     (write_data     ),
        .write_ready    (write_ready    )
    );
    
 vector_reg 
 #(
    .SCALAR_BITS (SCALAR_BITS ),
    .LENGTH      (NUM_ROWS      )
 )
 u_vector_reg(
 	.rst         (rst         ),
    .clk         (clk         ),
    .load        (reg_load        ),
    .in          (row_out         ),
    .out         (reg_out         ),
    .read_index  (reg_read_index  ),
    .slice_out   (reg_slice_out   ),
    .write_index (reg_write_index ),
    .slice_in    (reg_slice_in    ),
    .write_slice (reg_write_slice )
 );
 
    
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
        reg_load = 1'b0;
        reg_write_slice = 1'b0;

        #(2.25*PERIOD);

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
            assert(col_valid == 1'b1);
            $displayh("Col %d: %0h", c, col_out);
        end

        col_addr_ready = 1'b0;

        $display("Finished reading columns");

        // Read rows
        for (int r = 0; r < NUM_ROWS; r++) begin
            row_addr = r;
            row_addr_ready = 1'b1;

            #PERIOD;
            assert(row_valid == 1'b1);
            $displayh("Row %d: %0h", r, row_out);
        end

        row_addr_ready = 1'b0;

        $display("Finished reading rows");

        #(2*PERIOD);

        row_addr = 1;
        row_addr_ready = 1'b1;

        #PERIOD;

        assert(row_valid == 1'b1);
        
        reg_load = 1'b1;

        $displayh("Row: ", row_out);

        #PERIOD;

        $displayh("Reg: %0h", reg_out);

        reg_load = 1'b0;
        row_addr_ready = 1'b0;

        #PERIOD;

        for (int c = 0; c < NUM_COLS; c++) begin
            reg_read_index = c;

            #PERIOD;
            $displayh("reg[%d]: %0h", c, reg_slice_out);
        end

        for (int c = 0; c < NUM_COLS; c++) begin
            reg_write_slice = 1'b1;
            reg_write_index = c;
            reg_slice_in = c;

            #PERIOD;
            reg_write_slice = 1'b0;

            for (int c2 = 0; c2 < NUM_COLS; c2++) begin
                reg_read_index = c2;

                #PERIOD;
                $displayh("(%d) reg[%d]: %0h", c, c2, reg_slice_out);
            end

        end


    end

endmodule