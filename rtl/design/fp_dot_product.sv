module fp_dot_product #(
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

    // Data
    input logic [WIDTH*NUM_INPUTS-1:0] a,
    input logic [WIDTH*NUM_INPUTS-1:0] b,
    input logic [WIDTH-1:0] c,

    // Out = a*b+c

    output logic [WIDTH-1:0] out,

    // We don't have to sum all the entries of the vectors, we have a logic per element that tells us
    // if we need to take into account that element for the dot product
    input logic [NUM_INPUTS-1:0] enable,

    input logic ready,
    output logic valid,

    // Ports to multiplier
    // In order to support sharing resources, this module does *NOT* allocate it's own fp_multiplier,
    // but it connects to another already instantiated multiplier

    output logic [WIDTH*NUM_INPUTS-1:0] vector_mult_in_a,
    output logic [WIDTH*NUM_INPUTS-1:0] vector_mult_in_b, 
    input logic  [WIDTH*NUM_INPUTS-1:0] vector_mult_out,

    output logic vector_mult_in_ready,
    input  logic vector_mult_out_valid
);

    logic [WIDTH*NUM_INPUTS-1:0] adder_tree_input;
    logic adder_tree_ready;
    logic [NUM_INPUTS-1:0] reg_enable;
    logic [WIDTH-1:0] c_reg;

    assign vector_mult_in_a = a;
    assign vector_mult_in_b = b;
    assign vector_mult_in_ready = ready;

    genvar i;
    generate

        for (i = 0; i < NUM_INPUTS; i++) begin
            
            if(PIPELINE_BETWEEN_MULT_AND_ADDER_TREE == 1) begin        
                // Stablish the register for adder_tree_input[(i+1)*WIDTH-1:i*WIDTH]
                
                if(USE_RESET_FOR_REGISTERS_INSTEAD_OF_MUX == 1) begin            
                    
                    // Note: We no longer use USE_RESET_FOR_REGISTERS_INSTEAD_OF_MUX, as we don't reset the values (unneeded)
                    always_ff @( posedge clk ) begin
                        if (~reg_enable[i]) begin
                            adder_tree_input[(i+1)*WIDTH-1:i*WIDTH] <= '0;
                        end else begin
                            adder_tree_input[(i+1)*WIDTH-1:i*WIDTH] <= vector_mult_out[(i+1)*WIDTH-1:i*WIDTH];
                        end
                    end

                end else begin
                    
                    always_ff @( posedge clk ) begin
                        if (reg_enable[i] == 1'b1) begin
                            adder_tree_input[(i+1)*WIDTH-1:i*WIDTH] <= vector_mult_out[(i+1)*WIDTH-1:i*WIDTH];
                        end else begin
                            adder_tree_input[(i+1)*WIDTH-1:i*WIDTH] <= '0;
                        end
                    end
                    
                end
            end else begin
                assign adder_tree_input[(i+1)*WIDTH-1:i*WIDTH] = (reg_enable[i] == 1'b1) ? vector_mult_out[(i+1)*WIDTH-1:i*WIDTH] : '0;
            end
         end

        // Cache ready signal
        if(PIPELINE_BETWEEN_MULT_AND_ADDER_TREE == 1) begin        
            
            register_delay 
            #(
                .REG_WIDTH    (1    ),
                .DELAY_CYCLES (MULT_LATENCY + 1 )
            )
            u_register_delay(
                .clk (clk ),
                .rst (rst ),
                .in  (ready),
                .out (adder_tree_ready)
            );

            register_delay_no_rst
            #(
                .REG_WIDTH    (WIDTH),
                .DELAY_CYCLES (MULT_LATENCY + 1 )
            )
            u_c_reg_delay (
                .clk (clk ),
                .in  (c),
                .out (c_reg)
            );

        end else begin

            register_delay 
            #(
                .REG_WIDTH    (1    ),
                .DELAY_CYCLES (MULT_LATENCY)
            )
            u_register_delay(
                .clk (clk ),
                .rst (rst ),
                .in  (ready),
                .out (adder_tree_ready)
            );

            register_delay_no_rst
            #(
                .REG_WIDTH    (WIDTH),
                .DELAY_CYCLES (MULT_LATENCY)
            )
            u_c_reg_delay (
                .clk (clk ),
                .in  (c),
                .out (c_reg)
            );
        end


    endgenerate;
    
    fp_adder_tree 
    #(
        .WIDTH                   (WIDTH               ),
        .NUM_INPUTS              (NUM_INPUTS  + 1     ),
        .FP_ADDER_LATENCY        (SUM_LATENCY         ),
        .PIPELINE_BETWEEN_STAGES (PIPELINE_ADDER_TREE )
    )
    u_fp_adder_tree(
    	.clk   (clk   ),
        .rst   (rst   ),
        .in    ({c_reg, adder_tree_input}),
        .out   (out ),
        .ready (adder_tree_ready),
        .valid (valid )
    );
    
    register_delay_no_rst
    #(
        .REG_WIDTH    (NUM_INPUTS),
        .DELAY_CYCLES (MULT_LATENCY )
    )
    u_enable_delay (
    	.clk (clk ),
        .in  (enable),
        .out (reg_enable)
    );
    

endmodule