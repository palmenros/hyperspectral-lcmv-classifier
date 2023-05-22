`timescale 1ns/10ps
`include "sim/fp_vector_printer.sv"

module tb_matrix_divider ();

    localparam NUM_ROWS = 11;
    localparam NUM_COLS = 4;

    localparam DIVIDER_LATENCY = 28;

    localparam ROW_ADDR_WIDTH = $clog2(NUM_ROWS);
    localparam COL_ADDR_WIDTH = $clog2(NUM_COLS);
    localparam ROW_SIZE = NUM_COLS * WIDTH;
    localparam COL_SIZE = NUM_ROWS * WIDTH;

    localparam WIDTH = 32;

    logic rst, clk;
    logic initializing;

    // A matrix

    logic [ROW_ADDR_WIDTH-1:0] real_row_addr;
    logic real_row_addr_ready;
    logic [COL_ADDR_WIDTH-1:0] real_col_addr;
    logic real_col_addr_ready;
    logic [ROW_ADDR_WIDTH-1:0] real_write_row_addr;
    logic [COL_ADDR_WIDTH-1:0] real_write_col_addr;
    logic [WIDTH-1:0] real_write_data;
    logic real_write_ready;

    logic [ROW_ADDR_WIDTH-1:0] ini_row_addr;
    logic ini_row_addr_ready;
    logic [COL_ADDR_WIDTH-1:0] ini_col_addr;
    logic ini_col_addr_ready;
    logic [ROW_ADDR_WIDTH-1:0] ini_write_row_addr;
    logic [COL_ADDR_WIDTH-1:0] ini_write_col_addr;
    logic [WIDTH-1:0] ini_write_data;
    logic ini_write_ready;

    logic [ROW_ADDR_WIDTH-1:0] row_addr;
    logic row_addr_ready;
    logic row_valid;
    logic [ROW_SIZE-1:0] row_out;
    logic [COL_ADDR_WIDTH-1:0] col_addr;
    logic col_addr_ready;
    logic col_valid;
    logic [COL_SIZE-1:0] col_out;
    logic [ROW_ADDR_WIDTH-1:0] write_row_addr;
    logic [COL_ADDR_WIDTH-1:0] write_col_addr;
    logic [WIDTH-1:0] write_data;
    logic write_ready;

    assign real_row_addr = initializing ? ini_row_addr : row_addr; 
    assign real_row_addr_ready = initializing ? ini_row_addr_ready : row_addr_ready; 
    assign real_col_addr = initializing ? ini_col_addr : col_addr; 
    assign real_col_addr_ready = initializing ? ini_col_addr_ready : col_addr_ready; 
    assign real_write_row_addr = initializing ? ini_write_row_addr : write_row_addr; 
    assign real_write_col_addr = initializing ? ini_write_col_addr : write_col_addr; 
    assign real_write_data = initializing ? ini_write_data : write_data; 
    assign real_write_ready = initializing ? ini_write_ready : write_ready;

    matrix 
    #(
        .NUM_ROWS          (NUM_ROWS          ),
        .NUM_COLS          (NUM_COLS          ),
        .SCALAR_BITS       (WIDTH)
    )
    u_matrix(
    	.clk            (clk            ),
        .rst            (rst            ),
        .row_addr       (real_row_addr       ),
        .row_addr_ready (real_row_addr_ready ),
        .row_valid      (row_valid      ),
        .row_out        (row_out        ),
        .col_addr       (real_col_addr       ),
        .col_addr_ready (real_col_addr_ready ),
        .col_valid      (col_valid      ),
        .col_out        (col_out        ),
        .write_row_addr (real_write_row_addr ),
        .write_col_addr (real_write_col_addr ),
        .write_data     (real_write_data     ),
        .write_ready    (real_write_ready    )
    );

    // D vector register

    logic[COL_SIZE-1:0] d_out;
    logic d_load;
    logic[COL_SIZE-1:0] d_in;
    logic[ROW_ADDR_WIDTH-1:0] d_read_index;
    logic[WIDTH-1:0] d_slice_out;
    logic[ROW_ADDR_WIDTH-1:0] d_write_index;
    logic[WIDTH-1:0] d_slice_in;
    logic d_write_slice;

    vector_reg 
    #(
        .SCALAR_BITS (WIDTH),
        .LENGTH      (NUM_ROWS)
    )
    u_vector_reg(
    	.rst         (rst         ),
        .clk         (clk         ),
        .load        (d_load        ),
        .in          (d_in          ),
        .out         (d_out         ),
        .read_index  (d_read_index  ),
        .slice_out   (d_slice_out   ),
        .write_index (d_write_index ),
        .slice_in    (d_slice_in    ),
        .write_slice (d_write_slice )
    );

    logic start, finished;

    matrix_divider 
    #(
        .NUM_ROWS        (NUM_ROWS        ),
        .NUM_COLS        (NUM_COLS        ),
        .WIDTH           (WIDTH           ),
        .DIVIDER_LATENCY (DIVIDER_LATENCY )
    )
    u_matrix_divider(
    	.clk                (clk                ),
        .rst                (rst                ),
        .start              (start              ),
        .finished           (finished           ),
        .mat_row_addr       (row_addr       ),
        .mat_row_addr_ready (row_addr_ready ),
        .mat_row_valid      (row_valid      ),
        .mat_row_out        (row_out        ),
        .mat_write_row_addr (write_row_addr ),
        .mat_write_col_addr (write_col_addr ),
        .mat_write_data     (write_data     ),
        .mat_write_ready    (write_ready    ),
        .d_read_index       (d_read_index       ),
        .d_slice_out        (d_slice_out        )
    );
    
    localparam PERIOD = 10;

    always 
    begin
        clk = 1'b1;
        #(PERIOD/2);

        clk = 1'b0;
        #(PERIOD/2);    
    end

    assign d_load = 1'b0;

    // Define matrix
    shortreal d_vector[NUM_ROWS-1:0];
    shortreal matrix[NUM_ROWS-1:0][NUM_COLS-1:0];
    shortreal output_matrix[NUM_ROWS-1:0][NUM_COLS-1:0];

    fp_vector_printer #( .LENGTH ( NUM_COLS )) v_printer ();
    fp_vector_printer #( .LENGTH ( NUM_ROWS )) v_d_printer ();

    task print_matrix;
        for (int r = 0; r < NUM_ROWS; r++) begin
                ini_row_addr = r;
                ini_row_addr_ready = 1'b1;

                #PERIOD;
                ini_row_addr_ready = 1'b0;

                wait(row_valid == 1'b1);
                #(0.25*PERIOD);

                v_printer.print_str($sformatf("Row %d: ", r), row_out);
            end

        ini_row_addr_ready = 1'b0;
    endtask

    task load_matrix_values(input string file_name, input logic print_values);
        int fd;
        int file_num_rows;
        int file_num_cols;
        shortreal element;
        shortreal d_err, mat_err;

        // Initialize the matrix
        fd = $fopen($sformatf("../../../../../src/sim_data/%s.in", file_name), "r");
        if (!fd) 
            $fatal(1, "File was NOT opened successfully");

        $fscanf(fd, "%d", file_num_rows);
        $fscanf(fd, "%d", file_num_cols);

        if (file_num_rows != NUM_ROWS)
            $fatal(1, "File has a different number of rows than set on verilog file");

        if (file_num_cols != NUM_COLS)
            $fatal(1, "File has a different number of columns than set on verilog file");


        for (int r = 0; r < NUM_ROWS; r++) begin
            $fscanf(fd, "%f", element);
            d_vector[r] = element;
        end

        for (int r = 0; r < NUM_ROWS; r++) begin
            for (int c = 0; c < NUM_COLS;c++) begin
                $fscanf(fd, "%f", element);
                matrix[r][c] = element;
            end
        end

        $fclose(fd);

        // Load d
        for (int r = 0; r < NUM_ROWS; r++) begin
            d_write_index = r;
            d_slice_in = $shortrealtobits(d_vector[r]);
            d_write_slice = 1'b1;
            #PERIOD;
        end
        
        d_write_slice = 1'b0;    

        // Load Matrix

        for (int r = 0; r < NUM_ROWS; r++) begin
            for (int c = 0; c < NUM_COLS; c++) begin
                // Set (r, c) in matrix
                ini_write_row_addr = r;
                ini_write_col_addr = c;
                
                ini_write_data = $shortrealtobits(matrix[r][c]);
                ini_write_ready = 1'b1;

                #PERIOD;
            end 
        end

        ini_write_ready = 1'b0;

        $display("Finished initializing matrix");

        if(print_values) begin
            v_d_printer.print_str("D: ", d_out);
            print_matrix;
            $display("Finished reading matrix rows");
        end
    endtask

    task test_matrix_divider(input string test_case, input logic print_original_matrix);
        int fd;
        shortreal element;
        shortreal d_err, mat_err, actual_val;

        initializing = 1'b1;
        start = 1'b0;

        load_matrix_values(test_case, print_original_matrix);

        #(2*PERIOD);

        start = 1'b1;
        initializing = 1'b0;

        #PERIOD;
        start = 1'b0;

        wait(finished == 1'b1);

        #(1.25*PERIOD);

        initializing = 1'b1;

        // Print d
        v_d_printer.print_str("D: ", d_out);
        
        for (int r = 0; r < NUM_ROWS; r++) begin
            ini_row_addr = r;
            ini_row_addr_ready = 1'b1;

            #PERIOD;
            ini_row_addr_ready = 1'b0;

            wait(row_valid == 1'b1);
            #(0.25*PERIOD);

            for(int c = 0; c < NUM_COLS; c++) begin
                output_matrix[r][c] = $bitstoshortreal(row_out[c*WIDTH +: WIDTH]); 
            end

            v_printer.print_str($sformatf("Row %d: ", r), row_out);
        end
        ini_row_addr_ready = 1'b0;

        ////////////////////////////////////
        //         Compute errors
        ////////////////////////////////////
        
        fd = $fopen($sformatf("../../../../../src/sim_data/%s.out", test_case), "r");
        if (!fd) 
            $fatal(1, "File was NOT opened successfully");

        mat_err = 0;
          for (int r = 0; r < NUM_ROWS; r++) begin
            for (int c = 0; c < NUM_COLS;c++) begin
                $fscanf(fd, "%f", element);    
                // Let's compute the relative error    
                if (element != 0)
                    mat_err += (element - output_matrix[r][c]) ** 2 / element * (element > 0 ? 1 : -1);
                else
                    mat_err += (element - output_matrix[r][c]) ** 2;
            end
        end
        mat_err /= NUM_ROWS * NUM_COLS;
        $display("Average relative squared error matrix: %f%%", mat_err * 100);
        
        $fclose(fd);
    endtask

    initial begin
        rst = 1'b1;
        initializing = 1'b1;
        start = 1'b0;

        #(2.25*PERIOD);

        rst = 1'b0;
        //test_matrix_divider("div_1", 1'b1);
        //test_matrix_divider("div_2", 1'b1);
        test_matrix_divider("div_3", 1'b1);
    end

endmodule