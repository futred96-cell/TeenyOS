; =============================================================================
; TeenyOS Kernel
; =============================================================================

[BITS 16]
[ORG 0x7C00]

KERNEL_LOAD      equ 0x7E00
RAM_INFO_ADDR    equ 0x4F00

boot_start:
    cli
    cld
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    mov [boot_drive], dl

    in al, 0x92
    or al, 0x02
    out 0x92, al

    mov ah, 0x88
    int 0x15
    jc .no_ram
    movzx eax, ax
    add eax, 640
    mov [RAM_INFO_ADDR], eax
    jmp .ram_done
.no_ram:
    mov dword [RAM_INFO_ADDR], 640
.ram_done:

    mov esi, 1
    mov ecx, 80
    mov ax, 0x0000
    mov es, ax
    mov di, 0x7E00
    call read_sectors

    mov esi, 81
    mov ecx, 80
    mov ax, 0x11E0
    mov es, ax
    xor di, di
    call read_sectors

    mov esi, 161
    mov ecx, 30
    mov ax, 0x1BE0
    mov es, ax
    xor di, di
    call read_sectors

    mov esi, 137
    mov ecx, 32
    mov ax, 0x1900
    mov es, ax
    xor di, di
    call read_sectors

    mov esi, 300
    mov ecx, 4
    mov ax, 0x0000
    mov es, ax
    mov di, 0x5000
    call read_sectors

    xor ax, ax
    mov ds, ax
    mov es, ax

    ; Bochs VBE 640x480x32
    mov dx, 0x01CE
    mov ax, 0x0000
    out dx, ax
    mov dx, 0x01CE
    mov ax, 0x0001
    out dx, ax
    mov dx, 0x01CF
    mov ax, 640
    out dx, ax
    mov dx, 0x01CE
    mov ax, 0x0002
    out dx, ax
    mov dx, 0x01CF
    mov ax, 480
    out dx, ax
    mov dx, 0x01CE
    mov ax, 0x0003
    out dx, ax
    mov dx, 0x01CF
    mov ax, 32
    out dx, ax
    mov dx, 0x01CE
    mov ax, 0x0004
    out dx, ax
    mov dx, 0x01CF
    mov ax, 0x0041
    out dx, ax

    cli
    lgdt [gdt_descriptor]
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp 0x08:kernel_entry

read_sectors:
    pusha
    mov [dap_count], cx
    mov [dap_offset], di
    mov [dap_segment], es
    mov [dap_lba], esi
    mov dword [dap_lba + 4], 0
    mov ah, 0x42
    mov dl, [boot_drive]
    mov si, dap_packet
    int 0x13
    jc .fail
    popa
    ret
.fail:
    popa
    jmp boot_error

boot_error:
    mov si, boot_error_msg
.print:
    lodsb
    test al, al
    jz .halt
    mov ah, 0x0E
    mov bh, 0
    int 0x10
    jmp .print
.halt:
    cli
    hlt
    jmp .halt

boot_drive:     db 0
boot_error_msg: db 'TeenyOS boot error',0

dap_packet:
    db 0x10
    db 0
dap_count:   dw 0
dap_offset:  dw 0
dap_segment: dw 0
dap_lba:     dq 0

gdt_start:
    dq 0
    dw 0xFFFF, 0x0000, 0x9A00, 0x00CF
    dw 0xFFFF, 0x0000, 0x9200, 0x00CF
gdt_end:
gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

times 510-($-$$) db 0
dw 0xAA55

; =============================================================================
[BITS 32]

VGA            equ 0xFD000000
BACKBUF        equ 0x200000
SCREEN_W       equ 320
FONT_BASE      equ 0x5000
VGA_PALETTE_ADDR equ 0x5800
SCREEN_H       equ 200
SCREEN_SIZE    equ 320 * 200 * 4
WALLPAPER_RENDERED equ 0x400000
STACK_TOP      equ 0x70000
APP_STORAGE    equ 0x20000
APP_EXEC       equ 0x20000
CALL_TABLE     equ 0x6000
MAX_APPS       equ 8
HEADER_SIZE    equ 320
ICON_OFFSET    equ 64

FS_NAME_LEN    equ 16
FS_DATA_LEN    equ 256
MAX_FILES      equ 8

ATA_TEST_BUF   equ 0x40000
ATA_TEST_LBA   equ 1000
FS_HEADER_LBA  equ 500
FS_DATA_LBA    equ 501
FS_MAGIC       equ 0x54534654
FS_HEADER_BUF  equ 0x42000
FS_DATA_BUF    equ 0x44000

WALLPAPER_BUF      equ 0x30000
TEENY_USED_BYTES   equ (257*512) + 64000 + 64000 + (PAINT_W*PAINT_H) + (257*512) + 2048 + 3232 + 640
TEENY_USED_KB      equ TEENY_USED_BYTES / 1024
PAINT_BUF          equ 0x300000
PAINT_W            equ 240
PAINT_H            equ 120
WALLPAPER_LBA      equ 304
BACKUP_TOTAL_SECTORS equ 20480
BACKUP_HOUR_TICKS    equ 360000
BACKUP_BATCH         equ 4
WALLPAPER_SECTORS  equ 128
PREFS_MAGIC        equ 0x46524550   ; "PREF"
PREFS_SIZE         equ 64
PREFS_WP           equ 4
PREFS_CUR          equ 5
PREFS_USR          equ 6
PREFS_PWD          equ 22
PREFS_LOG          equ 38
COMPRESSED_BUF     equ 0x46000

COLOR_BLACK    equ 0x000000
PCI_CONFIG_ADDR  equ 0xCF8
E1000_RAL        equ 0x5400
E1000_CTRL       equ 0x0000
E1000_STATUS     equ 0x0008
E1000_TCTL       equ 0x0400
E1000_TIPG       equ 0x0410
E1000_TDBAL      equ 0x3800
E1000_TDBAH      equ 0x3804
E1000_TDLEN      equ 0x3808
E1000_TDH        equ 0x3810
E1000_TDT        equ 0x3818
E1000_RCTL       equ 0x0100
E1000_RDBAL      equ 0x2800
E1000_RDBAH      equ 0x2804
E1000_RDLEN      equ 0x2808
E1000_RDH        equ 0x2810
E1000_RDT        equ 0x2818

E1000_RX_DESC_COUNT  equ 8
E1000_RX_DESC_SIZE   equ 16
E1000_RX_BUF_SIZE    equ 2048
E1000_RX_DESC_ADDR   equ 0x57000
E1000_RX_BUF_ADDR    equ 0x5C000

E1000_TX_DESC_COUNT  equ 8
E1000_TX_DESC_SIZE   equ 16
E1000_TX_BUF_SIZE    equ 2048

E1000_TX_DESC_ADDR   equ 0x56000
E1000_TX_BUF_ADDR    equ 0x58000
E1000_RAH        equ 0x5404
PCI_CONFIG_DATA  equ 0xCFC
WAV_LBA      equ 688
WAV_SECTORS  equ 128
WAV_BUF      equ 0x500000
SB16_BASE        equ 0x220
SB16_RESET       equ SB16_BASE + 0x6
SB16_READ        equ SB16_BASE + 0xA
SB16_WRITE       equ SB16_BASE + 0xC
SB16_READ_STATUS equ SB16_BASE + 0xE
SB16_INT_ACK     equ SB16_BASE + 0xF
COLOR_BLUE     equ 0x0000AA
COLOR_GREEN    equ 0x00AA00
COLOR_CYAN     equ 0x00AAAA
COLOR_RED      equ 0xAA0000
COLOR_MAGENTA  equ 0xAA00AA
COLOR_BROWN    equ 0xAA5500
COLOR_GRAY     equ 0xAAAAAA
COLOR_DGRAY    equ 0x555555
COLOR_LBLUE    equ 0x5555FF
COLOR_LGREEN   equ 0x55FF55
COLOR_LCYAN    equ 0x55FFFF
COLOR_LRED     equ 0xFF5555
COLOR_PINK     equ 0xFF55FF
COLOR_YELLOW   equ 0xFFFF55
COLOR_WHITE    equ 0xFFFFFF

APP_TERMINAL   equ 0
APP_FILES      equ 1
APP_BROWSER    equ 2
APP_ABOUT      equ 3
APP_NOTEPAD    equ 4
APP_INSTALLER  equ 5
APP_PAINT      equ 6
APP_CALC       equ 7
APP_SNAKE      equ 8
APP_SETTINGS   equ 9

MAX_WINDOWS    equ 10

WX             equ 0
WY             equ 4
WW             equ 8
WH             equ 12
WMODE          equ 16
WVIS           equ 20
WAW            equ 24
WAH            equ 28
ICON_GRID_X    equ 30
ICON_GRID_Y    equ 24
ICON_CELL_W    equ 75
ICON_CELL_H    equ 50
ICON_COLS      equ 4
ICON_ROWS      equ 4
ICON_SLOTS     equ 8

DRAG_MOVE      equ 0x10
DRAG_L         equ 0x01
DRAG_R         equ 0x02
DRAG_T         equ 0x04
DRAG_B         equ 0x08
PIC1_CMD   equ 0x20
PIC1_DATA  equ 0x21
PIC2_CMD   equ 0xA0
PIC2_DATA  equ 0xA1
PIT_CH0    equ 0x40
PIT_CMD    equ 0x43
PIT_FREQ   equ 100
WMIN_W         equ 100
WMIN_H         equ 60
TASKBAR_Y      equ 180

kernel_entry:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, STACK_TOP
    cld
    ; VBE test: red square
    mov edi, VGA
    mov ecx, 0
.xloop:
    mov ebx, 0
.yloop:
    mov eax, 0x00FF0000
    mov edx, ecx
    imul edx, SCREEN_W
    add edx, ebx
    shl edx, 2
    add edx, edi
    mov [edx], eax
    inc ebx
    cmp ebx, 100
    jl .yloop
    inc ecx
    cmp ecx, 100
    jl .xloop
    mov byte [dirty], 1
    mov byte [start_open], 0
    mov byte [shift_down], 0
    mov byte [np_ctrl_down], 0
    mov byte [np_menu_open], 0
    mov byte [np_saveas_mode], 0
    mov dword [inst_tick], 0
    mov dword [top_win], 0
    mov dword [drag_mode], 0
    mov dword [drag_win], 0

    call clip_reset
    call windows_init
    mov dword [win_focus_time + 0], 0xFFFFFFFF
    call setup_call_table

    mov dword [mouse_x], 156
    mov dword [mouse_y], 92
    mov byte [mouse_enabled], 0
    mov byte [mouse_packet_pos], 0
    mov byte [mouse_buttons], 0

    call terminal_clear
    mov byte [quiet], 0
    mov esi, str_sb16_ok
    call terminal_append
    call terminal_newline
    mov byte [quiet], 1
    call pci_scan
    call e1000_read_mac
    call e1000_print_mac
    call e1000_reset
    call e1000_tx_init
    call e1000_send_test
    call e1000_rx_init

    ; SB16 test — only this line shows
    mov byte [quiet], 0
    call sb16_reset
    test eax, eax
    jnz .sb16_fail
    mov esi, str_sb16_ok
    call terminal_append
    call terminal_newline
    jmp .sb16_done
.sb16_fail:
    mov esi, str_sb16_fail
    call terminal_append
    call terminal_newline
.sb16_done:
    mov byte [quiet], 1

    ; --- RX register dump ---
    mov esi, str_empty
    call terminal_append
    mov eax, E1000_RCTL
    call e1000_read
    push eax
    mov esi, str_eq
    call terminal_append
    pop eax
    call pci_print_hex32
    call terminal_newline

    mov esi, str_empty
    call terminal_append
    mov eax, E1000_RDBAL
    call e1000_read
    push eax
    mov esi, str_eq
    call terminal_append
    pop eax
    call pci_print_hex32
    call terminal_newline

    mov esi, str_empty
    call terminal_append
    mov eax, E1000_RDLEN
    call e1000_read
    push eax
    mov esi, str_eq
    call terminal_append
    pop eax
    call pci_print_hex32
    call terminal_newline

    mov esi, str_empty
    call terminal_append
    mov eax, E1000_RDH
    call e1000_read
    push eax
    mov esi, str_eq
    call terminal_append
    pop eax
    call pci_print_hex32
    call terminal_newline

    mov esi, str_empty
    call terminal_append
    mov eax, E1000_RDT
    call e1000_read
    push eax
    mov esi, str_eq
    call terminal_append
    pop eax
    call pci_print_hex32
    call terminal_newline

    call e1000_send_arp



    ; Wait up to ~1 sec for the ARP reply to arrive
    mov ecx, 0x6400000
.arp_wait:
    call e1000_rx_poll
    cmp byte [arp_reply_mac], 0
    jne .arp_ready
    loop .arp_wait
.arp_ready:


    mov edi, PAINT_BUF
    mov ecx, PAINT_W * PAINT_H
    mov al, 0x0F
    rep stosb
    call notepad_init
    call scan_apps
    call mouse_init
    call uart_init
    call load_wallpaper

    call setup_idt
    call setup_pic
    call setup_pit
    sti
    mov byte [quiet], 0
    call play_boot_sound
    call login_screen

    jmp main_loop
; Called when it's time to start a fresh backup.
; Does NOT copy anything — just arms the incremental process.
backup_start:
    pushad
    cmp byte [backup_failed], 0
    jne .skip
    cmp byte [backup_active], 0
    jne .skip
    mov dword [backup_sector], 0
    mov byte [backup_active], 1
.skip:
    popad
    ret

; Called every frame from main_loop.
; Copies BACKUP_BATCH sectors and returns.
backup_step:
    pushad
    cmp byte [backup_active], 0
    je .done
    cmp byte [backup_failed], 0
    jne .done

    mov ecx, BACKUP_BATCH
.batch_loop:
    ; Done?
    mov eax, [backup_sector]
    cmp eax, BACKUP_TOTAL_SECTORS
    jae .batch_done

    ; Read from master
    mov byte [ata_drive], 0xE0
    mov esi, [backup_sector]
    mov edi, ATA_TEST_BUF
    call ata_read_sector
    jc .fail

    ; Write to slave
    mov byte [ata_drive], 0xF0
    mov esi, [backup_sector]
    mov edi, ATA_TEST_BUF
    call ata_write_sector
    jc .fail

    ; Restore master as default
    mov byte [ata_drive], 0xE0

    inc dword [backup_sector]
    dec ecx
    jnz .batch_loop

.batch_done:
    ; Whole disk done?
    mov eax, [backup_sector]
    cmp eax, BACKUP_TOTAL_SECTORS
    jb .still_going
    mov byte [backup_active], 0
.still_going:
    popad
    ret

.fail:
    mov byte [ata_drive], 0xE0
    mov byte [backup_active], 0
    mov byte [backup_failed], 1
    popad
    ret

.done:
    popad
    ret
; EAX = window ptr. Resets app state when a window is fully closed.
window_close_reset:
    pushad
    mov ebx, [eax + WMODE]

    cmp ebx, APP_TERMINAL
    jne .cr_notepad
    call terminal_clear
    mov esi, str_sb16_ok
    call terminal_append
    call terminal_newline
    mov dword [input_len], 0
    mov byte [input_buf], 0
    jmp .done

.cr_notepad:
    cmp ebx, APP_NOTEPAD
    jne .cr_paint
    mov dword [notepad_len], 0
    mov byte [notepad_buf], 0
    mov byte [notepad_saved], 0
    mov byte [np_menu_open], 0
    mov byte [np_saveas_mode], 0
    mov dword [np_saveas_len], 0
    mov edi, np_filename
    mov ecx, 16
    xor eax, eax
    rep stosb
    mov edi, np_filename
    mov esi, str_note_filename
    mov ecx, 9
    rep movsb
    jmp .done

.cr_paint:
    cmp ebx, APP_PAINT
    jne .done
    mov edi, PAINT_BUF
    mov ecx, PAINT_W * PAINT_H
    mov al, COLOR_WHITE
    rep stosb
    mov dword [paint_curr_color], 0
    mov byte [paint_drawing], 0

.done:
    popad
    ret
; =============================================================
; LOGIN SCREEN
; =============================================================

login_screen:
    cmp byte [prefs_blob + PREFS_LOG], 0
    je .skip
    cmp byte [prefs_blob + PREFS_USR], 0
    je .skip
    cmp byte [prefs_blob + PREFS_PWD], 0
    je .skip
.drain_all:
    in al, 0x64
    test al, 1
    jz .restart
    in al, 0x60
    jmp .drain_all


.restart:
    mov dword [login_user_len], 0
    mov dword [login_pass_len], 0
    mov byte [login_user_buf], 0
    mov byte [login_pass_buf], 0
    mov byte [login_stage], 0
    call login_draw

.loop:
    in al, 0x64
    test al, 1
    jz .loop
    test al, 0x20
    jnz .mouse_byte
    in al, 0x60
    test al, 0x80
    jnz .loop
    jmp .process
.mouse_byte:
    in al, 0x60
    jmp .loop
.process:

    cmp al, 0x1C
    je .enter
    cmp al, 0x0E
    je .backspace
    cmp al, 0x01
    je .skip

    call scancode_to_ascii
    test al, al
    jz .loop

    cmp byte [login_stage], 0
    jne .add_pass

    mov ecx, [login_user_len]
    cmp ecx, 15
    jae .loop
    mov [login_user_buf + ecx], al
    inc ecx
    mov [login_user_len], ecx
    mov byte [login_user_buf + ecx], 0
    call login_draw
    jmp .loop

.add_pass:
    mov ecx, [login_pass_len]
    cmp ecx, 15
    jae .loop
    mov [login_pass_buf + ecx], al
    inc ecx
    mov [login_pass_len], ecx
    mov byte [login_pass_buf + ecx], 0
    call login_draw
    jmp .loop

.backspace:
    cmp byte [login_stage], 0
    jne .bs_pass
    mov ecx, [login_user_len]
    test ecx, ecx
    jz .loop
    dec ecx
    mov [login_user_len], ecx
    mov byte [login_user_buf + ecx], 0
    call login_draw
    jmp .loop
.bs_pass:
    mov ecx, [login_pass_len]
    test ecx, ecx
    jz .loop
    dec ecx
    mov [login_pass_len], ecx
    mov byte [login_pass_buf + ecx], 0
    call login_draw
    jmp .loop

.enter:
    cmp byte [login_stage], 0
    jne .verify
    mov byte [login_stage], 1
    call login_draw
    jmp .loop

.verify:
    mov esi, login_user_buf
    mov edi, prefs_blob + PREFS_USR
    call streq
    test eax, eax
    jnz .wrong
    mov esi, login_pass_buf
    mov edi, prefs_blob + PREFS_PWD
    call streq
    test eax, eax
    jnz .wrong
    ret

.wrong:
    mov byte [login_stage], 2
    call login_draw
    mov ecx, 0x2000000
.pause:
    dec ecx
    jnz .pause
    jmp .restart

.skip:
    ret

login_draw:
    call clip_reset

    xor eax, eax
    xor ebx, ebx
    mov ecx, 320
    mov edx, 200
    mov esi, COLOR_CYAN
    call draw_rect

    mov esi, str_login_title
    mov edi, 132
    mov edx, 40
    mov ebx, COLOR_WHITE
    call draw_text

    mov esi, str_login_user
    mov edi, 60
    mov edx, 80
    mov ebx, COLOR_BLACK
    call draw_text

    mov eax, 60
    mov ebx, 94
    mov ecx, 200
    mov edx, 14
    mov esi, COLOR_WHITE
    call draw_rect

    mov esi, login_user_buf
    mov edi, 64
    mov edx, 97
    mov ebx, COLOR_BLACK
    call draw_text

    cmp byte [login_stage], 0
    jne .no_u_cur
    mov eax, [login_user_len]
    shl eax, 3
    add eax, 64
    mov [text_x], eax
    mov dword [text_y], 97
    mov byte [glyph_char], '_'
    mov byte [text_color], COLOR_BLACK
    call draw_char
.no_u_cur:

    mov esi, str_login_pass
    mov edi, 60
    mov edx, 120
    mov ebx, COLOR_BLACK
    call draw_text

    mov eax, 60
    mov ebx, 134
    mov ecx, 200
    mov edx, 14
    mov esi, COLOR_WHITE
    call draw_rect

    mov ecx, [login_pass_len]
    xor ebp, ebp
.pw_loop:
    cmp ebp, ecx
    jae .pw_done
    mov eax, 64
    mov ebx, ebp
    shl ebx, 3
    add eax, ebx
    mov [text_x], eax
    mov dword [text_y], 137
    mov byte [glyph_char], '*'
    mov byte [text_color], COLOR_BLACK
    call draw_char
    inc ebp
    jmp .pw_loop
.pw_done:

    cmp byte [login_stage], 1
    jne .no_p_cur
    mov eax, [login_pass_len]
    shl eax, 3
    add eax, 64
    mov [text_x], eax
    mov dword [text_y], 137
    mov byte [glyph_char], '_'
    mov byte [text_color], COLOR_BLACK
    call draw_char
.no_p_cur:

    mov esi, str_login_enter
    mov edi, 80
    mov edx, 175
    mov ebx, COLOR_BLACK
    call draw_text

    cmp byte [login_stage], 2
    jne .no_err
    mov esi, str_login_wrong
    mov edi, 40
    mov edx, 158
    mov ebx, COLOR_RED
    call draw_text
.no_err:

    call blit_screen
    ret

main_loop:
    call mouse_poll
    call keyboard_poll


    ; Smooth X
    mov eax, [mouse_x]
    sub eax, [mouse_smooth_x]
    test eax, eax
    jz .sx_done
    cmp eax, 2
    jge .sx_halve
    cmp eax, -2
    jle .sx_halve
    mov eax, [mouse_x]
    mov [mouse_smooth_x], eax
    jmp .sx_done
.sx_halve:
    sar eax, 1
    add [mouse_smooth_x], eax
.sx_done:

    ; Smooth Y
    mov eax, [mouse_y]
    sub eax, [mouse_smooth_y]
    test eax, eax
    jz .sy_done
    cmp eax, 2
    jge .sy_halve
    cmp eax, -2
    jle .sy_halve
    mov eax, [mouse_y]
    mov [mouse_smooth_y], eax
    jmp .sy_done
.sy_halve:
    sar eax, 1
    add [mouse_smooth_y], eax
.sy_done:
        ; --- Shutdown submenu hover + animation ---
    mov byte [sm_sub_hover], 0
    cmp byte [start_open], 1
    jne .sm_sub_check

    ; Over the Shutdown row?
    cmp dword [mouse_x], 2
    jl .sm_sub_check2
    cmp dword [mouse_x], 136
    jg .sm_sub_check2
    cmp dword [mouse_y], 154
    jl .sm_sub_check2
    cmp dword [mouse_y], 176
    jg .sm_sub_check2
    mov byte [sm_sub_hover], 1
    jmp .sm_sub_check

.sm_sub_check2:
    ; Over the submenu itself?
    cmp dword [mouse_x], 136
    jl .sm_sub_check
    cmp dword [mouse_x], 216
    jg .sm_sub_check
    cmp dword [mouse_y], 144
    jl .sm_sub_check
    cmp dword [mouse_y], 178
    jg .sm_sub_check
    mov byte [sm_sub_hover], 1

.sm_sub_check:
    cmp byte [sm_sub_hover], 1
    jne .sm_sub_collapse
    cmp dword [sm_sub_anim], 80
    jae .sm_sub_done
    add dword [sm_sub_anim], 8
    cmp dword [sm_sub_anim], 80
    jbe .sm_sub_delay
    mov dword [sm_sub_anim], 80
.sm_sub_delay:
    mov ecx, 0x300000
.sm_sub_d1:
    dec ecx
    jnz .sm_sub_d1
    mov byte [dirty], 1
    jmp .sm_sub_done
.sm_sub_collapse:
    cmp dword [sm_sub_anim], 0
    je .sm_sub_done
    sub dword [sm_sub_anim], 8
    cmp dword [sm_sub_anim], 0
    jge .sm_sub_delay2
    mov dword [sm_sub_anim], 0
.sm_sub_delay2:
    mov ecx, 0x300000
.sm_sub_d2:
    dec ecx
    jnz .sm_sub_d2
    mov byte [dirty], 1
.sm_sub_done:

    ; --- Start menu animation ---
    cmp byte [start_open], 1
    jne .menu_down
    cmp dword [start_anim_w], 116
    jae .menu_ready
    mov ecx, 0x600000
.smu_d:
    dec ecx
    jnz .smu_d
    add dword [start_anim_w], 8
    cmp dword [start_anim_w], 116
    jbe .do_redraw
    mov dword [start_anim_w], 116
    jmp .do_redraw
.menu_down:
    cmp dword [start_anim_w], 0
    je .menu_ready
    mov ecx, 0x600000
.smd_d:
    dec ecx
    jnz .smd_d
    sub dword [start_anim_w], 8
    cmp dword [start_anim_w], 0
    jge .do_redraw
    mov dword [start_anim_w], 0
    jmp .do_redraw
.menu_ready:

    ; --- Window open animation ---
    xor ebp, ebp
    xor ecx, ecx
.wa_loop:
    cmp ecx, MAX_WINDOWS
    jae .wa_done
    mov ebx, ecx
    call win_ptr
    cmp dword [eax + WVIS], 1
    jne .wa_next
    mov edx, [eax + WAW]
    cmp edx, [eax + WW]
    jae .wa_check_h
    add dword [eax + WAW], 8
    mov edx, [eax + WAW]
    cmp edx, [eax + WW]
    jbe .wa_mark
    mov edx, [eax + WW]
    mov [eax + WAW], edx
.wa_mark:
    mov byte [dirty], 1
    inc ebp
.wa_check_h:
    mov edx, [eax + WAH]
    cmp edx, [eax + WH]
    jae .wa_next
    add dword [eax + WAH], 6
    mov edx, [eax + WAH]
    cmp edx, [eax + WH]
    jbe .wa_mark2
    mov edx, [eax + WH]
    mov [eax + WAH], edx
.wa_mark2:
    mov byte [dirty], 1
    inc ebp
.wa_next:
    inc ecx
    jmp .wa_loop
.wa_done:
    test ebp, ebp
    jz .no_wa_delay
    mov ecx, 0x500000
.wa_dl:
    dec ecx
    jnz .wa_dl
.no_wa_delay:

    ; --- Window close animation ---
    xor ebp, ebp
    xor ecx, ecx
.wc_loop:
    cmp ecx, MAX_WINDOWS
    jae .wc_done
    mov ebx, ecx
    call win_ptr
    cmp dword [eax + WVIS], 2
    jne .wc_next
    cmp dword [eax + WAW], 0
    je .wc_zero_h
    sub dword [eax + WAW], 8
    cmp dword [eax + WAW], 0
    jge .wc_mark
    mov dword [eax + WAW], 0
.wc_mark:
    mov byte [dirty], 1
    inc ebp
.wc_zero_h:
    cmp dword [eax + WAH], 0
    je .wc_finish
    sub dword [eax + WAH], 6
    cmp dword [eax + WAH], 0
    jge .wc_mark2
    mov dword [eax + WAH], 0
.wc_mark2:
    mov byte [dirty], 1
    inc ebp
    jmp .wc_next
.wc_finish:
    mov dword [eax + WVIS], 0
    call window_close_reset
    mov byte [dirty], 1
    inc ebp
.wc_next:
    inc ecx
    jmp .wc_loop
.wc_done:
    test ebp, ebp
    jz .no_wc_delay
    mov ecx, 0x500000
.wc_dl:
    dec ecx
    jnz .wc_dl
.no_wc_delay:

.no_wm_delay:
    ; --- CLI installer step ---
    cmp byte [cli_active], 0
    je .cli_step_done
    cmp byte [cli_screen], 3
    jne .cli_step_done
    call cli_install_step
.cli_step_done:
    ; --- Silent background disk backup ---
    call backup_step

    ; --- Hourly backup trigger ---
    cmp byte [backup_failed], 0
    jne .no_hourly
    mov eax, [pit_ticks]
    sub eax, [backup_last_tick]
    cmp eax, BACKUP_HOUR_TICKS
    jb .no_hourly
    mov eax, [pit_ticks]
    mov [backup_last_tick], eax
    call backup_start
.no_hourly:

    ; --- Titlebar fade tick ---

    ; If any window's fade is in progress, mark dirty
    xor ecx, ecx
.fade_chk:
    cmp ecx, MAX_WINDOWS
    jae .fade_done
    movzx eax, byte [win_order + ecx]
    cmp eax, [top_win]
    je .fade_next
    mov eax, [win_focus_time + eax*4]
    mov ebx, [pit_ticks]
    sub ebx, eax
    cmp ebx, 20000
    jae .fade_next
    mov byte [dirty], 1
    jmp .fade_done
.fade_next:
    inc ecx
    jmp .fade_chk
.fade_done:

    ; --- Snap preview tick ---
    ; --- Snap preview tick ---
    mov byte [snap_preview], 0
    mov ecx, [drag_mode]
    test ecx, DRAG_MOVE
    jz .snap_prev_done

    ; Corner zones first (70x70 boxes) - check corners before edges
    ; Top-left: x < 70, y < 70
    mov eax, [mouse_x]
    cmp eax, 70
    jge .sp_ck_tr
    mov eax, [mouse_y]
    cmp eax, 70
    jge .sp_ck_tr
    mov byte [snap_preview], 4
    jmp .snap_prev_done
.sp_ck_tr:
    ; Top-right: x > 250, y < 70
    mov eax, [mouse_x]
    cmp eax, 250
    jl .sp_ck_bl
    mov eax, [mouse_y]
    cmp eax, 70
    jge .sp_ck_bl
    mov byte [snap_preview], 5
    jmp .snap_prev_done
.sp_ck_bl:
    ; Bottom-left: x < 70, y > 130
    mov eax, [mouse_x]
    cmp eax, 70
    jge .sp_ck_br
    mov eax, [mouse_y]
    cmp eax, 130
    jl .sp_ck_br
    mov byte [snap_preview], 6
    jmp .snap_prev_done
.sp_ck_br:
    ; Bottom-right: x > 250, y > 130
    mov eax, [mouse_x]
    cmp eax, 250
    jl .sp_ck_edges
    mov eax, [mouse_y]
    cmp eax, 130
    jl .sp_ck_edges
    mov byte [snap_preview], 7
    jmp .snap_prev_done

.sp_ck_edges:
    ; Edge zones (12px bands)
    ; Top edge -> maximize
    mov eax, [mouse_y]
    cmp eax, 12
    jge .sp_ck_left
    mov byte [snap_preview], 1
    jmp .snap_prev_done
.sp_ck_left:
    ; Left edge -> left half
    mov eax, [mouse_x]
    cmp eax, 12
    jge .sp_ck_right
    mov byte [snap_preview], 2
    jmp .snap_prev_done
.sp_ck_right:
    ; Right edge -> right half
    mov eax, [mouse_x]
    cmp eax, 308
    jle .snap_prev_done
    mov byte [snap_preview], 3
.snap_prev_done:

    ; --- Snake game tick ---
    cmp byte [snake_started], 0
    je .snake_tick_done
    cmp byte [snake_paused], 1
    je .snake_tick_done
    cmp byte [snake_dead], 1
    je .snake_tick_done
    mov eax, [pit_ticks]
    sub eax, [snake_last_move]
    cmp eax, [snake_speed]
    jb .snake_tick_done
    mov eax, [pit_ticks]
    mov [snake_last_move], eax
    call snake_step
.snake_tick_done:

    ; --- Cursor blink tick ---
    mov eax, [pit_ticks]
    sub eax, [blink_last]
    cmp eax, 50
    jb .blink_done
    mov eax, [pit_ticks]
    mov [blink_last], eax
    xor byte [cursor_on], 1
    mov byte [dirty], 1
.blink_done:


    ; Redraw if dirty OR cursor still moving
    cmp byte [dirty], 0
    jne .do_redraw
    mov eax, [mouse_smooth_x]
    cmp eax, [mouse_x]
    jne .do_redraw
    mov eax, [mouse_smooth_y]
    cmp eax, [mouse_y]
    jne .do_redraw
    jmp main_loop

.do_redraw:
    mov byte [dirty], 0
    call redraw_all
    call blit_screen
    jmp main_loop
	
	; =============================================================
; PREFS
; =============================================================

load_prefs:
    mov esi, str_empty
    call terminal_append
    call terminal_newline
    pushad
    mov esi, str_empty
    call terminal_append
    movzx eax, byte [prefs_blob + PREFS_WP]
    mov edi, ram_str_buf
    call format_u32
    mov esi, ram_str_buf
    call terminal_append
    call terminal_newline
    mov edi, prefs_blob
    mov ecx, 64
    xor eax, eax
    rep stosb
    mov dword [prefs_blob], PREFS_MAGIC
    mov byte [prefs_blob + PREFS_WP], 0
    mov byte [prefs_blob + PREFS_CUR], 15
    mov byte [prefs_blob + PREFS_LOG], 0

    mov esi, str_prefs_filename
    mov edi, prefs_temp
    call fs_read
    test eax, eax
    js .apply

    mov eax, [prefs_temp]
    cmp eax, PREFS_MAGIC
    jne .apply

    mov esi, prefs_temp
    mov edi, prefs_blob
    mov ecx, 64
    rep movsb

.apply:
    movzx eax, byte [prefs_blob + PREFS_WP]
    cmp eax, 3
    jb .wp_ok
    xor eax, eax
    mov [prefs_blob + PREFS_WP], al
.wp_ok:
    imul eax, WALLPAPER_SECTORS
    add eax, WALLPAPER_LBA
    mov [wallpaper_lba], eax
    mov esi, str_empty
    call terminal_append
    movzx eax, byte [prefs_blob + PREFS_WP]
    mov edi, ram_str_buf
    call format_u32
    mov esi, ram_str_buf
    call terminal_append
    call terminal_newline
    popad
    ret

save_prefs:
    mov esi, str_empty
    call terminal_append
    call terminal_newline
    mov esi, str_empty
    call terminal_append
    call terminal_newline
    pushad
    mov dword [prefs_blob], PREFS_MAGIC
    mov esi, str_prefs_filename
    mov edi, prefs_blob
    mov ecx, PREFS_SIZE
    call fs_write
    popad
    ret

; AL = wallpaper index 0-2
set_wallpaper:
    pushad
    cmp al, 3
    jae .done
    mov [prefs_blob + PREFS_WP], al
    movzx eax, al
    imul eax, WALLPAPER_SECTORS
    add eax, WALLPAPER_LBA
    mov [wallpaper_lba], eax
    call load_wallpaper
    call save_prefs
    mov byte [dirty], 1
.done:
    popad
    ret

; AL = cursor color 0-15
set_cursor_color:
    pushad
    cmp al, 16
    jae .done
    mov [prefs_blob + PREFS_CUR], al
    call save_prefs
    mov byte [dirty], 1
.done:
    popad
    ret

; =============================================================================
installer_fullscreen:
    call clip_reset

.loop:
    call installer_full_draw
    call draw_cursor
    call blit_screen

    cmp byte [inst_stage], 0
    je .prompt

    cmp byte [inst_stage], 100
    jae .finish

    jmp .loop

.prompt:
    call installer_poll_mouse
    test al, al
    jz .loop
    cmp al, 1
    je .yes
    cmp al, 2
    je .no
    jmp .loop

.yes:
    mov byte [inst_stage], 1
    call installer_full_draw
    call draw_cursor
    call blit_screen
    call install_write
    jmp .loop

.no:
    call do_shutdown
    jmp .no

.finish:
    call installer_poll_mouse
    test al, al
    jz .loop
    mov byte [inst_stage], 5
    call install_save
    call do_reboot
    jmp .loop

installer_full_draw:
    call clip_reset
    mov eax, 0
    mov ebx, 0
    mov ecx, 320
    mov edx, 200
    mov esi, COLOR_BLUE
    call draw_rect
    mov esi, str_inst_logo
    mov edi, 128
    mov edx, 26
    mov ebx, COLOR_LGREEN
    call draw_text
    mov esi, str_inst_sub
    mov edi, 140
    mov edx, 44
    mov ebx, COLOR_LCYAN
    call draw_text
    cmp byte [inst_stage], 0
    je .confirm
    cmp byte [inst_stage], 100
    jae .finished
    mov esi, str_inst_wait
    mov edi, 116
    mov edx, 86
    mov ebx, COLOR_WHITE
    call draw_text
    mov eax, 60
    mov ebx, 110
    mov ecx, 200
    mov edx, 16
    mov esi, COLOR_BLACK
    call draw_rect
    movzx eax, byte [inst_stage]
    cmp eax, 100
    jbe .prog_ok
    mov eax, 100
.prog_ok:
    imul eax, 2
    mov ecx, eax
    mov eax, 61
    mov ebx, 111
    mov edx, 14
    mov esi, COLOR_LGREEN
    call draw_rect
    mov esi, str_inst_do_not_power
    mov edi, 90
    mov edx, 145
    mov ebx, COLOR_GRAY
    call draw_text
    ret
.confirm:
    mov esi, str_inst_confirm
    mov edi, 26
    mov edx, 90
    mov ebx, COLOR_WHITE
    call draw_text
    mov eax, 80
    mov ebx, 110
    mov ecx, 60
    mov edx, 22
    mov esi, COLOR_LGREEN
    call draw_rect
    mov esi, str_inst_yes
    mov edi, 102
    mov edx, 117
    mov ebx, COLOR_BLACK
    call draw_text
    mov eax, 180
    mov ebx, 110
    mov ecx, 60
    mov edx, 22
    mov esi, COLOR_RED
    call draw_rect
    mov esi, str_inst_no
    mov edi, 205
    mov edx, 117
    mov ebx, COLOR_WHITE
    call draw_text
    ret
.finished:
    mov esi, str_inst_done
    mov edi, 128
    mov edx, 86
    mov ebx, COLOR_LGREEN
    call draw_text
    mov esi, str_inst_press_key
    mov edi, 60
    mov edx, 130
    mov ebx, COLOR_WHITE
    call draw_text
    ret
; Copy the OS image from source disk (master) to target disk (slave).
install_write:
    pushad
    mov dword [inst_src], 0

.loop:
    cmp dword [inst_src], 340
    jae .done

    mov byte [ata_drive], 0xA0
    mov esi, [inst_src]
    mov edi, 0x48000
    call ata_read_sector
    jc .fail

    mov byte [ata_drive], 0xB0
    mov esi, [inst_src]
    mov edi, 0x48000
    call ata_write_sector
    jc .fail

    mov eax, [inst_src]
    xor edx, edx
    mov ecx, 3
    div ecx
    mov [inst_stage], al

    call installer_full_draw
    call draw_cursor
    call blit_screen

    inc dword [inst_src]
    jmp .loop

.done:
    mov byte [inst_stage], 100
    mov byte [ata_drive], 0xA0
    popad
    ret

.fail:
    mov byte [inst_stage], 0
    mov byte [ata_drive], 0xA0
    popad
    ret

installer_poll_mouse:
    pushad
    mov byte [poll_result], 0
.read:
    in al, 0x64
    test al, 1
    jz .done
    test al, 0x20
    jz .done
    in al, 0x60
    cmp byte [mouse_packet_pos], 0
    jne .b1
    test al, 8
    jz .read
    mov [mouse_packet], al
    mov byte [mouse_packet_pos], 1
    jmp .read
.b1:
    cmp byte [mouse_packet_pos], 1
    jne .b2
    mov [mouse_packet+1], al
    mov byte [mouse_packet_pos], 2
    jmp .read
.b2:
    mov [mouse_packet+2], al
    mov byte [mouse_packet_pos], 0
    mov al, [mouse_packet]
    test al, 0x40
    jnz .done
    test al, 0x80
    jnz .done
    movsx eax, byte [mouse_packet+1]
    add [mouse_x], eax
    cmp dword [mouse_x], 0
    jge .x1
    mov dword [mouse_x], 0
.x1:
    cmp dword [mouse_x], 312
    jle .x2
    mov dword [mouse_x], 312
.x2:
    movsx eax, byte [mouse_packet+2]
    sub [mouse_y], eax
    cmp dword [mouse_y], 0
    jge .y1
    mov dword [mouse_y], 0
.y1:
    cmp dword [mouse_y], 189
    jle .y2
    mov dword [mouse_y], 189
.y2:
    mov al, [mouse_packet]
    and al, 1
    mov bl, [mouse_buttons]
    mov [mouse_buttons], al
    cmp al, bl
    je .done
    test al, 1
    jz .done
    cmp byte [inst_stage], 0
    jne .finish_click
    cmp dword [mouse_x], 80
    jl .no_chk
    cmp dword [mouse_x], 140
    jg .no_chk
    cmp dword [mouse_y], 110
    jl .no_chk
    cmp dword [mouse_y], 132
    jg .no_chk
    mov byte [poll_result], 1
    jmp .done
.no_chk:
    cmp dword [mouse_x], 180
    jl .done
    cmp dword [mouse_x], 240
    jg .done
    cmp dword [mouse_y], 110
    jl .done
    cmp dword [mouse_y], 132
    jg .done
    mov byte [poll_result], 2
    jmp .done
.finish_click:
    mov byte [poll_result], 1
.done:
    popad
    mov al, [poll_result]
    mov byte [poll_result], 0
    ret

install_check:
    pushad
    mov esi, str_inst_filename
    mov edi, install_buf
    call fs_read
    test eax, eax
    js .no_file
    mov al, [install_buf]
    mov [inst_stage], al
    popad
    ret
.no_file:
    mov byte [inst_stage], 0
    popad
    ret

install_save:
    pushad
    mov al, [inst_stage]
    mov [install_buf], al
    mov esi, str_inst_filename
    mov edi, install_buf
    mov ecx, 1
    call fs_write
    popad
    ret

do_reboot:
    call backup_start
.wait_bk:
    cmp byte [backup_active], 0
    je .go
    cmp byte [backup_failed], 0
    jne .go
    call backup_step
    jmp .wait_bk
.go:
    cli

    ; Keyboard controller reset
    mov dx, 0x64
    mov al, 0xFE
    out dx, al

    ; Chipset reset (QEMU honors this)
    mov dx, 0xCF9
    mov al, 0x06
    out dx, al

    ; Triple-fault as last resort
    lidt [null_idt]
    int 0
    hlt
    jmp do_reboot

null_idt:
    dw 0
    dd 0

do_shutdown:
    call backup_start
.wait_bk:
    cmp byte [backup_active], 0
    je .go
    cmp byte [backup_failed], 0
    jne .go
    call backup_step
    jmp .wait_bk
.go:
    mov dx, 0x604
    mov ax, 0x2000
    out dx, ax
    cli
    hlt
    jmp do_shutdown
do_sleep:
    mov byte [start_open], 0
    mov byte [sm_sub_anim], 0
    call backup_start
.wait_bk:
    cmp byte [backup_active], 0
    je .go
    cmp byte [backup_failed], 0
    jne .go
    call backup_step
    jmp .wait_bk
.go:

.drain:
    in al, 0x64
    test al, 1
    jz .draw
    in al, 0x60
    jmp .drain

.draw:
    call clip_reset
    mov eax, 0
    mov ebx, 0
    mov ecx, 320
    mov edx, 200
    mov esi, COLOR_BLACK
    call draw_rect
    mov esi, str_sleep_msg
    mov edi, 48
    mov edx, 94
    mov ebx, COLOR_GRAY
    call draw_text
    call blit_screen

.wait_key:
    in al, 0x64
    test al, 1
    jz .wait_key
    test al, 0x20
    jnz .eat_mouse
    in al, 0x60
    call clip_reset
    mov byte [dirty], 1
    ret

.eat_mouse:
    in al, 0x60
    jmp .wait_key

; =============================================================
; IDT / PIC / PIT
; =============================================================

idt_default:
    iret

irq0_handler:
    pushad
    inc dword [pit_ticks]
    mov al, 0x20
    out PIC1_CMD, al
    popad
    iret

setup_idt:
    pushad
    mov edi, idt_table
    mov ecx, 256
.fill:
    mov eax, idt_default
    mov [edi], ax
    shr eax, 16
    mov [edi+6], ax
    mov word [edi+2], 0x08
    mov byte [edi+4], 0
    mov byte [edi+5], 0x8E
    add edi, 8
    dec ecx
    jnz .fill

    ; Patch entry 0x20 (IRQ 0 after PIC remap)
    mov edi, idt_table + 0x20 * 8
    mov eax, irq0_handler
    mov [edi], ax
    shr eax, 16
    mov [edi+6], ax

    lidt [idt_descriptor]
    popad
    ret

setup_pic:
    pushad

    ; ICW1: initialize (edge-triggered, cascade)
    mov al, 0x11
    out PIC1_CMD, al
    out PIC2_CMD, al

    ; ICW2: vector offsets — remap 0-7 -> 0x20, 8-15 -> 0x28
    mov al, 0x20
    out PIC1_DATA, al
    mov al, 0x28
    out PIC2_DATA, al

    ; ICW3: cascade wiring
    mov al, 0x04
    out PIC1_DATA, al
    mov al, 0x02
    out PIC2_DATA, al

    ; ICW4: 8086 mode
    mov al, 0x01
    out PIC1_DATA, al
    out PIC2_DATA, al

    ; Mask everything except IRQ 0 on master, all on slave
    mov al, 0xFE
    out PIC1_DATA, al
    mov al, 0xFF
    out PIC2_DATA, al

    popad
    ret

setup_pit:
    pushad

    ; Channel 0, rate generator (mode 2), 16-bit binary
    mov al, 0x34
    out PIT_CMD, al

    ; Divisor = 1193182 / PIT_FREQ
    mov ax, 1193182 / PIT_FREQ
    out PIT_CH0, al
    mov al, ah
    out PIT_CH0, al

    popad
    ret
; =============================================================
; PCI ENUMERATION
; =============================================================

; EAX = bus/slot/func packed as (bus<<16)|(slot<<11)|(func<<8)|reg
; Returns EAX = config dword
pci_read_config:
    push edx
    or eax, 0x80000000
    mov dx, PCI_CONFIG_ADDR
    out dx, eax
    mov dx, PCI_CONFIG_DATA
    in eax, dx
    pop edx
    ret

; EAX = packed, EBX = value to write
pci_write_config:
    push eax
    push edx
    or eax, 0x80000000
    mov dx, PCI_CONFIG_ADDR
    out dx, eax
    mov dx, PCI_CONFIG_DATA
    mov eax, ebx
    out dx, eax
    pop edx
    pop eax
    ret
; IN: EAX = register offset. OUT: EAX = value.
e1000_read:
    push ebx
    mov ebx, [e1000_base]
    add ebx, eax
    mov eax, [ebx]
    pop ebx
    ret

; IN: EAX = offset, EBX = value.
e1000_write:
    push ecx
    mov ecx, [e1000_base]
    add ecx, eax
    mov [ecx], ebx
    pop ecx
    ret
e1000_read_mac:
    pushad
    cmp dword [e1000_base], 0
    je .done

    ; Read RAL (low 32 bits) and RAH (high 16 bits of MAC in RAH[15:0])
    mov eax, E1000_RAL
    call e1000_read
    mov ebx, eax

    mov eax, E1000_RAH
    call e1000_read
    ; Low 16 bits of RAH are MAC[5:4]

    ; MAC[0] = RAL[7:0]
    mov edx, ebx
    and edx, 0xFF
    mov [e1000_mac + 0], dl

    ; MAC[1] = RAL[15:8]
    mov edx, ebx
    shr edx, 8
    and edx, 0xFF
    mov [e1000_mac + 1], dl

    ; MAC[2] = RAL[23:16]
    mov edx, ebx
    shr edx, 16
    and edx, 0xFF
    mov [e1000_mac + 2], dl

    ; MAC[3] = RAL[31:24]
    mov edx, ebx
    shr edx, 24
    mov [e1000_mac + 3], dl

    ; MAC[4] = RAH[7:0]
    mov edx, eax
    and edx, 0xFF
    mov [e1000_mac + 4], dl

    ; MAC[5] = RAH[15:8]
    mov edx, eax
    shr edx, 8
    and edx, 0xFF
    mov [e1000_mac + 5], dl

.done:
    popad
    ret
; Reset the e1000 (write CTRL.RST, wait for it to self-clear)
e1000_reset:
    pushad
    cmp dword [e1000_base], 0
    je .done

    ; Read CTRL, set RST (bit 26)
    mov eax, E1000_CTRL
    call e1000_read
    mov ebx, eax
    or ebx, 0x04000000
    mov eax, E1000_CTRL
    call e1000_write

    ; Wait up to ~100 ms for RST to clear
    mov ecx, 0x100000
.wait:
    mov eax, E1000_CTRL
    call e1000_read
    test eax, 0x04000000
    jz .cleared
    loop .wait

.cleared:
    ; Set link up (CTRL.SLU bit 6)
    mov eax, E1000_CTRL
    call e1000_read
    mov ebx, eax
    or ebx, 0x40
    mov eax, E1000_CTRL
    call e1000_write

    mov esi, str_empty
    call terminal_append
    call terminal_newline
.done:
    popad
    ret

; Set up TX descriptor ring and enable transmitter
e1000_tx_init:
    pushad
    cmp dword [e1000_base], 0
    je .done

    ; Zero the descriptor ring (128 bytes)
    mov edi, E1000_TX_DESC_ADDR
    mov ecx, E1000_TX_DESC_COUNT * E1000_TX_DESC_SIZE / 4
    xor eax, eax
    rep stosd

    ; TDBAL/TDBAH = descriptor ring base
    mov eax, E1000_TDBAL
    mov ebx, E1000_TX_DESC_ADDR
    call e1000_write

    mov eax, E1000_TDBAH
    xor ebx, ebx
    call e1000_write

    ; TDLEN = 128 bytes
    mov eax, E1000_TDLEN
    mov ebx, E1000_TX_DESC_COUNT * E1000_TX_DESC_SIZE
    call e1000_write

    ; TDH = TDT = 0
    mov eax, E1000_TDH
    xor ebx, ebx
    call e1000_write
    mov eax, E1000_TDT
    xor ebx, ebx
    call e1000_write

    ; TCTL: EN=1, PSP=1, CT=0x10, COLD=0x40
    ; = 0x0004010A? No: EN=bit1, PSP=bit3, CT<<4, COLD<<12
    ; EN(2) + PSP(8) + 0x10<<4 + 0x40<<12 = 0x2 + 0x8 + 0x100 + 0x40000 = 0x04010A
    mov eax, E1000_TCTL
    mov ebx, 0x0004010A
    call e1000_write

    ; TIPG = 10, 8, 6 (IPGT, IPGR1, IPGR2)
    ; = 0x0060200A
    mov eax, E1000_TIPG
    mov ebx, 0x0060200A
    call e1000_write

    mov dword [e1000_tx_cur], 0

    mov esi, str_empty
    call terminal_append
    call terminal_newline
.done:
    popad
    ret
; Send an ARP request for 10.0.2.2
e1000_send_arp:
    pushad
    mov edi, E1000_TX_BUF_ADDR

    ; --- Ethernet header ---
    ; dst MAC: broadcast
    mov byte [edi + 0], 0xFF
    mov byte [edi + 1], 0xFF
    mov byte [edi + 2], 0xFF
    mov byte [edi + 3], 0xFF
    mov byte [edi + 4], 0xFF
    mov byte [edi + 5], 0xFF

    ; src MAC: ours
    movzx eax, byte [e1000_mac + 0]
    mov [edi + 6], al
    movzx eax, byte [e1000_mac + 1]
    mov [edi + 7], al
    movzx eax, byte [e1000_mac + 2]
    mov [edi + 8], al
    movzx eax, byte [e1000_mac + 3]
    mov [edi + 9], al
    movzx eax, byte [e1000_mac + 4]
    mov [edi + 10], al
    movzx eax, byte [e1000_mac + 5]
    mov [edi + 11], al

    ; EtherType = 0x0806 (ARP)
    mov byte [edi + 12], 0x08
    mov byte [edi + 13], 0x06

    ; --- ARP body ---
    ; Hardware type = 0x0001
    mov byte [edi + 14], 0x00
    mov byte [edi + 15], 0x01

    ; Protocol type = 0x0800
    mov byte [edi + 16], 0x08
    mov byte [edi + 17], 0x00

    ; HLEN = 6, PLEN = 4
    mov byte [edi + 18], 0x06
    mov byte [edi + 19], 0x04

    ; Opcode = 0x0001 (request)
    mov byte [edi + 20], 0x00
    mov byte [edi + 21], 0x01

    ; Sender MAC = ours
    movzx eax, byte [e1000_mac + 0]
    mov [edi + 22], al
    movzx eax, byte [e1000_mac + 1]
    mov [edi + 23], al
    movzx eax, byte [e1000_mac + 2]
    mov [edi + 24], al
    movzx eax, byte [e1000_mac + 3]
    mov [edi + 25], al
    movzx eax, byte [e1000_mac + 4]
    mov [edi + 26], al
    movzx eax, byte [e1000_mac + 5]
    mov [edi + 27], al

    ; Sender IP = 10.0.2.15
    mov byte [edi + 28], 10
    mov byte [edi + 29], 0
    mov byte [edi + 30], 2
    mov byte [edi + 31], 15

    ; Target MAC = zeros (unknown)
    mov byte [edi + 32], 0
    mov byte [edi + 33], 0
    mov byte [edi + 34], 0
    mov byte [edi + 35], 0
    mov byte [edi + 36], 0
    mov byte [edi + 37], 0

    ; Target IP = 10.0.2.2
    mov byte [edi + 38], 10
    mov byte [edi + 39], 0
    mov byte [edi + 40], 2
    mov byte [edi + 41], 2

    ; Pad to 60 bytes
    mov ecx, 18
    xor al, al
    add edi, 42
    rep stosb

    ; Send
    mov esi, E1000_TX_BUF_ADDR
    mov ebx, 60
    call e1000_send

    mov esi, str_empty
    call terminal_append
    call terminal_newline
    popad
    ret
; IN: ESI = buffer, ECX = length (even). OUT: AX = checksum.
ip_checksum:
    push ebx
    push esi
    push ecx
    xor eax, eax
.loop:
    test ecx, ecx
    jz .fold
    movzx ebx, word [esi]
    xchg bl, bh
    add eax, ebx
    add esi, 2
    sub ecx, 2
    jmp .loop
.fold:
    mov ebx, eax
    shr ebx, 16
    and eax, 0xFFFF
    add eax, ebx
    mov ebx, eax
    shr ebx, 16
    and eax, 0xFFFF
    add eax, ebx
    not eax
    and eax, 0xFFFF
    pop ecx
    pop esi
    pop ebx
    ret

; Parse "A.B.C.D" at ESI into 4 bytes at EDI. CF set on error.
parse_ip:
    push ebx
    push ecx
    push esi
    push edi
    xor ecx, ecx
.octet:
    cmp ecx, 4
    jae .done
    xor ebx, ebx
.digit:
    movzx eax, byte [esi]
    cmp al, '0'
    jb .sep
    cmp al, '9'
    ja .sep
    sub al, '0'
    imul ebx, 10
    movzx eax, al
    add ebx, eax
    inc esi
    jmp .digit
.sep:
    cmp ebx, 255
    ja .fail
    mov [edi + ecx], bl
    inc ecx
    cmp al, '.'
    jne .done
    inc esi
    jmp .octet
.done:
    cmp ecx, 4
    jne .fail
    pop edi
    pop esi
    pop ecx
    pop ebx
    clc
    ret
.fail:
    pop edi
    pop esi
    pop ecx
    pop ebx
    stc
    ret
cmd_ping_run:
    pushad

    cmp byte [arp_reply_mac], 0
    jne .have_gw
    mov esi, str_ping_nogw
    call terminal_append
    call terminal_newline
    popad
    ret
.have_gw:

    mov esi, input_buf + 5
    mov edi, ping_target_ip
    call parse_ip
    jc .bad_ip

    mov esi, str_ping_head
    call terminal_append
    xor ebp, ebp
.pr_octet1:
    cmp ebp, 4
    jae .pr_done1
    movzx eax, byte [ping_target_ip + ebp]
    mov edi, ram_str_buf
    call format_u32
    mov esi, ram_str_buf
    call terminal_append
    cmp ebp, 3
    je .pr_nod1
    mov esi, str_dot
    call terminal_append
.pr_nod1:
    inc ebp
    jmp .pr_octet1
.pr_done1:
    call terminal_newline

    ; --- Build Ethernet + IPv4 + ICMP at E1000_TX_BUF_ADDR ---
    mov edi, E1000_TX_BUF_ADDR

    ; Ethernet dst = gateway MAC
    movzx eax, byte [arp_reply_mac + 0]
    mov [edi + 0], al
    movzx eax, byte [arp_reply_mac + 1]
    mov [edi + 1], al
    movzx eax, byte [arp_reply_mac + 2]
    mov [edi + 2], al
    movzx eax, byte [arp_reply_mac + 3]
    mov [edi + 3], al
    movzx eax, byte [arp_reply_mac + 4]
    mov [edi + 4], al
    movzx eax, byte [arp_reply_mac + 5]
    mov [edi + 5], al

    ; Ethernet src = our MAC
    movzx eax, byte [e1000_mac + 0]
    mov [edi + 6], al
    movzx eax, byte [e1000_mac + 1]
    mov [edi + 7], al
    movzx eax, byte [e1000_mac + 2]
    mov [edi + 8], al
    movzx eax, byte [e1000_mac + 3]
    mov [edi + 9], al
    movzx eax, byte [e1000_mac + 4]
    mov [edi + 10], al
    movzx eax, byte [e1000_mac + 5]
    mov [edi + 11], al

    ; EtherType = 0x0800
    mov byte [edi + 12], 0x08
    mov byte [edi + 13], 0x00

    ; IPv4 header
    mov byte [edi + 14], 0x45
    mov byte [edi + 15], 0x00
    mov byte [edi + 16], 0x00
    mov byte [edi + 17], 0x1C
    mov byte [edi + 18], 0x00
    mov byte [edi + 19], 0x01
    mov byte [edi + 20], 0x00
    mov byte [edi + 21], 0x00
    mov byte [edi + 22], 0x40
    mov byte [edi + 23], 0x01
    mov byte [edi + 24], 0x00
    mov byte [edi + 25], 0x00
    mov byte [edi + 26], 10
    mov byte [edi + 27], 0
    mov byte [edi + 28], 2
    mov byte [edi + 29], 15
    movzx eax, byte [ping_target_ip + 0]
    mov [edi + 30], al
    movzx eax, byte [ping_target_ip + 1]
    mov [edi + 31], al
    movzx eax, byte [ping_target_ip + 2]
    mov [edi + 32], al
    movzx eax, byte [ping_target_ip + 3]
    mov [edi + 33], al

    lea esi, [edi + 14]
    mov ecx, 20
    call ip_checksum
    mov [edi + 24], ah
    mov [edi + 25], al

    ; ICMP echo request
    mov byte [edi + 34], 0x08
    mov byte [edi + 35], 0x00
    mov byte [edi + 36], 0x00
    mov byte [edi + 37], 0x00
    mov byte [edi + 38], 0x12
    mov byte [edi + 39], 0x34
    mov byte [edi + 40], 0x00
    mov byte [edi + 41], 0x01

    lea esi, [edi + 34]
    mov ecx, 8
    call ip_checksum
    mov [edi + 36], ah
    mov [edi + 37], al

    ; Send quietly
    mov byte [tx_quiet], 1
    mov esi, E1000_TX_BUF_ADDR
    mov ebx, 42
    call e1000_send
    mov byte [tx_quiet], 0

    ; Wait for reply
    mov dword [ping_received], 0
    mov dword [ping_counter], 0
    call e1000_ping_wait

    cmp dword [ping_received], 0
    jne .done
    mov esi, str_ping_timeout
    call terminal_append
    call terminal_newline

.done:
    popad
    ret
.bad_ip:
    mov esi, str_ping_badip
    call terminal_append
    call terminal_newline
    popad
    ret

e1000_ping_wait:
    pushad
.wait_loop:
    inc dword [ping_counter]
    cmp dword [ping_counter], 3000000
    jae .done

    mov eax, E1000_RDH
    call e1000_read
    mov [rx_head], eax
    cmp dword [rx_debug_shown], 1
    je .no_dbg
    mov dword [rx_debug_shown], 1
    mov esi, str_rx_head
    call terminal_append
    mov eax, [rx_head]
    call pci_print_hex32
    call terminal_newline
.no_dbg:

    mov eax, [rx_cur]
    cmp eax, [rx_head]
    je .wait_loop

    imul eax, E1000_RX_DESC_SIZE
    add eax, E1000_RX_DESC_ADDR
    mov [rx_desc_ptr], eax
    mov edx, eax

    test byte [edx + 12], 0x01
    jz .wait_loop

    ; DEBUG: print real ethertype from packet buffer
    mov edx, [rx_desc_ptr]
    mov edx, [edx + 0]
    movzx ebx, byte [edx + 12]
    shl ebx, 8
    movzx ecx, byte [edx + 13]
    or ebx, ecx
    mov edx, [rx_desc_ptr]
    mov eax, [edx + 0]
    cmp byte [eax + 13], 0x00
    jne .release
    cmp byte [eax + 23], 0x01
    jne .release
    cmp byte [eax + 34], 0x00
    jne .release

    movzx ecx, byte [eax + 26]
    cmp cl, [ping_target_ip + 0]
    jne .release
    movzx ecx, byte [eax + 27]
    cmp cl, [ping_target_ip + 1]
    jne .release
    movzx ecx, byte [eax + 28]
    cmp cl, [ping_target_ip + 2]
    jne .release
    movzx ecx, byte [eax + 29]
    cmp cl, [ping_target_ip + 3]
    jne .release

    mov dword [ping_received], 1

    mov esi, str_ping_reply
    call terminal_append
    xor ebp, ebp
.pr_octet2:
    cmp ebp, 4
    jae .pr_done2
    movzx eax, byte [ping_target_ip + ebp]
    mov edi, ram_str_buf
    call format_u32
    mov esi, ram_str_buf
    call terminal_append
    cmp ebp, 3
    je .pr_nod2
    mov esi, str_dot
    call terminal_append
.pr_nod2:
    inc ebp
    jmp .pr_octet2
.pr_done2:
    call terminal_newline
    mov esi, str_ping_hi
    call terminal_append
    call terminal_newline
    jmp .release_ok

.release:
    mov edx, [rx_desc_ptr]
    mov byte [edx + 12], 0

    mov eax, E1000_RDT
    mov ebx, [rx_cur]
    call e1000_write

    inc dword [rx_cur]
    cmp dword [rx_cur], E1000_RX_DESC_COUNT
    jb .rel_r
    mov dword [rx_cur], 0
.rel_r:
    jmp .wait_loop

.release_ok:
    mov edx, [rx_desc_ptr]
    mov byte [edx + 12], 0

    mov eax, E1000_RDT
    mov ebx, [rx_cur]
    call e1000_write

    inc dword [rx_cur]
    cmp dword [rx_cur], E1000_RX_DESC_COUNT
    jb .rel_ok2
    mov dword [rx_cur], 0
.rel_ok2:

.done:
    popad
    ret
cmd_dns_run:
    pushad
    mov esi, input_buf + 4
    mov edi, dns_hostname
    xor ecx, ecx
.copy:
    lodsb
    test al, al
    jz .copied
    cmp ecx, 63
    jae .copied
    mov [edi], al
    inc edi
    inc ecx
    jmp .copy
.copied:
    mov byte [edi], 0
    test ecx, ecx
    jz .usage
    mov esi, str_dns_head
    call terminal_append
    mov esi, dns_hostname
    call terminal_append
    call terminal_newline
    call dns_build_query
    mov byte [tx_quiet], 1
    mov esi, E1000_TX_BUF_ADDR
    mov ebx, [dns_frame_len]
    call e1000_send
    mov byte [tx_quiet], 0
    mov dword [dns_poll], 0
    mov byte [dns_got_reply], 0
    call dns_wait_reply
    cmp byte [dns_got_reply], 0
    je .fail
    mov esi, str_dns_result
    call terminal_append
    xor ebp, ebp
.print_ip:
    cmp ebp, 4
    jae .print_done
    movzx eax, byte [dns_result_ip + ebp]
    mov edi, ram_str_buf
    call format_u32
    mov esi, ram_str_buf
    call terminal_append
    cmp ebp, 3
    je .no_dot
    mov esi, str_dot
    call terminal_append
.no_dot:
    inc ebp
    jmp .print_ip
.print_done:
    call terminal_newline
    popad
    ret
.usage:
    mov esi, str_dns_usage
    call terminal_append
    call terminal_newline
    popad
    ret
.fail:
    mov esi, str_dns_fail
    call terminal_append
    call terminal_newline
    popad
    ret

dns_build_query:
    pushad
    mov esi, dns_hostname
    mov ecx, 1
.ql:
    lodsb
    test al, al
    jz .qld
    cmp al, '.'
    je .qdot
    inc ecx
    jmp .ql
.qdot:
    inc ecx
    jmp .ql
.qld:
    inc ecx
    mov [dns_qname_len], ecx
    mov eax, ecx
    add eax, 16
    mov [dns_query_len], eax
    mov edx, eax
    add edx, 28
    mov eax, edx
    add eax, 14
    mov [dns_frame_len], eax
    mov edi, E1000_TX_BUF_ADDR
    movzx eax, byte [arp_reply_mac + 0]
    mov [edi + 0], al
    movzx eax, byte [arp_reply_mac + 1]
    mov [edi + 1], al
    movzx eax, byte [arp_reply_mac + 2]
    mov [edi + 2], al
    movzx eax, byte [arp_reply_mac + 3]
    mov [edi + 3], al
    movzx eax, byte [arp_reply_mac + 4]
    mov [edi + 4], al
    movzx eax, byte [arp_reply_mac + 5]
    mov [edi + 5], al
    movzx eax, byte [e1000_mac + 0]
    mov [edi + 6], al
    movzx eax, byte [e1000_mac + 1]
    mov [edi + 7], al
    movzx eax, byte [e1000_mac + 2]
    mov [edi + 8], al
    movzx eax, byte [e1000_mac + 3]
    mov [edi + 9], al
    movzx eax, byte [e1000_mac + 4]
    mov [edi + 10], al
    movzx eax, byte [e1000_mac + 5]
    mov [edi + 11], al
    mov byte [edi + 12], 0x08
    mov byte [edi + 13], 0x00
    mov byte [edi + 14], 0x45
    mov byte [edi + 15], 0x00
    mov eax, edx
    xchg al, ah
    mov [edi + 16], ax
    mov byte [edi + 18], 0x00
    mov byte [edi + 19], 0x04
    mov byte [edi + 20], 0x00
    mov byte [edi + 21], 0x00
    mov byte [edi + 22], 0x40
    mov byte [edi + 23], 0x11
    mov byte [edi + 24], 0x00
    mov byte [edi + 25], 0x00
    mov byte [edi + 26], 10
    mov byte [edi + 27], 0
    mov byte [edi + 28], 2
    mov byte [edi + 29], 15
    mov byte [edi + 30], 10
    mov byte [edi + 31], 0
    mov byte [edi + 32], 2
    mov byte [edi + 33], 3
    push edi
    lea esi, [edi + 14]
    mov ecx, 20
    call ip_checksum
    pop edi
    mov [edi + 24], ah
    mov [edi + 25], al
    mov byte [edi + 34], 0xC0
    mov byte [edi + 35], 0x00
    mov byte [edi + 36], 0x00
    mov byte [edi + 37], 0x35
    mov eax, [dns_query_len]
    add eax, 8
    xchg al, ah
    mov [edi + 38], ax
    mov byte [edi + 40], 0x00
    mov byte [edi + 41], 0x00
    mov byte [edi + 42], 0x12
    mov byte [edi + 43], 0x34
    mov byte [edi + 44], 0x01
    mov byte [edi + 45], 0x00
    mov byte [edi + 46], 0x00
    mov byte [edi + 47], 0x01
    mov byte [edi + 48], 0x00
    mov byte [edi + 49], 0x00
    mov byte [edi + 50], 0x00
    mov byte [edi + 51], 0x00
    mov byte [edi + 52], 0x00
    mov byte [edi + 53], 0x00
    mov esi, dns_hostname
    mov edi, E1000_TX_BUF_ADDR
    add edi, 54
.qname_label:
    mov ebx, edi
    inc edi
    xor ecx, ecx
.qname_char:
    lodsb
    test al, al
    jz .qname_end
    cmp al, '.'
    je .qname_sep
    stosb
    inc ecx
    jmp .qname_char
.qname_sep:
    mov [ebx], cl
    jmp .qname_label
.qname_end:
    mov [ebx], cl
    mov byte [edi], 0x00
    inc edi
    mov byte [edi + 0], 0x00
    mov byte [edi + 1], 0x01
    mov byte [edi + 2], 0x00
    mov byte [edi + 3], 0x01
    popad
    ret

dns_wait_reply:
    pushad
.poll_loop:
    inc dword [dns_poll]
    cmp dword [dns_poll], 3000000
    jae .done

    mov eax, E1000_RDH
    call e1000_read
    mov [rx_head], eax
    cmp dword [rx_debug_shown], 1
    je .no_dbg
    mov dword [rx_debug_shown], 1
    mov esi, str_rx_head
    call terminal_append
    mov eax, [rx_head]
    call pci_print_hex32
    call terminal_newline
.no_dbg:
    mov eax, [rx_cur]
    cmp eax, [rx_head]
    je .poll_loop

    imul eax, E1000_RX_DESC_SIZE
    add eax, E1000_RX_DESC_ADDR
    mov [rx_desc_ptr], eax
    mov edx, eax

    test byte [edx + 12], 0x01
    jz .poll_loop

    mov edx, [rx_desc_ptr]
    mov eax, [edx + 0]

    cmp byte [eax + 12], 0x08
    jne .release
    cmp byte [eax + 13], 0x00
    jne .release
    cmp byte [eax + 23], 0x11
    jne .release
    cmp byte [eax + 26], 10
    jne .release
    cmp byte [eax + 27], 0
    jne .release
    cmp byte [eax + 28], 2
    jne .release
    cmp byte [eax + 29], 3
    jne .release
    cmp byte [eax + 34], 0x00
    jne .release
    cmp byte [eax + 35], 0x35
    jne .release
    cmp byte [eax + 42], 0x12
    jne .release
    cmp byte [eax + 43], 0x34
    jne .release

    lea esi, [eax + 42]
    add esi, 12
    add esi, [dns_qname_len]
    add esi, 4

    movzx ecx, byte [esi]
    and ecx, 0xC0
    cmp ecx, 0xC0
    jne .release
    add esi, 2
    add esi, 10

    mov al, [esi]
    mov [dns_result_ip + 0], al
    mov al, [esi + 1]
    mov [dns_result_ip + 1], al
    mov al, [esi + 2]
    mov [dns_result_ip + 2], al
    mov al, [esi + 3]
    mov [dns_result_ip + 3], al
    mov byte [dns_got_reply], 1

.release:
    mov edx, [rx_desc_ptr]
    mov byte [edx + 12], 0
    mov eax, E1000_RDT
    mov ebx, [rx_cur]
    call e1000_write
    inc dword [rx_cur]
    cmp dword [rx_cur], E1000_RX_DESC_COUNT
    jb .poll_loop
    mov dword [rx_cur], 0
    jmp .poll_loop

.done:
    popad
    ret
cmd_tcp_run:
    pushad

    mov esi, input_buf + 4
    mov edi, tcp_server_ip
    call parse_ip
    jc .usage

    cmp byte [arp_reply_mac], 0
    jne .have_gw
    mov esi, str_ping_nogw
    call terminal_append
    call terminal_newline
    popad
    ret
.have_gw:

    mov byte [tcp_state], 0

    call tcp_build_syn
    mov esi, str_tcp_syn
    call terminal_append
    call terminal_newline

    mov byte [tx_quiet], 1
    mov esi, E1000_TX_BUF_ADDR
    mov ebx, 54
    call e1000_send
    mov byte [tx_quiet], 0

    mov byte [tcp_state], 1
    mov dword [tcp_poll], 0
    call tcp_wait_synack

    cmp byte [tcp_state], 2
    jne .fail

    mov esi, str_tcp_synack
    call terminal_append
    call terminal_newline

    call tcp_build_ack

    mov byte [tx_quiet], 1
    mov esi, E1000_TX_BUF_ADDR
    mov ebx, 54
    call e1000_send
    mov byte [tx_quiet], 0

    mov esi, str_tcp_ok
    call terminal_append
    call terminal_newline
    popad
    ret

.usage:
    mov esi, str_tcp_usage
    call terminal_append
    call terminal_newline
    popad
    ret

.fail:
    mov esi, str_ping_timeout
    call terminal_append
    call terminal_newline
    popad
    ret

tcp_build_syn:
    pushad
    call tcp_build_common
    mov edi, E1000_TX_BUF_ADDR
    mov byte [edi + 47], 0x02

    ; Compute TCP checksum
    lea esi, [edi + 34]
    mov ecx, 20
    call tcp_checksum
    mov edi, E1000_TX_BUF_ADDR
    mov [edi + 50], ah
    mov [edi + 51], al
    popad
    ret

tcp_build_ack:
    pushad
    call tcp_build_common
    mov edi, E1000_TX_BUF_ADDR

    mov byte [edi + 47], 0x10

    mov eax, [tcp_local_isn]
    inc eax
    bswap eax
    mov [edi + 38], eax

    mov eax, [tcp_remote_isn]
    inc eax
    bswap eax
    mov [edi + 42], eax

    lea esi, [edi + 34]
    mov ecx, 20
    call tcp_checksum
    mov edi, E1000_TX_BUF_ADDR
    mov [edi + 50], ah
    mov [edi + 51], al
    ; Set next sequence numbers for data transfer
    mov eax, [tcp_local_isn]
    inc eax
    mov [tcp_my_seq], eax
    mov eax, [tcp_remote_isn]
    inc eax
    mov [tcp_their_seq], eax
    mov byte [tcp_done], 0
    mov dword [tcp_data_len], 0
    popad
    ret

tcp_build_common:
    pushad
    mov edi, E1000_TX_BUF_ADDR

    ; Ethernet dst = gateway MAC
    movzx eax, byte [arp_reply_mac + 0]
    mov [edi + 0], al
    movzx eax, byte [arp_reply_mac + 1]
    mov [edi + 1], al
    movzx eax, byte [arp_reply_mac + 2]
    mov [edi + 2], al
    movzx eax, byte [arp_reply_mac + 3]
    mov [edi + 3], al
    movzx eax, byte [arp_reply_mac + 4]
    mov [edi + 4], al
    movzx eax, byte [arp_reply_mac + 5]
    mov [edi + 5], al

    ; Ethernet src = our MAC
    movzx eax, byte [e1000_mac + 0]
    mov [edi + 6], al
    movzx eax, byte [e1000_mac + 1]
    mov [edi + 7], al
    movzx eax, byte [e1000_mac + 2]
    mov [edi + 8], al
    movzx eax, byte [e1000_mac + 3]
    mov [edi + 9], al
    movzx eax, byte [e1000_mac + 4]
    mov [edi + 10], al
    movzx eax, byte [e1000_mac + 5]
    mov [edi + 11], al

    mov byte [edi + 12], 0x08
    mov byte [edi + 13], 0x00

    ; IPv4 header
    mov byte [edi + 14], 0x45
    mov byte [edi + 15], 0x00
    mov byte [edi + 16], 0x00
    mov byte [edi + 17], 0x28
    mov byte [edi + 18], 0x00
    mov byte [edi + 19], 0x05
    mov byte [edi + 20], 0x00
    mov byte [edi + 21], 0x00
    mov byte [edi + 22], 0x40
    mov byte [edi + 23], 0x06
    mov byte [edi + 24], 0x00
    mov byte [edi + 25], 0x00
    mov byte [edi + 26], 10
    mov byte [edi + 27], 0
    mov byte [edi + 28], 2
    mov byte [edi + 29], 15
    movzx eax, byte [tcp_server_ip + 0]
    mov [edi + 30], al
    movzx eax, byte [tcp_server_ip + 1]
    mov [edi + 31], al
    movzx eax, byte [tcp_server_ip + 2]
    mov [edi + 32], al
    movzx eax, byte [tcp_server_ip + 3]
    mov [edi + 33], al

    push edi
    lea esi, [edi + 14]
    mov ecx, 20
    call ip_checksum
    pop edi
    mov [edi + 24], ah
    mov [edi + 25], al

    ; TCP header
    mov byte [edi + 34], 0xC0
    mov byte [edi + 35], 0x00
    mov byte [edi + 36], 0x00
    mov byte [edi + 37], 0x50

    mov eax, [tcp_local_isn]
    bswap eax
    mov [edi + 38], eax

    mov dword [edi + 42], 0

    mov byte [edi + 46], 0x50

    mov byte [edi + 47], 0x00

    mov byte [edi + 48], 0xFF
    mov byte [edi + 49], 0xFF

    mov byte [edi + 50], 0x00
    mov byte [edi + 51], 0x00

    mov byte [edi + 52], 0x00
    mov byte [edi + 53], 0x00

    popad
    ret

tcp_checksum:
    push ebx
    push edx
    push esi
    push ecx
    push ebp
    mov ebp, ecx
    xor eax, eax

    mov ebx, 0x0A00
    add eax, ebx
    mov ebx, 0x020F
    add eax, ebx

    movzx ebx, byte [tcp_server_ip + 0]
    shl ebx, 8
    movzx edx, byte [tcp_server_ip + 1]
    or ebx, edx
    add eax, ebx
    movzx ebx, byte [tcp_server_ip + 2]
    shl ebx, 8
    movzx edx, byte [tcp_server_ip + 3]
    or ebx, edx
    add eax, ebx

    mov ebx, 0x0006
    add eax, ebx

    movzx ebx, bp
    add eax, ebx

.loop:
    test ecx, ecx
    jz .fold
    cmp ecx, 1
    je .last_byte
    movzx ebx, word [esi]
    xchg bl, bh
    add eax, ebx
    add esi, 2
    sub ecx, 2
    jmp .loop

.last_byte:
    movzx ebx, byte [esi]
    shl ebx, 8
    add eax, ebx

.fold:
    mov ebx, eax
    shr ebx, 16
    and eax, 0xFFFF
    add eax, ebx
    mov ebx, eax
    shr ebx, 16
    and eax, 0xFFFF
    add eax, ebx
    not eax
    and eax, 0xFFFF
    pop ebp
    pop ecx
    pop esi
    pop edx
    pop ebx
    ret
; EDI = payload ptr, ECX = payload length. Sends PSH+ACK.
tcp_send_data:
    pushad
    mov [tcp_pay_ptr], edi
    mov [tcp_pay_len], ecx

    call tcp_build_common
    mov edi, E1000_TX_BUF_ADDR

    ; IP total length = 40 (IP+TCP) + payload
    mov eax, [tcp_pay_len]
    add eax, 40
    xchg al, ah
    mov [edi + 16], ax

    ; Seq = tcp_my_seq
    mov eax, [tcp_my_seq]
    bswap eax
    mov [edi + 38], eax

    ; Ack = tcp_their_seq
    mov eax, [tcp_their_seq]
    bswap eax
    mov [edi + 42], eax

    ; Flags: PSH+ACK = 0x18
    mov byte [edi + 47], 0x18

    ; Window
    mov byte [edi + 48], 0xFF
    mov byte [edi + 49], 0xFF

    ; Copy payload
    mov esi, [tcp_pay_ptr]
    lea edi, [edi + 54]
    mov ecx, [tcp_pay_len]
    rep movsb

    ; IP checksum
    mov edi, E1000_TX_BUF_ADDR
    push edi
    lea esi, [edi + 14]
    mov ecx, 20
    call ip_checksum
    pop edi
    mov [edi + 24], ah
    mov [edi + 25], al

    ; TCP checksum over header+payload
    lea esi, [edi + 34]
    mov ecx, [tcp_pay_len]
    add ecx, 20
    push edi
    call tcp_checksum
    pop edi
    mov [edi + 50], ah
    mov [edi + 51], al

    ; Send it
    mov esi, E1000_TX_BUF_ADDR
    mov ebx, [tcp_pay_len]
    add ebx, 54
    mov byte [tx_quiet], 1
    call e1000_send
    mov byte [tx_quiet], 0

    ; Advance our seq
    mov eax, [tcp_my_seq]
    add eax, [tcp_pay_len]
    mov [tcp_my_seq], eax

    popad
    ret
; Send a bare ACK, no payload.
tcp_send_pure_ack:
    pushad
    call tcp_build_common
    mov edi, E1000_TX_BUF_ADDR
    mov eax, [tcp_my_seq]
    bswap eax
    mov [edi + 38], eax
    mov eax, [tcp_their_seq]
    bswap eax
    mov [edi + 42], eax
    mov byte [edi + 47], 0x10
    lea esi, [edi + 34]
    mov ecx, 20
    call tcp_checksum
    mov edi, E1000_TX_BUF_ADDR
    mov [edi + 50], ah
    mov [edi + 51], al
    mov esi, E1000_TX_BUF_ADDR
    mov ebx, 54
    mov byte [tx_quiet], 1
    call e1000_send
    mov byte [tx_quiet], 0
    popad
    ret
tcp_wait_synack:
    pushad
.wait_loop:
    inc dword [tcp_poll]
    cmp dword [tcp_poll], 3000000
    jae .done

    mov eax, E1000_RDH
    call e1000_read
    mov [rx_head], eax

    mov eax, [rx_cur]
    cmp eax, [rx_head]
    je .wait_loop

    imul eax, E1000_RX_DESC_SIZE
    add eax, E1000_RX_DESC_ADDR
    mov [rx_desc_ptr], eax
    mov edx, eax

    test byte [edx + 12], 0x01
    jz .wait_loop

    mov edx, [rx_desc_ptr]
    mov edx, [edx + 0]
    movzx ebx, byte [edx + 12]
    shl ebx, 8
    movzx ecx, byte [edx + 13]
    or ebx, ecx
    mov esi, str_empty
    call terminal_append
    mov eax, ebx
    call pci_print_hex32
    mov esi, str_empty
    call terminal_append
    movzx eax, byte [edx + 23]
    call pci_print_hex_byte
    mov esi, str_empty
    call terminal_append
    movzx eax, byte [edx + 47]
    call pci_print_hex_byte
    call terminal_newline

    mov edx, [rx_desc_ptr]
    mov eax, [edx + 0]

    cmp byte [eax + 12], 0x08
    jne .release
    cmp byte [eax + 13], 0x00
    jne .release
    cmp byte [eax + 23], 0x06
    jne .release

    movzx ecx, byte [eax + 26]
    cmp cl, [tcp_server_ip + 0]
    jne .release
    movzx ecx, byte [eax + 27]
    cmp cl, [tcp_server_ip + 1]
    jne .release
    movzx ecx, byte [eax + 28]
    cmp cl, [tcp_server_ip + 2]
    jne .release
    movzx ecx, byte [eax + 29]
    cmp cl, [tcp_server_ip + 3]
    jne .release

    cmp byte [eax + 34], 0x00
    jne .release
    cmp byte [eax + 35], 0x50
    jne .release

    cmp byte [eax + 36], 0xC0
    jne .release
    cmp byte [eax + 37], 0x00
    jne .release

    movzx ecx, byte [eax + 47]
    and ecx, 0x12
    cmp ecx, 0x12
    jne .release

    movzx ecx, byte [eax + 38]
    shl ecx, 24
    movzx edx, byte [eax + 39]
    shl edx, 16
    or ecx, edx
    movzx edx, byte [eax + 40]
    shl edx, 8
    or ecx, edx
    movzx edx, byte [eax + 41]
    or ecx, edx
    mov [tcp_remote_isn], ecx

    mov byte [tcp_state], 2

.release:
    mov edx, [rx_desc_ptr]
    mov byte [edx + 12], 0
    mov eax, E1000_RDT
    mov ebx, [rx_cur]
    call e1000_write
    inc dword [rx_cur]
    cmp dword [rx_cur], E1000_RX_DESC_COUNT
    jb .rel_ok
    mov dword [rx_cur], 0
.rel_ok:
    cmp byte [tcp_state], 2
    jne .wait_loop

.done:
    popad
    ret
; Receive TCP data into tcp_data_buf until FIN or timeout.
tcp_recv_data:
    pushad
    mov dword [tcp_data_len], 0
    mov esi, str_empty
    call terminal_append
    call terminal_newline
    mov esi, str_empty
    call terminal_append
    call terminal_newline
    mov dword [tcp_poll], 0

.wait:
    inc dword [tcp_poll]
    cmp dword [tcp_poll], 50000000
    jae .done

    mov eax, E1000_RDH
    call e1000_read
    mov [rx_head], eax
    mov eax, [rx_cur]
    cmp eax, [rx_head]
    je .wait

    imul eax, E1000_RX_DESC_SIZE
    add eax, E1000_RX_DESC_ADDR
    mov [rx_desc_ptr], eax
    mov edx, eax
    test byte [edx + 12], 0x01
    jz .wait
    mov edx, [rx_desc_ptr]
    mov edx, [edx + 0]
    mov esi, str_empty
    call terminal_append
    movzx eax, byte [edx + 34]
    call pci_print_hex_byte
    movzx eax, byte [edx + 35]
    call pci_print_hex_byte
    mov esi, str_empty
    call terminal_append
    movzx eax, byte [edx + 36]
    call pci_print_hex_byte
    movzx eax, byte [edx + 37]
    call pci_print_hex_byte
    mov esi, str_empty
    call terminal_append
    movzx eax, byte [edx + 47]
    call pci_print_hex_byte
    mov esi, str_empty
    call terminal_append
    movzx eax, byte [edx + 16]
    call pci_print_hex_byte
    movzx eax, byte [edx + 17]
    call pci_print_hex_byte
    call terminal_newline
    mov edx, [rx_desc_ptr]
    mov edx, [edx + 0]
    mov esi, str_empty
    call terminal_append
    movzx eax, byte [edx + 12]
    call pci_print_hex_byte
    movzx eax, byte [edx + 13]
    call pci_print_hex_byte
    mov esi, str_empty
    call terminal_append
    movzx eax, byte [edx + 23]
    call pci_print_hex_byte
    call terminal_newline
    mov esi, str_empty
    call terminal_append
    movzx eax, byte [edx + 26]
    call pci_print_hex_byte
    movzx eax, byte [edx + 27]
    call pci_print_hex_byte
    movzx eax, byte [edx + 28]
    call pci_print_hex_byte
    movzx eax, byte [edx + 29]
    call pci_print_hex_byte
    mov esi, str_empty
    call terminal_append
    movzx eax, byte [edx + 34]
    call pci_print_hex_byte
    movzx eax, byte [edx + 35]
    call pci_print_hex_byte
    movzx eax, byte [edx + 36]
    call pci_print_hex_byte
    movzx eax, byte [edx + 37]
    call pci_print_hex_byte
    mov esi, str_empty
    call terminal_append
    movzx eax, byte [edx + 16]
    call pci_print_hex_byte
    movzx eax, byte [edx + 17]
    call pci_print_hex_byte
    call terminal_newline
    mov edx, [rx_desc_ptr]
    mov eax, [edx + 0]

    cmp byte [eax + 12], 0x08
    jne .release
    cmp byte [eax + 13], 0x00
    jne .release
    cmp byte [eax + 23], 0x06
    jne .release

    movzx ecx, byte [eax + 26]
    cmp cl, [tcp_server_ip + 0]
    jne .release
    movzx ecx, byte [eax + 27]
    cmp cl, [tcp_server_ip + 1]
    jne .release
    movzx ecx, byte [eax + 28]
    cmp cl, [tcp_server_ip + 2]
    jne .release
    movzx ecx, byte [eax + 29]
    cmp cl, [tcp_server_ip + 3]
    jne .release

    cmp byte [eax + 36], 0xC0
    jne .release
    cmp byte [eax + 37], 0x00
    jne .release

    movzx ecx, byte [eax + 38]
    shl ecx, 24
    movzx edx, byte [eax + 39]
    shl edx, 16
    or ecx, edx
    movzx edx, byte [eax + 40]
    shl edx, 8
    or ecx, edx
    movzx edx, byte [eax + 41]
    or ecx, edx
    mov [tcp_their_seq], ecx

    movzx edx, byte [eax + 16]
    shl edx, 8
    movzx esi, byte [eax + 17]
    or edx, esi
    sub edx, 20
    movzx ecx, byte [eax + 46]
    shr ecx, 4
    shl ecx, 2
    sub edx, ecx
    mov [tcp_pay_len], edx

    test edx, edx
    jz .check_flags
    mov ecx, [tcp_their_seq]
    add ecx, edx
    mov [tcp_their_seq], ecx

    movzx ecx, byte [eax + 46]
    shr ecx, 4
    shl ecx, 2
    lea esi, [eax + 34 + ecx]
    mov edi, tcp_data_buf
    add edi, [tcp_data_len]
    mov ecx, [tcp_pay_len]
    mov edx, [tcp_data_len]
    add edx, ecx
    cmp edx, 8000
    jbe .copy_ok
    mov ecx, 8000
    sub ecx, [tcp_data_len]
.copy_ok:
    rep movsb
    mov eax, [tcp_pay_len]
    add [tcp_data_len], eax

    call tcp_send_pure_ack

.check_flags:
    mov edx, [rx_desc_ptr]
    mov eax, [edx + 0]
    test byte [eax + 47], 0x01
    jnz .fin
    test byte [eax + 47], 0x04
    jnz .fin

.release:
    mov edx, [rx_desc_ptr]
    mov byte [edx + 12], 0
    mov eax, E1000_RDT
    mov ebx, [rx_cur]
    call e1000_write
    inc dword [rx_cur]
    cmp dword [rx_cur], E1000_RX_DESC_COUNT
    jb .wait
    mov dword [rx_cur], 0
    jmp .wait

.fin:
    mov edx, [rx_desc_ptr]
    mov byte [edx + 12], 0
    mov eax, E1000_RDT
    mov ebx, [rx_cur]
    call e1000_write
    inc dword [rx_cur]
    cmp dword [rx_cur], E1000_RX_DESC_COUNT
    jb .done
    mov dword [rx_cur], 0

.done:
    mov byte [tcp_done], 1
    popad
    ret
rx_dump_first_packet:
    pushad
    mov esi, str_empty
    call terminal_append
    call terminal_newline
    mov esi, E1000_RX_BUF_ADDR
    mov ecx, 32
.dump_loop:
    movzx eax, byte [esi]
    push esi
    push ecx
    call pci_print_hex_byte
    mov esi, str_empty
    call terminal_append
    pop ecx
    pop esi
    inc esi
    dec ecx
    jnz .dump_loop
    call terminal_newline
    popad
    ret
; Send a byte to the SB16 DSP. AL = byte.
sb16_write:
    pushad
    mov bl, al
    mov ecx, 0xFFFF
.wait:
    mov dx, SB16_WRITE
    in al, dx
    test al, 0x80
    jz .ready
    loop .wait
    popad
    ret
.ready:
    mov dx, SB16_WRITE
    mov al, bl
    out dx, al
    popad
    ret

; Play a square wave tone. Uses sb16_buf (512 bytes).
sb16_play_tone:
    pushad

    ; Fill buffer with 689 Hz square wave (11025 Hz sample rate)
    mov edi, sb16_buf
    mov ecx, 512
    xor ebx, ebx
.fill:
    mov eax, ebx
    test eax, 0x08
    jz .low
    mov al, 0xD0
    jmp .store
.low:
    mov al, 0x30
.store:
    mov [edi], al
    inc edi
    inc ebx
    loop .fill

    ; Speaker on
    mov al, 0xD1
    call sb16_write

    ; Set sample rate 11025 Hz
    mov al, 0x40
    call sb16_write
    mov al, 166
    call sb16_write

    ; Mask DMA channel 1
    mov dx, 0x0A
    mov al, 0x05
    out dx, al

    ; Clear DMA flip-flop
    mov dx, 0x0C
    xor al, al
    out dx, al

    ; DMA mode: single, increment, read from memory, channel 1
    mov dx, 0x0B
    mov al, 0x49
    out dx, al

    ; Address low, then high
    mov eax, sb16_buf
    mov dx, 0x02
    out dx, al
    mov al, ah
    out dx, al

    ; Page register
    shr eax, 16
    mov dx, 0x83
    out dx, al

    ; Count = 511 (512 - 1), low then high
    mov dx, 0x03
    mov al, 0xFF
    out dx, al
    mov al, 0x01
    out dx, al

    ; Unmask DMA channel 1
    mov dx, 0x0A
    mov al, 0x01
    out dx, al

    ; Command 0x14: 8-bit single-cycle DMA output
    mov al, 0x14
    call sb16_write
    mov al, 0xFF
    call sb16_write
    mov al, 0x01
    call sb16_write

    popad
    ret
play_wav:
    pushad

    ; Read sectors from disk into WAV_BUF
    mov byte [ata_drive], 0xE0
    xor ebp, ebp
.read_loop:
    cmp ebp, WAV_SECTORS
    jae .read_done
    mov esi, WAV_LBA
    add esi, ebp
    mov edi, WAV_BUF
    mov eax, ebp
    shl eax, 9
    add edi, eax
    call ata_read_sector
    jc .bad
    inc ebp
    jmp .read_loop
.read_done:

    cmp dword [WAV_BUF], 0x46464952
    jne .bad
    cmp dword [WAV_BUF + 8], 0x45564157
    jne .bad
    cmp dword [WAV_BUF + 12], 0x20746D66
    jne .bad
    cmp dword [WAV_BUF + 36], 0x61746164
    jne .bad
    movzx eax, word [WAV_BUF + 22]
    cmp eax, 1
    jne .bad
    movzx eax, word [WAV_BUF + 34]
    cmp eax, 8
    jne .bad

    ; Time constant = 256 - (1000000 / sample_rate)
    mov ecx, [WAV_BUF + 24]
    mov eax, 1000000
    xor edx, edx
    div ecx
    mov ebx, 256
    sub ebx, eax
    mov [wav_tc], bl

    ; Data length
    mov eax, [WAV_BUF + 40]
    cmp eax, WAV_SECTORS * 512 - 44
    jbe .size_ok
    mov eax, WAV_SECTORS * 512 - 44
.size_ok:
    mov [wav_len], eax
    dec eax
    mov [wav_lenm1], ax

    ; --- DMA channel 1 ---
    mov dx, 0x0A
    mov al, 0x05
    out dx, al
    mov dx, 0x0C
    xor al, al
    out dx, al
    mov dx, 0x0B
    mov al, 0x59
    out dx, al

    mov eax, WAV_BUF + 44
    mov dx, 0x02
    out dx, al
    mov al, ah
    out dx, al
    mov eax, WAV_BUF + 44
    shr eax, 16
    mov dx, 0x83
    out dx, al

    mov ax, [wav_lenm1]
    mov dx, 0x03
    out dx, al
    mov al, ah
    out dx, al

    mov dx, 0x0A
    mov al, 0x01
    out dx, al

    ; --- DSP ---
    mov al, 0xD1
    call sb16_write
    mov al, 0x40
    call sb16_write
    mov al, [wav_tc]
    call sb16_write
    mov al, 0x14
    call sb16_write
    mov ax, [wav_lenm1]
    call sb16_write
    mov al, ah
    call sb16_write

    popad
    ret
.bad:
    popad
    ret

wav_tc:     db 0
wav_len:    dd 0
wav_lenm1:  dw 0
; Reset the Sound Blaster 16 DSP. Returns 0 on success, -1 on failure.
sb16_reset:
    pushad

    ; 1. Write 1 to reset port
    mov dx, SB16_RESET
    mov al, 1
    out dx, al

    ; 2. Wait ~3 microseconds
    mov ecx, 50
.wait_reset:
    in al, 0x80
    loop .wait_reset

    ; 3. Write 0 to reset port
    mov dx, SB16_RESET
    xor al, al
    out dx, al

    ; 4. Wait for 0xAA from DSP
    mov ecx, 0xFFFF
.wait_ready:
    mov dx, SB16_READ_STATUS
    in al, dx
    test al, 0x80
    jz .next_check

    mov dx, SB16_READ
    in al, dx
    cmp al, 0xAA
    je .reset_ok

.next_check:
    loop .wait_ready
    popad
    mov eax, -1
    ret

.reset_ok:
    popad
    xor eax, eax
    ret

e1000_rx_init:
    pushad
    cmp dword [e1000_base], 0
    je .done

    ; Zero the descriptor ring
    mov edi, E1000_RX_DESC_ADDR
    mov ecx, E1000_RX_DESC_COUNT * E1000_RX_DESC_SIZE / 4
    xor eax, eax
    rep stosd

    ; Initialize each descriptor with its own buffer
    xor ebx, ebx
.fill:
    cmp ebx, E1000_RX_DESC_COUNT
    jae .filled

    mov eax, ebx
    imul eax, E1000_RX_DESC_SIZE
    add eax, E1000_RX_DESC_ADDR
    mov edi, eax

    ; buffer addr = RX_BUF_ADDR + ebx * RX_BUF_SIZE
    mov eax, ebx
    imul eax, E1000_RX_BUF_SIZE
    add eax, E1000_RX_BUF_ADDR
    mov [edi + 0], eax
    mov dword [edi + 4], 0
    mov word [edi + 8], 0
    mov word [edi + 10], 0
    mov byte [edi + 12], 0
    mov byte [edi + 13], 0
    mov word [edi + 14], 0

    inc ebx
    jmp .fill
.filled:

    ; RDBAL / RDBAH
    mov eax, E1000_RDBAL
    mov ebx, E1000_RX_DESC_ADDR
    call e1000_write
    mov eax, E1000_RDBAH
    xor ebx, ebx
    call e1000_write

    ; RDLEN = 128
    mov eax, E1000_RDLEN
    mov ebx, E1000_RX_DESC_COUNT * E1000_RX_DESC_SIZE
    call e1000_write

    ; RDH = 0
    mov eax, E1000_RDH
    xor ebx, ebx
    call e1000_write

    ; RDT = count - 1 (all descriptors available to HW)
    mov eax, E1000_RDT
    mov ebx, E1000_RX_DESC_COUNT - 1
    call e1000_write

    ; RCTL = EN | UPE | MPE | BAM | BSIZE=2048
    mov eax, E1000_RCTL
    mov ebx, 0x0000801A
    call e1000_write

    mov dword [rx_cur], 0
    mov dword [rx_ready], 1

    mov esi, str_empty
    call terminal_append
    call terminal_newline
.done:
    popad
    ret

e1000_rx_poll:
    pushad
    cmp dword [rx_ready], 0
    je .done
    cmp dword [e1000_base], 0
    je .done

    ; Read RDH
    mov eax, E1000_RDH
    call e1000_read
    mov [rx_head], eax

.poll_loop:
    mov eax, [rx_cur]
    cmp eax, [rx_head]
    je .done

    ; Descriptor address
    imul eax, E1000_RX_DESC_SIZE
    add eax, E1000_RX_DESC_ADDR
    mov [rx_desc_ptr], eax
    mov edx, eax

    ; DD bit?
    test byte [edx + 12], 0x01
    jz .done

    ; Read length
    movzx ebx, word [edx + 8]
    mov [rx_len], ebx

    ; Get descriptor's buffer address
    mov edx, [rx_desc_ptr]
    mov eax, [edx + 0]           ; buffer addr low

    ; Print "RX: packet, len=XXXXXXXX"
    mov esi, str_empty
    call terminal_append
    mov eax, [rx_len]
    call pci_print_hex32
    call terminal_newline

    ; Read ethertype from buffer+12
    mov edx, [rx_desc_ptr]
    mov eax, [edx + 0]           ; buffer addr
    movzx ebx, byte [eax + 12]
    shl ebx, 8
    movzx ecx, byte [eax + 13]
    or ebx, ecx
    mov [rx_et], ebx

    ; Print "  et=XXXXXXXX"
    mov esi, str_empty
    call terminal_append
    mov eax, ebx
    call pci_print_hex32
    call terminal_newline

    ; --- Name layer UDP ---
    mov edx, [rx_desc_ptr]
    mov eax, [edx + 0]
    cmp byte [eax + 12], 0x08
    jne .nl_not_udp
    cmp byte [eax + 13], 0x00
    jne .nl_not_udp
    cmp byte [eax + 23], 0x11
    jne .nl_not_udp
    movzx ecx, byte [eax + 36]
    shl ecx, 8
    movzx edx, byte [eax + 37]
    or ecx, edx
    cmp ecx, 5353
    jne .nl_not_udp
    mov esi, eax
    add esi, 26
    mov edi, nl_src_ip
    mov ecx, 4
.nls:
    mov dl, [esi]
    mov [edi], dl
    inc esi
    inc edi
    dec ecx
    jnz .nls
    add eax, 42
    mov ebx, [rx_len]
    sub ebx, 42
    call nl_wire_handle
    jmp .not_arp
.nl_not_udp:

    ; Look at ethertype at buffer+12

    ; Look at ethertype at buffer+12
    mov edx, [rx_desc_ptr]
    mov eax, [edx + 0]
    movzx ecx, byte [eax + 12]
    cmp cl, 0x08
    jne .not_arp
    movzx ecx, byte [eax + 13]
    cmp cl, 0x06
    jne .not_arp

    ; It's ARP. Check opcode (bytes 20-21) == 0x0002 (reply)
    movzx ecx, byte [eax + 20]
    cmp cl, 0x00
    jne .not_arp
    movzx ecx, byte [eax + 21]
    cmp cl, 0x02
    jne .not_arp

    ; Save sender MAC (bytes 22-27) and IP (28-31)
    mov edx, eax
    movzx ecx, byte [edx + 22]
    mov [arp_reply_mac + 0], cl
    movzx ecx, byte [edx + 23]
    mov [arp_reply_mac + 1], cl
    movzx ecx, byte [edx + 24]
    mov [arp_reply_mac + 2], cl
    movzx ecx, byte [edx + 25]
    mov [arp_reply_mac + 3], cl
    movzx ecx, byte [edx + 26]
    mov [arp_reply_mac + 4], cl
    movzx ecx, byte [edx + 27]
    mov [arp_reply_mac + 5], cl

    movzx ecx, byte [edx + 28]
    mov [arp_reply_ip + 0], cl
    movzx ecx, byte [edx + 29]
    mov [arp_reply_ip + 1], cl
    movzx ecx, byte [edx + 30]
    mov [arp_reply_ip + 2], cl
    movzx ecx, byte [edx + 31]
    mov [arp_reply_ip + 3], cl

    ; Print "  ARP REPLY from "
    call terminal_newline
    mov esi, str_empty
    call terminal_append

    ; Print MAC
    xor ebp, ebp
.mac_loop:
    cmp ebp, 6
    jae .mac_done
    movzx eax, byte [arp_reply_mac + ebp]
    call pci_print_hex_byte
    cmp ebp, 5
    je .no_col
    mov al, ':'
    mov [pci_scan_buf], al
    mov byte [pci_scan_buf+1], 0
    mov esi, pci_scan_buf
    call terminal_append
.no_col:
    inc ebp
    jmp .mac_loop
.mac_done:
    call terminal_newline

.not_arp:

    ; Clear status so HW can reuse
    mov edx, [rx_desc_ptr]
    mov byte [edx + 12], 0

    ; RDT = rx_cur (mark the descriptor we just consumed as free)
    mov eax, E1000_RDT
    mov ebx, [rx_cur]
    call e1000_write

    ; Advance rx_cur
    inc dword [rx_cur]
    cmp dword [rx_cur], E1000_RX_DESC_COUNT
    jb .no_wrap
    mov dword [rx_cur], 0
.no_wrap:

    ; Re-read RDH in case more arrived
    mov eax, E1000_RDH
    call e1000_read
    mov [rx_head], eax
    jmp .poll_loop

.done:
    popad
    ret
e1000_send_test:
    pushad
    ; Fill a small buffer with a fake Ethernet frame
    ; dst MAC = ff:ff:ff:ff:ff:ff (broadcast)
    ; src MAC = our MAC
    ; ethertype = 0x0806 (ARP)
    ; then 42 bytes of zero (a stub ARP body)
    mov edi, E1000_TX_BUF_ADDR

    ; broadcast dst
    mov dword [edi + 0], 0xFFFFFFFF
    mov word  [edi + 4], 0xFFFF

    ; src = our MAC
    movzx eax, byte [e1000_mac + 0]
    mov [edi + 6], al
    movzx eax, byte [e1000_mac + 1]
    mov [edi + 7], al
    movzx eax, byte [e1000_mac + 2]
    mov [edi + 8], al
    movzx eax, byte [e1000_mac + 3]
    mov [edi + 9], al
    movzx eax, byte [e1000_mac + 4]
    mov [edi + 10], al
    movzx eax, byte [e1000_mac + 5]
    mov [edi + 11], al

    ; ethertype = ARP
    mov word [edi + 12], 0x0608   ; 0x0806 big-endian in memory

    ; zero the rest (42 bytes) — enough for a stub frame
    mov ecx, 42
    mov eax, 0
    add edi, 14
    rep stosb

    ; Send 60 bytes total (min Ethernet frame)
    mov esi, E1000_TX_BUF_ADDR
    mov ebx, 60
    call e1000_send
    popad
    ret
; Send a packet of EBX bytes from buffer at ESI
e1000_send:
    pushad
    cmp dword [e1000_base], 0
    je .fail

    ; Copy packet into the TX buffer slot for current descriptor
    mov edi, E1000_TX_BUF_ADDR
    mov ecx, ebx
    push esi
    push edi
    cld
    rep movsb
    pop edi
    pop esi

    ; Compute descriptor address for slot e1000_tx_cur
    mov eax, [e1000_tx_cur]
    imul eax, E1000_TX_DESC_SIZE
    add eax, E1000_TX_DESC_ADDR
    mov [tx_desc_ptr], eax

    ; Write descriptor: buffer addr (buf_base), length, cmd = EOP|IFCS|RS = 0x0B
    mov edx, [tx_desc_ptr]
    mov [edx + 0], edi          ; buffer addr low
    mov dword [edx + 4], 0      ; buffer addr high
    mov [edx + 8], bx           ; length
    mov byte [edx + 10], 0      ; CSO
    mov byte [edx + 11], 0x0B   ; CMD = EOP | IFCS | RS
    mov byte [edx + 12], 0      ; STATUS = 0 (hardware will set DD when done)
    mov byte [edx + 13], 0      ; CSS
    mov word [edx + 14], 0      ; special

    ; Advance TDT
    inc dword [e1000_tx_cur]
    cmp dword [e1000_tx_cur], E1000_TX_DESC_COUNT
    jb .no_wrap
    mov dword [e1000_tx_cur], 0
.no_wrap:

    mov eax, E1000_TDT
    mov ebx, [e1000_tx_cur]
    call e1000_write

    ; Wait up to ~100 ms for DD bit in descriptor status
    mov ecx, 0x100000
.wait:
    mov edx, [tx_desc_ptr]
    test byte [edx + 12], 0x01
    jnz .sent
    loop .wait

.fail:
    mov esi, str_e1000_tx_bad
    call terminal_append
    call terminal_newline
    popad
    ret

.sent:
    cmp byte [tx_quiet], 0
    jne .silent
    mov esi, str_empty
    call terminal_append
    call terminal_newline
.silent:
    popad
    ret
e1000_print_mac:
    pushad
    cmp dword [e1000_base], 0
    je .none

    mov esi, str_empty
    call terminal_append

    mov ebp, 0
.loop:
    cmp ebp, 6
    jae .done
    movzx eax, byte [e1000_mac + ebp]
    call pci_print_hex_byte
    cmp ebp, 5
    je .no_colon
    mov al, ':'
    mov [pci_scan_buf], al
    mov byte [pci_scan_buf+1], 0
    mov esi, pci_scan_buf
    call terminal_append
.no_colon:
    inc ebp
    jmp .loop
.done:
    call terminal_newline
    popad
    ret

.none:
    mov esi, str_empty
    call terminal_append
    call terminal_newline
    popad
    ret

pci_print_hex_byte:
    pushad
    mov ebx, eax
    mov edi, pci_scan_buf
    mov eax, ebx
    shr eax, 4
    and eax, 0x0F
    cmp al, 10
    jb .d1
    add al, 'A' - 10
    jmp .s1
.d1:
    add al, '0'
.s1:
    mov [edi], al
    mov eax, ebx
    and eax, 0x0F
    cmp al, 10
    jb .d2
    add al, 'A' - 10
    jmp .s2
.d2:
    add al, '0'
.s2:
    mov [edi+1], al
    mov byte [edi+2], 0
    mov esi, pci_scan_buf
    call terminal_append
    popad
    ret
pci_print_hex32:
    pushad
    mov edi, pci_scan_buf
    mov ecx, 8
    mov ebx, eax
.loop:
    rol ebx, 4
    mov eax, ebx
    and eax, 0x0F
    cmp al, 10
    jb .digit
    add al, 'A' - 10
    jmp .store
.digit:
    add al, '0'
.store:
    mov [edi], al
    inc edi
    dec ecx
    jnz .loop
    mov byte [edi], 0
    mov esi, pci_scan_buf
    call terminal_append
    popad
    ret

; Scan all PCI devices, print them to the terminal
pci_scan:
    pushad

    call terminal_newline
    mov esi, str_empty
    call terminal_append
    call terminal_newline

    xor ebp, ebp

.slot_loop:
    cmp ebp, 32
    jae .scan_done

    mov eax, ebp
    shl eax, 11
    call pci_read_config
    mov [pci_vendor], eax
    and eax, 0xFFFF
    cmp eax, 0xFFFF
    je .next_slot

    mov eax, ebp
    shl eax, 11
    call pci_read_config
    shr eax, 16
    mov [pci_device], eax

    mov eax, ebp
    shl eax, 11
    or eax, 0x10
    call pci_read_config
    mov [pci_bar0], eax

    inc dword [pci_found_count]

    ; Line 1: v=XXXX:YYYY
    mov esi, str_empty
    call terminal_append

    mov eax, [pci_vendor]
    and eax, 0xFFFF
    call pci_print_hex32

    mov al, ':'
    mov [pci_scan_buf], al
    mov byte [pci_scan_buf+1], 0
    mov esi, pci_scan_buf
    call terminal_append

    mov eax, [pci_device]
    call pci_print_hex32

    call terminal_newline

    ; Line 2: bar0=XXXXXXXX
    mov esi, str_empty
    call terminal_append

    mov eax, [pci_bar0]
    call pci_print_hex32

    call terminal_newline

    ; e1000 check
    mov eax, [pci_vendor]
    and eax, 0xFFFF
    cmp eax, 0x8086
    jne .next_slot

    mov eax, [pci_device]
    cmp eax, 0x100E
    jne .next_slot

    ; Save BAR0 (mask off low bits — PCI BARs have flag bits)
    mov eax, [pci_bar0]
    and eax, 0xFFFFFFF0
    mov [e1000_base], eax

    ; Enable bus master in PCI command register (offset 4, bit 2)
    mov eax, ebp
    shl eax, 11
    or eax, 4
    call pci_read_config
    mov ebx, eax
    or ebx, 0x04
    mov eax, ebp
    shl eax, 11
    or eax, 4
    call pci_write_config

    mov esi, str_empty
    call terminal_append
    call terminal_newline

.next_slot:
    inc ebp
    jmp .slot_loop

.scan_done:
    cmp dword [pci_found_count], 0
    jne .done
    mov esi, str_empty
    call terminal_append
    call terminal_newline
.done:
    popad
    ret

; =============================================================================
setup_call_table:
    pushad
    mov dword [CALL_TABLE + 0],  draw_rect
    mov dword [CALL_TABLE + 4],  draw_text
    mov dword [CALL_TABLE + 8],  k_set_clip
    mov dword [CALL_TABLE + 12], k_get_window_rect
    mov dword [CALL_TABLE + 16], k_exit
    mov dword [CALL_TABLE + 20], k_get_key
    mov dword [CALL_TABLE + 24], k_get_mouse
    mov dword [CALL_TABLE + 28], k_draw_pixel
    mov dword [CALL_TABLE + 32], k_get_ticks
    mov dword [CALL_TABLE + 36], k_print_debug
    mov dword [CALL_TABLE + 40], k_get_screen_size
    mov dword [CALL_TABLE + 44], k_yield
    mov dword [CALL_TABLE + 48], k_app_id
    mov dword [CALL_TABLE + 52], k_fs_write
    mov dword [CALL_TABLE + 56], k_fs_read
    popad
    ret

k_set_clip:
    mov [clip_x1], eax
    mov [clip_y1], ebx
    mov [clip_x2], ecx
    mov [clip_y2], edx
    ret

k_get_window_rect:
    mov eax, [app_win_x]
    mov [edi], eax
    mov eax, [app_win_y]
    mov [edi+4], eax
    mov eax, [app_win_w]
    mov [edi+8], eax
    mov eax, [app_win_h]
    mov [edi+12], eax
    ret

k_exit:
    mov esp, [kernel_saved_esp]
    jmp app_return_point

k_get_key:
    in al, 0x64
    test al, 1
    jz .none
    test al, 0x20
    jnz .none
    in al, 0x60
    test al, 0x80
    jnz .none
    movzx eax, al
    ret
.none:
    xor eax, eax
    ret

k_get_mouse:
    mov eax, [mouse_x]
    mov [edi], eax
    mov eax, [mouse_y]
    mov [edi+4], eax
    movzx eax, byte [mouse_buttons]
    mov [edi+8], eax
    ret

k_draw_pixel:
    push ebx
    push eax
    cmp eax, [clip_x1]
    jl .done
    cmp eax, [clip_x2]
    jge .done
    cmp ebx, [clip_y1]
    jl .done
    cmp ebx, [clip_y2]
    jge .done
    imul ebx, SCREEN_W
    add ebx, eax
    add ebx, BACKBUF
    mov eax, esi
    mov [ebx], al
.done:
    pop eax
    pop ebx
    ret

k_get_ticks:
    xor eax, eax
    ret

k_print_debug:
    call terminal_append
    ret

k_get_screen_size:
    mov eax, SCREEN_W
    mov [edi], eax
    mov eax, SCREEN_H
    mov [edi+4], eax
    ret

k_yield:
    call blit_screen
    ret

k_app_id:
    xor eax, eax
    ret

k_fs_write:
    call fs_write
    ret

k_fs_read:
    call fs_read
    ret

run_app:
    pushad
    cmp dword [app_count], 0
    je run_app_crash
    mov eax, [run_index]
    cmp eax, [app_count]
    jae run_app_crash
    shl eax, 2
    mov esi, [app_tab + eax]
    test esi, esi
    jz run_app_crash
    mov ecx, [esi + 26]
    add esi, HEADER_SIZE
    mov edi, APP_EXEC
    rep movsb
    mov dword [app_win_x], 0
    mov dword [app_win_y], 0
    mov dword [app_win_w], 320
    mov dword [app_win_h], 180
    mov dword [clip_x1], 0
    mov dword [clip_y1], 0
    mov dword [clip_x2], 320
    mov dword [clip_y2], 180
    mov [kernel_saved_esp], esp
    call APP_EXEC
app_return_point:
    call clip_reset
    mov byte [dirty], 1
    popad
    ret
run_app_crash:
    popad
    mov esi, str_bsod_app
    jmp bsod

bsod:
    mov [bsod_reason], esi
    call clip_reset
    mov eax, 0
    mov ebx, 0
    mov ecx, 320
    mov edx, 200
    mov esi, COLOR_BLUE
    call draw_rect
    mov esi, str_bsod_1
    mov edi, 24
    mov edx, 30
    mov ebx, COLOR_WHITE
    call draw_text
    mov esi, str_bsod_2
    mov edi, 24
    mov edx, 60
    mov ebx, COLOR_LCYAN
    call draw_text
    mov esi, [bsod_reason]
    mov edi, 24
    mov edx, 90
    mov ebx, COLOR_WHITE
    call draw_text
    mov esi, str_bsod_3
    mov edi, 24
    mov edx, 130
    mov ebx, COLOR_GRAY
    call draw_text
    mov esi, str_bsod_4
    mov edi, 24
    mov edx, 150
    mov ebx, COLOR_GRAY
    call draw_text
    call blit_screen
.hang:
    cli
    hlt
    jmp .hang

clip_reset:
    mov dword [clip_x1], 0
    mov dword [clip_y1], 0
    mov dword [clip_x2], SCREEN_W
    mov dword [clip_y2], SCREEN_H
    ret

clear_backbuf:
    pushad
    mov esi, WALLPAPER_RENDERED
    mov edi, BACKBUF
    mov ecx, SCREEN_SIZE / 4
    rep movsd
    popad
    ret

blit_screen:
    pushad
    mov esi, BACKBUF
    mov edi, VGA
    xor ecx, ecx
.row:
    cmp ecx, 200
    jae .done
    mov ebx, ecx
    shl ebx, 1
    imul ebx, 640
    shl ebx, 2
    add ebx, edi
    mov ebp, ebx
    add ebp, 2560
    xor edx, edx
.col:
    cmp edx, 320
    jae .next_row
    mov eax, [esi]
    add esi, 4
    mov [ebx], eax
    mov [ebx+4], eax
    mov [ebp], eax
    mov [ebp+4], eax
    add ebx, 8
    add ebp, 8
    inc edx
    jmp .col
.next_row:
    inc ecx
    jmp .row
.done:
    popad
    ret
; EAX=x, EBX=y, ECX=w, EDX=h, ESI=top color, EDI=bottom color
draw_vgrad:
    pushad
    mov [vg_x], eax
    mov [vg_y], ebx
    mov [vg_w], ecx
    mov [vg_h], edx
    mov [vg_top], esi
    mov [vg_bot], edi

    mov eax, [vg_h]
    shr eax, 1
    mov [vg_mid], eax

    mov eax, [vg_x]
    mov ebx, [vg_y]
    mov ecx, [vg_w]
    mov edx, [vg_mid]
    mov esi, [vg_top]
    call draw_rect

    mov eax, [vg_x]
    mov ebx, [vg_y]
    add ebx, [vg_mid]
    mov ecx, [vg_w]
    mov edx, [vg_h]
    sub edx, [vg_mid]
    mov esi, [vg_bot]
    call draw_rect

    popad
    ret

vg_x:    dd 0
vg_y:    dd 0
vg_w:    dd 0
vg_h:    dd 0
vg_mid:  dd 0
vg_top:  dd 0
vg_bot:  dd 0

draw_rect:
    pushad
    test ecx, ecx
    jz .done
    test edx, edx
    jz .done
    mov edi, [clip_x1]
    cmp eax, edi
    jge .x_ok
    sub edi, eax
    sub ecx, edi
    mov eax, [clip_x1]
.x_ok:
    mov edi, [clip_y1]
    cmp ebx, edi
    jge .y_ok
    sub edi, ebx
    sub edx, edi
    mov ebx, [clip_y1]
.y_ok:
    test ecx, ecx
    jle .done
    test edx, edx
    jle .done
    mov edi, eax
    add edi, ecx
    cmp edi, [clip_x2]
    jle .right_ok
    mov ecx, [clip_x2]
    sub ecx, eax
.right_ok:
    mov edi, ebx
    add edi, edx
    cmp edi, [clip_y2]
    jle .bottom_ok
    mov edx, [clip_y2]
    sub edx, ebx
.bottom_ok:
    test ecx, ecx
    jle .done
    test edx, edx
    jle .done

    mov edi, ebx
    imul edi, SCREEN_W
    add edi, eax
    shl edi, 2
    add edi, BACKBUF

    mov ebp, edx
.yloop:
    push ecx
    push edi
    mov eax, esi
    rep stosd
    pop edi
    pop ecx
    add edi, SCREEN_W * 4
    dec ebp
    jnz .yloop

.done:
    popad
    ret
draw_text:
    push eax
    push ecx
    push edx
    push esi
    push edi
    push ebx
    mov [text_color], ebx
    mov [text_x], edi
    mov [text_y], edx
    mov [text_start_x], edi
.next:
    lodsb
    test al, al
    jz .done
    cmp al, 10
    je .newline
    mov [glyph_char], al
    call draw_char
    add dword [text_x], 8
    jmp .next
.newline:
    mov eax, [text_start_x]
    mov [text_x], eax
    add dword [text_y], 8
    jmp .next
.done:
    pop ebx
    pop edi
    pop esi
    pop edx
    pop ecx
    pop eax
    ret
draw_char:
    pushad
    movzx eax, byte [glyph_char]
    shl eax, 3
    add eax, FONT_BASE
    mov esi, eax
    xor ebp, ebp
.row:
    cmp ebp, 8
    jae .done
    mov al, [esi]
    xor ecx, ecx
.col:
    cmp ecx, 8
    jae .next_row
    test al, 0x80
    jz .skip
    mov edi, [text_x]
    add edi, ecx
    cmp edi, [clip_x1]
    jl .skip
    cmp edi, [clip_x2]
    jge .skip
    mov edx, [text_y]
    add edx, ebp
    cmp edx, [clip_y1]
    jl .skip
    cmp edx, [clip_y2]
    jge .skip
    imul edx, SCREEN_W
    add edi, edx
    shl edi, 2
    add edi, BACKBUF
    mov edx, [text_color]
    mov [edi], edx
.skip:
    shl al, 1
    inc ecx
    jmp .col
.next_row:
    inc esi
    inc ebp
    jmp .row
.done:
    popad
    ret

draw_app_icon:
    pushad
    mov [dai_src], esi
    mov [dai_x], edi
    mov [dai_y], edx
    xor ebp, ebp
.row:
    cmp ebp, 16
    jae .done
    xor ecx, ecx
.col:
    cmp ecx, 16
    jae .next_row
    mov esi, [dai_src]
    mov eax, ebp
    shl eax, 4
    add eax, ecx
    movzx esi, byte [esi + eax]
    test esi, esi
    jz .skip
    mov eax, [dai_x]
    add eax, ecx
    mov ebx, [dai_y]
    add ebx, ebp
    call draw_icon_pixel
.skip:
    inc ecx
    jmp .col
.next_row:
    inc ebp
    jmp .row
.done:
    popad
    ret

draw_icon_pixel:
    pushad
    cmp eax, [clip_x1]
    jl .done
    cmp eax, [clip_x2]
    jge .done
    cmp ebx, [clip_y1]
    jl .done
    cmp ebx, [clip_y2]
    jge .done
    imul ebx, SCREEN_W
    add ebx, eax
    shl ebx, 2
    add ebx, BACKBUF
    mov eax, esi
    and eax, 0xFF
    shl eax, 2
    add eax, VGA_PALETTE_ADDR
    mov eax, [eax]
    mov [ebx], eax
.done:
    popad
    ret
windows_init:
    mov byte [win_order+0], 0
    mov byte [win_order+1], 1
    mov byte [win_order+2], 2
    mov byte [win_order+3], 3
    mov byte [win_order+4], 4
    mov byte [win_order+5], 5
    mov byte [win_order+6], 6
    mov byte [win_order+7], 7
	mov byte [win_order+8], 8
    mov byte [win_order+9], 9
    ret

win_ptr:
    mov eax, ebx
    shl eax, 5
    add eax, win_tab
    ret

raise_window:
    push eax
    push ecx
    push edx
    xor ecx, ecx
.find:
    cmp ecx, MAX_WINDOWS
    jae .done
    movzx eax, byte [win_order + ecx]
    cmp eax, ebx
    je .found
    inc ecx
    jmp .find
.found:
    mov edx, ecx
.shift:
    cmp edx, MAX_WINDOWS - 1
    jae .put_top
    mov al, [win_order + edx + 1]
    mov [win_order + edx], al
    inc edx
    jmp .shift
.put_top:
    mov [win_order + MAX_WINDOWS - 1], bl
    ; Focus change: record when the OLD top window lost focus
    mov eax, [top_win]
    cmp eax, ebx
    je .focus_same
    mov ecx, [pit_ticks]
    mov [win_focus_time + eax*4], ecx
.focus_same:
    mov [top_win], ebx
.done:
    pop edx
    pop ecx
    pop eax
    ret

open_window:
    call win_ptr
    mov dword [eax + WVIS], 1
    mov dword [eax + WAW], 8
    mov dword [eax + WAH], 8
    call raise_window
    mov byte [start_open], 0
    mov byte [dirty], 1
    ret

get_focus_mode:
    push ebx
    mov ebx, [top_win]
    call win_ptr
    mov eax, [eax + WMODE]
    pop ebx
    ret

redraw_all:
    call clip_reset
    call clear_backbuf
    call draw_desktop
    call draw_all_windows
    call clip_reset
    call draw_snap_preview
    call draw_start_menu
    call draw_start_submenu
    call draw_ctx_menu
    call draw_alt_tab
    call draw_cursor
    ret
draw_all_windows:
    pushad
    xor ecx, ecx
.loop:
    cmp ecx, MAX_WINDOWS
    jae .done
    movzx ebx, byte [win_order + ecx]
    call win_ptr
    cmp dword [eax + WVIS], 1
    jb .next
    cmp dword [eax + WVIS], 2
    ja .next
    mov [cur_draw_win_idx], ebx
    push ecx
    call draw_one_window
    pop ecx
.next:
    inc ecx
    jmp .loop
.done:
    popad
    ret

draw_one_window:
    mov ecx, [eax + WX]
    mov [window_x], ecx
    mov ecx, [eax + WY]
    mov [window_y], ecx
    mov ecx, [eax + WAW]
    mov [window_w], ecx
    mov ecx, [eax + WAH]
    mov [window_h], ecx
    mov ecx, [eax + WMODE]
    mov [window_mode], ecx

    ; Clip everything to the window's current bounds.
    mov ecx, [window_x]
    mov [clip_x1], ecx
    mov ecx, [window_y]
    mov [clip_y1], ecx
    mov ecx, [window_x]
    add ecx, [window_w]
    mov [clip_x2], ecx
    mov ecx, [window_y]
    add ecx, [window_h]
    mov [clip_y2], ecx

    mov eax, [window_x]
    add eax, 3
    mov ebx, [window_y]
    add ebx, 3
    mov ecx, [window_w]
    mov edx, [window_h]
    mov esi, COLOR_BLACK
    call draw_rect

    mov eax, [window_x]
    mov ebx, [window_y]
    mov ecx, [window_w]
    mov edx, [window_h]
    mov esi, COLOR_GRAY
    call draw_rect

    mov eax, [window_x]
    mov ebx, [window_y]
    mov ecx, [window_w]
    mov edx, 1
    mov esi, COLOR_WHITE
    call draw_rect

    mov eax, [window_x]
    mov ebx, [window_y]
    mov ecx, 1
    mov edx, [window_h]
    mov esi, COLOR_WHITE
    call draw_rect

    mov eax, [window_x]
    mov ebx, [window_y]
    add ebx, [window_h]
    dec ebx
    mov ecx, [window_w]
    mov edx, 1
    mov esi, COLOR_DGRAY
    call draw_rect

    mov eax, [window_x]
    add eax, [window_w]
    dec eax
    mov ebx, [window_y]
    mov ecx, 1
    mov edx, [window_h]
    mov esi, COLOR_DGRAY
    call draw_rect

    mov eax, [cur_draw_win_idx]
    cmp eax, [top_win]
    jne .titlebar_fading

    mov eax, [window_x]
    add eax, 2
    mov ebx, [window_y]
    add ebx, 2
    mov ecx, [window_w]
    sub ecx, 4
    mov edx, 12
    mov esi, 0x00001A3D
    mov edi, 0x00005588
    call draw_vgrad
    jmp .titlebar_hl
    jmp .titlebar_hl

.titlebar_fading:
    mov eax, [cur_draw_win_idx]
    mov eax, [win_focus_time + eax*4]
    mov ebx, [pit_ticks]
    sub ebx, eax
    cmp ebx, 20000
    jae .titlebar_gray

    mov eax, ebx
    xor edx, edx
    mov ecx, 2000
    div ecx
    mov esi, eax

    mov eax, [window_x]
    add eax, 2
    mov ebx, [window_y]
    add ebx, 2
    mov ecx, [window_w]
    sub ecx, 4
    mov edx, 12
    call draw_titlebar_dither
    jmp .titlebar_hl

.titlebar_gray:
    mov eax, [window_x]
    add eax, 2
    mov ebx, [window_y]
    add ebx, 2
    mov ecx, [window_w]
    sub ecx, 4
    mov edx, 12
    mov esi, COLOR_DGRAY
    call draw_rect

.titlebar_hl:
    mov eax, [window_x]
    add eax, 2
    mov ebx, [window_y]
    add ebx, 2
    mov ecx, [window_w]
    sub ecx, 4
    mov edx, 1
    mov esi, COLOR_LBLUE
    call draw_rect

    mov eax, [window_x]
    add eax, [window_w]
    sub eax, 14
    mov ebx, [window_y]
    add ebx, 4
    mov ecx, 9
    mov edx, 9
    mov esi, COLOR_RED
    call draw_rect

    mov esi, str_x
    mov edi, eax
    add edi, 1
    mov edx, ebx
    mov ebx, COLOR_WHITE
    call draw_text

    mov eax, [window_x]
    add eax, [window_w]
    sub eax, 25
    mov ebx, [window_y]
    add ebx, 4
    mov ecx, 9
    mov edx, 9
    mov esi, COLOR_YELLOW
    call draw_rect

    mov esi, str_min
    mov edi, eax
    add edi, 1
    mov edx, ebx
    add edx, 5
    mov ebx, COLOR_BLACK
    call draw_text

    mov eax, [window_x]
    add eax, 3
    mov ebx, [window_y]
    add ebx, 17
    mov ecx, [window_w]
    sub ecx, 6
    mov edx, [window_h]
    sub edx, 21
    cmp dword [window_mode], APP_NOTEPAD
    je .bg_white
    cmp dword [window_mode], APP_PAINT
    je .bg_white
    mov esi, COLOR_BLACK
    call draw_rect
    jmp .bg_done
.bg_white:
    mov esi, COLOR_WHITE
    call draw_rect
.bg_done:

    mov eax, [window_x]
    add eax, 3
    mov [clip_x1], eax
    mov ebx, [window_y]
    add ebx, 17
    mov [clip_y1], ebx
    mov eax, [window_x]
    add eax, [window_w]
    sub eax, 3
    mov [clip_x2], eax
    mov ebx, [window_y]
    add ebx, [window_h]
    sub ebx, 4
    mov [clip_y2], ebx

    mov eax, [window_mode]
    cmp eax, APP_TERMINAL
    je .terminal
    cmp eax, APP_FILES
    je .files
    cmp eax, APP_BROWSER
    je .browser
    cmp eax, APP_ABOUT
    je .about
    cmp eax, APP_NOTEPAD
    je .notepad
    cmp eax, APP_PAINT
    je .paint
    cmp eax, APP_CALC
    je .calc
    cmp eax, APP_SNAKE
    je .snake
    cmp eax, APP_SETTINGS
    je .settings
    jmp .title
.terminal:
    call draw_terminal
    jmp .title
.files:
    call draw_files
    jmp .title
.browser:
    call draw_browser
    jmp .title
.about:
    call draw_about
    jmp .title
.notepad:
    call draw_notepad
    jmp .title
.paint:
    call draw_paint
    jmp .title
.calc:
    call draw_calc
    jmp .title
.snake:
    call draw_snake
    jmp .title
.settings:
    call draw_settings
    jmp .title

.title:
    mov ecx, [window_x]
    mov [clip_x1], ecx
    mov ecx, [window_y]
    mov [clip_y1], ecx
    mov ecx, [window_x]
    add ecx, [window_w]
    mov [clip_x2], ecx
    mov ecx, [window_y]
    add ecx, [window_h]
    mov [clip_y2], ecx
    mov esi, str_title_terminal
    mov eax, [window_mode]
    cmp eax, APP_FILES
    jne .t1
    mov esi, str_title_files
    jmp .tdraw
.t1:
    cmp eax, APP_BROWSER
    jne .t2
    mov esi, str_title_browser
    jmp .tdraw
.t2:
    cmp eax, APP_ABOUT
    jne .t3
    mov esi, str_title_about
    jmp .tdraw
.t3:
    cmp eax, APP_NOTEPAD
    jne .t4
    mov esi, str_title_notepad
    jmp .tdraw
.t4:
    cmp eax, APP_CALC
    jne .t5
    mov esi, str_title_calc
    jmp .tdraw
.t5:
    cmp eax, APP_SNAKE
    jne .t6
    mov esi, str_title_snake
    jmp .tdraw
.t5b:
    cmp eax, APP_PAINT
    jne .t6
    mov esi, str_title_paint
    jmp .tdraw
.t6:
    cmp eax, APP_SETTINGS
    jne .tdraw
    mov esi, str_title_settings
.tdraw:
    mov edi, [window_x]
    add edi, 8
    mov edx, [window_y]
    add edx, 5
    mov ebx, COLOR_WHITE
    call draw_text
    ret

draw_desktop:
    mov eax, 0
    mov ebx, 0
    mov ecx, 320
    mov edx, 4
    mov esi, COLOR_BLUE
    call draw_rect
    mov eax, 0
    mov ebx, 8
    mov ecx, 320
    mov edx, 1
    mov esi, COLOR_BLUE
    call draw_rect

    mov ecx, 0
    call draw_icon_hover
    call draw_terminal_icon
    mov ecx, 1
    call draw_icon_hover
    call draw_files_icon
    mov ecx, 2
    call draw_icon_hover
    call draw_browser_icon
    mov ecx, 3
    call draw_icon_hover
    call draw_about_icon
    mov ecx, 4
    call draw_icon_hover
    call draw_notepad_icon
    mov ecx, 5
    call draw_icon_hover
    call draw_paint_icon
    mov ecx, 6
    call draw_icon_hover
    call draw_calc_icon
    mov ecx, 7
    call draw_icon_hover
    pushad
    mov edi, [icon_x + 28]
    mov edx, [icon_y + 28]
    mov esi, icon_snake
    call draw_app_icon
    mov edi, [icon_x + 28]
    sub edi, 16
    mov edx, [icon_y + 28]
    add edx, 20
    mov esi, str_icon_snake
    mov ebx, COLOR_BLACK
    call draw_text
    popad

    call draw_app_icons
    call draw_snake_icon
    mov eax, 0
    mov ebx, 180
    mov ecx, 320
    mov edx, 20
    mov esi, COLOR_DGRAY
    call draw_rect
    mov eax, 0
    mov ebx, 180
    mov ecx, 320
    mov edx, 1
    mov esi, COLOR_WHITE
    call draw_rect
    mov eax, 4
    mov ebx, 184
    mov ecx, 58
    mov edx, 12
    mov esi, COLOR_BLUE
    call draw_rect
    mov esi, str_start
    mov edi, 10
    mov edx, 186
    mov ebx, COLOR_WHITE
    call draw_text
    call draw_taskbar_buttons
    call rtc_update
    mov esi, date_str
    mov edi, 222
    mov edx, 186
    mov ebx, COLOR_WHITE
    call draw_text
    mov esi, clock_str
    mov edi, 274
    mov edx, 186
    mov ebx, COLOR_WHITE
    call draw_text
    ret

draw_taskbar_buttons:
    pushad

    ; --- Count visible windows ---
    mov dword [tb_vis_count], 0
    xor ebp, ebp
.count_loop:
    cmp ebp, MAX_WINDOWS
    jae .count_done
    movzx ebx, byte [win_order + ebp]
    call win_ptr
    cmp dword [eax + WVIS], 0
    je .count_next
    cmp dword [eax + WVIS], 2
    je .count_next
    inc dword [tb_vis_count]
.count_next:
    inc ebp
    jmp .count_loop
.count_done:
    cmp dword [tb_vis_count], 0
    je .done

    ; --- Compute pitch and width from count ---
    ; Available: x=66 to x=214 = 148 pixels (leaves 8px gap before date)
    mov eax, 148
    xor edx, edx
    mov ecx, [tb_vis_count]
    div ecx
    mov [tb_pitch], eax
    ; Clamp pitch to <= 44
    cmp dword [tb_pitch], 44
    jbe .pitch_capped
    mov dword [tb_pitch], 44
.pitch_capped:
    ; width = pitch - 4
    mov eax, [tb_pitch]
    sub eax, 4
    cmp eax, 14
    jge .width_ok
    mov eax, 14
.width_ok:
    mov [tb_width], eax
    ; Recompute pitch = width + 4
    add eax, 4
    mov [tb_pitch], eax

    ; --- Draw loop ---
    mov dword [tb_slot], 0
    xor ebp, ebp
.loop:
    cmp ebp, MAX_WINDOWS
    jae .done
    movzx ebx, byte [win_order + ebp]
    call win_ptr
    cmp dword [eax + WVIS], 0
    je .next
    cmp dword [eax + WVIS], 2
    je .next

    mov ecx, [eax + WMODE]
    mov [tb_mode], ecx
    mov [tb_win_idx], ebx

    mov eax, [tb_slot]
    imul eax, [tb_pitch]
    add eax, 66
    mov [tb_x], eax

    ; Hover detection
    mov dword [tb_hover], 0
    mov eax, [mouse_x]
    mov ecx, [tb_x]
    cmp eax, ecx
    jl .no_hover
    add ecx, [tb_width]
    cmp eax, ecx
    jg .no_hover
    mov eax, [mouse_y]
    cmp eax, 180
    jl .no_hover
    cmp eax, 200
    jg .no_hover
    mov dword [tb_hover], 1
.no_hover:

    ; Background
    mov esi, COLOR_BLUE
    cmp dword [tb_hover], 0
    je .bg_pick
    mov esi, COLOR_LBLUE
.bg_pick:
    mov eax, [tb_x]
    mov ebx, 184
    mov ecx, [tb_width]
    mov edx, 12
    call draw_rect

    ; Top + left highlight
    mov eax, [tb_x]
    mov ebx, 184
    mov ecx, [tb_width]
    mov edx, 1
    mov esi, COLOR_WHITE
    call draw_rect

    mov eax, [tb_x]
    mov ebx, 184
    mov ecx, 1
    mov edx, 12
    mov esi, COLOR_WHITE
    call draw_rect

    ; Bottom + right shadow
    mov eax, [tb_x]
    mov ebx, 195
    mov ecx, [tb_width]
    mov edx, 1
    mov esi, COLOR_DGRAY
    call draw_rect

    mov eax, [tb_x]
    add eax, [tb_width]
    dec eax
    mov ebx, 184
    mov ecx, 1
    mov edx, 12
    mov esi, COLOR_DGRAY
    call draw_rect

    ; --- Label with dynamic length ---
    mov eax, [tb_width]
    mov dword [tb_lbl_len], 4
    cmp eax, 36
    jge .len_done
    mov dword [tb_lbl_len], 3
    cmp eax, 28
    jge .len_done
    mov dword [tb_lbl_len], 2
    cmp eax, 20
    jge .len_done
    mov dword [tb_lbl_len], 1
.len_done:

    ; Source label pointer
    mov eax, [tb_mode]
    cmp eax, 10
    jb .mode_ok
    xor eax, eax
.mode_ok:
    imul eax, 5
    add eax, tb_labels
    mov esi, eax

    ; Copy tb_lbl_len chars into scratch buffer
    mov edi, tb_label_scratch
    mov ecx, [tb_lbl_len]
.copy:
    lodsb
    test al, al
    jz .copy_end
    stosb
    dec ecx
    jnz .copy
.copy_end:
    mov byte [edi], 0

    ; Center x
    mov eax, [tb_lbl_len]
    shl eax, 3
    mov ecx, [tb_width]
    sub ecx, eax
    sar ecx, 1
    mov edi, [tb_x]
    add edi, ecx
    cmp edi, [tb_x]
    jge .pos_ok
    mov edi, [tb_x]
.pos_ok:
    mov esi, tb_label_scratch
    mov edx, 186
    mov ebx, COLOR_WHITE
    call draw_text

    ; Active-window indicator bar
    mov eax, [tb_win_idx]
    cmp eax, [top_win]
    jne .no_active
    mov eax, [tb_x]
    mov ebx, 193
    mov ecx, [tb_width]
    mov edx, 2
    mov esi, COLOR_YELLOW
    call draw_rect
.no_active:

    inc dword [tb_slot]
.next:
    inc ebp
    jmp .loop
.done:
    popad
    ret
draw_icon_hover:
    pushad
    mov [hov_slot], ecx
    mov eax, [icon_x + ecx*4]
    mov ebx, [icon_y + ecx*4]
    mov edx, [mouse_x]
    cmp edx, eax
    jl .done
    add eax, 16
    cmp edx, eax
    jg .done
    mov edx, [mouse_y]
    cmp edx, ebx
    jl .done
    add ebx, 16
    cmp edx, ebx
    jg .done

    ; Top edge
    mov ecx, [hov_slot]
    mov eax, [icon_x + ecx*4]
    sub eax, 2
    mov ebx, [icon_y + ecx*4]
    sub ebx, 2
    mov ecx, 20
    mov edx, 1
    mov esi, COLOR_WHITE
    call draw_rect

    ; Bottom edge
    mov ecx, [hov_slot]
    mov eax, [icon_x + ecx*4]
    sub eax, 2
    mov ebx, [icon_y + ecx*4]
    add ebx, 17
    mov ecx, 20
    mov edx, 1
    mov esi, COLOR_WHITE
    call draw_rect

    ; Left edge
    mov ecx, [hov_slot]
    mov eax, [icon_x + ecx*4]
    sub eax, 2
    mov ebx, [icon_y + ecx*4]
    sub ebx, 2
    mov ecx, 1
    mov edx, 20
    mov esi, COLOR_WHITE
    call draw_rect

    ; Right edge
    mov ecx, [hov_slot]
    mov eax, [icon_x + ecx*4]
    add eax, 17
    mov ebx, [icon_y + ecx*4]
    sub ebx, 2
    mov ecx, 1
    mov edx, 20
    mov esi, COLOR_WHITE
    call draw_rect

.done:
    popad
    ret

draw_app_icons:
    pushad
    cmp dword [app_count], 0
    je .done
    xor ecx, ecx
.loop:
    cmp ecx, [app_count]
    jae .done
    cmp ecx, 3
    jae .done
    mov [dai_idx], ecx
    mov eax, [app_tab + ecx*4]
    mov [dai_hdr], eax
    mov edx, ecx
    imul edx, 70
    add edx, 156
    mov [dai_cellx], edx
    mov edi, edx
    add edi, 19
    mov edx, 140
    mov eax, [dai_hdr]
    add eax, ICON_OFFSET
    mov esi, eax
    call draw_app_icon
    mov edi, [dai_cellx]
    sub edi, 4
    mov edx, 160
    mov eax, [dai_hdr]
    add eax, 4
    mov esi, eax
    mov ebx, COLOR_BLACK
    call draw_text
    mov ecx, [dai_idx]
    inc ecx
    jmp .loop
.done:
    popad
    ret

draw_terminal_icon:
    mov edi, [icon_x + 0]
    mov edx, [icon_y + 0]
    mov esi, icon_terminal
    call draw_app_icon
    mov edi, [icon_x + 0]
    sub edi, 17
    mov edx, [icon_y + 0]
    add edx, 20
    mov esi, str_icon_terminal
    mov ebx, COLOR_BLACK
    call draw_text
    ret

draw_files_icon:
    mov edi, [icon_x + 4]
    mov edx, [icon_y + 4]
    mov esi, icon_files
    call draw_app_icon
    mov edi, [icon_x + 4]
    sub edi, 9
    mov edx, [icon_y + 4]
    add edx, 20
    mov esi, str_icon_files
    mov ebx, COLOR_BLACK
    call draw_text
    ret

draw_browser_icon:
    mov edi, [icon_x + 8]
    mov edx, [icon_y + 8]
    mov esi, icon_browser
    call draw_app_icon
    mov edi, [icon_x + 8]
    sub edi, 17
    mov edx, [icon_y + 8]
    add edx, 20
    mov esi, str_icon_browser
    mov ebx, COLOR_BLACK
    call draw_text
    ret

draw_about_icon:
    mov edi, [icon_x + 12]
    mov edx, [icon_y + 12]
    mov esi, icon_about
    call draw_app_icon
    mov edi, [icon_x + 12]
    sub edi, 17
    mov edx, [icon_y + 12]
    add edx, 20
    mov esi, str_icon_about
    mov ebx, COLOR_BLACK
    call draw_text
    ret

draw_notepad_icon:
    mov edi, [icon_x + 16]
    mov edx, [icon_y + 16]
    mov esi, icon_notepad
    call draw_app_icon
    mov edi, [icon_x + 16]
    sub edi, 16
    mov edx, [icon_y + 16]
    add edx, 20
    mov esi, str_icon_notepad
    mov ebx, COLOR_BLACK
    call draw_text
    ret

draw_terminal:
    mov esi, str_welcome_1
    mov edi, [window_x]
    add edi, 8
    mov edx, [window_y]
    add edx, 26
    mov ebx, COLOR_LGREEN
    call draw_text
    mov esi, str_welcome_2
    mov edi, [window_x]
    add edi, 8
    mov edx, [window_y]
    add edx, 34
    mov ebx, COLOR_GRAY
    call draw_text
    xor ecx, ecx
    mov eax, [term_rows]
    sub eax, 9
    sub eax, [term_view]
    jns .s1
    xor eax, eax
.s1:
    mov [term_draw_start], eax

    xor ecx, ecx
.line:
    cmp ecx, 9
    jae .prompt
    mov eax, [term_draw_start]
    add eax, ecx
    cmp eax, [term_rows]
    jae .blank_row
    shl eax, 5
    add eax, terminal_buffer
    mov esi, eax
    mov edi, [window_x]
    add edi, 8
    mov eax, ecx
    imul eax, 9
    add eax, [window_y]
    add eax, 50
    mov edx, eax
    mov ebx, COLOR_WHITE
    call draw_text
    jmp .next_row
.blank_row:
    mov esi, str_blank_row
    mov edi, [window_x]
    add edi, 8
    mov eax, ecx
    imul eax, 9
    add eax, [window_y]
    add eax, 50
    mov edx, eax
    mov ebx, COLOR_BLACK
    call draw_text
.next_row:
    inc ecx
    jmp .line
.prompt:
    mov esi, str_prompt
    mov edi, [window_x]
    add edi, 8
    mov edx, [window_y]
    add edx, 134
    mov ebx, COLOR_LGREEN
    call draw_text
    mov esi, input_buf
    mov edi, [window_x]
    add edi, 16
    mov edx, [window_y]
    add edx, 134
    mov ebx, COLOR_WHITE
    call draw_text

    cmp byte [cursor_on], 0
    je .no_cursor
    mov eax, [input_len]
    shl eax, 3
    add eax, [window_x]
    add eax, 16
    mov [text_x], eax
    mov eax, [window_y]
    add eax, 134
    mov [text_y], eax
    mov byte [glyph_char], '|'
    mov byte [text_color], COLOR_LGREEN
    call draw_char
.no_cursor:
    ret

draw_files:
    mov esi, str_files_header
    mov edi, [window_x]
    add edi, 8
    mov edx, [window_y]
    add edx, 25
    mov ebx, COLOR_LCYAN
    call draw_text
    xor ebp, ebp
    xor ecx, ecx
.loop:
    cmp ebp, MAX_FILES
    jae .done
    cmp byte [fs_used + ebp], 0
    je .next
    mov esi, ebp
    imul esi, FS_NAME_LEN
    add esi, fs_names
    mov edi, [window_x]
    add edi, 8
    mov edx, [window_y]
    add edx, 42
    mov eax, ecx
    imul eax, 16
    add edx, eax
    mov ebx, COLOR_WHITE
    call draw_text
    inc ecx
.next:
    inc ebp
    jmp .loop
.done:
    test ecx, ecx
    jnz .ret
    mov esi, str_files_empty
    mov edi, [window_x]
    add edi, 8
    mov edx, [window_y]
    add edx, 42
    mov ebx, COLOR_GRAY
    call draw_text
.ret:
    ret

draw_browser:
    cmp dword [tcp_data_len], 0
    je .nothing

    ; Skip HTTP headers: find \r\n\r\n
    mov esi, tcp_data_buf
    mov ecx, [tcp_data_len]
.find_blank:
    cmp ecx, 4
    jb .raw
    cmp byte [esi], 13
    jne .adv
    cmp byte [esi + 1], 10
    jne .adv
    cmp byte [esi + 2], 13
    jne .adv
    cmp byte [esi + 3], 10
    jne .adv
    add esi, 4
    sub ecx, 4
    jmp .render
.adv:
    inc esi
    dec ecx
    jmp .find_blank

.raw:
    mov esi, tcp_data_buf
    mov ecx, [tcp_data_len]

.render:
    ; Strip HTML tags, draw text
    mov edi, [window_x]
    add edi, 6
    mov edx, [window_y]
    add edx, 22
    mov [text_x], edi
    mov [text_y], edx
    mov [text_start_x], edi
    mov [text_color], COLOR_BLACK
    mov ebx, COLOR_BLACK

.loop:
    test ecx, ecx
    jz .done
    lodsb
    dec ecx
    cmp al, '<'
    je .skip_tag
    cmp al, 10
    je .newline
    cmp al, 13
    je .loop
    cmp al, '&'
    je .entity
    mov [glyph_char], al
    mov byte [text_color], COLOR_BLACK
    call draw_char
    add dword [text_x], 8
    ; Wrap
    mov eax, [text_x]
    mov edx, [window_x]
    add edx, [window_w]
    sub edx, 14
    cmp eax, edx
    jl .loop
    mov eax, [text_start_x]
    mov [text_x], eax
    add dword [text_y], 8
    jmp .loop

.newline:
    mov eax, [text_start_x]
    mov [text_x], eax
    add dword [text_y], 8
    jmp .loop

.skip_tag:
    cmp al, '>'
    je .loop
    lodsb
    dec ecx
    test ecx, ecx
    jnz .skip_tag
    jmp .done

.entity:
    ; Skip &...; for now, just print a space
    mov al, ' '
    mov [glyph_char], al
    call draw_char
    add dword [text_x], 8
.skip_ent:
    test ecx, ecx
    jz .done
    lodsb
    dec ecx
    cmp al, ';'
    jne .skip_ent
    jmp .loop

.done:
    ret

.nothing:
    mov esi, browser_title
    mov edi, [window_x]
    add edi, 24
    mov edx, [window_y]
    add edx, 56
    mov ebx, COLOR_LCYAN
    call draw_text
    mov esi, browser_line1
    mov edi, [window_x]
    add edi, 24
    mov edx, [window_y]
    add edx, 78
    mov ebx, COLOR_WHITE
    call draw_text
    mov esi, browser_line2
    mov edi, [window_x]
    add edi, 24
    mov edx, [window_y]
    add edx, 94
    mov ebx, COLOR_GRAY
    call draw_text
    ret
draw_about:
    mov esi, str_about_title
    mov edi, [window_x]
    add edi, 18
    mov edx, [window_y]
    add edx, 34
    mov ebx, COLOR_LCYAN
    call draw_text
    mov esi, str_about_1
    mov edi, [window_x]
    add edi, 18
    mov edx, [window_y]
    add edx, 52
    mov ebx, COLOR_WHITE
    call draw_text
    mov esi, str_about_2
    mov edi, [window_x]
    add edi, 18
    mov edx, [window_y]
    add edx, 68
    mov ebx, COLOR_WHITE
    call draw_text
    mov esi, str_about_3
    mov edi, [window_x]
    add edi, 18
    mov edx, [window_y]
    add edx, 84
    mov ebx, COLOR_WHITE
    call draw_text
    mov esi, str_about_4
    mov edi, [window_x]
    add edi, 18
    mov edx, [window_y]
    add edx, 100
    mov ebx, COLOR_GRAY
    call draw_text
    ret

draw_notepad:
    mov eax, [window_x]
    add eax, 3
    mov ebx, [window_y]
    add ebx, 17
    mov ecx, [window_w]
    sub ecx, 6
    mov edx, 11
    mov esi, COLOR_GRAY
    call draw_rect
    mov esi, str_np_file
    mov edi, [window_x]
    add edi, 6
    mov edx, [window_y]
    add edx, 19
    mov ebx, COLOR_BLACK
    call draw_text
    mov esi, np_filename
    mov edi, [window_x]
    add edi, [window_w]
    sub edi, 110
    mov edx, [window_y]
    add edx, 19
    mov ebx, COLOR_BLACK
    call draw_text
    cmp byte [np_menu_open], 0
    je .no_menu
    mov eax, [window_x]
    add eax, 3
    mov ebx, [window_y]
    add ebx, 28
    mov ecx, 54
    mov edx, 36
    mov esi, COLOR_WHITE
    call draw_rect
    mov eax, [window_x]
    add eax, 3
    mov ebx, [window_y]
    add ebx, 28
    mov ecx, 54
    mov edx, 1
    mov esi, COLOR_BLACK
    call draw_rect
    mov eax, [window_x]
    add eax, 3
    mov ebx, [window_y]
    add ebx, 28
    mov ecx, 1
    mov edx, 36
    mov esi, COLOR_BLACK
    call draw_rect
    mov eax, [window_x]
    add eax, 3
    mov ebx, [window_y]
    add ebx, 63
    mov ecx, 54
    mov edx, 1
    mov esi, COLOR_BLACK
    call draw_rect
    mov esi, str_np_new
    mov edi, [window_x]
    add edi, 6
    mov edx, [window_y]
    add edx, 30
    mov ebx, COLOR_BLACK
    call draw_text
    mov esi, str_np_save
    mov edi, [window_x]
    add edi, 6
    mov edx, [window_y]
    add edx, 42
    mov ebx, COLOR_BLACK
    call draw_text
    mov esi, str_np_saveas
    mov edi, [window_x]
    add edi, 6
    mov edx, [window_y]
    add edx, 54
    mov ebx, COLOR_BLACK
    call draw_text
.no_menu:
    mov esi, notepad_buf
    mov edi, [window_x]
    add edi, 8
    mov edx, [window_y]
    add edx, 34
    mov ebx, COLOR_BLACK
    mov [text_color], ebx
    mov [text_x], edi
    mov [text_y], edx
    mov [text_start_x], edi
    xor ebp, ebp
.loop:
    cmp ebp, [notepad_len]
    jae .done
    movzx eax, byte [notepad_buf + ebp]
    cmp al, 10
    je .nl
    mov ecx, [text_x]
    sub ecx, [window_x]
    mov edx, [window_w]
    sub edx, 12
    cmp ecx, edx
    jl .no_wrap
    mov eax, [text_start_x]
    mov [text_x], eax
    add dword [text_y], 8
.no_wrap:
    mov [glyph_char], al
    call draw_char
    add dword [text_x], 8
    inc ebp
    jmp .loop
.nl:
    mov eax, [text_start_x]
    mov [text_x], eax
    add dword [text_y], 8
    inc ebp
    jmp .loop
.done:
    cmp byte [cursor_on], 0
    je .no_cur
    mov byte [glyph_char], '|'
    mov byte [text_color], COLOR_BLACK
    call draw_char
.no_cur:
    cmp byte [np_saveas_mode], 0
    je .no_dialog
    mov eax, [window_x]
    add eax, 40
    mov ebx, [window_y]
    add ebx, 60
    mov ecx, 180
    mov edx, 44
    mov esi, COLOR_WHITE
    call draw_rect
    mov eax, [window_x]
    add eax, 40
    mov ebx, [window_y]
    add ebx, 60
    mov ecx, 180
    mov edx, 1
    mov esi, COLOR_BLACK
    call draw_rect
    mov eax, [window_x]
    add eax, 40
    mov ebx, [window_y]
    add ebx, 103
    mov ecx, 180
    mov edx, 1
    mov esi, COLOR_BLACK
    call draw_rect
    mov eax, [window_x]
    add eax, 40
    mov ebx, [window_y]
    add ebx, 60
    mov ecx, 1
    mov edx, 44
    mov esi, COLOR_BLACK
    call draw_rect
    mov eax, [window_x]
    add eax, 219
    mov ebx, [window_y]
    add ebx, 60
    mov ecx, 1
    mov edx, 44
    mov esi, COLOR_BLACK
    call draw_rect
    mov esi, str_np_saveas_prompt
    mov edi, [window_x]
    add edi, 46
    mov edx, [window_y]
    add edx, 68
    mov ebx, COLOR_BLACK
    call draw_text
    mov eax, [window_x]
    add eax, 46
    mov ebx, [window_y]
    add ebx, 82
    mov ecx, 168
    mov edx, 12
    mov esi, COLOR_GRAY
    call draw_rect
    mov esi, np_saveas_buf
    mov edi, [window_x]
    add edi, 50
    mov edx, [window_y]
    add edx, 84
    mov ebx, COLOR_BLACK
    call draw_text
.no_dialog:
    mov esi, str_notepad_hint
    mov edi, [window_x]
    add edi, 8
    mov edx, [window_y]
    add edx, [window_h]
    sub edx, 14
    mov ebx, COLOR_GRAY
    call draw_text
    ret

draw_start_menu:
    cmp dword [start_anim_w], 0
    je .done

    push dword [clip_x1]
    push dword [clip_y1]
    push dword [clip_x2]
    push dword [clip_y2]

    mov dword [clip_x1], 0
    mov eax, 176
    sub eax, [start_anim_w]
    mov [clip_y1], eax
    mov dword [clip_x2], 320
    mov dword [clip_y2], 200

    mov eax, 2
    mov ebx, 60
    mov ecx, 134
    mov edx, 116
    mov esi, COLOR_WHITE
    call draw_rect

    mov eax, 4
    mov ebx, 62
    mov ecx, 130
    mov edx, 112
    mov esi, COLOR_DGRAY
    call draw_rect

    mov esi, menu_terminal
    mov edi, 10
    mov edx, 68
    mov ebx, COLOR_WHITE
    call draw_text

    mov esi, menu_files
    mov edi, 10
    mov edx, 84
    call draw_text

    mov esi, menu_browser
    mov edi, 10
    mov edx, 100
    call draw_text

    mov esi, menu_notepad
    mov edi, 10
    mov edx, 116
    call draw_text

    mov esi, menu_about
    mov edi, 10
    mov edx, 132
    call draw_text

    mov esi, menu_settings
    mov edi, 10
    mov edx, 148
    call draw_text

    cmp byte [sm_sub_hover], 0
    je .no_hl
    mov eax, 4
    mov ebx, 160
    mov ecx, 130
    mov edx, 14
    mov esi, COLOR_BLUE
    call draw_rect
.no_hl:
    mov esi, menu_shutdown
    mov edi, 10
    mov edx, 164
    mov ebx, COLOR_LRED
    call draw_text

    pop dword [clip_y2]
    pop dword [clip_x2]
    pop dword [clip_y1]
    pop dword [clip_x1]

.done:
    ret
draw_start_submenu:
    cmp byte [start_open], 1
    jne .done
    cmp dword [sm_sub_anim], 0
    je .done

    push dword [clip_x1]
    push dword [clip_y1]
    push dword [clip_x2]
    push dword [clip_y2]

    mov dword [clip_x1], 136
    mov dword [clip_y1], 0
    mov eax, 136
    add eax, [sm_sub_anim]
    mov [clip_x2], eax
    mov dword [clip_y2], 200

    mov eax, 136
    mov ebx, 144
    mov ecx, 80
    mov edx, 34
    mov esi, COLOR_WHITE
    call draw_rect

    mov eax, 138
    mov ebx, 146
    mov ecx, 76
    mov edx, 30
    mov esi, COLOR_DGRAY
    call draw_rect

    mov esi, menu_restart
    mov edi, 142
    mov edx, 148
    mov ebx, COLOR_WHITE
    call draw_text

    mov esi, menu_sleep
    mov edi, 142
    mov edx, 164
    mov ebx, COLOR_WHITE
    call draw_text

    pop dword [clip_y2]
    pop dword [clip_x2]
    pop dword [clip_y1]
    pop dword [clip_x1]
.done:
    ret
paint_plot_pixel:
    pushad
    mov [paint_tx], eax
    mov [paint_ty], ebx
    mov [paint_tc], esi
    xor ebp, ebp
.yloop:
    cmp ebp, 3
    jge .done
    xor ecx, ecx
.xloop:
    cmp ecx, 3
    jge .next_row
    mov eax, [paint_tx]
    add eax, ecx
    sub eax, 1
    mov ebx, [paint_ty]
    add ebx, ebp
    sub ebx, 1
    cmp eax, 0
    jl .skip
    cmp eax, PAINT_W
    jge .skip
    cmp ebx, 0
    jl .skip
    cmp ebx, PAINT_H
    jge .skip
    imul ebx, PAINT_W
    add ebx, eax
    add ebx, PAINT_BUF
    mov eax, [paint_tc]
    mov [ebx], al
.skip:
    inc ecx
    jmp .xloop
.next_row:
    inc ebp
    jmp .yloop
.done:
    popad
    ret

paint_get_win_coords:
    push ebx
    mov ebx, MAX_WINDOWS - 1
    call win_ptr
    mov ecx, [eax + WX]
    mov [paint_win_x], ecx
    mov ecx, [eax + WY]
    mov [paint_win_y], ecx
    pop ebx
    ret

paint_stroke:
    pushad
    call paint_get_win_coords
    mov eax, [mouse_x]
    sub eax, [paint_win_x]
    sub eax, 3
    mov ebx, [mouse_y]
    sub ebx, [paint_win_y]
    sub ebx, 29
    mov esi, [paint_curr_color]
    call paint_plot_pixel
    popad
    ret

paint_click:
    pushad
    mov ecx, [eax + WX]
    mov [window_x], ecx
    mov ecx, [eax + WY]
    mov [window_y], ecx
    mov edi, [mouse_x]
    sub edi, [window_x]
    mov edx, [mouse_y]
    sub edx, [window_y]
    cmp edi, 3
    jl .done
    cmp edi, 243
    jge .check_canvas
    cmp edx, 17
    jl .done
    cmp edx, 28
    jge .check_canvas
    mov eax, edi
    sub eax, 3
    xor edx, edx
    mov ecx, 15
    div ecx
    mov [paint_curr_color], eax
    mov byte [dirty], 1
    jmp .done
.check_canvas:
    cmp edx, 29
    jl .done
    cmp edx, 149
    jge .done
    mov eax, edi
    sub eax, 3
    mov ebx, edx
    sub ebx, 29
    mov esi, [paint_curr_color]
    call paint_plot_pixel
    mov byte [paint_drawing], 1
    mov byte [dirty], 1
.done:
    popad
    ret

draw_paint:
    xor ebp, ebp
.pal_loop:
    cmp ebp, 16
    jae .pal_done
    mov eax, ebp
    imul eax, 15
    add eax, [window_x]
    add eax, 3
    mov ebx, [window_y]
    add ebx, 17
    mov ecx, 15
    mov edx, 11
    mov esi, [paint_curr_color]
    cmp ebp, esi
    jne .pal_use
    mov esi, 0xFFFFFF
    jmp .pal_draw
.pal_use:
    mov esi, ebp
    shl esi, 2
    add esi, VGA_PALETTE_ADDR
    mov esi, [esi]
.pal_draw:
    call draw_rect
    inc ebp
    jmp .pal_loop
.pal_done:

    ; current color swatch
    mov eax, [window_x]
    add eax, [window_w]
    sub eax, 22
    mov ebx, [window_y]
    add ebx, 17
    mov ecx, 16
    mov edx, 11
    mov esi, [paint_curr_color]
    shl esi, 2
    add esi, VGA_PALETTE_ADDR
    mov esi, [esi]
    call draw_rect

    ; canvas
    xor ecx, ecx
.row_loop:
    cmp ecx, PAINT_H
    jae .canvas_done
    mov edx, [window_y]
    add edx, 29
    add edx, ecx
    cmp edx, [clip_y1]
    jl .next_row
    cmp edx, [clip_y2]
    jge .next_row
    mov esi, PAINT_BUF
    mov eax, ecx
    imul eax, PAINT_W
    add esi, eax
    xor edi, edi
.col_loop:
    cmp edi, PAINT_W
    jae .next_row
    mov eax, [window_x]
    add eax, 3
    add eax, edi
    cmp eax, [clip_x1]
    jl .skip_px
    cmp eax, [clip_x2]
    jge .skip_px
    mov ebx, edx
    imul ebx, SCREEN_W
    add ebx, eax
    shl ebx, 2
    add ebx, BACKBUF
    movzx eax, byte [esi + edi]
    shl eax, 2
    add eax, VGA_PALETTE_ADDR
    mov eax, [eax]
    mov [ebx], eax
.skip_px:
    inc edi
    jmp .col_loop
.next_row:
    inc ecx
    jmp .row_loop
.canvas_done:
    ret
draw_paint_icon:
    mov edi, [icon_x + 20]
    mov edx, [icon_y + 20]
    mov esi, icon_paint
    call draw_app_icon
    mov edi, [icon_x + 20]
    sub edi, 16
    mov edx, [icon_y + 20]
    add edx, 20
    mov esi, str_icon_paint
    mov bl, COLOR_BLACK
    call draw_text
    ret
; =============================================================
; CALCULATOR
; =============================================================

calc_clear:
    pushad
    mov edi, calc_display
    mov ecx, 16
    xor eax, eax
    rep stosb
    mov byte [calc_display], '0'
    mov dword [calc_display_len], 1
    mov dword [calc_acc], 0
    mov byte [calc_op], 0
    mov byte [calc_new], 0
    mov byte [calc_error], 0
    popad
    ret

; EAX = value -> display string
calc_show:
    pushad
    test eax, eax
    jnz .nz
    mov byte [calc_display], '0'
    mov byte [calc_display+1], 0
    mov dword [calc_display_len], 1
    popad
    ret
.nz:
    mov edi, calc_display
    call format_u32
    mov esi, calc_display
    xor ecx, ecx
.len:
    cmp byte [esi], 0
    je .done
    inc esi
    inc ecx
    jmp .len
.done:
    mov [calc_display_len], ecx
    popad
    ret

; returns parsed value of calc_display in EAX
calc_parse:
    push ebx
    push esi
    mov esi, calc_display
    xor eax, eax
.loop:
    movzx ebx, byte [esi]
    test bl, bl
    jz .done
    cmp bl, '0'
    jb .done
    cmp bl, '9'
    ja .done
    imul eax, 10
    sub bl, '0'
    movzx ebx, bl
    add eax, ebx
    inc esi
    jmp .loop
.done:
    pop esi
    pop ebx
    ret

; AL = digit char
calc_append_digit:
    push eax
    push ebx
    push ecx
    push edi
    mov bl, al
    cmp byte [calc_new], 0
    je .no_reset
    mov byte [calc_new], 0
    mov edi, calc_display
    mov ecx, 16
    xor eax, eax
    rep stosb
    mov dword [calc_display_len], 0
    jmp .append
.no_reset:
    cmp dword [calc_display_len], 1
    jne .append
    cmp byte [calc_display], '0'
    jne .append
    mov dword [calc_display_len], 0
    mov byte [calc_display], 0
.append:
    mov ecx, [calc_display_len]
    cmp ecx, 10
    jae .done
    mov [calc_display + ecx], bl
    inc ecx
    mov [calc_display_len], ecx
    mov byte [calc_display + ecx], 0
.done:
    pop edi
    pop ecx
    pop ebx
    pop eax
    ret

; apply pending op: acc = acc OP display_value
calc_apply_op:
    push ebx
    call calc_parse
    mov ebx, eax
    mov eax, [calc_acc]
    movzx ecx, byte [calc_op]
    test ecx, ecx
    jz .store_display
    cmp ecx, 1
    je .add
    cmp ecx, 2
    je .sub
    cmp ecx, 3
    je .mul
    cmp ecx, 4
    je .div
    jmp .store_display
.add:
    add eax, ebx
    jmp .store
.sub:
    sub eax, ebx
    jmp .store
.mul:
    imul eax, ebx
    jmp .store
.div:
    test ebx, ebx
    jz .div0
    xor edx, edx
    div ebx
    jmp .store
.div0:
    mov byte [calc_error], 1
    xor eax, eax
    jmp .store
.store_display:
    mov eax, ebx
.store:
    mov [calc_acc], eax
    pop ebx
    ret

; ECX = op code (1-4)
calc_set_op:
    pushad
    cmp byte [calc_error], 0
    jne .done
    call calc_apply_op
    mov al, [calc_op_new]
    mov [calc_op], al
    mov byte [calc_new], 1
    mov eax, [calc_acc]
    call calc_show
    mov byte [calc_new], 1
.done:
    popad
    ret

calc_equals:
    pushad
    cmp byte [calc_error], 0
    jne .done
    call calc_apply_op
    mov byte [calc_op], 0
    mov eax, [calc_acc]
    call calc_show
    mov byte [calc_new], 1
.done:
    popad
    ret

calc_op_new:  db 0

; EAX = x, EBX = y of click (window-local)
calc_handle_click:
    pushad
    mov edi, eax
    mov edx, ebx
    sub edi, 12
    sub edx, 46
    cmp edi, 0
    jl .done
    cmp edx, 0
    jl .done

    ; column = lx / 40, remainder = lx % 40
    mov eax, edi
    xor edx, edx
    mov ecx, 40
    div ecx
    mov [calc_c], eax
    mov [calc_xr], edx

    ; row = ly / 21, remainder = ly % 21
    mov eax, [mouse_y]
    sub eax, [window_y]
    sub eax, 46
    cmp eax, 0
    jl .done
    xor edx, edx
    mov ecx, 21
    div ecx
    mov [calc_r], eax
    mov [calc_yr], edx

    cmp dword [calc_xr], 38
    jae .done
    cmp dword [calc_yr], 19
    jae .done

    mov eax, [calc_r]
    cmp eax, 5
    jae .done
    mov ecx, [calc_c]
    cmp ecx, 4
    jae .done

    cmp eax, 4
    jne .not_row4
    cmp ecx, 0
    je .do_zero
    cmp ecx, 1
    je .do_zero
    cmp ecx, 2
    je .do_dot
    jmp .done
.do_zero:
    mov al, '0'
    call calc_append_digit
    jmp .done
.do_dot:
    jmp .done

.not_row4:
    cmp eax, 0
    jne .row1
    cmp ecx, 0
    je .do_clear
    cmp ecx, 1
    je .do_div
    cmp ecx, 2
    je .do_mul
    cmp ecx, 3
    je .do_sub
    jmp .done
.row1:
    cmp eax, 1
    jne .row2
    cmp ecx, 0
    je .do_7
    cmp ecx, 1
    je .do_8
    cmp ecx, 2
    je .do_9
    cmp ecx, 3
    je .do_add
    jmp .done
.row2:
    cmp eax, 2
    jne .row3
    cmp ecx, 0
    je .do_4
    cmp ecx, 1
    je .do_5
    cmp ecx, 2
    je .do_6
    cmp ecx, 3
    je .do_equals
    jmp .done
.row3:
    cmp ecx, 0
    je .do_1
    cmp ecx, 1
    je .do_2
    cmp ecx, 2
    je .do_3
    cmp ecx, 3
    je .do_equals
    jmp .done

.do_clear:
    call calc_clear
    jmp .done
.do_div:
    mov byte [calc_op_new], 4
    mov ecx, 4
    call calc_set_op
    jmp .done
.do_mul:
    mov byte [calc_op_new], 3
    mov ecx, 3
    call calc_set_op
    jmp .done
.do_sub:
    mov byte [calc_op_new], 2
    mov ecx, 2
    call calc_set_op
    jmp .done
.do_add:
    mov byte [calc_op_new], 1
    mov ecx, 1
    call calc_set_op
    jmp .done
.do_7:
    mov al, '7'
    call calc_append_digit
    jmp .done
.do_8:
    mov al, '8'
    call calc_append_digit
    jmp .done
.do_9:
    mov al, '9'
    call calc_append_digit
    jmp .done
.do_4:
    mov al, '4'
    call calc_append_digit
    jmp .done
.do_5:
    mov al, '5'
    call calc_append_digit
    jmp .done
.do_6:
    mov al, '6'
    call calc_append_digit
    jmp .done
.do_1:
    mov al, '1'
    call calc_append_digit
    jmp .done
.do_2:
    mov al, '2'
    call calc_append_digit
    jmp .done
.do_3:
    mov al, '3'
    call calc_append_digit
    jmp .done
.do_equals:
    call calc_equals
.done:
    mov byte [dirty], 1
    popad
    ret

calc_c:  dd 0
calc_r:  dd 0
calc_xr: dd 0
calc_yr: dd 0

; Draw a single calculator button.
; EAX=x, EBX=y, ECX=w, EDX=h, ESI=bg color, EDI=label string
calc_button:
    pushad
    mov [cb_x], eax
    mov [cb_y], ebx
    mov [cb_w], ecx
    mov [cb_h], edx
    mov [cb_bg], esi
    mov [cb_label], edi

    ; outer dark border
    mov eax, [cb_x]
    mov ebx, [cb_y]
    mov ecx, [cb_w]
    mov edx, [cb_h]
    mov esi, COLOR_BLACK
    call draw_rect

    ; inner fill
    mov eax, [cb_x]
    inc eax
    mov ebx, [cb_y]
    inc ebx
    mov ecx, [cb_w]
    sub ecx, 2
    mov edx, [cb_h]
    sub edx, 2
    mov esi, [cb_bg]
    call draw_rect

    ; top highlight
    mov eax, [cb_x]
    inc eax
    mov ebx, [cb_y]
    inc ebx
    mov ecx, [cb_w]
    sub ecx, 2
    mov edx, 1
    mov esi, COLOR_WHITE
    call draw_rect

    ; centered label
    mov esi, [cb_label]
    push esi
    xor ecx, ecx
.len:
    lodsb
    test al, al
    jz .got_len
    inc ecx
    jmp .len
.got_len:
    pop esi
    ; center x = cb_x + (cb_w - len*8)/2
    mov eax, ecx
    shl eax, 3
    mov edx, [cb_w]
    sub edx, eax
    sar edx, 1
    add edx, [cb_x]
    mov edi, edx
    ; y = cb_y + (cb_h - 8)/2
    mov edx, [cb_h]
    sub edx, 8
    sar edx, 1
    add edx, [cb_y]
    mov ebx, COLOR_WHITE
    call draw_text

    popad
    ret

cb_x:     dd 0
cb_y:     dd 0
cb_w:     dd 0
cb_h:     dd 0
cb_bg:    dd 0
cb_label: dd 0

draw_calc:
    ; Display background
    mov eax, [window_x]
    add eax, 8
    mov ebx, [window_y]
    add ebx, 22
    mov ecx, 164
    mov edx, 22
    mov esi, COLOR_BLACK
    call draw_rect

    ; Display inner border
    mov eax, [window_x]
    add eax, 9
    mov ebx, [window_y]
    add ebx, 23
    mov ecx, 162
    mov edx, 20
    mov esi, COLOR_DGRAY
    call draw_rect

    ; Right-aligned display text
    mov eax, [calc_display_len]
    cmp eax, 12
    jbe .len_ok
    mov eax, 12
.len_ok:
    shl eax, 3
    mov ecx, [window_x]
    add ecx, 170
    sub ecx, eax
    mov edx, [window_y]
    add edx, 28
    mov esi, calc_display
    mov edi, ecx
    mov ebx, COLOR_LGREEN
    call draw_text

    ; Row 0: C / * -
    mov eax, [window_x]
    add eax, 12
    mov ebx, [window_y]
    add ebx, 46
    mov ecx, 38
    mov edx, 19
    mov esi, COLOR_RED
    mov edi, cb_lbl_c
    call calc_button

    mov eax, [window_x]
    add eax, 52
    mov ebx, [window_y]
    add ebx, 46
    mov ecx, 38
    mov edx, 19
    mov esi, COLOR_BLUE
    mov edi, cb_lbl_div
    call calc_button

    mov eax, [window_x]
    add eax, 92
    mov ebx, [window_y]
    add ebx, 46
    mov ecx, 38
    mov edx, 19
    mov esi, COLOR_BLUE
    mov edi, cb_lbl_mul
    call calc_button

    mov eax, [window_x]
    add eax, 132
    mov ebx, [window_y]
    add ebx, 46
    mov ecx, 38
    mov edx, 19
    mov esi, COLOR_BLUE
    mov edi, cb_lbl_sub
    call calc_button

    ; Row 1: 7 8 9 +
    mov eax, [window_x]
    add eax, 12
    mov ebx, [window_y]
    add ebx, 67
    mov ecx, 38
    mov edx, 19
    mov esi, COLOR_GRAY
    mov edi, cb_lbl_7
    call calc_button

    mov eax, [window_x]
    add eax, 52
    mov ebx, [window_y]
    add ebx, 67
    mov ecx, 38
    mov edx, 19
    mov esi, COLOR_GRAY
    mov edi, cb_lbl_8
    call calc_button

    mov eax, [window_x]
    add eax, 92
    mov ebx, [window_y]
    add ebx, 67
    mov ecx, 38
    mov edx, 19
    mov esi, COLOR_GRAY
    mov edi, cb_lbl_9
    call calc_button

    mov eax, [window_x]
    add eax, 132
    mov ebx, [window_y]
    add ebx, 67
    mov ecx, 38
    mov edx, 19
    mov esi, COLOR_BLUE
    mov edi, cb_lbl_add
    call calc_button

    ; Row 2: 4 5 6 = (tall)
    mov eax, [window_x]
    add eax, 12
    mov ebx, [window_y]
    add ebx, 88
    mov ecx, 38
    mov edx, 19
    mov esi, COLOR_GRAY
    mov edi, cb_lbl_4
    call calc_button

    mov eax, [window_x]
    add eax, 52
    mov ebx, [window_y]
    add ebx, 88
    mov ecx, 38
    mov edx, 19
    mov esi, COLOR_GRAY
    mov edi, cb_lbl_5
    call calc_button

    mov eax, [window_x]
    add eax, 92
    mov ebx, [window_y]
    add ebx, 88
    mov ecx, 38
    mov edx, 19
    mov esi, COLOR_GRAY
    mov edi, cb_lbl_6
    call calc_button

    mov eax, [window_x]
    add eax, 132
    mov ebx, [window_y]
    add ebx, 88
    mov ecx, 38
    mov edx, 40
    mov esi, COLOR_LGREEN
    mov edi, cb_lbl_eq
    call calc_button

    ; Row 3: 1 2 3
    mov eax, [window_x]
    add eax, 12
    mov ebx, [window_y]
    add ebx, 109
    mov ecx, 38
    mov edx, 19
    mov esi, COLOR_GRAY
    mov edi, cb_lbl_1
    call calc_button

    mov eax, [window_x]
    add eax, 52
    mov ebx, [window_y]
    add ebx, 109
    mov ecx, 38
    mov edx, 19
    mov esi, COLOR_GRAY
    mov edi, cb_lbl_2
    call calc_button

    mov eax, [window_x]
    add eax, 92
    mov ebx, [window_y]
    add ebx, 109
    mov ecx, 38
    mov edx, 19
    mov esi, COLOR_GRAY
    mov edi, cb_lbl_3
    call calc_button

    ; Row 4: 0 (wide) .
    mov eax, [window_x]
    add eax, 12
    mov ebx, [window_y]
    add ebx, 130
    mov ecx, 78
    mov edx, 19
    mov esi, COLOR_GRAY
    mov edi, cb_lbl_0
    call calc_button

    mov eax, [window_x]
    add eax, 92
    mov ebx, [window_y]
    add ebx, 130
    mov ecx, 38
    mov edx, 19
    mov esi, COLOR_GRAY
    mov edi, cb_lbl_dot
    call calc_button

    ret

cb_lbl_c:   db 'C',0
cb_lbl_div: db '/',0
cb_lbl_mul: db '*',0
cb_lbl_sub: db '-',0
cb_lbl_add: db '+',0
cb_lbl_eq:  db '=',0
cb_lbl_0:   db '0',0
cb_lbl_1:   db '1',0
cb_lbl_2:   db '2',0
cb_lbl_3:   db '3',0
cb_lbl_4:   db '4',0
cb_lbl_5:   db '5',0
cb_lbl_6:   db '6',0
cb_lbl_7:   db '7',0
cb_lbl_8:   db '8',0
cb_lbl_9:   db '9',0
cb_lbl_dot: db '.',0

draw_calc_icon:
    pushad
    mov eax, [icon_x + 24]
    mov ebx, [icon_y + 24]
    mov ecx, 16
    mov edx, 16
    mov esi, COLOR_DGRAY
    call draw_rect
    ; display strip
    mov eax, [icon_x + 24]
    inc eax
    mov ebx, [icon_y + 24]
    inc ebx
    mov ecx, 14
    mov edx, 4
    mov esi, COLOR_LGREEN
    call draw_rect
    ; button dots
    mov eax, [icon_x + 24]
    add eax, 2
    mov ebx, [icon_y + 24]
    add ebx, 7
    mov ecx, 4
    mov edx, 2
    mov esi, COLOR_WHITE
    call draw_rect
    mov eax, [icon_x + 24]
    add eax, 7
    mov ebx, [icon_y + 24]
    add ebx, 7
    mov ecx, 4
    mov edx, 2
    mov esi, COLOR_WHITE
    call draw_rect
    mov eax, [icon_x + 24]
    add eax, 12
    mov ebx, [icon_y + 24]
    add ebx, 7
    mov ecx, 2
    mov edx, 2
    mov esi, COLOR_RED
    call draw_rect
    mov eax, [icon_x + 24]
    add eax, 2
    mov ebx, [icon_y + 24]
    add ebx, 11
    mov ecx, 4
    mov edx, 2
    mov esi, COLOR_WHITE
    call draw_rect
    mov eax, [icon_x + 24]
    add eax, 7
    mov ebx, [icon_y + 24]
    add ebx, 11
    mov ecx, 4
    mov edx, 2
    mov esi, COLOR_WHITE
    call draw_rect
    mov eax, [icon_x + 24]
    add eax, 12
    mov ebx, [icon_y + 24]
    add ebx, 11
    mov ecx, 2
    mov edx, 2
    mov esi, COLOR_WHITE
    call draw_rect
    ; label
    mov edi, [icon_x + 24]
    sub edi, 16
    mov edx, [icon_y + 24]
    add edx, 20
    mov esi, str_icon_calc
    mov ebx, COLOR_BLACK
    call draw_text
    popad
    ret
; =============================================================
; SNAKE
; =============================================================

snake_reset:
    pushad
    mov byte [snake_body+0], 10
    mov byte [snake_body+1], 10
    mov byte [snake_body+2], 9
    mov byte [snake_body+3], 10
    mov byte [snake_body+4], 8
    mov byte [snake_body+5], 10
    mov dword [snake_len], 3
    mov byte [snake_dir], 0
    mov byte [snake_next_dir], 0
    mov dword [snake_score], 0
    mov dword [snake_tick], 0
    mov dword [snake_speed], 8
    mov eax, [pit_ticks]
    mov [snake_last_move], eax
    mov byte [snake_paused], 0
    mov byte [snake_dead], 0
    mov byte [snake_started], 0
    call snake_spawn_food
    mov byte [dirty], 1
    popad
    ret

snake_rand:
    push ecx
    mov eax, [snake_rng]
    mov ecx, eax
    shl ecx, 13
    xor eax, ecx
    mov ecx, eax
    shr ecx, 17
    xor eax, ecx
    mov ecx, eax
    shl ecx, 5
    xor eax, ecx
    mov [snake_rng], eax
    pop ecx
    ret

snake_spawn_food:
    pushad
.try:
    call snake_rand
    xor edx, edx
    mov ecx, 26
    div ecx
    mov [snake_food_x], dl
    call snake_rand
    xor edx, edx
    mov ecx, 20
    div ecx
    mov [snake_food_y], dl
    xor ebx, ebx
.chk:
    cmp ebx, [snake_len]
    jae .ok
    movzx eax, byte [snake_body + ebx*2]
    cmp al, [snake_food_x]
    jne .next
    movzx eax, byte [snake_body + ebx*2 + 1]
    cmp al, [snake_food_y]
    jne .next
    jmp .try
.next:
    inc ebx
    jmp .chk
.ok:
    popad
    ret

snake_step:
    pushad
    cmp byte [snake_dead], 1
    je .done
    cmp byte [snake_paused], 1
    je .done

    mov al, [snake_next_dir]
    mov [snake_dir], al

    movzx eax, byte [snake_body+0]
    movzx ebx, byte [snake_body+1]
    mov cl, [snake_dir]
    cmp cl, 0
    je .go_up
    cmp cl, 1
    je .go_right
    cmp cl, 2
    je .go_down
    dec eax
    jmp .moved
.go_up:
    dec ebx
    jmp .moved
.go_right:
    inc eax
    jmp .moved
.go_down:
    inc ebx
.moved:
    cmp eax, 0
    jl .died
    cmp eax, 26
    jge .died
    cmp ebx, 0
    jl .died
    cmp ebx, 20
    jge .died

    mov edx, [snake_len]
    dec edx
    xor ecx, ecx
.self_chk:
    cmp ecx, edx
    jae .no_self
    movzx esi, byte [snake_body + ecx*2]
    cmp esi, eax
    jne .self_next
    movzx esi, byte [snake_body + ecx*2 + 1]
    cmp esi, ebx
    jne .self_next
    jmp .died
.self_next:
    inc ecx
    jmp .self_chk
.no_self:

    movzx esi, byte [snake_food_x]
    cmp esi, eax
    jne .no_eat
    movzx esi, byte [snake_food_y]
    cmp esi, ebx
    jne .no_eat

    mov ecx, [snake_len]
    cmp ecx, 100
    jae .no_grow
.grow_shift:
    test ecx, ecx
    jz .grow_done
    mov dl, [snake_body + ecx*2 - 2]
    mov [snake_body + ecx*2], dl
    mov dl, [snake_body + ecx*2 - 1]
    mov [snake_body + ecx*2 + 1], dl
    dec ecx
    jmp .grow_shift
.grow_done:
    mov [snake_body+0], al
    mov [snake_body+1], bl
    inc dword [snake_len]
    add dword [snake_score], 10
    mov eax, [snake_score]
    cmp eax, [snake_best]
    jbe .no_best
    mov [snake_best], eax
.no_best:
    cmp dword [snake_speed], 3
    jbe .no_grow
    dec dword [snake_speed]
.no_grow:
    call snake_spawn_food
    jmp .done

.no_eat:
    mov ecx, [snake_len]
    dec ecx
.shift_loop:
    test ecx, ecx
    jz .shift_done
    mov dl, [snake_body + ecx*2 - 2]
    mov [snake_body + ecx*2], dl
    mov dl, [snake_body + ecx*2 - 1]
    mov [snake_body + ecx*2 + 1], dl
    dec ecx
    jmp .shift_loop
.shift_done:
    mov [snake_body+0], al
    mov [snake_body+1], bl
.done:
    mov byte [dirty], 1
    popad
    ret
.died:
    mov byte [snake_dead], 1
    mov byte [dirty], 1
    popad
    ret

; Draw one cell at grid coords (EAX, EBX) with color ESI
snake_draw_cell:
    pushad
    mov [snk_tmp_cx], eax
    mov [snk_tmp_cy], ebx
    mov [snk_tmp_color], esi

    mov eax, [window_x]
    add eax, 3
    add eax, [snake_board_x]
    mov ecx, [snk_tmp_cx]
    shl ecx, 3
    add eax, ecx
    mov [snk_tmp_px], eax

    mov eax, [window_y]
    add eax, 17
    add eax, [snake_board_y]
    mov ecx, [snk_tmp_cy]
    shl ecx, 3
    add eax, ecx
    mov [snk_tmp_py], eax

    ; 8x8 black border
    mov eax, [snk_tmp_px]
    mov ebx, [snk_tmp_py]
    mov ecx, 8
    mov edx, 8
    mov esi, COLOR_BLACK
    call draw_rect

    ; 6x6 inner fill
    mov eax, [snk_tmp_px]
    inc eax
    mov ebx, [snk_tmp_py]
    inc ebx
    mov ecx, 6
    mov edx, 6
    mov esi, [snk_tmp_color]
    call draw_rect

    popad
    ret

snk_tmp_cx:    dd 0
snk_tmp_cy:    dd 0
snk_tmp_color: dd 0
snk_tmp_px:    dd 0
snk_tmp_py:    dd 0

snake_board_x: dd 0
snake_board_y: dd 0

draw_snake:
    ; Center 26x20 board inside client area (208x160 px)
    mov eax, [window_w]
    sub eax, 6
    sub eax, 208
    sar eax, 1
    mov [snake_board_x], eax

    mov eax, [window_h]
    sub eax, 21
    sub eax, 160
    sar eax, 1
    add eax, 4
    mov [snake_board_y], eax

    ; Board frame
    mov eax, [window_x]
    add eax, 3
    add eax, [snake_board_x]
    dec eax
    mov ebx, [window_y]
    add ebx, 17
    add ebx, [snake_board_y]
    dec ebx
    mov ecx, 210
    mov edx, 162
    mov esi, COLOR_DGRAY
    call draw_rect

    ; Board background
    mov eax, [window_x]
    add eax, 3
    add eax, [snake_board_x]
    mov ebx, [window_y]
    add ebx, 17
    add ebx, [snake_board_y]
    mov ecx, 208
    mov edx, 160
    mov esi, 3
    call draw_rect

    ; Food
    movzx eax, byte [snake_food_x]
    movzx ebx, byte [snake_food_y]
    mov esi, COLOR_LRED
    call snake_draw_cell

    ; Body from tail to head
    mov ecx, [snake_len]
    dec ecx
.body_loop:
    test ecx, ecx
    js .body_done
    movzx eax, byte [snake_body + ecx*2]
    movzx ebx, byte [snake_body + ecx*2 + 1]
    push ecx
    mov esi, COLOR_LGREEN
    test ecx, ecx
    jnz .draw_body
    mov esi, COLOR_YELLOW
.draw_body:
    call snake_draw_cell
    pop ecx
    dec ecx
    jmp .body_loop
.body_done:

    ; Score
    mov esi, str_snake_score
    mov edi, [window_x]
    add edi, 8
    mov edx, [window_y]
    add edx, 20
    mov ebx, COLOR_LGREEN
    call draw_text

    mov eax, [snake_score]
    mov edi, snake_score_buf
    call format_u32
    mov esi, snake_score_buf
    mov edi, [window_x]
    add edi, 60
    mov edx, [window_y]
    add edx, 20
    mov ebx, COLOR_WHITE
    call draw_text

    ; Best
    mov esi, str_snake_best
    mov edi, [window_x]
    add edi, [window_w]
    sub edi, 90
    mov edx, [window_y]
    add edx, 20
    mov ebx, COLOR_YELLOW
    call draw_text

    mov eax, [snake_best]
    mov edi, snake_best_buf
    call format_u32
    mov esi, snake_best_buf
    mov edi, [window_x]
    add edi, [window_w]
    sub edi, 40
    mov edx, [window_y]
    add edx, 20
    mov ebx, COLOR_WHITE
    call draw_text

    ; Hint
    mov esi, str_snake_hint
    mov edi, [window_x]
    add edi, 8
    mov edx, [window_y]
    add edx, [window_h]
    sub edx, 12
    mov ebx, COLOR_GRAY
    call draw_text

    ; Overlays
    cmp byte [snake_paused], 1
    je .show_pause
    cmp byte [snake_dead], 1
    je .show_dead
    cmp byte [snake_started], 0
    je .show_ready
    ret
.show_pause:
    mov esi, str_snake_paused
    jmp .overlay
.show_dead:
    mov esi, str_snake_dead
    jmp .overlay
.show_ready:
    mov esi, str_snake_ready
.overlay:
    push esi
    mov eax, [window_x]
    add eax, [window_w]
    sub eax, 200
    sar eax, 1
    add eax, 40
    mov [snk_ov_x], eax
    mov ebx, [window_y]
    add ebx, [window_h]
    sub ebx, 44
    sar ebx, 1
    add ebx, 8
    mov [snk_ov_y], ebx
    mov ecx, 190
    mov edx, 22
    mov esi, COLOR_BLACK
    call draw_rect
    pop esi
    mov edi, [snk_ov_x]
    add edi, 8
    mov edx, [snk_ov_y]
    add edx, 7
    mov ebx, COLOR_WHITE
    call draw_text
    ret

snk_ov_x: dd 0
snk_ov_y: dd 0

snake_score_buf: times 12 db 0
snake_best_buf:  times 12 db 0

str_snake_score:  db 'Score:',0
str_snake_best:   db 'Best:',0
str_snake_hint:   db 'Arrows  ESC=Pause  R=Restart',0
str_snake_paused: db 'PAUSED - ESC to resume',0
str_snake_dead:   db 'GAME OVER - R to restart',0
str_snake_ready:  db 'Press arrow key to start',0

snake_click:
    ret

draw_snake_icon:
    pushad
    mov edi, [icon_x + 28]
    mov edx, [icon_y + 28]
    mov esi, icon_snake
    call draw_app_icon
    mov edi, [icon_x + 28]
    sub edi, 16
    mov edx, [icon_y + 28]
    add edx, 20
    mov esi, str_icon_snake
    mov ebx, COLOR_BLACK
    call draw_text
    popad
    ret
; IN: EAX=x, EBX=y, ECX=w, EDX=h, ESI=progress (0-10)
draw_titlebar_dither:
    pushad
    mov [vg_x], eax
    mov [vg_y], ebx
    mov [vg_w], ecx
    mov [vg_h], edx
    mov [vg_top], esi

    mov eax, [vg_h]
    shr eax, 1
    mov [vg_mid], eax

    mov eax, [vg_x]
    mov ebx, [vg_y]
    mov ecx, [vg_w]
    mov edx, [vg_mid]
    mov esi, 0x00002A4A
    call draw_rect

    mov eax, [vg_x]
    mov ebx, [vg_y]
    add ebx, [vg_mid]
    mov ecx, [vg_w]
    mov edx, [vg_h]
    sub edx, [vg_mid]
    mov esi, 0x00003A5A
    call draw_rect

    popad
    ret
; =============================================================
; CLI INSTALLER
; =============================================================

cli_start:
    mov byte [cli_active], 1
    mov byte [cli_screen], 1
    mov byte [cli_disk], 0
    mov byte [cli_yn], 0
    mov dword [cli_sector], 0
    mov byte [dirty], 1
    ret

cli_quit:
    mov byte [cli_active], 0
    mov byte [cli_screen], 0
    mov byte [ata_drive], 0xA0
    mov byte [dirty], 1
    ret

cli_draw:
    cmp byte [cli_active], 0
    je .abort
    call clip_reset
    xor eax, eax
    xor ebx, ebx
    mov ecx, 320
    mov edx, 200
    mov esi, COLOR_BLUE
    call draw_rect

    mov esi, str_cli_title
    mov edi, 8
    mov edx, 6
    mov ebx, COLOR_LCYAN
    call draw_text

    mov eax, 0
    mov ebx, 16
    mov ecx, 320
    mov edx, 1
    mov esi, COLOR_WHITE
    call draw_rect

    mov al, [cli_screen]
    cmp al, 1
    je .draw_disk
    cmp al, 2
    je .draw_confirm
    cmp al, 3
    je .draw_progress
    cmp al, 4
    je .draw_reboot
    cmp al, 5
    je .draw_error
.abort:
    ret

.draw_disk:
    mov esi, str_cli_s1
    mov edi, 8
    mov edx, 32
    mov ebx, COLOR_WHITE
    call draw_text

    mov esi, str_cli_master
    mov edi, 32
    mov edx, 60
    mov ebx, COLOR_WHITE
    call draw_text

    mov esi, str_cli_slave
    mov edi, 32
    mov edx, 76
    mov ebx, COLOR_WHITE
    call draw_text

    cmp byte [cli_disk], 0
    jne .dk_slave
    mov esi, str_cli_arrow
    mov edi, 16
    mov edx, 60
    mov ebx, COLOR_YELLOW
    call draw_text
    jmp .dk_hint
.dk_slave:
    mov esi, str_cli_arrow
    mov edi, 16
    mov edx, 76
    mov ebx, COLOR_YELLOW
    call draw_text
.dk_hint:
    mov esi, str_cli_hint1
    mov edi, 8
    mov edx, 170
    mov ebx, COLOR_GRAY
    call draw_text
    ret

.draw_confirm:
    mov esi, str_cli_s2
    mov edi, 8
    mov edx, 32
    mov ebx, COLOR_LCYAN
    call draw_text

    mov esi, str_cli_dst
    mov edi, 8
    mov edx, 60
    mov ebx, COLOR_WHITE
    call draw_text

    cmp byte [cli_disk], 0
    jne .cf_slave
    mov esi, str_cli_master
    jmp .cf_dst
.cf_slave:
    mov esi, str_cli_slave
.cf_dst:
    mov edi, 84
    mov edx, 60
    mov ebx, COLOR_YELLOW
    call draw_text

    mov esi, str_cli_warn
    mov edi, 8
    mov edx, 84
    mov ebx, COLOR_LRED
    call draw_text

    mov esi, str_cli_yes
    mov edi, 32
    mov edx, 120
    mov ebx, COLOR_WHITE
    call draw_text
    mov esi, str_cli_no
    mov edi, 32
    mov edx, 136
    mov ebx, COLOR_WHITE
    call draw_text

    cmp byte [cli_yn], 0
    jne .cf_no
    mov esi, str_cli_arrow
    mov edi, 16
    mov edx, 120
    mov ebx, COLOR_YELLOW
    call draw_text
    jmp .cf_hint
.cf_no:
    mov esi, str_cli_arrow
    mov edi, 16
    mov edx, 136
    mov ebx, COLOR_YELLOW
    call draw_text
.cf_hint:
    mov esi, str_cli_hint2
    mov edi, 8
    mov edx, 170
    mov ebx, COLOR_GRAY
    call draw_text
    ret

.draw_progress:
    mov esi, str_cli_inst
    mov edi, 8
    mov edx, 60
    mov ebx, COLOR_WHITE
    call draw_text

    mov eax, 40
    mov ebx, 90
    mov ecx, 240
    mov edx, 20
    mov esi, COLOR_WHITE
    call draw_rect

    mov eax, [cli_sector]
    mov ecx, 340
    cmp eax, ecx
    jae .pg_full
    xor edx, edx
    imul eax, 234
    div ecx
    mov ecx, eax
    jmp .pg_fill
.pg_full:
    mov ecx, 234
.pg_fill:
    mov eax, 42
    mov ebx, 92
    mov edx, 16
    mov esi, COLOR_LGREEN
    call draw_rect

    mov esi, str_cli_prog
    mov edi, 8
    mov edx, 130
    mov ebx, COLOR_GRAY
    call draw_text
    ret

.draw_reboot:
    mov esi, str_cli_done
    mov edi, 8
    mov edx, 60
    mov ebx, COLOR_LGREEN
    call draw_text

    mov esi, str_cli_reboot
    mov edi, 8
    mov edx, 90
    mov ebx, COLOR_WHITE
    call draw_text

    mov esi, str_cli_yes
    mov edi, 32
    mov edx, 120
    mov ebx, COLOR_WHITE
    call draw_text
    mov esi, str_cli_no
    mov edi, 32
    mov edx, 136
    mov ebx, COLOR_WHITE
    call draw_text

    cmp byte [cli_yn], 0
    jne .rb_no
    mov esi, str_cli_arrow
    mov edi, 16
    mov edx, 120
    mov ebx, COLOR_YELLOW
    call draw_text
    jmp .rb_hint
.rb_no:
    mov esi, str_cli_arrow
    mov edi, 16
    mov edx, 136
    mov ebx, COLOR_YELLOW
    call draw_text
.rb_hint:
    mov esi, str_cli_hint2
    mov edi, 8
    mov edx, 170
    mov ebx, COLOR_GRAY
    call draw_text
    ret

.draw_error:
    mov esi, str_cli_err
    mov edi, 8
    mov edx, 80
    mov ebx, COLOR_LRED
    call draw_text
    mov esi, str_cli_anykey
    mov edi, 8
    mov edx, 120
    mov ebx, COLOR_WHITE
    call draw_text
    ret

cli_install_step:
    cmp dword [cli_sector], 340
    jae .done

    mov byte [ata_drive], 0xA0
    mov esi, [cli_sector]
    mov edi, 0x48000
    call ata_read_sector
    jc .fail

    mov al, [cli_disk]
    shl al, 4
    add al, 0xE0
    mov [ata_drive], al
    mov esi, [cli_sector]
    mov edi, 0x48000
    call ata_write_sector
    jc .fail

    mov byte [ata_drive], 0xA0
    inc dword [cli_sector]
    ret

.done:
    mov byte [ata_drive], 0xA0
    mov byte [cli_screen], 4
    mov byte [cli_yn], 0
    mov byte [dirty], 1
    ret

.fail:
    mov byte [ata_drive], 0xA0
    mov byte [cli_screen], 5
    mov byte [dirty], 1
    ret

cli_key:
    test al, 0x80
    jz .make
    ret
.make:
    mov dl, al
    mov al, [cli_screen]
    cmp al, 1
    je .s1
    cmp al, 2
    je .s2
    cmp al, 4
    je .s4
    cmp al, 5
    je .s5
    ret

.s1:
    cmp dl, 0x48
    je .s1_tog
    cmp dl, 0x50
    je .s1_tog
    cmp dl, 0x1C
    je .s1_go
    cmp dl, 0x01
    je .s1_esc
    ret
.s1_tog:
    xor byte [cli_disk], 1
    mov byte [dirty], 1
    ret
.s1_go:
    mov byte [cli_screen], 2
    mov byte [cli_yn], 0
    mov byte [dirty], 1
    ret
.s1_esc:
    call cli_quit
    ret

.s2:
    cmp dl, 0x48
    je .s2_tog
    cmp dl, 0x50
    je .s2_tog
    cmp dl, 0x1C
    je .s2_go
    cmp dl, 0x01
    je .s2_back
    ret
.s2_tog:
    xor byte [cli_yn], 1
    mov byte [dirty], 1
    ret
.s2_go:
    cmp byte [cli_yn], 0
    jne .s2_back
    mov dword [cli_sector], 0
    mov byte [cli_screen], 3
    mov byte [dirty], 1
    ret
.s2_back:
    mov byte [cli_screen], 1
    mov byte [dirty], 1
    ret

.s4:
    cmp dl, 0x48
    je .s4_tog
    cmp dl, 0x50
    je .s4_tog
    cmp dl, 0x1C
    je .s4_go
    ret
.s4_tog:
    xor byte [cli_yn], 1
    mov byte [dirty], 1
    ret
.s4_go:
    cmp byte [cli_yn], 0
    jne .s4_no
    call do_reboot
    ret
.s4_no:
    call cli_quit
    ret

.s5:
    call cli_quit
    ret
draw_settings:
    ; Section: Wallpaper
    mov esi, str_set_wp
    mov edi, [window_x]
    add edi, 8
    mov edx, [window_y]
    add edx, 22
    mov bl, COLOR_LCYAN
    call draw_text

    ; 3 wallpaper buttons
    xor ebp, ebp
.wp_loop:
    cmp ebp, 3
    jae .wp_done
    mov eax, ebp
    imul eax, 55
    add eax, [window_x]
    add eax, 8
    mov ebx, [window_y]
    add ebx, 34
    mov ecx, 50
    mov edx, 30
    mov esi, COLOR_LBLUE
    call draw_rect

    mov eax, ebp
    imul eax, 55
    add eax, [window_x]
    add eax, 10
    mov ebx, [window_y]
    add ebx, 36
    mov ecx, 46
    mov edx, 26
    mov esi, COLOR_DGRAY
    call draw_rect

    mov esi, str_set_1
    cmp ebp, 1
    jne .wp_n2
    mov esi, str_set_2
.wp_n2:
    cmp ebp, 2
    jne .wp_nd
    mov esi, str_set_3
.wp_nd:
    mov eax, ebp
    imul eax, 55
    add eax, [window_x]
    add eax, 30
    mov edi, eax
    mov edx, [window_y]
    add edx, 46
    mov bl, COLOR_WHITE
    call draw_text

    movzx eax, byte [prefs_blob + PREFS_WP]
    cmp eax, ebp
    jne .wp_next
    mov eax, ebp
    imul eax, 55
    add eax, [window_x]
    add eax, 6
    mov ebx, [window_y]
    add ebx, 32
    mov ecx, 54
    mov edx, 1
    mov esi, COLOR_WHITE
    call draw_rect
    mov eax, ebp
    imul eax, 55
    add eax, [window_x]
    add eax, 6
    mov ebx, [window_y]
    add ebx, 65
    mov ecx, 54
    mov edx, 1
    mov esi, COLOR_WHITE
    call draw_rect
    mov eax, ebp
    imul eax, 55
    add eax, [window_x]
    add eax, 6
    mov ebx, [window_y]
    add ebx, 32
    mov ecx, 1
    mov edx, 34
    mov esi, COLOR_WHITE
    call draw_rect
    mov eax, ebp
    imul eax, 55
    add eax, [window_x]
    add eax, 59
    mov ebx, [window_y]
    add ebx, 32
    mov ecx, 1
    mov edx, 34
    mov esi, COLOR_WHITE
    call draw_rect
.wp_next:
    inc ebp
    jmp .wp_loop
.wp_done:

    ; Section: Cursor color
    mov esi, str_set_cur
    mov edi, [window_x]
    add edi, 8
    mov edx, [window_y]
    add edx, 72
    mov bl, COLOR_LCYAN
    call draw_text

    xor ebp, ebp
.cur_loop:
    cmp ebp, 16
    jae .cur_done
    mov eax, ebp
    imul eax, 15
    add eax, [window_x]
    add eax, 8
    mov ebx, [window_y]
    add ebx, 84
    mov ecx, 14
    mov edx, 14
    push ebp
    mov esi, ebp
    shl esi, 2
    add esi, VGA_PALETTE_ADDR
    mov esi, [esi]
    call draw_rect
    pop ebp

    movzx eax, byte [prefs_blob + PREFS_CUR]
    cmp eax, ebp
    jne .cur_next
    mov eax, ebp
    imul eax, 15
    add eax, [window_x]
    add eax, 7
    mov ebx, [window_y]
    add ebx, 83
    mov ecx, 16
    mov edx, 1
    mov esi, COLOR_WHITE
    call draw_rect
    mov eax, ebp
    imul eax, 15
    add eax, [window_x]
    add eax, 7
    mov ebx, [window_y]
    add ebx, 98
    mov ecx, 16
    mov edx, 1
    mov esi, COLOR_WHITE
    call draw_rect
    mov eax, ebp
    imul eax, 15
    add eax, [window_x]
    add eax, 7
    mov ebx, [window_y]
    add ebx, 83
    mov ecx, 1
    mov edx, 16
    mov esi, COLOR_WHITE
    call draw_rect
    mov eax, ebp
    imul eax, 15
    add eax, [window_x]
    add eax, 22
    mov ebx, [window_y]
    add ebx, 83
    mov ecx, 1
    mov edx, 16
    mov esi, COLOR_WHITE
    call draw_rect
.cur_next:
    inc ebp
    jmp .cur_loop
.cur_done:

    ; Section: Login at boot
    mov esi, str_set_login
    mov edi, [window_x]
    add edi, 8
    mov edx, [window_y]
    add edx, 112
    mov bl, COLOR_LCYAN
    call draw_text

    mov eax, [window_x]
    add eax, 8
    mov ebx, [window_y]
    add ebx, 124
    mov ecx, 50
    mov edx, 18
    mov esi, COLOR_WHITE
    call draw_rect

    mov eax, [window_x]
    add eax, 9
    mov ebx, [window_y]
    add ebx, 125
    mov ecx, 48
    mov edx, 16
    cmp byte [prefs_blob + PREFS_LOG], 0
    jne .login_on
    mov esi, COLOR_DGRAY
    jmp .login_bg
.login_on:
    mov esi, COLOR_LGREEN
.login_bg:
    call draw_rect

    mov esi, str_set_off
    cmp byte [prefs_blob + PREFS_LOG], 0
    je .login_lbl
    mov esi, str_set_on
.login_lbl:
    mov edi, [window_x]
    add edi, 24
    mov edx, [window_y]
    add edx, 129
    mov bl, COLOR_BLACK
    call draw_text

    mov esi, str_set_hint
    mov edi, [window_x]
    add edi, 8
    mov edx, [window_y]
    add edx, [window_h]
    sub edx, 14
    mov bl, COLOR_GRAY
    call draw_text
    ret

settings_click:
    pushad
    mov ecx, [eax + WX]
    mov [window_x], ecx
    mov ecx, [eax + WY]
    mov [window_y], ecx

    mov edi, [mouse_x]
    sub edi, [window_x]
    mov edx, [mouse_y]
    sub edx, [window_y]

    ; Wallpaper buttons: y in 34..64, x in 8..168
    cmp edx, 34
    jl .try_cur
    cmp edx, 64
    jg .try_cur
    cmp edi, 8
    jl .try_cur
    cmp edi, 168
    jg .try_cur
    mov eax, edi
    sub eax, 8
    xor edx, edx
    mov ecx, 55
    div ecx
    cmp eax, 3
    jae .done
    call set_wallpaper
    jmp .done

.try_cur:
    ; Cursor swatches: y in 84..98, x in 8..248
    cmp edx, 84
    jl .try_login
    cmp edx, 98
    jg .try_login
    cmp edi, 8
    jl .try_login
    cmp edi, 248
    jg .try_login
    mov eax, edi
    sub eax, 8
    xor edx, edx
    mov ecx, 15
    div ecx
    cmp eax, 16
    jae .done
    call set_cursor_color
    jmp .done

.try_login:
    ; Login toggle: y in 124..142, x in 8..58
    cmp edx, 124
    jl .done
    cmp edx, 142
    jg .done
    cmp edi, 8
    jl .done
    cmp edi, 58
    jg .done
    xor byte [prefs_blob + PREFS_LOG], 1
    call save_prefs
    mov byte [dirty], 1
.done:
    popad
    ret

draw_snap_preview:
    cmp byte [snap_preview], 0
    je .done

    mov dword [snap_prev_x], 0
    mov dword [snap_prev_y], 0
    mov dword [snap_prev_w], 320
    mov dword [snap_prev_h], 180

    mov al, [snap_preview]
    cmp al, 1
    je .have
    cmp al, 2
    jne .not_lh
    mov dword [snap_prev_w], 160
    jmp .have
.not_lh:
    cmp al, 3
    jne .not_rh
    mov dword [snap_prev_x], 160
    mov dword [snap_prev_w], 160
    jmp .have
.not_rh:
    cmp al, 4
    jne .not_tl
    mov dword [snap_prev_w], 160
    mov dword [snap_prev_h], 90
    jmp .have
.not_tl:
    cmp al, 5
    jne .not_tr
    mov dword [snap_prev_x], 160
    mov dword [snap_prev_w], 160
    mov dword [snap_prev_h], 90
    jmp .have
.not_tr:
    cmp al, 6
    jne .not_bl
    mov dword [snap_prev_y], 90
    mov dword [snap_prev_w], 160
    mov dword [snap_prev_h], 90
    jmp .have
.not_bl:
    mov dword [snap_prev_x], 160
    mov dword [snap_prev_y], 90
    mov dword [snap_prev_w], 160
    mov dword [snap_prev_h], 90

.have:
    mov eax, [snap_prev_x]
    mov ebx, [snap_prev_y]
    mov ecx, [snap_prev_w]
    mov edx, 2
    mov esi, COLOR_WHITE
    call draw_rect

    mov eax, [snap_prev_x]
    mov ebx, [snap_prev_y]
    add ebx, [snap_prev_h]
    sub ebx, 2
    mov ecx, [snap_prev_w]
    mov edx, 2
    mov esi, COLOR_WHITE
    call draw_rect

    mov eax, [snap_prev_x]
    mov ebx, [snap_prev_y]
    mov ecx, 2
    mov edx, [snap_prev_h]
    mov esi, COLOR_WHITE
    call draw_rect

    mov eax, [snap_prev_x]
    add eax, [snap_prev_w]
    sub eax, 2
    mov ebx, [snap_prev_y]
    mov ecx, 2
    mov edx, [snap_prev_h]
    mov esi, COLOR_WHITE
    call draw_rect

.done:
    ret

	draw_ctx_menu:
    cmp byte [ctx_open], 0
    je .done
    mov eax, [ctx_draw_x]
    mov ebx, [ctx_draw_y]
    mov ecx, 80
    mov edx, 56
    mov esi, COLOR_WHITE
    call draw_rect
    mov eax, [ctx_draw_x]
    inc eax
    mov ebx, [ctx_draw_y]
    inc ebx
    mov ecx, 78
    mov edx, 54
    mov esi, COLOR_DGRAY
    call draw_rect

    mov esi, ctx_new_note
    mov edi, [ctx_draw_x]
    add edi, 6
    mov edx, [ctx_draw_y]
    add edx, 4
    mov ebx, COLOR_WHITE
    call draw_text

    mov esi, ctx_new_paint
    mov edi, [ctx_draw_x]
    add edi, 6
    mov edx, [ctx_draw_y]
    add edx, 16
    mov ebx, COLOR_WHITE
    call draw_text

    mov esi, ctx_refresh
    mov edi, [ctx_draw_x]
    add edi, 6
    mov edx, [ctx_draw_y]
    add edx, 28
    mov ebx, COLOR_WHITE
    call draw_text

    mov esi, ctx_about
    mov edi, [ctx_draw_x]
    add edi, 6
    mov edx, [ctx_draw_y]
    add edx, 40
    mov ebx, COLOR_WHITE
    call draw_text
.done:
    ret

draw_cursor:
    pushad
    movzx ebp, byte [prefs_blob + PREFS_CUR]
    shl ebp, 2
    add ebp, VGA_PALETTE_ADDR
    mov ebp, [ebp]

    mov esi, cursor_bitmap
    xor ecx, ecx
.row:
    cmp ecx, 10
    jae .done
    xor edx, edx
.col:
    cmp edx, 8
    jae .next_row
    mov al, [esi]
    test al, al
    jz .skip
    mov eax, [mouse_smooth_x]
    add eax, edx
    cmp eax, 319
    ja .skip
    mov ebx, [mouse_smooth_y]
    add ebx, ecx
    cmp ebx, 199
    ja .skip
    imul ebx, SCREEN_W
    add ebx, eax
    shl ebx, 2
    add ebx, BACKBUF
    cmp byte [esi], 2
    je .black
    mov [ebx], ebp
    jmp .skip
.black:
    mov dword [ebx], 0x000000
.skip:
    inc esi
    inc edx
    jmp .col
.next_row:
    inc ecx
    jmp .row
.done:
    popad
    ret
play_tone:
    pushad
    mov [tone_freq], eax
    mov [tone_delay], ecx
    mov eax, 1193182
    xor edx, edx
    mov ebx, [tone_freq]
    div ebx
    mov [tone_div], ax
    mov al, 0xB6
    out 0x43, al
    mov al, [tone_div]
    out 0x42, al
    mov al, [tone_div+1]
    out 0x42, al
    in al, 0x61
    or al, 3
    out 0x61, al
    mov ebx, [tone_delay]
.delay:
    dec ebx
    jnz .delay
    in al, 0x61
    and al, 0xFC
    out 0x61, al
    popad
    ret

play_boot_sound:
    pushad
    mov eax, 523
    mov ecx, 0x3000000
    call play_tone
    mov eax, 659
    mov ecx, 0x3000000
    call play_tone
    mov eax, 784
    mov ecx, 0x6000000
    call play_tone
    popad
    ret

init_palette:
    pushad
    push esi
    mov dx, 0x3C8
    xor al, al
    out dx, al
    mov dx, 0x3C9
    mov ecx, 768
.loop:
    lodsb
    out dx, al
    dec ecx
    jnz .loop
    pop esi
    popad
    ret

load_wallpaper:
    pushad

    ; Read 128 sectors (64KB) of wallpaper into WALLPAPER_BUF
    mov byte [ata_drive], 0xE0
    mov dword [wl_sector], 0
.read:
    cmp dword [wl_sector], 128
    jae .setup
    mov esi, [wallpaper_lba]
    add esi, [wl_sector]
    mov edi, WALLPAPER_BUF
    mov eax, [wl_sector]
    shl eax, 9
    add edi, eax
    call ata_read_sector
    jc .done
    inc dword [wl_sector]
    jmp .read

.setup:
    ; Convert 6-bit VGA palette → 24-bit dwords at VGA_PALETTE_ADDR
    mov esi, WALLPAPER_BUF
    mov edi, VGA_PALETTE_ADDR
    mov ecx, 256
.pal:
    movzx eax, byte [esi]
    shl eax, 2
    shl eax, 16
    mov ebx, eax
    movzx eax, byte [esi+1]
    shl eax, 2
    shl eax, 8
    or ebx, eax
    movzx eax, byte [esi+2]
    shl eax, 2
    or ebx, eax
    mov [edi], ebx
    add esi, 3
    add edi, 4
    dec ecx
    jnz .pal

    ; Render 320x200 pixel indices to BACKBUF (32-bit pixels)
    mov esi, WALLPAPER_BUF + 768
    mov edi, BACKBUF
    mov ecx, 64000
.render:
    movzx eax, byte [esi]
    shl eax, 2
    add eax, VGA_PALETTE_ADDR
    mov eax, [eax]
    mov [edi], eax
    inc esi
    add edi, 4
    dec ecx
    jnz .render

.done:
    popad
    ; Save rendered wallpaper to its own buffer
    mov esi, BACKBUF
    mov edi, WALLPAPER_RENDERED
    mov ecx, SCREEN_SIZE / 4
    rep movsd
    ret
; =============================================================================
; UART (COM1, 0x3F8)
; =============================================================================
uart_init:
    push eax
    push edx
    mov dx, 0x3F9
    xor al, al
    out dx, al
    mov dx, 0x3FB
    mov al, 0x80
    out dx, al
    mov dx, 0x3F8
    mov al, 1
    out dx, al
    mov dx, 0x3F9
    xor al, al
    out dx, al
    mov dx, 0x3FB
    mov al, 0x03
    out dx, al
    mov dx, 0x3FA
    mov al, 0xC7
    out dx, al
    mov dx, 0x3FC
    mov al, 0x0B
    out dx, al
    pop edx
    pop eax
    ret

uart_putc:
    push eax
    push ebx
    push ecx
    push edx
    mov bl, al
    mov ecx, 100000
.wait:
    mov dx, 0x3FD
    in al, dx
    test al, 0x20
    jnz .send
    loop .wait
.send:
    mov dx, 0x3F8
    mov al, bl
    out dx, al
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

uart_puts:
    push eax
    push esi
.loop:
    lodsb
    test al, al
    jz .done
    call uart_putc
    jmp .loop
.done:
    pop esi
    pop eax
    ret

uart_getc:
    push edx
    mov dx, 0x3FD
    in al, dx
    test al, 0x01
    jz .none
    mov dx, 0x3F8
    in al, dx
    pop edx
    ret
.none:
    xor al, al
    pop edx
    ret

; =============================================================================
; ATA PIO driver
; =============================================================================
ata_wait_bsy:
    push ecx
    push edx
    mov ecx, 0x100000
.loop:
    mov dx, 0x1F7
    in al, dx
    test al, 0x80
    jz .done
    loop .loop
    stc
    pop edx
    pop ecx
    ret
.done:
    clc
    pop edx
    pop ecx
    ret

ata_wait_drq:
    push ecx
    push edx
    mov ecx, 0x100000
.loop:
    mov dx, 0x1F7
    in al, dx
    test al, 0x80
    jnz .cont
    test al, 0x08
    jnz .ok
    test al, 0x01
    jnz .err
.cont:
    loop .loop
    stc
    pop edx
    pop ecx
    ret
.ok:
    clc
    pop edx
    pop ecx
    ret
.err:
    stc
    pop edx
    pop ecx
    ret

ata_delay400:
    push eax
    push edx
    mov dx, 0x1F7
    in al, dx
    in al, dx
    in al, dx
    in al, dx
    pop edx
    pop eax
    ret

ata_read_sector:
    pushad
    call ata_wait_bsy
    jc .err
    mov eax, esi
    shr eax, 24
    and al, 0x0F
    mov cl, [ata_drive]
    and cl, 0xF0
    or al, cl
    mov dx, 0x1F6
    out dx, al
    call ata_delay400
    mov dx, 0x1F2
    mov al, 1
    out dx, al
    mov eax, esi
    mov dx, 0x1F3
    out dx, al
    shr eax, 8
    mov dx, 0x1F4
    out dx, al
    shr eax, 8
    mov dx, 0x1F5
    out dx, al
    mov dx, 0x1F7
    mov al, 0x20
    out dx, al
    call ata_wait_drq
    jc .err
    mov dx, 0x1F0
    mov ecx, 256
    cld
.loop:
    in ax, dx
    stosw
    dec ecx
    jnz .loop
    popad
    clc
    ret
.err:
    popad
    stc
    ret

ata_write_sector:
    pushad
    mov ebx, edi
    call ata_wait_bsy
    jc .err
    mov eax, esi
    shr eax, 24
    and al, 0x0F
    mov cl, [ata_drive]
    and cl, 0xF0
    or al, cl
    mov dx, 0x1F6
    out dx, al
    call ata_delay400
    mov dx, 0x1F2
    mov al, 1
    out dx, al
    mov eax, esi
    mov dx, 0x1F3
    out dx, al
    shr eax, 8
    mov dx, 0x1F4
    out dx, al
    shr eax, 8
    mov dx, 0x1F5
    out dx, al
    mov dx, 0x1F7
    mov al, 0x30
    out dx, al
    call ata_wait_drq
    jc .err
    mov dx, 0x1F0
    mov ecx, 256
    mov esi, ebx
    cld
.loop:
    lodsw
    out dx, ax
    dec ecx
    jnz .loop
    mov dx, 0x1F7
    mov al, 0xE7
    out dx, al
    call ata_wait_bsy
    jc .err
    popad
    clc
    ret
.err:
    popad
    stc
    ret
	icon_drag_update:
    pushad
    mov ecx, [icon_drag_slot]
    mov eax, [mouse_x]
    sub eax, [icon_drag_off_x]
    mov [icon_x + ecx*4], eax
    mov eax, [mouse_y]
    sub eax, [icon_drag_off_y]
    mov [icon_y + ecx*4], eax
    mov byte [dirty], 1
    popad
    ret

icon_snap:
    pushad
    mov ecx, [icon_drag_slot]
    mov eax, [icon_x + ecx*4]
    sub eax, ICON_GRID_X
    cmp eax, 0
    jge .col_pos
    xor eax, eax
.col_pos:
    xor edx, edx
    mov ebx, ICON_CELL_W
    div ebx
    cmp edx, ICON_CELL_W / 2
    jb .col_noround
    inc eax
.col_noround:
    cmp eax, ICON_COLS
    jb .col_ok
    mov eax, ICON_COLS - 1
.col_ok:
    imul eax, ICON_CELL_W
    add eax, ICON_GRID_X
    mov [icon_x + ecx*4], eax
    mov eax, [icon_y + ecx*4]
    sub eax, ICON_GRID_Y
    cmp eax, 0
    jge .row_pos
    xor eax, eax
.row_pos:
    xor edx, edx
    mov ebx, ICON_CELL_H
    div ebx
    cmp edx, ICON_CELL_H / 2
    jb .row_noround
    inc eax
.row_noround:
    cmp eax, ICON_ROWS
    jb .row_ok
    mov eax, ICON_ROWS - 1
.row_ok:
    imul eax, ICON_CELL_H
    add eax, ICON_GRID_Y
    mov [icon_y + ecx*4], eax
    popad
    ret
alt_tab_show:
    pushad
    cmp byte [alt_tab_active], 0
    jne .advance

    ; Build list of visible windows from win_order (bottom to top)
    mov dword [alt_tab_count], 0
    xor ecx, ecx
.build_loop:
    cmp ecx, MAX_WINDOWS
    jae .build_done
    movzx ebx, byte [win_order + ecx]
    call win_ptr
    cmp dword [eax + WVIS], 1
    jne .build_next
    mov edx, [alt_tab_count]
    mov [alt_tab_list + edx], bl
    inc dword [alt_tab_count]
.build_next:
    inc ecx
    jmp .build_loop
.build_done:

    cmp dword [alt_tab_count], 0
    je .done
    mov byte [alt_tab_active], 1

    ; highlight starts at 1 (the window below current top)
    cmp dword [alt_tab_count], 1
    jbe .set_zero
    mov dword [alt_tab_index], 1
    jmp .done
.set_zero:
    mov dword [alt_tab_index], 0
    jmp .done

.advance:
    mov eax, [alt_tab_index]
    inc eax
    cmp eax, [alt_tab_count]
    jb .idx_ok
    xor eax, eax
.idx_ok:
    mov [alt_tab_index], eax

.done:
    mov byte [dirty], 1
    popad
    ret

alt_tab_commit:
    pushad
    mov eax, [alt_tab_index]
    cmp eax, [alt_tab_count]
    jae .clear
    mov ecx, [alt_tab_count]
    dec ecx
    sub ecx, eax
    movzx ebx, byte [alt_tab_list + ecx]
    call raise_window
.clear:
    mov byte [alt_tab_active], 0
    mov byte [dirty], 1
    popad
    ret

; EAX = window mode, returns ESI = icon pointer
at_icon_for_mode:
    push ebx
    mov ebx, eax
    mov esi, icon_terminal
    cmp ebx, APP_TERMINAL
    je .done
    mov esi, icon_files
    cmp ebx, APP_FILES
    je .done
    mov esi, icon_browser
    cmp ebx, APP_BROWSER
    je .done
    mov esi, icon_about
    cmp ebx, APP_ABOUT
    je .done
    mov esi, icon_notepad
    cmp ebx, APP_NOTEPAD
    je .done
    mov esi, icon_paint
    cmp ebx, APP_PAINT
    je .done
    mov esi, icon_calc
    cmp ebx, APP_CALC
    je .done
    mov esi, icon_snake
.done:
    pop ebx
    ret

; EAX = window mode, returns ESI = title string
at_title_for_mode:
    push ebx
    mov ebx, eax
    mov esi, str_title_terminal
    cmp ebx, APP_TERMINAL
    je .done
    mov esi, str_title_files
    cmp ebx, APP_FILES
    je .done
    mov esi, str_title_browser
    cmp ebx, APP_BROWSER
    je .done
    mov esi, str_title_about
    cmp ebx, APP_ABOUT
    je .done
    mov esi, str_title_notepad
    cmp ebx, APP_NOTEPAD
    je .done
    mov esi, str_title_paint
    cmp ebx, APP_PAINT
    je .done
    mov esi, str_title_calc
    cmp ebx, APP_CALC
    je .done
    mov esi, str_title_snake
.done:
    pop ebx
    ret

draw_alt_tab:
    cmp byte [alt_tab_active], 0
    je .done

    pushad
    mov eax, 0
    mov ebx, 0
    mov ecx, 320
    mov edx, 180
    mov esi, COLOR_BLACK
    call draw_rect
    popad

    mov eax, [alt_tab_count]
    imul eax, 20
    add eax, 12
    mov [at_panel_h], eax
    mov dword [at_panel_w], 220
    mov dword [at_panel_x], 50
    mov eax, 180
    sub eax, [at_panel_h]
    sar eax, 1
    mov [at_panel_y], eax

    mov eax, [at_panel_x]
    mov ebx, [at_panel_y]
    mov ecx, [at_panel_w]
    mov edx, [at_panel_h]
    mov esi, COLOR_WHITE
    call draw_rect

    mov eax, [at_panel_x]
    inc eax
    mov ebx, [at_panel_y]
    inc ebx
    mov ecx, [at_panel_w]
    sub ecx, 2
    mov edx, [at_panel_h]
    sub edx, 2
    mov esi, COLOR_DGRAY
    call draw_rect

    xor ebp, ebp
.row_loop:
    cmp ebp, [alt_tab_count]
    jae .rows_done

    mov eax, [alt_tab_count]
    dec eax
    sub eax, ebp
    movzx eax, byte [alt_tab_list + eax]
    mov [at_win_idx], eax

    mov eax, [at_panel_y]
    inc eax
    mov ecx, ebp
    imul ecx, 20
    add eax, ecx
    mov [at_row_y], eax

    cmp ebp, [alt_tab_index]
    jne .no_hl
    mov eax, [at_panel_x]
    inc eax
    mov ebx, [at_row_y]
    mov ecx, [at_panel_w]
    sub ecx, 2
    mov edx, 20
    mov esi, COLOR_BLUE
    call draw_rect
.no_hl:

    mov ebx, [at_win_idx]
    call win_ptr
    mov eax, [eax + WMODE]
    mov [at_mode], eax

    mov eax, [at_mode]
    call at_icon_for_mode
    push esi
    mov edi, [at_panel_x]
    add edi, 4
    mov edx, [at_row_y]
    add edx, 2
    pop esi
    call draw_app_icon

    mov eax, [at_mode]
    call at_title_for_mode
    mov edi, [at_panel_x]
    add edi, 26
    mov edx, [at_row_y]
    add edx, 6
    mov ebx, COLOR_WHITE
    call draw_text

    inc ebp
    jmp .row_loop
.rows_done:
.done:
    ret

at_panel_x:   dd 0
at_panel_y:   dd 0
at_panel_w:   dd 0
at_panel_h:   dd 0
at_row_y:     dd 0
at_win_idx:   dd 0
at_mode:      dd 0

	cycle_window:
    pushad
    mov ebp, [top_win]
    mov ecx, 1
.try:
    cmp ecx, MAX_WINDOWS
    ja .done
    mov eax, ebp
    add eax, ecx
    xor edx, edx
    mov esi, MAX_WINDOWS
    div esi
    mov ebx, edx
    call win_ptr
    cmp dword [eax + WVIS], 1
    jne .next
    call raise_window
    mov byte [dirty], 1
    popad
    ret
.next:
    inc ecx
    jmp .try
.done:
    popad
    ret


rtc_update:
    pushad
    mov al, 0x04
    out 0x70, al
    in al, 0x71
    mov [rtc_h], al
    mov al, 0x02
    out 0x70, al
    in al, 0x71
    mov [rtc_m], al
    mov al, 0x07
    out 0x70, al
    in al, 0x71
    mov [rtc_day], al
    mov al, 0x06
    out 0x70, al
    in al, 0x71
    mov [rtc_dow], al
    mov al, 0x0B
    out 0x70, al
    in al, 0x71
    test al, 0x04
    jnz .binary
    mov al, [rtc_h]
    call bcd2bin
    mov [rtc_h], al
    mov al, [rtc_m]
    call bcd2bin
    mov [rtc_m], al
    mov al, [rtc_day]
    call bcd2bin
    mov [rtc_day], al
    mov al, [rtc_dow]
    call bcd2bin
    mov [rtc_dow], al

.binary:
    mov al, [rtc_h]
    xor ah, ah
    mov bl, 10
    div bl
    add al, '0'
    mov [clock_str], al
    mov al, ah
    add al, '0'
    mov [clock_str+1], al
    mov byte [clock_str+2], ':'
    mov al, [rtc_m]
    xor ah, ah
    mov bl, 10
    div bl
    add al, '0'
    mov [clock_str+3], al
    mov al, ah
    add al, '0'
    mov [clock_str+4], al
    mov byte [clock_str+5], 0

    ; Format "Mon 22"
    mov al, [rtc_dow]
    cmp al, 1
    jge .d1
    mov al, 1
.d1:
    cmp al, 7
    jle .d2
    mov al, 1
.d2:
    dec al
    movzx eax, al
    imul eax, 3
    lea esi, [dow_names + eax]
    mov edi, date_str
    mov cl, 3
.dcopy:
    lodsb
    mov [edi], al
    inc edi
    dec cl
    jnz .dcopy
    mov byte [edi], ' '
    inc edi

    mov al, [rtc_day]
    xor ah, ah
    mov bl, 10
    div bl
    cmp al, 0
    jne .dthree
    mov byte [edi], ' '
    inc edi
    add ah, '0'
    mov [edi], ah
    inc edi
    jmp .ddone
.dthree:
    add al, '0'
    add ah, '0'
    mov [edi], al
    inc edi
    mov [edi], ah
    inc edi
.ddone:
    mov byte [edi], 0
    popad
    ret

bcd2bin:
    push ebx
    push ecx
    mov bl, al
    and al, 0x0F
    shr bl, 4
    mov cl, 10
    movzx ecx, cl
    movzx ebx, bl
    imul ebx, ecx
    add al, bl
    pop ecx
    pop ebx
    ret

mouse_init:
    call ps2_wait_write
    mov al, 0xA8
    out 0x64, al
    call ps2_wait_write
    mov al, 0x20
    out 0x64, al
    call ps2_wait_read
    in al, 0x60
    or al, 2
    push eax
    call ps2_wait_write
    mov al, 0x60
    out 0x64, al
    call ps2_wait_write
    pop eax
    out 0x60, al
    call ps2_wait_write
    mov al, 0xD4
    out 0x64, al
    call ps2_wait_write
    mov al, 0xF4
    out 0x60, al
    call ps2_wait_read
    in al, 0x60
    cmp al, 0xFA
    jne .done
    mov byte [mouse_enabled], 1
.done:
    ret

ps2_wait_write:
    push ecx
    mov ecx, 100000
.loop:
    in al, 0x64
    test al, 2
    jz .done
    loop .loop
.done:
    pop ecx
    ret

ps2_wait_read:
    push ecx
    mov ecx, 100000
.loop:
    in al, 0x64
    test al, 1
    jnz .done
    loop .loop
.done:
    pop ecx
    ret

mouse_poll:
    cmp byte [mouse_enabled], 1
    jne .done
.read:
    in al, 0x64
    test al, 1
    jz .done
    test al, 0x20
    jz .done
    in al, 0x60
    cmp byte [mouse_packet_pos], 0
    jne .byte1
    test al, 8
    jz .read
    mov [mouse_packet], al
    mov byte [mouse_packet_pos], 1
    jmp .read
.byte1:
    cmp byte [mouse_packet_pos], 1
    jne .byte2
    mov [mouse_packet+1], al
    mov byte [mouse_packet_pos], 2
    jmp .read
.byte2:
    mov [mouse_packet+2], al
    mov byte [mouse_packet_pos], 0
    mov al, [mouse_packet]
    test al, 0x40
    jnz .read
    test al, 0x80
    jnz .read
    movsx eax, byte [mouse_packet+1]
    add [mouse_x], eax
    cmp dword [mouse_x], 0
    jge .x1
    mov dword [mouse_x], 0
.x1:
    cmp dword [mouse_x], 312
    jle .x2
    mov dword [mouse_x], 312
.x2:
    movsx eax, byte [mouse_packet+2]
    sub [mouse_y], eax
    cmp dword [mouse_y], 0
    jge .y1
    mov dword [mouse_y], 0
.y1:
    cmp dword [mouse_y], 189
    jle .y2
    mov dword [mouse_y], 189
.y2:
    mov al, [mouse_packet]
    and al, 1
    mov bl, [mouse_buttons]
    mov [mouse_buttons], al
    cmp al, bl
    je .no_transition
    test al, 1
    jz .release
    call mouse_down
    jmp .no_transition
.release:
    call mouse_up
.no_transition:
    mov al, [mouse_packet]
    and al, 2
    shr al, 1
    mov bl, [mouse_right]
    mov [mouse_right], al
    cmp al, bl
    je .no_right
    test al, 1
    jz .no_right
    call mouse_down_right
.no_right:
    test byte [mouse_buttons], 1
    jz .no_drag
    cmp dword [drag_mode], 0
    je .maybe_icon
    call drag_update
    jmp .no_drag
.maybe_icon:
    cmp dword [icon_drag_slot], -1
    je .maybe_paint
    call icon_drag_update
    jmp .no_drag
.maybe_paint:
    cmp byte [paint_drawing], 0
    je .no_drag
    call paint_stroke
.no_drag:
    mov byte [dirty], 1
    jmp .read
.done:
    ret
mouse_down_right:
    ; Taskbar
    cmp dword [mouse_y], TASKBAR_Y
    jge .no_ctx

    ; Start menu / submenu (only when open)
    cmp byte [start_open], 0
    je .check_windows
    cmp dword [mouse_x], 2
    jl .check_submenu
    cmp dword [mouse_x], 136
    jg .check_submenu
    cmp dword [mouse_y], 76
    jl .check_submenu
    cmp dword [mouse_y], 176
    jle .no_ctx
.check_submenu:
    cmp dword [mouse_x], 136
    jl .check_windows
    cmp dword [mouse_x], 216
    jg .check_windows
    cmp dword [mouse_y], 144
    jl .check_windows
    cmp dword [mouse_y], 178
    jle .no_ctx

.check_windows:
    mov ecx, MAX_WINDOWS
.win_loop:
    dec ecx
    js .open_ctx
    movzx ebx, byte [win_order + ecx]
    call win_ptr
    cmp dword [eax + WVIS], 1
    jne .win_loop
    mov edi, [mouse_x]
    cmp edi, [eax + WX]
    jl .win_loop
    mov edx, [eax + WX]
    add edx, [eax + WW]
    cmp edi, edx
    jge .win_loop
    mov edi, [mouse_y]
    cmp edi, [eax + WY]
    jl .win_loop
    mov edx, [eax + WY]
    add edx, [eax + WH]
    cmp edi, edx
    jge .win_loop
    jmp .no_ctx

.open_ctx:
    mov eax, [mouse_x]
    mov ecx, eax
    add ecx, 80
    cmp ecx, 320
    jle .x_ok
    mov eax, 320
    sub eax, 80
.x_ok:
    mov [ctx_draw_x], eax
    mov eax, [mouse_y]
    mov ecx, eax
    add ecx, 56
    cmp ecx, TASKBAR_Y
    jle .y_ok
    mov eax, TASKBAR_Y
    sub eax, 56
.y_ok:
    mov [ctx_draw_y], eax
    mov byte [ctx_open], 1
    mov byte [dirty], 1
    ret

.no_ctx:
    mov byte [ctx_open], 0
    mov byte [dirty], 1
    ret
mouse_down:
    pushad
    cmp byte [cli_active], 0
    jne .done
    cmp byte [ctx_open], 0
    je .sm_check

    mov eax, [mouse_x]
    mov ecx, [ctx_draw_x]
    cmp eax, ecx
    jl .close_ctx
    add ecx, 80
    cmp eax, ecx
    jg .close_ctx

    mov eax, [mouse_y]
    mov ecx, [ctx_draw_y]
    cmp eax, ecx
    jl .close_ctx
    add ecx, 56
    cmp eax, ecx
    jg .close_ctx

    mov edx, eax
    sub edx, [ctx_draw_y]
    mov byte [ctx_open], 0
    mov byte [dirty], 1
    cmp edx, 14
    jl .ctx_new
    cmp edx, 28
    jl .ctx_newpaint
    cmp edx, 42
    jl .ctx_refresh
    mov ebx, 3
    call open_window
    jmp .done

.ctx_newpaint:
    mov ebx, 6
    call open_window
    jmp .done

.ctx_new:
    mov dword [notepad_len], 0
    mov byte [notepad_buf], 0
    mov byte [notepad_saved], 0
    mov edi, np_filename
    mov ecx, 16
    xor eax, eax
    rep stosb
    mov edi, np_filename
    mov esi, str_note_filename
    mov ecx, 9
    rep movsb
    mov ebx, 4
    call open_window
    jmp .done

.ctx_refresh:
    jmp .done

.close_ctx:
    mov byte [ctx_open], 0
    mov byte [dirty], 1
    ; Start menu takes priority over any window behind it
    cmp byte [start_open], 1
    jne .md_no_sm

    ; Start button?
    cmp dword [mouse_x], 4
    jl .md_sm_menu
    cmp dword [mouse_x], 62
    jg .md_sm_menu
    cmp dword [mouse_y], TASKBAR_Y
    jl .md_sm_menu
    jmp .md_to_desktop

.md_sm_menu:
    ; Start menu box (2..136 x, 76..176 y)
    cmp dword [mouse_x], 2
    jl .md_sm_sub
    cmp dword [mouse_x], 136
    jg .md_sm_sub
    cmp dword [mouse_y], 76
    jl .md_sm_sub
    cmp dword [mouse_y], 176
    jg .md_sm_sub
    jmp .md_to_desktop

.md_sm_sub:
    ; Submenu box (136..216 x, 144..178 y)
    cmp dword [mouse_x], 136
    jl .md_no_sm
    cmp dword [mouse_x], 216
    jg .md_no_sm
    cmp dword [mouse_y], 144
    jl .md_no_sm
    cmp dword [mouse_y], 178
    jg .md_no_sm

.md_to_desktop:
    call mouse_down_desktop
    jmp .done

.md_no_sm:


.sm_check:
    cmp byte [start_open], 1
    jne .no_ctx
    call mouse_down_desktop
    jmp .done
.no_ctx:
    mov ecx, MAX_WINDOWS
.top_loop:
    dec ecx
    js .no_window
    movzx ebx, byte [win_order + ecx]
    call win_ptr
    cmp dword [eax + WVIS], 1
    jne .top_loop
    mov edi, [mouse_x]
    cmp edi, [eax + WX]
    jl .top_loop
    mov edx, [eax + WX]
    add edx, [eax + WW]
    cmp edi, edx
    jge .top_loop
    mov edi, [mouse_y]
    cmp edi, [eax + WY]
    jl .top_loop
    mov edx, [eax + WY]
    add edx, [eax + WH]
    cmp edi, edx
    jge .top_loop
    push eax
    call raise_window
    pop eax
    mov edi, [mouse_x]
    mov edx, [eax + WX]
    add edx, [eax + WW]
    sub edx, 14
    cmp edi, edx
    jl .try_min
    add edx, 10
    cmp edi, edx
    jae .try_min
    mov edi, [mouse_y]
    mov edx, [eax + WY]
    add edx, 4
    cmp edi, edx
    jl .try_min
    add edx, 10
    cmp edi, edx
    jae .try_min
    mov dword [eax + WVIS], 2
    jmp .done
.try_min:
    mov edi, [mouse_x]
    mov edx, [eax + WX]
    add edx, [eax + WW]
    sub edx, 25
    cmp edi, edx
    jl .not_close
    add edx, 10
    cmp edi, edx
    jae .not_close
    mov edi, [mouse_y]
    mov edx, [eax + WY]
    add edx, 4
    cmp edi, edx
    jl .not_close
    add edx, 10
    cmp edi, edx
    jae .not_close
    mov dword [eax + WVIS], 3
    jmp .done
.not_close:
    mov edi, [mouse_x]
    sub edi, [eax + WX]
    mov edx, [mouse_y]
    sub edx, [eax + WY]
    cmp dword [eax + WMODE], APP_NOTEPAD
    jne .np_files
    cmp edx, 17
    jl .np_files
    push eax
    call notepad_click
    pop eax
    jmp .done
.np_files:
    cmp dword [eax + WMODE], APP_FILES
    jne .np_paint
    cmp edx, 17
    jl .np_skip
    push eax
    call files_click
    pop eax
    jmp .done
.np_paint:
    cmp dword [eax + WMODE], APP_PAINT
    jne .np_calc
    cmp edx, 17
    jl .np_skip
    push eax
    call paint_click
    pop eax
    jmp .done
.np_calc:
    cmp dword [eax + WMODE], APP_CALC
    jne .np_snake
    cmp edx, 17
    jl .np_skip
    push eax
    mov eax, edi
    mov ebx, edx
    call calc_handle_click
    pop eax
    jmp .done
.np_snake:
    cmp dword [eax + WMODE], APP_SNAKE
    jne .np_settings
    cmp edx, 17
    jl .np_skip
    push eax
    call snake_click
    pop eax
    jmp .done
.np_settings:
    cmp dword [eax + WMODE], APP_SETTINGS
    jne .np_skip
    cmp edx, 17
    jl .np_skip
    push eax
    call settings_click
    pop eax
    jmp .done
.np_skip:
    xor ecx, ecx
    cmp edx, 2
    jl .check_edges
    cmp edx, 15
    jg .check_edges
    cmp edi, 4
    jl .check_edges
    mov esi, [eax + WW]
    sub esi, 4
    cmp edi, esi
    jg .check_edges
    mov ecx, DRAG_MOVE
    jmp .set_drag
.check_edges:
    cmp edi, 4
    jge .no_left
    or ecx, DRAG_L
.no_left:
    mov esi, [eax + WW]
    sub esi, 4
    cmp edi, esi
    jl .no_right
    or ecx, DRAG_R
.no_right:
    cmp edx, 4
    jge .no_top
    or ecx, DRAG_T
.no_top:
    mov esi, [eax + WH]
    sub esi, 4
    cmp edx, esi
    jl .no_bottom
    or ecx, DRAG_B
.no_bottom:
.set_drag:
    test ecx, ecx
    jz .done
    mov [drag_mode], ecx
    mov ebx, [top_win]
    mov [drag_win], ebx

    ; If dragging a maximized window's title bar, restore it
    test ecx, DRAG_MOVE
    jz .no_restore
    cmp dword [max_active], 1
    jne .no_restore
    cmp dword [eax + WX], 0
    jne .no_restore
    cmp dword [eax + WY], 0
    jne .no_restore
    cmp dword [eax + WW], 320
    jne .no_restore
    cmp dword [eax + WH], 180
    jne .no_restore

    ; Restore size
    mov ecx, [max_prev_w]
    mov [eax + WW], ecx
    mov [eax + WAW], ecx
    mov ecx, [max_prev_h]
    mov [eax + WH], ecx
    mov [eax + WAH], ecx

    ; Position centered on cursor
    mov ecx, [max_prev_w]
    shr ecx, 1
    mov esi, [mouse_x]
    sub esi, ecx
    cmp esi, 0
    jge .r1
    xor esi, esi
.r1:
    mov ecx, [max_prev_w]
    add ecx, esi
    cmp ecx, 320
    jle .r2
    mov esi, 320
    sub esi, [max_prev_w]
    cmp esi, 0
    jge .r2
    xor esi, esi
.r2:
    mov [eax + WX], esi
    mov esi, [mouse_y]
    sub esi, 10
    cmp esi, 0
    jge .r3
    xor esi, esi
.r3:
    mov [eax + WY], esi
    mov dword [max_active], 0

.no_restore:
    mov esi, [mouse_x]
    sub esi, [eax + WX]
    mov [drag_off_x], esi
    mov esi, [mouse_y]
    sub esi, [eax + WY]
    mov [drag_off_y], esi
    mov esi, [eax + WX]
    mov [drag_orig_x], esi
    mov esi, [eax + WY]
    mov [drag_orig_y], esi
    mov esi, [eax + WW]
    mov [drag_orig_w], esi
    mov esi, [eax + WH]
    mov [drag_orig_h], esi
    jmp .done
.no_window:
    call mouse_down_desktop
.done:
    mov byte [dirty], 1
    popad
    ret

mouse_up:
    mov byte [paint_drawing], 0
    ; Window snap
    mov ecx, [drag_mode]
    test ecx, DRAG_MOVE
    jz .skip_snap

    ; Determine horizontal zone: 0=none, 1=left, 2=right
    mov eax, [mouse_x]
    xor edx, edx
    cmp eax, 70
    jl .h_left
    cmp eax, 250
    jg .h_right
    jmp .h_done
.h_left:
    mov edx, 1
    jmp .h_done
.h_right:
    mov edx, 2
.h_done:

    ; Determine vertical zone: 0=none, 1=top, 2=bottom
    mov eax, [mouse_y]
    xor ecx, ecx
    cmp eax, 70
    jl .v_top
    cmp eax, 130
    jg .v_bottom
    jmp .v_done
.v_top:
    mov ecx, 1
    jmp .v_done
.v_bottom:
    mov ecx, 2
.v_done:

    ; Now: edx = horizontal (0/1/2), ecx = vertical (0/1/2)
    test edx, edx
    jz .no_h
    test ecx, ecx
    jz .h_only

    ; Corner (both set)
    mov ebx, [drag_win]
    call win_ptr
    call save_max_rect
    cmp edx, 1
    jne .c_r
    mov dword [eax + WX], 0
    jmp .c_x_done
.c_r:
    mov dword [eax + WX], 160
.c_x_done:
    cmp ecx, 1
    jne .c_b
    mov dword [eax + WY], 0
    jmp .c_y_done
.c_b:
    mov dword [eax + WY], 90
.c_y_done:
    mov dword [eax + WW], 160
    mov dword [eax + WAW], 160
    mov dword [eax + WH], 90
    mov dword [eax + WAH], 90
    jmp .skip_snap

.h_only:
    ; Left or right half
    mov ebx, [drag_win]
    call win_ptr
    call save_max_rect
    cmp edx, 1
    jne .h_half_r
    mov dword [eax + WX], 0
    jmp .h_half_x
.h_half_r:
    mov dword [eax + WX], 160
.h_half_x:
    mov dword [eax + WY], 0
    mov dword [eax + WW], 160
    mov dword [eax + WAW], 160
    mov dword [eax + WH], 180
    mov dword [eax + WAH], 180
    jmp .skip_snap

.no_h:
    test ecx, ecx
    jz .skip_snap
    cmp ecx, 1
    jne .skip_snap
    ; Top only → maximize
    mov ebx, [drag_win]
    call win_ptr
    call save_max_rect
    mov dword [eax + WX], 0
    mov dword [eax + WY], 0
    mov dword [eax + WW], 320
    mov dword [eax + WAW], 320
    mov dword [eax + WH], 180
    mov dword [eax + WAH], 180
    mov dword [max_active], 1
    jmp .skip_snap

.skip_snap:
    mov dword [drag_mode], 0
    cmp dword [icon_drag_slot], -1
    je .no_icon
    mov ecx, [icon_drag_slot]
    mov eax, [icon_x + ecx*4]
    sub eax, [icon_drag_orig_x]
    mov ebx, eax
    sar ebx, 31
    xor eax, ebx
    sub eax, ebx
    cmp eax, 4
    jae .snap
    mov eax, [icon_y + ecx*4]
    sub eax, [icon_drag_orig_y]
    mov ebx, eax
    sar ebx, 31
    xor eax, ebx
    sub eax, ebx
    cmp eax, 4
    jae .snap
    mov eax, [icon_drag_orig_x]
    mov [icon_x + ecx*4], eax
    mov eax, [icon_drag_orig_y]
    mov [icon_y + ecx*4], eax
    mov ebx, ecx
    cmp ecx, 5
    jb .ic_go
    inc ebx
.ic_go:
    call open_window
    jmp .clear_drag
    jmp .clear_drag
.snap:
    call icon_snap
.clear_drag:
    mov dword [icon_drag_slot], -1
.no_icon:
    mov byte [dirty], 1
    ret

save_max_rect:
    push ecx
    mov ecx, [eax + WX]
    mov [max_prev_x], ecx
    mov ecx, [eax + WY]
    mov [max_prev_y], ecx
    mov ecx, [eax + WW]
    mov [max_prev_w], ecx
    mov ecx, [eax + WH]
    mov [max_prev_h], ecx
    pop ecx
    ret

drag_update:
    pushad
    mov ebx, [drag_win]
    call win_ptr
    mov ecx, [drag_mode]
    test ecx, DRAG_MOVE
    jz .resize
    mov esi, [mouse_x]
    sub esi, [drag_off_x]
    mov edi, [mouse_y]
    sub edi, [drag_off_y]
    cmp esi, 0
    jge .m1
    xor esi, esi
.m1:
    mov edx, esi
    add edx, [eax + WW]
    cmp edx, SCREEN_W
    jle .m2
    mov esi, SCREEN_W
    sub esi, [eax + WW]
.m2:
    cmp edi, 0
    jge .m3
    xor edi, edi
.m3:
    mov edx, edi
    add edx, [eax + WH]
    cmp edx, TASKBAR_Y
    jle .m4
    mov edi, TASKBAR_Y
    sub edi, [eax + WH]
.m4:
    mov [eax + WX], esi
    mov [eax + WY], edi
    jmp .done
.resize:
    mov edx, [drag_orig_x]
    mov ebp, [drag_orig_y]
    mov esi, [drag_orig_w]
    mov edi, [drag_orig_h]
    test ecx, DRAG_L
    jz .no_l
    mov edx, [mouse_x]
    mov esi, [drag_orig_x]
    add esi, [drag_orig_w]
    sub esi, edx
.no_l:
    test ecx, DRAG_R
    jz .no_r
    mov esi, [mouse_x]
    sub esi, [drag_orig_x]
.no_r:
    test ecx, DRAG_T
    jz .no_t
    mov ebp, [mouse_y]
    mov edi, [drag_orig_y]
    add edi, [drag_orig_h]
    sub edi, ebp
.no_t:
    test ecx, DRAG_B
    jz .no_b
    mov edi, [mouse_y]
    sub edi, [drag_orig_y]
.no_b:
    cmp esi, WMIN_W
    jge .w_ok
    test ecx, DRAG_L
    jz .w_no_x
    mov edx, [drag_orig_x]
    add edx, [drag_orig_w]
    sub edx, WMIN_W
.w_no_x:
    mov esi, WMIN_W
.w_ok:
    cmp edi, WMIN_H
    jge .h_ok
    test ecx, DRAG_T
    jz .h_no_y
    mov ebp, [drag_orig_y]
    add ebp, [drag_orig_h]
    sub ebp, WMIN_H
.h_no_y:
    mov edi, WMIN_H
.h_ok:
    cmp edx, 0
    jge .cx
    xor edx, edx
.cx:
    cmp ebp, 0
    jge .cy
    xor ebp, ebp
.cy:
    mov ecx, edx
    add ecx, esi
    cmp ecx, SCREEN_W
    jle .cw
    mov esi, SCREEN_W
    sub esi, edx
.cw:
    mov ecx, ebp
    add ecx, edi
    cmp ecx, TASKBAR_Y
    jle .ch
    mov edi, TASKBAR_Y
    sub edi, ebp
.ch:
    mov [eax + WX], edx
    mov [eax + WY], ebp
    mov [eax + WW], esi
    mov [eax + WAW], esi
    mov [eax + WH], edi
    mov [eax + WAH], edi
.done:
    mov byte [dirty], 1
    popad
    ret

mouse_down_desktop:
    cmp dword [mouse_y], TASKBAR_Y
    jb .check_menu
    cmp dword [mouse_x], 4
    jb .chk_task_buttons
    cmp dword [mouse_x], 62
    ja .chk_task_buttons
    xor byte [start_open], 1
    mov byte [dirty], 1
    ret
.chk_task_buttons:
    cmp dword [mouse_x], 66
    jb .check_menu
    cmp dword [mouse_x], 270
    ja .check_menu
    mov eax, [mouse_x]
    sub eax, 66
    xor edx, edx
    mov ecx, [tb_pitch]
    test ecx, ecx
    jnz .pitch_ok
    mov ecx, 44
.pitch_ok:
    div ecx
    cmp edx, [tb_width]
    jae .check_menu
    mov [tb_click_slot], eax
    xor ebx, ebx
    xor ecx, ecx
.tb_find:
    cmp ebx, MAX_WINDOWS
    jae .check_menu
    movzx eax, byte [win_order + ebx]
    push ebx
    push ecx
    mov ebx, eax
    call win_ptr
    mov edx, [eax + WVIS]
    pop ecx
    pop ebx
    cmp edx, 0
    je .tb_skip
    cmp edx, 2
    je .tb_skip
    cmp ecx, [tb_click_slot]
    je .tb_got
    inc ecx
.tb_skip:
    inc ebx
    jmp .tb_find
.tb_got:
    movzx ebx, byte [win_order + ebx]
    call win_ptr
    cmp dword [eax + WVIS], 0
    jne .tb_focus
    mov dword [eax + WVIS], 1
.tb_focus:
    cmp dword [eax + WVIS], 3
    jne .tb_just_raise
    mov dword [eax + WVIS], 1
    mov dword [eax + WAW], 8
    mov dword [eax + WAH], 8
.tb_just_raise:
    call raise_window
    mov byte [start_open], 0
    mov byte [dirty], 1
    ret
.check_menu:
    cmp byte [start_open], 0
    je .check_icons
    cmp dword [mouse_x], 2
    jb .check_submenu
    cmp dword [mouse_x], 136
    ja .check_submenu
    cmp dword [mouse_y], 60
    jb .check_submenu
    cmp dword [mouse_y], 176
    ja .check_submenu
    cmp dword [mouse_y], 76
    jbe .m_term
    cmp dword [mouse_y], 92
    jbe .m_files
    cmp dword [mouse_y], 108
    jbe .m_browser
    cmp dword [mouse_y], 124
    jbe .m_notepad
    cmp dword [mouse_y], 140
    jbe .m_about
    cmp dword [mouse_y], 156
    jbe .m_settings
    call do_shutdown
    jmp .open_menu
.m_settings:
    mov ebx, 9
    jmp .open_menu
.m_about:
    mov ebx, 3
    jmp .open_menu
	.check_submenu:
    cmp dword [mouse_x], 136
    jl .check_icons
    cmp dword [mouse_x], 216
    jg .check_icons
    cmp dword [mouse_y], 144
    jl .check_icons
    cmp dword [mouse_y], 176
    jg .check_icons
    cmp dword [mouse_y], 160
    jbe .do_restart
    mov byte [start_open], 0
    mov byte [sm_sub_anim], 0
    jmp do_sleep
.do_restart:
    mov byte [start_open], 0
    mov byte [sm_sub_anim], 0
    call do_reboot
    ret
.m_term:
    mov ebx, 0
    jmp .open_menu
.m_files:
    mov ebx, 1
    jmp .open_menu
.m_browser:
    mov ebx, 2
    jmp .open_menu
.m_notepad:
    mov ebx, 4
.open_menu:
    call open_window
    ret
.check_icons:
    xor ecx, ecx
.icon_loop:
    cmp ecx, ICON_SLOTS
    jae .chk_app_icons
    mov eax, [icon_x + ecx*4]
    mov ebx, [mouse_x]
    cmp ebx, eax
    jl .icon_next
    add eax, 16
    cmp ebx, eax
    jg .icon_next
    mov eax, [icon_y + ecx*4]
    mov ebx, [mouse_y]
    cmp ebx, eax
    jl .icon_next
    add eax, 16
    cmp ebx, eax
    jg .icon_next
    mov [icon_drag_slot], ecx
    mov eax, [icon_x + ecx*4]
    mov [icon_drag_orig_x], eax
    mov eax, [icon_y + ecx*4]
    mov [icon_drag_orig_y], eax
    mov eax, [mouse_x]
    sub eax, [icon_x + ecx*4]
    mov [icon_drag_off_x], eax
    mov eax, [mouse_y]
    sub eax, [icon_y + ecx*4]
    mov [icon_drag_off_y], eax
    ret
.icon_next:
    inc ecx
    jmp .icon_loop
.chk_app_icons:
    cmp dword [mouse_y], 136
    jb .close_menu_if_any
    cmp dword [mouse_y], 168
    ja .close_menu_if_any
    cmp dword [mouse_x], 156
    jb .close_menu_if_any
    mov eax, [mouse_x]
    sub eax, 156
    xor edx, edx
    mov ecx, 70
    div ecx
    cmp eax, [app_count]
    jae .close_menu_if_any
    cmp eax, 3
    jae .close_menu_if_any
    mov [run_index], eax
    call run_app
    ret
.close_menu_if_any:
    cmp byte [start_open], 0
    je .done
    mov byte [start_open], 0
    mov byte [dirty], 1
.done:
    ret

keyboard_poll:
    in al, 0x64
    test al, 1
    jz .done
    test al, 0x20
    jnz .done
    in al, 0x60
    cmp byte [cli_active], 0
    jne .cli_dispatch
    test al, 0x80
    jz .make
    cmp al, 0xAA
    je .shift_up
    cmp al, 0xAA
    je .shift_up
    cmp al, 0xB6
    je .shift_up
    cmp al, 0x9D
    je .ctrl_up
    cmp al, 0xB8
    je .alt_up
    jmp .done
.shift_up:
    mov byte [shift_down], 0
    jmp .done
.ctrl_up:
    mov byte [np_ctrl_down], 0
    jmp .done
.alt_up:
    mov byte [alt_down], 0
    cmp byte [alt_tab_active], 0
    je .done
    call alt_tab_commit
    jmp .done
.make:
    cmp al, 0x2A
    je .shift_down_set
    cmp al, 0x36
    je .shift_down_set
    cmp al, 0x1D
    je .ctrl_down_set
    cmp al, 0x38
    je .alt_down_set
    cmp al, 0x0F
    je .tab_key
    mov [kb_scancode], al
    cmp al, 0x01
    jne .not_esc
    call get_focus_mode
    cmp eax, APP_SNAKE
    je .snake_key
    jmp .esc
.not_esc:
    cmp al, 0x5B
    je .winkey
    call get_focus_mode
    cmp eax, APP_TERMINAL
    je .terminal_key
    cmp eax, APP_BROWSER
    je .browser_key
    cmp eax, APP_NOTEPAD
    je .notepad_key
    cmp eax, APP_CALC
    je .calc_key
    cmp eax, APP_SNAKE
    je .snake_key
    jmp .done
.shift_down_set:
    mov byte [shift_down], 1
    jmp .done
.ctrl_down_set:
    mov byte [np_ctrl_down], 1
    jmp .done
.alt_down_set:
    mov byte [alt_down], 1
    jmp .done
.tab_key:
    cmp byte [alt_down], 1
    jne .done
    call alt_tab_show
    ret
.esc:
    cmp byte [ctx_open], 0
    je .esc_no_ctx
    mov byte [ctx_open], 0
    mov byte [dirty], 1
    ret
.esc_no_ctx:
    cmp byte [np_saveas_mode], 1
    jne .esc_close
    mov byte [np_saveas_mode], 0
    mov byte [dirty], 1
    ret
.esc_close:
    mov ebx, [top_win]
    call win_ptr
    mov dword [eax + WVIS], 0
    mov byte [start_open], 0
    mov byte [dirty], 1
    ret
	.winkey:
    xor byte [start_open], 1
    mov byte [dirty], 1
    ret
.terminal_key:
    cmp al, 0x49
    je .term_pgup
    cmp al, 0x51
    je .term_pgdn
    mov al, [kb_scancode]
    cmp al, 0x48
    je .hist_up
    cmp al, 0x50
    je .hist_down
    cmp al, 0x1C
    je .enter
    cmp al, 0x0E
    je .backspace
    cmp al, 0x39
    je .space
    call scancode_to_ascii
    test al, al
    jz .done
    jmp .append
.term_pgup:
    mov eax, [term_rows]
    sub eax, 9
    jle .term_pg_done
    cmp [term_view], eax
    jae .term_pg_done
    inc dword [term_view]
    mov byte [dirty], 1
    ret
.term_pgdn:
    cmp dword [term_view], 0
    je .term_pg_done
    dec dword [term_view]
    mov byte [dirty], 1
    ret
.term_pg_done:
    ret

.append:
    mov ecx, [input_len]
    cmp ecx, 30
    jae .done
    mov [input_buf + ecx], al
    inc ecx
    mov [input_len], ecx
    mov byte [input_buf + ecx], 0
    mov byte [dirty], 1
    ret
.space:
    mov al, ' '
    jmp .append
.backspace:
    mov ecx, [input_len]
    test ecx, ecx
    jz .done
    dec ecx
    mov [input_len], ecx
    mov byte [input_buf + ecx], 0
    mov byte [dirty], 1
    ret
.enter:
    call cmd_hist_push
    call execute_command
    mov dword [input_len], 0
    mov byte [input_buf], 0
    mov dword [cmd_hist_view], -1
    mov byte [dirty], 1
    ret
.hist_up:
    cmp dword [cmd_hist_count], 0
    je .done
    cmp dword [cmd_hist_view], -1
    jne .hu_dec
    mov eax, [cmd_hist_count]
    dec eax
    mov [cmd_hist_view], eax
    jmp .hu_load
.hu_dec:
    cmp dword [cmd_hist_view], 0
    jbe .done
    dec dword [cmd_hist_view]
.hu_load:
    mov eax, [cmd_hist_view]
    shl eax, 5
    add eax, cmd_history
    mov esi, eax
    mov edi, input_buf
    xor ecx, ecx
.hu_copy:
    lodsb
    test al, al
    jz .hu_end
    cmp ecx, 30
    jae .hu_end
    mov [edi + ecx], al
    inc ecx
    jmp .hu_copy
.hu_end:
    mov byte [edi + ecx], 0
    mov [input_len], ecx
    mov byte [dirty], 1
    ret
.hist_down:
    cmp dword [cmd_hist_view], -1
    je .done
    mov eax, [cmd_hist_view]
    inc eax
    cmp eax, [cmd_hist_count]
    jae .hd_clear
    mov [cmd_hist_view], eax
    jmp .hu_load
.hd_clear:
    mov dword [cmd_hist_view], -1
    mov dword [input_len], 0
    mov byte [input_buf], 0
    mov byte [dirty], 1
    ret
.browser_key:
    ret
.snake_key:
    mov al, [kb_scancode]
    cmp al, 0x01
    je .snk_pause
    cmp al, 0x13
    je .snk_restart
    cmp byte [snake_dead], 1
    je .done
    cmp byte [snake_started], 0
    jne .snk_dirs
    mov byte [snake_started], 1
.snk_dirs:
    cmp al, 0x48
    je .snk_up
    cmp al, 0x4D
    je .snk_right
    cmp al, 0x50
    je .snk_down
    cmp al, 0x4B
    je .snk_left
    ret
.snk_up:
    cmp byte [snake_dir], 2
    je .done
    mov byte [snake_next_dir], 0
    ret
.snk_right:
    cmp byte [snake_dir], 3
    je .done
    mov byte [snake_next_dir], 1
    ret
.snk_down:
    cmp byte [snake_dir], 0
    je .done
    mov byte [snake_next_dir], 2
    ret
.snk_left:
    cmp byte [snake_dir], 1
    je .done
    mov byte [snake_next_dir], 3
    ret
.snk_pause:
    cmp byte [snake_dead], 1
    je .done
    cmp byte [snake_started], 0
    je .done
    xor byte [snake_paused], 1
    mov byte [dirty], 1
    ret
.snk_restart:
    call snake_reset
    ret

.cli_dispatch:
    call cli_key
    ret

.calc_key:
    mov al, [kb_scancode]
    cmp byte [calc_error], 0
    jne .done
    cmp al, 0x1C
    je .ck_enter
    cmp al, 0x0E
    je .ck_bs
    cmp al, 0x4E
    je .ck_add
    cmp al, 0x4A
    je .ck_sub
    cmp al, 0x37
    je .ck_mul
    cmp al, 0x35
    je .ck_div
    cmp al, 0x01
    je .ck_clear
    cmp al, 0x53
    je .ck_dot
    ; digits 0-9
    cmp al, 0x0B
    je .ck_0
    cmp al, 0x02
    jb .done
    cmp al, 0x0A
    ja .ck_hi
    add al, '0' - 1
    call calc_append_digit
    jmp .ck_refresh
.ck_hi:
    cmp al, 0x0A
    jne .done
    mov al, '0'
    call calc_append_digit
    jmp .ck_refresh
.ck_0:
    mov al, '0'
    call calc_append_digit
    jmp .ck_refresh
.ck_enter:
    call calc_equals
    jmp .ck_refresh
.ck_clear:
    call calc_clear
    jmp .ck_refresh
.ck_bs:
    cmp dword [calc_display_len], 1
    jbe .ck_bs_zero
    dec dword [calc_display_len]
    mov ecx, [calc_display_len]
    mov byte [calc_display + ecx], 0
    jmp .ck_refresh
.ck_bs_zero:
    mov dword [calc_display_len], 1
    mov byte [calc_display], '0'
    mov byte [calc_display+1], 0
    jmp .ck_refresh
.ck_add:
    mov ecx, 1
    mov byte [calc_op_new], 1
    call calc_set_op
    jmp .ck_refresh
.ck_sub:
    mov ecx, 2
    mov byte [calc_op_new], 2
    call calc_set_op
    jmp .ck_refresh
.ck_mul:
    mov ecx, 3
    mov byte [calc_op_new], 3
    call calc_set_op
    jmp .ck_refresh
.ck_div:
    mov ecx, 4
    mov byte [calc_op_new], 4
    call calc_set_op
    jmp .ck_refresh
.ck_dot:
    ret
.ck_refresh:
    mov byte [dirty], 1
    ret
.notepad_key:
    mov al, [kb_scancode]
    cmp byte [np_saveas_mode], 1
    je .np_saveas_input
    cmp byte [np_ctrl_down], 0
    je .np_no_ctrl
    cmp al, 0x1F
    je .np_save
.np_no_ctrl:
    cmp al, 0x1C
    je .np_enter
    cmp al, 0x0E
    je .np_back
    cmp al, 0x39
    je .np_space
    call scancode_to_ascii
    test al, al
    jz .done
    jmp .np_append
.np_saveas_input:
    cmp al, 0x1C
    je .np_saveas_confirm
    cmp al, 0x0E
    je .np_saveas_bs
    cmp al, 0x39
    je .np_saveas_sp
    call scancode_to_ascii
    test al, al
    jz .done
    jmp .np_saveas_append
.np_saveas_sp:
    mov al, ' '
.np_saveas_append:
    mov ecx, [np_saveas_len]
    cmp ecx, 15
    jae .done
    mov [np_saveas_buf + ecx], al
    inc ecx
    mov [np_saveas_len], ecx
    mov byte [np_saveas_buf + ecx], 0
    mov byte [dirty], 1
    ret
.np_saveas_bs:
    mov ecx, [np_saveas_len]
    test ecx, ecx
    jz .done
    dec ecx
    mov [np_saveas_len], ecx
    mov byte [np_saveas_buf + ecx], 0
    mov byte [dirty], 1
    ret
.np_saveas_confirm:
    cmp dword [np_saveas_len], 0
    je .np_saveas_cancel
    mov esi, np_saveas_buf
    mov edi, np_filename
    mov ecx, 16
    xor eax, eax
    push edi
    rep stosb
    pop edi
    mov ecx, [np_saveas_len]
    cmp ecx, 15
    jbe .sa_len_ok
    mov ecx, 15
.sa_len_ok:
    mov esi, np_saveas_buf
    rep movsb
    mov byte [np_saveas_mode], 0
    call notepad_save
    ret
.np_saveas_cancel:
    mov byte [np_saveas_mode], 0
    mov byte [dirty], 1
    ret
.np_save:
    call notepad_save
    ret
.np_space:
    mov al, ' '
.np_append:
    mov ecx, [notepad_len]
    cmp ecx, 255
    jae .done
    mov [notepad_buf + ecx], al
    inc ecx
    mov [notepad_len], ecx
    mov byte [dirty], 1
    ret
.np_enter:
    mov ecx, [notepad_len]
    cmp ecx, 255
    jae .done
    mov byte [notepad_buf + ecx], 10
    inc ecx
    mov [notepad_len], ecx
    mov byte [dirty], 1
    ret
.np_back:
    mov ecx, [notepad_len]
    test ecx, ecx
    jz .done
    dec ecx
    mov [notepad_len], ecx
    mov byte [dirty], 1
    ret
.done:
    ret

notepad_click:
    pushad
    mov ecx, [eax + WX]
    mov [window_x], ecx
    mov ecx, [eax + WY]
    mov [window_y], ecx
    mov ecx, [eax + WW]
    mov [window_w], ecx
    mov ecx, [eax + WH]
    mov [window_h], ecx
    mov edi, [mouse_x]
    sub edi, [window_x]
    mov edx, [mouse_y]
    sub edx, [window_y]
    cmp byte [np_saveas_mode], 1
    jne .not_dialog
    cmp edi, 40
    jl .dialog_cancel
    cmp edi, 220
    jg .dialog_cancel
    cmp edx, 60
    jl .dialog_cancel
    cmp edx, 104
    jg .dialog_cancel
    jmp .done
.dialog_cancel:
    mov byte [np_saveas_mode], 0
    mov byte [dirty], 1
    jmp .done
.not_dialog:
    cmp edi, 3
    jl .check_dropdown
    cmp edi, 35
    jg .check_dropdown
    cmp edx, 17
    jl .check_dropdown
    cmp edx, 28
    jg .check_dropdown
    xor byte [np_menu_open], 1
    mov byte [dirty], 1
    jmp .done
.check_dropdown:
    cmp byte [np_menu_open], 0
    je .done
    cmp edi, 3
    jl .close_menu
    cmp edi, 57
    jg .close_menu
    cmp edx, 28
    jl .close_menu
    cmp edx, 64
    jg .close_menu
    sub edx, 28
    cmp edx, 12
    jl .do_new
    cmp edx, 24
    jl .do_save
    jmp .do_saveas
.do_new:
    mov byte [np_menu_open], 0
    mov dword [notepad_len], 0
    mov byte [notepad_buf], 0
    mov byte [notepad_saved], 0
    mov byte [dirty], 1
    jmp .done
.do_save:
    mov byte [np_menu_open], 0
    call notepad_save
    jmp .done
.do_saveas:
    mov byte [np_menu_open], 0
    mov byte [np_saveas_mode], 1
    mov dword [np_saveas_len], 0
    mov byte [np_saveas_buf], 0
    mov esi, np_filename
    mov edi, np_saveas_buf
    mov ecx, 16
.copy_prefill:
    lodsb
    test al, al
    jz .prefill_done
    mov [edi], al
    inc edi
    inc dword [np_saveas_len]
    dec ecx
    jnz .copy_prefill
.prefill_done:
    mov byte [edi], 0
    mov byte [dirty], 1
    jmp .done
.close_menu:
    mov byte [np_menu_open], 0
    mov byte [dirty], 1
.done:
    popad
    ret

files_click:
    pushad
    cmp edx, 42
    jl .done
    sub edx, 42
    mov eax, edx
    xor edx, edx
    mov ecx, 16
    div ecx
    xor ebx, ebx
    xor ecx, ecx
.slot_loop:
    cmp ebx, MAX_FILES
    jae .done
    cmp byte [fs_used + ebx], 0
    je .slot_next
    cmp ecx, eax
    je .found
    inc ecx
.slot_next:
    inc ebx
    jmp .slot_loop
.found:
    mov esi, ebx
    imul esi, FS_NAME_LEN
    add esi, fs_names
    mov edi, np_filename
    mov ecx, FS_NAME_LEN
    rep movsb
    call notepad_init
    mov ebx, 4
    call open_window
.done:
    popad
    ret

scancode_to_ascii:
    push ebx
    movzx ebx, al
    cmp byte [shift_down], 0
    je .lower
    mov al, [scancode_shift_table + ebx]
    jmp .done
.lower:
    mov al, [scancode_table + ebx]
.done:
    pop ebx
    ret

cmd_hist_push:
    pushad
    cmp dword [input_len], 0
    je .done
    cmp dword [cmd_hist_count], 8
    jb .have_room
    mov esi, cmd_history + 32
    mov edi, cmd_history
    mov ecx, 7 * 32
    rep movsb
    mov dword [cmd_hist_count], 7
.have_room:
    mov eax, [cmd_hist_count]
    shl eax, 5
    add eax, cmd_history
    mov edi, eax
    mov esi, input_buf
    mov ecx, 31
.copy:
    lodsb
    test al, al
    jz .term
    mov [edi], al
    inc edi
    dec ecx
    jnz .copy
.term:
    mov byte [edi], 0
    inc dword [cmd_hist_count]
.done:
    popad
    ret

cmd_read_test:
    call terminal_newline
    mov esi, 0
    mov edi, ATA_TEST_BUF
    call ata_read_sector
    jc .fail
    mov esi, ATA_TEST_BUF + 504
    mov ecx, 8
.loop:
    push ecx
    push esi
    movzx eax, byte [esi]
    mov ebx, eax
    shr eax, 4
    and eax, 0x0F
    mov al, [hex_chars + eax]
    mov [hex_buf + 0], al
    mov eax, ebx
    and eax, 0x0F
    mov al, [hex_chars + eax]
    mov [hex_buf + 1], al
    mov byte [hex_buf + 2], ' '
    mov byte [hex_buf + 3], 0
    mov esi, hex_buf
    call terminal_append
    pop esi
    pop ecx
    inc esi
    dec ecx
    jnz .loop
    ret
.fail:
    mov esi, str_read_fail
    call terminal_append
    ret

cmd_write_test:
    call terminal_newline
    mov edi, ATA_TEST_BUF
    mov al, 0xAB
    mov ecx, 512
    rep stosb
    mov esi, ATA_TEST_LBA
    mov edi, ATA_TEST_BUF
    call ata_write_sector
    jc .wfail
    mov edi, ATA_TEST_BUF + 512
    xor al, al
    mov ecx, 512
    rep stosb
    mov esi, ATA_TEST_LBA
    mov edi, ATA_TEST_BUF + 512
    call ata_read_sector
    jc .rfail
    mov al, [ATA_TEST_BUF + 512]
    cmp al, 0xAB
    jne .bad
    mov esi, str_write_ok
    call terminal_append
    ret
.bad:
    mov esi, str_write_bad
    call terminal_append
    ret
.wfail:
    mov esi, str_write_fail
    call terminal_append
    ret
.rfail:
    mov esi, str_read_fail
    call terminal_append
    ret

execute_command:
    mov esi, input_buf
    mov edi, cmd_help
    call streq
    je .help
    mov esi, input_buf
    mov edi, cmd_ver
    call streq
    je .ver
    mov esi, input_buf
    mov edi, cmd_about
    call streq
    je .about
    mov esi, input_buf
    mov edi, cmd_gui
    call streq
    je .gui
    mov esi, input_buf
    mov edi, cmd_files
    call streq
    je .files
    mov esi, input_buf
    mov edi, cmd_browser
    call streq
    je .browser
    mov esi, input_buf
    mov edi, cmd_notepad
    call streq
    je .notepad
    mov esi, input_buf
    mov edi, cmd_ram
    call streq
    je .ram
	mov esi, input_buf
    mov edi, cmd_ramusg
    call streq
    je .ramusg
    mov esi, input_buf
    mov edi, cmd_apps
    call streq
    je .apps
    mov esi, input_buf
    mov edi, cmd_bsod
    call streq
    je .bsod
    mov esi, input_buf
    mov edi, cmd_serial
    call streq
    je .serial
    mov esi, input_buf
    mov edi, cmd_read
    call streq
    je .read_test
    mov esi, input_buf
    mov edi, cmd_write
    call streq
    je .write_test
    mov esi, input_buf
    mov edi, cmd_tcp
    call starts_with
    je .cmd_tcp
    mov esi, input_buf
    mov edi, cmd_dns
    call starts_with
    je .cmd_dns
    mov esi, input_buf
    mov edi, cmd_ping
    call starts_with
    je .cmd_ping
    mov esi, input_buf
    mov edi, cmd_user
    call starts_with
    je .cmd_user
    mov esi, input_buf
    mov edi, cmd_pass
    call starts_with
    je .cmd_pass
    mov esi, input_buf
    mov edi, cmd_cursor
    call starts_with
    je .cmd_cur
    mov esi, input_buf
    mov edi, cmd_run
    call streq
    je .run_default
    mov esi, input_buf
    mov edi, cmd_run_sp
    call starts_with
    je .run_index
    mov esi, input_buf
    mov edi, cmd_clear
    call streq
    je .clear
    mov esi, input_buf
    mov edi, cmd_shutdown
    call streq
    je .shutdown
    mov esi, input_buf
    mov edi, cmd_reboot
    call streq
    je .reboot
    mov esi, input_buf
    mov edi, cmd_echo
    call starts_with
    je .echo
    mov esi, input_buf
    mov edi, cmd_play
    call streq
    je .play
    mov esi, input_buf
    mov edi, cmd_ip
    call starts_with
    je .nl_ip
    mov esi, input_buf
    mov edi, cmd_browse
    call starts_with
    je .do_browse
    mov esi, input_buf
    mov edi, cmd_browse
    call starts_with
    je .do_browse
    mov esi, input_buf
    mov edi, cmd_nl_name
    call starts_with
    je .nl_name
    mov esi, input_buf
    mov edi, cmd_nl_lookup
    call starts_with
    je .nl_lookup
    mov esi, input_buf
    mov edi, cmd_nl_peer
    call starts_with
    je .nl_peer
    call terminal_newline
    mov esi, str_unknown
    call terminal_append
    ret
.help:
    mov esi, str_help
    call terminal_append
    ret
.ver:
    mov esi, str_ver
    call terminal_append
    ret
.about:
    mov esi, str_about
    call terminal_append
    ret
.gui:
    mov ebx, 0
    call open_window
    call terminal_newline
    mov esi, str_gui_open
    call terminal_append
    ret
.files:
    mov ebx, 1
    call open_window
    ret
.browser:
    mov ebx, 2
    call open_window
    ret
.notepad:
    mov ebx, 4
    call open_window
    ret
.apps:
    call cmd_list_apps
    ret
.bsod:
    mov esi, str_bsod_manual
    jmp bsod
.serial:
    mov esi, str_serial_msg
    call uart_puts
    call terminal_newline
    mov esi, str_serial_ok
    call terminal_append
    ret
.read_test:
    call cmd_read_test
    ret
.write_test:
    call cmd_write_test
    ret
.cmd_tcp:
    call cmd_tcp_run
    ret

.cmd_dns:
    call cmd_dns_run
    ret

.cmd_ping:
    call cmd_ping_run
    ret

.cmd_user:
    mov esi, input_buf + 5
    mov edi, prefs_blob + PREFS_USR
    mov ecx, 16
    xor eax, eax
    rep stosb
    mov esi, input_buf + 5
    mov edi, prefs_blob + PREFS_USR
    mov ecx, 15
    xor ebp, ebp
.cu_cp:
    lodsb
    test al, al
    jz .cu_done
    test al, ' '
    jz .cu_done
    mov [edi + ebp], al
    inc ebp
    dec ecx
    jnz .cu_cp
.cu_done:
    call save_prefs
    call terminal_newline
    mov esi, str_user_ok
    call terminal_append
    ret

.cmd_pass:
    mov esi, input_buf + 5
    mov edi, prefs_blob + PREFS_PWD
    mov ecx, 16
    xor eax, eax
    rep stosb
    mov esi, input_buf + 5
    mov edi, prefs_blob + PREFS_PWD
    mov ecx, 15
    xor ebp, ebp
.cp_cp:
    lodsb
    test al, al
    jz .cp_done
    mov [edi + ebp], al
    inc ebp
    dec ecx
    jnz .cp_cp
.cp_done:
    call save_prefs
    call terminal_newline
    mov esi, str_pass_ok
    call terminal_append
    ret

.cmd_wp:
    mov al, [input_buf + 10]
    sub al, '0'
    call set_wallpaper
    call terminal_newline
    mov esi, str_wp_ok
    call terminal_append
    ret

.cmd_cur:
    mov al, [input_buf + 7]
    cmp al, '1'
    jb .cmd_cur_1
    cmp al, '9'
    ja .cmd_cur_2
    sub al, '0'
    jmp .cmd_cur_go
.cmd_cur_2:
    mov al, [input_buf + 7]
    cmp al, '1'
    jne .cmd_cur_bad
    mov al, [input_buf + 8]
    sub al, '0'
    add al, 10
    jmp .cmd_cur_go
.cmd_cur_1:
    sub al, '0'
.cmd_cur_go:
    call set_cursor_color
    call terminal_newline
    mov esi, str_cur_ok
    call terminal_append
    ret
.cmd_cur_bad:
    ret

.run_default:
    mov dword [run_index], 0
    jmp .run_go
.run_index:
    mov al, [input_buf + 4]
    sub al, '0'
    cmp al, 9
    ja .run_none
    movzx eax, al
    mov [run_index], eax
.run_go:
    cmp dword [app_count], 0
    je .run_none
    mov eax, [run_index]
    cmp eax, [app_count]
    jae .run_none
    call run_app
    ret
.run_none:
    call terminal_newline
    mov esi, str_no_apps
    call terminal_append
    ret
.ram:
    call terminal_newline
    mov esi, str_ram_pre
    call terminal_append
    mov eax, [RAM_INFO_ADDR]
    mov edi, ram_str_buf
    call format_u32
    mov esi, ram_str_buf
    call terminal_append
    mov esi, str_ram_post
    call terminal_append
    ret
.ramusg:
    call cmd_ramusg_show
    ret
.clear:
    call terminal_clear
    ret
.reboot:
    call do_reboot
    jmp $
.shutdown:
    call do_shutdown
    jmp $
.echo:
    call terminal_newline
    mov esi, input_buf + 5
    call terminal_append
    ret
.play:
    call play_wav
    ret
.nl_ip:
    call nl_cmd_ip
    ret
.do_browse:
    call cmd_browse_run
    ret
.nl_name:
    call nl_cmd_name
    ret
.nl_lookup:
    call nl_cmd_lookup
    ret
.nl_peer:
    call nl_cmd_peer
    ret
cmd_ramusg_show:
    call terminal_newline

    mov esi, str_ramusg_total
    call terminal_append
    mov eax, [RAM_INFO_ADDR]
    mov edi, ram_str_buf
    call format_u32
    mov esi, ram_str_buf
    call terminal_append
    mov esi, str_kb
    call terminal_append

    call terminal_newline
    mov esi, str_ramusg_used
    call terminal_append
    mov eax, TEENY_USED_KB
    mov edi, ram_str_buf
    call format_u32
    mov esi, ram_str_buf
    call terminal_append
    mov esi, str_kb
    call terminal_append

    call terminal_newline
    mov esi, str_ramusg_free
    call terminal_append
    mov eax, [RAM_INFO_ADDR]
    sub eax, TEENY_USED_KB
    jns .ok
    xor eax, eax
.ok:
    mov edi, ram_str_buf
    call format_u32
    mov esi, ram_str_buf
    call terminal_append
    mov esi, str_kb
    call terminal_append
    ret

format_u32:
    push ebp
    mov ebx, 10
    xor ebp, ebp
.push:
    xor edx, edx
    div ebx
    push edx
    inc ebp
    test eax, eax
    jnz .push
.pop:
    pop eax
    add al, '0'
    mov [edi], al
    inc edi
    dec ebp
    jnz .pop
    mov byte [edi], 0
    pop ebp
    ret

terminal_clear:
    push eax
    push ecx
    push edi
    mov edi, terminal_buffer
    xor eax, eax
    mov ecx, TERM_ROWS * 32
    rep stosb
    mov dword [term_rows], 1
    mov dword [term_col], 0
    mov dword [term_view], 0
    pop edi
    pop ecx
    pop eax
    ret

terminal_newline:
    cmp byte [quiet], 0
    jne .quiet_ret
    cmp byte [quiet], 0
    jne .quiet_ret
    cmp dword [term_rows], TERM_ROWS
    jb .add
    push esi
    push edi
    push ecx
    mov esi, terminal_buffer + 32
    mov edi, terminal_buffer
    mov ecx, (TERM_ROWS - 1) * 32
    rep movsb
    pop ecx
    pop edi
    pop esi
    dec dword [term_rows]
.add:
    mov eax, [term_rows]
    imul eax, 32
    add eax, terminal_buffer
    mov edi, eax
    mov ecx, 32
    xor eax, eax
    rep stosb
    inc dword [term_rows]
    mov dword [term_col], 0
    ret
.quiet_ret:
    ret

terminal_append:

    pushad
    cmp byte [quiet], 0
    je .not_quiet
    popad
    ret
.not_quiet:
    cmp byte [quiet], 0
    je .nq
    popad
    ret
.nq:
    mov eax, [term_rows]
    dec eax
    imul eax, 32
    add eax, terminal_buffer
    add eax, [term_col]
    mov edi, eax
.copy:
    lodsb
    test al, al
    jz .done
    cmp al, 10
    je .newline
    cmp dword [term_col], 31
    jae .done
    mov [edi], al
    inc edi
    inc dword [term_col]
    jmp .copy
.newline:
    call terminal_newline
    mov eax, [term_rows]
    dec eax
    imul eax, 32
    add eax, terminal_buffer
    mov edi, eax
    jmp .copy
.done:
    popad
    ret

fs_init:
    pushad
    call fs_load
    jnc .done
    mov edi, fs_used
    xor eax, eax
    mov ecx, MAX_FILES
    rep stosb
    mov esi, str_fs_readme_name
    mov edi, str_fs_readme_data
    mov ecx, str_fs_readme_data_end - str_fs_readme_data
    call fs_write
    mov esi, str_fs_hello_name
    mov edi, str_fs_hello_data
    mov ecx, str_fs_hello_data_end - str_fs_hello_data
    call fs_write
.done:
    popad
    ret

fs_write:
    push ebx
    push esi
    push edi
    mov [fs_tmp_data], edi
    mov [fs_tmp_len], ecx
    xor ebx, ebx
.find:
    cmp ebx, MAX_FILES
    jae .fail
    cmp byte [fs_used + ebx], 0
    je .use_slot
    mov eax, ebx
    imul eax, FS_NAME_LEN
    add eax, fs_names
    mov edi, eax
    call streq
    test eax, eax
    jz .use_slot
    inc ebx
    jmp .find
.use_slot:
    mov byte [fs_used + ebx], 1
    mov eax, ebx
    imul eax, FS_NAME_LEN
    add eax, fs_names
    mov edi, eax
    push edi
    mov ecx, FS_NAME_LEN
    xor eax, eax
    rep stosb
    pop edi
    mov ecx, FS_NAME_LEN - 1
.copy_name:
    lodsb
    test al, al
    jz .name_done
    mov [edi], al
    inc edi
    dec ecx
    jnz .copy_name
.name_done:
    mov edi, ebx
    imul edi, FS_DATA_LEN
    add edi, fs_data
    mov esi, [fs_tmp_data]
    mov ecx, [fs_tmp_len]
    cmp ecx, FS_DATA_LEN
    jbe .len_ok
    mov ecx, FS_DATA_LEN
.len_ok:
    mov [fs_lens + ebx*4], ecx
    rep movsb
    mov eax, ebx
    jmp .done
.fail:
    mov eax, -1
    pop edi
    pop esi
    pop ebx
    ret
.done:
    call fs_save
    pop edi
    pop esi
    pop ebx
    ret

fs_save:
    pushad
    mov edi, FS_HEADER_BUF
    mov ecx, 512
    xor eax, eax
    rep stosb
    mov dword [FS_HEADER_BUF], FS_MAGIC
    mov esi, fs_used
    mov edi, FS_HEADER_BUF + 4
    mov ecx, 8
    rep movsb
    mov esi, fs_lens
    mov edi, FS_HEADER_BUF + 16
    mov ecx, 32
    rep movsb
    mov esi, fs_names
    mov edi, FS_HEADER_BUF + 48
    mov ecx, 128
    rep movsb
    mov esi, FS_HEADER_LBA
    mov edi, FS_HEADER_BUF
    call ata_write_sector
    jc .done
    xor ebx, ebx
.loop:
    cmp ebx, 8
    jae .done
    cmp byte [fs_used + ebx], 0
    je .next
    push ebx
    mov edi, FS_DATA_BUF
    mov ecx, 512
    xor eax, eax
    rep stosb
    pop ebx
    mov esi, ebx
    imul esi, FS_DATA_LEN
    add esi, fs_data
    mov edi, FS_DATA_BUF
    mov ecx, [fs_lens + ebx*4]
    cmp ecx, FS_DATA_LEN
    jbe .len_ok
    mov ecx, FS_DATA_LEN
.len_ok:
    rep movsb
    mov esi, FS_DATA_LBA
    add esi, ebx
    mov edi, FS_DATA_BUF
    call ata_write_sector
    jc .done
.next:
    inc ebx
    jmp .loop
.done:
    popad
    ret

fs_load:
    pushad
    mov esi, FS_HEADER_LBA
    mov edi, FS_HEADER_BUF
    call ata_read_sector
    jc .err
    mov eax, [FS_HEADER_BUF]
    cmp eax, FS_MAGIC
    jne .err
    mov esi, FS_HEADER_BUF + 4
    mov edi, fs_used
    mov ecx, 8
    rep movsb
    mov esi, FS_HEADER_BUF + 16
    mov edi, fs_lens
    mov ecx, 32
    rep movsb
    mov esi, FS_HEADER_BUF + 48
    mov edi, fs_names
    mov ecx, 128
    rep movsb
    xor ebx, ebx
.loop:
    cmp ebx, 8
    jae .done
    cmp byte [fs_used + ebx], 0
    je .next
    mov esi, FS_DATA_LBA
    add esi, ebx
    mov edi, FS_DATA_BUF
    call ata_read_sector
    jc .err
    mov esi, FS_DATA_BUF
    mov edi, ebx
    imul edi, FS_DATA_LEN
    add edi, fs_data
    mov ecx, FS_DATA_LEN
    rep movsb
.next:
    inc ebx
    jmp .loop
.done:
    popad
    clc
    ret
.err:
    popad
    stc
    ret

fs_read:
    push ebx
    push esi
    push edi
    xor ebx, ebx
.find:
    cmp ebx, MAX_FILES
    jae .fail
    cmp byte [fs_used + ebx], 0
    je .next
    mov eax, ebx
    imul eax, FS_NAME_LEN
    add eax, fs_names
    mov edi, eax
    mov esi, [esp + 4]
    call streq
    test eax, eax
    jz .found
.next:
    inc ebx
    jmp .find
.found:
    mov esi, ebx
    imul esi, FS_DATA_LEN
    add esi, fs_data
    mov edi, [esp + 0]
    mov eax, [fs_lens + ebx*4]
    mov ecx, eax
    test ecx, ecx
    jz .done
    rep movsb
    jmp .done
.fail:
    mov eax, -1
.done:
    pop edi
    pop esi
    pop ebx
    ret

notepad_init:
    pushad
    cmp byte [np_filename], 0
    jne .have_name
    mov esi, str_note_filename
    mov edi, np_filename
    mov ecx, 9
    rep movsb
.have_name:
    mov esi, np_filename
    mov edi, notepad_buf
    call fs_read
    test eax, eax
    js .empty
    mov [notepad_len], eax
    mov byte [notepad_saved], 1
    jmp .done
.empty:
    mov dword [notepad_len], 0
    mov byte [notepad_saved], 0
.done:
    popad
    ret

notepad_save:
    pushad
    mov esi, np_filename
    mov edi, notepad_buf
    mov ecx, [notepad_len]
    call fs_write
    mov byte [notepad_saved], 1
    mov byte [dirty], 1
    popad
    ret

scan_apps:
    pushad
    mov dword [app_count], 0
    mov esi, APP_STORAGE
.loop:
    mov eax, [app_count]
    cmp eax, MAX_APPS
    jae .done
    cmp dword [esi], 0x50504154
    jne .done
    mov al, [esi + 20]
    cmp al, 2
    jne .done
    mov edi, [app_count]
    shl edi, 2
    mov [app_tab + edi], esi
    movzx eax, byte [esi + 30]
    test eax, eax
    jz .done
    shl eax, 9
    add esi, eax
    inc dword [app_count]
    jmp .loop
.done:
    popad
    ret

cmd_list_apps:
    call terminal_newline
    cmp dword [app_count], 0
    jne .have
    mov esi, str_no_apps
    call terminal_append
    ret
.have:
    mov esi, str_apps_header
    call terminal_append
    xor ecx, ecx
.loop:
    cmp ecx, [app_count]
    jae .done
    push ecx
    mov eax, [app_tab + ecx*4]
    lea esi, [eax + 4]
    call terminal_append
    pop ecx
    inc ecx
    jmp .loop
.done:
    ret

streq:
    push esi
    push edi
.loop:
    mov al, [esi]
    cmp al, [edi]
    jne .no
    test al, al
    jz .yes
    inc esi
    inc edi
    jmp .loop
.yes:
    pop edi
    pop esi
    xor eax, eax
    ret
.no:
    pop edi
    pop esi
    mov eax, 1
    ret

starts_with:
    push esi
    push edi
.loop:
    mov al, [edi]
    test al, al
    jz .yes
    cmp al, [esi]
    jne .no
    inc esi
    inc edi
    jmp .loop
.yes:
    pop edi
    pop esi
    xor eax, eax
    ret
.no:
    pop edi
    pop esi
    mov eax, 1
    ret

; =============================================================================
; Data
; =============================================================================
start_open:        db 0
quiet:             db 1
dirty:             db 1
cursor_on:         db 1
blink_tick:        dd 0
shift_down:        db 0
mouse_enabled:     db 0
mouse_packet_pos:  db 0
mouse_buttons:     db 0
kb_scancode:       db 0
mouse_right:       db 0
ctx_open:          db 0
ctx_draw_x:        dd 0
ctx_draw_y:        dd 0
alt_down:          db 0
alt_tab_active:    db 0
alt_tab_index:     dd 0
alt_tab_count:     dd 0
alt_tab_list:      times MAX_WINDOWS db 0
win_focus_time:    times MAX_WINDOWS dd 0
cur_draw_win_idx:  dd 0
dth_x:             dd 0
dth_y:             dd 0
dth_w:             dd 0
dth_h:             dd 0
dth_prog:          dd 0
notepad_saved:     db 0
np_menu_open:      db 0
np_ctrl_down:      db 0
np_saveas_mode:    db 0
paint_drawing:     db 0

inst_stage:        db 0
inst_tick:         dd 0
cli_active:        db 0
cli_screen:        db 0
cli_disk:          db 0
cli_yn:            db 0
cli_sector:        dd 0
ata_drive:         db 0xE0
inst_src:          dd 0
poll_result:       db 0

bsod_reason:       dd 0
tb_x:              dd 0
tb_slot:           dd 0
tb_click_slot:     dd 0
hov_slot:          dd 0
snap_preview:      db 0
snap_prev_x:       dd 0
snap_prev_y:       dd 0
snap_prev_w:       dd 0
snap_prev_h:       dd 0

top_win:           dd 0
drag_mode:         dd 0
drag_win:          dd 0
drag_off_x:        dd 0
drag_off_y:        dd 0
drag_orig_x:       dd 0
drag_orig_y:       dd 0
drag_orig_w:       dd 0
drag_orig_h:       dd 0

clip_x1:  dd 0
clip_y1:  dd 0
clip_x2:  dd SCREEN_W
clip_y2:  dd SCREEN_H

window_x:    dd 0
window_y:    dd 0
window_w:    dd 0
window_h:    dd 0
window_mode: dd 0

kernel_saved_esp: dd 0
app_win_x: dd 0
app_win_y: dd 0
app_win_w: dd 320
app_win_h: dd 180

dai_src:   dd 0
dai_x:     dd 0
dai_y:     dd 0
dai_idx:   dd 0
dai_hdr:   dd 0
dai_cellx: dd 0

wl_sector:  dd 0
wallpaper_lba:    dd WALLPAPER_LBA
backup_sector:      dd BACKUP_TOTAL_SECTORS
backup_last_tick:   dd 0
backup_active:      db 0
backup_failed:      db 0
prefs_blob:       times 64 db 0
prefs_temp:       times 64 db 0
tone_freq:  dd 0
tone_div:   dw 0
tone_delay: dd 0

win_tab:
    dd 24, 24, 272, 142
    dd APP_TERMINAL, 0
    dd 272, 142
    dd 40, 40, 240, 120
    dd APP_FILES, 0
    dd 240, 120
    dd 60, 30, 240, 140
    dd APP_BROWSER, 0
    dd 240, 140
    dd 80, 50, 220, 130
    dd APP_ABOUT, 0
    dd 220, 130
    dd 50, 40, 260, 130
    dd APP_NOTEPAD, 0
    dd 260, 130
    dd 30, 30, 260, 150
    dd APP_INSTALLER, 0
    dd 260, 150
    dd 30, 30, 250, 160
    dd APP_PAINT, 0
    dd 250, 160
	dd 80, 20, 180, 160
    dd APP_CALC, 0
    dd 180, 160
    dd 60, 30, 200, 150
    dd APP_SNAKE, 0
    dd 200, 150
    dd 30, 20, 260, 168
    dd APP_SETTINGS, 0
    dd 260, 168
win_order:  db 0, 1, 2, 3, 4, 5, 6, 7, 8, 9

mouse_x:    dd 156
mouse_y:    dd 92
mouse_smooth_x:  dd 156
mouse_smooth_y:  dd 92
start_anim_w:    dd 0
sm_sub_anim:     dd 0
sm_sub_hover:    db 0
max_active:      dd 0
max_prev_x:      dd 0
max_prev_y:      dd 0
max_prev_w:      dd 0
max_prev_h:      dd 0
icon_x:          dd 30, 105, 180, 255, 30, 105, 180, 255
icon_y:          dd 24, 24, 24, 24, 74, 74, 74, 74
icon_drag_slot:  dd -1
icon_drag_off_x: dd 0
icon_drag_off_y: dd 0
icon_drag_orig_x: dd 0
icon_drag_orig_y: dd 0
mouse_packet: db 0,0,0

text_x:       dd 0
text_y:       dd 0
text_start_x: dd 0
text_color:   dd COLOR_WHITE
glyph_char:   db 0
TERM_ROWS equ 64
term_view:        dd 0
term_draw_start:  dd 0
str_blank_row:    times 32 db ' '
                  db 0
term_rows:    dd 1
term_col:     dd 0
input_len:    dd 0
input_buf:    times 32 db 0
terminal_buffer: times TERM_ROWS*32 db 0

cmd_history:     times 8*32 db 0
cmd_hist_count:  dd 0
cmd_hist_view:   dd -1

rtc_h:        db 0
rtc_m:        db 0
rtc_day:      db 0
rtc_dow:      db 0
clock_str:    db '00:00',0
date_str:     times 8 db 0
dow_names:    db 'SunMonTueWedThuFriSat'

ram_str_buf:  times 12 db 0

hex_buf:        times 4 db 0
hex_chars:      db '0123456789ABCDEF',0
str_read_fail:  db 'ATA read failed.',0
str_write_fail: db 'ATA write failed.',0
str_write_ok:   db 'WRITE OK',0
str_write_bad:  db 'WRITE BAD',0

notepad_len:     dd 0
notepad_buf:     times 256 db 0
np_filename:     times 16 db 0
np_saveas_buf:   times 16 db 0
np_saveas_len:   dd 0
paint_win_x:     dd 0
paint_win_y:     dd 0
paint_curr_color: dd 0
calc_display:     times 16 db 0
calc_display_len: dd 1
calc_acc:         dd 0
calc_op:          db 0
calc_new:         db 0
calc_error:       db 0
calc_digit:       db 0
snake_body:       times 100 db 0
snake_len:        dd 3
snake_dir:        db 0
snake_next_dir:   db 0
snake_food_x:     db 0
snake_food_y:     db 0
snake_score:      dd 0
snake_best:       dd 0
snake_tick:       dd 0
snake_speed:      dd 12
snake_paused:     db 0
snake_dead:       db 0
snake_started:    db 0
snake_rng:        dd 0x12345678
pit_ticks:        dd 0
pci_found_count:  dd 0
pci_vendor:       dd 0
pci_device:       dd 0
pci_bar0:         dd 0
e1000_base:       dd 0
e1000_mac:        times 6 db 0
str_e1000_mac:    db '  MAC: ',0
str_e1000_none:   db '  (e1000 not detected)',0
e1000_tx_cur:     dd 0
tx_desc_ptr:      dd 0
str_e1000_reset:  db '  e1000: reset OK',0
str_e1000_tx_ok:  db '  e1000: TX ring ready',0
str_e1000_tx_snt: db '  e1000: packet sent (DD=1)',0
str_e1000_tx_bad: db '  e1000: TX timeout',0
str_e1000_rx_ok:  db '  e1000: RX ring ready',0
str_sb16_ok:   db 'SB16 OK',0
str_playing:  db 'Playing tone...',0
sb16_buf:     times 512 db 0
sb16_addr:    dd 0
sb16_size:    dd 0
str_before: db 'BEFORE SB',0
str_after:  db 'AFTER SB',0
str_before_sb: db 'BEFORE SB',0
str_after_sb:  db 'AFTER SB',0
str_sb16_fail: db 'SB16 FAIL',0
str_rx_got:       db '  RX: packet, len=',0
str_rx_et:        db '  et=',0
rx_et:            dd 0
rx_cur:           dd 0
rx_head:          dd 0
rx_len:           dd 0
rx_desc_ptr:      dd 0
rx_ready:         dd 0
rx_poll_counter:  dd 0
str_arp_sent:     db '  ARP: request sent for 10.0.2.2',0
str_arp_reply:    db '  ARP REPLY from ',0
str_arp_ours:     db '  (reply is not ours)',0
arp_reply_mac:    times 6 db 0
arp_reply_ip:     times 4 db 0
ping_target_ip:   times 4 db 0
ping_id:          dw 0x1234
ping_seq:         dw 1
ping_counter:     dd 0
ping_received:    db 0
tx_quiet:         db 0
str_ping_head:    db '  PING ',0
str_ping_reply:   db '  Reply from ',0
str_ping_hi:      db '  Hi',0
str_ping_timeout: db '  Request timed out.',0
str_ping_badip:   db '  Bad IP address.',0
str_ping_nogw:    db '  No gateway MAC. Wait for ARP.',0
str_dot:          db '.',0
cmd_ping:         db 'ping ',0
cmd_dns:          db 'dns ',0
cmd_tcp:          db 'tcp ',0
str_tcp_usage:    db 'Usage: tcp <ip>',0
str_tcp_syn:      db '  SYN sent',0
str_tcp_synack:   db '  SYN-ACK received',0
str_tcp_ok:       db '  TCP connected',0
tcp_server_ip:    times 4 db 0
tcp_local_isn:    dd 0x12345678
tcp_remote_isn:   dd 0
tcp_state:        db 0
tcp_poll:         dd 0
tcp_my_seq:       dd 0
tcp_their_seq:    dd 0
tcp_data_buf:     times 8192 db 0
tcp_data_len:     dd 0
tcp_done:         db 0
http_req_buf:     times 256 db 0
browser_url:      times 64 db 0
browser_result:   db 0
browser_status:   times 64 db 0
str_browser_usage: db 'Usage: browse <host>',0
str_browser_get:  db 'GET / HTTP/1.0',13,10,'Host: ',0
str_browser_crlf: db 13,10,13,10,0
cmd_browse:       db 'browse ',0
str_browser_nodns: db 'DNS failed.',0
str_browser_noconn: db 'Connect failed.',0
str_browser_ok:   db 'Page loaded.',0
tcp_pay_ptr:      dd 0
tcp_pay_len:      dd 0
str_dns_usage:    db 'Usage: dns <hostname>',0
str_dns_head:     db '  DNS: ',0
str_dns_result:   db '  -> ',0
str_dns_fail:     db '  DNS lookup failed.',0
dns_hostname:     times 64 db 0
dns_qname_len:    dd 0
dns_query_len:    dd 0
dns_frame_len:    dd 0
dns_result_ip:    times 4 db 0
dns_got_reply:    db 0
dns_poll:         dd 0
pci_scan_buf:     times 64 db 0
str_pci_header:   db 'PCI devices:',0
str_pci_line:     db '  ',0
str_pci_vendor:   db 'v=',0
str_pci_dev:      db ' d=',0
str_pci_bar:      db ' bar0=',0
str_pci_e1000:    db '  ** Intel e1000 found **',0
str_pci_none:     db '  (none)',0
login_user_buf:    times 16 db 0
login_pass_buf:    times 16 db 0
login_user_len:    dd 0
login_pass_len:    dd 0
login_stage:       db 0
blink_last:       dd 0
snake_last_move:  dd 0
paint_tx:         dd 0
paint_ty:         dd 0
paint_tc:         dd 0
install_buf:     times 16 db 0

app_count:    dd 0
app_tab:      times MAX_APPS dd 0
run_index:    dd 0

fs_used:   times MAX_FILES db 0
fs_names:  times MAX_FILES * FS_NAME_LEN db 0
fs_lens:   times MAX_FILES dd 0
fs_data:   times MAX_FILES * FS_DATA_LEN db 0
fs_tmp_data: dd 0
fs_tmp_len:  dd 0

str_start: db 'START',0
str_tb_T: db 'T',0
tb_letter_buf: db 0,0
tb_mode:          dd 0
tb_pitch:         dd 44
tb_width:         dd 40
tb_vis_count:     dd 0
tb_lbl_len:       dd 0
tb_label_scratch: times 8 db 0
tb_labels:
    db 'Term',0
    db 'File',0
    db 'Brow',0
    db 'Abou',0
    db 'Note',0
    db 'Inst',0
    db 'Pain',0
    db 'Calc',0
    db 'Snak',0
    db 'Sett',0
tb_win_idx:  dd 0
tb_hover:    dd 0
str_icon_terminal: db 'Terminal',0
str_icon_files:    db 'Files',0
str_icon_browser:  db 'Browser',0
str_icon_about:    db 'About',0
str_icon_notepad:  db 'Notepad',0
str_icon_paint:    db 'Paint',0
str_icon_calc:     db 'Calc',0
str_icon_snake:    db 'Snake',0
str_title_snake:   db 'TeenyOS Snake',0
str_title_settings: db 'TeenyOS Settings',0
str_set_wp:         db 'Wallpaper:',0
str_set_cur:        db 'Cursor color:',0
str_set_login:      db 'Login at boot:',0
str_set_on:         db 'On',0
str_set_off:        db 'Off',0
str_set_1:          db '1',0
str_set_hint: db 'Use: user <name>  pass <word>',0
str_sp_dbg: db 'SAVE ',0
str_lp_dbg: db 'LOAD WP=',0
str_set_2:          db '2',0
str_set_3:          db '3',0
menu_settings:      db 'Settings',0
str_title_paint:   db 'TeenyOS Paint',0
str_title_calc:    db 'TeenyOS Calculator',0
str_x: db 'X',0
str_min: db '_',0

str_title_terminal: db 'TeenyOS Terminal',0
str_title_files:    db 'TeenyOS Files',0
str_title_browser:  db 'TeenyOS Browser',0
str_title_about:    db 'About TeenyOS',0
str_title_notepad:  db 'TeenyOS Notepad',0

str_welcome_1: db 'TeenyOS Alpha v1.8',0
str_welcome_2: db 'Type "help" for commands.',0
str_prompt:     db '>',0

str_files_header: db 'Name',0
str_files_empty:  db '(no files)',0

browser_title: db 'Coming Soon!',0
browser_line1: db 'The browser is under construction.',0
browser_line2: db 'Check back in a future release.',0

menu_terminal: db 'Terminal',0
menu_files:    db 'Files',0
menu_browser:  db 'Browser',0
menu_notepad:  db 'Notepad',0
menu_about:    db 'About',0
menu_shutdown: db 'Shutdown',0
menu_restart:  db 'Restart',0
menu_sleep:    db 'Sleep',0
ctx_new_note:  db 'New Note',0
ctx_new_paint: db 'New Paint',0
ctx_refresh:   db 'Refresh',0
ctx_about:     db 'About',0
cmd_shutdown:  db 'shutdown',0

str_help:
   str_help:
    db 'help clear ver about gui files browser notepad wallpaper cursor ram ramusg apps bsod serial read write run reboot shutdown echo name lookup peer ip',0
str_ver:
    db 'TeenyOS Alpha v1.8 | 256-color',0
str_about:
    db 'TeenyOS is a tiny experimental x86 OS foundation.',0
str_about_title: db 'TeenyOS Alpha v1.8',0
str_about_1: db 'A small 32-bit x86 operating system.',0
str_about_2: db '256-color palette + wallpaper.',0
str_about_3: db 'Persistent FS on ATA disk.',0
str_about_4: db 'Made By Daquavis',0
str_gui_open:
    db 'GUI active.',0
str_unknown:
    db 'Unknown command.',0

str_bsod_1: db 'TeenyOS',0
str_bsod_2: db 'A fatal error has occurred.',0
str_bsod_3: db 'The system has been halted to prevent damage.',0
str_bsod_4: db 'Reboot to continue.',0
str_bsod_manual: db 'Manually triggered by user.',0
str_bsod_app:    db 'External app could not be loaded.',0

str_ram_pre:  db 'RAM: ',0
str_ram_post: db ' KB total',0
str_ramusg_total: db 'RAM total: ',0
str_ramusg_used:  db 'TeenyOS used: ',0
str_ramusg_free:  db 'Free: ',0
str_kb:           db ' KB',0

str_apps_header: db 'Apps loaded:',0
str_no_apps:     db 'No apps found.',0

str_notepad_hint:      db 'Ctrl+S = save',0
str_note_filename:     db 'NOTE.TXT',0
str_np_file:           db 'File',0
str_np_new:            db 'New',0
str_np_save:           db 'Save',0
str_np_saveas:         db 'Save As...',0
str_np_saveas_prompt:  db 'Save as:',0

str_inst_logo:      db 'TeenyOS',0
str_inst_sub:       db 'Setup',0
str_inst_confirm:   db 'Are you sure you want to install TeenyOS?',0
str_inst_yes:       db 'Yes',0
str_inst_no:        db 'No',0
str_inst_wait:      db 'Please wait...',0
str_inst_do_not_power: db 'Do not power off.',0
str_inst_done:      db 'Finished!',0
str_inst_press_key: db 'Click to reboot.',0
str_inst_filename:  db 'INSTALL.DAT',0
str_reinstall_msg:  db 'Installer reset. Reboot to see it.',0
str_cli_title:    db 'TeenyOS Setup',0
str_cli_s1:       db 'Which disk do you want to install to?',0
str_cli_master:   db 'Primary Master  (hd0)',0
str_cli_slave:    db 'Primary Slave   (hd1)',0
str_cli_hint1:    db 'UP/DOWN to select   ENTER to confirm   ESC to boot without installing',0
str_cli_s2:       db 'Confirm Installation',0
str_cli_dst:      db 'Target disk:',0
str_cli_warn:     db 'WARNING: All data on this disk will be ERASED.',0
str_cli_yes:      db 'Yes',0
str_cli_no:       db 'No',0
str_cli_hint2:    db 'UP/DOWN to select   ENTER to confirm',0
str_cli_inst:     db 'Installing TeenyOS...',0
str_cli_prog:     db 'Do not power off the machine.',0
str_cli_done:     db 'Installation complete!',0
str_cli_reboot:   db 'Reboot now?',0
str_cli_err:      db 'ERROR: Disk read or write failed.',0
str_cli_anykey:   db 'Press any key to return to desktop.',0
str_cli_arrow:    db '>',0

cmd_install:      db 'install',0

str_serial_msg: db 13,10,'Hello from TeenyOS over UART!',13,10,0
str_serial_ok:  db 'Sent to COM1.',0
str_sleep_msg:  db 'Sleeping... press any key to wake.',0
str_prefs_filename: db 'PREFS.DAT',0
str_wp_ok:          db 'Wallpaper saved.',0
str_cur_ok:         db 'Cursor color saved.',0
cmd_wallpaper:      db 'wallpaper ',0
cmd_user:           db 'user ',0
cmd_pass:           db 'pass ',0
str_user_ok:        db 'Username saved.',0
str_pass_ok:        db 'Password saved.',0
str_login_title:   db 'TeenyOS',0
str_login_user:    db 'Username:',0
str_login_pass:    db 'Password:',0
str_login_enter:   db 'ENTER=log in   ESC=skip',0
str_login_wrong:   db 'Incorrect username or password.',0
cmd_cursor:         db 'cursor ',0
str_fs_readme_name: db 'README.TXT',0
str_fs_readme_data: db 'Welcome to TeenyOS Micro!'
str_fs_readme_data_end:
str_fs_hello_name: db 'HELLO.TXT',0
str_fs_hello_data: db 'Hello from the persistent filesystem.'
str_fs_hello_data_end:

cmd_help:    db 'help',0
cmd_clear:   db 'clear',0
cmd_ver:     db 'ver',0
cmd_about:   db 'about',0
cmd_gui:     db 'gui',0
cmd_files:   db 'files',0
cmd_browser: db 'browser',0
cmd_notepad: db 'notepad',0
cmd_ram:     db 'ram',0
cmd_ramusg:  db 'ramusg',0
cmd_apps:    db 'apps',0
cmd_bsod:    db 'bsod',0
cmd_serial:  db 'serial',0
cmd_read:    db 'read',0
cmd_write:   db 'write',0
cmd_reinstall: db 'reinstall',0
cmd_run:     db 'run',0
cmd_run_sp:  db 'run ',0
cmd_reboot:  db 'reboot',0
cmd_echo:    db 'echo ',0
cmd_play:    db 'play',0
str_play_bad: db 'Play failed.',0
; =============================================================================
; NAME LAYER — personal DNS, no ICANN
; =============================================================================
NL_NAME_MAX    equ 16
NL_NAME_LEN    equ 16
NL_ENTRY_SZ    equ 24          ; 16 name + 4 ip + 1 used + 3 pad
NL_PEER_MAX    equ 8
NL_MAGIC       equ 0x4E4D5151
NL_TYPE_Q      equ 1
NL_TYPE_A      equ 2
NL_TYPE_NF     equ 3

name_table:    times NL_NAME_MAX * NL_ENTRY_SZ db 0
peer_table:    times NL_PEER_MAX * 4 db 0
nl_scratch:    times NL_NAME_LEN db 0
nl_ipbuf:      times 4 db 0
nl_result:     dd 0
nl_slot:       dd 0
nl_ipi:        dd 0
nl_entry:      dd 0
nl_wire:       times 64 db 0
nl_src_ip:     times 4 db 0

str_nl_names:   db 'NAMES.DAT',0
str_nl_peers:   db 'PEERS.DAT',0
str_nl_hdr:     db 'Local names:',0
str_nl_arrow:   db ' -> ',0
str_nl_ok:      db 'Registered.',0
str_nl_del:     db 'Deleted.',0
str_nl_usage:   db 'Usage: name | name add <name> <ip> | name del <name>',0
str_nl_peerok:  db 'Peer added.',0
str_nl_peerusg: db 'Usage: peer | peer add <ip> | peer del <ip>',0
str_nl_nf:      db 'Not found.',0
rx_debug_shown:   dd 0
str_rx_head:      db 'RDH=',0
icon_palette:
    dd 0x000000, 0x0000AA, 0x00AA00, 0x00AAAA
    dd 0xAA0000, 0xAA00AA, 0xAA5500, 0xAAAAAA
    dd 0x555555, 0x5555FF, 0x55FF55, 0x55FFFF
    dd 0xFF5555, 0xFF55FF, 0xFFFF55, 0xFFFFFF
str_dbg_rctl:  db 'RCTL=',0
str_dbg_et:    db '  ET=',0
str_dbg_sp:    db '  SRC=',0
str_tcp_dot: db '.',0
str_syn_sent:  db 'SYN sent',0
str_syn_dump:  db 'SYN:',0
str_syn_space: db ' ',0
str_len_dbg: db 'LEN=',0
str_get_dbg: db 'GET DUMP:',0
str_get_seq:   db 'SEQ=',0
str_get_ack:   db 'ACK=',0
str_get_flags: db 'FLG=',0
str_get_csum:  db 'CKSUM=',0
str_get_sp:  db ' ',0
str_recv_dbg: db 'RECV START',0
str_r_fin: db '--RECV--',0
str_r_pkt: db 'SP=',0
str_r_p2:  db ' DP=',0
str_r_p3:  db ' F=',0
str_r_p4:  db ' L=',0
str_pkt_dbg:  db 'PKT',0
str_recv_l1:    db 'PKT ET=',0
str_recv_p:     db ' P=',0
str_recv_l2:    db 'SRC=',0
str_recv_ports: db ' PORTS=',0
str_recv_tl:    db ' LEN=',0
str_tcp_et:    db 'ET=',0
str_tcp_prot:  db ' P=',0
str_tcp_flags: db ' F=',0
str_dbg_prot:  db '  PROT=',0
str_dbg_srcip: db '  SRCIP=',0
str_dbg_icmp:  db '  ICMP=',0
str_dbg_dump:  db 'BUFFER0:',0
str_dbg_space: db ' ',0
str_dbg_ctrl:  db 'CTRL=',0
str_dbg_rdbal: db 'RDBAL=',0
str_dbg_rdlen: db 'RDLEN=',0
str_dbg_rdh:   db 'RDH=',0
str_dbg_rdt:   db 'RDT=',0
str_eq:        db ' 0x',0
str_dbg_poll: db 'P',0
str_dbg_pkt:  db 'K',0
local_ip:      db 10, 0, 2, 15
str_ip_ok:     db 'IP set.',0
str_ip_usage:  db 'Usage: ip <a.b.c.d>',0
cmd_ip:        db 'ip ',0
str_nl_peersh:  db 'Peers:',0
cmd_nl_name:    db 'name',0
cmd_nl_lookup:  db 'lookup ',0
cmd_nl_peer:    db 'peer',0

nl_load:
    pushad
    mov esi, str_nl_names
    mov edi, name_table
    call fs_read
    test eax, eax
    jns .p
    mov edi, name_table
    mov ecx, NL_NAME_MAX * NL_ENTRY_SZ
    xor eax, eax
    rep stosb
.p:
    mov esi, str_nl_peers
    mov edi, peer_table
    call fs_read
    test eax, eax
    jns .d
    mov edi, peer_table
    mov ecx, NL_PEER_MAX * 4
    xor eax, eax
    rep stosb
.d:
    popad
    ret

nl_save_names:
    pushad
    mov esi, str_nl_names
    mov edi, name_table
    mov ecx, NL_NAME_MAX * NL_ENTRY_SZ
    call fs_write
    popad
    ret

nl_save_peers:
    pushad
    mov esi, str_nl_peers
    mov edi, peer_table
    mov ecx, NL_PEER_MAX * 4
    call fs_write
    popad
    ret

; ESI = name. EAX = slot index or -1
nl_find:
    push ebx
    push ecx
    push edi
    xor ecx, ecx
.f:
    cmp ecx, NL_NAME_MAX
    jae .no
    mov eax, ecx
    imul eax, NL_ENTRY_SZ
    add eax, name_table
    cmp byte [eax + 20], 0
    je .n
    mov edi, eax
    call streq
    test eax, eax
    jz .y
.n:
    inc ecx
    jmp .f
.y:
    mov eax, ecx
    pop edi
    pop ecx
    pop ebx
    ret
.no:
    mov eax, -1
    pop edi
    pop ecx
    pop ebx
    ret
; ESI = name, EBX = ip ptr
nl_add:
    pushad
    call nl_find
    cmp eax, -1
    jne .have
    xor ecx, ecx
.free:
    cmp ecx, NL_NAME_MAX
    jae .fail
    mov eax, ecx
    imul eax, NL_ENTRY_SZ
    add eax, name_table
    cmp byte [eax + 20], 0
    je .have
    inc ecx
    jmp .free
.have:
    mov [nl_entry], eax
    mov edi, eax
    mov ecx, NL_ENTRY_SZ
    xor eax, eax
    rep stosb
    mov edi, [nl_entry]
    mov ecx, NL_NAME_LEN - 1
.cn:
    lodsb
    test al, al
    jz .cnd
    stosb
    dec ecx
    jnz .cn
.cnd:
    mov edi, [nl_entry]
    mov eax, [ebx]
    mov [edi + 16], eax
    mov byte [edi + 20], 1
    call nl_save_names
    popad
    ret
.fail:
    popad
    ret

; ESI = name
nl_del:
    pushad
    call nl_find
    cmp eax, -1
    je .f
    imul eax, NL_ENTRY_SZ
    add eax, name_table
    mov byte [eax + 20], 0
    call nl_save_names
.f:
    popad
    ret

; ESI = name. EAX = 1 found / 0 not. IP stored as 4 bytes in nl_result.
nl_local:
    pushad
    call nl_find
    cmp eax, -1
    je .no
    imul eax, NL_ENTRY_SZ
    add eax, name_table
    mov ecx, [eax + 16]
    mov [nl_result], ecx
    popad
    mov eax, 1
    ret
.no:
    popad
    xor eax, eax
    ret

; ESI=dst ip ptr, EAX=dst port, EBX=src port, EDI=payload, ECX=len
nl_udp_send:
    pushad
    mov [nl_u_dip], esi
    mov [nl_u_dp], eax
    mov [nl_u_sp], ebx
    mov [nl_u_pp], edi
    mov [nl_u_pl], ecx

    mov edi, E1000_TX_BUF_ADDR
    mov byte [edi + 0], 0xFF
    mov byte [edi + 1], 0xFF
    mov byte [edi + 2], 0xFF
    mov byte [edi + 3], 0xFF
    mov byte [edi + 4], 0xFF
    mov byte [edi + 5], 0xFF
    xor ecx, ecx
.sm:
    cmp ecx, 6
    jae .smd
    movzx eax, byte [e1000_mac + ecx]
    mov [edi + 6 + ecx], al
    inc ecx
    jmp .sm
.smd:
    mov byte [edi + 12], 0x08
    mov byte [edi + 13], 0x00
    mov byte [edi + 14], 0x45
    mov byte [edi + 15], 0x00
    mov eax, [nl_u_pl]
    add eax, 28
    xchg al, ah
    mov [edi + 16], ax
    mov byte [edi + 18], 0
    mov byte [edi + 19], 2
    mov byte [edi + 20], 0
    mov byte [edi + 21], 0
    mov byte [edi + 22], 0x40
    mov byte [edi + 23], 0x11
    mov byte [edi + 24], 0
    mov byte [edi + 25], 0
    mov al, [local_ip + 0]
    mov [edi + 26], al
    mov al, [local_ip + 1]
    mov [edi + 27], al
    mov al, [local_ip + 2]
    mov [edi + 28], al
    mov al, [local_ip + 3]
    mov [edi + 29], al
    mov esi, [nl_u_dip]
    mov al, [esi + 0]
    mov [edi + 30], al
    mov al, [esi + 1]
    mov [edi + 31], al
    mov al, [esi + 2]
    mov [edi + 32], al
    mov al, [esi + 3]
    mov [edi + 33], al
    push edi
    lea esi, [edi + 14]
    mov ecx, 20
    call ip_checksum
    pop edi
    mov [edi + 24], ah
    mov [edi + 25], al
    mov eax, [nl_u_sp]
    xchg al, ah
    mov [edi + 34], ax
    mov eax, [nl_u_dp]
    xchg al, ah
    mov [edi + 36], ax
    mov eax, [nl_u_pl]
    add eax, 8
    xchg al, ah
    mov [edi + 38], ax
    mov byte [edi + 40], 0
    mov byte [edi + 41], 0
    mov esi, [nl_u_pp]
    lea edi, [edi + 42]
    mov ecx, [nl_u_pl]
    rep movsb
    mov esi, E1000_TX_BUF_ADDR
    mov ebx, [nl_u_pl]
    add ebx, 42
    mov byte [tx_quiet], 1
    call e1000_send
    mov byte [tx_quiet], 0
    popad
    ret

nl_u_dip:  dd 0
nl_u_dp:   dd 0
nl_u_sp:   dd 0
nl_u_pp:   dd 0
nl_u_pl:   dd 0

; EAX = payload ptr, EBX = len. Source IP already in nl_src_ip.
nl_wire_handle:
    pushad
    cmp ebx, 6
    jb .done
    cmp dword [eax], NL_MAGIC
    jne .done
    movzx ecx, byte [eax + 4]
    cmp ecx, NL_TYPE_Q
    je .query
    cmp ecx, NL_TYPE_A
    je .answer
    jmp .done

.query:
    lea esi, [eax + 6]
    mov edi, nl_scratch
    mov ecx, NL_NAME_LEN
    rep movsb
    mov esi, nl_scratch
    call nl_local
    test eax, eax
    jz .nf
    mov edi, nl_wire
    mov dword [edi], NL_MAGIC
    mov byte [edi + 4], NL_TYPE_A
    mov byte [edi + 5], 0
    lea edi, [edi + 6]
    mov esi, nl_scratch
    mov ecx, NL_NAME_LEN
    rep movsb
    mov eax, [nl_result]
    mov [edi], eax
    mov esi, nl_src_ip
    mov eax, 5353
    mov ebx, 5353
    mov edi, nl_wire
    mov ecx, 26
    call nl_udp_send
    jmp .done
.nf:
    mov edi, nl_wire
    mov dword [edi], NL_MAGIC
    mov byte [edi + 4], NL_TYPE_NF
    mov byte [edi + 5], 0
    mov byte [edi + 6], 0
    mov esi, nl_src_ip
    mov eax, 5353
    mov ebx, 5353
    mov edi, nl_wire
    mov ecx, 8
    call nl_udp_send
    jmp .done

.answer:
    lea esi, [eax + 6]
    mov edi, nl_scratch
    mov ecx, NL_NAME_LEN
    rep movsb
    mov ecx, [eax + 22]
    mov [nl_result], ecx
.done:
    popad
    ret

; =============================================================================
; Commands
; =============================================================================
nl_cmd_name:
    pushad
    cmp byte [input_buf + 4], 0
    je .list
    cmp byte [input_buf + 4], ' '
    jne .usage
    cmp byte [input_buf + 5], 'a'
    je .add
    cmp byte [input_buf + 5], 'd'
    je .del
    jmp .usage
.add:
    lea esi, [input_buf + 9]
    mov edi, nl_scratch
    xor ecx, ecx
.cn:
    lodsb
    test al, al
    jz .usage
    cmp al, ' '
    je .cnd
    cmp ecx, NL_NAME_LEN - 1
    jae .usage
    mov [edi + ecx], al
    inc ecx
    jmp .cn
.cnd:
    mov byte [edi + ecx], 0
    mov edi, nl_ipbuf
    call parse_ip
    jc .usage
    mov esi, nl_scratch
    mov ebx, nl_ipbuf
    call nl_add
    call terminal_newline
    mov esi, str_nl_ok
    call terminal_append
    jmp .done
.del:
    lea esi, [input_buf + 9]
    mov edi, nl_scratch
    xor ecx, ecx
.cd:
    lodsb
    test al, al
    jz .cdd
    cmp al, ' '
    je .cdd
    cmp ecx, NL_NAME_LEN - 1
    jae .cdd
    mov [edi + ecx], al
    inc ecx
    jmp .cd
.cdd:
    mov byte [edi + ecx], 0
    mov esi, nl_scratch
    call nl_del
    call terminal_newline
    mov esi, str_nl_del
    call terminal_append
    jmp .done
.list:
    call terminal_newline
    mov esi, str_nl_hdr
    call terminal_append
    call terminal_newline
    mov dword [nl_slot], 0
.ll:
    mov ebp, [nl_slot]
    cmp ebp, NL_NAME_MAX
    jae .done
    mov eax, ebp
    imul eax, NL_ENTRY_SZ
    add eax, name_table
    mov [nl_entry], eax
    cmp byte [eax + 20], 0
    je .ln
    mov esi, eax
    call terminal_append
    mov esi, str_nl_arrow
    call terminal_append
    mov dword [nl_ipi], 0
.li:
    mov ebp, [nl_ipi]
    cmp ebp, 4
    jae .lid
    mov eax, [nl_entry]
    movzx eax, byte [eax + 16 + ebp]
    mov edi, ram_str_buf
    call format_u32
    mov esi, ram_str_buf
    call terminal_append
    cmp ebp, 3
    je .lidn
    mov esi, str_dot
    call terminal_append
.lidn:
    inc dword [nl_ipi]
    jmp .li
.lid:
    call terminal_newline
.ln:
    inc dword [nl_slot]
    jmp .ll
.done:
    popad
    ret
.usage:
    call terminal_newline
    mov esi, str_nl_usage
    call terminal_append
    popad
    ret

nl_cmd_peer:
    pushad
    cmp byte [input_buf + 4], 0
    je .list
    cmp byte [input_buf + 4], ' '
    jne .usage
    cmp byte [input_buf + 5], 'a'
    je .add
    cmp byte [input_buf + 5], 'd'
    je .del
    jmp .usage
.add:
    lea esi, [input_buf + 9]
    mov edi, nl_ipbuf
    call parse_ip
    jc .usage
    mov ecx, [nl_ipbuf]
    xor ebp, ebp
.fa:
    cmp ebp, NL_PEER_MAX
    jae .done
    mov eax, ebp
    shl eax, 2
    cmp dword [peer_table + eax], 0
    je .pa
    inc ebp
    jmp .fa
.pa:
    mov [peer_table + eax], ecx
    call nl_save_peers
    call terminal_newline
    mov esi, str_nl_peerok
    call terminal_append
    jmp .done
.del:
    lea esi, [input_buf + 9]
    mov edi, nl_ipbuf
    call parse_ip
    jc .usage
    mov ecx, [nl_ipbuf]
    xor ebp, ebp
.fd:
    cmp ebp, NL_PEER_MAX
    jae .done
    mov eax, ebp
    shl eax, 2
    cmp dword [peer_table + eax], ecx
    jne .nd
    mov dword [peer_table + eax], 0
    call nl_save_peers
    jmp .done
.nd:
    inc ebp
    jmp .fd
.list:
    call terminal_newline
    mov esi, str_nl_peersh
    call terminal_append
    call terminal_newline
    xor ebp, ebp
.pl:
    cmp ebp, NL_PEER_MAX
    jae .done
    mov eax, ebp
    shl eax, 2
    mov ecx, [peer_table + eax]
    test ecx, ecx
    jz .pn
    mov eax, ecx
    shr eax, 24
    mov edi, ram_str_buf
    call format_u32
    mov esi, ram_str_buf
    call terminal_append
    mov esi, str_dot
    call terminal_append
    mov eax, ecx
    shr eax, 16
    and eax, 0xFF
    mov edi, ram_str_buf
    call format_u32
    mov esi, ram_str_buf
    call terminal_append
    mov esi, str_dot
    call terminal_append
    mov eax, ecx
    shr eax, 8
    and eax, 0xFF
    mov edi, ram_str_buf
    call format_u32
    mov esi, ram_str_buf
    call terminal_append
    mov esi, str_dot
    call terminal_append
    mov eax, ecx
    and eax, 0xFF
    mov edi, ram_str_buf
    call format_u32
    mov esi, ram_str_buf
    call terminal_append
    call terminal_newline
.pn:
    inc ebp
    jmp .pl
.done:
    popad
    ret
.usage:
    call terminal_newline
    mov esi, str_nl_peerusg
    call terminal_append
    popad
    ret
nl_cmd_ip:
    pushad
    lea esi, [input_buf + 3]
    mov edi, local_ip
    call parse_ip
    jc .bad
    call terminal_newline
    mov esi, str_ip_ok
    call terminal_append
    popad
    ret
.bad:
    call terminal_newline
    mov esi, str_ip_usage
    call terminal_append
    popad
    ret
cmd_browse_run:
    pushad
    ; Copy hostname from input_buf+7 into browser_url
    lea esi, [input_buf + 7]
    mov edi, browser_url
    xor ecx, ecx
.cn:
    lodsb
    test al, al
    jz .cnd
    cmp al, ' '
    je .cnd
    cmp ecx, 62
    jae .cnd
    mov [edi + ecx], al
    inc ecx
    jmp .cn
.cnd:
    mov byte [edi + ecx], 0
    test ecx, ecx
    jz .usage

    mov byte [tcp_server_ip + 0], 17
    mov byte [tcp_server_ip + 1], 253
    mov byte [tcp_server_ip + 2], 15
    mov byte [tcp_server_ip + 3], 142

    ; Open browser window
    mov ebx, APP_BROWSER
    call open_window

    ; TCP connect
    call tcp_build_syn


    mov byte [tx_quiet], 1
    mov esi, E1000_TX_BUF_ADDR
    mov ebx, 54
    call e1000_send
    mov byte [tx_quiet], 0

    mov byte [tcp_state], 1
    mov dword [tcp_poll], 0
    call tcp_wait_synack
    cmp byte [tcp_state], 2
    jne .noconn

    call tcp_build_ack
    mov byte [tx_quiet], 1
    mov esi, E1000_TX_BUF_ADDR
    mov ebx, 54
    call e1000_send
    mov byte [tx_quiet], 0

    ; Build HTTP request: "GET / HTTP/1.0\r\nHost: <host>\r\n\r\n"
    mov edi, http_req_buf
    mov esi, str_browser_get
    mov ecx, 22
    rep movsb
    mov esi, browser_url
.copy_h:
    lodsb
    test al, al
    jz .copy_hd
    stosb
    jmp .copy_h
.copy_hd:
    mov esi, str_browser_crlf
    mov ecx, 4
    rep movsb
    ; Compute total length
    mov eax, edi
    sub eax, http_req_buf
    mov [tcp_pay_len], eax

    ; Send GET
    mov edi, http_req_buf
    mov ecx, [tcp_pay_len]
    call tcp_send_data
    mov esi, str_empty
    call terminal_append
    mov edx, E1000_TX_BUF_ADDR
    movzx eax, byte [edx + 38]
    call pci_print_hex_byte
    movzx eax, byte [edx + 39]
    call pci_print_hex_byte
    movzx eax, byte [edx + 40]
    call pci_print_hex_byte
    movzx eax, byte [edx + 41]
    call pci_print_hex_byte
    call terminal_newline

    mov esi, str_empty
    call terminal_append
    mov edx, E1000_TX_BUF_ADDR
    movzx eax, byte [edx + 42]
    call pci_print_hex_byte
    movzx eax, byte [edx + 43]
    call pci_print_hex_byte
    movzx eax, byte [edx + 44]
    call pci_print_hex_byte
    movzx eax, byte [edx + 45]
    call pci_print_hex_byte
    call terminal_newline

    mov esi, str_empty
    call terminal_append
    mov edx, E1000_TX_BUF_ADDR
    movzx eax, byte [edx + 46]
    call pci_print_hex_byte
    movzx eax, byte [edx + 47]
    call pci_print_hex_byte
    call terminal_newline

    mov esi, str_empty
    call terminal_append
    mov edx, E1000_TX_BUF_ADDR
    movzx eax, byte [edx + 50]
    call pci_print_hex_byte
    movzx eax, byte [edx + 51]
    call pci_print_hex_byte
    call terminal_newline
    ; Receive response
    call tcp_recv_data
    mov esi, str_empty
    call terminal_append
    mov eax, [tcp_data_len]
    call pci_print_hex32
    call terminal_newline
    ; Mark dirty so window redraws
    mov byte [dirty], 1
    call terminal_newline
    mov esi, str_browser_ok
    call terminal_append
    popad
    ret

.usage:
    call terminal_newline
    mov esi, str_browser_usage
    call terminal_append
    popad
    ret
.nodns:
    call terminal_newline
    mov esi, str_browser_nodns
    call terminal_append
    popad
    ret
.noconn:
    call terminal_newline
    mov esi, str_browser_noconn
    call terminal_append
    popad
    ret
nl_cmd_lookup:
    pushad
    lea esi, [input_buf + 7]
    mov edi, nl_scratch
    xor ecx, ecx
.cn:
    lodsb
    test al, al
    jz .cnd
    cmp al, ' '
    je .cnd
    cmp ecx, NL_NAME_LEN - 1
    jae .cnd
    mov [edi + ecx], al
    inc ecx
    jmp .cn
.cnd:
    mov byte [edi + ecx], 0
    mov esi, nl_scratch
    call nl_local
    test eax, eax
    jnz .print
    mov edi, nl_wire
    mov dword [edi], NL_MAGIC
    mov byte [edi + 4], NL_TYPE_Q
    mov byte [edi + 5], 0
    lea edi, [edi + 6]
    mov esi, nl_scratch
    mov ecx, NL_NAME_LEN
    rep movsb
    mov dword [nl_result], 0
    xor ebp, ebp
.snd:
    cmp ebp, NL_PEER_MAX
    jae .wait
    mov eax, ebp
    shl eax, 2
    cmp dword [peer_table + eax], 0
    je .sn
    mov esi, peer_table
    add esi, eax
    mov eax, 5353
    mov ebx, 5353
    mov edi, nl_wire
    mov ecx, 22
    call nl_udp_send
.sn:
    inc ebp
    jmp .snd
.wait:
    mov dword [ping_counter], 0
.wl:
    inc dword [ping_counter]
    cmp dword [ping_counter], 500000
    jae .nf
    cmp dword [nl_result], 0
    je .wl
.print:
    call terminal_newline
    mov esi, nl_scratch
    call terminal_append
    mov esi, str_nl_arrow
    call terminal_append
    xor ebp, ebp
.pp:
    cmp ebp, 4
    jae .ppd
    movzx eax, byte [nl_result + ebp]
    mov edi, ram_str_buf
    call format_u32
    mov esi, ram_str_buf
    call terminal_append
    cmp ebp, 3
    je .ppdn
    mov esi, str_dot
    call terminal_append
.ppdn:
    inc ebp
    jmp .pp
.ppd:
    call terminal_newline
    popad
    ret
.nf:
    call terminal_newline
    mov esi, str_nl_nf
    call terminal_append
    popad
    ret
scancode_table:
    times 2 db 0
    db '1','2','3','4','5','6','7','8','9','0','-','='
    db 8,9,'q','w','e','r','t','y','u','i','o','p','[',']',10,0
    db 'a','s','d','f','g','h','j','k','l',';',39,'`',0,92,'z','x'
    db 'c','v','b','n','m',',','.','/',0,'*',0,' '
    times 128-($-scancode_table) db 0

scancode_shift_table:
    times 2 db 0
    db '!','@','#','$','%','^','&','*','(',')','_','+'
    db 8,9,'Q','W','E','R','T','Y','U','I','O','P','{','}',10,0
    db 'A','S','D','F','G','H','J','K','L',':','"','~',0,'|','Z','X'
    db 'C','V','B','N','M','<','>','?',0,'*',0,' '
    times 128-($-scancode_shift_table) db 0
align 16
idt_table:
    times 256 * 8 db 0

idt_descriptor:
    dw 256 * 8 - 1
    dd idt_table

cursor_bitmap:
    db 2,0,0,0,0,0,0,0
    db 2,2,0,0,0,0,0,0
    db 2,1,2,0,0,0,0,0
    db 2,1,1,2,0,0,0,0
    db 2,1,1,1,2,0,0,0
    db 2,1,1,1,1,2,0,0
    db 2,1,1,1,1,1,2,0
    db 2,1,1,2,2,0,0,0
    db 2,1,2,0,2,0,0,0
    db 2,2,0,0,0,0,0,0

icon_terminal: incbin "icons/terminal.raw"
icon_files:    incbin "icons/files.raw"
icon_browser:  incbin "icons/browser.raw"
icon_about:    incbin "icons/about.raw"
icon_notepad:  incbin "icons/notepad.raw"
icon_calc:     incbin "icons/calc.raw"
icon_snake:    incbin "icons/snake.raw"
icon_paint:    incbin "icons/paint.raw"

%if ($-$$) > (257*512)
    %error "TeenyOS is larger than the 129-sector image"
%endif
str_empty: db 0
times (257*512)-($-$$) db 0

