// Copypasta of given testbench for the first instruction
// result checking is altered to check whether the stored data is correct
// reset time was also changed so that reset is held for exactly 2 cycles
`timescale 1ns / 1ps
module testbench();

  logic        clk;
  logic        reset;

  logic [31:0] writedata, dataadr;
  logic        memwrite;

  // instantiate device to be tested
  top dut(clk, reset, writedata, dataadr, memwrite);
  
  // initialize test
  initial
    begin
      $dumpfile("dump.vcd");
      $dumpvars;
      reset <= 1; # 20; reset <= 0;
    end

  // generate clock to sequence tests
  always
    begin
      clk <= 1; # 5; clk <= 0; # 5;
    end

  // check results
  always @(negedge clk)
    begin
      if(memwrite) begin
        if(dataadr === 16 & writedata === 'hbbaab2d6) begin
          $display("Simulation succeeded");
          $stop;
        end else if (writedata === 'hbbaab2d6) begin
          $display("Simulation failed");
          $stop;
        end
      end
    end
endmodule
