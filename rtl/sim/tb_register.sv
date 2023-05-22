`timescale 1ns/10ps

module tb_register ();
    
    localparam WIDTH = 5;

    logic clk, rst, load;
    logic[WIDTH-1:0] in, out;
    
    register 
    #(
        .WIDTH (WIDTH )
    )
    u_register(
    	.clk  (clk  ),
        .rst  (rst  ),
        .load (load ),
        .in   (in   ),
        .out  (out  )
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

        load = 1'b0;

        #(3.25*PERIOD);

        rst = 1'b0;

        #(2*PERIOD);

        in = 5'b10101;
        load = 1'b1;

        #PERIOD;

        load = 1'b0;
        
        #(2*PERIOD);

        in = 5'b01010;
        load = 1'b1;

        #PERIOD;

        load = 1'b0;

        #(3*PERIOD);

    end

endmodule