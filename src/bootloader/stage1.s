[bits 16]
[org 0x7c00]

; Stage 1 Bootloader (MBR)
start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00

    mov [boot_drive], dl

    mov si, msg_loading
    call print_string

    ; Load Stage 2 (8 sectors)
    mov bx, 0x7e00
    mov al, 8           ; 8 sectors
    mov cl, 2           ; Start sector 2
    call disk_load

    mov si, msg_jump
    call print_string
    
    mov dl, [boot_drive]
    jmp 0x0000:0x7e00

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

disk_load:
    pusha
    mov ah, 0x02
    mov dh, 0
    mov ch, 0
    mov dl, [boot_drive]
    int 0x13
    jc .err
    popa
    ret
.err:
    mov si, msg_err
    call print_string
    jmp $

msg_loading db 'L1...', 0
msg_jump    db 'J2...', 0
msg_err     db 'E1', 0
boot_drive  db 0

times 510-($-$$) db 0
dw 0xaa55
