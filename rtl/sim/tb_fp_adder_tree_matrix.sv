`include "sim/fp_vector_printer.sv"

`timescale 1ns/10ps

// Sum columns and rows of a matrix
module tb_fp_adder_tree_matrix ();

    localparam NUM_ROWS = 3;
    localparam NUM_COLS = 5;
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

    localparam FP_ADDER_LATENCY = 11;
    logic [NUM_COLS * SCALAR_BITS-1:0] adder_row_in;
    logic [SCALAR_BITS-1:0] adder_row_out;

    logic adder_row_ready;
    logic adder_row_valid;

    fp_adder_tree 
    #(
        .WIDTH                   (SCALAR_BITS),
        .NUM_INPUTS              (NUM_COLS),
        .FP_ADDER_LATENCY        (FP_ADDER_LATENCY ),
        .PIPELINE_BETWEEN_STAGES (1)
    ) u_fp_adder_tree_row_sum (
    	.clk   (clk   ),
        .rst   (rst   ),
        .in    (adder_row_in    ),
        .out   (adder_row_out   ),
        .ready (adder_row_ready ),
        .valid (adder_row_valid )
    );
    
    // Vector printer

    fp_vector_printer #( .LENGTH ( NUM_ROWS )) col_printer ();
    fp_vector_printer #( .LENGTH ( NUM_COLS )) row_printer ();

    // Tasks

    localparam PERIOD = 10;

    always 
    begin
        clk = 1'b1;
        #(PERIOD/2);

        clk = 1'b0;
        #(PERIOD/2);    
    end

    initial begin
        string strvar;

        rst = 1'b1;

        #(3.25*PERIOD);

        rst = 1'b0;

        #(2*PERIOD);

        // Fill up matrix

        for (int r = 0; r < NUM_ROWS; r++) begin
            for (int c = 0; c < NUM_COLS; c++) begin
                // Set (r, c) in matrix
                write_row_addr = r;
                write_col_addr = c;
                
                write_data = $shortrealtobits(shortreal'(c + r * NUM_COLS));
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
            
            //$displayh("Col %d: %0h", c, col_out);
            col_printer.print_str($sformatf("Col %d: ", c), col_out);
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

            //$displayh("Row %d: %0h", r, row_out);
            row_printer.print_str($sformatf("Row %d: ", r), row_out);

            // Sum row
            adder_row_in = row_out;
            adder_row_ready = 1'b1;

            #PERIOD;

            adder_row_ready = 1'b0;

            wait(adder_row_valid == 1'b1);

            #(0.25*PERIOD);

            assert(adder_row_valid);
            $display("Sum: %f", $bitstoshortreal(adder_row_out));
        end

        row_addr_ready = 1'b0;

        $display("Finished reading rows");

        // Sum columns


    end

endmodule