module counter #(
    parameter WIDTH = 8
) (
    input logic clk,
    input logic rst,

    // If reset_count = 1, the counter will be set to 0
    input logic reset_count,

    // If up = 1, the counter will increment
    // Otherwise, it will stay the same
    input logic up,

    output logic[WIDTH-1:0] out
);

logic[WIDTH-1:0] storage;
assign out = storage;

always_ff @(posedge clk) begin
    if (rst) begin
        storage <= '0;
    end else if (reset_count) begin
        storage <= '0;
    end else if (up) begin
        storage <= storage + 1;
    end
end

endmodule