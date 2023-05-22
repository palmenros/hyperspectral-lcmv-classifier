module shift_register #(
    parameter WIDTH = 5,

    // If SHIFT_RIGHT is 1, the register will be shifted right,
    // otherwise, it will be shifted left
    parameter SHIFT_RIGHT = 1
) (
    input logic clk,
    input logic rst,

    input logic[WIDTH-1:0] load_data,
    input logic shift_in,

    // If load = 1, load_data will be loaded to the register,
    // Else, if shift = 1, data will be shifted to the right (rightmost bit will be lost) 
    input logic load,
    input logic shift,

    output logic[WIDTH-1:0] out
);

logic[WIDTH-1:0] register;
    
assign out = register;

generate
    
always_ff @(posedge clk) begin
    if (rst) begin
        register <= '0;
    end else begin
        if (load) begin
            register <= load_data;
        end else if (shift) begin
            if (SHIFT_RIGHT == 1) begin
                register <= {shift_in, register[WIDTH-1:1]};
            end else begin
                register <= {register[WIDTH-2:0], shift_in};
            end
        end
    end

end
endgenerate


endmodule