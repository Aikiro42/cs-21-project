`timescale 1ns / 1ps

// wordmod.sv
// used by datapath
// takes the original word from memory,
// modifies the particular byte in the word,
// and stores the modded word into memory
module wordmod(
  input logic [31:0] byte_addr,
  input logic [31:0] orig_word,
  input logic [7:0] byte_to_write,
  output logic[31:0] modded_word
);

logic [31:0] wordmod, wordmod_mask;
int shift;

// suppose byte_to_write is 0xXX
// and we want to write it at the third byte (byte_addr[3:0] is thus 0b10)
// then wordmod is 0x0000XX00

assign shift = byte_addr[1:0] * 8;

assign wordmod = {24'b0, byte_to_write} << shift;
assign wordmod_mask = 'h000000FF << shift;

// we have the orig_word, say:            0xC0DEBABE
// and the wordmod:                       0x0000XX00
// and the wordmod_mask:                  0x0000FF00
// what we want is for modded_word to be: 0xC0DEXXBE

assign modded_word = (orig_word & ~wordmod_mask) | wordmod;

endmodule
