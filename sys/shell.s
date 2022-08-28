include "defs.s"

org 0x8000

main:
  org 0
  call cls
  org 0x8000
  ld hl, _welcome_msg
  org 0
  call puts
  org 0x8000

_main_loop:
  call _prompt
  call read

  ld hl, readbuf
  call cmdlookup
  org 0
  call flush
  org 0x8000

  jp _main_loop

_welcome_msg: db "snshell v. 0.3.0", 10, 0


_prompt:
  ld ix, 0
  add ix, sp
  push ix
  pop hl
  org 0
  call printhex16
  org 0x8000
  ld a, ' '
  out [UART_PORT], a
  ld hl, _prompt_prompt
  org 0
  call puts
  org 0x8000
  ret

_prompt_prompt: db "$ ", 0


read:
  in a, [UART_BUFSZ_PORT]
  cp 0
  jp z, read

  ld b, a
  ld c, UART_PORT
  ld hl, readbuf
  inir
  inc hl
  ld [hl], 0
  ret

readbuf:
  ds 0x40, 0


cmdlookup:
  ld iy, commands

_cmdlookup_cmp:
  ld a, [iy + 0]
  cp 0
  ret z

  push iy
  call cmdcmp
  cp 0
  pop iy
  jp nz, _cmdlookup_next
  ret

_cmdlookup_next:
  ld b, 0
  ld c, [iy + 0]
  add iy, bc
  inc iy
  inc iy
  inc iy
  jp _cmdlookup_cmp

cmdcmp:
  ld c, [iy + 0]
  ld ix, readbuf
  inc iy

_cmdcmp_loop:
  ld a, [ix + 0]
  cp [iy + 0]
  jp nz, _cmdcmp_loop_neq

  dec c
  jp z, _cmdcmp_loop_eq

  inc ix
  inc iy
  jp _cmdcmp_loop

_cmdcmp_loop_neq:
  ld a, c
  ret

_cmdcmp_loop_eq:
  xor a
  ld h, [iy + 2]
  ld l, [iy + 1]

  ld bc, _cmdcmp_ret
  push bc
  jp [hl]

_cmdcmp_ret:
  ret

_help_msg: db 27, "[7m Commands ", 27, "[0m", 10
           db "    ", 27, "[4mhelp", 27, "[0m -- show help", 10,
           db "    ", 27, "[4mcls", 27, "[0m  -- clear screen", 10
           db "    ", 27, "[4mexit", 27, "[0m -- quit shell", 10
           db 0
help:
  ld hl, _help_msg
  org 0
  call puts
  org 0x8000
  ret

scls:
  org 0
  call cls
  org 0x8000
  ret

exit:
  ld sp, 0xffff
  jp 0

scall:
  ld hl, readbuf
  ld bc, 5
  adc hl, bc
  push hl
  pop de
  org 0
  call parse_hex
  org 0x8000

  ld bc, _scall_ret
  push bc
  ld a, l
  ld l, h
  ld h, a
  jp [hl]
_scall_ret:
  ret

load:
  ld hl, readbuf
  ld bc, 5
  adc hl, bc
  push hl
  pop de

  org 0
  call parse_hex
  org 0x8000

  push hl

_check:
  org 0
  call check_progbuf
  cp 0
  org 0x8000
  jp z, _check
  pop hl
  ld d, l
  ld e, h
  org 0
  call nz, load_program
  org 0x8000

  ret

memdump:
  ld hl, readbuf
  ld bc, 5
  adc hl, bc

  push hl
  pop de

  org 0
  call parse_hex
  ld d, h
  ld h, l
  ld l, d
  push hl
  call printhex16
  org 0x8000

  ld a, ':'
  out [UART_PORT], a
  ld a, ' '
  out [UART_PORT], a

  pop hl
  ld c, 0x10
_memdump_loop:
  ld a, [hl]
  org 0
  call printhex8
  org 0x8000
  ld a, ' '
  out [UART_PORT], a

  inc hl
  dec c
  jp nz, _memdump_loop

  ld a, 10
  out [UART_PORT], a

  ret

;wptr:
;  ld hl, readbuf
;  ld bc, 5
;  adc hl, bc
;  push hl
;  pop de
;  org 0
;  call parse_hex
;  org 0x8000
;
;  ld d, l
;  ld e, h
;  ld [_wptr], de
;
;  ret
;
;_wptr: dw 0

commands:
          db 5, "help", 10
          dw help
          db 4, "cls", 10
          dw scls
          db 5, "exit", 10
          dw exit
          db 5, "call "
          dw scall
          db 5, "load "
          dw load
          db 5, "dump "
          dw memdump
          ;db 5, "wptr "
          ;dw wptr
          db 0
