# cs-21-project

Repository of CS 21 project where I am instructed to add features to an incomplete single-cycle MIPS datapath

Total score so far: 55 points

## Completed Features

### Normal Instructions:

- `sll` _(15 points)_

### Pseudo-instructions

- `ble` _(20 points)_
- `li` _(20 points)_

## Features to complete

### Normal Instructions:

- `sb`

### Custom instructions

- `zfr` (Zero-from-right)

## MIPS-ML Syntax

| Instruction | Binary |
|-------------|--------|
|`li <rt>, <imm>`           |`010001 XXXXX <rt[5]> <imm[16]>`
|`sll <rt>, <rs>, <shamt>`  |`000000 XXXXX <rs[5]> <rt[5]> <shamt[5]> 000000`
|`addi <rt>, <rs>, <imm>`   |`001000 <rs[5]> <rt[5]> <imm[16]>`
|`addiu <rt>, <rs>, <imm>`  |`001001 <rs[5]> <rt[5]> <imm[16]>`
|`sw <rt>, <imm>(<rs>)`     |`101011 <rs[5]> <rt[5]> <imm[16]>`
|`lw <rt>, <imm>(<rs>)`     |`100011 <rs[5]> <rt[5]> <imm[16]>`
|`sb <rt>, <imm>(<rs>)`     |`101000 <rs[5]> <rt[5]> <imm[16]>`
|`add <rd>, <rs>, <rt>`     |`000000 <rs[5]> <rt[5]> <rd[5]> 00000 100000`