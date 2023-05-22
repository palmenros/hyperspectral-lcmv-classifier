module counter_up_to #(
    parameter WIDTH = 8 
) (
    input logic clk,
    input logic rst,

    input logic reset_count,     /* Resets the counter to 0 */
    input logic up,              /* Increments the counter by 1 */
    input logic[WIDTH-1:0] last, /* Maximum number the counter can reach, when up=1 and the counter value is last, the counter will wrap to 0 */       
    output logic[WIDTH-1:0] out,
    output logic max             /* Will be 1 if the counter value is last and up = 1'b1*/
);

    assign max = up && (out == last);

    logic[WIDTH-1:0] storage;
    assign out = storage;

    always_ff @(posedge clk) begin
        if (rst) begin
            storage <= '0;
        end else if (reset_count) begin
            storage <= '0;
        end else if (up) begin
            // If storage == last, go back to 0. Else, continue incrementing 
            if (max)
                storage <= '0;
            else
                storage <= storage + 1;
        end
    end

endmodule