# Test Run Report - 2026-03-11

## Environment
- Host: local macOS (Apple Silicon)
- Simulator: Icarus Verilog 13.0 (stable)

## Commands
1. `make tb_fifo`
2. `make tb_top`
3. `make tb_riscv_axi`

## Latest Results Summary
- `tb_fifo`: PASS
- `tb_top`: PASS
- `tb_riscv_axi`: PASS

## Detailed Results (Latest Run)

### tb_fifo
- Outcome: PASS
- Last line: `tb/tb_dual_bank_fifo.v:54: $finish called at 165000 (1ps)`

### tb_top
- Outcome: PASS
- Last line: `tb/tb_bibieq_dma_banked_top.v:90: $finish called at 335000 (1ps)`

### tb_riscv_axi
- Outcome: PASS
- Coverage summary (selected):
  - parity/use_4ec/ds bins covered
  - phase bins 0..7 hit at least once
  - r bins 0..4 hit at least once (r[5..7] remain zero as expected)
  - burst bins hit: `other`
- Last line: `TEST PASSED (FAST_MODE=0)`

## Changes Applied To Fix AXI-Lite Handshake
- `rtl/axi_lite_regs.v`
  - Ready logic updated to allow a 1-entry buffered write while a response is pending.
- `tb/tb_bibieq_dma_banked_riscv_axi.v`
  - AXI-Lite tasks drive on `negedge` and sample on `posedge` to avoid race conditions.
  - Write sequence changed to AW first, then W to avoid address/data mismatches.
  - Internal debug task (`dump_dut_state`) added for failure triage.

## Prior Failure (Before Fixes)
- `tb_riscv_axi` previously failed with AXI-Lite handshake timeouts and DONE timeout.
- Root cause: TB/DUT race on AW/W handshakes leading to stuck holds and mismatched writes.
