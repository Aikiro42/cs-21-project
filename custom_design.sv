`timescale 1ns / 1ps

// alu.sv
// used by datapath
// uses nothing
// sll implementation: https://stackoverflow.com/a/34100023/9035578
// sll is done in alu
module alu(input  logic [31:0] a, b,
           input  logic [4:0] shamt,
           input  logic [2:0]  alucontrol,
           output logic [31:0] result,
           output logic        zero);
  
  // logic [31:0] condinvb, sum;
  logic [31:0] isdiff, sum;

  assign isdiff = alucontrol[2] ? ~b : b;
  assign sum = a + isdiff + alucontrol[2];

  always_comb
    case (alucontrol[2:0])
      3'b000: result = a & b;       // AND
      3'b001: result = a | b;       // OR
      3'b010: result = sum;         // ADD
      3'b011: result = b << shamt;  // SLL  (rt is shifted)
      3'b110: result = sum;         // SUB
      3'b111: result = sum[31];     // SLT
      default: result = 32'bX;
    endcase

  // result = result << shamt;

  assign zero = (result == 32'b0);
endmodule

// mux2.sv
// used by datapath
// uses nothing
module mux2 #(parameter WIDTH = 8)
             (input  logic [WIDTH-1:0] d0, d1, 
              input  logic             s, 
              output logic [WIDTH-1:0] y);

  assign y = s ? d1 : d0; 
endmodule

// signext.sv
// used by datapath
// uses nothing
module signext(input  logic [15:0] a,
               output logic [31:0] y);
              
  assign y = {{16{a[15]}}, a};
endmodule

// zeroext.sv
// used by datapath
// uses nothing
module zeroext(input  logic [15:0] a,
               output logic [31:0] y);
              
  assign y = {16'b0, a};
endmodule


// regfile.v
// Register file for the single-cycle and multicycle processors
// used by datapath
// uses nothing
module regfile(input  logic        clk, 
               input  logic        we3, 
               input  logic [4:0]  ra1, ra2, wa3, 
               input  logic [31:0] wd3, 
               output logic [31:0] rd1, rd2);

  logic [31:0] rf[31:0];

  // three ported register file
  // read two ports combinationally
  // write third port on rising edge of clk
  // register 0 hardwired to 0
  // note: for pipelined processor, write on
  // falling edge of clk

  always_ff @(posedge clk)
    if (we3) rf[wa3] <= wd3;	

  assign rd1 = (ra1 != 0) ? rf[ra1] : 0;
  assign rd2 = (ra2 != 0) ? rf[ra2] : 0;
endmodule



// sl2
// used by datapath
// uses nothing
module sl2(input  logic [31:0] a,
           output logic [31:0] y);

  // shift left by 2
  assign y = {a[29:0], 2'b00};
endmodule

// 5.1: adder
// used by datapath
// uses nothing
module adder #(parameter N = 8)
              (input  logic [N-1:0] a, b,
               input  logic         cin,
               output logic [N-1:0] s,
               output logic         cout);

  assign {cout, s} = a + b + cin;
endmodule


// flopr.sv
// used by datapath
// uses nothing
module flopr #(parameter WIDTH = 8)
              (input  logic             clk, reset,
               input  logic [WIDTH-1:0] d, 
               output logic [WIDTH-1:0] q);

  always_ff @(posedge clk, posedge reset)
    if (reset) q <= 0;
    else       q <= d;
endmodule

// datapath.sv
// used by mips.sv
// uses flopr, adder, sl2, mux2, regfile, signext, alu
module datapath(input  logic        clk, reset,
                input  logic        memtoreg, pcsrc,
                input  logic        alusrc, regdst,
                input  logic        regwrite, jump,
                input  logic        lessequal, zero_or_a, is_li,
                input  logic [2:0]  alucontrol,
                output logic        zero,
                output logic [31:0] pc,
                input  logic [31:0] instr,
                output logic [31:0] aluout, writedata,
                input  logic [31:0] readdata);

  logic [4:0]  writereg;
  logic [31:0] pcnext, pcnextbr, pcplus4, pcbranch;
  logic [31:0] sign_extended, zero_extended, signimm, signimmsh;
  logic [31:0] srca, srcb, srcx;
  logic [31:0] result;

  logic is_equal;

  // next PC logic
  flopr #(32) pcreg(clk, reset, pcnext, pc);
  adder #(32) pcadd1(pc, 32'b100, 'b0, pcplus4); //So we adjust this to use the more complex adder; wmt-modification
  sl2         immsh(signimm, signimmsh);
  adder #(32) pcadd2(pcplus4, signimmsh, 'b0, pcbranch); //See comment above
  mux2 #(32)  pcbrmux(pcplus4, pcbranch, pcsrc, pcnextbr);
  mux2 #(32)  pcmux(pcnextbr, {pcplus4[31:28], 
                    instr[25:0], 2'b00}, jump, pcnext);

  // register file logic
  regfile     rf(clk, regwrite, instr[25:21], instr[20:16], 
                 writereg, result, srcx, writedata);
  mux2 #(5)   wrmux(instr[20:16], instr[15:11],
                    regdst, writereg);
  mux2 #(32)  resmux(aluout, readdata, memtoreg, result);
  signext     se(instr[15:0], sign_extended);
  zeroext     ze(instr[15:0], zero_extended);

  mux2 #(32)  zero_or_sign(zero_extended, sign_extended, ~is_li, signimm);

  // ALU logic
  mux2 #(32)  srcbmux(writedata, signimm, alusrc, srcb);
  mux2 #(32)  zero_or_a_mux(32'b0, srcx, zero_or_a, srca);
  alu         alu(srca, srcb, instr[10:6], alucontrol, aluout, is_equal);

  assign zero = lessequal ? is_equal | aluout[31] : is_equal;

endmodule

// maindec.sv
// used by controller.sv
// uses nothing
module maindec(input  logic [5:0] op,
               output logic       memtoreg, memwrite,
               output logic       branch, alusrc,
               output logic       regdst, regwrite,
               output logic       jump,
               output logic       lessequal, zero_or_a, is_li, store_byte,
               output logic [1:0] aluop);

  logic [12:0] controls;

  assign {regwrite, regdst, alusrc, branch, memwrite,
          memtoreg, jump, lessequal, zero_or_a, is_li, store_byte, aluop} = controls;

  always_comb
    case(op)
      6'b000000: controls <= 13'b1100000010010; // RTYPE
      6'b100011: controls <= 13'b1010010010000; // LW
      6'b101011: controls <= 13'b0010100010000; // SW
      6'b101000: controls <= 13'b0010100010100; // SB
      6'b000100: controls <= 13'b0001000010001; // BEQ
      6'b011111: controls <= 13'b0001000110001; // BLE
      6'b001000: controls <= 13'b1010000010000; // ADDI
      6'b001001: controls <= 13'b1010000011000; // ADDIU
      6'b000010: controls <= 13'b0000001010000; // J
      6'b010001: controls <= 13'b1010000001000; // LI
      default:   controls <= 13'bxxxxxxxxxxxxx; // illegal op
    endcase
endmodule

// aludec.sv
// used by controller.sv
// uses nothing
module aludec(input  logic [5:0] funct,
              input  logic [1:0] aluop,
              output logic [2:0] alucontrol);

  always_comb
    case(aluop)
      2'b00: alucontrol <= 3'b010;  // add (for lw/sw/addi)
      2'b01: alucontrol <= 3'b110;  // sub (for beq)
      default: case(funct)          // R-type instructions
          6'b000000: alucontrol <= 3'b011; // sll
          6'b100000: alucontrol <= 3'b010; // add
          6'b100010: alucontrol <= 3'b110; // sub
          6'b100100: alucontrol <= 3'b000; // and
          6'b100101: alucontrol <= 3'b001; // or
          6'b101010: alucontrol <= 3'b111; // slt
          default:   alucontrol <= 3'bxxx; // ???
        endcase
    endcase
endmodule


// controller.sv
// used by mips.sv
// uses maindec, aludec
module controller(input  logic [5:0] op, funct,
                  input  logic       zero,
                  output logic       memtoreg, memwrite,
                  output logic       pcsrc, alusrc,
                  output logic       regdst, regwrite,
                  output logic       jump,
                  output logic       lessequal, zero_or_a, is_li, store_byte,
                  output logic [2:0] alucontrol);

  logic [1:0] aluop;
  logic       branch;

  maindec md(op, memtoreg, memwrite, branch,
             alusrc, regdst, regwrite, jump, lessequal, zero_or_a, is_li, store_byte, aluop);

  aludec  ad(funct, aluop, alucontrol);

  assign pcsrc = branch & zero;
endmodule

// mips.sv
// used by top.sv
// uses controller, datapath
module mips(input  logic        clk, reset,
            output logic [31:0] pc,
            input  logic [31:0] instr,
            output logic        memwrite, store_byte,
            output logic [31:0] aluout, writedata,
            input  logic [31:0] readdata);

  logic       memtoreg, alusrc, regdst, 
              regwrite, jump, pcsrc, zero,
              lessequal, zero_or_a, is_li;
  logic [2:0] alucontrol;

  controller c(instr[31:26], instr[5:0], zero,
               memtoreg, memwrite, pcsrc,
               alusrc, regdst, regwrite, jump,
               lessequal, zero_or_a, is_li, store_byte,
               alucontrol);
  datapath dp(clk, reset, memtoreg, pcsrc,
              alusrc, regdst, regwrite, jump,
              lessequal, zero_or_a, is_li,
              alucontrol,
              zero, pc, instr,
              aluout, writedata, readdata);
endmodule

// imem.sv
// used by top.sv
// uses nothing
module imem(input  logic [5:0] a,
            output logic [31:0] rd);

  logic [31:0] RAM[63:0];

  initial
      $readmemh("memfile.mem",RAM);

  assign rd = RAM[a]; // word aligned
endmodule

// dmem.sv
// used by top.sv
// uses nothing
module dmem(input  logic        clk, we, store_byte,
            input  logic [31:0] a, wd,
            output logic [31:0] rd);

  logic [31:0] RAM[63:0];
  logic [31:0] wordmod_mask, wordmod, modded_word;
  int shift;

  assign shift = a[1:0] * 8;

  assign wordmod = {wd[7:0], 24'b0} >> shift;
  assign wordmod_mask = 'hFF000000 >> shift;

  assign rd = RAM[a[31:2]]; // word aligned

  assign modded_word = (rd & ~wordmod_mask) | wordmod;

  always_ff @(posedge clk)
    if (we) RAM[a[31:2]] <= store_byte ? modded_word : wd;
endmodule

// top.sv
// uses mips, imem, dmem
module top(input  logic        clk, reset, 
           output logic [31:0] writedata, dataadr, 
           output logic        memwrite);

  logic [31:0] pc, instr, readdata;
  logic store_byte;
  
  // instantiate processor and memories
  mips mips(clk, reset, pc, instr, memwrite, store_byte, dataadr, 
            writedata, readdata);
  imem imem(pc[7:2], instr);
  dmem dmem(clk, memwrite, store_byte, dataadr, writedata, readdata);
endmodule