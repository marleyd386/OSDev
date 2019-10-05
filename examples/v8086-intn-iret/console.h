#ifndef CONSOLE_H
#define CONSOLE_H

#include <stdint.h>
#include "x86helper.h"

#define VIDEO_TEXT_ADDR 0xb8000
#define VIDEO_TEXT_SEG  (VIDEO_TEXT_ADDR>>4)

#define COLOR_BWHITE           0x0f
#define COLOR_WHITE            0x07
#define COLOR_BLACK            0x00
#define COLOR_BLUE             0x01
#define COLOR_GREEN            0x02
#define COLOR_RED              0x04
#define COLOR_MAGENTA          0x05
#define TEXT_ATTR(fg,bg) (bg<<4 | fg)

#define ATTR_BWHITE_ON_GREEN   TEXT_ATTR(COLOR_BWHITE, COLOR_GREEN)
#define ATTR_BWHITE_ON_MAGENTA TEXT_ATTR(COLOR_BWHITE, COLOR_MAGENTA)
#define ATTR_BWHITE_ON_BLUE    TEXT_ATTR(COLOR_BWHITE, COLOR_BLUE)
#define ATTR_BWHITE_ON_RED     TEXT_ATTR(COLOR_BWHITE, COLOR_RED)
#define ATTR_BWHITE_ON_GREEN   TEXT_ATTR(COLOR_BWHITE, COLOR_GREEN)
#define ATTR_BLUE_ON_WHITE     TEXT_ATTR(COLOR_BLUE,   COLOR_WHITE)
#define ATTR_RED_ON_WHITE      TEXT_ATTR(COLOR_RED,    COLOR_WHITE)
#define ATTR_WHITE_ON_BLACK    TEXT_ATTR(COLOR_WHITE,  COLOR_BLACK)

extern uint16_t vid_offset;
extern uint16_t vid_line;

static volatile uint16_t *const vid_mem = (uint16_t *)VIDEO_TEXT_ADDR;

fastcall void rm_print_str_attr (const char *str, uint8_t attr);
void print_str_attr (const char *str, uint8_t attr);
void clear_screen (void);

#endif
