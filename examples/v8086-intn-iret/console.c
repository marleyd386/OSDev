#include <stdint.h>
#include "x86helper.h"
#include "console.h"

void clear_screen (void)
{
    int num_cells  = 80*25;
    vid_offset = 0;

    while (vid_offset < num_cells)
        vid_mem[vid_offset++] = (uint16_t)ATTR_WHITE_ON_BLACK << 8 | ' ';

    vid_offset = 0;
}

void print_str_attr (const char *str, uint8_t attr)
{
    while (*str) {
        if (*str == '\n')
            vid_offset = (++vid_line)*80;
        else
            vid_mem[vid_offset++] = (uint16_t)attr << 8 | *str;
        str++;
    }

    return;
}
