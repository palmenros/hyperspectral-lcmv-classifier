`include "sim/fp_vector_printer.sv"

module tb_dot_product ();

localparam WIDTH = 32;
localparam NUM_INPUTS = 7;

localparam MULT_LATENCY = 8;
localparam SUM_LATENCY = 11;
localparam PIPELINE_ADDER_TREE = 1;
localparam PIPELINE_BETWEEN_MULT_AND_ADDER_TREE = 1;
localparam USE_RESET_FOR_REGISTERS_INSTEAD_OF_MUX = 1;

logic clk;
logic rst;

    // Data
logic [WIDTH*NUM_INPUTS-1:0] a;
logic [WIDTH*NUM_INPUTS-1:0] b;

logic [WIDTH-1:0] c;

logic [WIDTH-1:0] out;

// Control
logic [NUM_INPUTS-1:0] enable;

logic ready;
logic valid;

logic vector_mult_in_ready;
logic vector_mult_out_valid;
logic [WIDTH*NUM_INPUTS-1:0] vector_mult_in_a;
logic [WIDTH*NUM_INPUTS-1:0] vector_mult_in_b; 
logic  [WIDTH*NUM_INPUTS-1:0] vector_mult_out;


fp_dot_product 
#(
    .WIDTH                                  (WIDTH                                  ),
    .NUM_INPUTS                             (NUM_INPUTS                             ),
    .MULT_LATENCY                           (MULT_LATENCY                           ),
    .SUM_LATENCY                            (SUM_LATENCY                            ),
    .PIPELINE_ADDER_TREE                    (PIPELINE_ADDER_TREE                    ),
    .PIPELINE_BETWEEN_MULT_AND_ADDER_TREE   (PIPELINE_BETWEEN_MULT_AND_ADDER_TREE   ),
    .USE_RESET_FOR_REGISTERS_INSTEAD_OF_MUX (USE_RESET_FOR_REGISTERS_INSTEAD_OF_MUX )
)
u_fp_dot_product(
    .clk                   (clk                   ),
    .rst                   (rst                   ),
    .a                     (a                     ),
    .b                     (b                     ),
    .c                     (c                     ),
    .out                   (out                   ),
    .enable                (enable                ),
    .ready                 (ready                 ),
    .valid                 (valid                 ),
    .vector_mult_in_a      (vector_mult_in_a      ),
    .vector_mult_in_b      (vector_mult_in_b      ),
    .vector_mult_out       (vector_mult_out       ),
    .vector_mult_in_ready  (vector_mult_in_ready  ),
    .vector_mult_out_valid (vector_mult_out_valid )
);

fp_vector_mult 
#(
    .WIDTH      (WIDTH      ),
    .NUM_INPUTS (NUM_INPUTS ),
    .LATENCY    (MULT_LATENCY)
)
u_fp_vector_mult(
    .clk   (clk   ),
    .rst   (rst   ),
    .a     (vector_mult_in_a),
    .b     (vector_mult_in_b),
    .o     (vector_mult_out),
    .ready (vector_mult_in_ready ),
    .valid (vector_mult_out_valid )
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

initial begin
        rst = 1'b1;

        #(3.25*PERIOD);

        rst = 1'b0;
        enable = '0;
        ready = 1'b0;

        #(2*PERIOD);

        // a = [0.1 0.2 0.3 0.4 0.5 0.6 0.7]
        // b = [0.8 0.9 1.  1.1 1.2 1.3 1.4]
                       
        for(int i = 0; i < NUM_INPUTS; i++) begin
            //$display("%0h", $shortrealtobits(v[i]));
            a[i*WIDTH +: WIDTH] = $shortrealtobits(shortreal'( (i + 1) / 10.0 ));
            b[i*WIDTH +: WIDTH] = $shortrealtobits(shortreal'( (i + NUM_INPUTS + 1) / 10.0 ));
        end

        v_printer.print_str("a = ", a);
        v_printer.print_str("b = ", b);

        // enable = 7'b0000011;
        // ready = 1'b1;

        // wait(vector_mult_out_valid == 1'b1);

        // #(0.25 * PERIOD);

        // v_printer.print_str("v_out = ", vector_mult_out);

        enable = '0;
        c = $shortrealtobits(shortreal'(1));
        ready = 1'b1;

        #PERIOD;

        for(int i = 0; i < NUM_INPUTS; i++) begin
            enable[i] = 1'b1;
            c = $shortrealtobits(shortreal'(i+2));

            #PERIOD;
        end

        ready = 1'b0;

        wait(valid == 1'b1);

        #(0.25 * PERIOD);

        assert(valid == 1'b1);
        $display("%f", $bitstoshortreal(out));

        #PERIOD;

        for(int i = 0; i < NUM_INPUTS; i++) begin
            assert(valid == 1'b1);
            $display("%f", $bitstoshortreal(out));

            #PERIOD;
        end

        assert(valid == 1'b0);
        $display("Finished.");
    end


endmodule