###
Author:  Lyall Jonathan Di Trapani
16 bit CPU simulator
---------|---------|---------|---------|---------|---------|---------|--
###


if (typeof ljd).toString() == 'undefined'
  window.ljd = {}


END = 0


getNibbles = (word) ->
  opCode = word >> 12
  a = (word >> 8) & 0xF
  b = (word >> 4) & 0xF
  c = word & 0xF
  [opCode, a, b, c]


isPositiveOrZero = (word) ->
  (word >> 15) == 0


isNegative = (word) ->
  (word >> 15) == 1


isTruePositive = (word) ->
  isPositiveOrZero(word) and (word != 0)


hasOverflowedOnAdd = (a, b, sum) ->
  ((isNegative(a) and isNegative(b) and isPositiveOrZero(sum)) or
   (isPositiveOrZero(a) and isPositiveOrZero(b) and isNegative(sum)))


positionOfLastBitShifted = (direction, amount) ->
  if direction == 'right'
    amount - 1
  else
    16 - amount


oneBitWordMask = (position) ->
  Math.pow(2, position)


getShiftCarry = (value, direction, amount) ->
  position = positionOfLastBitShifted(direction, amount)
  mask = oneBitWordMask(position)
  if (value & mask) > 0 then 1 else 0


matchValue = (value, cond) ->
  if ((cond & 0b100) == 0b100) and isNegative(value)
    true
  else if ((cond & 0b010) == 0b010) and (value == 0)
    true
  else if ((cond & 0b001) == 0b001) and isTruePositive(value)
    true
  else
    false


matchFlags = (overflow, carry, cond) ->
  if (cond >= 2) and overflow
    true
  else if ((cond & 1) == 1) and carry
    true
  else if (cond == 0) and (not overflow) and (not carry)
    true
  else
    false


class CPU

  constructor: ->
    @reset()
    @opCodes = ('END HBY LBY LOD STR ADD SUB ADI SBI AND' +
                 ' ORR XOR NOT SHF BRN SPC').split(' ')

  reset: ->
    @pc = 0
    @registers = (0 for _ in [0...16])
    @ram = (0 for _ in [0...Math.pow(2, 16)])
    for i in [0xFFFA..0xFFFF]
      @ram[i] = []
    @carry = 0
    @overflow = 0

  step: ->
    instruction = @ram[@pc]
    [opCode, a, b, c] = getNibbles(instruction)
    if opCode == END
      true
    else
      [jump, address] = this[@opCodes[opCode]](a, b, c)
      @pc = if jump is true then address else @pc + 1
      false

  run: ->
    end = false
    while not end
      end = @step()

  loadProgram: (program) ->
    i = 0
    for value in program
      @ram[i] = value
      i += 1

  add: (a, b, carry) ->
    sum = a + b + carry
    @carry = Number(sum >= Math.pow(2, 16))
    sum = sum & 0xFFFF
    @overflow = Number(hasOverflowedOnAdd(a, b, sum))
    sum

  HBY: (highNibble, lowNibble, register) ->
    immediate8 = (highNibble << 4) | lowNibble
    value = @registers[register]
    @registers[register] = (immediate8 << 8) | (value & 0x00FF)

  LBY: (highNibble, lowNibble, register) ->
    immediate8 = (highNibble << 4) | lowNibble
    value = @registers[register]
    @registers[register] = (value & 0xFF00) | immediate8

  LOD: (ra, _, rd) ->
    address = @registers[ra]
    @registers[rd] = if address >= 0xFFFE
      @ioRead(address)
    else
      @ram[address]

  STR: (ra, r2, _) ->
    console.log(ra, r2)
    address = @registers[ra]
    value = @registers[r2]
    if address >= 0xFFFE
      @ioWrite(address, value)
    else
      @ram[address] = value

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

  NOT: (r1, _, rd) ->
    a = @registers[r1]
    @registers[rd] = a ^ 0xFFFF

  SHF: (r1, immd, rd) ->
    direction = if immd >= 8 then 'right' else 'left'
    amount = (immd & 7) + 1
    value = @registers[r1]
    @carry = getShiftCarry(value, direction, amount)
    value = if direction == 'right'
      value >> amount
    else
      (value << amount) & 0xFFFF
    @registers[rd] = value

  BRN: (r1, r2, cond) ->
    [value, jumpAddr] = [@registers[r1], @registers[r2]]
    takeJump = if cond >= 8
      matchFlags(@overflow, @carry, cond - 8)
    else
      matchValue(value, cond)
    if takeJump then [true, jumpAddr] else [false, 0]

  SPC: (_, __, rd) ->
    @registers[rd] = @pc + 2

  ioRead: (address) ->
    if address == 0xFFFF
      throw new Error("Read from debug output at PC #{@pc}")
    @ram[address].shift()

  ioWrite: (address, value) ->
    if address == 0xFFFE
      throw new Error("Write to debug input at PC #{@pc}")
    @ram[address].push value


ljd.cpu16bit =
  CPU: CPU
  getNibbles: getNibbles
  positionOfLastBitShifted: positionOfLastBitShifted
  oneBitWordMask: oneBitWordMask
  getShiftCarry: getShiftCarry
  matchValue: matchValue
  matchFlags: matchFlags
