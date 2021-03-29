# note that this is currently a well-formed makefile script with hardcoded files everywhere
# c makefile is in the c source directory since it's a lot more complicated.
exclude := src/boot/start.S
SRC := $(filter-out $(exclude), $(wildcard src/boot/*.S))
APP := $(wildcard src/app/*.S)
TEST := src/test/test.S

BOOT_LINK := src/boot/link_boot_script.l
APP_LINK := src/app/link_app_script.l

FLAGS := -march=68000 -mcpu=68000

boot: pre # assemble the bootloader
	m68k-elf-as $(FLAGS) $(exclude) $(SRC) -o boot.o # start.S code always executes first, putting it in the SRC variable means other files may be put at 0x400
	m68k-elf-ld -T $(BOOT_LINK) boot.o -o boot.out
	m68k-elf-objcopy -O binary boot.out boot.bin
	m68k-elf-readelf -S boot.out

asm: pre # dump assembly of bootloader
	@m68k-elf-objdump -d boot.out

test: pre # assemble a test file only, then dump assembly
	m68k-elf-as $(FLAGS) $(TEST) -o test.o
	m68k-elf-ld -T $(BOOT_LINK) test.o -o test.out # shouldn't matter where we link stuff to, just that it works properly
	m68k-elf-objcopy -O binary test.out test.bin
	@m68k-elf-readelf -S test.out
	@m68k-elf-objdump -D test.out

pre: # announce host and eventually check that binutils exists
	@echo "Building on: $(shell uname)"
	@echo "Using $(shell which m68k-elf-as) as assembler."

clean:
	@rm -f	{*.out,*.o,*.bin,*.lsb,*.msb}
