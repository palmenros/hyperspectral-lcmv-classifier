module set_reset_reg (
    input logic clk,
    input logic rst,

    input logic set,            /* If set=1 and reset=1, the register will be set */
    input logic reset,
    output logic out
);
    
logic storage;
assign out = storage;

always_ff @(posedge clk) begin
    if (rst) begin
        storage <= '0;
    end else if (set) begin
        storage <= 1'b1;
    end else if (reset) begin
        storage <= 1'b0;
    end
end 

endmodule