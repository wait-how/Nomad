# Nomad

A 68000 board.

## Details
See hackaday page.

### Memory map
0x00000 🠂 0x1FFFF: EEPROM  
	0x000 🠂 0x400: EVT  
	0x400 🠂 0x1FFFF: Bootloader and lib code - write-protected as this (will) set up the MMU.  
0x20000 🠂 0x3FFFF: "common" SRAM - accessible to all programs (put application code here)  
	0x3FC00 🠂 0x3FFFF: Program data (1024 bytes)  
		0x3FC00 🠂 0x3FC3F: MFP UART buffer (64 bytes)  
		0x3FC40 🠂 0x3FCFF: Reserved kernel space (used for EEPROM updates)  
0x40000 🠂 0x400FF?: MFP  

calling convention:
 - everything is callee-saved except for a0, a1, d0, and d1
 - pass everything on the stack as a long, eliminates alignment issues and we have the space for it

## Revision 1
Status: ordered, assembled, and partially tested.
  
 - Things that were broken:
	 - Bought a tantulum cap instead of an electrolytic one, didn't notice, and it blew on me
	 - RX buffering was inverted, luckily caught it before it broke anything
	 - Only one inverting buffer was used, so all of the TX and RX signals are inverted.
	 - Some of the silkscreens for the expansion IO were off a little, but I knew about that
	 - RC values for reset were wrong because I didn't have anything pulling current from it in the simulation
	 - 10uF caps have the wrong footprint
	 - Mounting holes were too small
	 - Software Data Protection on the EEPROMs needed to be turned off, but that isn't a huge concern and working around SDP is really annoying with current architecture
	 - MFP DTACK signal is grounded all the time, but MFP still accepts reads and writes.  Not a huge issue since grounded DTACK makes sense from a logical point of view
	 - Cold solder joint on 4AN1 prevented the MFP from being triggered

 - Things that worked:
	 - CPU executed code in a loop, RAM word access seemed to be working okay
	 - MFP can read data values off the bus and manipulate the IO ports just fine.
	 - MFP can print out characters encoded in instruction literals
	 - MFP can echo characters off the UART

 - Measurements:
	 - Board draws ~270mA when active
	 - At 14MHz (highest clock freq available that works properly) MFP IO switch time is 10us

## Revision 2
Status: schematic created, but revisions have not been checked either by hand or by computer

## TODOs
 - Do housekeeping such as zeroing out .bss section because no OS will do it for us
   - cannot load anything into SRAM at assemble time, all has to be done by bootloader.
 - Get the board clocked at 16 MHz (12 - 12.5 right now because anything faster will cause the MFP to not work)
 - put some artwork or something cool on the bottom side if it doesn't add too much to the cost of the board
 - make it so the bootloader program contains a lot of test code, and the board could read an unimplemented area of memory to determine what tests to run.
 - decide how much stuff I want to write in C vs assembly
 - write a linker script and assembly file containing _start, use it with GCC (can't use the standard _start since I have special requirements as to the memory layout)
 - write code in C, test on an x64 machine
 - port newlib to the board, but before all that I have to order a rev 2 with all the issues fixed.
 - finish vim extension for m68k asm

## Things I tried

### Bad ideas
 - letting the MMU handle illegal accesses to low 128K of memory - MMU has to sit between processor and memory
 - remove pullup on AS - there to prevent spurious memory acceses once bus master is done and CPU has not relinquished control of the bus yet
 - having the processor wait for the UART host to transmit a binary - will hang if the board should be booting from a stored EEPROM program
 - supervisor access only to EEPROM - prevents user from using hardware libs, initial supervisor -> user jump is awkward at best
 - having MFP drive IRQ lines directly - if a priority level 2 interrupt and level 1 interrupt fire at the same time, the processor will register a level 3 interrupt.

### Maybe ideas:
 - having an MMU board at all - 68451 chip is kinda hard to find on eBay and pretty expensive too, couldn't find a PLCC package for it

## Future ideas
 - make a wall clock using cool 7-seg displays
 - air quality measurement using some sort of gas sensor
 - add a GSM module or something - usually UART based!
 - some sort of laser thing - laser servo application!
 - write some sort of graphics application or game
	 - controlling the screen over UART isn't a good idea, and the maximum data transfer speed over the IO lines is pretty slow
 - use an FPGA board to perform DMA on the memory (like the Apple Macintosh)
	 - DMA would have to work correctly for this to function properly, and 68000 DMA chips are really hard to find
	 - write an I2C driver that bit-bangs data off the I/O port to something like an SSD1306
	   - simple, and doesn't require special hardware.
		 - might be hard to make this fast enough for a fun game
	 - reviewing OpenGL code before doing this would be helpful for knowing the features I need if 3D graphics are to be included
	 - screen options are I2C, a simple VGA adapter, or a full on HDMI port
 - User board
	 - could literally just be some switches and (buffered) LEDs
	 - switches can be pulled high or low, so a read to unimplemented memory can read in values (drive DTACK high until done)
	 - could also be CPLD-based
		 - gives me a chance to put something CPLD-based in here
		 - JTAG experience
		 - add features like DTACK/BERR generation
		 - add IO that can actually source current
 - Audio board
	 - could initially just be an op-amp or two connected to a couple lines on the MFP
	 - probably want a seperate power supply for this to avoid noise on the power lines?
	 - could also add seperate voices - if I were to do this it would require external hardware, MFP is pretty limited
 - Floating point arithmetic
	 - don't use the 68k floating point hardware - requires a 68020 or greater for coprocessor support
	 - hardware support without the 68020 is kinda dumb
 - Use a later version of the 68000 architecture.
   - Having a MMU and a FPU on-chip would be nice
   - Should be able to clock it at the same frequencies, which means no high-speed circuit design.
	 - If I go all the way up to the 68040/68060, I get nice features like JTAG and integrated FPU and MMUs
	 - Need to worry about heat sink stuff, kinda like a real computer
	 - At this point it would be easier to design a raspi clone, which is hard to do.
 - Replace the hard glue logic with a CPLD
	 - Should have done this originally, a lot easier to work with and I would have learned way more
	 - Custom hardware for peripherals, because finding cheap 68000-compatible peripheral chips is annoying
	 - If glue logic is required, use HCT family instead of LS family. Easier to interface with.
 - More interface options
	 - SPI using the MFP I/O pins - slow, but easier to implement
	 - External device grabs host memory using DMA (FPGA or CPLD with microcontroller)
		 - significantly faster
		 - harder to design
		 - requires host board modification since the DMA functionality is broken currently
	 - Dual-ported RAM
		- a good idea for video stuff, especially 3D applications
	 - FIFO chips
		 - good for ingesting lots of fast data
		 - could be part of a high-speed 8-bit parallel bus - clocked way higher than the processor itself?
		 - if using the AM7202A chip lying around, I could use the 9th bit to do hardware parity checking
 - Paper tape reader (for fun)
	 - Use a CPLD for interfacing with the board
	 - Might teach me something about proper motor control
	 - Uses either a cardboard or LEGO structure to read in holes punched into the tape
	 - Once that is done, use a solenoid motor to possibly punch holes in a new tape and output it