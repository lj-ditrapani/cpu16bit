LJD 16-bit processor
====================

This is the old design.  For the new design, see <https://github.com/lj-ditrapani/16-bit-computer-specification>.

Design:
-------

- 16-bit CPU
- 16 X 16-bit registers and program counter (PC)
- 2^16 = 65,536 memory addresses (16-bit resolution)
- 16-bit memory cells
- A word is 16 bits (2 bytes)
- 64 KWords = 128 KB = 1 M-bit
- All instructions are 16 bits long
- 16 instructions (4-bit op-code)

The processor instruction set architecture (ISA) can be found in
[doc/ISA.markdown](doc/ISA.markdown).

Author:  Lyall Jonathan Di Trapani
