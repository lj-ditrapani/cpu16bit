###
Author:  Lyall Jonathan Di Trapani
16 bit CPU simulator
http://jsfiddle.net/bL2eszp8/
###

###
noprotect
###
# -------|---------|---------|---------|---------|---------|---------|--
(->
  if (typeof ljd).toString() == 'undefined'
    window.ljd = {}

  getNibbles = (word) ->
    opCode = word >> 12
    a = (word >> 8) & 0xF
    b = (word >> 4) & 0xF
    c = word & 0xF
    [opCode, a, b, c]

  isPositive = (word) ->
    (word >> 15) == 0

  isNegative = (word) ->
    (word >> 15) == 1

  hasOverflowedOnAdd = (a, b, sum) ->
    ((isNegative(a) and isNegative(b) and isPositive(sum)) or
     (isPositive(a) and isPositive(b) and isNegative(sum)))

  class CPU

    constructor: ->
      @reset()
      @opCodes = ('HLT LBY HBY LOD STR ADD SUB ADI SBI AND' +
                   ' ORR XOR NOT ROT BRN SPC').split(' ')

    reset: ->
      @pc = 0
      @registers = (0 for _ in [0...16])
      @ram = (0 for _ in [0...Math.pow(2, 16)])
      @carry = 0
      @overflow = 0

    step: ->
      instruction = @ram[@pc]
      @pc += 1
      [opCode, a, b, c] = getNibbles(instruction)
      this[@opCodes[opCode]](a, b, c)

    add: (a, b, carry) ->
      sum = a + b + carry
      @carry = Number(sum >= Math.pow(2, 16))
      sum = sum & 0xFFFF
      @overflow = Number(hasOverflowedOnAdd(a, b, sum))
      sum

    LBY: (highNibble, lowNibble, register) ->
      immediate8 = (highNibble << 4) | lowNibble
      value = @registers[register]
      @registers[register] = (value & 0xFF00) | immediate8

    HBY: (highNibble, lowNibble, register) ->
      immediate8 = (highNibble << 4) | lowNibble
      value = @registers[register]
      @registers[register] = (immediate8 << 8) | (value & 0x00FF)

    LOD: (ra, _, rd) ->
      address = @registers[ra]
      @registers[rd] = @ram[address]

    STR: (ra, r2, _) ->
      console.log(ra, r2)
      address = @registers[ra]
      @ram[address] = @registers[r2]

    ADD: (r1, r2, rd) ->
      [a, b] = [@registers[r1], @registers[r2]]
      sum = this.add a, b, 0
      @registers[rd] = sum

    SUB: (r1, r2, rd) ->
      [a, b] = [@registers[r1], @registers[r2]]
      notB = b ^ 0xFFFF
      diff = this.add a, notB, 1
      @registers[rd] = diff

    ADI: (r1, immd, rd) ->
      a = @registers[r1]
      sum = this.add a, immd, 0
      @registers[rd] = sum

    SBI: (r1, immd, rd) ->
      a = @registers[r1]
      notB = immd ^ 0xFFFF
      diff = this.add a, notB, 1
      @registers[rd] = diff

    AND: (r1, r2, rd) ->
      [a, b] = [@registers[r1], @registers[r2]]
      @registers[rd] = a & b

    ORR: (r1, r2, rd) ->
      [a, b] = [@registers[r1], @registers[r2]]
      @registers[rd] = a | b

    XOR: (r1, r2, rd) ->
      [a, b] = [@registers[r1], @registers[r2]]
      @registers[rd] = a ^ b

    NOT: (r1, r2, rd) ->
      a = @registers[r1]
      @registers[rd] = a ^ 0xFFFF

    ROT: (r1, immd, rd) ->
      ammount = signed(immd)
      value = @registers[r1]
      value = if ammount < 0
        value >> Math.abs(ammount)
      else
        value << ammount
      @registers[rd] = value

    ljd.cpu16bit =
      CPU: CPU
      getNibbles: getNibbles
)()


(->
  cpu16bit = ljd.cpu16bit

  test 'makeImmediate8Instruction', ->
    tests = [
      [1, 0xFF, 0x5, 0x1FF5, 'LBY']
      [2, 0x17, 0xF, 0x217F, 'HBY']
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

  module "cpu 16-bit",
    setup: ->
      @cpu = new cpu16bit.CPU

  test "Initial State", ->
    equal @cpu.ram.length, 65536, '65536 RAM cells'
    deepEqual [@cpu.ram[0], @cpu.ram[65535]], [0, 0],
              'RAM init to all 0'
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

  test 'LBY', ->
    tests = [
      [5, 0, 0, 5]
      [0, 3, 0xFFFF, 0xFF00]
      [0xEA, 15, 0x1234, 0x12EA]
    ]
    testImmdLoad @cpu, tests, 1

  test 'HBY', ->
    tests = [
      [0x05, 0, 0x0000, 0x0500]
      [0x00, 3, 0xFFFF, 0x00FF]
      [0xEA, 15, 0x1234, 0xEA34]
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
      @cpu.ram[0] = makeInstruction(
          4, addressRegister, valueRegister, 0
      )
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

  test 'ROT', ->
    tests = [
      [0x0704, 0x0, 0x0704]
      [0x0704, 0x4, 0x7040]
      [0x090F, 0x1, 0x121E]
      [0x090F, 0x3, 0x4878]
      [0x90F0, 0xC, 0x090F]
      [0x90F1, 0xF, 0x4878]
      [0x450A, 0x7, 0x8500]
      [0x450A, 0x8, 0x0045]
    ]
    for [a, immd4, result] in tests
      [r1, rd] = [14, 7]
      @cpu.pc = 0
      @cpu.registers[r1] = a
      @cpu.ram[0] = makeInstruction(13, r1, immd4, rd)
      @cpu.step()
      equal @cpu.registers[rd],
            result,
            "ROT #{a} by #{immd4} = #{result}"

)()