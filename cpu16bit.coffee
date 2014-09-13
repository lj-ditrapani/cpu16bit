###
Author:  Lyall Jonathan Di Trapani
16 bit CPU simulator
http://jsfiddle.net/bL2eszp8/
---------|---------|---------|---------|---------|---------|---------|--
###

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

signed = (hex) ->
  if hex < 8
      hex
  else
      -((hex ^ 0xF) + 1)
  
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
      (value << ammount) & 0xFFFF
    @registers[rd] = value

  ljd.cpu16bit =
    CPU: CPU
    getNibbles: getNibbles
    signed: signed
