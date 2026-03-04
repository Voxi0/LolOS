MBALIGN  equ  1 << 0            ; align loaded modules on page boundaries
MEMINFO  equ  1 << 1            ; provide memory map
VIDMOD   equ  1 << 2            ; request video mode
FLAGS    equ  MBALIGN | MEMINFO | VIDMOD
MAGIC    equ  0x1BADB002        ; 'magic number' lets bootloader find the header
CHECKSUM equ -(MAGIC + FLAGS)   ; checksum of above, to prove we are multiboot

section .multiboot alloc
align 4
	dd MAGIC
	dd FLAGS
	dd CHECKSUM
	dd 0, 0, 0, 0, 0            ; unused 
	dd 0                        ; linear graphics
	dd 1024                     ; width
	dd 768                      ; height
	dd 32                       ; bpp

section .bss
align 16
stack_bottom:
resb 16384 ; 16 KiB
stack_top:

section .text
global _start:function (_start.end - _start)
extern kernel_main

_start:
	mov esp, stack_top

	; Per the Multiboot spec:
	;   EAX = 0x2BADB002 (bootloader magic)
	;   EBX = pointer to multiboot info struct
	; C calling convention: push args right-to-left
	push ebx          ; arg2: multiboot_info_t* addr
	push eax          ; arg1: uint32_t magic

	call kernel_main

	cli
.hang:	hlt
	jmp .hang
.end:
