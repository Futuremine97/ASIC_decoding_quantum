# Performance & Accuracy Evaluation

## Metrics

- **Throughput**: descriptors/sec = `clk_hz * desc_per_cycle`
- **Latency**: cycles per descriptor (end-to-end)
- **Utilization**: even/odd bank occupancy over time
- **Accuracy**: Exact vs Approx mismatch rate (when applicable)

## Measurement Method

1. Fix `DESC_COUNT`, `RD_BURST_LEN`, and clock frequency.
2. Capture cycles from `START` to `DONE`.
3. Compute `desc_per_cycle` and `desc_per_sec`.
4. Compare FAST vs non-FAST outputs if a golden model is available.

## Reporting Template

| Mode | clk_hz | desc_count | cycles | desc/cycle | desc/sec | notes |
|---|---:|---:|---:|---:|---:|---|
| EXACT | | | | | | |
| FAST | | | | | | |
| HETERO (even FAST, odd EXACT) | | | | | | |
