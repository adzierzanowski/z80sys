org 0xa000

hello:
  ld hl, msg
  ld c, 1
  ld a, [msg_size]
  ld b, a
  otir
  ret


msg: db "Hello, world!", 10, 0
msg_size: db 14
nop
