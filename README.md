# z80sys

This is a basic Z80 system which for now can be assembled using:

* Zilog Z80 CPU
* 62256-type DRAM (32 kiB)
* Couple of NOT and OR gates
* Arduino Mega 2560
* USB-UART device

The software used is:

* Python3 for loading script
* [zasm](https://github.com/adzierzanowski/zasm) assembler
* AVR compiler (e.g. [arduino-cli](https://github.com/arduino/arduino-cli))


## Future

As for now the system is slow because of the Arduino emulating first 32k of RAM
and other devices like UART and random number generator.

In the future this project will utilze either some SIO, PIO chips or some FPGA
programmed to handle these things.

[You can check how it looks now in this video](https://streamable.com/1nlvp2)

## Building Hardware

### Pin connections between Z80 CPU and the RAM chip

| Z80       | 62256      |
|-----------|------------|
| `D0..D7`  | `IO1..IO8` |
| `A0..A14` | `A0..A14`  |
| `WR`      | `WE`       |
| `RD`      | `OE`       |

The thing with `CE` pin is a little less straightforward. We need addresses
from `0x0000` to `0x7fff` to be handled by the Arduino Mega and the `0x8000`
to `0xffff` handled by the RAM chip. This will depend on the Z80's `A15` pin
which is the highest bit of the address bus.

When `A15` is low and `MREQ` pin is low, we have to set a certain pin of the
Arduino low. When `A15` is high and `MREQ` is low, we have to set `CS` pin of
the RAM chip low.

We'll acheive this connecting the pins like this:

```
            +----+
 A15 ----+--+    |
         |  | OR +--------------- CS (Arduino)
MREQ -+-----+    |
      |  |  +----+
      |  |
      |  |  +-----+    +----+
      |  +--+ NOT +----+    |
      |     +-----+    | OR +---- CS (RAM)
      +----------------+    |
                       +----+

```

### Pin connections between the Z80 and Arduino

| Z80       | Arduino Mega             |
|-----------|--------------------------|
| `D0..D7`  | `D23`, `D25`, ..., `D37` |
| `A0..A14` | `D22`, `D24`, ..., `D50` |
| `IRQ`     | `D4`                     |
| `NMI`     | `D5`                     |
| `HALT`    | `D6`                     |
| `IORQ`    | `D7`                     |
| `WAIT`    | `D8`                     |
| `WR`      | `D9`                     |
| `RD`      | `D10`                    |
| `MREQ`    | `D11`                    |
| `RST`     | `A0`                     |
| `CLK`     | `A7`                     |

`RST` and `CLK` are currently generated externally. You have to hook up a
signal generator of your own. `CLK` should at most be around `2-5 kHz` because
this is the speed Arduino can handle.

## Building the software

### Step 1: bootloader

Compile the Arduino sketch and upload it to the board.

The bootloader is already assembled inside the sketch. If you need to change
it, compile it:

```
$ zasm sys/boot.s -v 2 -o sys/boot -e sys/boot.lbl
```

This will assemble the bootloader and generate an lbl file with labels' addresses.

Then you'll need to update the `ram` array in the sketch with the binary values
of the assembled program (`boot` file).

### Step 2: Shell

The shell is assembled similarly but it needs to know the addresses from the
bootloader:

```
$ zasm sys/shell.s -o sys/shell -v 2 -l sys/boot.lbl
```

### Step 3: Loading the shell

The system utilizes two UARTs for communication. First is the Arduino's built-in
USB-UART (`Serial`), the second one (`Serial1`) has to be connected through an
external USB-UART device. `Serial` is used to display shell and to fetch user's
input. `Serial1` is used to load programs to the RAM (sort of like loading
programs from a cassette tape).

1. Power on the Arduino, set Z80's `CLK` to 2 kHz and `RST` to low state
2. Open some terminal emulator and connect with the Arduino
   *  e.g. use Python `serial` module's built-in terminal emulator:
      ```
      $ python3 -m serial - 115200 -e --raw --eol
      ```
3. Set the `RST` signal to the high state
4. You should now see a message like `Booting...`. This means that the bootloader
   waits for a program to appear in the IO controller's (which is the Arduino)
   program buffer.
5. Use `progload.py` script to load the shell into the RAM (using the `Serial1`
   interface).
   *  ```
      $ python3 progload.py sys/shell --port /path/to/serial1/uart
      ```
6. Wait a moment and then the shell should appear

### Step 4: Loading other programs

To load other programs, type the following thing into the shell:

```
FFFD $ load a000
```

This will wait for a program and load it at `0xa000` address. The hex value
in the prompt is the current stack pointer value.

To execute loaded program, type:

```
FFFD $ call a000
```
