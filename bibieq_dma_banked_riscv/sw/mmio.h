#pragma once
#include <stdint.h>

static inline void mmio_write32(uint32_t addr, uint32_t value) {
    *(volatile uint32_t*)addr = value;
    __asm__ volatile ("fence iorw, iorw" ::: "memory");
}

static inline uint32_t mmio_read32(uint32_t addr) {
    uint32_t v = *(volatile uint32_t*)addr;
    __asm__ volatile ("fence iorw, iorw" ::: "memory");
    return v;
}
