STACKSIZE equ 0x4000

bits 32
global mbentry

extern kmain
extern pm_setup
extern realmode_setup

; Multiboot Header
section .multiboot
MBALIGN     equ 1<<0
MEMINFO     equ 1<<1
VIDINFO     equ 0<<2
FLAGS       equ MBALIGN | MEMINFO | VIDINFO
MAGIC       equ 0x1BADB002
CHECKSUM    equ -(MAGIC + FLAGS)

mb_hdr:
    dd MAGIC
    dd FLAGS
    dd CHECKSUM

section .text
mbentry:
    cli
    cld
    mov esp, stack_top

    ; EAX = magic number. Should be 0x2badb002
    ; EBX = pointer to multiboot_info
    ; Pass as parameters to kmain
    push eax
    push ebx

    ; Copy real mode code to low memory at 0x00001000
    call realmode_setup
    ; Initialize protected mode, setup GDT and IDT
    call pm_setup
    ; Call C entry point
    call kmain
    add esp, 8                 ; Remove parameters from the stack

    ; Infinite loop to end program
    cli
.endloop:
    hlt
    jmp .endloop

section .bss
align 32
stack:
    resb STACKSIZE
stack_top:
