module fp_adder_tree #(
    parameter WIDTH = 32,
    parameter NUM_INPUTS = 7,
    parameter FP_ADDER_LATENCY = 11,

    // If PIPELINE_BETWEEN_STAGES = 1, introduce a pipeline register between stages of adder modules
    parameter PIPELINE_BETWEEN_STAGES = 1
) (
    input logic clk,
    input logic rst,

    // Data
    input logic [NUM_INPUTS * WIDTH-1:0] in,
    output logic [WIDTH-1:0] out,

    // Control
    input logic ready,
    output logic valid
);
    
    // Equivalent to ceil(NUM_INPUTS / 2.0)
    localparam NEXT_STAGE_NUM_INPUTS = (NUM_INPUTS+1) / 2 ;
    localparam NUM_INPUTS_EVEN = (NUM_INPUTS % 2 == 0) ? NUM_INPUTS : NUM_INPUTS - 1;

    logic[NEXT_STAGE_NUM_INPUTS * WIDTH - 1:0] next_stage_inputs; 

    genvar i;
    generate

        if (NUM_INPUTS == 2) begin
            fp_adder 
                #(
                    .WIDTH   (WIDTH ),
                    .LATENCY (FP_ADDER_LATENCY)
                )
                u_fp_adder(
                    .clk   (clk),
                    .rst   (rst),
                    .a     ( in[WIDTH-1 : 0] ),
                    .b     ( in[2*WIDTH-1 : WIDTH] ),
                    .o     ( out ),
                    .ready ( ready ),
                    .valid ( valid)
                );

        end else begin

            logic this_stage_valid;
            logic next_stage_ready;
            logic [NEXT_STAGE_NUM_INPUTS*WIDTH -1 : 0] this_stage_outputs;
            logic [NEXT_STAGE_NUM_INPUTS*WIDTH -1 : 0] next_stage_inputs;
            
            // Initialize adders
            for (i = 0; i < NUM_INPUTS_EVEN; i=i+2) begin
                
                logic this_valid;

                fp_adder 
                #(
                    .WIDTH   (WIDTH ),
                    .LATENCY (FP_ADDER_LATENCY)
                )
                u_fp_adder(
                    .clk   (clk),
                    .rst   (rst),
                    .a     ( in[(i+1)*WIDTH-1 : i * WIDTH] ),
                    .b     ( in[(i+2)*WIDTH-1 : (i+1) * WIDTH] ),
                    .o     ( this_stage_outputs[ (i/2 + 1) * WIDTH-1 : (i/2) * WIDTH] ),
                    .ready (ready ),
                    .valid (this_valid)
                );

                // Only assign one valid to the this_stage_valid
                if (i == 0) begin
                    assign this_stage_valid = this_valid;
                end
            end
            
            // If there's a remaining element this layer, construct a register delay to it
            if (NUM_INPUTS != NUM_INPUTS_EVEN) begin
                
                register_delay_no_rst 
                #(
                    .REG_WIDTH    (WIDTH),
                    .DELAY_CYCLES (FP_ADDER_LATENCY )
                )
                u_register_delay(
                	.clk (clk ),
                    .in  (in[NUM_INPUTS * WIDTH-1 : (NUM_INPUTS-1) * WIDTH]  ),
                    .out (this_stage_outputs[NEXT_STAGE_NUM_INPUTS*WIDTH -1 : (NEXT_STAGE_NUM_INPUTS - 1)* WIDTH] )
                );
            
            end

            // Recursively instantiate module
            fp_adder_tree 
            #(
                .WIDTH                 (WIDTH                 ),
                .NUM_INPUTS            (NEXT_STAGE_NUM_INPUTS ),
                .FP_ADDER_LATENCY      (FP_ADDER_LATENCY      )
            )
            u_fp_adder_tree(
                .clk   (clk),
                .rst   (rst),
                .in    (next_stage_inputs),
                .out   (out   ),
                .ready (next_stage_ready),
                .valid (valid )
            );
                
            // Connect this stage outputs with next stage inputs
            if (PIPELINE_BETWEEN_STAGES == 0) begin
                // No pipelining, combinational
                assign next_stage_inputs = this_stage_outputs;
                assign next_stage_ready = this_stage_valid;
            end else if (PIPELINE_BETWEEN_STAGES == 1) begin
                // Pipelining, insert register

                always_ff @( posedge clk ) begin
                    if (rst) begin
                        next_stage_ready <= 1'b0;
                    end else begin
                        next_stage_ready <= this_stage_valid;
                    end
                end

                // No reset needed for next_stage_inputs
                always_ff @( posedge clk ) begin
                    next_stage_inputs <= this_stage_outputs;
                end

            end else begin
                $fatal(1, "Invalid setting for PIPELINE_BETWEEN_STAGES, must be 0 or 1.");
            end
        end

    endgenerate;


endmodule