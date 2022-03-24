# Assembly Instructions
## 1. Ordering Parts
There are three kinds of processors that are compatible with the Nomad board, all of which are slightly different:
1. The 68000 is the "classic" 68000 processor.  This processor draws more power than the 68HC000, and cannot be clocked as fast.  Use the 68HC000.
2. The 68HC000 is a modification to the 68000.  It is constructed with CMOS technology instead of NMOS technology, and as a result draws less power and can be clocked faster.  The Nomad board has been tested with this processor.
3. The 68010 is a small feature upgrade from the 68000.  It draws more power (not sure if HC versions exist) but adds virtual memory support and a tiny 2-byte cache, among other things.  The 68010 has not been officially tested with the board, but should work properly.

Note that the Nomad board obviously does not support any 68000-series processor in a DIP64 package.

Any speed grade should work, with higher speed grade processors being able to be clocked faster.

Order everything on the "parts required" section, and the PCB.  Alternatively, one could order the parts and assemble the Nomad on a breadboard, although this takes significantly longer and is not recommended.

## 2. Power Supply
Assemble the power supply according to the schematic.  Test the power supply by plugging in a compatible wall wart to the DC jack and checking if the power LED turns on.  If the power LED does not turn on or is dim, immediately unplug the wall wart and check for shorts or bad connections.

## 3. Passives
Assemble all the passives, including the capacitors and resistors.  Assembling the sockets is also a good idea at this point, but make sure to not solder the sockets with chips inserted in them.

## 4. 68000 Processor
Plug in the 68000 processor and minimal glue logic.

To test if you build this part of the circuit correctly, add 10k pulldown resistors on all 15 data lines of the processor.  Power on the board, and verify with an oscilloscope that A0 operates at 1/4th the clock frequency, A1 operates at 1/8th frequency, and so on.  This is called "freerunning" and is important to verify before proceeding further to minimize errors in assembly.

Additionally, one can test the ability of the processor to crash by converting the D0 pin to a pullup rather than a pulldown resistor, ensuring the processor will encounter a double bus fault on startup.  This will cause the "!HALT" signal to be low, which can be verified using an oscilloscope.

## 5. EEPROM and Glue Logic
Assemble EEPROM glue logic.

At this point, enough of the processor is built that carefully constructed programs can be built and uploaded to the Nomad board to check functionality automatically. 

To verify correct assembly, flash a dummy program that just halts the processor and insert both EEPROM chips into the Nomad board.  The "H" EEPROM goes in the "H" socket, and the "L" EEPROM goes in the "L" socket.  Make sure to distinguish the "H" and "L" EEPROMs, as the order is important.  Power the board and verify that it does not freerun.

## 6. SRAM and Glue Logic
Assemble SRAM glue logic.

One can write a simple program that writes values to SRAM and reads the value back out, and halting if the read and written values differ.  Note that v1.0 of the hardware has a bug where the byte select signals for SRAM are backwards, so byte writes will fail and byte reads will return garbage.

## 7. MFP and Glue Logic
Assemble the MFP glue logic.

At this point, enough of the Nomad board is assembled that testing can switch to software rather than hardware.  Flash the bootloader program, and connect the UART port of the Nomad board to a USB-UART converter.  Configure your terminal emulator to be 115200 baud, 8N1.  Power on the board, and verify that text is printed onto the screen.

Currently, the bootloader only supports writing code into RAM, which means that application code will have to be re-uploaded every time the board is turned on.
