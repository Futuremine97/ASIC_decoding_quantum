#include <stdint.h>
#include "platform.h"
#include "bibieq.h"
#include "dma.h"

int main(void) {
    uint32_t desc_base   = BANKED_SRAM_BASE + 0x0000;
    uint32_t result_base = BANKED_SRAM_BASE + 0x1000;

    // Example: program BIBIEQ
    bibieq_init();
    bibieq_config(desc_base, 128, 8, result_base);
    bibieq_start();

    // Wait for completion
    if (bibieq_wait_done(1000000) != 0) {
        // timeout/error handling
        return -1;
    }

    // Example: use DMA controller (if applicable)
    // dma_start(desc_base, result_base, 128 * 8);
    // dma_wait_done(1000000);

    return 0;
}
