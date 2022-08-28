include "defs.s"

org 0x0000

ld sp, 0xffff
jp bootloader


ds 0x38 - $, 0
irq_handler:
  reti

ds 0x66 - $, 0
nmi_handler:
  retn

bootloader:
  call flush

  ld hl, bootmsg
  ld c, UART_PORT
  ld a, [bootmsg_len]
  ld b, a
  otir

  ld hl, bootmsg2
  ld c, UART_PORT
  ld a, [bootmsg2_len]
  ld b, a
  otir

_bootloader_loop:
  ld de, RAM_OFFSET
  call check_key
  cp 'f'
  jp z, _bootloader_call_ram

  call check_progbuf
  cp 0
  push af
  call nz, load_program
  pop af
  jp z, _bootloader_loop

_bootloader_call_ram:
  jp RAM_OFFSET
  halt

check_progbuf:
  in a, [PROGBUFSZ_LOW_PORT]
  cp 0
  jp z, _check_progbuf_high
  ret
_check_progbuf_high:
  in a, [PROGBUFSZ_HIGH_PORT]
  ret

; * load program from PROGBUF to [DE]
load_program:
  push de
  ld hl, loadmsg
  ld c, UART_PORT
  ld a, [loadmsg_len]
  ld b, a
  otir

  in a, [PROGBUFSZ_HIGH_PORT]
  ld h, a
  in a, [PROGBUFSZ_LOW_PORT]
  ld l, a

  push hl
  ld a, '0'
  out [UART_PORT], a
  ld a, 'x'
  out [UART_PORT], a
  call printhex16
  ld a, ' '
  out [UART_PORT], a
  ld a, 'B'
  out [UART_PORT], a
  ld a, 10
  out [UART_PORT], a
  pop hl

  ld bc, 1
  or a ; * clear carry flag
  pop de

_load_program_loop:
  in a, [PROGBUF_PORT]
  ld [de], a
  inc de
  sbc hl, bc
  jp nz, _load_program_loop

  ld hl, load_done_msg
  ld c, UART_PORT
  ld a, [load_done_msg_len]
  ld b, a
  otir

  ret

check_key:
  in a, [UART_BUFSZ_PORT]
  cp 0
  ret z
  in a, [UART_PORT]
  ret

bootmsg: db 27, "[2J", 27, "[0;0HBooting...", 10, 0
bootmsg_len: db $ - bootmsg
bootmsg2: db 27, "[7m F ", 27, "[0m -- force boot from 0x8000", 10, 0
bootmsg2_len: db $ - bootmsg2
loadmsg: db "Loading...", 10, 0
loadmsg_len: db $ - loadmsg
load_done_msg: db "Done.", 10, 0
load_done_msg_len: db $ - load_done_msg

include "stdlib.s"
