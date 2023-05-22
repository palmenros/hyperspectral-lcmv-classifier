`timescale 1ns/10ps

module tb_counter_mod ();
    
    localparam MOD_A = 5;
    localparam MOD_B = 4;

    localparam WIDTH_A = $clog2(MOD_A);
    localparam WIDTH_B = $clog2(MOD_B);

    logic clk, rst;

    logic reset_count_a, up_a, max_a;
    logic[WIDTH_A-1:0] out_a;
    
    counter_mod 
    #(
        .MOD   (MOD_A)
    )
    u_counter_mod_a(
    	.rst         (rst         ),
        .clk         (clk         ),
        .reset_count (reset_count_a ),
        .up          (up_a          ),
        .max         (max_a         ),
        .out         (out_a         )
    );

    logic reset_count_b, up_b, max_b;
    logic[WIDTH_B-1:0] out_b;

    counter_mod 
    #(
        .MOD   (MOD_B)
    )
    u_counter_mod(
    	.rst         (rst         ),
        .clk         (clk         ),
        .reset_count (reset_count_b),
        .up          (up_b         ),
        .max         (max_b        ),
        .out         (out_b        )
    );
    
    assign up_a = max_b;

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

        up_b = 1'b0;

        reset_count_a = 1'b0;
        reset_count_b = 1'b0;

        #(3.20*PERIOD);

        rst = 1'b0;

        #(2*PERIOD);

        up_b = 1'b1;
        #(0.05*PERIOD);

        for(int a = 0; a < MOD_A; a++) begin
            for (int b = 0; b < MOD_B; b++) begin
                assert(out_a == a && out_b == b) 
                else $fatal(1, "Values not being set properly");
                
                if (b == MOD_B - 1) begin
                    assert(max_b)
                    else $fatal(1, "Max not working properly");                    
                end

                if (a == MOD_A - 1 && b == MOD_B - 1) begin
                    assert(max_a)
                    else $fatal(1, "Max not working properly");                    
                end

                #PERIOD;
            end
        end
        
        assert(out_a == 0 && out_b == 0)
        else $fatal(1, "Not wrapping around properly");

        up_b = 1;
        #PERIOD;

        up_b = 0;
        #(3*PERIOD);

        up_b = 1;

        #(MOD_B*PERIOD);

        assert(out_a == 1 && out_b == 1)
        else $fatal(1, "Mod increment not working");

        reset_count_a = 1'b1;
        reset_count_b = 1'b1;
    
        #PERIOD;

        assert(out_a == 0 && out_b == 0)
        else $fatal(1, "Reset not working");

        reset_count_a = 1'b0;
        reset_count_b = 1'b0;
        up_b = 1;

        #PERIOD;

        assert(out_a == 0 && out_b == 1)
        else $fatal(1, "Increment after reset not working");
    end

endmodule