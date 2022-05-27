`timescale 1ns / 1ps

module sll_testbench();
    logic clk;

    logic [31:0] test_addr, test_orig_word, modded_word;
    logic [7:0] test_byte_to_write;

    wordmod instantiated_wordmod(test_addr, test_orig_word, test_byte_to_write, modded_word);

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
        clk = 0;
        test_addr = 'h81234560; test_orig_word = 'hAAAAAAAA; test_byte_to_write = 'hFF; #2;
        test_addr = 'h81234561; test_orig_word = 'hAAAAAAAA; test_byte_to_write = 'hFF; #2;
        test_addr = 'h81234562; test_orig_word = 'hAAAAAAAA; test_byte_to_write = 'hFF; #2;
        test_addr = 'h81234563; test_orig_word = 'hAAAAAAAA; test_byte_to_write = 'hFF; #2;
        test_addr = 'h81234564; test_orig_word = 'hAAAAAAAA; test_byte_to_write = 'hFF; #2;
        test_addr = 'h81234565; test_orig_word = 'hAAAAAAAA; test_byte_to_write = 'hFF; #2;
        test_addr = 'h81234566; test_orig_word = 'hAAAAAAAA; test_byte_to_write = 'hFF; #2;
        test_addr = 'h81234567; test_orig_word = 'hAAAAAAAA; test_byte_to_write = 'hFF; #2;
    end

    // loop clock
    always begin
        clk = ~clk; #1;
    end
endmodule