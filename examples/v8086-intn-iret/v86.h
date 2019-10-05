#ifndef V86_H
#define V86_H

#define EFLAGS_VM_BIT    17    /* EFLAGS VM bit */
#define EFLAGS_BIT1      1     /* EFLAGS bit 1 (reserved, always 1) */
#define EFLAGS_TF_BIT    8     /* EFLAGS TF bit */
#define EFLAGS_IF_BIT    9     /* EFLAGS IF bit */
#define EFLAGS_IOPL_BITS 12    /* EFLAGS IOPL bits (bit 12 and bit 13) */

extern void exit_v86  (void);
extern void enter_v86 (uint16_t cs_seg, uint16_t ip,
                       uint16_t ss_seg, uint16_t esp,
                       uint32_t flags);
#endif
