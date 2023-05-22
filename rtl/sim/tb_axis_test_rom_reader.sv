`timescale 1ns/10ps
`include "sim/fp_vector_printer.sv"

module tb_axis_test_rom_reader ();
    
parameter string ROM_NAME = "test_w_1";
localparam DEPTH = 33;
localparam WIDTH = 32;

localparam ROM_MEMORY_LATENCY = 2;

logic rst, clk;
logic initializing;

logic start;
logic ds_next_data, ds_valid, ds_last;
logic[WIDTH-1:0] ds_out;

axis_test_rom_reader 
#(
    .ROM_NAME           (ROM_NAME           ),
    .DEPTH              (DEPTH              ),
    .WIDTH              (WIDTH              ),
    .ROM_MEMORY_LATENCY (ROM_MEMORY_LATENCY )
    )
u_axis_test_rom_reader(
    .clk          (clk          ),
    .rst          (rst          ),
    .start        (start        ),
    .ds_next_data (ds_next_data ),
    .ds_out       (ds_out       ),
    .ds_valid     (ds_valid     ),
    .ds_last      (ds_last      )
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
    logic [WIDTH-1:0] rom_out[0:DEPTH-1];
    logic [WIDTH-1:0] file_data[0:DEPTH-1];
    

    task print_rom_out;
        for (int i = 0; i < DEPTH; i++) begin
            $displayh(rom_out[i]);
        end
    endtask

    task print_file_data;
        for (int i = 0; i < DEPTH; i++) begin
            $displayh(file_data[i]);
        end
    endtask;

    task load_matrix_values(input string file_name, input logic print_values);
        int fd;
        int file_depth;
        logic[WIDTH-1:0] element;

        // Initialize the matrix
        fd = $fopen($sformatf("../../../../../src/sim_data/%s.in", file_name), "r");
        if (!fd) 
            $fatal(1, "File was NOT opened successfully");

        $fscanf(fd, "%d", file_depth);

        if (file_depth != DEPTH)
            $fatal(1, "File has a different depth than set on verilog file");

        for (int r = 0; r < DEPTH; r++) begin
            $fscanf(fd, "%x", element);
            file_data[r] = element;
        end

        for (int r = 0; r < DEPTH; r++) begin
            $fscanf(fd, "%x", element);
            rom_out[r] = { WIDTH{1'bx} };
        end


        $fclose(fd);

        $display("Finished initializing file_data");

        if(print_values) begin
            print_file_data;
            $display("Finished reading expected rom data");
        end
    endtask

    task test_stream_rom_reader(input string test_case, input logic print_original_matrix);
        int fd;
        logic[WIDTH-1:0] element;
        int num_errors;

        initializing = 1'b1;
        start = 1'b0;

        load_matrix_values(test_case, print_original_matrix);

        #(2*PERIOD);

        start = 1'b1;
        initializing = 1'b0;

        #PERIOD;
        start = 1'b0;

        wait(ds_last == 1'b1 && ds_next_data == 1'b1 && ds_valid == 1'b1);


        #(2.25*PERIOD);

        initializing = 1'b1;


        ////////////////////////////////////
        //         Compute errors
        ////////////////////////////////////
        
        num_errors = 0;
        for (int r = 0; r < DEPTH; r++) begin
            if (rom_out[r] != file_data[r]) begin
                num_errors += 1;
            end    
        end

        $display("Total number of errors: %d", num_errors);
        
        $fclose(fd);
    endtask

    /* ----------------------------------------------------------- */
    //                  AXI BUS SIMULATION
    /* ----------------------------------------------------------- */

    integer AXI_BUS_LATENCY_SIM = 1;

    always
    begin
        ds_next_data = 1'b0;

        wait(start == 1'b1);

        #PERIOD;

        ds_next_data = 1'b1;

        for (int r = 0; r < DEPTH; r++) begin
                if (ds_valid == 1'b0) begin
                    wait(ds_valid == 1'b1);
                    #(0.25 * PERIOD);
                end

                rom_out[r] = ds_out;

                if(r == DEPTH - 1) begin
                    assert(ds_last == 1'b1)
                    else $error("Last not correctly asserted (should be 1 and is 0)");
                end else begin
                    assert(ds_last == 1'b0)
                    else $error("Last not correctly asserted (should be 0 and is 1)");
                end

                #PERIOD;

                ds_next_data = 1'b0;

                #(PERIOD * (AXI_BUS_LATENCY_SIM-1));

                ds_next_data = 1'b1;
        end

    end

    initial begin
        rst = 1'b1;
        initializing = 1'b1;
        start = 1'b0;

        #(2.25*PERIOD);

        rst = 1'b0;
        test_stream_rom_reader("test_rom_reader_w_1", 1'b1);
        test_stream_rom_reader("test_rom_reader_w_1", 1'b1);
    end


endmodule