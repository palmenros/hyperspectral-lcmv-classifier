`timescale 1ns/10ps

module tb_shift_register ();
    
    localparam WIDTH = 5;
    localparam SHIFT_RIGHT = 0;

    logic clk, rst;
    logic[WIDTH-1:0] load_data, out;
    logic shift_in, load, shift;
    
    shift_register 
    #(
        .WIDTH (WIDTH ),
        .SHIFT_RIGHT(SHIFT_RIGHT)
    )
    u_shift_register(
    	.clk       (clk       ),
        .rst       (rst       ),
        .load_data (load_data ),
        .shift_in  (shift_in  ),
        .load      (load      ),
        .shift     (shift     ),
        .out       (out       )
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
        shift = 1'b0;
        shift_in = 1'b0;

        #(3.25*PERIOD);

        rst = 1'b0;

        #(2*PERIOD);

        load_data = 5'b10101;
        //load_data = 5'b11111;
        load = 1'b1;

        #PERIOD;

        load = 1'b0;
        
        #(2*PERIOD);

        shift = 1'b1;


    end

endmodule