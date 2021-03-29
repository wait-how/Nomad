	.section .rodata
.set RESET_SSP_PTR, 0x40000
.set RESET_PC, 0x00000400

.long RESET_SSP_PTR
.long RESET_PC
.space 0x3F8

.set MFP_VR, 0x40017
.set MFP_IMRA, 0x40013
.set MFP_IMRB, 0x40015
.set MFP_UART_SCR, 0x40027
.set MFP_UART_UCR, 0x40029
.set MFP_UART_RSR, 0x4002B
.set MFP_UART_TSR, 0x4002D
.set MFP_UART_DATA, 0x4002F

	.text
	.global start

start:
	move.b #0xFF, (0x40005) | all IO pins outputs
	move.b #0x1, (0x40001) | set I0 to high
	
	move.b #0x40, (MFP_VR) | point IVR to right after mandatory section of EVT
	move.b #0x8, (MFP_UART_UCR) | uart: 1 start bit, 1 stop bit, async
	
	move.b #0x0, (MFP_IMRA) | clear mask registers - interrupt bits are recognizable, but cannot trigger an interrupt
	move.b #0x0, (MFP_IMRB)
	
	move.b #0x4, (MFP_UART_TSR) | idle high
	move.b #0x1, (MFP_UART_TSR) | enable tx
	
|	move.b #0x1, (MFP_UART_RSR)
|	read stuff out with the Buffer Full bit (7)
| 	eventually check for read / write errors in both registers!

|	timer stuff: MFP has 4 timers, 2 are delay only (C and D, both of which just count until done)
|	A and B timers have pulse width measuring mode - external signal is an enable to the timer, also stuff with the AER
|	and event counting mode - each pulse on the input bumps the timer

|	GPIO pins also have active edge registers that allow them to trigger interrupts

print:
	| MFP Buffer Empty bit set when ready, cleared when in the process of transmitting

	| word addressing is fine, but the byte addressing is backwards.
	| peripheral is addressed correctly, which is why I can print stuff
	| I can print literals just fine because they are accessed on word boundaries
	
	clr %d0
	clr %d1
	move.b (0x440), %d0
	move.b (0x441), %d1
	
1:	btst #7, (MFP_UART_TSR)
	beq 1b
	move.b %d0, (MFP_UART_DATA)

7:	btst #7, (MFP_UART_TSR)
	beq 7b
	move.b %d1, (MFP_UART_DATA)

| newline is the standard CRLF ('\n' is just CR)
2:	btst #7, (MFP_UART_TSR)
	beq 2b
	move.b #0xD, (MFP_UART_DATA) | CR
3:	btst #7, (MFP_UART_DATA)
	beq 3b
	move.b #0xA, (MFP_UART_DATA) | LF

	bra print

	.data
str: .asciz "hello\n"
