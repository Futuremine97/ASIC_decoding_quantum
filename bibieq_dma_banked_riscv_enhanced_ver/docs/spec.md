# Specification

## System Memory Map (32-bit SoC example)

| Address Range | Device | Description |
|---|---|---|
| 0x0000_0000 - 0x0000_FFFF | Boot ROM | Boot code / early init (64KB) |
| 0x1000_0000 - 0x1000_FFFF | Main SRAM | Instruction/data SRAM (64KB) |
| 0x2000_0000 - 0x2000_0FFF | BIBIEQ CSR | Accelerator control/status |
| 0x3000_0000 - 0x3000_0FFF | DMA CSR | DMA controller registers |
| 0x4000_0000 - 0x4FFF_FFFF | Banked SRAM | Syndrome / error buffers (256MB) |
| 0xFE00_0000 - 0xFE00_00FF | UART | Debug serial |

## CSR Register Map (BIBIEQ)

All control buses (AXI-Lite / APB3 / AHB-Lite) share the same map.

| Offset | Name | Access | Description |
|---|---|---|---|
| 0x00 | CTRL | W1P | START/CLR_DONE/SOFT_RESET |
| 0x04 | STATUS | RO | BUSY/DONE/FETCH_DONE/STORE_DONE |
| 0x08 | DESC_BASE | RW | Descriptor base address |
| 0x0C | DESC_COUNT | RW | Descriptor count (64-bit entries) |
| 0x10 | RD_BURST | RW | Read burst length in beats |
| 0x14 | RESULT_BASE | RW | Result base address |
| 0x18 | EVEN_LEVEL | RO | Even FIFO fill level |
| 0x1C | ODD_LEVEL | RO | Odd FIFO fill level |

**CTRL bits**

- bit0: START (write 1 to launch)
- bit1: CLR_DONE (clear DONE sticky)
- bit2: SOFT_RESET (pulse)

**STATUS bits**

- bit0: BUSY
- bit1: DONE_STICKY
- bit2: FETCH_DONE (pulse)
- bit3: STORE_DONE (pulse)

## Clocking / Reset / CDC

- `reset_sync.v` performs async assert, sync deassert.
- `sync_2ff.v` is used for single-bit async inputs (e.g., start if needed).
- For clock-domain crossing data paths, use `async_fifo.v` or `dual_bank_async_fifo.v`.

## Bus Interfaces (summary)

- **AXI-Lite**: 32-bit CSR access
- **APB3**: 32-bit CSR access
- **AHB-Lite**: 32-bit CSR access, base `0x2000_0000`
- **AXI4 DMA**: 64-bit read/write data path
