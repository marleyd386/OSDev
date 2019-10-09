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
