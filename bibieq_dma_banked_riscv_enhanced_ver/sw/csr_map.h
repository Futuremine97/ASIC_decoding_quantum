#pragma once
#include <stdint.h>

// CSR register offsets (byte)
#define BIBIEQ_CSR_CTRL        0x000u
#define BIBIEQ_CSR_STATUS      0x004u
#define BIBIEQ_CSR_DESC_BASE   0x008u
#define BIBIEQ_CSR_DESC_COUNT  0x00Cu
#define BIBIEQ_CSR_RD_BURST    0x010u
#define BIBIEQ_CSR_RESULT_BASE 0x014u
#define BIBIEQ_CSR_EVEN_LEVEL  0x018u
#define BIBIEQ_CSR_ODD_LEVEL   0x01Cu

// CTRL bits
#define BIBIEQ_CTRL_START      (1u << 0)
#define BIBIEQ_CTRL_CLR_DONE   (1u << 1)
#define BIBIEQ_CTRL_SOFT_RESET (1u << 2)

// STATUS bits
#define BIBIEQ_STATUS_BUSY     (1u << 0)
#define BIBIEQ_STATUS_DONE     (1u << 1)
#define BIBIEQ_STATUS_FETCH    (1u << 2)
#define BIBIEQ_STATUS_STORE    (1u << 3)
