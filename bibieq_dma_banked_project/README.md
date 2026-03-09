# BiBiEQ-inspired Verilog project (banked FIFO + DMA version)

This project is based on the paper **"BiBiEQ: Bivariate Bicycle Codes on Erasure Qubits"**. It extends a prior single-stream control example into a **banked even/odd FIFO** architecture with **DMA-based descriptor/result movement**.

The paper defines a **7-phase memory circuit**, a **4-bundle schedule-aware segment decomposition**, and **BiBiEQ-Exact / BiBiEQ-Approx dual engines**. In short: a seven‑phase BB CNOT schedule is compressed into four CNOT bundles with checkpoints `{A,B,C,D}`, using `S4EC = SABCD` and `S2EC = SBD`. Segments are defined around reset/EC records, posteriors are computed per segment, and then converted by Exact / Approx engines. This project preserves that structure and adds a hardware‑optimization layer.

## Key ideas added in this version

### 1) Even / odd FIFO banking

Descriptors are routed by `seg_idx[0]` parity:

- Even `seg_idx` -> **even bank FIFO**
- Odd `seg_idx` -> **odd bank FIFO**

This enables **independent dequeue** per bank, avoiding head‑of‑line blocking and allowing **parallel processing** of even/odd segments.

### 2) DMA-based descriptor fetch / result writeback

- `dma_desc_fetch.v` bursts descriptors from memory
- `dual_bank_fifo.v` buffers descriptors in two banks
- Two `segment_worker.v` instances process in parallel
- `result_arbiter.v` merges results
- `dma_result_writeback.v` streams results back to memory

DMA movement overlaps with computation, improving efficiency versus a CPU‑fed or polling pipeline.

## Relationship to the paper

These modules map directly to structures described in the paper:

- `bb_phase_router.v`
  - Router based on the paper’s seven‑phase BB CNOT schedule
- `ec_schedule_ctrl.v`
  - Maps the 4‑bundle checkpoints to hardware phase boundaries (`4EC = A/B/C/D`, `2EC = B/D`)
- `posterior_calc.v`
  - Computes canonical fault‑site posteriors per segment
- `engine_exact.v`
  - Exact‑style mask engine (simplified first‑hit + suffix correlation)
- `engine_approx.v`
  - Approx‑style mask engine (independent approximation)

These modules are **hardware optimizations not present in the paper**:

- `dual_bank_fifo.v`
- `dma_desc_fetch.v`
- `dma_result_writeback.v`
- `result_arbiter.v`
- `segment_worker.v`
- `bibieq_dma_banked_top.v`

So this design is **not** a literal Verilog translation of the paper; it reuses the schedule/segment/engine ideas and re‑architects them as a **banked, streaming accelerator** for FPGA/ASIC throughput.

## Directory structure

### Core modules

- `rtl/bb_phase_router.v`
- `rtl/ec_schedule_ctrl.v`
- `rtl/posterior_calc.v`
- `rtl/engine_exact.v`
- `rtl/engine_approx.v`
- `rtl/segment_processor.v`
- `rtl/lfsr16.v`

### Modules added in this version

- `rtl/dual_bank_fifo.v`
  - Even/odd banked FIFO
- `rtl/segment_worker.v`
  - Consumes one descriptor and packs router + schedule + posterior + engine outputs into a 64‑bit result
- `rtl/dma_desc_fetch.v`
  - Descriptor burst‑read DMA
- `rtl/result_arbiter.v`
  - Merges even/odd worker results
- `rtl/dma_result_writeback.v`
  - Streaming result writeback DMA
- `rtl/bibieq_dma_banked_top.v`
  - Top‑level integration (DMA + banked FIFO + dual workers)

### Testbenches

- `tb/tb_dual_bank_fifo.v`
- `tb/tb_bibieq_dma_banked_top.v`

## Data formats

### Descriptor format (`64-bit`)

- `[63:56]` : `seg_idx`
- `[55]`    : `use_4ec`
- `[54:52]` : `phase`
- `[51:49]` : `r`
- `[48]`    : `ds`
- `[47:32]` : `e_q` (Q0.16)
- `[31:16]` : `q_q` (Q0.16)
- `[15:12]` : `u`
- `[11:8]`  : `v`
- `[7:0]`   : reserved

### Result format (`64-bit`)

- `[63:56]` : `seg_idx`
- `[55]`    : `checkpoint_valid`
- `[54:53]` : `checkpoint_id`
- `[52:48]` : `exact_mask`
- `[47:43]` : `approx_mask`
- `[42]`    : `exact_first_hit_valid`
- `[41:39]` : `exact_first_hit_idx`
- `[38:23]` : `p_flag_q`
- `[22]`    : `x_valid`
- `[21]`    : `x_target_is_l`
- `[20]`    : `x_target_is_r`
- `[19:16]` : `x_u`
- `[15:12]` : `x_v`
- `[11]`    : `z_valid`
- `[10]`    : `z_source_is_l`
- `[9]`     : `z_source_is_r`
- `[8:5]`   : `z_u`
- `[4:1]`   : `z_v`
- `[0]`     : reserved

## Processing pipeline

1. `dma_desc_fetch` bursts descriptors from memory
2. `dual_bank_fifo` stores them by `seg_idx[0]` parity
3. Even/odd workers consume descriptors in parallel
4. Each worker computes schedule/router/posterior/exact/approx and outputs a 64‑bit result
5. `result_arbiter` merges results round‑robin
6. `dma_result_writeback` streams results to memory

## Throughput perspective

A single FIFO often limits sustained consumption to roughly **1 descriptor/cycle** due to head‑of‑line blocking.

With:

- **2‑bank buffering**
- **2‑lane workers**
- **DMA prefetch + writeback overlap**

This design can reach **up to ~2 descriptors/cycle** for favorable even/odd patterns. Actual sustained throughput depends on:

- Even/odd distribution
- Worker latency
- Writeback backpressure
- Memory burst efficiency

## Limitations (honest notes)

- This is **not** a full, decoder‑ready implementation of the paper.
- Stim circuit lowering, full stabilizer‑circuit emission, and a complete BP+OSD decoder are **not included**.
- The DMA interface is a **generic burst/streaming memory interface**.
  - For real SoC integration, an AXI4/AXI4‑Stream wrapper is the natural next step.
- This environment does not include `iverilog` or `verilator`, so **compilation/simulation was not run here**.

## If you want to extend this into a full research/graduate project

1. Replace `dma_desc_fetch` with AXI4 master read
2. Replace `dma_result_writeback` with AXI4 master write
3. Widen descriptors to `128/256-bit` to pack multiple segments per beat
4. Extend banking beyond even/odd (e.g., `mod-4` banks)
5. Split Approx/Exact into separate lanes for throughput‑vs‑accuracy modes
6. Build a Python/Stim golden model and co‑simulate descriptor/result streams
