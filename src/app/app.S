| Application section of 68k device

	.text
	.global user_start

| At startup: user mode, IPL 0, stack is 0x37000, entry point is 0x20000
user_start: 
	
	
	.section .bss
.align 4

	.section .data
.align 4
