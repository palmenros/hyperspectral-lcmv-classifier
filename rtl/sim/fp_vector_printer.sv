module fp_vector_printer#(
    parameter int LENGTH = 3
)();
    localparam WIDTH = 32;

    task automatic print;
        input [WIDTH*LENGTH-1:0] in;
        string strvar;

        strvar = "";
        
        for(int i = 0; i < LENGTH; i++) begin
            strvar = {strvar, $sformatf("%f ", $bitstoshortreal(in[i*WIDTH +: WIDTH]))};
        end

        $display(strvar);
    endtask //automatic

    task automatic print_str;
        input string strvar;
        input [WIDTH*LENGTH-1:0] in;

         for(int i = 0; i < LENGTH; i++) begin
            strvar = {strvar, $sformatf("%f ", $bitstoshortreal(in[i*WIDTH +: WIDTH]))};
        end

        $display(strvar);
    endtask //automatic

    task automatic print_str_scientific_notation;
        input string strvar;
        input [WIDTH*LENGTH-1:0] in;

         for(int i = 0; i < LENGTH; i++) begin
            strvar = {strvar, $sformatf("%e ", $bitstoshortreal(in[i*WIDTH +: WIDTH]))};
        end

        $display(strvar);
    endtask //automatic


endmodule