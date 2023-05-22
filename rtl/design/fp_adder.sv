module fp_adder #(
    parameter WIDTH = 32,
    parameter LATENCY = 11
) (
    input logic clk,
    input logic rst,

    // Data
    input logic[WIDTH-1:0] a,
    input logic[WIDTH-1:0] b,

    output logic[WIDTH-1:0] o,

    // Control signals
    input logic ready,
    output logic valid
);
    
    logic aclk;
    logic aresetn;

    logic s_axis_a_tvalid;
    logic [WIDTH-1:0] s_axis_a_tdata;

    logic s_axis_b_tvalid;
    logic [WIDTH-1:0] s_axis_b_tdata;

    logic m_axis_result_tvalid;
    logic [WIDTH-1:0] m_axis_result_tdata;

    // Convert between interfaces

    assign aclk = clk;
    assign aresetn = ~rst;

    assign s_axis_a_tvalid = ready;
    assign s_axis_a_tdata = a;

    assign s_axis_b_tvalid = ready;
    assign s_axis_b_tdata = b;

    assign valid = m_axis_result_tvalid;
    assign o = m_axis_result_tdata;

    generate
        
        if (WIDTH == 32 && LATENCY == 11) begin
            fp_adder_32_11 u_fp_adder_32_11 (.*);
        end else begin
            $fatal(1, "FP Adder not generated for selected width and latency."); 
        end

    endgenerate;

endmodule