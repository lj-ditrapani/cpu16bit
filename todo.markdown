---------|---------|---------|---------|---------|---------|---------|--
- Run coffeelint
- Add basic debug I/O (hex, decimal, ASCII char streams)
    - Exceptions for bad I/O (write to input, read output)
    - hex
    - ASCII
- Refactor
    - Create new branch
    - refactor test
    - refactor code
    - tests:
        - In module

            @ram = @cpu.getRam()
            @registers = @cpu.getRegisters()
            so you don't have to type @cpu.registers ect

    - Use functions instead of raw ram/registers
        - cpu.getRam
        - cpu.getRegisters
    - I/O Use functions instead of raw addresses
        - getDecimalOutput
        - setDecimalInput
        - getHexOutput
        - setHexInput
        - getCharOutput
        - setCharInput
- Split specs into seprate spec files (unit acceptance I/O video)
- Split readme into separate files
    - cpu
    - video
    - I/O
- Readme file
    - Split ISA from implementation
    - Have cpu file
      And separate computer file (MHz, register file porting, etc)
