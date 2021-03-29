/* boot m68k link script */

MEMORY
{
  rom (rx) : ORIGIN = 0x0, LENGTH = 128K
}

SECTIONS
{
  .rodata : { *(.rodata) } > rom 
  . = 0x400;
  .text : { *(.text) } > rom
  .data : { *(.data) } > rom
}
