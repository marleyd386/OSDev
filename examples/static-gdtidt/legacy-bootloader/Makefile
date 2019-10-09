LD:=ld
NASM:=nasm
GDB:=gdb
OBJCOPY:=objcopy
QEMU:=qemu-system-i386
BOCHS:=bochs
CPP:=cpp

NASMFLAGS=-f elf32 -gdwarf
LINK_SCRIPT=link.ld
LINKFLAGS=-melf_i386 -T$(LINK_SCRIPT)
BOCHS_CFG:=/dev/null
QEMUFLAGS=-d int -no-shutdown -no-reboot

OBJS_NASM=$(patsubst %.asm,%.o,$(wildcard *.asm))
ASM_INCLUDES=$(wildcard *.inc)
LD_INCLUDES=$(wildcard *.ldi)

BOOT_NAME:=boot
BOOT_ELF:=$(BOOT_NAME).elf
BOOT_BIN:=$(BOOT_NAME).bin

.PHONY: all clean bochs qemu

all:$(BOOT_BIN)

qemu:$(BOOT_BIN)
	$(QEMU) -drive format=raw,index=0,if=floppy,file=$(BOOT_BIN) $(QEMUFLAGS)

bochs:$(BOOT_BIN) $(BOCHS_CFG)
	$(BOCHS) -qf $(BOCHS_CFG) \
		'floppya: type=1_44, 1_44="$(BOOT_BIN)", status=inserted, write_protected=0' \
		'boot: floppy' \
		'magic_break: enabled=1'

$(LINK_SCRIPT): $(LINK_SCRIPT).pp $(LD_INCLUDES)
	$(CPP) -P $(LINK_SCRIPT).pp >$@

$(BOOT_BIN): $(BOOT_ELF)
	$(OBJCOPY) -O binary $< $@

$(BOOT_ELF): $(OBJS_NASM) $(LINK_SCRIPT)
	$(LD) $(LINKFLAGS) -o $@ $(OBJS_NASM)

%.o:%.asm $(ASM_INCLUDES)
	$(NASM) $(NASMFLAGS) -o $@ $<

clean:
	rm -f \
		$(OBJS_NASM) \
		$(BOOT_ELF) \
		$(BOOT_BIN) \
		$(LINK_SCRIPT)
