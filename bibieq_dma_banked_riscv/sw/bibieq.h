#pragma once
#include <stdint.h>
#include "platform.h"

#define BIBIEQ_CTRL          (BIBIEQ_CSR_BASE + 0x00)
#define BIBIEQ_STATUS        (BIBIEQ_CSR_BASE + 0x04)
#define BIBIEQ_DESC_BASE     (BIBIEQ_CSR_BASE + 0x08)
#define BIBIEQ_DESC_COUNT    (BIBIEQ_CSR_BASE + 0x0C)
#define BIBIEQ_RD_BURST      (BIBIEQ_CSR_BASE + 0x10)
#define BIBIEQ_RESULT_BASE   (BIBIEQ_CSR_BASE + 0x14)
#define BIBIEQ_EVEN_LEVEL    (BIBIEQ_CSR_BASE + 0x18)
#define BIBIEQ_ODD_LEVEL     (BIBIEQ_CSR_BASE + 0x1C)

#define BIBIEQ_CTRL_START      (1u << 0)
#define BIBIEQ_CTRL_CLR_DONE   (1u << 1)
#define BIBIEQ_CTRL_SOFT_RESET (1u << 2)

#define BIBIEQ_STATUS_BUSY     (1u << 0)
#define BIBIEQ_STATUS_DONE     (1u << 1)
#define BIBIEQ_STATUS_FETCH    (1u << 2)
#define BIBIEQ_STATUS_STORE    (1u << 3)

void bibieq_init(void);
void bibieq_config(uint32_t desc_base, uint16_t desc_count,
                   uint8_t rd_burst_len, uint32_t result_base);
void bibieq_start(void);
uint32_t bibieq_status(void);
int bibieq_wait_done(uint32_t timeout_cycles);
