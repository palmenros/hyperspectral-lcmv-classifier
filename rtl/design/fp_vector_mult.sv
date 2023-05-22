module fp_vector_mult #(
    parameter WIDTH = 32,
    parameter NUM_INPUTS = 5,
    parameter LATENCY = 8
) (

    input logic clk,
    input logic rst,

    // Data
    input logic [WIDTH*NUM_INPUTS-1:0] a,
    input logic [WIDTH*NUM_INPUTS-1:0] b,

    output logic [WIDTH*NUM_INPUTS-1:0] o,

    // Control
    input logic ready,
    output logic valid
);

genvar i;
generate
    
    for (i = 0; i < NUM_INPUTS; i++) begin
        
        logic this_valid;

        fp_multiplier 
        #(
            .WIDTH   (WIDTH   ),
            .LATENCY (LATENCY )
        )
        u_fp_multiplier(
        	.clk   (clk   ),
            .rst   (rst   ),
            .a     (a[(i+1)*WIDTH-1:i*WIDTH]),
            .b     (b[(i+1)*WIDTH-1:i*WIDTH]),
            .o     (o[(i+1)*WIDTH-1:i*WIDTH]),
            .ready (ready ),
            .valid (this_valid)
        );

        // Only assign first multiplier output to the valid output
        if (i == 0) begin
            assign valid = this_valid;
        end
        
    end

endgenerate;
    
endmodule