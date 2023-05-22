module simple_dual_port_mem #(
    parameter DEPTH = 3,
    parameter DATA_WIDTH = 32,
    parameter LATENCY = 2,

    parameter BRAM_PRIMITIVE = 0,

    localparam ADDR_WIDTH = $clog2(DEPTH)
) (
    input logic clka,
    input logic ena,
    input logic[0:0] wea,
    input logic[ADDR_WIDTH-1:0] addra,
    input logic[DATA_WIDTH-1:0] dina,

    input logic clkb,
    input logic enb,
    input logic[ADDR_WIDTH-1:0] addrb,
    output logic[DATA_WIDTH-1:0] doutb
);

generate

if (BRAM_PRIMITIVE == 1) begin 

    if (LATENCY == 2) begin
        if (DEPTH == 3 && DATA_WIDTH == 32) begin
            blk_mem_32_3 u_blk_mem_32_3 (.*);
        end else if (DEPTH == 4 && DATA_WIDTH == 32) begin
            blk_mem_32_4 u_blk_mem_32_4 (.*);
        end else if (DEPTH == 5 && DATA_WIDTH == 32) begin
            blk_mem_32_5 u_blk_mem_32_5 (.*);
        end else if (DEPTH == 11 && DATA_WIDTH == 32) begin
            blk_mem_32_11 u_blk_mem_32_11 (.*);
        end else if (DEPTH == 15 && DATA_WIDTH == 32) begin
            blk_mem_32_15 u_blk_mem_32_15 (.*);    
        end else if (DEPTH == 169 && DATA_WIDTH == 32) begin
            blk_mem_32_169 u_blk_mem_32_169 (.*);
        end else if (DEPTH == 5 && DATA_WIDTH == 160) begin
            blk_mem_160_5 u_blk_mem_160_5(.*);
        end else if (DEPTH == 11 && DATA_WIDTH == 352) begin
            blk_mem_352_11 u_blk_mem_352_11(.*);
        end else if (DEPTH == 120 && DATA_WIDTH == 3840) begin
            blk_mem_3840_120 u_blk_mem_160_5(.*);
        end else if (DEPTH == 169 && DATA_WIDTH == 5408) begin
            
            blk_mem_2688_169 u_blk_mem_2688_169(
            	.clka  (clka  ),
                .ena   (ena   ),
                .wea   (wea   ),
                .addra (addra ),
                .dina  (dina[2688-1:0]  ),
                .clkb  (clkb  ),
                .enb   (enb   ),
                .addrb (addrb ),
                .doutb (doutb[2688-1:0] )
            );
            
            blk_mem_2720_169 u_blk_mem_2720_169(
            	.clka  (clka  ),
                .ena   (ena   ),
                .wea   (wea   ),
                .addra (addra ),
                .dina  (dina[5408-1:2688]  ),
                .clkb  (clkb  ),
                .enb   (enb   ),
                .addrb (addrb ),
                .doutb (doutb[5408-1:2688] )
            );

        end else if (DEPTH == 4 && DATA_WIDTH == 128) begin
            blk_mem_128_4 u_blk_mem_128_4(.*);
        end else begin
            $fatal(1, "BRAMs not generated for selected simple dual port memory size."); 
        end
    end else begin
        $fatal(1, "BRAMs not generated for selected latency");
    end
end else begin
    
    logic [DATA_WIDTH-1:0] ram [DEPTH-1:0];

    always @(posedge clka) begin
        if (ena) begin
            if (wea)
                ram[addra] <= dina;
        end
    end

    logic[DATA_WIDTH-1:0] res1;
    
    always @(posedge clkb) begin
        res1 <= ram[addrb];
    end

    always @(posedge clkb) begin
        if (enb) begin
            doutb <= res1;        
        end
    end

end

endgenerate
    
endmodule