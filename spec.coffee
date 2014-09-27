###
Author:  Lyall Jonathan Di Trapani
Specification for 16 bit CPU simulator
---------|---------|---------|---------|---------|---------|---------|--
###

cpu16bit = ljd.cpu16bit

test 'makeImmediate8Instruction', ->
  tests = [
    [1, 0x17, 0xF, 0x117F, 'HBY']
    [2, 0xFF, 0x5, 0x2FF5, 'LBY']
  ]
  for [opCode, immediate, register, instruction, name] in tests
    equal makeImmediate8Instruction(opCode, immediate, register),
          instruction,
          name

test 'makeImmediate8Instruction', ->
  tests = [
    [3, 0xF, 0x0, 0x2, 0x3F02, 'LOD']
    [4, 0xE, 0x2, 0x0, 0x4E20, 'STR']
    [5, 0x1, 0x2, 0xD, 0x512D, 'ADD']
    [6, 0x1, 0x2, 0x3, 0x6123, 'SUB']
    [7, 0x7, 0x1, 0x2, 0x7712, 'ADI']
  ]
  for [opCode, a, b, c, instruction, name] in tests
    equal makeInstruction(opCode, a, b, c), instruction, name

makeImmediate8Instruction = (opCode, immediate, register) ->
  (opCode << 12) | (immediate << 4) | register

makeInstruction = (opCode, a, b, c) ->
  (opCode << 12) | (a << 8) | (b << 4) | c

test 'getNibbles', ->
  deepEqual cpu16bit.getNibbles(0xABCD), [0xA, 0xB, 0xC, 0xD]
  deepEqual cpu16bit.getNibbles(0x7712), [0x7, 0x7, 0x1, 0x2]

test 'positionOfLastBitShifted', ->
  tests = [
    ['left', 1, 15]
    ['right', 1, 0]
    ['left', 4, 12]
    ['right', 4, 3]
    ['left', 8, 8]
    ['right', 8, 7]
  ]
  for [direction, amount, position] in tests
    equal cpu16bit.positionOfLastBitShifted(direction, amount), position

test 'oneBitWordMask', ->
  tests = [
    [0, 0x0001]
    [1, 0x0002]
    [3, 0x0008]
    [4, 0x0010]
    [8, 0x0100]
    [15, 0x8000]
    [14, 0x4000]
  ]
  for [position, mask] in tests
    equal cpu16bit.oneBitWordMask(position), mask

test 'getShiftCarry', ->
  tests = [
    ['left', 1, 0x8000, 1]
    ['left', 1, 0x7FFF, 0]
    ['right', 1, 0x0001, 1]
    ['right', 1, 0xFFFE, 0]
    ['left', 4, 0x1000, 1]
    ['right', 4, 0xFFF7, 0]
    ['left', 8, 0xFEFF, 0]
    ['right', 8, 0x0080, 1]
  ]
  for [direction, amount, value, carry] in tests
    equal cpu16bit.getShiftCarry(value, direction, amount), carry

makeCondCode = (strCode) ->
  code = 0
  if ("V" in strCode) or ("C" in strCode) or ("-" in strCode)
    code += 8
    if "V" in strCode
      code += 2
    if "C" in strCode
      code += 1
  else
    if "N" in strCode
      code += 4
    if "Z" in strCode
      code += 2
    if "P" in strCode
      code += 1
  code

test 'makeCondCode', ->
  tests = [
    ["NZP", 0b0111]
    ["ZP", 0b0011]
    ["Z", 0b0010]
    ["P", 0b0001]
    ["VC", 0b1011]
    ["C", 0b1001]
    ["V", 0b1010]
    ["", 0b0000]
    ["-", 0b1000]
  ]
  for [str, code] in tests
    equal makeCondCode(str), code

test 'matchValue', ->
  tests = [
    #  NZP
    [0b000, 0xFFFF, false]
    [0b111, 0xFFFF, true]
    [0b011, 0xFFFF, false]
    [0b100, 0xFFFF, true]
    [0b100, 0x8000, true]
    [0b110, 0x0000, true]
    [0b101, 0x0000, false]
    [0b010, 0x0000, true]
    [0b001, 0x7FFF, true]
    [0b110, 0x7FFF, false]
    [0b101, 0x7FFF, true]
  ]
  for [cond, value, result] in tests
    equal cpu16bit.matchValue(value, cond),
          result,
          "#{cond} #{value} #{result}"

test 'matchFlags', ->
  tests = [
    #  VC
    [0b00, 0, 0, true]
    [0b00, 1, 0, false]
    [0b00, 0, 1, false]
    [0b11, 0, 1, true]
    [0b11, 1, 0, true]
    [0b11, 1, 1, true]
    [0b11, 0, 0, false]
    [0b10, 0, 0, false]
    [0b10, 0, 1, false]
    [0b10, 1, 0, true]
    [0b10, 1, 1, true]
    [0b01, 0, 0, false]
    [0b01, 0, 1, true]
    [0b01, 1, 0, false]
    [0b01, 1, 1, true]
  ]
  for [cond, overflow, carry, result] in tests
    equal cpu16bit.matchFlags(overflow, carry, cond),
          result,
          "#{cond} #{overflow} #{carry} #{result}"

module "cpu 16-bit",
  setup: ->
    @cpu = new cpu16bit.CPU

test "Initial State", ->
  equal @cpu.ram.length, 65536, '65536 RAM cells'
  deepEqual [@cpu.ram[0], @cpu.ram[0xFFF9]], [0, 0],
            'RAM init to all 0'
  deepEqual [@cpu.ram[0xFFFA], @cpu.ram[0xFFFF]], [[], []],
            'Last 6 RAM addresses are buffers'
  equal @cpu.registers.length, 16, '16 registers'
  equal @cpu.opCodes.length, 16, '16 op codes'
  deepEqual @cpu.pc, 0, 'pc = 0'
  deepEqual [@cpu.carry, @cpu.overflow], [0, 0], 'flags'

testImmdLoad = (cpu, tests, opCode) ->
  for [immediate, register, currentValue, finalValue] in tests
    cpu.pc = 0
    cpu.registers[register] = currentValue
    cpu.ram[0] =
      makeImmediate8Instruction(opCode, immediate, register)
    cpu.step()
    equal cpu.registers[register], finalValue

test 'END', ->
  @cpu.ram[0] = 0
  equal @cpu.step(), true
  equal @cpu.pc, 0

test 'HBY', ->
  tests = [
    [0x05, 0, 0x0000, 0x0500]
    [0x00, 3, 0xFFFF, 0x00FF]
    [0xEA, 15, 0x1234, 0xEA34]
  ]
  testImmdLoad @cpu, tests, 1

test 'LBY', ->
  tests = [
    [5, 0, 0, 5]
    [0, 3, 0xFFFF, 0xFF00]
    [0xEA, 15, 0x1234, 0x12EA]
  ]
  testImmdLoad @cpu, tests, 2

test 'LOD', ->
  tests = [
    [2, 13, 0x0100, 0xFEED]
    [3, 10, 0x1000, 0xFACE]
  ]
  for [addressRegister, destRegister, address, value] in tests
    @cpu.pc = 0
    @cpu.registers[addressRegister] = address
    @cpu.ram[address] = value
    @cpu.ram[0] = makeInstruction(
      3, addressRegister, 0, destRegister
    )
    @cpu.step()
    equal @cpu.registers[destRegister], value

test 'STR', ->
  tests = [
    [7, 15, 0x0100, 0xFEED]
    [12, 5, 0x1000, 0xFACE]
    [5, 5, 0x1000, 0x1000]
  ]
  for [addressRegister, valueRegister, address, value] in tests
    @cpu.pc = 0
    @cpu.registers[addressRegister] = address
    @cpu.registers[valueRegister] = value
    @cpu.ram[0] = makeInstruction(4, addressRegister, valueRegister, 0)
    @cpu.step()
    equal @cpu.ram[address], value

BinaryPairs = [[0, 0], [0, 1], [1, 0], [1, 1]]

test 'ADD', ->
  tests = [
    [0x0000, 0x0000, 0x0000, 0, 0]
    [0x00FF, 0xFF00, 0xFFFF, 0, 0]
    [0xFFFF, 0x0001, 0x0000, 1, 0]
    [0x0001, 0xFFFF, 0x0000, 1, 0]
    [0xFFFF, 0xFFFF, 0xFFFE, 1, 0]
    [0x8000, 0x8000, 0x0000, 1, 1]
    [0x1234, 0x9876, 0xAAAA, 0, 0]
    [0x1234, 0xDEAD, 0xF0E1, 0, 0]
    [0x7FFF, 0x0001, 0x8000, 0, 1]
    [0x0FFF, 0x7001, 0x8000, 0, 1]
    [0x7FFE, 0x0001, 0x7FFF, 0, 0]
  ]
  for [a, b, sum, finalCarry, finalOverflow] in tests
    for [initialCarry, initialOverflow] in BinaryPairs
      [r1, r2, rd] = if initialCarry then [3, 4, 13] else [7, 11, 2]
      @cpu.carry = initialCarry
      @cpu.overflow = initialOverflow
      @cpu.pc = 0
      @cpu.registers[r1] = a
      @cpu.registers[r2] = b
      @cpu.ram[0] = makeInstruction(5, r1, r2, rd)
      @cpu.step()
      equal @cpu.carry, finalCarry, "#{a} + #{b} = #{sum}"
      equal @cpu.overflow, finalOverflow
      equal @cpu.registers[rd], sum

test 'SUB', ->
  tests = [
    [0x0000, 0x0000, 0x0000, 1, 0]
    [0x0000, 0x0001, 0xFFFF, 0, 0]
    [0x0005, 0x0007, 0xFFFE, 0, 0]
    [0x7FFE, 0x7FFF, 0xFFFF, 0, 0]
    [0xFFFF, 0xFFFF, 0x0000, 1, 0]
    [0xFFFF, 0x0001, 0xFFFE, 1, 0]
    [0x8000, 0x8000, 0x0000, 1, 0]
    [0x8000, 0x7FFF, 0x0001, 1, 1]
    [0xFFFF, 0x7FFF, 0x8000, 1, 0]
    [0x7FFF, 0xFFFF, 0x8000, 0, 1]
    [0x7FFF, 0x0001, 0x7FFE, 1, 0]
  ]
  for [a, b, result, finalCarry, finalOverflow] in tests
    for [initialCarry, initialOverflow] in BinaryPairs
      [r1, r2, rd] = if initialCarry then [3, 4, 13] else [7, 11, 2]
      @cpu.carry = initialCarry
      @cpu.overflow = initialOverflow
      @cpu.pc = 0
      @cpu.registers[r1] = a
      @cpu.registers[r2] = b
      @cpu.ram[0] = makeInstruction(6, r1, r2, rd)
      @cpu.step()
      equal @cpu.carry, finalCarry, "Carry #{a} - #{b} = #{result}"
      equal @cpu.overflow, finalOverflow, "V"
      equal @cpu.registers[rd], result, "Result"

test 'ADI', ->
  tests = [
    [0x0000, 0x0000, 0x0000, 0, 0]
    [0xFFFF, 0x0001, 0x0000, 1, 0]
    [0x7FFF, 0x0001, 0x8000, 0, 1]
    [0x7FFE, 0x0001, 0x7FFF, 0, 0]
    [0xFFFE, 0x000F, 0x000D, 1, 0]
    [0x7FFE, 0x000F, 0x800D, 0, 1]
    [0xFEDF, 0x000E, 0xFEED, 0, 0]
  ]
  for [a, b, sum, finalCarry, finalOverflow] in tests
    for [initialCarry, initialOverflow] in BinaryPairs
      [r1, r2, rd] = if initialCarry then [3, 4, 13] else [7, 11, 2]
      @cpu.carry = initialCarry
      @cpu.overflow = initialOverflow
      @cpu.pc = 0
      @cpu.registers[r1] = a
      @cpu.ram[0] = makeInstruction(7, r1, b, rd)
      @cpu.step()
      equal @cpu.carry, finalCarry, "#{a} + #{b} = #{sum}"
      equal @cpu.overflow, finalOverflow
      equal @cpu.registers[rd], sum

test 'SBI', ->
  tests = [
    [0x0000, 0x0000, 0x0000, 1, 0]
    [0x0000, 0x0001, 0xFFFF, 0, 0]
    [0x8000, 0x0001, 0x7FFF, 1, 1]
    [0x7FFF, 0x0001, 0x7FFE, 1, 0]
    [0x000D, 0x000F, 0xFFFE, 0, 0]
    [0x800D, 0x000F, 0x7FFE, 1, 1]
    [0xFEED, 0x000E, 0xFEDF, 1, 0]
  ]
  for [a, b, result, finalCarry, finalOverflow] in tests
    for [initialCarry, initialOverflow] in BinaryPairs
      [r1, r2, rd] = if initialCarry then [3, 4, 13] else [7, 11, 2]
      @cpu.carry = initialCarry
      @cpu.overflow = initialOverflow
      @cpu.pc = 0
      @cpu.registers[r1] = a
      @cpu.ram[0] = makeInstruction(8, r1, b, rd)
      @cpu.step()
      equal @cpu.carry, finalCarry, "#{a} - #{b} = #{result}"
      equal @cpu.overflow, finalOverflow
      equal @cpu.registers[rd], result

test 'AND', ->
  tests = [
    [0x0000, 0x0000, 0x0000]
    [0xFEED, 0xFFFF, 0xFEED]
    [0xFEED, 0x0F0F, 0x0E0D]
    [0x7BDC, 0xCCE3, 0x48C0]
  ]
  for [a, b, result] in tests
    [r1, r2, rd] = [14, 7, 0]
    @cpu.pc = 0
    @cpu.registers[r1] = a
    @cpu.registers[r2] = b
    @cpu.ram[0] = makeInstruction(9, r1, r2, rd)
    @cpu.step()
    equal @cpu.registers[rd], result, "#{a} AND #{b} = #{result}"

test 'ORR', ->
  tests = [
    [0x0000, 0x0000, 0x0000]
    [0xFEED, 0xFFFF, 0xFFFF]
    [0xF000, 0x000F, 0xF00F]
    [0xC8C6, 0x3163, 0xF9E7]
  ]
  for [a, b, result] in tests
    [r1, r2, rd] = [13, 5, 3]
    @cpu.pc = 0
    @cpu.registers[r1] = a
    @cpu.registers[r2] = b
    @cpu.ram[0] = makeInstruction(10, r1, r2, rd)
    @cpu.step()
    equal @cpu.registers[rd], result, "#{a} OR #{b} = #{result}"

test 'XOR', ->
  tests = [
    [0x0000, 0x0000, 0x0000]
    [0xFF00, 0x00FF, 0xFFFF]
    [0x4955, 0x835A, 0xCA0F]
  ]
  for [a, b, result] in tests
    [r1, r2, rd] = [4, 6, 8]
    @cpu.pc = 0
    @cpu.registers[r1] = a
    @cpu.registers[r2] = b
    @cpu.ram[0] = makeInstruction(11, r1, r2, rd)
    @cpu.step()
    equal @cpu.registers[rd], result, "#{a} XOR #{b} = #{result}"

test 'NOT', ->
  tests = [
    [0x0000, 0xFFFF]
    [0xFF00, 0x00FF]
    [0x4955, 0xB6AA]
  ]
  for [a, result] in tests
    [r1, rd] = [9, 0]
    @cpu.pc = 0
    @cpu.registers[r1] = a
    @cpu.ram[0] = makeInstruction(12, r1, 0, rd)
    @cpu.step()
    equal @cpu.registers[rd], result, "NOT #{a} = #{result}"

test 'SHF', ->
  tests = [
    [0x0704, 0, 0x4, 0x7040, 0]
    [0x090F, 0, 0x1, 0x121E, 0]
    [0x090F, 0, 0x3, 0x4878, 0]
    [0x90F0, 1, 0x4, 0x090F, 0]
    [0x90F1, 1, 0x1, 0x4878, 1]
    [0x450A, 0, 0x7, 0x8500, 0]
    [0x450A, 0, 0x8, 0x0A00, 1]
    [0x450A, 1, 0x8, 0x0045, 0]
  ]
  for [value, direction, amount, result, carry] in tests
    [r1, rd] = [14, 7]
    @cpu.pc = 0
    @cpu.carry = 0
    @cpu.registers[r1] = value
    immd4 = direction * 8 + (amount - 1)
    @cpu.ram[0] = makeInstruction(13, r1, immd4, rd)
    @cpu.step()
    sDirection = if direction then "right" else "left"
    equal @cpu.registers[rd],
      result,
      "SHF #{value} #{sDirection} by #{amount} = #{result}"
    equal @cpu.carry, carry

test 'BRN value', ->
  tests = [
    [0xFFFF, 0x00FF, "",    false]
    [0xFFFF, 0x00FF, "NZP", true]
    [0xFFFF, 0x00FF, "ZP",  false]
    [0xFFFF, 0x00FF, "N",   true]
    [0x8000, 0x00FF, "N",   true]
    [0x0000, 0x00FF, "NZ",  true]
    [0x0000, 0x00FF, "NP",  false]
    [0x0000, 0x00FF, "Z",   true]
    [0x7FFF, 0x00FF, "P",   true]
    [0x7FFF, 0x00FF, "NZ",  false]
    [0x7FFF, 0x00FF, "NP",  true]
  ]
  for [value, jumpAddr, condString, takeJump] in tests
    [r1, r2] = [12, 0]
    @cpu.pc = 0
    @cpu.registers[r1] = value
    @cpu.registers[r2] = jumpAddr
    condCode = makeCondCode condString
    @cpu.ram[0] = makeInstruction(14, r1, r2, condCode)
    @cpu.step()
    finalPC = if takeJump then jumpAddr else 0x0001
    equal @cpu.pc, finalPC

test 'BRN flag', ->
  tests = [
    [0, 0, '-', true]
    [1, 0, '-', false]
    [0, 1, '-', false]
    [0, 1, 'VC', true]
    [1, 0, 'VC', true]
    [1, 1, 'VC', true]
    [0, 0, 'VC', false]
    [0, 0, 'V', false]
    [0, 1, 'V', false]
    [1, 0, 'V', true]
    [1, 1, 'V', true]
    [0, 0, 'C', false]
    [0, 1, 'C', true]
    [1, 0, 'C', false]
    [1, 1, 'C', true]
  ]
  for [overflow, carry, condString, takeJump] in tests
    [r1, r2] = [11, 1]
    jumpAddr = 0x00FF
    @cpu.pc = 0
    @cpu.overflow = overflow
    @cpu.carry = carry
    @cpu.registers[r2] = jumpAddr
    condCode = makeCondCode condString
    @cpu.ram[0] = makeInstruction(14, r1, r2, condCode)
    @cpu.step()
    finalPC = if takeJump then jumpAddr else 0x0001
    equal @cpu.pc,
          finalPC,
          "#{overflow} #{carry} #{condString} #{takeJump}"

test 'SPC', ->
  tests = [
    [0, 0x0000, 0x0002]
    [1, 0x00FF, 0x0101]
    [15, 0x0F00, 0x0F02]
  ]
  for [rd, pc, value] in tests
    @cpu.pc = pc
    @cpu.registers[rd] = 0
    @cpu.ram[pc] = makeInstruction(15, 0, 0, rd)
    @cpu.step()
    equal @cpu.registers[rd], value, "#{rd} #{pc} #{value}"

test 'Read from decimal debug input', ->
  addressRegister = 0xC
  decInputAddress = 0xFFFC
  @cpu.ram[decInputAddress] = [42, 24, 7]
  @cpu.registers[addressRegister] = decInputAddress
  @cpu.ram[0] = makeInstruction(3, addressRegister, 0, 0x0)
  @cpu.ram[1] = makeInstruction(3, addressRegister, 0, 0x1)
  @cpu.run()
  deepEqual @cpu.ram[decInputAddress], [7]
  deepEqual [@cpu.registers[0], @cpu.registers[1]], [42, 24]

test 'Write to decimal debug output', ->
  addressRegister = 0xA
  decOutputAddress = 0xFFFD
  value0 = 42
  value1 = 24
  @cpu.registers[0x0] = value0
  @cpu.registers[0x1] = value1
  @cpu.registers[addressRegister] = decOutputAddress
  @cpu.ram[0] = makeInstruction(4, addressRegister, 0x0, 0)
  @cpu.ram[1] = makeInstruction(4, addressRegister, 0x1, 0)
  @cpu.run()
  deepEqual @cpu.ram[decOutputAddress], [value0, value1]

test 'loadProgram', ->
  program = [
    1
    2
    3
    4
    5
  ]
  @cpu.loadProgram program
  equal @cpu.ram[0], 1
  equal @cpu.ram[4], 5

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
  @cpu.ram[0x0100] = 27
  @cpu.ram[0x0101] = 73
  @cpu.loadProgram program
  @cpu.run()
  equal @cpu.ram[0x0102], 100, "27 + 73 = 100"
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
  @cpu.ram[0x0100] = 101
  @cpu.ram[0x0101] = 99
  @cpu.loadProgram program
  @cpu.run()
  equal @cpu.ram[0x0102], 255, "101 - 99 < 3 => 255"
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
  @cpu.ram[0xFFFC] = [101].concat [10..110]
  @cpu.loadProgram program
  @cpu.run()
  # n = length(10..110) = 101
  # sum(10..110) = 6060
  # -2 * 6060 = -12120
  # 16-bit hex(+12120) = 0x2F58
  # 16-bit hex(-12120) = 0xD0A8
  deepEqual @cpu.ram[0xFFFC], []
  deepEqual @cpu.ram[0xFFFD], [0xD0A8]
  equal @cpu.pc, 15
