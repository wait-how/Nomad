	.section .rodata
.set RESET_SSP_PTR, 0x40000
.set RESET_PC, 0x00000400

.long RESET_SSP_PTR
.long RESET_PC
.space 0x3F8

.set MFP_IO_DDR, 0x40005
.set MFP_IO_GPDR, 0x40001

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
	move.b #0xFE, (MFP_IO_DDR) | I0 is input, I1-I7 are outputs
	move.b #0x40, (MFP_VR) | point IVR to right after mandatory section of EVT
	
|	timer stuff: MFP has 4 timers, 2 are delay only (C and D, both of which just count until done)
|	A and B timers have pulse width measuring mode - external signal is an enable to the timer, also stuff with the AER
|	and event counting mode - each pulse on the input bumps the timer

|	GPIO pins also have active edge registers that allow them to trigger interrupts

print:
	btst #0, (MFP_IO_GPDR)
	beq 1f
	bset #2, (MFP_IO_GPDR)
	bra print
1:	bclr #2, (MFP_IO_GPDR)
	bra print

