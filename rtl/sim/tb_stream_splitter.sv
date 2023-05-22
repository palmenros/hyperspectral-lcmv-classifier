`timescale 1ns/10ps

module tb_stream_splitter ();
    
    localparam WIDTH = 5;
    localparam PERIOD = 10;
    localparam NUM_ELEMENTS_FIRST_GROUP = 5;
    localparam NUM_ELEMENTS_SECOND_GROUP = 3;
    
    logic clk, rst;

    
    logic ds_in_next_data;
    logic[WIDTH-1:0] ds_in_out;
    logic ds_in_valid;
    logic ds_in_last;

    logic ds_out_a_next_data;
    logic[WIDTH-1:0] ds_out_a;
    logic ds_out_a_valid;
    logic ds_out_a_last;

    logic ds_out_b_next_data;
    logic[WIDTH-1:0] ds_out_b;
    logic ds_out_b_valid;
    logic ds_out_b_last;

    stream_splitter 
    #(
        .WIDTH                     (WIDTH                   ),
        .NUM_ELEMENTS_FIRST_OUTPUT (NUM_ELEMENTS_FIRST_GROUP)
    )
    u_stream_splitter(
    	.clk                (clk                ),
        .rst                (rst                ),
        .ds_in_next_data    (ds_in_next_data    ),
        .ds_in_out          (ds_in_out          ),
        .ds_in_valid        (ds_in_valid        ),
        .ds_in_last         (ds_in_last         ),
        .ds_out_a_next_data (ds_out_a_next_data ),
        .ds_out_a           (ds_out_a           ),
        .ds_out_a_valid     (ds_out_a_valid     ),
        .ds_out_a_last      (ds_out_a_last      ),
        .ds_out_b_next_data (ds_out_b_next_data ),
        .ds_out_b           (ds_out_b           ),
        .ds_out_b_valid     (ds_out_b_valid     ),
        .ds_out_b_last      (ds_out_b_last      )
    );
    
    always 
    begin
        clk = 1'b1;
        #(PERIOD/2);

        clk = 1'b0;
        #(PERIOD/2);    
    end


    integer data_a[NUM_ELEMENTS_FIRST_GROUP-1:0];
    integer data_b[NUM_ELEMENTS_SECOND_GROUP-1:0];


    task fill_data;
        for(int i = 0; i < NUM_ELEMENTS_FIRST_GROUP; i++) begin
            data_a[i] = i;
        end

        for(int i = 0; i < NUM_ELEMENTS_SECOND_GROUP; i++) begin
            data_b[i] = NUM_ELEMENTS_FIRST_GROUP + i;
        end
    endtask;

    logic start;

    task test_stream_splitter;
        fill_data;

        start = 1'b1;
        #PERIOD;
        start = 1'b0;


        $display("Finished");
    endtask;


    /* ----------------------------------------------------------- */
    //                  AXI BUS SIMULATION
    /* ----------------------------------------------------------- */

    // AXI WRITE

    integer AXI_BUS_LATENCY_SIM_WRITE = 2;

    always
    begin
        ds_in_valid = 0;
        ds_in_last = 0;

        wait(start == 1'b1);

        for (int i = 0; i < NUM_ELEMENTS_FIRST_GROUP; i++) begin
                ds_in_out = data_a[i];
                ds_in_valid = 1'b1;

                if (ds_in_next_data == 1'b1) begin
                    #(PERIOD);
                end else begin
                    wait(ds_in_next_data == 1'b1);
                    #(1.25 * PERIOD);
                end

                ds_in_valid = 1'b0;

                #(PERIOD * (AXI_BUS_LATENCY_SIM_WRITE-1));
        end

        for (int i = 0; i < NUM_ELEMENTS_SECOND_GROUP; i++) begin
                ds_in_out = data_b[i];
                if (i == NUM_ELEMENTS_SECOND_GROUP-1) begin
                    ds_in_last = 1'b1;
                end

                ds_in_valid = 1'b1;

                if (ds_in_next_data == 1'b1) begin
                    #(PERIOD);
                end else begin
                    wait(ds_in_next_data == 1'b1);
                    #(1.25 * PERIOD);
                end

                ds_in_valid = 1'b0;

                #(PERIOD * (AXI_BUS_LATENCY_SIM_WRITE-1));
        end
    end

    // AXI READ A

    integer AXI_BUS_LATENCY_SIM_READ_A = 3;

    always
    begin
        ds_out_a_next_data = 1'b0;

        wait(start == 1'b1);
        #(0.25*PERIOD);

        #PERIOD;

        ds_out_a_next_data = 1'b1;

        for (int i = 0; i < NUM_ELEMENTS_FIRST_GROUP; i++) begin

                if (ds_out_a_valid == 1'b0) begin
                    wait(ds_out_a_valid == 1'b1);
                    #(0.1 * PERIOD);
                end

                assert(ds_out_a == data_a[i])
                else $error($sformatf("Invalid ds_out_a value read on index %d, read '%d' and should be '%d' ", i, ds_out_a, data_a[i]));

                if(i == NUM_ELEMENTS_FIRST_GROUP - 1) begin
                    assert(ds_out_a_last == 1'b1)
                    else $error("Last not correctly asserted (should be 1 and is 0)");
                end else begin
                    assert(ds_out_a_last == 1'b0)
                    else $error("Last not correctly asserted (should be 0 and is 1)");
                end

                #PERIOD;

                ds_out_a_next_data = 1'b0;

                #(PERIOD * (AXI_BUS_LATENCY_SIM_READ_A-1));

                ds_out_a_next_data = 1'b1;
        end
    end

    // AXI READ B
    
    integer AXI_BUS_LATENCY_SIM_READ_B = 4;

    always
    begin
        ds_out_b_next_data = 1'b0;

        wait(start == 1'b1);

        #PERIOD;

        ds_out_b_next_data = 1'b1;

        for (int i = 0; i < NUM_ELEMENTS_SECOND_GROUP; i++) begin

                if (ds_out_b_valid == 1'b0) begin
                    wait(ds_out_b_valid == 1'b1);
                    #(0.1 * PERIOD);
                end

                assert(ds_out_b == data_b[i])
                else $error($sformatf("Invalid ds_out_b value read on index %d, read '%d' and should be '%d' ", i, ds_out_b, data_b[i]));

                if(i == NUM_ELEMENTS_SECOND_GROUP - 1) begin
                    assert(ds_out_b_last == 1'b1)
                    else $error("Last not correctly asserted (should be 1 and is 0)");
                end else begin
                    assert(ds_out_b_last == 1'b0)
                    else $error("Last not correctly asserted (should be 0 and is 1)");
                end

                #PERIOD;

                ds_out_b_next_data = 1'b0;

                #(PERIOD * (AXI_BUS_LATENCY_SIM_READ_A-1));

                ds_out_b_next_data = 1'b1;
        end

    end


    initial begin
        rst = 1'b1;
        start = 1'b0;
        #(3.25*PERIOD);

        rst = 1'b0;

        test_stream_splitter;
        test_stream_splitter;

    end

endmodule