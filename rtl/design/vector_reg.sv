module vector_reg #(
    parameter SCALAR_BITS = 32, /* Size in bits of each scalar of the matrix */
    parameter LENGTH = 5,        /* Length in scalars of the vector */

    localparam INDEX_WIDTH = $clog2(LENGTH),
    localparam SIZE_BITS = LENGTH * SCALAR_BITS /* Size in bits of the register */
) (
    input logic clk,
    
    /* If load = 1, the data from in will be loaded */
    input logic load,

    input logic[SIZE_BITS-1:0] in,
    output logic[SIZE_BITS-1:0] out,

    // Slicing read
    input logic[INDEX_WIDTH-1:0] read_index,
    output logic[SCALAR_BITS-1:0] slice_out,

    // Slicing write
    input logic[INDEX_WIDTH-1:0] write_index,
    input logic[SCALAR_BITS-1:0] slice_in,
    input logic write_slice
);

/* Register storage */
logic[SIZE_BITS-1:0] register;
assign out = register;

// Load logic
always_ff @( posedge clk ) begin
    if(load) begin
        register <= in;
    end else if(write_slice) begin
        register[write_index*SCALAR_BITS +: SCALAR_BITS] <= slice_in;
    end
end

// Slicing logic

assign slice_out = register[read_index*SCALAR_BITS +: SCALAR_BITS];

endmodule