OUTPUT_FORMAT("elf32-i386");
ENTRY(_start);

REAL_BASE = 0x00007c00;

SECTIONS
{
    . = REAL_BASE;

    .text : SUBALIGN(4) {
        *(.text*);
    }

    .rodata : SUBALIGN(4) {
        *(.rodata*);
#include "gdtidt.ldh"
    }

    .data : SUBALIGN(4) {
        *(.data);
    }

    /* Disk boot signature */
    .bootsig : AT(0x7dfe) {
        SHORT (0xaa55);
    }

    .bss : SUBALIGN(4) {
        *(COMMON);
        *(.bss)
    }

    /DISCARD/ : { 
        *(.note.gnu.property)
        *(.comment);
    }
}
