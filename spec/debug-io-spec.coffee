###
Author:  Lyall Jonathan Di Trapani
Debug I/O Specification for 16 bit CPU simulator
---------|---------|---------|---------|---------|---------|---------|--
###

cpu16bit = ljd.cpu16bit

test 'Read from debug input', ->
  addressRegister = 0xC
  decInputAddress = 0xFFFE
  @ram[decInputAddress] = [42, 64, 7]
  @registers[addressRegister] = decInputAddress
  @ram[0] = @makeInstruction(3, addressRegister, 0, 0x0)
  @ram[1] = @makeInstruction(3, addressRegister, 0, 0x1)
  @cpu.run()
  deepEqual @ram[decInputAddress], [7]
  deepEqual [@registers[0], @registers[1]], [42, 64]

runDebugOutputTest = (mod, outputAddress, output0, output1) ->
  addressRegister = 0xA
  [value0, value1] = [42, 64]
  mod.registers[0x0] = value0
  mod.registers[0x1] = value1
  mod.registers[addressRegister] = outputAddress
  mod.ram[0] = mod.makeInstruction(4, addressRegister, 0x0, 0)
  mod.ram[1] = mod.makeInstruction(4, addressRegister, 0x1, 0)
  mod.cpu.run()
  deepEqual mod.ram[outputAddress], [output0, output1]

test 'Write to debug output', ->
  runDebugOutputTest(this, 0xFFFF, 42, 64)

test 'Attempt to write to debug input', ->
  pc = 2
  @cpu.pc = pc
  @registers[0] = 0xFFFE   # debug input address
  # STR R1 -> M[R0]        # write 0 to debug input
  @ram[pc] = 0x4010        # Attempt to write to input
  throws (-> @cpu.step()), /Write to debug input at PC 2/

test 'Attempt to read from debug output', ->
  pc = 5
  @cpu.pc = pc
  @registers[0] = 0xFFFF   # debug output address
  # LOD M[R0] -> R1        # read from debug output
  @ram[pc] = 0x3001        # Attempt to read output
  throws (-> @cpu.step()), /Read from debug output at PC 5/
