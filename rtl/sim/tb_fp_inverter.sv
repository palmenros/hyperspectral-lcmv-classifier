`timescale 1ns/10ps

module tb_fp_inverter ();
    
    localparam WIDTH = 32;

    logic [WIDTH-1:0] in, out;
    
    localparam PERIOD = 10;

    fp_inverter 
    #(
        .WIDTH (WIDTH )
    )
    u_fp_inverter (
    	.in  (in  ),
        .out (out )
    );
    

    initial begin

        in = $shortrealtobits(1.3);
        $display("%f", $bitstoshortreal(in));

        #PERIOD;

        $display("%f", $bitstoshortreal(out));
        
        #PERIOD;

        in = $shortrealtobits(-3.1415);
        $display("%f", $bitstoshortreal(in));

        #PERIOD;

        $display("%f", $bitstoshortreal(out));

    end

endmodule