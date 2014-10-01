###
Author:  Lyall Jonathan Di Trapani
Specification for 16 bit CPU simulator
---------|---------|---------|---------|---------|---------|---------|--
###

cpu16bit = ljd.cpu16bit

test 'loadProgram', ->
  program = [
    1
    2
    3
    4
    5
  ]
  @cpu.loadProgram program
  equal @ram[0], 1
  equal @ram[4], 5

test 'adding program', ->
  # RA (register 10) is used for all addresses
  # A is stored in M[0100]
  # B is stored in M[0101]
  # Add A and B and store in M[0102]
  # Put A in R1
  # Put B in R2
  # Add A + B and put in R3
  # Store R3 into M[0102]
  program = [
    0x101A    # HBY 0x01 RA
    0x200A    # LBY 0x00 RA
    0x3A01    # LOD RA R1
    0x201A    # LBY 0x01 RA
    0x3A02    # LOD RA R2
    0x5123    # ADD R1 R2 R3
    0x202A    # LBY 0x02 RA
    0x4A30    # STR RA R3
    0x0000    # END
  ]
  @ram[0x0100] = 27
  @ram[0x0101] = 73
  @cpu.loadProgram program
  @cpu.run()
  equal @ram[0x0102], 100, "27 + 73 = 100"
  equal @cpu.pc, 8, "PC = 8"

test 'branching program', ->
  # RA (register 10) is used for all value addresses
  # RB has address of 2nd branch
  # RC has address of final, common, end of program
  # A is stored in M[0100]
  # B is stored in M[0101]
  # If A - B < 3, store 255 in M[0102], else store 1 in M[0102]
  # Put A in R1
  # Put B in R2
  # Sub A - B and put in R3
  # Load const 3 into R4
  # Sub R3 - R4 => R5
  # If R5 is negative, 255 => R6, else 1 => R6
  # Store R6 into M[0102]
  program = [
    # Load 2nd branch address into RB
    0x100B    # 00 HBY 0x00 RB
    0x210B    # 01 LBY 0x10 RB

    # Load end of program address int RC
    0x7B2C    # 02 ADI RB 2 RC

    # Load A value into R1
    0x101A    # 03 HBY 0x01 RA
    0x200A    # 04 LBY 0x00 RA
    0x3A01    # 05 LOD RA R1

    # Load B value into R2
    0x201A    # 06 LBY 0x01 RA
    0x3A02    # 07 LOD RA R2

    0x6123    # 08 SUB R1 R2 R3

    # Load constant 3 to R4
    0x1004    # 09 HBY 0x00 R4
    0x2034    # 0A LBY 0x03 R4

    0x6345    # 0B SUB R3 R4 R5

    # Branch to ? if A - B >= 3
    0xE5B3    # 0C BRN R5 RB ZP

    # Load constant 255 into R6
    0x1006    # 0D HBY 0x00 R6
    0x2FF6    # 0E LBY 0xFF R6
    0xE0C7    # 0F BRN R0 RC NZP (Jump to end)

    # Load constant 0x01 into R6
    0x1006    # 10 HBY 0x00 R6
    0x2016    # 11 LBY 0x01 R6

    # Store final value into M[0102]
    0x202A    # 12 LBY 0x02 RA
    0x4A60    # 13 STR RA R6
    0x0000    # 14 END
  ]
  @ram[0x0100] = 101
  @ram[0x0101] = 99
  @cpu.loadProgram program
  @cpu.run()
  equal @ram[0x0102], 255, "101 - 99 < 3 => 255"
  equal @cpu.pc, 20, "PC = 20"

test 'Program with while loop', ->
  # Run a complete program
  # Uses decimal I/O ports
  # Input: n followed by a list of n integers
  # Output: -2 * sum(list of n integers)
  program = [
    # R0 gets input address
    0x1FF0      # 0 HBY 0xFF R0       0xFF -> Upper(R0)
    0x2FC0      # 1 LBY 0xFC R0       0xFC -> Lower(R0)

    # R1 gets output address
    0x1FF1      # 2 HBY 0xFF R1       0xFF -> Upper(R1)
    0x2FD1      # 3 LBY 0xFD R1       0xFD -> Lower(R1)

    # R2 gets n, the count of how many input values to sum
    0x3002      # 4 LOD R0 R2         First Input (count n) -> R2

    # R3 and R4 have start and end of while loop respectively
    0x2073      # 5 LBY 0x.. R3       addr start of while loop -> R3
    0x20C4      # 6 LBY 0x.. R4       addr to end while loop -> R4

    # Start of while loop
    0xE242      # 7 BRN R2 R4 Z       if R2 is zero (0x.... -> PC)
    0x3006      # 8 LOD R0 R6         Next Input -> R6
    0x5565      # 9 ADD R5 R6 R5      R5 + R6 (running sum) -> R5
    0x8212      # A SBI R2 1 R2       R2 - 1 -> R2
    0xE037      # B BRN R0 R3 NZP     0x.... -> PC (unconditional)

    # End of while loop
    0xD506      # C SHF R5 left 1 R6  Double sum

    # Negate double of sum
    0x6767      # D SUB R7 R6 R7      0 - R6 -> R7

    # Output result
    0x4170      # E STR R1 R7         Output value of R7
    0x0000      # F END
  ]
  @ram[0xFFFC] = [101].concat [10..110]
  @cpu.loadProgram program
  @cpu.run()
  # n = length(10..110) = 101
  # sum(10..110) = 6060
  # -2 * 6060 = -12120
  # 16-bit hex(+12120) = 0x2F58
  # 16-bit hex(-12120) = 0xD0A8
  deepEqual @ram[0xFFFC], [], 'Decimal input queue is empty'
  deepEqual @ram[0xFFFD], [0xD0A8], "Outputs #{0xD0A8}"
  equal @cpu.pc, 15, 'PC is 15'
