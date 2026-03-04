#include "graphics.h"
#include "memory.h"
#include <stddef.h>

static uint32_t* front_buffer = NULL;
static uint32_t* back_buffer = NULL;

uint32_t* current_framebuffer = NULL; // This will point to back_buffer
uint32_t current_width = 0;
uint32_t current_height = 0;
uint32_t current_pitch = 0;

void init_graphics(uint32_t* framebuffer, uint32_t width, uint32_t height, uint32_t pitch) {
    front_buffer = framebuffer;
    current_width = width;
    current_height = height;
    current_pitch = pitch;

    // Allocate back buffer using our new kmalloc
    // Pitch / 4 is the number of 32-bit words per line
    size_t buffer_size = (pitch / 4) * height * sizeof(uint32_t);
    back_buffer = (uint32_t*)kmalloc_aligned(buffer_size, 4096);
    
    // Set current draw target to the back buffer
    current_framebuffer = back_buffer;
}

void swap_buffers(void) {
    if (!front_buffer || !back_buffer) return;
    
    // High-performance copy from back to front
    // We can copy word by word (32-bit)
    uint32_t total_words = (current_pitch / 4) * current_height;
    for (uint32_t i = 0; i < total_words; i++) {
        front_buffer[i] = back_buffer[i];
    }
}

void put_pixel(uint32_t x, uint32_t y, uint32_t color) {
    if (!current_framebuffer) return;
    if (x >= current_width || y >= current_height) return;

    uint32_t location = x + (y * (current_pitch / 4));
    current_framebuffer[location] = color;
}

void draw_rect(uint32_t x, uint32_t y, uint32_t width, uint32_t height, uint32_t color) {
    for (uint32_t i = 0; i < width; i++) {
        put_pixel(x + i, y, color);
        put_pixel(x + i, y + height - 1, color);
    }
    for (uint32_t i = 0; i < height; i++) {
        put_pixel(x, y + i, color);
        put_pixel(x + width - 1, y + i, color);
    }
}

void fill_rect(uint32_t x, uint32_t y, uint32_t width, uint32_t height, uint32_t color) {
    if (!current_framebuffer) return;
    
    uint32_t words_per_line = current_pitch / 4;
    for (uint32_t i = 0; i < height; i++) {
        uint32_t row_offset = (y + i) * words_per_line + x;
        for (uint32_t j = 0; j < width; j++) {
            current_framebuffer[row_offset + j] = color;
        }
    }
}

void clear_screen(uint32_t color) {
    // Highly optimized clear
    if (!current_framebuffer) return;
    uint32_t total_words = (current_pitch / 4) * current_height;
    for (uint32_t i = 0; i < total_words; i++) {
        current_framebuffer[i] = color;
    }
}
