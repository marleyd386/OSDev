CROSSPREFIX:=i686-elf-
CC:=$(CROSSPREFIX)gcc
LD:=$(CROSSPREFIX)ld
AS:=$(CROSSPREFIX)as
OBJCOPY:=$(CROSSPREFIX)objcopy
NASM:=nasm
DD:=dd
GDB:=gdb
QEMU:=qemu-system-i386
BOCHS:=bochs
GRUB_MKRESCUE:=grub-mkrescue

CFLAGS=-g -Wall -Wextra -pedantic -std=gnu99 -ffreestanding \
       -fno-asynchronous-unwind-tables -fomit-frame-pointer -fno-pie
CFLAGS32=-O3 -m32 -mpreferred-stack-boundary=2
CFLAGS16=-Os -m16 -xc -mpreferred-stack-boundary=2
NASMFLAGS=-f elf32 -gdwarf
LINK_SCRIPT=link.ld
LINKFLAGS=-m32 -no-pie -nostdlib -Wl,--build-id=none -T$(LINK_SCRIPT)
QEMUFLAGS:=
QEMU_BP:=*kmain
BOCHS_CFG:=/dev/null

OBJS=$(patsubst %.c,%.o,$(wildcard *.c))
OBJS_RM=$(patsubst %.rmc,%.rmo,$(wildcard *.rmc))
OBJS_NASM=$(patsubst %.asm,%.o,$(wildcard *.asm)) \
	$(patsubst %.rma,%.rmo,$(wildcard *.rma))
C_INCLUDES=$(wildcard *.h)
ASM_INCLUDES=$(wildcard *.inc)

KERNEL:=v8086
KERNEL_ELF:=$(KERNEL).elf
KERNEL_ISO:=$(KERNEL).iso
ISO_DIR:=iso
GRUB_CFG:=grub.cfg

.PHONY: all clean bochs qemu qemu-iso qemu-dbg qemu-iso-dbg

all:$(KERNEL_ELF) $(KERNEL_ISO)

qemu:$(KERNEL_ELF)
	$(QEMU) -kernel $(KERNEL_ELF) $(QEMUFLAGS)

qemu-iso:$(KERNEL_ISO)
	$(QEMU) -cdrom $(KERNEL_ISO) $(QEMUFLAGS)

qemu-dbg:$(KERNEL_ELF)
	$(QEMU) -kernel $(KERNEL_ELF) $(QEMUFLAGS) -S -s &
	$(GDB) $(KERNEL_ELF) \
		-ex 'target remote localhost:1234' \
		-ex 'layout src' \
		-ex 'layout regs' \
		-ex 'break $(QEMU_BP)' \
		-ex 'continue'

qemu-iso-dbg:$(KERNEL_ISO)
	$(QEMU) -cdrom $(KERNEL_ISO) $(QEMUFLAGS) -S -s &
	$(GDB) $(KERNEL_ELF) \
		-ex 'target remote localhost:1234' \
		-ex 'layout src' \
		-ex 'layout regs' \
		-ex 'break $(QEMU_BP)' \
		-ex 'continue'

bochs:$(KERNEL_ISO) $(BOCHS_CFG)
	$(BOCHS) -qf $(BOCHS_CFG) \
		'ata0-master: type=cdrom, path="$(KERNEL_ISO)", status=inserted, model="Generic 1234", biosdetect=auto' \
		'boot: cdrom' \
		'magic_break: enabled=1'

$(KERNEL_ISO): $(KERNEL_ELF)
	mkdir -p $(ISO_DIR)/boot/grub
	cp $(KERNEL_ELF) $(ISO_DIR)/boot/$(KERNEL_ELF)
	@echo 'Creating $(ISO_DIR)/boot/grub/$(GRUB_CFG)'
	@echo 'set timeout=0'                   >  $(ISO_DIR)/boot/grub/$(GRUB_CFG)
	@echo 'set default=0'                   >> $(ISO_DIR)/boot/grub/$(GRUB_CFG)
	@echo 'menuentry "My Kernel" {'         >> $(ISO_DIR)/boot/grub/$(GRUB_CFG)
	@echo '  multiboot /boot/$(KERNEL_ELF)' >> $(ISO_DIR)/boot/grub/$(GRUB_CFG)
	@echo '}'                               >> $(ISO_DIR)/boot/grub/$(GRUB_CFG)
	@echo 'Creating $(KERNEL_ISO)'
	$(GRUB_MKRESCUE) -o $(KERNEL_ISO) $(ISO_DIR)/ 2>/dev/null

$(KERNEL_ELF): $(OBJS) $(OBJS_RM) $(OBJS_NASM) $(LINK_SCRIPT)
	$(CC) $(LINKFLAGS) -o $@ $(OBJS) $(OBJS_RM) $(OBJS_NASM) -lgcc

%.o:%.c $(C_INCLUDES)
	$(CC) -c $(CFLAGS) $(CFLAGS32) -o $@ $<

%.o:%.asm $(ASM_INCLUDES)
	$(NASM) $(NASMFLAGS) -o $@ $<

%.rmo:%.rma $(ASM_INCLUDES)
	$(NASM) $(NASMFLAGS) -o $@ $<

%.rmo:%.rmc $(C_INCLUDES)
	$(CC) -c $(CFLAGS) $(CFLAGS16) -o $@ $<

clean:
	rm -f $(OBJS) \
		$(OBJS_RM) \
		$(OBJS_NASM) \
		$(KERNEL_ELF) \
		$(KERNEL_ISO)
	rm -rf $(ISO_DIR)
