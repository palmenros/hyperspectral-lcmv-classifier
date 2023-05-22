module tb_wrapper_weighting_matrix_golden_test ();

localparam WIDTH = 32;

logic clk, rst;
logic[2:0] result;

wrapper_weighting_matrix_golden_test 
u_weighting_matrix_golden_test(
    .clk_in1_p    (clk    ),
    .rst_i    (rst    ),
    .result (result )
);


localparam PERIOD = 10;

always 
begin
    clk = 1'b1;
    #(PERIOD/2);

    clk = 1'b0;
    #(PERIOD/2);    
end

logic finished;
assign finished = |result;

initial begin
    rst = 1'b1;

    #(3.25*PERIOD);

    rst = 1'b0;

    wait(finished == 1'b1);

    if (result[0] == 1'b1) begin
        $display("Wrapper: Successfully finished!");
    end else if (result[1] == 1'b1) begin
        $error("Wrapper: Error: Different element!");
    end else if (result[2] == 1'b1) begin
        $error("Wrapper: Error: Different length!");
    end

    $stop();

end

endmodule
