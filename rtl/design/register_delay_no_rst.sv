module register_delay_no_rst #(
    parameter REG_WIDTH = 32,
    parameter DELAY_CYCLES = 1
) (
    input logic clk,

    input logic [REG_WIDTH-1:0] in,
    output logic [REG_WIDTH-1:0] out
);

    logic [REG_WIDTH-1:0] regs [0:DELAY_CYCLES-1];
    
    // Wire intermediate registers
    genvar i;
    generate

        if (DELAY_CYCLES == 0) begin
            
            assign out = in;

        end else begin

            // Assign last register to out
            assign out = regs[DELAY_CYCLES-1];

            for (i = 0; i < DELAY_CYCLES; i++) begin                
                always_ff @( posedge clk ) begin                
                    if (i == 0) begin
                        regs[i] <= in;
                    end else begin                    
                        regs[i] <= regs[i-1];
                    end
                end
            end
        end

    endgenerate;

    
endmodule