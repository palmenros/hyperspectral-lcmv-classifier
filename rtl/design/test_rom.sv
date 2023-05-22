module test_rom  
# (
    parameter string ROM_NAME = "test_w_1", 
    parameter DEPTH = 33,

    parameter MEMORY_LATENCY = 2,
    parameter WIDTH = 32,
    localparam ADDR_WIDTH = $clog2(DEPTH)
) (
    input logic clk,
    input logic rst,

    input logic ready,
    output logic valid,

    input logic[ADDR_WIDTH-1:0] addr,
    output logic[WIDTH-1:0] dout
);

register_delay 
#(
    .REG_WIDTH    (1),
    .DELAY_CYCLES (MEMORY_LATENCY)
)
u_register_delay(
    .clk (clk ),
    .rst (rst ),
    .in  (ready),
    .out (valid)
);


generate
    
    if (MEMORY_LATENCY == 2) begin       

        if (ROM_NAME == "test_w_1") begin
            if (DEPTH == 33) begin
                       
                test_rom_w_1 u_test_rom_w_1(
                    .clka  (clk  ),
                    .addra (addr),
                    .douta (dout)
                );
            
            end else begin
                $fatal(1, "Invalid parameter for test_rom, selected DEPTH does not match ROM_NAME.");
            end

        end else if (ROM_NAME == "test_tc_1") begin

            if (DEPTH == 70) begin
                       
                test_rom_tc_1 u_test_rom_tc_1(
                    .clka  (clk  ),
                    .addra (addr),
                    .douta (dout)
                );
            
            end else begin
                $fatal(1, "Invalid parameter for test_rom, selected DEPTH does not match ROM_NAME.");
            end

        end else if (ROM_NAME == "test_x_1") begin

            if (DEPTH == 550) begin
                       
                test_rom_x_1 u_test_rom_x_1(
                    .clka  (clk  ),
                    .addra (addr),
                    .douta (dout)
                );
            
            end else begin
                $fatal(1, "Invalid parameter for test_rom, selected DEPTH does not match ROM_NAME.");
            end

        end else begin
            $fatal(1, "Invalid parameter for test_rom, ROM_NAME not found.");
        end            
    
    end else begin
        $fatal(1, "Invalid parameter for test_rom, rom not instantiated for selected MEMORY_LATENCY.");
    end


endgenerate
    
endmodule