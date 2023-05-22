module top_dot_product #(
    parameter WIDTH = 32,
    parameter NUM_INPUTS = 7,
    
    parameter MULT_LATENCY = 8,
    parameter SUM_LATENCY = 11,
    parameter PIPELINE_ADDER_TREE = 1,
    parameter PIPELINE_BETWEEN_MULT_AND_ADDER_TREE = 1,
    parameter USE_RESET_FOR_REGISTERS_INSTEAD_OF_MUX = 1
) (
    input logic clk,
    input logic rst,

    // Data
    input logic [WIDTH*NUM_INPUTS-1:0] a,
    input logic [WIDTH*NUM_INPUTS-1:0] b,
    input logic [WIDTH-1:0] c,

    output logic [WIDTH-1:0] out,

    // Control
    input logic [NUM_INPUTS-1:0] enable,

    input logic ready,
    output logic valid
);

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


endmodule