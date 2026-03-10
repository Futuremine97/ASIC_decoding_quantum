#pragma once
#include <stdint.h>
#include "platform.h"

#define DMA_CTRL        (DMA_CSR_BASE + 0x00)
#define DMA_STATUS      (DMA_CSR_BASE + 0x04)
#define DMA_SRC         (DMA_CSR_BASE + 0x08)
#define DMA_DST         (DMA_CSR_BASE + 0x0C)
#define DMA_LEN         (DMA_CSR_BASE + 0x10)

#define DMA_CTRL_START  (1u << 0)
#define DMA_CTRL_IRQEN  (1u << 1)

#define DMA_STATUS_BUSY (1u << 0)
#define DMA_STATUS_DONE (1u << 1)
#define DMA_STATUS_ERR  (1u << 2)

void dma_start(uint32_t src, uint32_t dst, uint32_t len_bytes);
int  dma_wait_done(uint32_t timeout_cycles);
