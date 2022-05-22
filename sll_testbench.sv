`timescale 1ns / 1ps;

module sll_testbench();
    logic clk;

    logic [31:0] a, y;
    logic [4:0] shamt;

    sll instantiated_sll(a, shamt, y);

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
        clk = 0;
        a = 'b101101; shamt = 'b00000; #2;
        a = 'b101101; shamt = 'b00001; #2;
        a = 'b101101; shamt = 'b00010; #2;
    end

    // loop clock
    always begin
        clk = ~clk; #1;
    end
endmodule