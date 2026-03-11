# Test Run Report - 2026-03-11

## Environment
- Host: local macOS (Apple Silicon)
- Simulator: Icarus Verilog 13.0 (stable)

## Commands
1. `make tb_fifo`
2. `make tb_top`
3. `make tb_riscv_axi`

## Results Summary
- `tb_fifo`: PASS
- `tb_top`: PASS
- `tb_riscv_axi`: FAIL

## Detailed Results

### tb_fifo
- Outcome: PASS
- Last line: `tb/tb_dual_bank_fifo.v:54: $finish called at 165000 (1ps)`

### tb_top
- Outcome: PASS
- Last line: `tb/tb_bibieq_dma_banked_top.v:90: $finish called at 335000 (1ps)`

### tb_riscv_axi
- Outcome: FAIL
- Errors observed:
  - AXI-Lite handshake timeouts:
    - `ERROR: AXI-Lite WREADY timeout (wready=0 bvalid=1 w_hold=0)`
    - `ERROR: AXI-Lite AWREADY timeout (awready=0 bvalid=1 aw_hold=0)` (repeated)
  - Control flow timeout:
    - `ERROR: timeout waiting for DONE`
  - Scoreboard mismatches:
    - `ERROR: write_count 0 != desc_count 31`
    - `ERROR: result seg_idx set mismatch`
- Coverage summary printed (selected):
  - parity/use_4ec/ds bins covered
  - `phase[5..7]` and `r[5..7]` bins remain zero
  - burst bins only hit `other`
- Final line: `TEST FAILED with 8 error(s)`

## Notes / Suspected Root Cause
- AXI-Lite write responses appear to stall: `bvalid` stays asserted, which holds `awready`/`wready` low in `axi_lite_regs.v`. This blocks subsequent register writes and prevents `START` from reliably issuing.
- Testbench now contains explicit AXI-Lite timeouts and a simulation watchdog to avoid indefinite hangs.

## Files Touched During Run
- `Makefile` (Icarus flags: `-g2012`, include path `-I rtl`)
- `tb/tb_bibieq_dma_banked_riscv_axi.v` (timeouts + watchdog + minor task robustness)

