# Stim Integration (BiBiEQ)

The BiBiEQ paper describes a parameterized generator for seven-phase BB memory circuits in Stim and schedule-aware EC insertion. This folder adds a small bridge from Stim circuits to the RTL testbench used in this project.

## Files

- `stim_to_descriptors.py`: Parse a `.stim` file and emit 64-bit descriptor words (`.hex`) for the AXI testbench.

## How It Helps

- Lets you drive the Verilog testbench with phase/round patterns from a real Stim circuit.
- Makes coverage more realistic than purely random descriptors.

## Usage

1) Generate or obtain a Stim circuit (from your BiBiEQ circuit builder):

```
/path/to/circuit.stim
```

2) Convert it into descriptors:

```bash
python3 stim/stim_to_descriptors.py \
  --stim /path/to/circuit.stim \
  --out tb/descriptors.hex \
  --phases 7 \
  --schedule 4EC
```

3) Run the AXI testbench using those descriptors:

```bash
make tb_riscv_axi VVP_ARGS="+DESC_FILE=tb/descriptors.hex +DESC_COUNT=128"
```

## Notes

- The converter uses `TICK` boundaries to define phases (default: 7 phases per round).
- The `r` field wraps by default every 5 rounds (`--r-mod 5`) to match the testbench bins.
- `ds`, `u`, and `v` are generated deterministically (see flags in `stim_to_descriptors.py`).
- If your circuit uses a different phase count, pass `--phases` accordingly.
