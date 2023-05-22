module wrapper_weighting_matrix_golden_test #() (
    input logic clk_in1_p,
    input logic rst_i,

    // Result from axis_comparator
    output logic[2:0] result
);

localparam WIDTH = 32;

logic clk_out1, locked;

clk_wiz_golden_test u_clk_wiz_golden_test(
    .clk_out1 (clk_out1 ),
    .reset    (rst_i    ),
    .locked   (locked   ),
    .clk_in1  (clk_in1_p)
);

localparam RESET_DELAY = 4;

logic rst_regs [0:RESET_DELAY-1];

// Delay reset
genvar i;
generate

    for (i = 0; i < RESET_DELAY; i++) begin
        always_ff @( posedge clk_out1 or negedge locked) begin                
            if (!locked) begin
                rst_regs[i] <= 1'b1;
            end else begin
                if (i == 0) begin
                    rst_regs[i] <= 1'b0;
                end else begin                    
                    rst_regs[i] <= rst_regs[i-1];
                end
            end
        end
    end

endgenerate;

weighting_matrix_golden_test 
#(
    .WIDTH (WIDTH)
)
u_weighting_matrix_golden_test(
    .clk    (clk_out1),
    .rst    (rst_regs[RESET_DELAY-1]),
    .result (result)
);


endmodule
