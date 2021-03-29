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
	
	move.b #0x1, (MFP_UART_RSR) | enable rx

|	read stuff out with the Buffer Full bit (7)
| 	eventually check for read / write errors in both registers!

echo:

1:	btst #7, (MFP_UART_RSR)
	beq 1b
	move.b (MFP_UART_DATA), %d0

2:	btst #7, (MFP_UART_TSR)
	beq 2b
	move.b %d0, (MFP_UART_DATA)
	
	bra echo


