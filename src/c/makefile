CSRC := $(wildcard *.c)
CPPSRC := $(wildcard *.cpp)

CSTART := cstart.S

CLINK := clink.l
CPPLINK := clink.l $(shell m68k-elf-g++ -print-file-name=crtbegin.o) $(shell m68k-elf-g++ -print-file-name=crtend.o)

ALLFLAGS := -march=68000 -mcpu=68000 -nostdlib -ffreestanding -Wall -Og

CFLAGS := $(CSRC) $(ALLFLAGS) -Wl,-lgcc,-T,$(CLINK)
CPPFLAGS := $(CPPSRC) $(ALLFLAGS) -Wl,-lgcc,-T,$(CPPLINK)

lang: pre # compile a C file, building as an application
	@echo "Using $(shell which m68k-elf-gcc) as C compiler."
	@m68k-elf-gcc $(CFLAGS) -o lang.out # use gcc as linker as well
	@m68k-elf-objcopy -O binary lang.out lang.bin
	@m68k-elf-objdump -d lang.out

langpp: pre
	@echo "Using $(shell which m68k-elf-g++) as C++ compiler."
	@m68k-elf-gcc $(CPPFLAGS) -o langpp.out # use gcc as linker as well
	@m68k-elf-objcopy -O binary langpp.out langpp.bin
	@m68k-elf-objdump -d langpp.out
	@echo "need to write crti and crto for constructors and destructors to work..." && false

pre: # announce host and eventually check that binutils exists
	@echo "Building on: $(shell uname)"
	@echo "Using $(shell which m68k-elf-as) as assembler."
	@m68k-elf-as -march=68000 -mcpu=68000  $(CSTART) -o cstart.o # assemble small start file

clean:
	 @rm -f {*.out,*.o,*.bin}
