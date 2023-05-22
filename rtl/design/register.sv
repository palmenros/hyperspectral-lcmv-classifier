module register #(
    parameter WIDTH = 32
) (
    input logic clk, 
    input logic rst,

    /* If load = 1, the register will load the value */
    input logic load,
    input logic[WIDTH-1:0] in,

    output logic[WIDTH-1:0] out
);

logic[WIDTH-1:0] storage;
assign out = storage;

always_ff @(posedge clk) begin
    if (rst) begin
        storage <= '0;
    end else if (load) begin
        storage <= in;
    end
end
    
endmodule