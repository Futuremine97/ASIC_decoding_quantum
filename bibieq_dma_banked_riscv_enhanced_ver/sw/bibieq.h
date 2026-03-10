#pragma once
#include <stdint.h>
#include "platform.h"
#include "csr_map.h"

#define BIBIEQ_CTRL          (BIBIEQ_CSR_BASE + BIBIEQ_CSR_CTRL)
#define BIBIEQ_STATUS        (BIBIEQ_CSR_BASE + BIBIEQ_CSR_STATUS)
#define BIBIEQ_DESC_BASE     (BIBIEQ_CSR_BASE + BIBIEQ_CSR_DESC_BASE)
#define BIBIEQ_DESC_COUNT    (BIBIEQ_CSR_BASE + BIBIEQ_CSR_DESC_COUNT)
#define BIBIEQ_RD_BURST      (BIBIEQ_CSR_BASE + BIBIEQ_CSR_RD_BURST)
#define BIBIEQ_RESULT_BASE   (BIBIEQ_CSR_BASE + BIBIEQ_CSR_RESULT_BASE)
#define BIBIEQ_EVEN_LEVEL    (BIBIEQ_CSR_BASE + BIBIEQ_CSR_EVEN_LEVEL)
#define BIBIEQ_ODD_LEVEL     (BIBIEQ_CSR_BASE + BIBIEQ_CSR_ODD_LEVEL)

void bibieq_init(void);
void bibieq_config(uint32_t desc_base, uint16_t desc_count,
                   uint8_t rd_burst_len, uint32_t result_base);
void bibieq_start(void);
uint32_t bibieq_status(void);
int bibieq_wait_done(uint32_t timeout_cycles);
