| read-only section including all interrupt vectors in the table
.section .rodata

.long RESET_SSP_PTR
.long RESET_PC
.space 4 | BUS_ERROR
.space 4 | ADDRESS_ERROR
.space 4 | ILLEGAL_INSTRUCTION
.space 4 | ZERO_DIVIDE
.space 4 | CHK_INSTRUCTION
.space 4 | TRAPV_INSTRUCTION
.space 4 | PRIVILEGE_VIOLATION
.space 4 | TRACE
.space 4 | LINE_1010_EMULATOR
.space 4 | LINE_1111_EMULATOR
.space 8 | - 
.space 4 | FORMAT_ERROR
.space 4 | UNINITIALIZED_INTERRUPT
.space 32 | - 
.space 4 | SPURIOUS_INTERRUPT
.space 4 | LEVEL_1_INTERRUPT - only 6800 peripherals are autovectored
.space 4 | LEVEL_2_INTERRUPT
.space 4 | LEVEL_3_INTERRUPT
.space 4 | LEVEL_4_INTERRUPT
.space 4 | LEVEL_5_INTERRUPT
.space 4 | LEVEL_6_INTERRUPT
.space 4 | LEVEL_7_INTERRUPT
.space 64 | TRAP vectors
.space 64 | - 
.space 4 | MFP_GPIO_0
.space 4 | MFP_GPIO_1
.space 4 | MFP_GPIO_2
.space 4 | MFP_GPIO_3
.space 4 | MFP_TIMER_D
.space 4 | MFP_TIMER_C
.space 4 | MFP_GPIO_4
.space 4 | MFP_GPIO_5
.space 4 | MFP_TIMER_B
.space 4 | MFP_UART_TXERR
.space 4 | MFP_UART_TXBUFE
.space 4 | MFP_UART_RXERR
.space 4 | MFP_UART_RXBUFF
.space 4 | MFP_TIMER_A
.space 4 | MFP_GPIO_6
.space 4 | MFP_GPIO_7
.space 704 | rest of user interrupt vectors

| minimum vectors needed for booting the processor
.set RESET_SSP_PTR, 0x40000 | stack is pre-decrement
.set RESET_PC, 0x400

.set version, 0x1 

