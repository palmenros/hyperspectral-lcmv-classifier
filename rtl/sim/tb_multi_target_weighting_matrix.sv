`timescale 1ns/10ps
`include "sim/fp_vector_printer.sv"

module tb_multi_target_weighting_matrix ();
    
    localparam WIDTH = 32;               /* Width of an scalar element */

    localparam NUM_PIXELS = 50;        /* Number of total pixels in image */
    localparam NUM_CHANNELS = 11;         /* Number of spectral channels in input hyperspectral image*/
    localparam NUM_SIGNATURES = 5;       /* Number of signatures to detect */
    localparam NUM_OUTPUT_CHANNELS = 3;  /* Number of channels in output image */
    
    // Latencies

    localparam MEMORY_LATENCY = 2;
    localparam MULTIPLIER_LATENCY = 8;
    localparam ADDER_LATENCY = 11;
    localparam DIVIDER_LATENCY = 28;

    // Matrix sizes

    localparam T_NUM_ROWS = NUM_CHANNELS;
    localparam T_NUM_COLS = NUM_SIGNATURES;

    localparam C_NUM_ROWS = NUM_SIGNATURES;
    localparam C_NUM_COLS = NUM_OUTPUT_CHANNELS;

    localparam W_NUM_ROWS = NUM_CHANNELS;
    localparam W_NUM_COLS = NUM_OUTPUT_CHANNELS;

    // Matrix port parameters

    localparam T_ROW_ADDR_WIDTH = $clog2(T_NUM_ROWS);
    localparam T_COL_ADDR_WIDTH = $clog2(T_NUM_COLS);
    localparam T_ROW_SIZE = T_NUM_COLS * WIDTH;
    localparam T_COL_SIZE = T_NUM_ROWS * WIDTH;

    localparam C_ROW_ADDR_WIDTH = $clog2(C_NUM_ROWS);
    localparam C_COL_ADDR_WIDTH = $clog2(C_NUM_COLS);
    localparam C_ROW_SIZE = C_NUM_COLS * WIDTH;
    localparam C_COL_SIZE = C_NUM_ROWS * WIDTH;

    localparam W_ROW_ADDR_WIDTH = $clog2(W_NUM_ROWS);
    localparam W_COL_ADDR_WIDTH = $clog2(W_NUM_COLS);
    localparam W_ROW_SIZE = W_NUM_COLS * WIDTH;
    localparam W_COL_SIZE = W_NUM_ROWS * WIDTH;

    logic clk, rst, finished;
    logic initializing;

    // Matrix T

    logic [T_ROW_ADDR_WIDTH-1:0] t_row_addr;
    logic t_row_addr_ready;
    logic t_row_valid;
    logic [T_ROW_SIZE-1:0] t_row_out;

    logic [T_COL_ADDR_WIDTH-1:0] t_col_addr;
    logic t_col_addr_ready;
    logic t_col_valid;
    logic [T_COL_SIZE-1:0] t_col_out;

    // Element writing port
    logic [T_ROW_ADDR_WIDTH-1:0] t_write_row_addr;
    logic [T_COL_ADDR_WIDTH-1:0] t_write_col_addr;
    logic [WIDTH-1:0] t_write_data;
    logic t_write_ready;

    logic [T_ROW_ADDR_WIDTH-1:0] real_t_row_addr;
    logic real_t_row_addr_ready;
    logic [T_COL_ADDR_WIDTH-1:0] real_t_col_addr;
    logic real_t_col_addr_ready;
    logic [T_ROW_ADDR_WIDTH-1:0] real_t_write_row_addr;
    logic [T_COL_ADDR_WIDTH-1:0] real_t_write_col_addr;
    logic [WIDTH-1:0] real_t_write_data;
    logic real_t_write_ready;
    
    logic [T_ROW_ADDR_WIDTH-1:0] ini_t_row_addr;
    logic ini_t_row_addr_ready;
    logic [T_COL_ADDR_WIDTH-1:0] ini_t_col_addr;
    logic ini_t_col_addr_ready;
    logic [T_ROW_ADDR_WIDTH-1:0] ini_t_write_row_addr;
    logic [T_COL_ADDR_WIDTH-1:0] ini_t_write_col_addr;
    logic [WIDTH-1:0] ini_t_write_data;
    logic ini_t_write_ready;

    matrix 
    #(
        .NUM_ROWS          (T_NUM_ROWS          ),
        .NUM_COLS          (T_NUM_COLS          ),
        .SCALAR_BITS       (WIDTH       ),
        .MEMORY_LATENCY    (MEMORY_LATENCY    )
    )
    u_t_matrix(
    	.clk            (clk            ),
        .rst            (rst            ),
        .row_addr       (real_t_row_addr       ),
        .row_addr_ready (real_t_row_addr_ready ),
        .row_valid      (t_row_valid      ),
        .row_out        (t_row_out        ),
        .col_addr       (real_t_col_addr       ),
        .col_addr_ready (real_t_col_addr_ready ),
        .col_valid      (t_col_valid      ),
        .col_out        (t_col_out        ),
        .write_row_addr (real_t_write_row_addr ),
        .write_col_addr (real_t_write_col_addr ),
        .write_data     (real_t_write_data     ),
        .write_ready    (real_t_write_ready    )
    );
    
    assign t_write_ready = 1'b0;

    assign real_t_row_addr = initializing ? ini_t_row_addr : t_row_addr; 
    assign real_t_row_addr_ready = initializing ? ini_t_row_addr_ready : t_row_addr_ready; 
    assign real_t_col_addr = initializing ? ini_t_col_addr : t_col_addr; 
    assign real_t_col_addr_ready = initializing ? ini_t_col_addr_ready : t_col_addr_ready; 
    assign real_t_write_row_addr = initializing ? ini_t_write_row_addr : t_write_row_addr; 
    assign real_t_write_col_addr = initializing ? ini_t_write_col_addr : t_write_col_addr; 
    assign real_t_write_data = initializing ? ini_t_write_data : t_write_data; 
    assign real_t_write_ready = initializing ? ini_t_write_ready : t_write_ready; 

    // Matrix C

    logic [C_ROW_ADDR_WIDTH-1:0] c_row_addr;
    logic c_row_addr_ready;
    logic c_row_valid;
    logic [C_ROW_SIZE-1:0] c_row_out;

    logic [C_COL_ADDR_WIDTH-1:0] c_col_addr;
    logic c_col_addr_ready;
    logic c_col_valid;
    logic [C_COL_SIZE-1:0] c_col_out;

    // Element writing port
    logic [C_ROW_ADDR_WIDTH-1:0] c_write_row_addr;
    logic [C_COL_ADDR_WIDTH-1:0] c_write_col_addr;
    logic [WIDTH-1:0] c_write_data;
    logic c_write_ready;

    logic [C_ROW_ADDR_WIDTH-1:0] real_c_row_addr;
    logic real_c_row_addr_ready;
    logic [C_COL_ADDR_WIDTH-1:0] real_c_col_addr;
    logic real_c_col_addr_ready;
    logic [C_ROW_ADDR_WIDTH-1:0] real_c_write_row_addr;
    logic [C_COL_ADDR_WIDTH-1:0] real_c_write_col_addr;
    logic [WIDTH-1:0] real_c_write_data;
    logic real_c_write_ready;
    
    logic [C_ROW_ADDR_WIDTH-1:0] ini_c_row_addr;
    logic ini_c_row_addr_ready;
    logic [C_COL_ADDR_WIDTH-1:0] ini_c_col_addr;
    logic ini_c_col_addr_ready;
    logic [C_ROW_ADDR_WIDTH-1:0] ini_c_write_row_addr;
    logic [C_COL_ADDR_WIDTH-1:0] ini_c_write_col_addr;
    logic [WIDTH-1:0] ini_c_write_data;
    logic ini_c_write_ready;

    matrix_no_col 
    #(
        .NUM_ROWS          (C_NUM_ROWS          ),
        .NUM_COLS          (C_NUM_COLS          ),
        .SCALAR_BITS       (WIDTH       ),
        .MEMORY_LATENCY    (MEMORY_LATENCY    )
    )
    u_c_matrix(
    	.clk            (clk            ),
        .rst            (rst            ),
        .row_addr       (real_c_row_addr       ),
        .row_addr_ready (real_c_row_addr_ready ),
        .row_valid      (c_row_valid      ),
        .row_out        (c_row_out        ),
        .write_row_addr (real_c_write_row_addr ),
        .write_col_addr (real_c_write_col_addr ),
        .write_data     (real_c_write_data     ),
        .write_ready    (real_c_write_ready    )
    );
    
    assign c_write_ready = 1'b0;
    assign c_col_addr_ready = 1'b0;

    assign real_c_row_addr = initializing ? ini_c_row_addr : c_row_addr; 
    assign real_c_row_addr_ready = initializing ? ini_c_row_addr_ready : c_row_addr_ready; 
    assign real_c_col_addr = initializing ? ini_c_col_addr : c_col_addr; 
    assign real_c_col_addr_ready = initializing ? ini_c_col_addr_ready : c_col_addr_ready; 
    assign real_c_write_row_addr = initializing ? ini_c_write_row_addr : c_write_row_addr; 
    assign real_c_write_col_addr = initializing ? ini_c_write_col_addr : c_write_col_addr; 
    assign real_c_write_data = initializing ? ini_c_write_data : c_write_data; 
    assign real_c_write_ready = initializing ? ini_c_write_ready : c_write_ready; 

    // Matrix W

    logic [W_ROW_ADDR_WIDTH-1:0] w_row_addr;
    logic w_row_addr_ready;
    logic w_row_valid;
    logic [W_ROW_SIZE-1:0] w_row_out;

    logic [W_COL_ADDR_WIDTH-1:0] w_col_addr;
    logic w_col_addr_ready;
    logic w_col_valid;
    logic [W_COL_SIZE-1:0] w_col_out;

    // Element writing port
    logic [W_ROW_ADDR_WIDTH-1:0] w_write_row_addr;
    logic [W_COL_ADDR_WIDTH-1:0] w_write_col_addr;
    logic [WIDTH-1:0] w_write_data;
    logic w_write_ready;

    logic [W_ROW_ADDR_WIDTH-1:0] real_w_row_addr;
    logic real_w_row_addr_ready;
    logic [W_COL_ADDR_WIDTH-1:0] real_w_col_addr;
    logic real_w_col_addr_ready;
    logic [W_ROW_ADDR_WIDTH-1:0] real_w_write_row_addr;
    logic [W_COL_ADDR_WIDTH-1:0] real_w_write_col_addr;
    logic [WIDTH-1:0] real_w_write_data;
    logic real_w_write_ready;
    
    logic [W_ROW_ADDR_WIDTH-1:0] ini_w_row_addr;
    logic ini_w_row_addr_ready;
    logic [W_COL_ADDR_WIDTH-1:0] ini_w_col_addr;
    logic ini_w_col_addr_ready;
    logic [W_ROW_ADDR_WIDTH-1:0] ini_w_write_row_addr;
    logic [W_COL_ADDR_WIDTH-1:0] ini_w_write_col_addr;
    logic [WIDTH-1:0] ini_w_write_data;
    logic ini_w_write_ready;

    matrix 
    #(
        .NUM_ROWS          (W_NUM_ROWS          ),
        .NUM_COLS          (W_NUM_COLS          ),
        .SCALAR_BITS       (WIDTH       ),
        .MEMORY_LATENCY    (MEMORY_LATENCY    )
    )
    u_w_matrix(
    	.clk            (clk            ),
        .rst            (rst            ),
        .row_addr       (real_w_row_addr       ),
        .row_addr_ready (real_w_row_addr_ready ),
        .row_valid      (w_row_valid      ),
        .row_out        (w_row_out        ),
        .col_addr       (real_w_col_addr       ),
        .col_addr_ready (real_w_col_addr_ready ),
        .col_valid      (w_col_valid      ),
        .col_out        (w_col_out        ),
        .write_row_addr (real_w_write_row_addr ),
        .write_col_addr (real_w_write_col_addr ),
        .write_data     (real_w_write_data     ),
        .write_ready    (real_w_write_ready    )
    );

    assign w_row_addr_ready = 1'b0;
    assign w_col_addr_ready = 1'b0;

    assign real_w_row_addr = initializing ? ini_w_row_addr : w_row_addr; 
    assign real_w_row_addr_ready = initializing ? ini_w_row_addr_ready : w_row_addr_ready; 
    assign real_w_col_addr = initializing ? ini_w_col_addr : w_col_addr; 
    assign real_w_col_addr_ready = initializing ? ini_w_col_addr_ready : w_col_addr_ready; 
    assign real_w_write_row_addr = initializing ? ini_w_write_row_addr : w_write_row_addr; 
    assign real_w_write_col_addr = initializing ? ini_w_write_col_addr : w_write_col_addr; 
    assign real_w_write_data = initializing ? ini_w_write_data : w_write_data; 
    assign real_w_write_ready = initializing ? ini_w_write_ready : w_write_ready; 

    // Modules

    logic ds_next_data, ds_valid;
    logic[WIDTH-1:0] ds_out;

    logic [WIDTH*NUM_CHANNELS-1:0] nc_dot_product_a;
    logic [WIDTH*NUM_CHANNELS-1:0] nc_dot_product_b;
    logic [WIDTH-1:0] nc_dot_product_c;
    logic [WIDTH-1:0] nc_dot_product_out;
    logic [NUM_CHANNELS-1:0] nc_dot_product_enable;
    logic [WIDTH*NUM_CHANNELS-1:0] nc_vector_mult_in_a;
    logic [WIDTH*NUM_CHANNELS-1:0] nc_vector_mult_in_b; 
    logic [WIDTH*NUM_CHANNELS-1:0] nc_vector_mult_out;
    logic nc_vector_mult_alu_ready;
    logic nc_dot_product_valid;
    logic nc_vector_mult_valid;
    logic nc_dot_product_mode;

    logic nc_real_vector_mult_alu_ready;
    assign nc_real_vector_mult_alu_ready = initializing ? 1'b0 : nc_vector_mult_alu_ready;

    fp_vector_mult_alu 
    #(
        .WIDTH                                  (WIDTH),
        .NUM_INPUTS                             (NUM_CHANNELS)
    )
    u_fp_vector_mult_alu_nc(
    	.clk                (clk                ),
        .rst                (rst                ),
        .dot_product_a      (nc_dot_product_a      ),
        .dot_product_b      (nc_dot_product_b      ),
        .dot_product_c      (nc_dot_product_c      ),
        .dot_product_out    (nc_dot_product_out    ),
        .dot_product_enable (nc_dot_product_enable ),
        .vector_mult_in_a   (nc_vector_mult_in_a   ),
        .vector_mult_in_b   (nc_vector_mult_in_b   ),
        .vector_mult_out    (nc_vector_mult_out    ),
        .ready              (nc_real_vector_mult_alu_ready),
        .dot_product_valid  (nc_dot_product_valid  ),
        .vector_mult_valid  (nc_vector_mult_valid  ),
        .dot_product_mode   (nc_dot_product_mode   )
    );


    multi_target_weighting_matrix 
    #(
        .WIDTH               (WIDTH               ),
        .NUM_PIXELS          (NUM_PIXELS          ),
        .NUM_CHANNELS        (NUM_CHANNELS        ),
        .NUM_SIGNATURES      (NUM_SIGNATURES      ),
        .NUM_OUTPUT_CHANNELS (NUM_OUTPUT_CHANNELS ),
        .MEMORY_LATENCY      (MEMORY_LATENCY      ),
        .MULTIPLIER_LATENCY  (MULTIPLIER_LATENCY  ),
        .ADDER_LATENCY       (ADDER_LATENCY       ),
        .DIVIDER_LATENCY     (DIVIDER_LATENCY     )
    )
    u_multi_target_weighting_matrix(
    	.clk                      (clk                      ),
        .rst                      (rst                      ),
        .finished                 (finished                 ),
        .ds_next_data             (ds_next_data             ),
        .ds_out                   (ds_out                   ),
        .ds_valid                 (ds_valid                 ),
        .t_row_addr               (t_row_addr               ),
        .t_row_addr_ready         (t_row_addr_ready         ),
        .t_row_valid              (t_row_valid              ),
        .t_row_out                (t_row_out                ),
        .t_col_addr               (t_col_addr               ),
        .t_col_addr_ready         (t_col_addr_ready         ),
        .t_col_valid              (t_col_valid              ),
        .t_col_out                (t_col_out                ),
        .c_row_addr               (c_row_addr               ),
        .c_row_addr_ready         (c_row_addr_ready         ),
        .c_row_valid              (c_row_valid              ),
        .c_row_out                (c_row_out                ),
        .w_write_row_addr         (w_write_row_addr         ),
        .w_write_col_addr         (w_write_col_addr         ),
        .w_write_data             (w_write_data             ),
        .w_write_ready            (w_write_ready            ),
        .nc_dot_product_mode      (nc_dot_product_mode      ),
        .nc_vector_mult_alu_ready (nc_vector_mult_alu_ready ),
        .nc_vector_mult_in_a      (nc_vector_mult_in_a      ),
        .nc_vector_mult_in_b      (nc_vector_mult_in_b      ),
        .nc_vector_mult_out       (nc_vector_mult_out       ),
        .nc_vector_mult_valid     (nc_vector_mult_valid     ),
        .nc_dot_product_a         (nc_dot_product_a         ),
        .nc_dot_product_b         (nc_dot_product_b         ),
        .nc_dot_product_c         (nc_dot_product_c         ),
        .nc_dot_product_out       (nc_dot_product_out       ),
        .nc_dot_product_enable    (nc_dot_product_enable    ),
        .nc_dot_product_valid     (nc_dot_product_valid)
    );

    localparam PERIOD  = 10;

    always 
    begin
        clk = 1'b1;
        #(PERIOD/2);

        clk = 1'b0;
        #(PERIOD/2);    
    end

    shortreal matrix_T [T_NUM_ROWS-1:0][T_NUM_COLS-1:0];
    shortreal matrix_C [C_NUM_ROWS-1:0][C_NUM_COLS-1:0];
    
    localparam X_NUM_ROWS = NUM_PIXELS;
    localparam X_NUM_COLS = NUM_CHANNELS;

    // Matrix that will be fed to the correlation 
    shortreal matrix_X [X_NUM_ROWS-1:0][X_NUM_COLS-1:0];

    shortreal output_matrix[W_NUM_ROWS-1:0][W_NUM_COLS-1:0];

    fp_vector_printer #( .LENGTH ( T_NUM_COLS )) v_T_printer ();
    fp_vector_printer #( .LENGTH ( C_NUM_COLS )) v_C_printer ();
    // fp_vector_printer #( .LENGTH ( NUM_CHANNELS )) v_X_printer ();
    fp_vector_printer #( .LENGTH ( W_NUM_COLS )) v_W_out_printer ();

    task print_matrix_T;
        for (int r = 0; r < T_NUM_ROWS; r++) begin
                ini_t_row_addr = r;
                ini_t_row_addr_ready = 1'b1;

                #PERIOD;

                ini_t_row_addr_ready = 1'b0;

                wait(t_row_valid == 1'b1);
                #(0.25*PERIOD);
                
                v_T_printer.print_str($sformatf("Row %d: ", r), t_row_out);
            end

        ini_t_row_addr_ready = 1'b0;
    endtask

    task print_matrix_C;
        for (int r = 0; r < C_NUM_ROWS; r++) begin
            ini_c_row_addr = r;
            ini_c_row_addr_ready = 1'b1;

            #PERIOD;

            ini_c_row_addr_ready = 1'b0;

            wait(c_row_valid == 1'b1);
            #(0.25*PERIOD);
                
            v_C_printer.print_str($sformatf("Row %d: ", r), c_row_out);
        end

        ini_c_row_addr_ready = 1'b0;
    endtask

    task print_matrix_W;
            for (int r = 0; r < W_NUM_ROWS; r++) begin
                ini_w_row_addr = r;
                ini_w_row_addr_ready = 1'b1;

                #PERIOD;

                ini_w_row_addr_ready = 1'b0;

                wait(w_row_valid == 1'b1);
                #(0.25*PERIOD);
                    
                v_W_out_printer.print_str($sformatf("Row %d: ", r), w_row_out);
            end

        ini_w_row_addr_ready = 1'b0;
    endtask

    task load_matrix_values(input string file_name, input logic print_values);
        int fd;
        int fd_out_hex;
        int fd_out_fp;
        int file_num_pixels;
        int file_num_channels;
        int file_num_signatures;
        int file_num_output_channels;
    
        shortreal element;
        shortreal d_err, mat_err;

        // Initialize the matrix
        fd = $fopen($sformatf("../../../../../src/sim_data/%s.in", file_name), "r");
        if (!fd) 
            $fatal(1, "File was NOT opened successfully");

        $fscanf(fd, "%d", file_num_pixels);
        $fscanf(fd, "%d", file_num_channels);
        $fscanf(fd, "%d", file_num_signatures);
        $fscanf(fd, "%d", file_num_output_channels);
        
        if (file_num_pixels != NUM_PIXELS || file_num_channels != NUM_CHANNELS 
                || file_num_signatures != NUM_SIGNATURES || file_num_output_channels != NUM_OUTPUT_CHANNELS)
            $fatal(1, "File has a different parameters than set on verilog file");

        fd_out_hex = $fopen($sformatf("../../../../../src/sim_data/%s.hex.symout", file_name), "w");
        fd_out_fp = $fopen($sformatf("../../../../../src/sim_data/%s.fp.symout", file_name), "w");

        // We load first matrix T
        $fdisplay(fd_out_hex, "T\n");
        $fdisplay(fd_out_fp, "T\n");

        for (int r = 0; r < T_NUM_ROWS; r++) begin
            for (int c = 0; c < T_NUM_COLS;c++) begin
                $fscanf(fd, "%f", element);

                $fdisplayh(fd_out_hex, $shortrealtobits(element));
                $fdisplay(fd_out_fp, $sformatf("%f ", element));

                matrix_T[r][c] = element;
            end
        end

        // Then we load matrix C
        $fdisplay(fd_out_hex, "\nC\n");
        $fdisplay(fd_out_fp, "\nC\n");

        for (int r = 0; r < C_NUM_ROWS; r++) begin
            for (int c = 0; c < C_NUM_COLS; c++) begin
                $fscanf(fd, "%f", element);

                $fdisplayh(fd_out_hex, $shortrealtobits(element));
                $fdisplay(fd_out_fp, $sformatf("%f ", element));

                matrix_C[r][c] = element;
            end
        end

        // Then we load matrix X
        $fdisplay(fd_out_hex, "\nX\n");
        $fdisplay(fd_out_fp, "\nX\n");

        for (int r = 0; r < X_NUM_ROWS; r++) begin
            for (int c = 0; c < X_NUM_COLS; c++) begin
                $fscanf(fd, "%f", element);

                $fdisplayh(fd_out_hex, $shortrealtobits(element));
                $fdisplay(fd_out_fp, $sformatf("%f ", element));

                matrix_X[r][c] = element;
            end
        end


        $fclose(fd);
        $fclose(fd_out_fp);
        $fclose(fd_out_hex);

        // Set values in matrix t
        for (int r = 0; r < T_NUM_ROWS; r++) begin
            for (int c = 0; c < T_NUM_COLS; c++) begin
                // Set (r, c) in matrix
                ini_t_write_row_addr = r;
                ini_t_write_col_addr = c;
                
                ini_t_write_data = $shortrealtobits(matrix_T[r][c]);
                ini_t_write_ready = 1'b1;

                #PERIOD;
            end 
        end

        ini_t_write_ready = 1'b0;

        // Set values in matrix C
        for (int r = 0; r < C_NUM_ROWS; r++) begin
            for (int c = 0; c < C_NUM_COLS; c++) begin
                // Set (r, c) in matrix
                ini_c_write_row_addr = r;
                ini_c_write_col_addr = c;
                
                ini_c_write_data = $shortrealtobits(matrix_C[r][c]);
                ini_c_write_ready = 1'b1;

                #PERIOD;
            end 
        end

        ini_c_write_ready = 1'b0;

        $display("Finished initializing matrix");

        if(print_values) begin
            $display("Matrix T:");
            print_matrix_T;
            
            $display("Matrix C:");
            print_matrix_C;
            $display("Finished reading matrix rows");
        end
    endtask

    logic start;

    task test_multi_target_weighting_matrix(input string test_case, input logic print_original_matrix);
        int fd;
        int fd_out_hex;
        int fd_out_fp;
        shortreal element;
        shortreal mat_err, actual_val;

        initializing = 1'b1;
        start = 1'b0;

        load_matrix_values(test_case, print_original_matrix);

        #PERIOD;

        start = 1'b1;
        initializing = 1'b0;

        #PERIOD;
        start = 1'b0;

        wait(finished == 1'b1);

        #(1.25*PERIOD);

        initializing = 1'b1;
    
        fd_out_hex = $fopen($sformatf("../../../../../src/sim_data/%s.hex.symout", test_case), "a");
        fd_out_fp = $fopen($sformatf("../../../../../src/sim_data/%s.fp.symout", test_case), "a");

        $fdisplay(fd_out_hex, "\nW\n");
        $fdisplay(fd_out_fp, "\nW\n");
        
        // Save the matrix output values
        for (int r = 0; r < W_NUM_ROWS; r++) begin
            ini_w_row_addr = r;
            ini_w_row_addr_ready = 1'b1;

            #PERIOD;
            ini_w_row_addr_ready = 1'b0;

            wait(w_row_valid == 1'b1);
            #(0.25*PERIOD);

            for(int c = 0; c < W_NUM_COLS; c++) begin
                output_matrix[r][c] = $bitstoshortreal(w_row_out[c*WIDTH +: WIDTH]); 

                $fdisplayh(fd_out_hex, w_row_out[c*WIDTH +: WIDTH]);
                $fdisplay(fd_out_fp, $sformatf("%e ", $bitstoshortreal(w_row_out[c*WIDTH +: WIDTH])));
            end

            v_W_out_printer.print_str_scientific_notation($sformatf("Row %d: ", r), w_row_out);
        end
        ini_w_row_addr_ready = 1'b0;

        $fclose(fd_out_hex);
        $fclose(fd_out_fp);

        ////////////////////////////////////
        //         Compute errors
        ////////////////////////////////////
        
        fd = $fopen($sformatf("../../../../../src/sim_data/%s.out", test_case), "r");

        if (!fd) 
            $fatal(1, "File was NOT opened successfully");

        mat_err = 0;
        for (int r = 0; r < W_NUM_ROWS; r++) begin
            for (int c = 0; c < W_NUM_COLS; c++) begin
                $fscanf(fd, "%f", element);

                // Let's compute the relative error        
                if (element != 0)
                    mat_err += (element - output_matrix[r][c]) ** 2 / element * (element > 0 ? 1 : -1);
                else
                    mat_err += (element - output_matrix[r][c]) ** 2;
            end
        end
        mat_err /= W_NUM_COLS * W_NUM_ROWS;
        $display("Average relative squared error: %f%%", mat_err * 100);
        
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
                ds_out = $shortrealtobits(matrix_X[r][c]);
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
        test_multi_target_weighting_matrix("multi_1", 1'b1);
        test_multi_target_weighting_matrix("multi_2", 1'b1);
    end



endmodule
