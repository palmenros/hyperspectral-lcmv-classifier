module dual_shift_register #(
    parameter WIDTH = 5
) (
    input logic clk,
    input logic rst,

    input logic shift_in,

    // If reset_zero= 1, the register will be filled with zeros,
    // Else, if shift = 1, the register will be shifted to the right if direction_right = 1 (else, it will be shifted to the left) 
    // The bit shifted in will be shift_in
    input logic direction_right,
    input logic reset_zero,
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
        if (reset_zero) begin
            register <= '0;
        end else if (shift) begin
            if (direction_right) begin
                register <= {shift_in, register[WIDTH-1:1]};
            end else begin
                register <= {register[WIDTH-2:0], shift_in};
            end
        end
    end

end
endgenerate


endmodule