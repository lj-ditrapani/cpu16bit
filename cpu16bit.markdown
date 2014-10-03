---------|---------|---------|---------|---------|---------|---------|--

General
-------

- 16-bit CPU
- 16 X 16-bit registers and program counter (PC)
- 2^16 = 65,536 memory addresses (16-bit resolution)
- 16-bit memory cells
- A word is 16 bits (2 bytes)
- 64 KWords = 128 KB = 1 M-bit
- All instructions are 16 bits long
- 16 instructions (4-bit op-code)


Instruction Meaning
-------------------

    0 END    Halt computer
    1 HBY    High byte
    2 LBY    Low byte
    3 LOD    Load
    4 STR    Store
    5 ADD
    6 SUB
    7 ADI    Add 4-bit immediate
    8 SBI    Subtract 4-bit immediate
    9 AND
    A ORR    or
    B XOR    exclusive or
    C NOT
    D SHF    Shift
    E BRN    Branch
    F SPC    Save PC


Instruction operation
--------------------

    0 END
    1 HBY    immd8 -> RD[15-08]
    2 LBY    immd8 -> RD[07-00]
    3 LOD    M[R1] -> RD
    4 STR    R2 -> M[R1]
    5 ADD    RS1 + RS2 -> RD
    6 SUB    RS1 - RS2 -> RD
    7 ADI    RS1 + immd4 -> RD
    8 SBI    RS1 - immd4 -> RD
    9 AND    RS1 and RS2 -> RD
    A ORR    RS1 or RS2 -> RD
    B XOR    RS1 xor RS2 -> RD
    C NOT    ! R1 -> RD
    D SHF    S1 shifted by immd4 -> RD
    E BRN    if (R1 matches NZP) or CV then (R2 -> PC)
    F SPC    PC + 2 -> RD


*SHF*  Shift, zero fill

    Carry contains bit of last bit shifted out
    immd4 format
    DAAA
    D is direction:  0 left, 1 right
    AAA is (amount - 1)
    0-7  ->  1-8
    Assembly:
    SHF R3 L 2 RA ->  $D31A
    SHF R7 R 7 R0 ->  $D7E0


*BRN* M---

    M is mode
    0NZP    0 is value mode (negative zero positive)
    10VC    1 is flag mode (overflow carry)
    0111    unconditional jump (jump if value is Neg, Zero or Positive
    0000    never jump (no operation; NOP)
    1000    jump if carry and overflow are *NOT* set (ignore value)
    1011    jump if carry or overflow are set (probably useless)
    1010    jump if overflow set (don't care about carry)
    1001    jump if carry set (don't care about overflow)

Because you want to handle a carry or overflow situations differently
You may be interested in ensuring NO exceptions (1000). You probably
wouldn't know what to do if both exceptions happened;
just handle each separately
BRN 1011 is probably not useful.


Instruction format
------------------

            Mm Reg   01 02 03
    0 END    - ----    0  0  0
    1 HBY    - --W-   UC UC RD
    2 LBY    - --W-   UC UC RD
    3 LOD    R R-W-   RA  0 RD
    4 STR    W RR--   RA R2  0
    5 ADD    - RRW-   R1 R2 RD
    6 SUB    - RRW-   R1 R2 RD
    7 ADI    - R-W-   R1 UC RD
    8 SBI    - R-W-   R1 UC RD
    9 AND    - RRW-   R1 R2 RD
    A ORR    - RRW-   R1 R2 RD
    B XOR    - RRW-   R1 R2 RD
    C NOT    - R-W-   R1  0 RD
    D SHF    - R-W-   R1 DA RD
    E BRN    - RR-W   RV RP cond
    F SPC    - --W-    0  0 RD


    Nibble 00:  op code
    Nibble 01:  0, high nibble of 8-bit const, Memory address register,
                ALU input 1 register
    Nibble 02:  0, low nibble of 8-bit const,
                data in register to STR DI,
                ALU input 2 register, unsigned const,
                dir & amount for SHF, PC address register
    Nibble 03:  0, cond, destination register to WRITE to
