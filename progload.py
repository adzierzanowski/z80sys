import sys
import serial
import argparse
import time

ACK = 0x48
NACK = 0x7d
PROG_END_ACK = 0xa9

parser = argparse.ArgumentParser()
parser.add_argument('-p', '--port', required=True, type=str)
parser.add_argument('-n', '--nmi', action='store_true')
parser.add_argument('file', type=str)
args = parser.parse_args()

s = serial.Serial(port=args.port, baudrate=115200)

if args.nmi:
  s.write(b'\x66')
  s.close()
  sys.exit(0)

def fail(msg='NACK'):
  print(msg, file=sys.stderr)
  s.close()
  sys.exit(1)

try:
  with open(args.file, 'rb') as f:
    data = f.read()
    #print(data)
except FileNotFoundError:
  fail('File not found.')


def send(b):
  _b = b.to_bytes(1, 'little') if type(b) == int else b
  #print(f' {_b} -> ', end='', flush=True)
  s.write(_b)
  c = int.from_bytes(s.read(), byteorder='little')
  #print(f'{hex(c)}')

  if c not in (ACK, PROG_END_ACK):
    fail()

datalen = len(data)
print(f'Loading {args.file} ({datalen} bytes)')

send(b'\xed')
send(b'\x33')

for i, b in enumerate(data):
  print(f'\r{(i+1)/datalen*100:0.0f}%', end='', flush=True)
  send(b)

send(b'\xed')
send(b'\x8c')

time.sleep(1)

s.close()
