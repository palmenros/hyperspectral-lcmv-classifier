`timescale 1ns/10ps

module tb_counter ();
    
    localparam WIDTH = 5;

    logic clk, rst;

    logic reset_count, up;
    logic[WIDTH-1:0] out;
    
    counter 
    #(
        .WIDTH (WIDTH)
    )
    u_counter(
    	.clk         (clk         ),
        .rst         (rst         ),
        .reset_count (reset_count ),
        .up          (up          ),
        .out         (out         )
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

        up = 1'b0;
        reset_count = 1'b0;

        #(3.25*PERIOD);

        rst = 1'b0;

        #(2*PERIOD);

        up = 1'b1;
        
        #(3*PERIOD);

        up = 1'b0;

        #(2*PERIOD);

        reset_count = 1'b1;

        #(1*PERIOD);

        reset_count = 1'b0;
        up = 1'b1;
    end

endmodule