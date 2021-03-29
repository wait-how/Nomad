| misc core lib and kernel stuff that should be helpful for application programs...
| TODO: write trap handlers that at least try to recover from errors, if not too serious

.set ram_function, 0x3FC40

.text

| xor all words in a block, returning a checksum
| @param: length of block - 1
| @param: start address
| @returns: checksum
checksum:
	move.l %d2, -(%sp) | save d2
	move.l 4(%sp), %d1 | len
	move.l 8(%sp), %a0 | addr
	clr %d0 | running checksum
1:	move.w (%a0), %d2
	eor %d2, %d0
	dbf %d1, 1b
	move.l (%sp)+, %d2 | restore d2
	rts

| itoa, implemented in assembly
| all numbers are considered unsigned, printed in hex
| @param: number to convert to int
| @param: space to write int to (max space needed is 8 chars for hex)
asm_itoa:
	move.l %d2, -(%sp) | save d2
	move 4(%sp), %a0 | space
	move 8(%sp), %d1 | num

1:	cmpi #0, %a0
	beq 4f | done?
	move.l %d1, %d2
	andi.b #0x0F, %d2
	cmpi.b #0xA, %d2 | if greater than 2, add from 'A', not '0'
	bge 2f
	add #0x30, %d2 | add '0'
	bra 3f
2:	add #0x41, %d2 | add 'A'
3:	move.b %d2, (%a0)+ | write to next byte
	bra 1b
4:	move.b #0, (%a0)+ | add a null byte	
	move.l (%sp)+, %d2 | restore d2
	rts

| NOTE: loop overhead is 10us for delay_us and 15us for  regular delay
| calculations done for a 16MHz clock

| software delay subroutine
| ((ms * 1000) / 22) loops required
| @param: ms to delay for
delay:
	move.l 4(%sp), %d0
	mulu.w #1000, %d0 | convert ms -> us
	move.w %d0, %d1 | move into seperate register to avoid loading in remainder?
	divu.w #22, %d1 | divide by loop execution time
	move.w %d1, %d0 | move quotient into d0
	clr %d1

1:	addq.l #1, %d1 | 8 cc
	cmp.l %d1, %d0 | 6 cc
	beq.b 1b | 8 cc when not taken
	| 22 cc total
	rts

| same as delay but in microseconds
| (us / 22) loops required
| @param: us to delay for
delay_us:
	move.l 4(%sp), %d0 | 16 cc 
	move.w %d0, %d1 | 4 cc
	divu.w #22, %d1 | 140 cc
	move.w %d1, %d0 | 4 cc
	clr %d1 | 6 cc

1:	addq.l #1, %d1 | 8 cc
	cmp.l %d1, %d0 | 6 cc
	beq.b 1b | 8 cc when not taken
	rts

| EEPROM writing works, since you need to de-assert CS every time you write a byte and you have to wait 200us (way longer than 68k instruction fetches) in order to write a page
| SDP needs to be disabled since the SDP enable sequence is part of the page-write sequence, as well as the fact that the SDP enable sequence would be written to neither chip
| since it has both odd and even addresses.

| TODO: check the heck out of this against the EEPROM write spec

| the holy grail of bootloaders - writing a block of flash to EEPROM
| write a 128-byte page of memory to one of two EEPROM chips, blocking until the write is complete.
| @param: address of block to write (word-aligned)
| @param: EEPROM address to write block to (128-byte aligned)
eeprom_write_page:

	.set ram_prog_size, ewp_ram_prog_end-ewp_ram_prog | calculate size of RAM part of bootloader and put it into a constant
	moveq #ram_prog_size, %d0 | probably less than 255 bytes
	
	move.l #ewp_ram_prog, %a0 | load EEPROM write program into RAM, since EEPROM memory will be unavailable during write.
	move.l #0x3FC40, %a1
1:	cmpi #0, %d0
	beq 2f
	move.b (%a0)+, (%a1)+
	subq #1, %d0
	bra 1b

2:	move #128, %d0
	clr %d1
	move.l 4(%sp), %a0 | memory address
	move.l 8(%sp), %a1 | EEPROM address

	jmp ram_function | start of kernel memory and where we dumped the RAM function

3:	rts

| program to run in RAM to write a page of EEPROM memory
ewp_ram_prog:
	move.b (%a0)+, (%a1)
	addq #2, %a1 | has to be same EEPROM chip
	| can't be a dbcc since it jumps to the wrong address, possibly a bug in binutils.
	cmp #0, %a1
	jmp ram_function
	
	move.l #200, -(%sp)
	jsr delay_us
	addq #4, %sp

1:	| use toggle bit method to check for write completion
	btst #6, (%a1)
	move %sr, %d0
	btst #6, (%a1)
	move %sr, %d1
	cmp.b %d0, %d1 | TODO: make sure these are the same in every other bit but Z.
	.set ram_bne_add, 0x3FC40 + 0x1A | cannot jump to any assembler labels since all of those are in ROM
	jmp ram_bne_add

	jmp 3b | done, jump back to kernel portion
	
| end of program in RAM, for assembler use only.
ewp_ram_prog_end:
	nop | has to be at least one instruction here or it will alias the next label

| generic exception handler for unrecoverable system events
bad_exception:
	move.l #0x20100, %sp | reset possibly corrupted stack pointer
	or.i #0x700, %sr | disable interrupts
	reset | try to bring the MFP back online - also clears interrupt sources
    move.l system_error_message, %a0 | code copied from mfp_write.
    clr %d0
    clr %d1
1:  cmp.b (%a0), %d1 | test for null character
    beq 3f
2:  btst #7, (0x4002D) | wait until buffer is ready
    beq 2b
    move.b (%a0)+, (MFP_UART_DATA) | write byte to MFP
    addq #1, %d0
    bra 1b
3:	stop #0x700

| interactive dump of registers
dumpir:
	| push all registers on the stack using movem
	| pop each one off, turn to an ascii-encoded string, and print it in hex
	| TODO: check if stack has enough space for this?
	| TODO: don't need to push all registers, just the ones we modify (including d0-d2/a0-a2)
	movem %d0-%d7/%a0-%a7, -(%sp)
	sub #8, %sp | space for asm_itoa to work
	move %sp, %d1

	moveq #16, %d0

1:	move.l (%sp), -(%sp)
	move.l %d1, -(%sp)
	jsr asm_itoa
	add #8, %sp
	
	| move.l %d0, -(%sp)
	| jsr uart_write | TODO: not sure about parameters here?
	
	subq #1, %d0
	cmpi #0, %d0
	bne 1b

	rts

| 00000000:0000 0000 0000 0000 0000 0000 0000 0000
| 00000010:0010 00FF AAFF 0000 0000 0000 0000 FFAF

| interactive dump of memory contents
| @param: address to dump
| @param: length of memory block to dump (multiple of 16)
dumpim:
	move.l 4(%sp), %a0
	move.l 8(%sp), %a1
	| TODO: finish this
	| PUSH A2
	| write address, justified to 8 characters
	move.b #':', %d0
	jsr mfp_writec
	move.b (%a0)+, %d0
	| do a quick itoa here, since %d0 is a byte and 0 <= d0 <= 255
	| write %d0
	cmp %a0, %a1
	| bne ...
	| POP A2
	rts

.data
.align 4
system_error_message: .asciz "System crash - no longer nomadic!\n"
