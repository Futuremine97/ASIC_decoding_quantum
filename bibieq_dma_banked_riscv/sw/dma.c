#include "dma.h"
#include "mmio.h"

void dma_start(uint32_t src, uint32_t dst, uint32_t len_bytes) {
    mmio_write32(DMA_SRC, src);
    mmio_write32(DMA_DST, dst);
    mmio_write32(DMA_LEN, len_bytes);
    mmio_write32(DMA_CTRL, DMA_CTRL_START);
}

int dma_wait_done(uint32_t timeout_cycles) {
    while (timeout_cycles--) {
        uint32_t st = mmio_read32(DMA_STATUS);
        if (st & DMA_STATUS_DONE) {
            return 0;
        }
        if (st & DMA_STATUS_ERR) {
            return -2;
        }
    }
    return -1;
}
