<!-- ====|=========|=========|=========|=========|=========|======== -->
- Run coffeelint
- Remove debug I/O; use output I/O space instead (video or storge out)
- Refactor
    - refactor code
- Improve ISA file


Considerations
--------------
- Use functions instead of raw ram/registers
    - cpu.getRam
    - cpu.getRegisters
- I/O Use functions instead of raw addresses
    - getDebugOutput
    - setDebugInput
- Remove debug I/O?
