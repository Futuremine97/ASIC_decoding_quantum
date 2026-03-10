# MMIO Driver Scaffold

This folder provides a minimal C driver scaffold for the BIBIEQ accelerator and a generic DMA controller.

## Files

- `platform.h` - system address map
- `csr_map.h` - CSR offsets/bits
- `mmio.h` - MMIO access helpers
- `bibieq.h/.c` - BIBIEQ driver
- `dma.h/.c` - DMA driver
- `main.c` - example usage

## Notes

- The DMA register map is a placeholder; update offsets to your SoC DMA IP.
- Use `fence iorw, iorw` to ensure MMIO ordering on RISC-V.
