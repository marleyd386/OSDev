OUTPUT_FORMAT("elf32-i386");
ENTRY(mbentry);

/* Multiboot spec uses 0x00100000 as a base */
KERNEL_BASE = 0x00100000;
REAL_BASE = 0x00001000;

SECTIONS
{
    . = KERNEL_BASE;

    /* Place the multiboot record first */
    .multiboot : {
        *(.multiboot);
    }

    /* This is the tricky part. The LMA (load memory address) is the
     * memory location the code/data is read into memory by the
     * multiboot loader. The LMA is after the colon. We want to tell
     * the linker that the code/data in this section was loaded into
     * RAM in the memory area above 0x100000. On the other hand the
     * VMA (virtual memory address) specified before the colon acts
     * like an ORG directive. The VMA tells the linker to resolve all 
     * subsequent code starting relative to the specified VMA. The
     * VMA in this case is REAL_BASE which we defined as 0x1000.
     * 0x1000 is 4KB page aligned (useful if you ever use paging) and
     * resides above the end of the interrupt table and the
     * BIOS Data Area (BDA)
     */

    __kernelreal_diff = . - REAL_BASE;
    .realmode REAL_BASE : AT(ADDR(.realmode) + __kernelreal_diff) SUBALIGN(4) {
        /* The __realmode* values can be used by code to copy
         * the code/data from where it was placed in RAM by the 
         * multiboot loader into lower memory at REAL_BASE
         *
         * . (period) is the current VMA */
        __realmode_vma_start = .;

        /* LOADADDR is the LMA of the specified section */ 
        __realmode_lma_start = LOADADDR(.realmode);
        *.rmo(.text*);
        *.rmo(.rodata*);
        *.rmo(.data);
        *.rmo(COMMON);
        *.rmo(.bss)
    }
    . = ALIGN(4);
    __realmode_vma_end = .;
    __realmode_secsize   = ((__realmode_vma_end)-(__realmode_vma_start));
    __realmode_secsize_l = __realmode_secsize>>2;
    __realmode_lma_end   = __realmode_vma_start + __kernelreal_diff + __realmode_secsize;


    /* . (period) is the current VMA. We set it to the value that would
     * have been generated had we not changed the VMA in the previous
     * section. The .text section also specified the LMA = VMA with
     * AT(ADDR(.text))
     */
    . += __kernelreal_diff;
    .text ALIGN(4K): AT(ADDR(.text)) {
        *(.text*);
    }

    /* From this point the linker script is typical */
    .data ALIGN(4K) : {
        *(.data);
    }

    .data ALIGN(4K) : {
        *(.rodata*);
    }

    /* We want to avoid this section being placed in low memory */
    .eh_frame : {
        *(.eh_frame*);
    }

    .bss ALIGN(4K): {
        *(COMMON);
        *(.bss)
    }

    /DISCARD/ : { 
        *(.note.gnu.property)
        *(.comment);
    }
}
