`timescale 1ns/10ps
`include "sim/fp_vector_printer.sv"

module tb_stream_matrix_loader ();

    localparam NUM_ROWS = 4;
    localparam NUM_COLS = 5;


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

    logic start, finished_loading;
    logic ds_next_data, ds_valid;
    logic[WIDTH-1:0] ds_out;

    stream_matrix_loader 
    #(
        .NUM_ROWS       (NUM_ROWS       ),
        .NUM_COLS       (NUM_COLS       ),
        .WIDTH          (WIDTH          )
    )
    u_stream_matrix_loader(
    	.rst              (rst              ),
        .clk              (clk              ),
        .finished_loading (finished_loading ),
        .ds_next_data     (ds_next_data     ),
        .ds_out           (ds_out           ),
        .ds_valid         (ds_valid         ),
        .write_row_addr   (write_row_addr   ),
        .write_col_addr   (write_col_addr   ),
        .write_data       (write_data       ),
        .write_ready      (write_ready      )
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
            for (int c = 0; c < NUM_COLS;c++) begin
                $fscanf(fd, "%f", element);
                matrix[r][c] = element;
            end
        end

        $fclose(fd);

        ini_write_ready = 1'b0;

        $display("Finished initializing matrix");

        if(print_values) begin
            print_matrix;
            $display("Finished reading matrix rows");
        end
    endtask

    task test_stream_matrix_loader(input string test_case, input logic print_original_matrix);
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

        wait(finished_loading == 1'b1);

        #(1.25*PERIOD);

        initializing = 1'b1;
  
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

    /* ----------------------------------------------------------- */
    //                  AXI BUS SIMULATION
    /* ----------------------------------------------------------- */

    integer AXI_BUS_LATENCY_SIM = 1;

    always
    begin
        ds_valid = 0;
        
        wait(start == 1'b1);

        for (int r = 0; r < NUM_ROWS; r++) begin
            for (int c = 0; c < NUM_COLS; c++) begin
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
        test_stream_matrix_loader("mat_load_1", 1'b1);
        test_stream_matrix_loader("mat_load_2", 1'b1);
    end

endmodule