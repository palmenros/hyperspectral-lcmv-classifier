module scalar_to_vector #(
    parameter WIDTH = 32,
    parameter VECTOR_LENGTH = 5
) (
    input logic[WIDTH-1:0] scalar_in,
    output logic[VECTOR_LENGTH*WIDTH-1:0] vector_out
);

genvar i;
generate
    
    for (i = 0; i < VECTOR_LENGTH; i++) begin
        assign vector_out[(i+1)*WIDTH-1:i*WIDTH] = scalar_in;
    end

endgenerate
    
endmodule