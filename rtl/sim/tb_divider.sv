`timescale 1ns/10ps

module tb_divider ();
    
    localparam WIDTH = 32;
    localparam LATENCY = 28;

    logic clk, rst;
    logic [WIDTH-1:0] a, b, o;
    logic ready, valid;

    fp_divider 
    #(
        .WIDTH   (WIDTH   ),
        .LATENCY (LATENCY )
    )
    u_fp_adder(
    	.clk   (clk   ),
        .rst   (rst   ),
        .a     (a     ),
        .b     (b     ),
        .o     (o     ),
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

    initial begin
        rst = 1'b1;

        #(3.25*PERIOD);

        rst = 1'b0;

        #(2*PERIOD);

        a = $shortrealtobits(15.3);
        b = $shortrealtobits(-4.8);

        ready = 1'b1;

        #PERIOD;

        ready = 1'b0;

        #((LATENCY - 1) * PERIOD);
        assert(valid == 1'b1);
        $display("%f", $bitstoshortreal(o));
    end

endmodule