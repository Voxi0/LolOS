# LoLOS - Low-level Operating System

LoLOS is a 32-bit x86 operating system developed from scratch in Assembly, C, and C++. It features a modern graphical interface, memory management, and several pre-installed applications.

## 🚀 Features

- **Bootloader**: Custom Multiboot kernel compatible with GRUB.
- **Architecture**: 32-bit protected mode with GDT, IDT, ISRs, and IRQs.
- **Graphics**: High-resolution VESA VBE (1024x768x32) with optimized double-buffering.
- **Input**: PS/2 Keyboard and Mouse drivers (with a graphical cursor).
- **GUI**: Interactive windowing system with a taskbar, icons, and focus management.
- **Memory**: Kernel heap allocator (kmalloc) for dynamic resource management.
- **VFS**: Basic Virtual File System for managing files in memory.

## 📂 Project Structure

- `src/boot.s`: The assembly entry point.
- `src/kernel.c`: The main kernel logic and system initialization.
- `src/graphics.c`: Drawing library and double-buffering implementation.
- `src/desktop.c`: State machine for the GUI and user interaction.
- `src/apps.c`: Built-in applications (Terminal, Calculator, Text Editor, File Manager).
- `src/mouse.c`: PS/2 mouse handling and cursor rendering.
- `src/vfs.c`: In-memory file system.
- `src/memory.c`: Kernel memory management.

## 🖥️ Applications

1. **Terminal**: A CLI window for typing and shell simulation.
2. **Calculator**: Fully functional graphical calculator.
3. **Text Editor**: Edit text and save files directly to the VFS.
4. **File Manager**: Browse files stored in the memory-based filesystem.

## 🛠️ How to Build and Run

### Prerequisites

You need the following tools installed on your Linux system:
- `nasm`
- `gcc`
- `make`
- `qemu-system-i386`
- `grub-common`
- `xorriso`

### Build

To compile the entire OS and generate the bootable ISO:
```bash
make
```

### Run

To launch the OS in QEMU:
```bash
make run
```

*Note: Use `Ctrl + Alt + G` to capture/release the mouse in QEMU.*

## 🔐 Credentials

The OS is password-protected.
- **Username**: admin
- **Password**: `admin1234`

---
*Developed with ❤️ as an educational OsDEV project.*
