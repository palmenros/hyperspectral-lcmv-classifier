module fp_inverter #(
    parameter WIDTH = 32
) (
    input logic[WIDTH-1:0] in,
    output logic[WIDTH-1:0] out
);

assign out = { ~in[WIDTH-1], in[WIDTH-2:0] };
    
endmodule