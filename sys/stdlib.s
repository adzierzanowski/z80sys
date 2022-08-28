org 0x0000

puts:
_puts:
  ld c, UART_PORT
_puts_loop:
  outi
  ld a, [hl]
  cp 0
  ret z
  jp _puts_loop
  ret

flush:
  xor a
  out [UART_BUFSZ_PORT], a
  ret

cls:
  ld hl, _cls_str
  call puts
  ret
_cls_str: db 27, "[2J", 27, "[0;0H", 0

_printhex_digit:
  cp 10
  jp nc, _printhex_digit_alpha
  add a, '0'
  out [UART_PORT], a
  jp _printhex_digit_ret

_printhex_digit_alpha:
  add a, '7'
  out [UART_PORT], a

_printhex_digit_ret:
  ret

; * prints a hex number stored in A
printhex8:
  push af
  srl a
  srl a
  srl a
  srl a
  call _printhex_digit
  pop af
  and 0x0f
  call _printhex_digit
  ret

; * prints a hex number stored in HL
printhex16:
  ld a, h
  call printhex8
  ld a, l
  call printhex8
  ret

parse_hex_digit:
  cp 'a'
  jp nc, _parse_hex_a
  cp 'A'
  jp nc, _parse_hex_A
_parse_hex_0:
  sub '0'
  jp _parse_hex_digit_ret
_parse_hex_a:
  sub 87
  jp _parse_hex_digit_ret
_parse_hex_A:
  sub 55
_parse_hex_digit_ret:
  ret

parse_hex:
  ld bc, 0
  ld [_parse_hex_buf_h], bc

  ld a, [de]
  call parse_hex_digit
  sla a
  sla a
  sla a
  sla a
  ld [_parse_hex_buf_h], a

  inc de
  ld a, [de]
  call parse_hex_digit
  ld b, a
  ld a, [_parse_hex_buf_h]
  or b
  ld [_parse_hex_buf_h], a

  inc de
  ld a, [de]
  call parse_hex_digit
  sla a
  sla a
  sla a
  sla a
  ld [_parse_hex_buf_l], a

  inc de
  ld a, [de]
  call parse_hex_digit
  ld b, a
  ld a, [_parse_hex_buf_l]
  or b
  ld [_parse_hex_buf_l], a

  ld hl, [_parse_hex_buf_h]

  ret

_parse_hex_buf_h: db 0
_parse_hex_buf_l: db 0
