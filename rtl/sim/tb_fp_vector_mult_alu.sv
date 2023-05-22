`include "sim/fp_vector_printer.sv"

module tb_fp_vector_mult_alu ();

localparam WIDTH = 32;
localparam NUM_INPUTS = 7;

localparam MULT_LATENCY = 8;
localparam SUM_LATENCY = 11;
localparam PIPELINE_ADDER_TREE = 1;
localparam PIPELINE_BETWEEN_MULT_AND_ADDER_TREE = 1;
localparam USE_RESET_FOR_REGISTERS_INSTEAD_OF_MUX = 1;

logic clk, rst;
logic [WIDTH*NUM_INPUTS-1:0] dot_product_a;
logic [WIDTH*NUM_INPUTS-1:0] dot_product_b;

logic [WIDTH-1:0] dot_product_c;

logic [WIDTH-1:0] dot_product_out;

// Control
logic [NUM_INPUTS-1:0] dot_product_enable;

logic ready;
logic dot_product_valid;
logic vector_mult_valid;
logic dot_product_mode;

logic vector_mult_in_ready;
logic vector_mult_out_valid;
logic [WIDTH*NUM_INPUTS-1:0] vector_mult_in_a;
logic [WIDTH*NUM_INPUTS-1:0] vector_mult_in_b; 
logic  [WIDTH*NUM_INPUTS-1:0] vector_mult_out;

fp_vector_mult_alu 
#(
    .WIDTH                                  (WIDTH                                  ),
    .NUM_INPUTS                             (NUM_INPUTS                             ),
    .MULT_LATENCY                           (MULT_LATENCY                           ),
    .SUM_LATENCY                            (SUM_LATENCY                            ),
    .PIPELINE_ADDER_TREE                    (PIPELINE_ADDER_TREE                    ),
    .PIPELINE_BETWEEN_MULT_AND_ADDER_TREE   (PIPELINE_BETWEEN_MULT_AND_ADDER_TREE   ),
    .USE_RESET_FOR_REGISTERS_INSTEAD_OF_MUX (USE_RESET_FOR_REGISTERS_INSTEAD_OF_MUX )
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
    .ready              (ready              ),
    .dot_product_valid  (dot_product_valid  ),
    .vector_mult_valid  (vector_mult_valid  ),
    .dot_product_mode   (dot_product_mode   )
);


fp_vector_printer #( .LENGTH ( NUM_INPUTS )) v_printer ();

localparam PERIOD = 10;

always 
begin
    clk = 1'b1;
    #(PERIOD/2);

    clk = 1'b0;
    #(PERIOD/2);    
end

task test_dot_product;
        dot_product_mode = 1'b1;
        dot_product_enable = '0;
        ready = 1'b0;

        #(2*PERIOD);

        // a = [0.1 0.2 0.3 0.4 0.5 0.6 0.7]
        // b = [0.8 0.9 1.  1.1 1.2 1.3 1.4]
                       
        for(int i = 0; i < NUM_INPUTS; i++) begin
            //$display("%0h", $shortrealtobits(v[i]));
            dot_product_a[i*WIDTH +: WIDTH] = $shortrealtobits(shortreal'( (i + 1) / 10.0 ));
            dot_product_b[i*WIDTH +: WIDTH] = $shortrealtobits(shortreal'( (i + NUM_INPUTS + 1) / 10.0 ));
        end

        v_printer.print_str("a = ", dot_product_a);
        v_printer.print_str("b = ", dot_product_b);

        // enable = 7'b0000011;
        // ready = 1'b1;

        // wait(vector_mult_out_valid == 1'b1);

        // #(0.25 * PERIOD);

        // v_printer.print_str("v_out = ", vector_mult_out);

        dot_product_enable = '0;
        dot_product_c = $shortrealtobits(shortreal'(1));
        ready = 1'b1;

        #PERIOD;

        for(int i = 0; i < NUM_INPUTS; i++) begin
            dot_product_enable[i] = 1'b1;
            dot_product_c = $shortrealtobits(shortreal'(i+2));

            #PERIOD;
        end

        ready = 1'b0;

        wait(dot_product_valid == 1'b1);

        #(0.25 * PERIOD);

        assert(dot_product_valid == 1'b1);
        $display("%f", $bitstoshortreal(dot_product_out));

        #PERIOD;

        for(int i = 0; i < NUM_INPUTS; i++) begin
            assert(dot_product_valid == 1'b1);
            $display("%f", $bitstoshortreal(dot_product_out));

            #PERIOD;
        end

        assert(dot_product_valid == 1'b0);
        $display("Finished.");
endtask

task test_vector_mult;

        dot_product_mode = 1'b0;
        ready = 1'b0;

        #(2*PERIOD);

        // a = [0.1 0.2 0.3 0.4 0.5 0.6 0.7]
        // b = [0.8 0.9 1.  1.1 1.2 1.3 1.4]
                       
        for(int i = 0; i < NUM_INPUTS; i++) begin
            //$display("%0h", $shortrealtobits(v[i]));
            vector_mult_in_a[i*WIDTH +: WIDTH] = $shortrealtobits(shortreal'( (i + 1) / 10.0 ));
            vector_mult_in_b[i*WIDTH +: WIDTH] = $shortrealtobits(shortreal'( (i + NUM_INPUTS + 1) / 10.0 ));
        end

        v_printer.print_str("a = ", vector_mult_in_a);
        v_printer.print_str("b = ", vector_mult_in_b);

        // enable = 7'b0000011;
        // ready = 1'b1;

        // wait(vector_mult_out_valid == 1'b1);

        // #(0.25 * PERIOD);

        // v_printer.print_str("v_out = ", vector_mult_out);

        ready = 1'b1;

        wait(vector_mult_valid == 1'b1);

        #(0.25*PERIOD);

        ready = 1'b0;
        v_printer.print_str("v_out = ", vector_mult_out);

        $display("Finished.");

endtask

initial begin
    rst = 1'b1;
    ready = 1'b0;

    #(3.25*PERIOD);

    rst = 1'b0;

    #(2*PERIOD);
    
    test_vector_mult();

    #(2*PERIOD);
    
    test_dot_product();
    
    #(2*PERIOD);
    
    test_vector_mult();

    #(2*PERIOD);

    test_dot_product();

end


endmodule