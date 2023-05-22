module int_to_fp #(
    parameter INT_WIDTH = 32,
    parameter INT_UNSIGNED = 1, /* If INT_UNSIGNED = 1, the input int is unsigned, else it's signed */
    parameter FP_WIDTH = 32
) (
    input logic clk,
    input logic rst,

    // Data
    input logic[INT_WIDTH-1:0] in,
    output logic[FP_WIDTH-1:0] out,

    // Control signals
    input logic ready,
    output logic valid
);
    
    logic aclk;
    logic aresetn;

    logic s_axis_a_tvalid;
    logic [INT_WIDTH-1:0] s_axis_a_tdata;

    logic m_axis_result_tvalid;
    logic [FP_WIDTH-1:0] m_axis_result_tdata;

    // Convert between interfaces

    assign aclk = clk;
    assign aresetn = ~rst;

    assign s_axis_a_tvalid = ready;
    assign s_axis_a_tdata = in;

    assign valid = m_axis_result_tvalid;
    assign out = m_axis_result_tdata;

    generate
        
        if (INT_UNSIGNED == 1 && INT_WIDTH == 32 && FP_WIDTH == 32) begin
            uint32_to_float u_uint32_to_float (.*);
        end else begin
            $fatal(1, "Fixed to FP converter not generated for selected parameters."); 
        end

    endgenerate;

endmodule