# SPI Master–Slave Design and Verification

## About the Project

This project is part of my learning and development journey in RTL Design and SoC Design Verification.

I started by implementing the SPI Master and Slave in Verilog and then integrated them into a modular design. After completing the RTL, I developed a SystemVerilog testbench to verify communication between the Master and Slave using QuestaSim.

The main objective was to understand how SPI communication works at the RTL level and how to verify the different operating modes.

## What I Implemented

- SPI Master and Slave
- All four SPI modes (Mode 0, 1, 2 and 3)
- MSB-first and LSB-first data transmission
- Full-duplex communication
- Configurable SPI clock divider
- Parameterized data width
- Separate control and datapath modules
- Transmit and receive shift registers
- Bit counter and transaction control FSM

## RTL Design

The design is divided into smaller modules to keep the implementation organized.
_____________________________________________________________________
| Module                  | Purpose                                 |
|-------------------------|-----------------------------------------|
| `spi_top.v`             | Connects the SPI Master and Slave       |
| `spi_master.v`          | Integrates the Master components        |
| `spi_slave.v`           | Implements the SPI Slave                |
| `spi_master_ctrl.v`     | Controls the Master using an FSM        |
| `spi_master_datapath.v` | Connects the Master datapath components |
| `spi_clk_divider.v`     | Generates the SPI clock                 |
| `spi_shift_register.v`  | Handles transmit and receive data       |
| `spi_bit_counter.v`     | Tracks the number of transferred bits   |

## Verification

After completing the RTL, I created a SystemVerilog testbench to test the design.

The testbench uses four separate configurations for the four SPI modes. Each mode is tested with both MSB-first and LSB-first transmission.

The following checks are included:

- Master received the expected Slave data.
- Slave received the expected Master data.
- Slave receive-valid signal was generated.
- Each transaction completed successfully.

## Simulation Results

I ran the initial directed regression in QuestaSim 10.7c.
__________________________________________________
| SPI Mode | CPOL | CPHA | MSB-first | LSB-first |
|----------|------|------|-----------|-----------|
| Mode 0   | 0    | 0    | PASS      | PASS      |
| Mode 1   | 0    | 1    | PASS      | PASS      |
| Mode 2   | 1    | 0    | PASS      | PASS      |
| Mode 3   | 1    | 1    | PASS      | PASS      |

**Regression summary:**
- Total transactions: 8
- Passed: 8
- Failed: 0

These are the results of my initial directed tests. Additional corner-case testing and coverage work are still planned.

## Tools Used

- Verilog
- SystemVerilog
- QuestaSim 10.7c

## Project Structure

- `rtl/` – RTL design files
- `tb/` – SystemVerilog testbench files
- `docs/` – Project documentation
- `waveforms/` – Simulation waveform screenshots

## What's Next?

I plan to extend this project with:

- More directed and corner-case tests
- SystemVerilog Assertions (SVA)
- Functional coverage
- UVM-based verification
- Formal verification

This project is helping me build practical experience in RTL design, simulation, and SoC Design Verification.
