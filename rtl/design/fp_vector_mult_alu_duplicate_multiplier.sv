module fp_vector_mult_alu_duplicate_multiplier #(
    parameter WIDTH = 32,
    parameter NUM_INPUTS = 5,

    parameter MULT_LATENCY = 8,
    parameter SUM_LATENCY = 11,
    parameter PIPELINE_ADDER_TREE = 1,

    // Introduce a set of registers after the multiplication and before the adder tree if set to 1
    // If set to 0, then directly connect the adder tree
    parameter PIPELINE_BETWEEN_MULT_AND_ADDER_TREE = 1,

    // If PIPELINE_BETWEEN_MULT_AND_ADDER_TREE = 1
    parameter USE_RESET_FOR_REGISTERS_INSTEAD_OF_MUX = 1
) (
    input logic clk,
    input logic rst,

    // As in many places we use different inputs for the dot product and vector multiplier,
    // to avoid having an extra multiplexer in the inputs, we will have sepate inputs for 
    // dot product and the vector multiplier

    ///////////////////////
    // Dot product ports //
    ///////////////////////

    input logic [WIDTH*NUM_INPUTS-1:0] dot_product_a,
    input logic [WIDTH*NUM_INPUTS-1:0] dot_product_b,
    input logic [WIDTH-1:0] dot_product_c,

    // dot_product_out = a*b+c
    output logic [WIDTH-1:0] dot_product_out,

    // We don't have to sum all the entries of the vectors, we have a logic per element that tells us
    // if we need to take into account that element for the dot product
    input logic [NUM_INPUTS-1:0] dot_product_enable,

    ///////////////////////
    // Multiplier ports  //
    ///////////////////////
    input logic [WIDTH*NUM_INPUTS-1:0] vector_mult_in_a,
    input logic [WIDTH*NUM_INPUTS-1:0] vector_mult_in_b, 
    output logic [WIDTH*NUM_INPUTS-1:0] vector_mult_out,

    
    input logic ready,
    output logic dot_product_valid,
    output logic vector_mult_valid,

    // If dot_product_mode = 1, the ALU will be configured to act as the dot product,
    // else, it will act as a vector multiplier
    input logic dot_product_mode 
);

logic dot_product_ready;
logic [WIDTH*NUM_INPUTS-1:0] dp_vector_mult_in_a, dp_vector_mult_in_b, dp_vector_mult_out;

logic dp_vector_mult_in_ready, vector_mult_ready;

assign dot_product_ready = ready && dot_product_mode;
assign vector_mult_ready = ready && !dot_product_mode;

logic o_dot_product_valid, o_vector_mult_valid, dp_vector_mult_valid;

assign dot_product_valid = dot_product_mode && o_dot_product_valid;
assign vector_mult_valid = !dot_product_mode && o_vector_mult_valid;


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
    .clk                   (clk),
    .rst                   (rst),
    .a                     (dot_product_a),
    .b                     (dot_product_b),
    .c                     (dot_product_c),
    .out                   (dot_product_out),
    .enable                (dot_product_enable),
    .ready                 (dot_product_ready),
    .valid                 (o_dot_product_valid),
    .vector_mult_in_a      (dp_vector_mult_in_a      ),
    .vector_mult_in_b      (dp_vector_mult_in_b      ),
    .vector_mult_out       (dp_vector_mult_out       ),
    .vector_mult_in_ready  (dp_vector_mult_in_ready  ),
    .vector_mult_out_valid (dp_vector_mult_valid)
);

fp_vector_mult 
#(
    .WIDTH      (WIDTH      ),
    .NUM_INPUTS (NUM_INPUTS ),
    .LATENCY    (MULT_LATENCY    )
)
u_fp_vector_mult_dp (
    .clk   (clk   ),
    .rst   (rst   ),
    .a     (dp_vector_mult_in_a     ),
    .b     (dp_vector_mult_in_b     ),
    .o     (dp_vector_mult_out     ),
    .ready (dp_vector_mult_in_ready ),
    .valid (dp_vector_mult_valid )
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
    .ready (vector_mult_ready),
    .valid (o_vector_mult_valid)
);
 
endmodule