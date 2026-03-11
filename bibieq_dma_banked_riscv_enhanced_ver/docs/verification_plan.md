# Verification Plan

## Goals

- Functional correctness of CSR programming and DMA data flow
- CDC correctness for async FIFOs and synchronized control signals
- Basic bus-protocol sanity for AXI-Lite/APB/AHB register access
- Throughput sanity (no deadlocks under backpressure)

## Coverage Targets (Functional)

Minimum targets for a single test run (AXI testbench):

- Even/odd parity both exercised
- `use_4ec` = 0 and 1 exercised
- `ds` = 0 and 1 exercised
- `phase` bins 0-7 hit at least once
- `r` bins 0-4 hit at least once
- Read burst length bins: 1,2,4,8 (or "other")
- Backpressure cycles observed on read and write channels

## Testbenches

- `tb/tb_dual_bank_fifo.v` - basic FIFO sanity
- `tb/tb_bibieq_dma_banked_riscv_axi.v` - AXI-Lite + AXI DMA + coverage counters
- `tb/tb_bibieq_dma_banked_riscv_axi.v` can optionally load descriptors from a Stim-derived `.hex` file (see `stim/README.md`)

## CDC Checklist

- All async control inputs are 2-FF synchronized
- All multi-bit CDC paths use async FIFO or equivalent safe protocol
- Reset deassertion is synchronized per domain
