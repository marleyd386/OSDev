#ifndef ISR_H
#define ISR_H

#include <stdint.h>

typedef struct registers_s
{
    uint32_t edi;
    uint32_t esi;
    uint32_t ebp;
    uint32_t unused0;
    uint32_t ebx;
    uint32_t edx;
    uint32_t ecx;
    uint32_t eax;
    uint32_t intno;
    uint32_t errno;
    uint32_t user_eip;
    uint32_t user_cs;
    uint32_t user_flags;
    uint32_t user_esp;
    uint32_t user_ss;
    uint32_t vm_es;
    uint32_t vm_ds;
    uint32_t vm_fs;
    uint32_t vm_gs;
} registers_t;

extern uint32_t common_isr_handler (registers_t *sframe, uint8_t isvm);

#endif
