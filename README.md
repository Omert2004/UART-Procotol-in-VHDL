# UART Protocol in VHDL

This project implements a **Universal Asynchronous Receiver and Transmitter (UART)** communication protocol in **VHDL**. It was developed during a 20-day internship at **ASELSAN Elektronik Sanayi ve Ticaret A.Ş.**, under the **Avionics Digital Electronics Design Department (AGS)**.  
The goal of this project is to establish a reliable UART communication link between an **FPGA board** and a **PC**, enabling bidirectional data transmission, arithmetic processing, and checksum verification.

---

## 🔧 Project Overview

The system enables UART communication between an FPGA board and a PC.  
It receives a series of bytes from the PC — including **control bytes**, **operands**, and **opcode** — processes them in an **Arithmetic Logic Unit (ALU)** on the FPGA, and transmits the computed result back to the PC.

### Key Objectives
- Implement **synchronous transmitter (TX)** and **receiver (RX)** modules.
- Design modular VHDL entities for scalability and readability.
- Manage **clock synchronization**, **data framing**, and **error checking**.
- Verify communication using **ModelSim** simulation.
- Perform arithmetic operations through the **ALU** and send results back via UART.

## 🧩 System Architecture

The system is composed of modular VHDL entities:

| Module             | Description                                                                 |
|:------------------:|------------------------------------------------------------------------------|
| **TX_Block**       | Handles UART data transmission and converts 8-bit frames into serial data.  |
| **RX_Block**       | Receives serial data from the PC and reconstructs it into 8-bit frames.     |
| **RX_Controller**  | Validates message structure, verifies checksums, and prepares ALU operands. |
| **ALU_Block**      | Executes arithmetic and logic operations based on opcode values.             |
| **UART_Board_Top** | Top-level entity connecting all modules (RX, TX, ALU, Controller, PLL).     |
| **my_pll**         | Generates internal clock signals for FPGA synchronization.                   |

---

## 🧮 ALU Operations

The ALU supports the following operations based on the received **opcode**:

| Opcode | Operation        | Description                    |
|:------:|------------------|--------------------------------|
| `00`   | **Fzero**        | Reset output (`F = 0`)         |
| `01`   | **AplusB**       | Addition (`F = A + B`)         |
| `02`   | **AminusB**      | Subtraction (`F = A - B`)      |
| `03`   | **Adividedby2**  | Divide A by 2                  |
| `04`   | **Bdividedby2**  | Divide B by 2                  |
| `05`   | **BminusA**      | Subtraction (`F = B - A`)      |
| `06`   | **Amultiplyby2** | Multiply A by 2                |
| `07`   | **Bmultiplyby2** | Multiply B by 2                |
| `08`   | **OnlyA**        | Output A                       |
| `09`   | **OnlyB**        | Output B                       |

---

## 🧠 Implementation Details

- **Language:** VHDL (High-Speed Integrated Circuit Hardware Description Language)  
- **Simulation Tool:** ModelSim  
- **Clock Frequency:** 50 MHz  
- **Baudrate:** 115200 bps  
- **Stop Bit Configurations:** 1, 1.5, or 2 stop bits  
- **Parity Options:** Even, Odd, or None  
- **Data Width:** 8 bits  

The design was thoroughly tested in ModelSim using custom testbenches to verify UART timing, state transitions, and synchronization accuracy.

---

## 🧰 Tools and Technologies

| Tool                     | Purpose                                       |
|:-------------------------:|----------------------------------------------|
| **ModelSim**              | HDL simulation and waveform analysis         |
| **Notepad++ / Quartus**   | VHDL code editing and FPGA synthesis         |
| **FPGA Board**            | Target hardware for UART communication       |
| **PC (Serial Terminal)**  | Sends and receives UART data                |

---

## 📊 Simulation Results

The simulation verified:
- Correct transmission and reception of UART frames.
- Accurate state transitions for TX and RX.
- Proper checksum verification and ALU result handling.
- Reliable full-duplex operation under clock synchronization.

Example results include waveform snapshots showing TX-RX synchronization, ALU computation, and data validation sequences.

---

## 📁 Repository Structure

```
UART-Protocol-in-VHDL/
│
├── src/
│   ├── TX_Block.vhd
│   ├── RX_Block.vhd
│   ├── RX_Controller.vhd
│   ├── ALU_Block.vhd
│   ├── UART_Board_Top.vhd
│   └── my_pll.vhd
│
├── simulation/
│   ├── testbench_tx.vhd
│   ├── testbench_rx.vhd
│   └── uart_waveforms.do
│
├── docs/
│   ├── report_summary.pdf
│   └── block_diagrams/
│
└── README.md
```

---

## 🧑‍💻 Author

**Oğuz Mert Coşkun**  
Electrical & Electronics Engineer (Özyeğin University)  
🔗 [LinkedIn](https://www.linkedin.com/in/oguzmertcoskun) | [GitHub](https://github.com/Omert2004)  

---

## 📜 License

This project is provided for educational and non-commercial purposes only.  
All rights reserved © 2025 Oğuz Mert Coşkun.
