module ldl_decomposer #(
    parameter NUM_ROWS = 4, /* Number of rows and columns of the matrix */
    parameter WIDTH = 32, /* Size in bits of each scalar of the matrix */
    parameter DIVIDER_LATENCY = 28,

    localparam ROW_ADDR_WIDTH = $clog2(NUM_ROWS), /* Width of the address of columns and rows */
    localparam ROW_SIZE = NUM_ROWS * WIDTH, /* Size of a row or a column */
    
    // Width to be used by registers j and k
    // They need to store an extra number compared to the width indices
    // That number is the number of rows
    localparam INDEX_REGISTER_WIDTH = $clog2(NUM_ROWS+1)
) (

    // LDL Decomposition ports
    input logic rst,
    input logic clk,

    input logic start,
    output logic finished,


    /* ----------------------------------------------------------- */
    //                   MATRIX MEMORY PORTS
    /* ----------------------------------------------------------- */
    
    // This module does NOT instantiate a matrix memory, it gets ports to interact 
    // with an already instantiated matrix

    output logic [ROW_ADDR_WIDTH-1:0] row_addr,
    output logic row_addr_ready,
    input logic row_valid,
    input logic [ROW_SIZE-1:0] row_out,

    /* The module does not need to read matrices column by column */

    //output logic [ROW_ADDR_WIDTH-1:0] col_addr,
    //output logic col_addr_ready,
    //input logic col_valid,
    //input logic [ROW_SIZE-1:0] col_out,

    // Element writing port
    output logic [ROW_ADDR_WIDTH-1:0] write_row_addr,
    output logic [ROW_ADDR_WIDTH-1:0] write_col_addr,
    output logic [WIDTH-1:0] write_data,
    output logic write_ready,

    /* ----------------------------------------------------------- */
    //                  FP VECTOR MULT ALU PORTS
    /* ----------------------------------------------------------- */

    // This module does NOT instantiate a fp vector multiplication ALU, it gets ports to interact 
    // with an already instantiated fp vector multiplication ALU

    output logic [WIDTH*NUM_ROWS-1:0] dot_product_a,
    output logic [WIDTH*NUM_ROWS-1:0] dot_product_b,
    output logic [WIDTH-1:0] dot_product_c,

    // dot_product_out = a*b+c
    input logic [WIDTH-1:0] dot_product_out,

    // We don't have to sum all the entries of the vectors, we have a logic per element that tells us
    // if we need to take into account that element for the dot product
    output logic [NUM_ROWS-1:0] dot_product_enable,

    output logic [WIDTH*NUM_ROWS-1:0] vector_mult_in_a,
    output logic [WIDTH*NUM_ROWS-1:0] vector_mult_in_b, 
    input logic [WIDTH*NUM_ROWS-1:0] vector_mult_out,

    
    output logic vector_mult_alu_ready,
    input logic dot_product_valid,
    input logic vector_mult_valid,

    // If dot_product_mode = 1, the ALU will be configured to act as the dot product,
    // else, it will act as a vector multiplier
    output logic dot_product_mode,

    /* ----------------------------------------------------------- */
    //                  D VECTOR REGISTER PORTS
    /* ----------------------------------------------------------- */
    
    // This module does NOT instantiate the vector register for the 
    // output D, it gets ports to interact with an already instantiated
    // vector register

    input logic[ROW_SIZE-1:0] d_out,

    // We won't load any value onto the d register, we'll write element by element

    // output logic d_load,
    // output logic[ROW_SIZE-1:0] d_in,

    // Slicing read
    output logic[ROW_ADDR_WIDTH-1:0] d_read_index,
    input logic[WIDTH-1:0] d_slice_out,

    // Slicing write
    output logic[ROW_ADDR_WIDTH-1:0] d_write_index,
    output logic[WIDTH-1:0] d_slice_in,
    output logic d_write_slice

);
    
    /* ----------------------------------------------------------- */
    //                  VECTOR REGISTERS
    /* ----------------------------------------------------------- */

    // R

    logic r_load;
    logic[ROW_SIZE-1:0] r_in, r_out;
    logic[ROW_ADDR_WIDTH-1:0] r_read_index;
    logic[WIDTH-1:0] r_slice_out;

    // vector_reg_no_write_slice
    // #(
    //     .SCALAR_BITS (WIDTH ),
    //     .LENGTH      (NUM_ROWS)
    // )
    // u_vector_reg_r(
    //     .clk         (clk    ),
    //     .load        (r_load ),
    //     .in          (r_in   ),
    //     .out         (r_out  ),
    //     .read_index  (r_read_index  ),
    //     .slice_out   (r_slice_out   )
    // );

    assign r_slice_out = r_in[r_read_index*WIDTH +: WIDTH];
    assign r_out = r_in;

    // V
    
    logic v_load;
    logic[ROW_SIZE-1:0] v_in, v_out;

    register_no_rst 
    #(
        .WIDTH (WIDTH * NUM_ROWS)
    )
    u_reg_v (
    	.clk  (clk ),
        .load (v_load),
        .in   (v_in  ),
        .out  (v_out )
    );
    
    /* ----------------------------------------------------------- */
    //                SCALAR CONTROL REGISTERS
    /* ----------------------------------------------------------- */
    
    // div_gate
    logic div_gate_load, div_gate_in, div_gate_out;

    register 
    #(
        .WIDTH (1)
    )
    u_register_div_gate(
    	.clk  (clk  ),
        .rst  (rst  ),
        .load (div_gate_load ),
        .in   (div_gate_in   ),
        .out  (div_gate_out  )
    );

    // dp_mode
    logic dp_mode_load, dp_mode_in, dp_mode_out;

    register 
    #(
        .WIDTH (1)
    )
    u_register_dp_mode(
    	.clk  (clk  ),
        .rst  (rst  ),
        .load (dp_mode_load ),
        .in   (dp_mode_in   ),
        .out  (dp_mode_out  )
    );
    
    // fulfiller_released
    logic fulfiller_released_load, fulfiller_released_in, fulfiller_released_out;

    register 
    #(
        .WIDTH (1)
    )
    u_register_fulfiller_released(
    	.clk  (clk  ),
        .rst  (rst  ),
        .load (fulfiller_released_load ),
        .in   (fulfiller_released_in   ),
        .out  (fulfiller_released_out  )
    );
    
    /* ----------------------------------------------------------- */
    //                          INDEX REGISTERS
    /* ----------------------------------------------------------- */
    
    // J

    logic j_load;
    logic[INDEX_REGISTER_WIDTH-1:0] j_in, j_out;

    register 
    #(
        .WIDTH (INDEX_REGISTER_WIDTH)
    )
    u_register_j(
    	.clk  (clk  ),
        .rst  (rst  ),
        .load (j_load ),
        .in   (j_in   ),
        .out  (j_out  )
    );
    
    // K

    logic k_load;
    logic[INDEX_REGISTER_WIDTH-1:0] k_in, k_out;

    register 
    #(
        .WIDTH (INDEX_REGISTER_WIDTH)
    )
    u_register_k(
    	.clk  (clk  ),
        .rst  (rst  ),
        .load (k_load ),
        .in   (k_in   ),
        .out  (k_out  )
    );

    // K_F

    logic kf_load;
    logic[INDEX_REGISTER_WIDTH-1:0] kf_in, kf_out;

    register 
    #(
        .WIDTH (INDEX_REGISTER_WIDTH)
    )
    u_register_kf(
    	.clk  (clk  ),
        .rst  (rst  ),
        .load (kf_load ),
        .in   (kf_in   ),
        .out  (kf_out  )
    );

    /* ----------------------------------------------------------- */
    //                      SHIFT REGISTER
    /* ----------------------------------------------------------- */

    logic dpen_load, dpen_shift, dpen_shift_in;
    logic [NUM_ROWS-1:0] dpen_load_data, dpen_out;

    shift_register 
    #(
        .WIDTH       (NUM_ROWS),
        .SHIFT_RIGHT (1'b0)
    )
    u_shift_register_dp_enable(
    	.clk       (clk       ),
        .rst       (rst       ),
        .load_data (dpen_load_data ),
        .shift_in  (dpen_shift_in  ),
        .load      (dpen_load      ),
        .shift     (dpen_shift     ),
        .out       (dpen_out       )
    );
    
    /* ----------------------------------------------------------- */
    //                    ARITHMETIC HARDWARE
    /* ----------------------------------------------------------- */

    logic div_ready, div_valid;
    logic [WIDTH-1:0] div_a, div_b, div_o;

    fp_divider 
    #(
        .WIDTH   (WIDTH   ),
        .LATENCY (DIVIDER_LATENCY )
    )
    u_fp_divider(
    	.clk   (clk   ),
        .rst   (rst   ),
        .a     (div_a  ),
        .b     (div_b  ),
        .o     (div_o  ),
        .ready (div_ready ),
        .valid (div_valid )
    );

    // Inverter placed at the ALU output (do)

    logic[WIDTH-1:0] fp_inv_do_in, fp_inv_do_out;

    fp_inverter 
    #(
        .WIDTH (WIDTH )
    )
    u_fp_inverter_div_out(
    	.in  (fp_inv_do_in  ),
        .out (fp_inv_do_out )
    );
    
    // Inverter placed at the ALU input (di)

    logic[WIDTH-1:0] fp_inv_di_in, fp_inv_di_out;

    fp_inverter 
    #(
        .WIDTH (WIDTH )
    )
    u_fp_inverter(
    	.in  (fp_inv_di_in  ),
        .out (fp_inv_di_out )
    );

    /* ----------------------------------------------------------- */
    //                HARDWARE WIRE CONNECTIONS
    /* ----------------------------------------------------------- */

    logic load_j;

    assign row_addr = load_j ? j_out : k_out;
    
    assign write_row_addr = kf_out;
    assign write_col_addr = j_out;
    assign write_data = div_o;

    assign r_in = row_out;
    assign r_read_index = j_out;

    assign dot_product_a = r_out;
    assign dot_product_b = v_out;
    assign dot_product_c = fp_inv_di_out;
    assign dot_product_enable = dpen_out;
    assign vector_mult_in_a = r_out;
    assign vector_mult_in_b = d_out;
    assign dot_product_mode = dp_mode_out;

    assign dpen_load_data = '0;
    assign dpen_shift_in = 1'b1; 

    assign fp_inv_di_in = r_slice_out;
    assign fp_inv_do_in = dot_product_out;
    assign d_slice_in = fp_inv_do_out;
    assign div_a = fp_inv_do_out;

    assign d_write_index = j_out;
    assign d_read_index = j_out;

    assign div_b = d_slice_out;
    assign div_ready = div_gate_out && dot_product_valid;

    assign v_in = vector_mult_out;


    /* ----------------------------------------------------------- */
    //        CONTROL SIGNALS BETWEEN FULFILLER AND ISSUER 
    /* ----------------------------------------------------------- */

    logic start_fulfiller;

    /* ----------------------------------------------------------- */
    //                  ISSUER STATE MACHINE
    /* ----------------------------------------------------------- */
    
    typedef enum { s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12 } state_issuer_t;
    state_issuer_t state_issuer_reg, state_issuer_next;

    always_ff @( posedge clk ) begin
        if (rst) begin
            state_issuer_reg <= s0;
        end else begin
            state_issuer_reg <= state_issuer_next;
        end
    end

    // Issuer next_state
    always_comb begin : issuer_next_state
        unique case (state_issuer_reg)
            s0: 
                if(start)
                    state_issuer_next = s1;
                else
                    state_issuer_next = s0;
            s1:
                state_issuer_next = s2;
            s2:
                if(row_valid)
                    state_issuer_next = s3;
                else
                    state_issuer_next = s2;
            s3:
                state_issuer_next = s4;
            s4:
                if(vector_mult_valid)
                    state_issuer_next = s5;
                else
                    state_issuer_next = s4;
            s5:
                state_issuer_next = s6;
            s6:
                if(k_out == NUM_ROWS)
                    state_issuer_next = s10;
                else
                    state_issuer_next = s7;
            s7:
                state_issuer_next = s8;
            s8: 
                if(row_valid)
                    state_issuer_next = s9;
                else
                    state_issuer_next = s8;
            s9:
                state_issuer_next = s6;
            s10: 
                if (fulfiller_released_out)
                    state_issuer_next = s11;
                else
                    state_issuer_next = s10;
            s11:
                if (j_out + 1 == NUM_ROWS)
                    state_issuer_next = s12;
                else
                    state_issuer_next = s1;
            s12:
                state_issuer_next = s0;
        endcase
    end

    // Issuer outputs
    always_comb begin : issuer_outputs

        dp_mode_in = 1'b0;
        dp_mode_load = 1'b0;
        dpen_load = 1'b0;
        dpen_shift = 1'b0;
        j_in = 0;
        j_load = 1'b0;
        k_in = 0;
        k_load = 1'b0;
        load_j = 1'b0;
        r_load = 1'b0;
        row_addr_ready = 1'b0;
        start_fulfiller = 0;
        v_load = 1'b0;  
        vector_mult_alu_ready = 1'b0;
        finished = 1'b0;

        unique case (state_issuer_reg)
            s0: begin
                j_in = 0;
                j_load = 1'b1;
                dpen_load = 1'b1;
            end
            s1: begin
                load_j = 1'b1;
                row_addr_ready = 1'b1;
            end
            s2: begin
                load_j = 1'b1;
                r_load = 1'b1;
                dp_mode_in = 1'b0;
                dp_mode_load = 1'b1;
            end
            s3: begin
                load_j = 1'b1;
                vector_mult_alu_ready = 1'b1;
            end
            s4: begin
                load_j = 1'b1;
                v_load = 1'b1;  
                if(vector_mult_valid) begin
                   dp_mode_in = 1'b1;
                   dp_mode_load = 1'b1;
                end
            end
            s5: begin
                load_j = 1'b1;
                vector_mult_alu_ready = 1'b1;

                k_in = j_out + 1;
                k_load = 1'b1;
                start_fulfiller = 1;
            end
            s6: begin
                start_fulfiller = 0;
            end
            s7: begin
                load_j = 1'b0;
                row_addr_ready = 1'b1;
            end
            s8: begin
                r_load = 1'b1;
            end
            s9: begin
                k_in = k_out + 1;
                k_load = 1'b1;

                vector_mult_alu_ready = 1'b1;
            end
            s10: begin
                // No control signals
            end
            s11: begin
                dpen_shift = 1'b1;
                j_in = j_out + 1;
                j_load = 1'b1;
            end
            s12: begin
                finished = 1'b1;
            end
        endcase
    
    end

    /* ----------------------------------------------------------- */
    //                  FULFILLER STATE MACHINE
    /* ----------------------------------------------------------- */

    typedef enum {sf_0, sf_1, sf_2, sf_3} state_fulfiller_t;
    state_fulfiller_t state_fulfiller_reg, state_fulfiller_next;

    always_ff @( posedge clk ) begin
        if (rst) begin
            state_fulfiller_reg <= sf_0;
        end else begin
            state_fulfiller_reg <= state_fulfiller_next;
        end
    end

    // Fulfiller next_state
    always_comb begin : fulfiller_next_state
        unique case (state_fulfiller_reg)
            sf_0:
                if (start_fulfiller)
                    state_fulfiller_next = sf_1;
                else
                    state_fulfiller_next = sf_0;
            sf_1:
                if (dot_product_valid) begin
                    if (kf_out == NUM_ROWS) begin
                        state_fulfiller_next = sf_3;                        
                    end else begin
                        state_fulfiller_next = sf_2;
                    end
                end else begin
                    state_fulfiller_next = sf_1;
                end
            sf_2:
                if(kf_out == NUM_ROWS)
                    state_fulfiller_next = sf_3;
                else
                    state_fulfiller_next = sf_2;
            sf_3:
                state_fulfiller_next = sf_0;
        endcase
    end

    // Fulfiller outputs
    always_comb begin : fulfiller_outputs
        
        d_write_slice = 1'b0;
        div_gate_in = 1'b0;
        div_gate_load = 1'b0;
        fulfiller_released_in = 0;
        fulfiller_released_load = 1'b0;
        kf_in = 0;
        kf_load = 1'b0;
        write_ready = 1'b0;

        unique case (state_fulfiller_reg) 
            sf_0: begin
                kf_in = j_out + 1;
                kf_load = 1'b1;
                write_ready = 1'b0;
                fulfiller_released_in = 0;
                fulfiller_released_load = 1'b1;
                div_gate_in = '0;
                div_gate_load = 1'b1;
            end
            sf_1: begin
                d_write_slice = dot_product_valid;
                div_gate_in = dot_product_valid;
                div_gate_load = 1'b1;
            end
            sf_2: begin
                write_ready = div_valid;

                kf_in = kf_out + 1;
                kf_load = div_valid;
            end
            sf_3: begin                
                fulfiller_released_in = 1;
                fulfiller_released_load = 1'b1;

                div_gate_in = 1'b0;
                div_gate_load = 1'b1;
            end
        endcase
    end

endmodule