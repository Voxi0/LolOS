#ifndef GRAPHICS_H
#define GRAPHICS_H

#include <stdint.h>
#include <stddef.h>

extern uint32_t* current_framebuffer;
extern uint32_t current_width;
extern uint32_t current_height;
extern uint32_t current_pitch;

void init_graphics(uint32_t* framebuffer, uint32_t width, uint32_t height, uint32_t pitch);
void put_pixel(uint32_t x, uint32_t y, uint32_t color);
void draw_rect(uint32_t x, uint32_t y, uint32_t width, uint32_t height, uint32_t color);
void fill_rect(uint32_t x, uint32_t y, uint32_t width, uint32_t height, uint32_t color);
void clear_screen(uint32_t color);
void swap_buffers(void);

#endif
