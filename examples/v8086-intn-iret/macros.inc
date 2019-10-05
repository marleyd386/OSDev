; Macro to build a GDT descriptor entry
%define MAKE_GDT_DESC(base, limit, access, flags) \
    (((base & 0x00FFFFFF) << 16) | \
    ((base & 0xFF000000) << 32) | \
    (limit & 0x0000FFFF) | \
    ((limit & 0x000F0000) << 32) | \
    ((access & 0xFF) << 40) | \
    ((flags & 0x0F) << 52))

; Macro to build a IDT descriptor entry
%define MAKE_IDT_DESC(offset, selector, access) \
    ((offset & 0x0000FFFF) | \
    ((offset & 0xFFFF0000) << 32) | \
    ((selector & 0x0000FFFF) << 16) | \
    ((access & 0xFF) << 40))

; Macro to set the handler address in an IDT entry
; %1 = address of IDT entry to modify
; %2 = address of the handler
; Clobbers EAX
%macro SET_IDT_ENTRY_HANDLER 2
    mov eax, %2
    mov [%1], ax
    shr eax, 16
    mov [%1 + 6], ax
%endmacro

; Macro to set the base address in a GDT entry
; %1 = address of GDT entry to modify
; %2 = base address
; Clobbers EAX
%macro SET_GDT_ENTRY_BASE 2
    mov eax, %2
    mov [%1+2], ax
    shr eax, 16
    mov [%1 + 4], al
    mov [%1 + 7], ah
%endmacro
