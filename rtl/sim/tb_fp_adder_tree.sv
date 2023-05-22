`include "sim/fp_vector_printer.sv"

`timescale 1ns/10ps

// Sum columns and rows of a matrix
module tb_fp_adder_tree ();

    localparam WIDTH = 32;
    localparam SIZE = 7;
    localparam FP_ADDER_LATENCY = 11;

    logic clk, rst;

    logic [SIZE * WIDTH-1:0] in;
    logic [WIDTH-1:0] out;

    logic ready;
    logic valid;

    fp_adder_tree 
    #(
        .WIDTH                   (WIDTH),
        .NUM_INPUTS              (SIZE),
        .FP_ADDER_LATENCY        (FP_ADDER_LATENCY ),
        .PIPELINE_BETWEEN_STAGES (1)
    ) dut (
    	.clk   (clk   ),
        .rst   (rst   ),
        .in    (in    ),
        .out   (out   ),
        .ready (ready ),
        .valid (valid )
    );
    
    // Vector printer

    fp_vector_printer #( .LENGTH ( SIZE )) col_printer ();


    // Tasks

    localparam PERIOD = 10;

    always 
    begin
        clk = 1'b1;
        #(PERIOD/2);

        clk = 1'b0;
        #(PERIOD/2);    
    end

    shortreal v[0:SIZE-1];

    initial begin
        rst = 1'b1;

        #(3.25*PERIOD);

        rst = 1'b0;

        #(2*PERIOD);

        // [2.3, -3.5, 41.3, -5.4, 6.8, 4.25, -11.3]
        // sum = 34.45
        v[0] = 2.3;
        v[1] = -3.5;
        v[2] = 41.3;
        v[3] = -5.4;
        v[4] = 6.8;
        v[5] = 4.25;
        v[6] = -11.3;
                
        for(int i = 0; i < SIZE; i++) begin
            //$display("%0h", $shortrealtobits(v[i]));
            in[i*WIDTH +: WIDTH] = $shortrealtobits(v[i]);
        end

        ready = 1'b1;

        #PERIOD;

        ready = 1'b0;

        wait(valid == 1'b1);

        #(0.25 * PERIOD);
        assert(valid == 1'b1);
        $display("%f", $bitstoshortreal(out));
    end

endmodule