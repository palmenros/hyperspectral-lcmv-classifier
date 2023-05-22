`timescale 1ns/10ps
`include "sim/fp_vector_printer.sv"

module tb_tri_solver ();
    
     /* 
        Sizes M and N such that

        A is a matrix [n, n]
        B is a matrix [n, m]
        X is a matrix [n, m]
     */
    localparam N = 4;
    localparam M = 11;

    localparam WIDTH = 32;

    // Defining indices sizes
    localparam I_REGISTER_WIDTH = $clog2(N);
    localparam K_REGISTER_WIDTH = $clog2(M);
    localparam K_F_COUNTER_WIDTH = $clog2(M + 1);

    // Defining matrix parameters

    localparam A_NUM_ROWS = N;
    localparam A_NUM_COLS = N;

    localparam A_ROW_ADDR_WIDTH = $clog2(A_NUM_ROWS);
    localparam A_COL_ADDR_WIDTH = $clog2(A_NUM_COLS);
    localparam A_ROW_SIZE = A_NUM_COLS * WIDTH;
    localparam A_COL_SIZE = A_NUM_ROWS * WIDTH;

    localparam B_NUM_ROWS = N;
    localparam B_NUM_COLS = M;

    localparam B_ROW_ADDR_WIDTH = $clog2(B_NUM_ROWS);
    localparam B_COL_ADDR_WIDTH = $clog2(B_NUM_COLS);
    localparam B_ROW_SIZE = B_NUM_COLS * WIDTH;
    localparam B_COL_SIZE = B_NUM_ROWS * WIDTH;

    localparam X_NUM_ROWS = N;
    localparam X_NUM_COLS = M;

    localparam X_ROW_ADDR_WIDTH = $clog2(X_NUM_ROWS);
    localparam X_COL_ADDR_WIDTH = $clog2(X_NUM_COLS);
    localparam X_ROW_SIZE = X_NUM_COLS * WIDTH;
    localparam X_COL_SIZE = X_NUM_ROWS * WIDTH;

    logic clk, rst;
    logic initializing;
    logic lower_triangular_input, start, finished;

    // Matrix A

    // logic [A_ROW_ADDR_WIDTH-1:0] a_row_addr;
    // logic a_row_addr_ready;
    // logic a_row_valid;
    // logic [A_ROW_SIZE-1:0] a_row_out;
    // logic [A_COL_ADDR_WIDTH-1:0] a_col_addr;
    // logic a_col_addr_ready;
    // logic a_col_valid;
    // logic [A_COL_SIZE-1:0] a_col_out;
    // logic [A_ROW_ADDR_WIDTH-1:0] a_write_row_addr;
    // logic [A_COL_ADDR_WIDTH-1:0] a_write_col_addr;
    // logic [WIDTH-1:0] a_write_data;
    // logic a_write_ready;

    logic [A_ROW_ADDR_WIDTH-1:0] real_a_row_addr;
    logic real_a_row_addr_ready;
    logic [A_COL_ADDR_WIDTH-1:0] real_a_col_addr;
    logic real_a_col_addr_ready;
    logic [A_ROW_ADDR_WIDTH-1:0] real_a_write_row_addr;
    logic [A_COL_ADDR_WIDTH-1:0] real_a_write_col_addr;
    logic [WIDTH-1:0] real_a_write_data;
    logic real_a_write_ready;

    logic [A_ROW_ADDR_WIDTH-1:0] ini_a_row_addr;
    logic ini_a_row_addr_ready;
    logic [A_COL_ADDR_WIDTH-1:0] ini_a_col_addr;
    logic ini_a_col_addr_ready;
    logic [A_ROW_ADDR_WIDTH-1:0] ini_a_write_row_addr;
    logic [A_COL_ADDR_WIDTH-1:0] ini_a_write_col_addr;
    logic [WIDTH-1:0] ini_a_write_data;
    logic ini_a_write_ready;

    logic [A_ROW_ADDR_WIDTH-1:0] a_row_addr;
    logic a_row_addr_ready;
    logic a_row_valid;
    logic [A_ROW_SIZE-1:0] a_row_out;
    logic [A_COL_ADDR_WIDTH-1:0] a_col_addr;
    logic a_col_addr_ready;
    logic a_col_valid;
    logic [A_COL_SIZE-1:0] a_col_out;
    logic [A_ROW_ADDR_WIDTH-1:0] a_write_row_addr;
    logic [A_COL_ADDR_WIDTH-1:0] a_write_col_addr;
    logic [WIDTH-1:0] a_write_data;
    logic a_write_ready;

    assign real_a_row_addr = initializing ? ini_a_row_addr : a_row_addr; 
    assign real_a_row_addr_ready = initializing ? ini_a_row_addr_ready : a_row_addr_ready; 
    assign real_a_col_addr = initializing ? ini_a_col_addr : a_col_addr; 
    assign real_a_col_addr_ready = initializing ? ini_a_col_addr_ready : a_col_addr_ready; 
    assign real_a_write_row_addr = initializing ? ini_a_write_row_addr : a_write_row_addr; 
    assign real_a_write_col_addr = initializing ? ini_a_write_col_addr : a_write_col_addr; 
    assign real_a_write_data = initializing ? ini_a_write_data : a_write_data; 
    assign real_a_write_ready = initializing ? ini_a_write_ready : a_write_ready; 
    
    assign a_write_ready = 1'b0;

    matrix 
    #(
        .NUM_ROWS          (A_NUM_ROWS),
        .NUM_COLS          (A_NUM_COLS),
        .SCALAR_BITS       (WIDTH)
    )
    u_matrix_A(
    	.clk            (clk            ),
        .rst            (rst            ),
        .row_addr       (real_a_row_addr       ),
        .row_addr_ready (real_a_row_addr_ready ),
        .row_valid      (a_row_valid      ),
        .row_out        (a_row_out        ),
        .col_addr       (real_a_col_addr       ),
        .col_addr_ready (real_a_col_addr_ready ),
        .col_valid      (a_col_valid      ),
        .col_out        (a_col_out        ),
        .write_row_addr (real_a_write_row_addr ),
        .write_col_addr (real_a_write_col_addr ),
        .write_data     (real_a_write_data     ),
        .write_ready    (real_a_write_ready    )
    );
    
    // Matrix b

    logic [B_ROW_ADDR_WIDTH-1:0] b_row_addr;
    logic b_row_addr_ready;
    logic b_row_valid;
    logic [B_ROW_SIZE-1:0] b_row_out;

    logic [B_COL_ADDR_WIDTH-1:0] b_col_addr;
    logic b_col_addr_ready;
    logic b_col_valid;
    logic [B_COL_SIZE-1:0] b_col_out;

    // Element writing port
    logic [B_ROW_ADDR_WIDTH-1:0] b_write_row_addr;
    logic [B_COL_ADDR_WIDTH-1:0] b_write_col_addr;
    logic [WIDTH-1:0] b_write_data;
    logic b_write_ready;

    logic [B_ROW_ADDR_WIDTH-1:0] real_b_row_addr;
    logic real_b_row_addr_ready;
    logic [B_COL_ADDR_WIDTH-1:0] real_b_col_addr;
    logic real_b_col_addr_ready;
    logic [B_ROW_ADDR_WIDTH-1:0] real_b_write_row_addr;
    logic [B_COL_ADDR_WIDTH-1:0] real_b_write_col_addr;
    logic [WIDTH-1:0] real_b_write_data;
    logic real_b_write_ready;
    
    logic [B_ROW_ADDR_WIDTH-1:0] ini_b_row_addr;
    logic ini_b_row_addr_ready;
    logic [B_COL_ADDR_WIDTH-1:0] ini_b_col_addr;
    logic ini_b_col_addr_ready;
    logic [B_ROW_ADDR_WIDTH-1:0] ini_b_write_row_addr;
    logic [B_COL_ADDR_WIDTH-1:0] ini_b_write_col_addr;
    logic [WIDTH-1:0] ini_b_write_data;
    logic ini_b_write_ready;

    assign b_write_ready = 1'b0;

    assign real_b_row_addr = initializing ? ini_b_row_addr : b_row_addr; 
    assign real_b_row_addr_ready = initializing ? ini_b_row_addr_ready : b_row_addr_ready; 
    assign real_b_col_addr = initializing ? ini_b_col_addr : b_col_addr; 
    assign real_b_col_addr_ready = initializing ? ini_b_col_addr_ready : b_col_addr_ready; 
    assign real_b_write_row_addr = initializing ? ini_b_write_row_addr : b_write_row_addr; 
    assign real_b_write_col_addr = initializing ? ini_b_write_col_addr : b_write_col_addr; 
    assign real_b_write_data = initializing ? ini_b_write_data : b_write_data; 
    assign real_b_write_ready = initializing ? ini_b_write_ready : b_write_ready; 

    matrix 
    #(
        .NUM_ROWS          (B_NUM_ROWS),
        .NUM_COLS          (B_NUM_COLS),
        .SCALAR_BITS       (WIDTH)
    )
    u_matrix_B(
    	.clk            (clk            ),
        .rst            (rst            ),
        .row_addr       (real_b_row_addr       ),
        .row_addr_ready (real_b_row_addr_ready ),
        .row_valid      (b_row_valid      ),
        .row_out        (b_row_out        ),
        .col_addr       (real_b_col_addr       ),
        .col_addr_ready (real_b_col_addr_ready ),
        .col_valid      (b_col_valid      ),
        .col_out        (b_col_out        ),
        .write_row_addr (real_b_write_row_addr ),
        .write_col_addr (real_b_write_col_addr ),
        .write_data     (real_b_write_data     ),
        .write_ready    (real_b_write_ready    )
    );

    // Matrix X

    
    logic [X_COL_ADDR_WIDTH-1:0] x_col_addr;
    logic x_col_addr_ready;
    logic x_col_valid;
    logic [X_COL_SIZE-1:0] x_col_out;

    logic [X_ROW_ADDR_WIDTH-1:0] x_row_addr;
    logic x_row_addr_ready;
    logic x_row_valid;
    logic [X_ROW_SIZE-1:0] x_row_out;

    // Element writing port
    logic [X_ROW_ADDR_WIDTH-1:0] x_write_row_addr;
    logic [X_COL_ADDR_WIDTH-1:0] x_write_col_addr;
    logic [WIDTH-1:0] x_write_data;
    logic x_write_ready;

    logic [X_COL_ADDR_WIDTH-1:0] ini_x_col_addr;
    logic ini_x_col_addr_ready;
    logic [X_ROW_ADDR_WIDTH-1:0] ini_x_row_addr;
    logic ini_x_row_addr_ready;
    logic [X_ROW_ADDR_WIDTH-1:0] ini_x_write_row_addr;
    logic [X_COL_ADDR_WIDTH-1:0] ini_x_write_col_addr;
    logic [WIDTH-1:0] ini_x_write_data;
    logic ini_x_write_ready;

    logic [X_COL_ADDR_WIDTH-1:0] real_x_col_addr;
    logic real_x_col_addr_ready;
    logic [X_ROW_ADDR_WIDTH-1:0] real_x_row_addr;
    logic real_x_row_addr_ready;
    logic [X_ROW_ADDR_WIDTH-1:0] real_x_write_row_addr;
    logic [X_COL_ADDR_WIDTH-1:0] real_x_write_col_addr;
    logic [WIDTH-1:0] real_x_write_data;
    logic real_x_write_ready;

    assign real_x_col_addr = initializing ? ini_x_col_addr : x_col_addr; 
    assign real_x_col_addr_ready = initializing ? ini_x_col_addr_ready : x_col_addr_ready; 
    assign real_x_row_addr = initializing ? ini_x_row_addr : x_row_addr; 
    assign real_x_row_addr_ready = initializing ? ini_x_row_addr_ready : x_row_addr_ready; 
    assign real_x_write_row_addr = initializing ? ini_x_write_row_addr : x_write_row_addr; 
    assign real_x_write_col_addr = initializing ? ini_x_write_col_addr : x_write_col_addr; 
    assign real_x_write_data = initializing ? ini_x_write_data : x_write_data; 
    assign real_x_write_ready = initializing ? ini_x_write_ready : x_write_ready; 

    matrix 
    #(
        .NUM_ROWS          (X_NUM_ROWS),
        .NUM_COLS          (X_NUM_COLS),
        .SCALAR_BITS       (WIDTH)
    )
    u_matrix_X (
    	.clk            (clk            ),
        .rst            (rst            ),
        .row_addr       (real_x_row_addr       ),
        .row_addr_ready (real_x_row_addr_ready ),
        .col_addr       (real_x_col_addr       ),
        .col_addr_ready (real_x_col_addr_ready ),
        .write_row_addr (real_x_write_row_addr ),
        .write_col_addr (real_x_write_col_addr ),
        .write_data     (real_x_write_data     ),
        .write_ready    (real_x_write_ready    ),
        .row_valid      (x_row_valid      ),
        .row_out        (x_row_out        ),
        .col_valid      (x_col_valid      ),
        .col_out        (x_col_out        )
    );
    
    logic [WIDTH*N-1:0] dot_product_a;
    logic [WIDTH*N-1:0] dot_product_b;
    logic [WIDTH-1:0] dot_product_c;
    logic [WIDTH-1:0] dot_product_out;
    logic [N-1:0] dot_product_enable;
    logic [WIDTH*N-1:0] vector_mult_in_a;
    logic [WIDTH*N-1:0] vector_mult_in_b; 
    logic [WIDTH*N-1:0] vector_mult_out;
    logic vector_mult_alu_ready;
    logic dot_product_valid;
    logic vector_mult_valid;
    logic dot_product_mode;

    logic real_vector_mult_alu_ready;
    assign real_vector_mult_alu_ready = initializing ? 1'b0 : vector_mult_alu_ready;

    fp_vector_mult_alu 
    #(
        .WIDTH                                  (WIDTH   ),
        .NUM_INPUTS                             (N)
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
        .ready              (real_vector_mult_alu_ready),
        .dot_product_valid  (dot_product_valid  ),
        .vector_mult_valid  (vector_mult_valid  ),
        .dot_product_mode   (dot_product_mode   )
    );

    tri_solver 
    #(
        .N                 (N                 ),
        .M                 (M                 ),
        .WIDTH             (WIDTH             )
    )
    u_tri_solver(
    	.clk                    (clk                    ),
        .rst                    (rst                    ),
        .start                  (start                  ),
        .finished               (finished               ),
        .lower_triangular_input (lower_triangular_input ),
        .dot_product_a          (dot_product_a          ),
        .dot_product_b          (dot_product_b          ),
        .dot_product_c          (dot_product_c          ),
        .dot_product_out        (dot_product_out        ),
        .dot_product_enable     (dot_product_enable     ),
        .dot_product_valid      (dot_product_valid      ),
        .dot_product_mode       (dot_product_mode       ),
        .vector_mult_alu_ready  (vector_mult_alu_ready  ),
        .a_row_addr             (a_row_addr             ),
        .a_row_addr_ready       (a_row_addr_ready       ),
        .a_row_valid            (a_row_valid            ),
        .a_row_out              (a_row_out              ),
        .a_col_addr             (a_col_addr             ),
        .a_col_addr_ready       (a_col_addr_ready       ),
        .a_col_valid            (a_col_valid            ),
        .a_col_out              (a_col_out              ),
        .b_row_addr             (b_row_addr             ),
        .b_row_addr_ready       (b_row_addr_ready       ),
        .b_row_valid            (b_row_valid            ),
        .b_row_out              (b_row_out              ),
        .x_col_addr             (x_col_addr             ),
        .x_col_addr_ready       (x_col_addr_ready       ),
        .x_col_valid            (x_col_valid            ),
        .x_col_out              (x_col_out              ),
        .x_write_row_addr       (x_write_row_addr       ),
        .x_write_col_addr       (x_write_col_addr       ),
        .x_write_data           (x_write_data           ),
        .x_write_ready          (x_write_ready          )
    );
    

    localparam PERIOD = 10;

    always 
    begin
        clk = 1'b1;
        #(PERIOD/2);

        clk = 1'b0;
        #(PERIOD/2);    
    end

    // // Define matrix
    // //shortreal matrix[NUM_ROWS-1:0][NUM_ROWS-1:0] = '{'{1, -1, 1, 0},'{-1, 2, -1, 2},'{1, -1, 5, 2},'{0, 2, 2, 6}};
    shortreal matrix_A [A_NUM_ROWS-1:0][A_NUM_COLS-1:0];
    shortreal matrix_B [B_NUM_ROWS-1:0][B_NUM_COLS-1:0];
    
    shortreal output_matrix[X_NUM_ROWS-1:0][X_NUM_COLS-1:0];

    fp_vector_printer #( .LENGTH ( N )) v_n_printer ();
    fp_vector_printer #( .LENGTH ( M )) v_m_printer ();

    task print_matrix_a;
        for (int r = 0; r < A_NUM_ROWS; r++) begin
                ini_a_row_addr = r;
                ini_a_row_addr_ready = 1'b1;

                #PERIOD;

                ini_a_row_addr_ready = 1'b0;

                wait(a_row_valid == 1'b1);
                #(0.25*PERIOD);
                
                v_n_printer.print_str($sformatf("Row %d: ", r), a_row_out);
            end

        ini_a_row_addr_ready = 1'b0;
    endtask

    task print_matrix_b;
        for (int r = 0; r < B_NUM_ROWS; r++) begin
                ini_b_row_addr = r;
                ini_b_row_addr_ready = 1'b1;

                #PERIOD;

                ini_b_row_addr_ready = 1'b0;

                wait(b_row_valid == 1'b1);
                #(0.25*PERIOD);
                
                v_m_printer.print_str($sformatf("Row %d: ", r), b_row_out);
            end

        ini_b_row_addr_ready = 1'b0;
    endtask

    task print_matrix_x;
        for (int r = 0; r < X_NUM_ROWS; r++) begin
                ini_x_row_addr = r;
                ini_x_row_addr_ready = 1'b1;

                #PERIOD;
                ini_x_row_addr_ready = 1'b0;

                wait(x_row_valid == 1'b1);
                #(0.25*PERIOD);
                
                v_m_printer.print_str($sformatf("Row %d: ", r), x_row_out);
            end

        ini_x_row_addr_ready = 1'b0;
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
        
        if (file_n != N || file_m != M)
            $fatal(1, "File has a different N or M than set on verilog file");

        // We load first matrix A

        for (int r = 0; r < A_NUM_ROWS; r++) begin
            for (int c = 0; c < A_NUM_COLS;c++) begin
                $fscanf(fd, "%f", element);
                matrix_A[r][c] = element;
            end
        end

        // Then we load matrix B

        for (int r = 0; r < B_NUM_ROWS; r++) begin
            for (int c = 0; c < B_NUM_COLS; c++) begin
                $fscanf(fd, "%f", element);
                matrix_B[r][c] = element;
            end
        end

        $fclose(fd);

        // Set values in matrix A
        for (int r = 0; r < A_NUM_ROWS; r++) begin
            for (int c = 0; c < A_NUM_COLS; c++) begin
                // Set (r, c) in matrix
                ini_a_write_row_addr = r;
                ini_a_write_col_addr = c;
                
                ini_a_write_data = $shortrealtobits(matrix_A[r][c]);
                ini_a_write_ready = 1'b1;

                #PERIOD;
            end 
        end

        ini_a_write_ready = 1'b0;

        // Set values in matrix B
        for (int r = 0; r < B_NUM_ROWS; r++) begin
            for (int c = 0; c < B_NUM_COLS; c++) begin
                // Set (r, c) in matrix
                ini_b_write_row_addr = r;
                ini_b_write_col_addr = c;
                
                ini_b_write_data = $shortrealtobits(matrix_B[r][c]);
                ini_b_write_ready = 1'b1;

                #PERIOD;
            end 
        end

        ini_b_write_ready = 1'b0;

        $display("Finished initializing matrix");

        if(print_values) begin
            $display("Matrix A:");
            print_matrix_a;
            
            $display("Matrix B:");
            print_matrix_b;
            $display("Finished reading matrix rows");
        end
    endtask

    task test_tri_solver(input string test_case, input logic print_original_matrix, input logic lower);
        int fd;
        shortreal element;
        shortreal d_err, mat_err, actual_val;

        initializing = 1'b1;
        start = 1'b0;

        load_matrix_values(test_case, print_original_matrix);

        #PERIOD;

        lower_triangular_input = !lower;

        #PERIOD;

        start = 1'b1;
        lower_triangular_input = lower;
        initializing = 1'b0;

        #PERIOD;
        start = 1'b0;

        // We change it to the other triangular input just to check
        // the state machine does not depend on its value (it should save it on a register)
        lower_triangular_input = !lower;

        wait(finished == 1'b1);

        #(1.25*PERIOD);

        initializing = 1'b1;
    
        // Save the matrix output values
        for (int r = 0; r < X_NUM_ROWS; r++) begin
            ini_x_row_addr = r;
            ini_x_row_addr_ready = 1'b1;

            #PERIOD;
            ini_x_row_addr_ready = 1'b0;

            wait(x_row_valid == 1'b1);
            #(0.25*PERIOD);

            for(int c = 0; c < X_NUM_COLS; c++) begin
                output_matrix[r][c] = $bitstoshortreal(x_row_out[c*WIDTH +: WIDTH]); 
            end

            v_m_printer.print_str($sformatf("Row %d: ", r), x_row_out);
        end
        ini_x_row_addr_ready = 1'b0;

        ////////////////////////////////////
        //         Compute errors
        ////////////////////////////////////
        
        if (lower)
            fd = $fopen($sformatf("../../../../../src/sim_data/%s_low.out", test_case), "r");
        else
            fd = $fopen($sformatf("../../../../../src/sim_data/%s_up.out", test_case), "r");

        if (!fd) 
            $fatal(1, "File was NOT opened successfully");

        mat_err = 0;
        for (int r = 0; r < X_NUM_ROWS; r++) begin
            for (int c = 0; c < X_NUM_COLS; c++) begin
                $fscanf(fd, "%f", element);

                // Let's compute the relative error        
                if (element != 0)
                    mat_err += (element - output_matrix[r][c]) ** 2 / element * (element > 0 ? 1 : -1);
                else
                    mat_err += (element - output_matrix[r][c]) ** 2;
            end
        end
        mat_err /= X_NUM_COLS * X_NUM_ROWS;
        $display("Average relative squared error: %f%%", mat_err * 100);
        
        $fclose(fd);
    endtask

    initial begin
        rst = 1'b1;
        initializing = 1'b1;
        start = 1'b0;

        ini_a_write_ready = 1'b0;
        ini_b_write_ready = 1'b0;
        ini_x_write_ready = 1'b0;
        
        #(2.25*PERIOD);

        rst = 1'b0;
        // test_tri_solver("tri_matrix_1", 1'b1, 1'b0);
        // test_tri_solver("tri_matrix_1", 1'b1, 1'b1);
        // test_tri_solver("tri_matrix_2", 1'b1, 1'b1);
        // test_tri_solver("tri_matrix_2", 1'b1, 1'b0);
        // test_tri_solver("tri_matrix_3", 1'b1, 1'b1);
        // test_tri_solver("tri_matrix_3", 1'b1, 1'b0);
        test_tri_solver("tri_matrix_4", 1'b1, 1'b1);
        test_tri_solver("tri_matrix_4", 1'b1, 1'b0);
    
    end

endmodule