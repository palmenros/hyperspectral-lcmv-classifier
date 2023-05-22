`timescale 1ns/10ps

module tb_int_to_fp ();
    
    localparam INT_WIDTH = 32;
    localparam FP_WIDTH = 32;
    localparam INT_UNSIGNED = 1;

    logic clk, rst, ready, valid;

    logic [INT_WIDTH-1:0] in;
    logic [FP_WIDTH-1:0] out;

    int_to_fp 
    #(
        .INT_WIDTH    (INT_WIDTH    ),
        .INT_UNSIGNED (INT_UNSIGNED ),
        .FP_WIDTH     (FP_WIDTH     )
    )
    u_fp_divider(
    	.clk   (clk   ),
        .rst   (rst   ),
        .in    (in    ),
        .out   (out   ),
        .ready (ready ),
        .valid (valid )
    );
    
    localparam PERIOD = 10;

    always 
    begin
        clk = 1'b1;
        #(PERIOD/2);

        clk = 1'b0;
        #(PERIOD/2);    
    end


    task test_case(int unsigned n);
        
        in = $unsigned(n);
        ready = 1'b1;

        #PERIOD;

        ready = 1'b0;

        wait(valid == 1'b1);
        #(0.25*PERIOD);

    
        $display("%f", $bitstoshortreal(out));
    endtask


    initial begin

        rst = 1'b1;
        #(3.25*PERIOD);

        ready = 1'b0;
        rst = 1'b0;
        #(2*PERIOD);

        test_case(0);
        test_case(1);
        test_case(37);
        test_case(4096);
        test_case(4294967295);
        test_case(-1);
    end

endmodule