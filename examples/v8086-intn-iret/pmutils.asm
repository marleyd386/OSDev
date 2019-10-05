%include "macros.inc"

IOPL_LEVEL             EQU 0       ; IO privilege level = 0, restricted ring 3
EFLAGS_VM_BIT          EQU 17      ; EFLAGS VM bit
EFLAGS_BIT1            EQU 1       ; EFLAGS bit 1 (reserved, always 1)
EFLAGS_IF_BIT          EQU 9       ; EFLAGS IF bit
EFLAGS_IOPL_BITS       EQU 12      ; EFLAGS IOPL bits (bit 12 and bit 13)
TSS_IO_BITMAP_SIZE     EQU 0x400/8 ; IO Bitmap for 0x400 IO ports
                                   ; Size 0 disables IO port bitmap (no permission)
RING0_EXC_STACK_SIZE   EQU 2048    ; Size of Ring0 exception stack in TSS.

global pm_setup
global enter_v86
global exit_v86
extern common_isr_handler

bits 32
section .text

pm_setup:
    ; Set the exception handlers in the IDT
    SET_IDT_ENTRY_HANDLER idt.isr6,  exc_invopcode
    SET_IDT_ENTRY_HANDLER idt.isr13, exc_gpf
    ; Set the TSS entry base address in the GDT's TSS entry
    SET_GDT_ENTRY_BASE    gdt.tss32, tss

    lgdt [gdtr]                 ; Load our GDT
    lidt [idtr]                 ; Install interrupt table

    jmp CODE32_SEL:.setcs       ; Set CS and resume
.setcs:

    mov ax, DATA32_SEL          ; Setup the segment registers with data selector
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax                  ; Not currently using FS and GS
    mov gs, ax

    ; Set iomap_base in tss with the offset of the iomap relative to beginning of the tss
    mov word [tss.iomap_base], tss.iomap-tss

    mov dword [tss.esp0], ring0_exc_stack_top
    mov dword [tss.ss0], DATA32_SEL

    mov eax, TSS32_SEL
    ltr ax                      ; Load default TSS (used for exceptions, interrupts, etc)
    ret

; void enter_v86(uint16_t cs_seg, uint16_t ip,
;               uint16_t ss_seg, uint16_t esp,
;               uint32_t flags);
; Follows CDECL calling convention
enter_v86:
    push ebp
    mov ebp, esp
    push es                     ; Save protected mode context
    push ds
    push fs
    push gs
    pusha
    pushf                       ; Flags, CS, EIP for an IRET to return
    push cs
    push dword .retfromvm
    mov [save_ss], ss           ; Save SS:ESP so they can be restored when
    mov [save_esp], esp         ;     exiting v8086 mode

    ; Set up initial v8086 stack frame
    xor eax, eax                ; EBX=0
    push eax                    ; Real mode GS=0
    push eax                    ; Real mode FS=0
    push eax                    ; Real mode DS=0
    push eax                    ; Real mode ES=0
    push dword [ebp+16]         ; Push SS:SP from passed arguments
    push dword [ebp+20]         ;     v8086 stack SS:SP (grows down from SS:SP)
    or dword [ebp+24], 1<<EFLAGS_VM_BIT | 1<<EFLAGS_BIT1
                                ; Set VM and BIT1 in flags
    push dword [ebp+24]         ; Push the flags
    push dword [ebp+8]          ; Push entry point (segment)
    push dword [ebp+12]         ; Push entry point (offset)

    mov ebx, eax                ; Set all the general purpose registers to 0
    mov ecx, eax                ;     EAX was set to 0 above
    mov edx, eax
    mov esi, eax
    mov edi, eax
    mov ebp, eax

    iret                        ; Transfer control to v8086 mode and our real mode code

.retfromvm:
    popa                        ; Restore protected mode context
    pop gs
    pop fs
    pop ds
    pop es

    leave
    ret

; void exit_v86(void);
; Follows CDECL calling convention
exit_v86:
    mov ss, [save_ss]           ; Restore SS:ESP to kernel stack frame
    mov esp, [save_esp]         ;     as it was before entering VM mode
    iret                        ; Return back to function that switched to VM mode

; #UD Invalid Opcode v8086 exception handler
exc_invopcode:
    push 0                      ; Push dummy error number
    push 0x06                   ; Push exception number
    jmp common_isr_stub

; #GP v8086 General Protection Fault handler
exc_gpf:
    push 0x0d                   ; Push exception number
;    jmp common_isr_stub

common_isr_stub:
    pusha                       ; Save all general purpose registers
    mov ebx, esp                ; EBX = beginning of stack frame including registers

    xor ecx, ecx                ; Set isvm flag to 0
    test dword [esp+48], 1<<EFLAGS_VM_BIT
    setnz cl                    ; If the eflags VM bit is set, set the isvm flag

    push ds                     ; Save original DS for restoration after ISR handler
    push ecx                    ; Push the isvm flag on stack as 2nd argument
    mov eax, DATA32_SEL         ; Setup the segment registers with kernel data selector
    mov ds, eax
    mov es, eax
    mov fs, eax
    mov gs, eax
    push ebx                    ; 1st arg is a pointer to exception stack frame
    cld                         ; DF=0 forward string movement
    call common_isr_handler
    pop eax                     ; Remove first parameter from stack
    pop ecx                     ; Restore the isvm flag
    pop eax                     ; Retrieve saved DS
    test ecx, ecx               ; Were we called from VM mode?
    jnz .vmexit                 ;     If so, don't restore segment registers
    mov gs, eax                 ; Otherwise restore all segment registers
    mov es, eax                 ;     Assume all of them are the same selector
    mov fs, eax
    mov ds, eax
.vmexit:
    popa                        ; Restore all general purpose registers
    add esp, 8                  ; Remove the error code and intno
;    xchg bx, bx
    iret

section .data
align 16

; Task State Structure (TSS)
tss:
.back_link: dd 0
.esp0:      dd 0                ; Kernel stack pointer used on ring transitions
.ss0:       dd 0                ; Kernel stack segment used on ring transitions
.esp1:      dd 0
.ss1:       dd 0
.esp2:      dd 0
.ss2:       dd 0
.cr3:       dd 0
.eip:       dd 0
.eflags:    dd 0
.eax:       dd 0
.ecx:       dd 0
.edx:       dd 0
.ebx:       dd 0
.esp:       dd 0
.ebp:       dd 0
.esi:       dd 0
.edi:       dd 0
.es:        dd 0
.cs:        dd 0
.ss:        dd 0
.ds:        dd 0
.fs:        dd 0
.gs:        dd 0
.ldt:       dd 0
.trap:      dw 0
.iomap_base:dw 0                ; IOPB offset

.iomap: TIMES TSS_IO_BITMAP_SIZE db 0x00
                                ; IO bitmap (IOPB) size 8192 (8*8192=65536) representing
                                ; all ports. An IO bitmap size of 0 would fault all IO
                                ; port access if IOPL < CPL (CPL=3 with v8086)
%if TSS_IO_BITMAP_SIZE > 0
.iomap_pad: db 0xff             ; Padding byte that has to be filled with 0xff
                                ; To deal with issues on some CPUs when using an IOPB
%endif
.end:
TSS_SIZE EQU tss.end - tss

align 4
gdt:
    dq MAKE_GDT_DESC(0, 0, 0, 0)   ; null descriptor
.code32:
    dq MAKE_GDT_DESC(0, 0x000fffff, 10011010b, 1100b)
                                ; 32-bit code, 4kb gran, limit 0xffffffff bytes, base=0
.data32:
    dq MAKE_GDT_DESC(0, 0x000fffff, 10010010b, 1100b)
                                ; 32-bit data, 4kb gran, limit 0xffffffff bytes, base=0
.tss32:
    dq MAKE_GDT_DESC(0, TSS_SIZE-1, 10001001b, 0000b)
                                ; 32-bit TSS, 1b gran, available, IOPL=0
.end:

CODE32_SEL equ gdt.code32 - gdt
DATA32_SEL equ gdt.data32 - gdt
TSS32_SEL  equ gdt.tss32  - gdt

gdtr:
    dw gdt.end - gdt - 1        ; limit (Size of GDT - 1)
    dd gdt                      ; base of GDT

align 4
; Create an IDT which handles #UD and #GPF. All other exceptions set to 0
; so that they triple fault. No external interrupts supported. Handler addresses
; will be filled in at runtime with SET_IDT_HANDLER macro
idt:
    TIMES 6 dq 0
.isr6:
    dq MAKE_IDT_DESC(0x0, CODE32_SEL, 10001110b) ; 6
    TIMES 6 dq 0
.isr13:
    dq MAKE_IDT_DESC(0x0, CODE32_SEL, 10001110b) ; D
    TIMES 18 dq 0
.end:

align 4
idtr:
    dw idt.end - idt - 1        ; limit (Size of IDT - 1)
    dd idt                      ; base of IDT

section .bss
align 16
ring0_exc_stack: resb RING0_EXC_STACK_SIZE
ring0_exc_stack_top:

align 4
save_esp: resd 1
save_ss:  resd 1
