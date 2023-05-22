`timescale 1ns/10ps
`include "sim/fp_vector_printer.sv"

module tb_correlation_matrix ();

    localparam N = 11; /* Number of total samples (pixels) */
    localparam M = 5;  /* Number of datapoints (channels) per sample (pixel) */

    localparam WIDTH = 32; /* Size in bits of each scalar of the matrix */
    localparam MEMORY_LATENCY = 2;
    localparam MULTIPLIER_LATENCY = 8;
    localparam ADDER_LATENCY = 11;

    localparam X_NUM_ROWS = N;
    localparam X_NUM_COLS = M;

    localparam X_ROW_ADDR_WIDTH = $clog2(X_NUM_ROWS);
    localparam X_COL_ADDR_WIDTH = $clog2(X_NUM_COLS);
    localparam X_ROW_SIZE = X_NUM_COLS * WIDTH;
    localparam X_COL_SIZE = X_NUM_ROWS * WIDTH;

    localparam R_NUM_ROWS = M;
    localparam R_NUM_COLS = M;

    localparam I_REGISTER_WIDTH = $clog2(N);
    localparam J_REGISTER_WIDTH = $clog2(M);

    localparam R_ROW_ADDR_WIDTH = $clog2(R_NUM_ROWS);
    localparam R_COL_ADDR_WIDTH = $clog2(R_NUM_COLS);
    localparam R_ROW_SIZE = R_NUM_COLS * WIDTH;
    localparam R_COL_SIZE = R_NUM_ROWS * WIDTH;

    logic rst, clk;
    logic initializing;

    // R matrix

    logic [R_ROW_ADDR_WIDTH-1:0] real_row_addr;
    logic real_row_addr_ready;
    logic [R_ROW_ADDR_WIDTH-1:0] real_write_row_addr;
    logic [R_ROW_SIZE-1:0] real_write_data;
    logic real_write_ready;

    logic [R_ROW_ADDR_WIDTH-1:0] ini_row_addr;
    logic ini_row_addr_ready;
    logic [R_ROW_ADDR_WIDTH-1:0] ini_write_row_addr;
    logic [R_ROW_SIZE-1:0] ini_write_data;
    logic ini_write_ready;

    logic [R_ROW_ADDR_WIDTH-1:0] row_addr;
    logic row_addr_ready;
    logic row_valid;
    logic [R_ROW_SIZE-1:0] row_out;
    logic [R_ROW_ADDR_WIDTH-1:0] write_row_addr;
    logic [R_ROW_SIZE-1:0] write_data;
    logic write_ready;

    assign real_row_addr = initializing ? ini_row_addr : row_addr; 
    assign real_row_addr_ready = initializing ? ini_row_addr_ready : row_addr_ready; 
    assign real_write_row_addr = initializing ? ini_write_row_addr : write_row_addr; 
    assign real_write_data = initializing ? ini_write_data : write_data; 
    assign real_write_ready = initializing ? ini_write_ready : write_ready;

    row_matrix 
    #(
        .NUM_ROWS       (M),
        .NUM_COLS       (M),
        .SCALAR_BITS    (WIDTH    ),
        .MEMORY_LATENCY (MEMORY_LATENCY )
    )
    u_row_matrix(
    	.clk            (clk            ),
        .rst            (rst            ),
        .row_addr       (real_row_addr       ),
        .row_addr_ready (real_row_addr_ready ),
        .row_valid      (row_valid      ),
        .row_out        (row_out        ),
        .write_row_addr (real_write_row_addr ),
        .write_data     (real_write_data     ),
        .write_ready    (real_write_ready    )
    );
    
    logic finished;

    logic vector_mult_alu_ready, vector_mult_valid, dot_product_mode;
    logic [R_ROW_SIZE-1:0] vector_mult_in_a, vector_mult_in_b, vector_mult_out;

    fp_vector_mult_alu 
    #(
        .WIDTH                                  (WIDTH        ),
        .NUM_INPUTS                             (M),
        .MULT_LATENCY                           (MULTIPLIER_LATENCY ),
        .SUM_LATENCY                            (ADDER_LATENCY)
    )
    u_fp_vector_mult_alu(
    	.clk                (clk                ),
        .rst                (rst                ),
        .dot_product_a      ({R_ROW_SIZE{1'b0}}),
        .dot_product_b      ({R_ROW_SIZE{1'b0}}),
        .dot_product_c      ({WIDTH{1'b0}}),
        .dot_product_out    (),
        .dot_product_enable ({M{1'b0}}),
        .vector_mult_in_a   (vector_mult_in_a   ),
        .vector_mult_in_b   (vector_mult_in_b   ),
        .vector_mult_out    (vector_mult_out    ),
        .ready              (vector_mult_alu_ready),
        .dot_product_valid  ( ),
        .vector_mult_valid  (vector_mult_valid  ),
        .dot_product_mode   (dot_product_mode   )
    );
    
    logic start;
    logic ds_next_data, ds_valid;
    logic [WIDTH-1:0] ds_out;

    correlation_matrix 
    #(
        .N                  (N                  ),
        .M                  (M                  ),
        .WIDTH              (WIDTH              ),
        .MEMORY_LATENCY     (MEMORY_LATENCY     ),
        .MULTIPLIER_LATENCY (MULTIPLIER_LATENCY ),
        .ADDER_LATENCY      (ADDER_LATENCY      )
    )
    u_correlation_matrix(
    	.clk                   (clk                   ),
        .rst                   (rst                   ),
        .finished              (finished              ),
        .ds_next_data          (ds_next_data          ),
        .ds_out                (ds_out                ),
        .ds_valid              (ds_valid              ),
        .r_row_addr            (row_addr            ),
        .r_row_addr_ready      (row_addr_ready      ),
        .r_row_valid           (row_valid           ),
        .r_row_out             (row_out             ),
        .r_write_row_addr      (write_row_addr      ),
        .r_write_data          (write_data          ),
        .r_write_ready         (write_ready         ),
        .dot_product_mode      (dot_product_mode      ),
        .vector_mult_alu_ready (vector_mult_alu_ready ),
        .vector_mult_in_a      (vector_mult_in_a      ),
        .vector_mult_in_b      (vector_mult_in_b      ),
        .vector_mult_out       (vector_mult_out       ),
        .vector_mult_valid     (vector_mult_valid     )
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
    shortreal matrix[X_NUM_ROWS-1:0][X_NUM_COLS-1:0];
    shortreal output_matrix[R_NUM_ROWS-1:0][R_NUM_COLS-1:0];

    fp_vector_printer #( .LENGTH ( R_NUM_COLS )) v_printer ();

    task print_matrix;
        for (int r = 0; r < R_NUM_ROWS; r++) begin
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
        int file_n;
        int file_m;
        shortreal element;
        shortreal d_err, mat_err;

        // Initialize the matrix
        fd = $fopen($sformatf("../../../../../src/sim_data/%s.in", file_name), "r");
        if (!fd) 
            $fatal(1, "File was NOT opened successfully");

        $fscanf(fd, "%d", file_n);
        $fscanf(fd, "%d", file_m);

        if (file_n != N)
            $fatal(1, "File has a different number of rows than set on verilog file");

        if (file_m != M)
            $fatal(1, "File has a different number of columns than set on verilog file");

        for (int r = 0; r < X_NUM_ROWS; r++) begin
            for (int c = 0; c < X_NUM_COLS;c++) begin
                $fscanf(fd, "%f", element);
                matrix[r][c] = element;
            end
        end

        $fclose(fd);

        $display("Finished loading matrix into memory");
    endtask

    task test_correlation_matrix(input string test_case, input logic print_original_matrix);
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
        
        for (int r = 0; r < R_NUM_ROWS; r++) begin
            ini_row_addr = r;
            ini_row_addr_ready = 1'b1;

            #PERIOD;
            ini_row_addr_ready = 1'b0;

            wait(row_valid == 1'b1);
            #(0.25*PERIOD);

            for(int c = 0; c < R_NUM_COLS; c++) begin
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
          for (int r = 0; r < R_NUM_ROWS; r++) begin
            for (int c = 0; c < R_NUM_COLS;c++) begin
                $fscanf(fd, "%f", element);
    
                if(c >= r) begin
                    // Let's compute the relative error    
                    if (element != 0)
                        mat_err += (element - output_matrix[r][c]) ** 2 / element * (element > 0 ? 1 : -1);
                    else
                        mat_err += (element - output_matrix[r][c]) ** 2;
                end
            end
        end
        mat_err = 2 * mat_err / M * M;
        $display("Average relative squared error matrix: %f%%", mat_err * 100);
        
        $fclose(fd);
    endtask

    
    /* ----------------------------------------------------------- */
    //                  AXI BUS SIMULATION
    /* ----------------------------------------------------------- */

    integer AXI_BUS_LATENCY_SIM = 2;

    always
    begin
        ds_valid = 0;
        
        wait(start == 1'b1);

        for (int r = 0; r < X_NUM_ROWS; r++) begin
            for (int c = 0; c < X_NUM_COLS; c++) begin
                ds_out = $shortrealtobits(matrix[r][c]);
                ds_valid = 1'b1;

                if (ds_next_data == 1'b1) begin
                    #(PERIOD);
                end else begin
                    wait(ds_next_data == 1'b1);
                    #(1.25 * PERIOD);
                end

                ds_valid = 1'b0;

                #(PERIOD * (AXI_BUS_LATENCY_SIM-1));
            end
        end

    end

    /* ----------------------------------------------------------- */
    //                      SIMULATION
    /* ----------------------------------------------------------- */
    

    initial begin
        rst = 1'b1;
        initializing = 1'b1;
        start = 1'b0;

        #(2.25*PERIOD);

        rst = 1'b0;
        test_correlation_matrix("corr_1", 1'b1);
        test_correlation_matrix("corr_2", 1'b1);
        // test_correlation_matrix("corr_3", 1'b1);
    end

endmodule