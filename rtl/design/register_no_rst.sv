module register_no_rst #(
    parameter WIDTH = 32
) (
    input logic clk, 

    /* If load = 1, the register will load the value */
    input logic load,
    input logic[WIDTH-1:0] in,

    output logic[WIDTH-1:0] out
);

logic[WIDTH-1:0] storage;
assign out = storage;

always_ff @(posedge clk) begin
    if (load) begin
        storage <= in;
    end
end
    
endmodule