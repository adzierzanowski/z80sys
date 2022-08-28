include "defs.s"

org 0xa000

main:
  ; * Get a random number and store it in the memory
  in a, [RNG_PORT]
  ld [number], a

  call cls
  ld hl, typenum_msg
  ld c, UART_PORT
  ld a, [typenum_msg_sz]
  ld b, a
  otir

  out [UART_BUFSZ_PORT], a


_wait_for_input:
  ld a, 0
  out [UART_BUFSZ_PORT], a

_wait_for_input_loop:
  in a, [UART_BUFSZ_PORT]
  cp 0
  jp z, _wait_for_input_loop

  ld b, a
  ld c, UART_PORT
  ld hl, guessed_buf
  inir

  call parsenum
  ld hl, number
  sub [hl]

  ld c, UART_PORT
  jp z, _good_number
  jp nc, _too_high

  call cls
  ld hl, too_low_msg
  ld a, [too_low_msg_sz]
  ld b, a
  otir
  out [UART_BUFSZ_PORT], a
  jp _wait_for_input

_too_high:
  call cls
  ld hl, too_high_msg
  ld a, [too_high_msg_sz]
  ld b, a
  otir
  out [UART_BUFSZ_PORT], a
  jp _wait_for_input

_good_number:
  call cls
  ld hl, correct_msg
  ld a, [correct_msg_sz]
  ld b, a
  otir
  ret

parsenum:
  ld hl, guessed_buf
  ld a, [hl]
  sub '0'

  ld c, a
  ld b, 99
_mul100_loop:
  add a, c
  dec b
  jp nz, _mul100_loop

  ld d, a
  inc hl
  ld a, [hl]
  sub '0'

  ld c, a
  ld b, 9
_mul10_loop:
  add a, c
  dec b
  jp nz, _mul10_loop

  add a, d
  ld d, a
  inc hl
  ld a, [hl]
  sub '0'
  add a, d

  ret

cls:
  ld a, 27
  out [UART_PORT], a
  ld a, '['
  out [UART_PORT], a
  ld a, '2'
  out [UART_PORT], a
  ld a, 'J'
  out [UART_PORT], a
  ld a, 27
  out [UART_PORT], a
  ld a, '['
  out [UART_PORT], a
  ld a, '0'
  out [UART_PORT], a
  ld a, 59
  out [UART_PORT], a
  ld a, '0'
  out [UART_PORT], a
  ld a, 'H'
  out [UART_PORT], a

  xor a
  out [UART_BUFSZ_PORT], a
  ret


typenum_msg: db "Write a number from 000 to 255: ", 0
typenum_msg_sz: db 33
correct_msg: db "This is the correct number!", 10, 0
correct_msg_sz: db 29
too_low_msg: db "Your number is too low. Try again: ", 0
too_low_msg_sz: db 36
too_high_msg: db "Your number is too high. Try again: ", 0
too_high_msg_sz: db 37
guessed_buf:
  ds 10, 0
number: db 0
