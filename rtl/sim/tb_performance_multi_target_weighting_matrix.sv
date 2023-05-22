`timescale 1ns/10ps
`include "sim/fp_vector_printer.sv"

module tb_performance_multi_target_weighting_matrix ();
    
    // Main parameters to experiment with 

    localparam NUM_PIXELS = 4096;        /* Number of total pixels in image */
    localparam NUM_CHANNELS = 169;         /* Number of spectral channels in input hyperspectral image*/
    
    // Other parameters

    localparam WIDTH = 32;               /* Width of an scalar element */
    
    localparam NUM_SIGNATURES = 15;       /* Number of signatures to detect */
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

    longint cycle_number = 0;

    always 
    begin
        clk = 1'b1;
        #(PERIOD/2);

        clk = 1'b0;
        #(PERIOD/2);    

        cycle_number += 1;
    end

    shortreal matrix_T [T_NUM_ROWS-1:0][T_NUM_COLS-1:0];
    shortreal matrix_C [C_NUM_ROWS-1:0][C_NUM_COLS-1:0];
    
    localparam X_NUM_ROWS = NUM_PIXELS;
    localparam X_NUM_COLS = NUM_CHANNELS;

    // Matrix that will be fed to the correlation 
    shortreal matrix_X [X_NUM_ROWS-1:0][X_NUM_COLS-1:0];

    shortreal output_matrix[W_NUM_ROWS-1:0][W_NUM_COLS-1:0];

    task load_matrix_values();
        for (int r = 0; r < T_NUM_ROWS; r++) begin
            for (int c = 0; c < T_NUM_COLS;c++) begin
                matrix_T[r][c] = '0;
            end
        end

        for (int r = 0; r < C_NUM_ROWS; r++) begin
            for (int c = 0; c < C_NUM_COLS; c++) begin
                matrix_C[r][c] = '0;
            end
        end

        for (int r = 0; r < X_NUM_ROWS; r++) begin
            for (int c = 0; c < X_NUM_COLS; c++) begin
                matrix_X[r][c] = '0;
            end
        end


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

        $display("Finished initializing matrices");

    endtask

    logic start;

    task test_performance_multi_target_weighting_matrix();
        int start_cycle;
        int last_cycle;
        int elapsed_1_corr;
        int elapsed_2_corr_mat_translator;
        int elapsed_3_ldl1;
        int elapsed_4_mult1;
        int elapsed_5_ldl2;
        int elapsed_6_mult2;
        int sum;
        int total;

        initializing = 1'b1;
        start = 1'b0;

        load_matrix_values();

        #PERIOD;

        start = 1'b1;
        initializing = 1'b0;

        start_cycle = cycle_number;
        last_cycle = start_cycle;

        #PERIOD;
        start = 1'b0;

        wait(u_multi_target_weighting_matrix.state_reg == u_multi_target_weighting_matrix.s2);

        elapsed_1_corr = cycle_number - last_cycle;
        last_cycle = cycle_number;

        wait(u_multi_target_weighting_matrix.state_reg == u_multi_target_weighting_matrix.s4);

        elapsed_2_corr_mat_translator = cycle_number - last_cycle;
        last_cycle = cycle_number;

        wait(u_multi_target_weighting_matrix.state_reg == u_multi_target_weighting_matrix.s6);

        elapsed_3_ldl1 = cycle_number - last_cycle;
        last_cycle = cycle_number;

        wait(u_multi_target_weighting_matrix.state_reg == u_multi_target_weighting_matrix.s8);

        elapsed_4_mult1 = cycle_number - last_cycle;
        last_cycle = cycle_number;

        wait(u_multi_target_weighting_matrix.state_reg == u_multi_target_weighting_matrix.s10);

        elapsed_5_ldl2 = cycle_number - last_cycle;
        last_cycle = cycle_number;

        wait(finished == 1'b1);

        elapsed_6_mult2 = cycle_number - last_cycle;
        last_cycle = cycle_number;


        #(2*PERIOD);

        $display("\n----------------------------------");
        $display("\t PERFORMANCE DATA");
        $display("----------------------------------");
        $display("FP_WIDTH: %0d", WIDTH);
        $display("NUM_CHANNELS (NUM_BANDS): %0d", NUM_CHANNELS);
        $display("NUM_PIXELS: %0d", NUM_PIXELS);
        
        $display("NUM_SIGNATURES: %0d", NUM_SIGNATURES);
        $display("NUM_OUTPUT_CHANNELS: %0d", NUM_OUTPUT_CHANNELS);        
        $display("----------------------------------");

        $display("Elapsed 1 Correlation: %0d cycles", elapsed_1_corr);
        $display("Elapsed 2 Correlation matrix translator: %0d cycles", elapsed_2_corr_mat_translator);
        $display("Elapsed 3 LDL1: %0d cycles", elapsed_3_ldl1);
        $display("Elapsed 4 MULT1: %0d cycles", elapsed_4_mult1);
        $display("Elapsed 5 LDL2: %0d cycles", elapsed_5_ldl2);
        $display("Elapsed 6 MULT2: %0d cycles", elapsed_6_mult2);

        sum = elapsed_1_corr + elapsed_2_corr_mat_translator + elapsed_3_ldl1 + elapsed_4_mult1 + elapsed_5_ldl2 + elapsed_6_mult2;
        total = cycle_number - start_cycle - 1;

        $display("----------------------------------");
        $display("Sum: %0d cycles", sum);
        $display("Total: %0d cycles", total);
        $display("----------------------------------");
        $display("CSV");
        $display("%0d;%0d;%0d;%0d;%0d;%0d;%0d;%0d;%0d;%0d;%0d;%0d;%0d", WIDTH, NUM_CHANNELS, NUM_PIXELS, NUM_SIGNATURES, NUM_OUTPUT_CHANNELS, elapsed_1_corr, elapsed_2_corr_mat_translator, elapsed_3_ldl1, elapsed_4_mult1, elapsed_5_ldl2, elapsed_6_mult2, sum, total);
        $display("----------------------------------\n");

        // End performance simulation
        $stop();
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
        test_performance_multi_target_weighting_matrix();
    end



endmodule
