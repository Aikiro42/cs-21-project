// sll
// shifts to the left by shamt
// used by nothing
// uses nothing
module sll(input  logic [31:0] a,
           input  logic [4:0] shamt,
           output logic [31:0] y);

  // shift left by 2
  assign y = a << shamt;
endmodule