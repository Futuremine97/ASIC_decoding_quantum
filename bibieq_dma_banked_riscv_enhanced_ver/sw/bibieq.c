#include "bibieq.h"
#include "mmio.h"

void bibieq_init(void) {
    mmio_write32(BIBIEQ_CTRL, BIBIEQ_CTRL_SOFT_RESET);
}

void bibieq_config(uint32_t desc_base, uint16_t desc_count,
                   uint8_t rd_burst_len, uint32_t result_base) {
    mmio_write32(BIBIEQ_DESC_BASE, desc_base);
    mmio_write32(BIBIEQ_DESC_COUNT, desc_count);
    mmio_write32(BIBIEQ_RD_BURST, rd_burst_len);
    mmio_write32(BIBIEQ_RESULT_BASE, result_base);
}

void bibieq_start(void) {
    mmio_write32(BIBIEQ_CTRL, BIBIEQ_CTRL_START);
}

uint32_t bibieq_status(void) {
    return mmio_read32(BIBIEQ_STATUS);
}

int bibieq_wait_done(uint32_t timeout_cycles) {
    while (timeout_cycles--) {
        if (bibieq_status() & BIBIEQ_STATUS_DONE) {
            mmio_write32(BIBIEQ_CTRL, BIBIEQ_CTRL_CLR_DONE);
            return 0;
        }
    }
    return -1;
}
