`timescale 1ns/10ps

module tb_counter_up_to ();
    
    localparam N = 5;
    localparam WIDTH = $clog2(N);

    logic clk, rst;

    logic reset_count_a, up_a, max_a;
    logic[WIDTH-1:0] out_a;
    
    counter_mod 
    #(
        .MOD (N)
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
    logic[WIDTH-1:0] out_b, last_b;

    counter_up_to 
    #(
        .WIDTH (WIDTH )
    )
    u_counter_up_to(
    	.clk         (clk         ),
        .rst         (rst         ),
        .reset_count (reset_count_b ),
        .up          (up_b          ),
        .last        (last_b        ),
        .out         (out_b         ),
        .max         (max_b         )
    );
    
    assign up_a = max_b;
    assign last_b = out_a;
    
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
        #(0.5*PERIOD);

        for(int a = 0; a < N; a++) begin
            for (int b = 0; b <= a; b++) begin
                assert(out_a == a && out_b == b) 
                else $error("Values not being set properly");
                
                if (b == a) begin
                    assert(max_b)
                    else $error("Max B not working properly");                    
                end

                if (a == N - 1 && b == a) begin
                    assert(max_a)
                    else $error("Max A not working properly");                    
                end

                #PERIOD;
            end
        end
        
        assert(out_a == 0 && out_b == 0)
        else $error(1, "Not wrapping around properly");

        up_b = 1;
        #PERIOD;

        up_b = 0;
        #(3*PERIOD);

        reset_count_a = 1'b1;
        reset_count_b = 1'b1;
    
        #PERIOD;

        assert(out_a == 0 && out_b == 0)
        else $error(1, "Reset not working");

        reset_count_a = 1'b0;
        reset_count_b = 1'b0;
        up_b = 1;

        #PERIOD;

        assert(out_a == 1 && out_b == 0)
        else $error(1, "Increment after reset not working");
    end

endmodule