# ⚡ UART Protocol in VHDL

[![Platform](https://img.shields.io/badge/platform-FPGA-green.svg)](/Omert2004/UART-Procotol-in-VHDL/blob/main)
[![Language](https://img.shields.io/badge/language-VHDL-orange.svg)](/Omert2004/UART-Procotol-in-VHDL/blob/main)
[![Tools](https://img.shields.io/badge/tools-ModelSim%2FQuartus-blue.svg)](/Omert2004/UART-Procotol-in-VHDL/blob/main)
[![License](https://img.shields.io/badge/license-Educational-lightgray.svg)](/Omert2004/UART-Procotol-in-VHDL/blob/main)

---

## 📘 Project Overview

**UART Protocol in VHDL** implements a **Universal Asynchronous Receiver and Transmitter (UART)** communication protocol entirely in **VHDL**.

Developed during a **20-day internship at ASELSAN Elektronik Sanayi ve Ticaret A.Ş.** in the **Avionics Digital Electronics Design Department (AGS)**, this project establishes a reliable, bidirectional data link between an **FPGA board** and a **PC**.

The system is designed to receive commands (control bytes, operands, opcode), process them in an **Arithmetic Logic Unit (ALU)** on the FPGA, and transmit the computed result back to the host PC, featuring built-in **checksum verification** for data integrity.

---

## ⚙️ Key Features

* ✅ **Modular VHDL Design** — Separated entities for TX, RX, Controller, and ALU for scalability.
* ✅ **Full-Duplex Communication** — Supports simultaneous transmit and receive operations.
* ✅ **Synchronous Implementation** — TX and RX modules are fully synchronous to the core clock.
* ✅ **Data Integrity** — Implements **Checksum Verification** within the `RX_Controller`.
* ✅ **Arithmetic Processing** — Onboard **ALU** performs 10 different operations based on the incoming opcode.
* ✅ **Configurable Settings** — Supports variable **Stop Bit** configurations and **Parity** options (Even/Odd/None).

---

## 🧠 System Architecture

### 🧩 Data Flow
      ┌────────────────────────┐
      │   PC (Serial Terminal) │
      └──────────┬─────────────┘
                 │  UART Protocol (TX/RX)
                 ▼
      ┌────────────────────────┐
      │      FPGA Board        │
      │                        │
      │ ┌────────────────────┐ │
      │ │     RX_Block       │ │  → Receives serial data
      │ └────────────────────┘ │
      │            │
      │            ▼
      │ ┌────────────────────┐ │
      │ │   RX_Controller    │ │  → Checks Checksum, Extracts A, B, Opcode
      │ └────────────────────┘ │
      │            │
      │   ┌────────┴────────┐
      │   │    ALU_Block    │ (Arithmetic Operations)
      │   └────────┬────────┘
      │            ▼
      │ ┌────────────────────┐
      │ │     TX_Block       │ │  → Sends processed result back
      │ └────────────────────┘
      │
      └────────────────────────┘

### ⚙️ Task Breakdown

| Module | Function |
| :--- | :--- |
| **my\_pll** | Generates required internal clock signals for system synchronization. |
| **RX\_Block** | Handles serial-to-parallel conversion and data framing (8-bit). |
| **RX\_Controller** | Validates message structure, verifies checksum, and prepares ALU operands. |
| **ALU\_Block** | Executes arithmetic and logic operations based on the received opcode. |
| **TX\_Block** | Handles parallel-to-serial conversion for data transmission. |
| **UART\_Board\_Top** | Top-level entity connecting and orchestrating all functional blocks. |

---

## 🧩 Hardware and Clock Specifications

The design is intended for synthesis onto a target FPGA platform.

| Signal | Type | Description |
| :--- | :--- | :--- |
| `CLK_in` | Input | System clock signal (e.g., 50 MHz). |
| `RST` | Input | Asynchronous or synchronous reset signal. |
| `RXD` | Input | UART Receive Data line. |
| `TXD` | Output | UART Transmit Data line. |

### Key Implementation Details

* **Language:** VHDL (IEEE 1076)
* **Clock Frequency:** **50 MHz**
* **Baudrate:** **115200 bps**
* **Data Width:** 8 bits
* **Stop Bit Options:** 1, 1.5, or 2 Stop Bits
* **Parity Options:** Even, Odd, or None

---

## 💾 Communication Protocol & ALU Operations

The system is configured to process a data packet containing a control byte, two operands (A and B), and an opcode for the ALU.

### ALU Operations

The `ALU_Block` supports the following operations based on the received **opcode**:

| Opcode (Binary) | Opcode (Decimal) | Operation | Description |
| :--- | :--- | :--- | :--- |
| `0000` | **0** | **Fzero** | Reset output (`F = 0`) |
| `0001` | **1** | **AplusB** | Addition (`F = A + B`) |
| `0010` | **2** | **AminusB** | Subtraction (`F = A - B`) |
| `0011` | **3** | **Adividedby2** | Divide A by 2 |
| `0100` | **4** | **Bdividedby2** | Divide B by 2 |
| `0101` | **5** | **BminusA** | Subtraction (`F = B - A`) |
| `0110` | **6** | **Amultiplyby2** | Multiply A by 2 |
| `0111` | **7** | **Bmultiplyby2** | Multiply B by 2 |
| `1000` | **8** | **OnlyA** | Output A (`F = A`) |
| `1001` | **9** | **OnlyB** | Output B (`F = B`) |

---

## 🧰 Development Environment

| Component | Tool / Environment | Purpose |
| :--- | :--- | :--- |
| **Language** | VHDL | Hardware description |
| **Simulation** | **ModelSim** | Behavioral and timing simulation, waveform analysis |
| **Synthesis** | **Quartus Prime** (or similar) | VHDL code editing and FPGA synthesis |
| **Hardware** | FPGA Development Board | Target platform for hardware implementation |
| **Interface** | PC (Serial Terminal) | Sends and receives data via UART |

---

## 🧪 Verification

The design was rigorously tested in **ModelSim** using custom VHDL testbenches to ensure reliable operation.

* Confirmed correct timing and state transitions for both the **TX** and **RX** modules.
* Verified accurate reconstruction of 8-bit frames upon reception.
* Validated the **checksum verification** mechanism within the `RX_Controller`.
* Ensured the **ALU** executed all 10 operations correctly based on the input opcode.
* Confirmed reliable full-duplex operation under high-speed synchronization.

---

## 🚀 Future Improvements

* 🗜️ Implement **Asynchronous FIFO buffers** between the clock domains (PLL output) to enhance robustness against jitter.
* 📈 Integrate the system with a physical FPGA board and perform **on-chip debugging** (e.g., using SignalTap).
* 🛡️ Introduce **hardware flow control** (RTS/CTS) for more robust communication under high load.

---

## 🧑‍💻 Author

## **Oğuz Mert Coşkun**
📧 [oguzmertcoskun@gmail.com](mailto:oguzmertcoskun@gmail.com)
🎓 Electrical & Electronics Engineering — Özyeğin University
🔗 [LinkedIn](https://www.linkedin.com/in/oguzmertcoskun) | [GitHub](https://github.com/Omert2004)

---

## 📄 License

This repository is provided for **educational and non-commercial purposes only.**

All rights reserved &copy; 2025 Oğuz Mert Coşkun.

---

## 📂 Repository Structure

UART-Protocol-in-VHDL/ │ ├── src/ # ✅ Core VHDL source files │ ├── TX_Block.vhd │ ├── RX_Block.vhd │ ├── RX_Controller.vhd │ ├── ALU_Block.vhd │ ├── UART_Board_Top.vhd │ └── my_pll.vhd │ ├── simulation/ # Testbench and ModelSim configuration files │ ├── testbench_tx.vhd │ ├── testbench_rx.vhd │ └── uart_waveforms.do │ └── README.md


### 🧩 Keywords

`VHDL` `UART` `FPGA` `ALU` `Protocol` `ASIC` `DigitalLogic` `HardwareDesign` `ModelSim` `ASIC`
