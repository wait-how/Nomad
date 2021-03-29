| a small interpreter to facilitate testing of the 68000 board and manipulation of programs
| using the MFP and core code I already wrote
| 
| syntax:
| <command> <arg> <arg> ... ;
| ex:
| > CheckSum 0xFF001 128 (checksum 128 bytes including and after 0xFF001)
| 0x45FF3D (the checksum is returned to the interpreter)

| interpreter features:
| SetVar STACKPOINTER 0xFFFF (can now use STACKPOINTER, will replace with 0xFFFF)
| DumpVar STACKPOINTER (prints value of STACKPOINTER)
| SetEnv SP BLOCKP (sets the stack pointer to SP, pointer to environment info to BLOCKP)
| DumpEnv (prints environment stuff here, all vars defined and stuff)
| (a comment here, interpreter ignores this)

| commands:
| DumpRegisters (dump all registers in a readable form)
| DumpMemory 0xFF 0x1FF (dump all memory in range, print like normal ascii dump)
| SetMemory 0x234F LONG 0x1 (sets a memory location of the given type)
| Execute 0x111F (execute the code at the given address) (execute as user)
| SelfTest (returns the number of errors and why they occurred)
| Info (returns hardware info stored somewhere and interpreter info)

| interpreter info:
| version
| linked list of variables to traverse (should traverse most recent to least recent, faster)
| (prev pointer) (next pointer) (string pointer) (value)

| commands:
| - notify user when exceptions occur, and how bad they are

