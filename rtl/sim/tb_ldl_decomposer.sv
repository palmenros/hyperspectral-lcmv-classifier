`timescale 1ns/10ps
`include "sim/fp_vector_printer.sv"

module tb_ldl_decomposer ();
    
    localparam NUM_ROWS = 4;
    localparam WIDTH = 32;

    localparam ROW_ADDR_WIDTH = $clog2(NUM_ROWS);
    localparam ROW_SIZE = NUM_ROWS * WIDTH;

    logic clk, rst;

    // Row reading port
    logic [ROW_ADDR_WIDTH-1:0] row_addr;
    logic row_addr_ready;

    logic initializing;

    logic [ROW_ADDR_WIDTH-1:0] ini_row_addr;
    logic ini_row_addr_ready;
    
    logic [ROW_ADDR_WIDTH-1:0] real_row_addr;
    logic real_row_addr_ready;
    
    assign real_row_addr = initializing ? ini_row_addr : row_addr;
    assign real_row_addr_ready = initializing ? ini_row_addr_ready : row_addr_ready;

    logic [ROW_ADDR_WIDTH-1:0] ini_write_row_addr;
    logic [ROW_ADDR_WIDTH-1:0] ini_write_col_addr;
    logic [WIDTH-1:0] ini_write_data;
    logic ini_write_ready;

    logic [ROW_ADDR_WIDTH-1:0] real_write_row_addr;
    logic [ROW_ADDR_WIDTH-1:0] real_write_col_addr;
    logic [WIDTH-1:0] real_write_data;
    logic real_write_ready;

    assign real_write_row_addr = initializing ? ini_write_row_addr : write_row_addr;
    assign real_write_col_addr = initializing ? ini_write_col_addr : write_col_addr;
    assign real_write_data = initializing ? ini_write_data : write_data;
    assign real_write_ready = initializing ? ini_write_ready : write_ready;

    logic row_valid;
    logic [ROW_SIZE-1:0] row_out;

    // Column reading port

    logic [ROW_ADDR_WIDTH-1:0] col_addr;
    logic col_addr_ready;

    logic col_valid;
    logic [ROW_SIZE-1:0] col_out;

    // Element writing port
    logic [ROW_ADDR_WIDTH-1:0] write_row_addr;
    logic [ROW_ADDR_WIDTH-1:0] write_col_addr;
    logic [WIDTH-1:0] write_data;
    logic write_ready;

    matrix 
    #(
        .NUM_ROWS          (NUM_ROWS          ),
        .NUM_COLS          (NUM_ROWS          ),
        .SCALAR_BITS       (WIDTH       )
    )
    u_matrix(
    	.clk            (clk            ),
        .rst            (rst            ),
        .row_addr       (real_row_addr       ),
        .row_addr_ready (real_row_addr_ready ),
        .row_valid      (row_valid      ),
        .row_out        (row_out        ),
        .col_addr       (col_addr       ),
        .col_addr_ready (col_addr_ready ),
        .col_valid      (col_valid      ),
        .col_out        (col_out        ),
        .write_row_addr (real_write_row_addr ),
        .write_col_addr (real_write_col_addr ),
        .write_data     (real_write_data     ),
        .write_ready    (real_write_ready    )
    );

    logic [WIDTH*NUM_ROWS-1:0] dot_product_a;
    logic [WIDTH*NUM_ROWS-1:0] dot_product_b;
    logic [WIDTH-1:0] dot_product_c;
    logic [WIDTH-1:0] dot_product_out;
    logic [NUM_ROWS-1:0] dot_product_enable;
    logic [WIDTH*NUM_ROWS-1:0] vector_mult_in_a;
    logic [WIDTH*NUM_ROWS-1:0] vector_mult_in_b; 
    logic [WIDTH*NUM_ROWS-1:0] vector_mult_out;
    logic vector_mult_alu_ready;
    logic dot_product_valid;
    logic vector_mult_valid;
    logic dot_product_mode;

    fp_vector_mult_alu 
    #(
        .WIDTH                                  (WIDTH   ),
        .NUM_INPUTS                             (NUM_ROWS)
    )
    u_fp_vector_mult_alu(
    	.clk                (clk                ),
        .rst                (rst                ),
        .dot_product_a      (dot_product_a      ),
        .dot_product_b      (dot_product_b      ),
        .dot_product_c      (dot_product_c      ),
        .dot_product_out    (dot_product_out    ),
        .dot_product_enable (dot_product_enable ),
        .vector_mult_in_a   (vector_mult_in_a   ),
        .vector_mult_in_b   (vector_mult_in_b   ),
        .vector_mult_out    (vector_mult_out    ),
        .ready              (vector_mult_alu_ready),
        .dot_product_valid  (dot_product_valid  ),
        .vector_mult_valid  (vector_mult_valid  ),
        .dot_product_mode   (dot_product_mode   )
    );

    logic[ROW_SIZE-1:0] d_out;
    logic d_load;
    logic[ROW_SIZE-1:0] d_in;
    logic[ROW_ADDR_WIDTH-1:0] d_read_index;
    logic[WIDTH-1:0] d_slice_out;
    logic[ROW_ADDR_WIDTH-1:0] d_write_index;
    logic[WIDTH-1:0] d_slice_in;
    logic d_write_slice;

    vector_reg 
    #(
        .SCALAR_BITS (WIDTH ),
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

    ldl_decomposer 
    #(
        .NUM_ROWS             (NUM_ROWS             ),
        .WIDTH                (WIDTH                )
    )
    u_ldl_decomposer(
    	.rst                   (rst                   ),
        .clk                   (clk                   ),
        .start                 (start                 ),
        .finished              (finished              ),
        .row_addr              (row_addr              ),
        .row_addr_ready        (row_addr_ready        ),
        .row_valid             (row_valid             ),
        .row_out               (row_out               ),
        .write_row_addr        (write_row_addr        ),
        .write_col_addr        (write_col_addr        ),
        .write_data            (write_data            ),
        .write_ready           (write_ready           ),
        .dot_product_a         (dot_product_a         ),
        .dot_product_b         (dot_product_b         ),
        .dot_product_c         (dot_product_c         ),
        .dot_product_out       (dot_product_out       ),
        .dot_product_enable    (dot_product_enable    ),
        .vector_mult_in_a      (vector_mult_in_a      ),
        .vector_mult_in_b      (vector_mult_in_b      ),
        .vector_mult_out       (vector_mult_out       ),
        .vector_mult_alu_ready (vector_mult_alu_ready ),
        .dot_product_valid     (dot_product_valid     ),
        .vector_mult_valid     (vector_mult_valid     ),
        .dot_product_mode      (dot_product_mode      ),
        .d_out                 (d_out                 ),
        .d_read_index          (d_read_index          ),
        .d_slice_out           (d_slice_out           ),
        .d_write_index         (d_write_index         ),
        .d_slice_in            (d_slice_in            ),
        .d_write_slice         (d_write_slice         )
    );

    localparam PERIOD = 10;

    always 
    begin
        clk = 1'b1;
        #(PERIOD/2);

        clk = 1'b0;
        #(PERIOD/2);    
    end

    // Define matrix
    //shortreal matrix[NUM_ROWS-1:0][NUM_ROWS-1:0] = '{'{1, -1, 1, 0},'{-1, 2, -1, 2},'{1, -1, 5, 2},'{0, 2, 2, 6}};
    shortreal matrix[NUM_ROWS-1:0][NUM_ROWS-1:0];
    shortreal output_matrix[NUM_ROWS-1:0][NUM_ROWS-1:0];

    fp_vector_printer #( .LENGTH ( NUM_ROWS )) v_printer ();

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
        shortreal element;
        shortreal d_err, mat_err;

        // Initialize the matrix
        fd = $fopen($sformatf("../../../../../src/sim_data/%s.in", file_name), "r");
        if (!fd) 
            $fatal(1, "File was NOT opened successfully");

        $fscanf(fd, "%d", file_num_rows);
        
        if (file_num_rows != NUM_ROWS)
            $fatal(1, "File has a different number of rows than set on verilog file");

        for (int r = 0; r < NUM_ROWS; r++) begin
            for (int c = 0; c < NUM_ROWS;c++) begin
                $fscanf(fd, "%f", element);
                matrix[r][c] = element;
            end
        end

        $fclose(fd);

        for (int r = 0; r < NUM_ROWS; r++) begin
            for (int c = 0; c < NUM_ROWS; c++) begin
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
            print_matrix;
            $display("Finished reading matrix rows");
        end
    endtask

    task test_ldl(input string test_case, input logic print_original_matrix);
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
        v_printer.print_str("D: ", d_out);
        
        for (int r = 0; r < NUM_ROWS; r++) begin
            ini_row_addr = r;
            ini_row_addr_ready = 1'b1;

            #PERIOD;
            ini_row_addr_ready = 1'b0;

            wait(row_valid == 1'b1);
            #(0.25*PERIOD);

            for(int c = 0; c < NUM_ROWS; c++) begin
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

        d_err = 0;
        for(int i = 0; i < NUM_ROWS; i++) begin
            actual_val = $bitstoshortreal(d_out[i*WIDTH +: WIDTH]);
            $fscanf(fd, "%f", element);
            if(element != 0)
                d_err += (element - actual_val) ** 2 / element * (element > 0 ? 1 : -1);
            else
                d_err += (element - actual_val) ** 2;
        end

        d_err /= NUM_ROWS;

        $display("Average relative squared error d: %f%%", d_err * 100);

        mat_err = 0;
          for (int r = 0; r < NUM_ROWS; r++) begin
            for (int c = 0; c < NUM_ROWS;c++) begin
                $fscanf(fd, "%f", element);
    
                if(r > c) begin
                    // Let's compute the relative error    
                    if (element != 0)
                        mat_err += (element - output_matrix[r][c]) ** 2 / element * (element > 0 ? 1 : -1);
                    else
                        mat_err += (element - output_matrix[r][c]) ** 2;
                end
            end
        end
        mat_err /= NUM_ROWS ** 2;
        $display("Average relative squared error matrix: %f%%", mat_err * 100);
        
        $fclose(fd);
    endtask

    initial begin
        rst = 1'b1;
        initializing = 1'b1;
        start = 1'b0;

        #(2.25*PERIOD);

        rst = 1'b0;
        test_ldl("ldl_matrix_1", 1'b1);
        test_ldl("ldl_matrix_2", 1'b1);
        //test_ldl("hydice_R", 1'b0);
    end

endmodule