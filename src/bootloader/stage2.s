[bits 16]
[org 0x7e00]

; Stage 2 Bootloader (Robust Mode Search + LBA)
stage2_start:
    mov [boot_drive], dl
    
    ; Setup segments
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7e00

    mov si, msg_stage2
    call print_string

    ; 1. Enable A20
    call enable_a20

    ; 2. Find and Set VESA Mode 1024x768x32
    call find_vesa_mode

    ; 3. Load Kernel (LBA 9, 127 sectors)
    mov si, lba_packet
    mov byte [si], 0x10
    mov byte [si+1], 0
    mov word [si+2], 127
    mov word [si+4], 0x0000
    mov word [si+6], 0x1000
    mov dword [si+8], 9
    mov dword [si+12], 0

    mov ah, 0x42
    mov dl, [boot_drive]
    int 0x13
    jnc .load_ok

    ; CHS Fallback
    mov ax, 0x1000
    mov es, ax
    xor bx, bx
    mov ah, 0x02
    mov al, 64
    mov ch, 0
    mov dh, 0
    mov cl, 10
    mov dl, [boot_drive]
    int 0x13
    jc .disk_err

.load_ok:
    mov si, msg_loaded
    call print_string

    ; 4. Enter Protected Mode
    cli
    lgdt [gdt_descriptor]
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp CODE_SEG:init_pm

.disk_err:
    mov si, msg_error
    call print_string
    jmp hang

[bits 32]
init_pm:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000

    ; Copy kernel to 1MB
    mov esi, 0x10000
    mov edi, 0x100000
    mov ecx, 16384      ; 64KB
    rep movsd

    ; Set Multiboot magic and info
    mov eax, 0x2BADB002
    mov ebx, dummy_mbi

    jmp 0x100000

[bits 16]
print_string:
    pusha
    mov ah, 0x0e
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    popa
    ret

enable_a20:
    in al, 0x92
    or al, 2
    out 0x92, al
    ret

find_vesa_mode:
    ; We'll try to scan some common modes
    ; 1. Try 0x11B (standard 1024x768x32)
    mov cx, 0x11B
    call check_and_set_mode
    jc .found
    
    ; 2. Try 0x144 (some QEMU versions)
    mov cx, 0x144
    call check_and_set_mode
    jc .found

    ; 3. Fallback search (0x100 to 0x150)
    mov cx, 0x100
.search_loop:
    push cx
    call check_and_set_mode
    pop cx
    jc .found
    inc cx
    cmp cx, 0x150
    jl .search_loop

.vbe_err:
    mov si, msg_vbe_err
    call print_string
    ret

.found:
    ret

check_and_set_mode:
    ; cx = mode to check
    push cx
    mov ax, 0x4f01
    mov di, vbe_mode_info
    int 0x10
    cmp ax, 0x004f
    jne .fail

    ; Check attributes: must be supported, must be linear (bit 7)
    mov ax, [vbe_mode_info]
    test ax, 0x0001     ; Supported?
    jz .fail
    test ax, 0x0080     ; Linear?
    jz .fail

    ; Check resolution and BPP
    cmp word [vbe_mode_info + 18], 1024
    jne .fail
    cmp word [vbe_mode_info + 20], 768
    jne .fail
    cmp byte [vbe_mode_info + 25], 32
    jne .fail

    ; If we're here, we found a perfect mode
    pop cx
    mov bx, cx
    or bx, 0x4000       ; Set linear bit
    mov [vbe_mode_selected], bx
    
    mov ax, 0x4f02
    int 0x10
    cmp ax, 0x004f
    jne .real_fail

    ; Populate MBI
    mov dword [dummy_mbi], (1 << 12) | (1 << 11) | (1 << 1) | (1 << 0)
    mov dword [dummy_mbi + 4], 640
    mov dword [dummy_mbi + 8], 131072
    mov ax, [vbe_mode_selected]
    mov [dummy_mbi + 80], ax
    
    mov eax, [vbe_mode_info + 40]
    mov [dummy_mbi + 88], eax
    movzx eax, word [vbe_mode_info + 16] ; Pitch
    mov [dummy_mbi + 96], eax
    movzx eax, word [vbe_mode_info + 18] ; Width
    mov [dummy_mbi + 100], eax
    movzx eax, word [vbe_mode_info + 20] ; Height
    mov [dummy_mbi + 104], eax
    movzx eax, byte [vbe_mode_info + 25] ; BPP
    mov [dummy_mbi + 108], al
    mov byte [dummy_mbi + 109], 1        ; Type: RGB

    stc                 ; Success
    ret

.fail:
    pop cx
.real_fail:
    clc                 ; Failure
    ret

hang:
    cli
    hlt
    jmp hang

boot_drive db 0
vbe_mode_selected dw 0
msg_stage2 db 'S2 ', 0
msg_loaded db 'K ', 0
msg_error  db 'DE ', 0
msg_vbe_err db 'VE ', 0

align 4
lba_packet:
    times 16 db 0

align 4
dummy_mbi:
    times 128 db 0

vbe_mode_info:
    times 256 db 0

align 4
gdt_start:
    dd 0, 0
gdt_code:
    dw 0xffff, 0
    db 0, 10011010b, 11001111b, 0
gdt_data:
    dw 0xffff, 0
    db 0, 10010010b, 11001111b, 0
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start
times 4096-($-$$) db 0
