`timescale 1ns/10ps
`include "sim/fp_vector_printer.sv"

module tb_correlation_translator ();

    localparam N = 4;
    localparam NUM_SAMPLES = 5;

    localparam NUM_ROWS = N;
    localparam NUM_COLS = N;

    localparam DIVIDER_LATENCY = 28;
    localparam MEMORY_LATENCY = 2;

    localparam WIDTH = 32;

    localparam ROW_ADDR_WIDTH = $clog2(NUM_ROWS);
    localparam COL_ADDR_WIDTH = $clog2(NUM_COLS);
    localparam ROW_SIZE = NUM_COLS * WIDTH;
    localparam COL_SIZE = NUM_ROWS * WIDTH;


    logic rst, clk;
    logic initializing;

    // A row matrix
    logic [ROW_ADDR_WIDTH-1:0] a_real_row_addr;
    logic a_real_row_addr_ready;
    logic [ROW_ADDR_WIDTH-1:0] a_real_write_row_addr;
    logic [ROW_SIZE-1:0] a_real_write_data;
    logic a_real_write_ready;

    logic a_row_valid;
    logic [ROW_SIZE-1:0] a_row_out;

    logic [ROW_ADDR_WIDTH-1:0] ini_a_row_addr;
    logic ini_a_row_addr_ready;
    logic [ROW_ADDR_WIDTH-1:0] ini_a_write_row_addr;
    logic [ROW_SIZE-1:0] ini_a_write_data;
    logic ini_a_write_ready;

    logic [ROW_ADDR_WIDTH-1:0] a_row_addr;
    logic a_row_addr_ready;
    logic [ROW_ADDR_WIDTH-1:0] a_write_row_addr;
    logic [ROW_SIZE-1:0] a_write_data;
    logic a_write_ready;

    row_matrix 
    #(
        .NUM_ROWS       (NUM_ROWS       ),
        .NUM_COLS       (NUM_COLS       ),
        .SCALAR_BITS    (WIDTH    ),
        .MEMORY_LATENCY (MEMORY_LATENCY )
    )
    u_row_matrix(
    	.clk            (clk            ),
        .rst            (rst            ),
        .row_addr       (a_real_row_addr       ),
        .row_addr_ready (a_real_row_addr_ready ),
        .row_valid      (a_row_valid      ),
        .row_out        (a_row_out        ),
        .write_row_addr (a_real_write_row_addr ),
        .write_data     (a_real_write_data     ),
        .write_ready    (a_real_write_ready    )
    );
    
    assign a_real_row_addr = initializing ? ini_a_row_addr : a_row_addr; 
    assign a_real_row_addr_ready = initializing ? ini_a_row_addr_ready : a_row_addr_ready; 
    assign a_real_write_row_addr = initializing ? ini_a_write_row_addr : a_write_row_addr; 
    assign a_real_write_data = initializing ? ini_a_write_data : a_write_data; 
    assign a_real_write_ready = initializing ? ini_a_write_ready : a_write_ready;

    assign a_write_ready = 1'b0;

    // X matrix

    logic [ROW_ADDR_WIDTH-1:0] x_real_row_addr;
    logic x_real_row_addr_ready;
    logic [COL_ADDR_WIDTH-1:0] x_real_col_addr;
    logic x_real_col_addr_ready;
    logic [ROW_ADDR_WIDTH-1:0] x_real_write_row_addr;
    logic [COL_ADDR_WIDTH-1:0] x_real_write_col_addr;
    logic [WIDTH-1:0] x_real_write_data;
    logic x_real_write_ready;

    logic [ROW_ADDR_WIDTH-1:0] ini_x_row_addr;
    logic ini_x_row_addr_ready;
    logic [COL_ADDR_WIDTH-1:0] ini_x_col_addr;
    logic ini_x_col_addr_ready;
    logic [ROW_ADDR_WIDTH-1:0] ini_x_write_row_addr;
    logic [COL_ADDR_WIDTH-1:0] ini_x_write_col_addr;
    logic [WIDTH-1:0] ini_x_write_data;
    logic ini_x_write_ready;

    logic [ROW_ADDR_WIDTH-1:0] x_row_addr;
    logic x_row_addr_ready;
    logic x_row_valid;
    logic [ROW_SIZE-1:0] x_row_out;
    logic [COL_ADDR_WIDTH-1:0] x_col_addr;
    logic x_col_addr_ready;
    logic x_col_valid;
    logic [COL_SIZE-1:0] x_col_out;
    logic [ROW_ADDR_WIDTH-1:0] x_write_row_addr;
    logic [COL_ADDR_WIDTH-1:0] x_write_col_addr;
    logic [WIDTH-1:0] x_write_data;
    logic x_write_ready;

    assign x_real_row_addr = initializing ? ini_x_row_addr : x_row_addr; 
    assign x_real_row_addr_ready = initializing ? ini_x_row_addr_ready : x_row_addr_ready; 
    assign x_real_col_addr = initializing ? ini_x_col_addr : x_col_addr; 
    assign x_real_col_addr_ready = initializing ? ini_x_col_addr_ready : x_col_addr_ready; 
    assign x_real_write_row_addr = initializing ? ini_x_write_row_addr : x_write_row_addr; 
    assign x_real_write_col_addr = initializing ? ini_x_write_col_addr : x_write_col_addr; 
    assign x_real_write_data = initializing ? ini_x_write_data : x_write_data; 
    assign x_real_write_ready = initializing ? ini_x_write_ready : x_write_ready;

    matrix 
    #(
        .NUM_ROWS          (NUM_ROWS          ),
        .NUM_COLS          (NUM_COLS          ),
        .SCALAR_BITS       (WIDTH)
    )
    u_matrix(
    	.clk            (clk            ),
        .rst            (rst            ),
        .row_addr       (x_real_row_addr       ),
        .row_addr_ready (x_real_row_addr_ready ),
        .row_valid      (x_row_valid      ),
        .row_out        (x_row_out        ),
        .col_addr       (x_real_col_addr       ),
        .col_addr_ready (x_real_col_addr_ready ),
        .col_valid      (x_col_valid      ),
        .col_out        (x_col_out        ),
        .write_row_addr (x_real_write_row_addr ),
        .write_col_addr (x_real_write_col_addr ),
        .write_data     (x_real_write_data     ),
        .write_ready    (x_real_write_ready    )
    );

    logic start, finished;

    correlation_matrix_translator 
    #(
        .N               (N               ),
        .NUM_SAMPLES     (NUM_SAMPLES     ),
        .WIDTH           (WIDTH           ),
        .DIVIDER_LATENCY (DIVIDER_LATENCY ),
        .MEMORY_LATENCY  (MEMORY_LATENCY  )
    )
    u_correlation_matrix_translator(
    	.clk              (clk              ),
        .rst              (rst              ),
        .start            (start            ),
        .finished         (finished         ),
        .a_row_addr       (a_row_addr       ),
        .a_row_addr_ready (a_row_addr_ready ),
        .a_row_valid      (a_row_valid      ),
        .a_row_out        (a_row_out        ),
        .x_write_row_addr (x_write_row_addr ),
        .x_write_col_addr (x_write_col_addr ),
        .x_write_data     (x_write_data     ),
        .x_write_ready    (x_write_ready    )
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
    shortreal matrix[NUM_ROWS-1:0][NUM_COLS-1:0];
    shortreal output_matrix[NUM_ROWS-1:0][NUM_COLS-1:0];

    fp_vector_printer #( .LENGTH ( NUM_COLS )) v_printer ();

    task print_matrix_a;
        for (int r = 0; r < NUM_ROWS; r++) begin
                ini_a_row_addr = r;
                ini_a_row_addr_ready = 1'b1;

                #PERIOD;

                ini_a_row_addr_ready = 1'b0;

                wait(a_row_valid == 1'b1);
                #(0.25*PERIOD);
                
                v_printer.print_str($sformatf("Row %d: ", r), a_row_out);
            end

        ini_a_row_addr_ready = 1'b0;
    endtask

    task print_matrix_x;
        for (int r = 0; r < NUM_ROWS; r++) begin
                ini_x_row_addr = r;
                ini_x_row_addr_ready = 1'b1;

                #PERIOD;
                ini_x_row_addr_ready = 1'b0;

                wait(x_row_valid == 1'b1);
                #(0.25*PERIOD);

                v_printer.print_str($sformatf("Row %d: ", r), x_row_out);
            end

        ini_x_row_addr_ready = 1'b0;
    endtask

    task load_matrix_values(input string file_name, input logic print_values);
        int fd;
        int file_n;
        int file_num_samples;
        shortreal element;
        shortreal d_err, mat_err;

        // Initialize the matrix
        fd = $fopen($sformatf("../../../../../src/sim_data/%s.in", file_name), "r");
        if (!fd) 
            $fatal(1, "File was NOT opened successfully");

        $fscanf(fd, "%d", file_n);
        $fscanf(fd, "%d", file_num_samples);

        if (file_n != N)
            $fatal(1, "File has a different number of rows than set on verilog file");

        if (file_num_samples != NUM_SAMPLES)
            $fatal(1, "File has a different number of columns than set on verilog file");

        for (int r = 0; r < NUM_ROWS; r++) begin
            for (int c = 0; c < NUM_COLS;c++) begin
                $fscanf(fd, "%f", element);
                matrix[r][c] = element;
            end
        end

        $fclose(fd);

        // Load Matrix A

        for (int r = 0; r < NUM_ROWS; r++) begin
            ini_a_write_row_addr = r;
                
            for (int c = 0; c < NUM_COLS; c++) begin
                ini_a_write_data[c*WIDTH +: WIDTH] = $shortrealtobits(matrix[r][c]);
            end

            ini_a_write_ready = 1'b1;
            #PERIOD;
        end

        ini_a_write_ready = 1'b0;

        $display("Finished initializing matrix");

        if(print_values) begin
            print_matrix_a;
            $display("Finished reading matrix rows");
        end
    endtask

    task test_correlation_matrix_translator(input string test_case, input logic print_original_matrix);
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
        
        for (int r = 0; r < NUM_ROWS; r++) begin
            ini_x_row_addr = r;
            ini_x_row_addr_ready = 1'b1;

            #PERIOD;
            ini_x_row_addr_ready = 1'b0;

            wait(x_row_valid == 1'b1);
            #(0.25*PERIOD);

            for(int c = 0; c < NUM_COLS; c++) begin
                output_matrix[r][c] = $bitstoshortreal(x_row_out[c*WIDTH +: WIDTH]); 
            end

            v_printer.print_str($sformatf("Row %d: ", r), x_row_out);
        end
        ini_x_row_addr_ready = 1'b0;

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

                if(r >= c) begin
                    // Let's compute the relative error    
                    if (element != 0)
                        mat_err += (element - output_matrix[r][c]) ** 2 / element * (element > 0 ? 1 : -1);
                    else
                        mat_err += (element - output_matrix[r][c]) ** 2;
                end
                
            end
        end
        mat_err = 2 * mat_err / NUM_ROWS * NUM_COLS;
        $display("Average relative squared error matrix: %f%%", mat_err * 100);
        
        $fclose(fd);
    endtask

    initial begin
        rst = 1'b1;
        initializing = 1'b1;
        start = 1'b0;

        #(2.25*PERIOD);

        rst = 1'b0;
        // test_correlation_matrix_translator("trans_1", 1'b1);
        test_correlation_matrix_translator("trans_2", 1'b1);
        test_correlation_matrix_translator("trans_3", 1'b1);

    end

endmodule