#include "desktop.h"
#include "login.h"
#include "apps.h"
#include "graphics.h"
#include "font.h"
#include "gui.h"
#include "vfs.h"
#include <stdint.h>

os_state_t os_state   = OS_STATE_LOGIN;
int        focused_app = APP_TERMINAL;

/* -------------------------------------------------------
 * Taskbar layout (bottom 32px)
 * -------------------------------------------------------*/
#define TASKBAR_H 32
#define TB_BTN_W  90
#define TB_BTN_H  24
#define TB_BTN_PAD 4

static const char* tb_labels[APP_COUNT] = {
    "Terminal", "Files", "Calculator", "Text Editor"
};

static void draw_taskbar(void) {
    uint32_t sw = current_width, sh = current_height;
    uint32_t ty = sh - TASKBAR_H;

    // Bar background with gradient look
    fill_rect(0, ty, sw, TASKBAR_H, 0x2B3A55);
    fill_rect(0, ty, sw, 1, 0x4A6494);      // top highlight line

    // Start/Logo button
    fill_rect(2, ty + 4, 60, 24, 0x1C5FA5);
    draw_rect(2, ty + 4, 60, 24, 0x5588CC);
    draw_string(8, ty + 12, "LoLOS", 0xFFFFFF, 0);

    // App buttons
    for (int i = 0; i < APP_COUNT; i++) {
        uint32_t bx = 70 + i * (TB_BTN_W + TB_BTN_PAD);
        uint32_t by = ty + 4;

        // Highlight if app is visible
        uint8_t visible = 0;
        if (i == APP_TERMINAL)    visible = g_terminal.visible;
        if (i == APP_FILEMANAGER) visible = g_filemanager.visible;
        if (i == APP_CALCULATOR)  visible = g_calculator.visible;
        if (i == APP_TEXTEDITOR)  visible = g_texteditor.visible;

        uint32_t bg = visible ? 0x4A6EB0 : 0x334466;
        uint32_t border = (i == focused_app) ? 0xFFAA00 : 0x556688;

        fill_rect(bx, by, TB_BTN_W, TB_BTN_H, bg);
        draw_rect(bx, by, TB_BTN_W, TB_BTN_H, border);
        draw_string(bx + 4, by + 8, tb_labels[i], 0xFFFFFF, bg);
    }

    // Clock area (static for now)
    draw_string(sw - 56, ty + 12, "00:00", 0xCCDDFF, 0);
}

void desktop_draw(void) {
    // Background / wallpaper
    fill_rect(0, 0, current_width, current_height - TASKBAR_H, 0x1A3A5C);

    // Simple grid pattern wallpaper
    for (uint32_t y = 0; y < current_height - TASKBAR_H; y += 40)
        fill_rect(0, y, current_width, 1, 0x204060);
    for (uint32_t x = 0; x < current_width; x += 40)
        fill_rect(x, 0, 1, current_height - TASKBAR_H, 0x204060);

    // OS name watermark
    draw_string(current_width - 56, current_height - TASKBAR_H - 20, "LoLOS", 0x2A4A70, 0);

    // Desktop icons (top-left column)
    uint32_t ic_y = 20;
    for (int i = 0; i < APP_COUNT; i++) {
        // Icon box
        fill_rect(12, ic_y, 48, 40, 0x1E4A70);
        draw_rect(12, ic_y, 48, 40, 0x4488BB);
        const char* icons[APP_COUNT] = {">_", "FM", "CA", "ED"};
        draw_string(24, ic_y + 14, icons[i], 0xFFFFFF, 0);
        draw_string(8, ic_y + 44, tb_labels[i], 0xCCDDFF, 0);
        ic_y += 72;
    }

    // Redraw visible windows
    if (g_terminal.visible)    terminal_draw();
    if (g_filemanager.visible) filemanager_draw();
    if (g_calculator.visible)  calculator_draw();
    if (g_texteditor.visible)  texteditor_draw();

    // Taskbar on top (always)
    draw_taskbar();
}

/* -------------------------------------------------------
 * Click hit test helpers
 * -------------------------------------------------------*/
static int hit(int32_t cx, int32_t cy, uint32_t x, uint32_t y, uint32_t w, uint32_t h) {
    return cx >= (int32_t)x && cx < (int32_t)(x+w) && cy >= (int32_t)y && cy < (int32_t)(y+h);
}

static void toggle_app(int app_id) {
    switch (app_id) {
        case APP_TERMINAL:    g_terminal.visible    ^= 1; terminal_draw();    break;
        case APP_FILEMANAGER: g_filemanager.visible ^= 1; filemanager_draw(); break;
        case APP_CALCULATOR:  g_calculator.visible  ^= 1; calculator_draw();  break;
        case APP_TEXTEDITOR:  g_texteditor.visible  ^= 1; texteditor_draw();  break;
    }
    focused_app = app_id;
    draw_taskbar();
}

void desktop_on_click(int32_t x, int32_t y) {
    if (os_state != OS_STATE_DESKTOP) return;
    uint32_t sw = current_width, sh = current_height;
    uint32_t ty = sh - TASKBAR_H;

    /* ---- Taskbar buttons ---- */
    if (y >= (int32_t)ty) {
        for (int i = 0; i < APP_COUNT; i++) {
            int32_t bx = (int32_t)(70 + i * (TB_BTN_W + TB_BTN_PAD));
            int32_t by = (int32_t)(ty + 4);
            if (hit(x, y, bx, by, TB_BTN_W, TB_BTN_H)) {
                toggle_app(i);
                return;
            }
        }
        return;
    }

    /* ---- Desktop icons ---- */
    int32_t ic_y = 20;
    for (int i = 0; i < APP_COUNT; i++) {
        if (hit(x, y, 8, ic_y, 64, 56)) {
            toggle_app(i);
            return;
        }
        ic_y += 72;
    }

    /* ---- Terminal window ---- */
    if (g_terminal.visible) {
        uint32_t wx = g_terminal.x, wy = g_terminal.y;
        uint32_t ww = g_terminal.width;
        // Close button
        if (hit(x, y, wx + ww - 20, wy + 4, 16, 16)) {
            g_terminal.visible = 0;
            desktop_draw(); return;
        }
        // Focus
        if (hit(x, y, wx, wy, ww, g_terminal.height)) {
            focused_app = APP_TERMINAL; draw_taskbar(); return;
        }
    }

    /* ---- File Manager window ---- */
    if (g_filemanager.visible) {
        uint32_t wx = g_filemanager.x, wy = g_filemanager.y;
        uint32_t ww = g_filemanager.width, wh = g_filemanager.height;
        if (hit(x, y, wx + ww - 20, wy + 4, 16, 16)) {
            g_filemanager.visible = 0; desktop_draw(); return;
        }
        // Row selection
        if (hit(x, y, wx, wy + 44, ww, wh - 64)) {
            int rel_y = (int)(y - (int32_t)(wy + 44));
            g_filemanager.selected = rel_y / 18;
            focused_app = APP_FILEMANAGER;
            filemanager_draw(); draw_taskbar(); return;
        }
        if (hit(x, y, wx, wy, ww, wh)) { focused_app = APP_FILEMANAGER; draw_taskbar(); return; }
    }

    /* ---- Calculator window ---- */
    if (g_calculator.visible) {
        uint32_t wx = g_calculator.x, wy = g_calculator.y;
        uint32_t ww = g_calculator.width;
        if (hit(x, y, wx + ww - 20, wy + 4, 16, 16)) {
            g_calculator.visible = 0; desktop_draw(); return;
        }
        // Button clicks
        calculator_click(x, y);
        focused_app = APP_CALCULATOR; draw_taskbar();
    }

    /* ---- Text Editor ---- */
    if (g_texteditor.visible) {
        uint32_t wx = g_texteditor.x, wy = g_texteditor.y;
        uint32_t ww = g_texteditor.width, wh = g_texteditor.height;
        if (hit(x, y, wx + ww - 20, wy + 4, 16, 16)) {
            g_texteditor.visible = 0; desktop_draw(); return;
        }
        // Save button
        if (hit(x, y, wx + 6, wy + 29, 48, 14)) {
            g_texteditor.buf[g_texteditor.buf_len] = '\0';
            vfs_create(g_texteditor.filename, g_texteditor.buf);
            return;
        }
        if (hit(x, y, wx, wy, ww, wh)) { focused_app = APP_TEXTEDITOR; draw_taskbar(); return; }
    }
}

void desktop_keyboard(char c) {
    if (os_state == OS_STATE_LOGIN) {
        login_key(c);
        return;
    }
    // Route to focused app
    switch (focused_app) {
        case APP_TERMINAL:   if (g_terminal.visible)    terminal_type(c);   break;
        case APP_TEXTEDITOR: if (g_texteditor.visible)  texteditor_type(c); break;
        default: break;
    }
}

void desktop_init(void) {
    os_state   = OS_STATE_LOGIN;
    focused_app = APP_TERMINAL;
}
