	.text
	.global _start
	.type _start,@function
_start:
	| getting here in user mode with stack set to 0x37000, CCR cleared.
	jsr main

