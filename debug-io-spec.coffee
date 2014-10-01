###
Author:  Lyall Jonathan Di Trapani
Specification for 16 bit CPU simulator
---------|---------|---------|---------|---------|---------|---------|--
###

cpu16bit = ljd.cpu16bit

test 'Read from decimal debug input', ->
  addressRegister = 0xC
  decInputAddress = 0xFFFC
  @ram[decInputAddress] = [42, 24, 7]
  @registers[addressRegister] = decInputAddress
  @ram[0] = @makeInstruction(3, addressRegister, 0, 0x0)
  @ram[1] = @makeInstruction(3, addressRegister, 0, 0x1)
  @cpu.run()
  deepEqual @ram[decInputAddress], [7]
  deepEqual [@registers[0], @registers[1]], [42, 24]

test 'Write to decimal debug output', ->
  addressRegister = 0xA
  decOutputAddress = 0xFFFD
  value0 = 42
  value1 = 24
  @registers[0x0] = value0
  @registers[0x1] = value1
  @registers[addressRegister] = decOutputAddress
  @ram[0] = @makeInstruction(4, addressRegister, 0x0, 0)
  @ram[1] = @makeInstruction(4, addressRegister, 0x1, 0)
  @cpu.run()
  deepEqual @ram[decOutputAddress], [value0, value1]

test 'Attempt to write to decimal debug input', ->
  pc = 2
  @cpu.pc = pc
  @registers[0] = 0xFFFC   # decimal debug input address
  # STR R1 -> M[R0]            # write 0 to decimal debug input
  @ram[pc] = 0x4010        # Attempt to write to input
  throws (-> @cpu.step()), /Write to decimal debug input at PC 2/

test 'Attempt to read from decimal debug output', ->
  pc = 5
  @cpu.pc = pc
  @registers[0] = 0xFFFD   # decimal debug output address
  # LOD M[R0] -> R1            # read from decimal debug output
  @ram[pc] = 0x3001        # Attempt to read output
  throws (-> @cpu.step()), /Read from decimal debug output at PC 5/
