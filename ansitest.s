org 0xa000

main:
  ld hl, ansimsg
  org 0x8000
  call print
  org 0xa000
  ret


ansimsg:
  db 27, "[3mhello",
     27, "[0m",
     27, "[4m world",
     27, "[0m",
     27, "[5m foobar",
     27, "[0m",
     27, "[38;5;1m foobaz",
     27, "[0m",
     27, "[48;5;1m quux",
     27, "[0m", 10, 0
