`timescale 1ns/10ps

module tb_dual_shift_register ();
    
    localparam WIDTH = 5;
    localparam SHIFT_RIGHT = 0;

    logic clk, rst;

    logic shift_in, direction_right, reset_zero, shift;
    logic[WIDTH-1:0] out;
    
    dual_shift_register 
    #(
        .WIDTH (WIDTH )
    )
    u_dual_shift_register(
    	.clk             (clk             ),
        .rst             (rst             ),
        .shift_in        (shift_in        ),
        .direction_right (direction_right ),
        .reset_zero      (reset_zero      ),
        .shift           (shift           ),
        .out             (out             )
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

        reset_zero = 1'b0;
        shift = 1'b0;
        shift_in = 1'b1;
        direction_right = 1;

        #(3.25*PERIOD);

        rst = 1'b0;

        #(2*PERIOD);

        shift_in = 1'b1;
        shift = 1'b1;

        #PERIOD;

        shift_in = 1'b0;
        shift = 1'b1;

        #PERIOD;

        shift_in = 1'b1;
        shift = 1'b1;

        #PERIOD;

        shift_in = 1'b0;
        shift = 1'b1;

        #PERIOD;
        
        shift = 1'b0;
        direction_right = 1'b0;

        #(2*PERIOD);

        shift = 1'b1;
        shift_in = 1'b1;

        #(3*PERIOD);

        shift = 1'b0;
        reset_zero = 1'b1;

        #(2*PERIOD);

        reset_zero = 1'b0;
        shift = 1'b1;
        shift_in = 1'b1;

    end

endmodule