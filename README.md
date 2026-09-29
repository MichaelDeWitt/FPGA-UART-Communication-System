# FPGA UART Communication System

A UART-based command and response system implemented in Verilog on the
**Digilent Basys 3 FPGA development board**. The project demonstrates
RTL design, finite-state machines (FSMs), serial communication, command
parsing, hardware control, and simulation-based verification using
Icarus Verilog.

The FPGA receives commands from a computer over UART, updates the state
of an onboard LED, and transmits a text response back to the computer.

> **Project status:** The RTL and end-to-end response simulation have
> passed the project's current testbenches. Physical-board validation of
> the command/response version should be recorded after testing it on
> the Basys 3.

## Features

-   UART serial communication using **115200 baud, 8 data bits, no
    parity, 1 stop bit (8N1)**.
-   UART receiver and transmitter implemented in Verilog.
-   Command parser for controlling and querying LED0.
-   Text responses sent from the FPGA to a PC serial terminal.
-   Transmitter handshake signals (`tx_busy` and `tx_done`) to
    coordinate transmission.
-   Parameter-specific baud timing based on the Basys 3's 100 MHz clock.
-   Testbenches for UART loopback, receive-side validation, transmitter
    handshake, command handling, and end-to-end response bytes.

## Hardware and tools

### Hardware

-   **FPGA board:** Digilent Basys 3
-   **FPGA device:** Artix-7 (Basys 3)
-   **System clock:** 100 MHz
-   **UART interface:** USB-to-UART serial connection exposed by the
    board
-   **PC serial port:** COM port assigned by the host operating system
    (COM3 was used during development)

### Development tools

-   AMD/Xilinx Vivado for synthesis, implementation, bitstream
    generation, and FPGA programming
-   Icarus Verilog (`iverilog` and `vvp`) for simulation
-   GTKWave for inspecting VCD simulation waveforms
-   Git and GitHub for version control

## System overview

``` text
                 Computer / Serial Terminal
                           |
                     UART 8N1, 115200
                           |
                           v
                  +------------------+
                  |    uart_rx       |
                  | UART receiver    |
                  +------------------+
                           |
                   rx_data / rx_done
                           |
                           v
                  +------------------+
                  | Command parser   |
                  | and response     |
                  | controller       |
                  +------------------+
                     |            |
                 LED0 state   response buffer
                     |            |
                     v            v
                  Basys 3     +------------------+
                  LED0        |     uart_tx      |
                              | UART transmitter |
                              +------------------+
                                       |
                                       v
                              Computer / Terminal
```

The receiver converts incoming serial data into an 8-bit byte and pulses
`rx_done` when a valid frame is received. The command controller
interprets that byte, updates LED0 when appropriate, selects a response
message, and coordinates transmission of the response one character at a
time.

## UART configuration and timing

The design uses a 100 MHz clock and a target baud rate of 115200 baud.

  Parameter                                           Value
  ------------------------ --------------------------------
  Clock frequency                                   100 MHz
  Clock period                                        10 ns
  UART baud rate                                115200 baud
  Bits per frame             10 (1 start + 8 data + 1 stop)
  Data format                                           8N1
  Clock cycles per bit                                  868
  Approximate bit period                            8.68 µs

The ideal number of clock cycles per bit is:

\[ `\frac{100{,}000{,}000}{115{,}200}`{=tex} `\approx 868.0556`{=tex} \]

The implementation uses 868 clock cycles per bit, corresponding to an
actual baud rate of approximately 115207.4 baud. This small difference
is approximately 0.0064% from the target baud rate.

The receiver checks the start bit around its midpoint before sampling
the data bits. UART data is transmitted least-significant bit first. The
stop bit is expected to be logic high.

## Supported commands

Send one ASCII character at a time from a serial terminal.

  -----------------------------------------------------------------------
  Input                   Action                  Response
  ----------------------- ----------------------- -----------------------
  `1`                     Turn LED0 on            `LED0=ON`

  `0`                     Turn LED0 off           `LED0=OFF`

  `?`                     Report the current LED0 `LED0=ON` or `LED0=OFF`
                          state                   

  Any other character     Do not change LED0;     `ERR`
                          report an invalid       
                          command                 
  -----------------------------------------------------------------------

Responses use **CRLF** line endings (`\r\n`) so successive messages
begin on a new terminal line.

**Current limitation:** The controller processes commands while it is in
its idle state. It does not queue incoming commands while transmitting a
response. For reliable manual testing, send a command and wait for its
response before sending the next one.

## RTL architecture

### `baud_counter.v`

Generates `baud_tick` at the UART bit interval. With a 100 MHz clock,
the counter counts 868 clock cycles per tick. In the current top-level
design, the counter is reset using `tx_start` so that the timing
interval is restarted when a new byte is accepted for transmission.

### `uart_rx.v`

Receives asynchronous UART serial data and assembles it into an 8-bit
byte. Its FSM uses the following states:

-   `IDLE`: Wait for the line to go low.
-   `START`: Wait approximately half a bit period and validate the start
    bit.
-   `DATA`: Sample the eight data bits, least-significant bit first.
-   `STOP`: Check that the stop bit is high, then update `rx_data` and
    pulse `rx_done`.

Frames with an invalid low stop bit are rejected by the current receiver
logic.

### `uart_tx.v`

Transmits a byte as a UART frame: a low start bit, eight data bits
(least-significant bit first), and a high stop bit. The transmitter uses
`baud_tick` to advance between bits.

The module provides: - `tx_busy`: Indicates that a transmission is in
progress. - `tx_done`: Pulses when the stop-bit interval has completed.

The controller uses these handshake signals to avoid starting a new byte
before the previous byte has finished.

### `uart_top.v`

Integrates the receiver, transmitter, baud counter, command parser,
response buffer, and LED output. It maps the received commands to LED0
behavior and response messages.

The response buffer stores up to 10 characters. `char_index` selects
each character in order, and the controller advances through the
response after each `tx_done` pulse.

## Pin constraints

The top-level module is `uart_top`. The XDC file should constrain the
ports to the Basys 3 pins below.

  Signal      Basys 3 pin   Purpose
  ----------- ------------- -----------------------------
  `clk`       `W5`          100 MHz board clock
  `uart_rx`   `B18`         Serial data from PC to FPGA
  `uart_tx`   `A18`         Serial data from FPGA to PC
  `led[0]`    `U16`         Command-controlled LED
  `led[1]`    `E19`         Received data bit 1
  `led[2]`    `U19`         Received data bit 2
  `led[3]`    `V19`         Received data bit 3
  `led[4]`    `W18`         Received data bit 4
  `led[5]`    `U15`         Received data bit 5
  `led[6]`    `U14`         Received data bit 6
  `led[7]`    `V14`         Received data bit 7

The clock constraint should specify a 10 ns period for the 100 MHz
clock. Use the project's XDC file as the source of truth and confirm
that all port names and constraints match the current RTL before
implementation.

## Repository contents

The repository contains the RTL modules and simulation testbenches. The
principal source and testbench files are:

  -----------------------------------------------------------------------
  File                                Purpose
  ----------------------------------- -----------------------------------
  `uart_top.v`                        Top-level integration, command
                                      parser, LED control, response
                                      controller

  `uart_rx.v`                         UART receiver

  `uart_tx.v`                         UART transmitter with busy/done
                                      handshake

  `baud_counter.v`                    UART baud timing generator

  `uart_system_tb.v`                  TX-to-RX loopback tests across
                                      several byte values

  `uart_rx_verify_tb.v`               RX tests for a valid frame and an
                                      invalid stop bit

  `uart_tx_handshake_tb.v`            Tests transmitter busy/done
                                      handshake behavior

  `uart_command_tb.v`                 Tests command parsing and LED state
                                      changes

  `uart_response_tb.v`                End-to-end tests of response bytes
                                      transmitted by the top-level system
  -----------------------------------------------------------------------

Vivado-generated directories and simulation output files do not need to
be committed unless there is a specific reason to include them. Keep the
source files, XDC constraints, testbenches, and project documentation
easy to find.

## Running simulations

Run the following commands from the directory containing the Verilog
source files.

### 1. UART loopback test

This test connects the transmitter output to the receiver input in
simulation and checks several byte patterns.

``` bash
iverilog -g2012 -Wall -s uart_system_tb \
  -o uart_system_sim uart_tx.v uart_rx.v uart_system_tb.v
vvp uart_system_sim
```

### 2. Receiver verification

Checks a valid received byte and verifies that a frame with a low stop
bit is rejected.

``` bash
iverilog -g2012 -Wall -s uart_rx_verify_tb \
  -o uart_rx_verify_sim uart_rx.v uart_rx_verify_tb.v
vvp uart_rx_verify_sim
```

### 3. Transmitter handshake test

Checks the transmitter's `tx_busy` and `tx_done` behavior.

``` bash
iverilog -g2012 -Wall -s uart_tx_handshake_tb \
  -o uart_tx_handshake_sim uart_tx.v uart_tx_handshake_tb.v
vvp uart_tx_handshake_sim
```

### 4. Command parser test

Checks command handling and the LED0 state changes.

``` bash
iverilog -g2012 -Wall -s uart_command_tb \
  -o uart_command_sim baud_counter.v uart_rx.v uart_tx.v \
  uart_top.v uart_command_tb.v
vvp uart_command_sim
```

### 5. End-to-end response test

Sends commands to the top-level design and checks the bytes returned by
the FPGA's simulated UART transmitter.

``` bash
iverilog -g2012 -Wall -s uart_response_tb \
  -o uart_response_sim baud_counter.v uart_rx.v uart_tx.v \
  uart_top.v uart_response_tb.v
vvp uart_response_sim
```

A successful run should report zero failures and
`ALL RESPONSE TESTS PASSED`. If RTL or a testbench is changed, recompile
the relevant simulation before running it; executing an existing
simulation binary does not automatically incorporate source changes.

The response testbench writes a VCD file (`uart_response.vcd`) for
waveform inspection.

## Viewing waveforms

If GTKWave is installed, open the response test waveform with:

``` bash
gtkwave uart_response.vcd
```

Useful signals to inspect include:

-   `uart_rx` and `uart_tx`
-   `rx_data` and `rx_done`
-   `tx_data`, `tx_start`, `tx_busy`, and `tx_done`
-   The controller `state`
-   `response_buf`, `response_len`, and `char_index`
-   `led[0]`

Waveforms are useful for checking UART bit timing, start and stop bits,
response sequencing, and the relationship between the controller and
transmitter handshake.

## Building and programming with Vivado

1.  Open the Vivado project.
2.  Confirm that `uart_top` is selected as the top module.
3.  Confirm the XDC file is enabled and its constraints match the
    current top-level ports.
4.  Run **Synthesis** and review any warnings or errors.
5.  Run **Implementation** and review timing results.
6.  Generate the bitstream.
7.  Open **Hardware Manager**, connect to the Basys 3, and program the
    FPGA with the generated `.bit` file.

A successful simulation does not replace hardware testing. After
programming, test the actual board and record the observed results in
this README.

## Testing with PuTTY

1.  Connect the Basys 3 to the computer using USB.
2.  Identify the serial port assigned to the board in the operating
    system.
3.  Open PuTTY in **Serial** mode.
4.  Configure:
    -   Serial line: the board's COM port (COM3 was used during
        development)
    -   Speed: `115200`
    -   Data bits: `8`
    -   Stop bits: `1`
    -   Parity: `None`
    -   Flow control: `None`
5.  Disable local echo if you want to see only the FPGA's responses.
6.  Send `1`, `0`, `?`, and an invalid character one at a time, waiting
    for each response.

Expected results:

-   `1`: LED0 turns on and the terminal displays `LED0=ON`.
-   `0`: LED0 turns off and the terminal displays `LED0=OFF`.
-   `?`: The terminal reports the current LED0 state.
-   Invalid character: The terminal displays `ERR`.

The terminal may display the response without visible escape characters;
CRLF moves the cursor to the start of the next line.

## Verification summary

The current simulation suite covers:

-   UART TX-to-RX loopback across multiple data patterns, including
    `00`, `FF`, `55`, and `AA`.
-   Receiver acceptance of a valid frame and rejection of an invalid
    stop bit.
-   Transmitter handshake behavior.
-   Command parsing and LED0 state changes.
-   End-to-end response-byte checks for the `1` and `0` commands.

The end-to-end response test currently checks the ON and OFF response
strings. Additional response-byte tests for `?` and invalid commands
would improve coverage.

## Possible future improvements

-   Add response-byte tests for `?` and invalid commands.
-   Add a hardware reset input or a clearly documented initialization
    strategy.
-   Buffer or queue commands received while the FPGA is transmitting a
    response.
-   Add UART oversampling and evaluate robustness to timing error and
    noise.
-   Add more malformed-frame and back-to-back traffic tests.
-   Parameterize the clock frequency and baud rate.
-   Capture hardware test results and add simulation waveform
    screenshots.
-   Improve the README with a system block diagram and a photo of the
    Basys 3 setup.

## Skills demonstrated

-   Verilog RTL design
-   Finite-state machine design
-   UART serial communication (8N1)
-   Digital timing and clock-cycle calculations
-   Module integration and synchronous control
-   Command parsing and response sequencing
-   Testbench development and simulation-based verification
-   Icarus Verilog, GTKWave, Vivado, Git, and GitHub
-   FPGA synthesis, implementation, and hardware debugging workflow

## License

No license is specified yet. If you want others to reuse or modify this
project, choose and add an appropriate open-source license file.

