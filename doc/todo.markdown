---------|---------|---------|---------|---------|---------|---------|--
- Run coffeelint
- Refactor
    - refactor code
- Change name of decimal I/O to debug I/O


Considerations
--------------
- Use functions instead of raw ram/registers
    - cpu.getRam
    - cpu.getRegisters
- I/O Use functions instead of raw addresses
    - getDebugOutput
    - setDebugInput
- Do not use a hex or char debug I/O; only decimal
