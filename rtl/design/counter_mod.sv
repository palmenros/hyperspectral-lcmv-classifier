module counter_mod #(
    parameter MOD = 5,

    localparam WIDTH = $clog2(MOD)
) (
    input logic rst,
    input logic clk,

    // If reset_count = 1, the counter will be set to 0
    input logic reset_count,

    // If up = 1, the counter will increment modulo MOD
    // Otherwise, it will stay the same
    input logic up,

    // Max = 1'b1 if out = MOD-1 and up=1'b1, useful for concatenating counters
    // It will be 1 if it "overflows"
    output logic max,

    output logic[WIDTH-1:0] out
);
    assign max = up && (out == MOD-1);

    logic[WIDTH-1:0] storage;
    assign out = storage;

    always_ff @(posedge clk) begin
        if (rst) begin
            storage <= '0;
        end else if (reset_count) begin
            storage <= '0;
        end else if (up) begin
            // If storage == MOD-1, go back to 0. Else, continue incrementing 
            if (max)
                storage <= '0;
            else
                storage <= storage + 1;
        end
    end
    
endmodule