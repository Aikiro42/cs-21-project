# Modified Single-cycle MIPS Processor

![](docu_assets/datapath_schema.png)
_Figure 1. Datapath modified to execute more instructions. Modifications are colored purple, red and green. Control lines are colored blue. Instruction and data lines are colored deep orange.The ALU is also modified, as indicated by the pencil symbol._

This project modifies the MIPS processor from Lab 12 such that it can execute the following instructions:

1. Shift left logical (`sll`),
2. Branch if less than or equal (`ble`),
3. Load immediate (`li`),
4. Store byte (`sb`), and
5. Zero-from-right (`zfr`), a custom instruction.

Each of the instructions above are implemented in that order.

<!--
## TODO
- Documentation
    - Filename: `alvarado_enriqueluis_201911112_lab1.pdf`
- Instruction Video:
    - Per instruction: 
        - HDL Edits
        - Testbench
        - Test Code
        - Demonstration
- Zip this repo up

### Normal Instructions:

- `sll` _(ALU Modification)_
- `sb` _(Data Memory Modification)_

### Pseudo-instructions

- `ble` _(Datapath Modification)_
- `li` _(Datapath Modification)_
- Custom instruction: `zfr` _(ALU Modification)_

-->

# Shift left logical (`sll`)

|Instruction syntax|Machine Code Translation|
|-|-|
|`sll <rt>, <rs>, <shamt>`  |`000000 XXXXX <rs[5]> <rt[5]> <shamt[5]> 000000`

Shift left logical (`sll`) shifts the bits in register `<rs>` `<shamt>` bits to the left and stores the result in `<rt>`. `<shamt>` is a 5-bit unsigned integer, which means that it can shift to, at most, 31 bits to the left.

## HDL Modifications

The `sll` instruction was implemented by modifying the `alu` module to take a 5-bit `shamt` input. The `shamt` bits from the passed instruction (`instr[10:6]`) are sent to this input:

![](docu_assets/sll_codemod_01.png)
_Figure 2. Modification done to the `datapath` module._

The `alu` module was also modified such that it now switches based on all bits of the `alucontrol` input. This way, the control code `011` is easily defined to be the code for the shift-left-logical operation:

![](docu_assets/sll_codemod_02.png)
_Figure 3. Modification done to the `alu` module._

The second source was chosen based on how `sll` is described in the MIPS greensheet.

Finally, the ALU decoder was modified (because `sll` is an R-type instruction) such that the function code `000000` is decoded for the `sll` instruction, as defined in the MIPS greensheet.

![](docu_assets/sll_codemod_03.png)
_Figure 4. Modification done to the `aludec` module._

## Testing

The code used to test the correctness of the HDL modifications is basically modified code from the exercise given in Lab 12.


1.  The first step is to replicate the `lui` instruction, particularly upper-loading `0xBBAA` to register `$1`. This is done in the next two steps. In this step, `0x5DD5` is "loaded" to register 1 via the `addi` instruction. (This is because `sll` is the first instruction implemented in the project; `li` has not been implemented yet.)

    Loading `0x5DD5` is a programming artifact from the last lab. Since shifting involved doubling the register's value, and immediately "loading" a value that has an MSB of 1 results in the register value turning negative, the desired value to be loaded was first shifted to the right. This is possible because the LSB of the desired value, `0xBBAA`, is zero, therefore not causing a loss of information.
    ```mips
    addi $1, $0, 0x5DD5
    # 001000 00000 00001 0101 1101 1101 0101
    # 20015DD5
    ```
2. To finally upper-load `0xBBAA` into register `$1`, the `sll` instruction is used to shift the lower bytes to the upper bytes.
    ```mips
    sll $1, $1, 17
    # 000000 11010 00001 00001 10001 000000
    # 03410C40
    ```

3. Next, 176 is "loaded" into register `$2`.
    ```mips
    addi $2, $0, 176
    # 001000 00000 00010 0000 0000 1011 0000
    # 200200B0
    ```

4. 45606 will then be "loaded" into register `$7`. Again, "loading" half of the desired value is an artifact from the code from the previous lab (as explained in step 1), but this serves our purpose of thoroughly testing the don't-care fields of the newly implemented instruction.
    ```mips
    addi $7, $0, 22803
    # 001000 00000 00111 0101 1001 0001 0011
    # 20075913
    ```

5. To properly load the desired value of 45606, the bits in register `$7` are shifted to the left by one.
    ```mips
    sll $7, $7, 1
    # 000000 00111 00111 00111 00001 000000
    # 00E73840
    ```

6. Add the values stored in registers `$2` and `$7` and store them in register `$3`.
    ```mips
    add $3, $2, $7
    # 000000 00010 00111 00011 00000 100000
    # 00471820
    ```

7. Add the values stored in registers `$1` and `$3` and store them in register `$4`.
    ```mips
    add $4, $1, $3
    # 000000 00001 00011 00100 00000 100000
    # 00232020
    ```

8. Load 16 into register `$5`. This register will hold the memory address where we will write the value stored in register `$4`.
    ```mips
    addi $5, $0, 16
    # 001000 00000 00101 0000 0000 0001 0000
    # 20050010
    ```

9. Store the word stored in register `$4` in the memory address specified by register `$5`, without offset.
    ```mips
    sw $4, 0($5)
    # 101011 00101 00100 0000 0000 0000 0000
    # ACA40000
    ```

In essence, testing the `sll` implementation involved replacing the shift-loops with the instruction, with randomized `<rs>` fields.

Hence, the instruction memory file that was used for testing contains the following data:
```
20015DD5
03410C40
200200B0
20075913
00E73840
00471820
00232020
20050010
ACA40000
```
_Code snippet 1. Contents of the `memfile.mem` used for testing the `sll` implementation._

## Results

The final version of the modified processor is used in testing to ensure harmony among all newly implemented instructions. The second testbench meant to run the original version of the aforementioned code is used to test the correctness of this implementation.

The implementation is thus correct since the kernel prints "Simulation succeeded":

![](docu_assets/sll_proof_01.png)
_Figure 5. Proof of correct `sll` implementation._

The following parts of the waveform further show the correctness of this implementation:

![](docu_assets/sll_proof_02.png)
_Figure 6. Further proof of correct `sll` implementation._

From the above waveform, we can see that the instructions specified by the `instr[31:0]` row behave as expected, correctly shifting our values to the left.

# Appendix

## I. MIPS-ML Translation table

| Instruction | Binary |
|-------------|--------|
|`li <rt>, <imm>`           |`010001 XXXXX <rt[5]> <imm[16]>`
|`sll <rt>, <rs>, <shamt>`  |`000000 XXXXX <rs[5]> <rt[5]> <shamt[5]> 000000`
|`addi <rt>, <rs>, <imm>`   |`001000 <rs[5]> <rt[5]> <imm[16]>`
|`addiu <rt>, <rs>, <imm>`  |`001001 <rs[5]> <rt[5]> <imm[16]>`
|`sw <rt>, <imm>(<rs>)`     |`101011 <rs[5]> <rt[5]> <imm[16]>`
|`lw <rt>, <imm>(<rs>)`     |`100011 <rs[5]> <rt[5]> <imm[16]>`
|`sb <rt>, <imm>(<rs>)`     |`101000 <rs[5]> <rt[5]> <imm[16]>`
|`add <rd>, <rs>, <rt>`     |`000000 <rs[5]> <rt[5]> <rd[5]> XXXXX 100000`
|`zfr <rd>, <rs>, <rt>`     |`000000 <rs[5]> <rt[5]> <rd[5]> XXXXX 110011`
|`ble <rs>, <rt>, <offset>` |`011111 <rs[5]> <rt[5]> <offset[16]>`