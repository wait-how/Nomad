/* application m68k link script */

MEMORY
{
  ram (rx) : ORIGIN = 0x20000, LENGTH = 128K
}

SECTIONS
{
  . = 0x20000;
  .text : { *(.text) } > ram
  .data : { *(.data) } > ram
  .bss : { *(.bss) } > ram
}
