#include <stdint.h>
#include "x86helper.h"
#include "console.h"
#include "isr.h"
#include "v86.h"

static uint32_t exc_gpf_handler_vm (registers_t *sframe)
{
    static uint32_t * const ivt_base = (uint32_t *)0x000;
    uint8_t  *lin_eip = far16_to_lin (sframe->user_cs, sframe->user_eip);
    uint16_t *lin_esp;
    uint8_t  ivt_idx;

    switch (lin_eip[0]) {
    /* Handle INT N instruction */
    case 0xcd:
        print_str_attr ("[v8086: INT_N]\n", ATTR_BWHITE_ON_BLUE);
        lin_esp = far16_to_lin_wrap (sframe->user_ss, sframe->user_esp);

        /* Push FLAGS, CS, IP on v8086 mode stack */
        *(--lin_esp) = (uint16_t)sframe->user_flags;
        *(--lin_esp) = sframe->user_cs;
        *(--lin_esp) = sframe->user_eip + 2;
        /* Adjust v8086 mode stack pointer to account for 6 new bytes pushed */
        sframe->user_esp = (uint16_t)(sframe->user_esp - 6);

        /* We need to clear the IF and TF bits when resuming v8086 mode */
        sframe->user_flags &= ~(1<<EFLAGS_IF_BIT | 1<<EFLAGS_TF_BIT);
        /* When returning back to v8086 mode, we return back to the address stored
           for the interrupt requested. That address is in the v8086 IVT
           starting at 0x0000:0x0000 */
        ivt_idx = lin_eip[1];
        sframe->user_eip = ivt_base[ivt_idx] & 0xffff;
        sframe->user_cs  = ivt_base[ivt_idx] >> 16;
        break;
    /* Handle IRET instruction (16-bit operands only) */
    case 0xcf:
        print_str_attr ("[v8086: IRET]\n", ATTR_BWHITE_ON_BLUE);
        lin_esp = far16_to_lin_wrap (sframe->user_ss, sframe->user_esp);

        /* Retrieve the return address (CS:IP) from v8086 stack */
        sframe->user_eip = lin_esp[0];
        sframe->user_cs  = lin_esp[1];

        /* With IRET (w/16-bit operands), the FLAGS on the stack aren't
           allowed to have the IOPL bits changed. We clear the IOPL bits
           and force them to the current IOPL. The top 16 bits of EFLAGS
           are unchanged */
        sframe->user_flags = (sframe->user_flags & 0xffff0000) |
                             ((uint32_t)lin_esp[2] & ~(3<<EFLAGS_IOPL_BITS)) |
                             (sframe->user_flags & (3<<EFLAGS_IOPL_BITS));
        /* Remove the 6 bytes making up the IRET's stack frame */
        sframe->user_esp   = (uint16_t)(sframe->user_esp + 6);
        break;
    default:
        print_str_attr ("[v8086: Unhandled instruction]\n", ATTR_BWHITE_ON_RED);
        while (TRUE) hlt ();
    }
    return 0;
}

static uint32_t exc_invop_handler_vm (registers_t *sframe)
{
    uint16_t *lin_eip = far16_to_lin (sframe->user_cs, sframe->user_eip);
    switch (*lin_eip) {
    case 0x0b0f:
        print_str_attr ("[v8086: UD2]\n", ATTR_BWHITE_ON_BLUE);
        exit_v86();
        break;
    default:
        print_str_attr ("[v8086: Unhandled UD? instruction]\n", ATTR_BWHITE_ON_RED);
        while (TRUE) hlt ();
    }
    return 0;
}

uint32_t common_isr_handler (registers_t *sframe, uint8_t isvm)
{
    if (isvm) {
        switch (sframe->intno) {
        case 0x06:
            return exc_invop_handler_vm (sframe);
        case 0x0d:
            return exc_gpf_handler_vm (sframe);
        default:
            print_str_attr ("[v8086: Unhandled Exception]\n", ATTR_BWHITE_ON_RED);
            while (TRUE) hlt ();
            break;
        }
    } else {
        print_str_attr ("[PM: Unhandled Exception]\n", ATTR_BWHITE_ON_RED);
        while (TRUE) hlt ();
    }
    return 0;
}
