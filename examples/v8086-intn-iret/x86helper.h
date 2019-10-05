#ifndef X86HELPER_H
#define X86HELPER_H

#include <stdint.h>

#define TRUE 1
#define FALSE 0
#ifndef NULL
    #define NULL ((void *)0)
#endif

/* regparam(3) is a calling convention that passes first
   three parameters via registers instead of on stack.
   1st param = EAX, 2nd param = EDX, 3rd param = ECX */
#define fastcall  __attribute__((regparm(3)))

/* noreturn lets GCC know that a function that it may detect
   won't exit is intentional */
#define noreturn      __attribute__((noreturn))
#define always_inline __attribute__((always_inline))
#define naked         __attribute__((naked))

/* Define helper x86 function */
static inline void fastcall always_inline hlt(void){
    __asm__ ("hlt\n\t");
}

/* Set FS segment */
static inline void fastcall always_inline
set_fs(uint16_t segment)
{
    __asm__("mov %w[desc], %%fs\n\t"
            :
            : [desc] "rm"(segment)
            : "memory");
}

/* Set FS segment and return previous value */
static inline uint16_t fastcall always_inline
getset_fs(uint16_t segment)
{
    uint16_t origfs;
    __asm__ __volatile__("mov %%fs, %w[origfs]\n\t"
                         "mov %w[desc], %%fs\n\t"
                         : [origfs] "=&rm"(origfs)
                         : [desc] "rm"(segment)
                         : "memory");
    return origfs;
}

/* Write uint16_t value to fs:[offset] */
static inline void fastcall always_inline
write_uint16_fs (uint32_t offset, uint16_t value)
{
    __asm__("movw %[val], %%fs:(%[offset])\n\t"
            :
            : [offset]"r"(offset), [val]"ri"(value)
            : "memory");
}

static inline void *far16_to_lin (uint16_t seg, uint32_t offset)
{
    return (void *)((uintptr_t)seg << 4 | offset);
}

static inline void *far16_to_lin_wrap (uint16_t seg, uint32_t offset)
{
    uint32_t adjoffset = offset ? offset : 0x10000;
    return far16_to_lin (seg, adjoffset);
}
#endif
