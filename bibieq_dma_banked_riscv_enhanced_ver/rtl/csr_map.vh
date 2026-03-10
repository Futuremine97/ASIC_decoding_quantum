`ifndef CSR_MAP_VH
`define CSR_MAP_VH

// CSR register offsets (byte)
`define CSR_CTRL        12'h000
`define CSR_STATUS      12'h004
`define CSR_DESC_BASE   12'h008
`define CSR_DESC_COUNT  12'h00C
`define CSR_RD_BURST    12'h010
`define CSR_RESULT_BASE 12'h014
`define CSR_EVEN_LEVEL  12'h018
`define CSR_ODD_LEVEL   12'h01C

// CTRL bits
`define CSR_CTRL_START      0
`define CSR_CTRL_CLR_DONE   1
`define CSR_CTRL_SOFT_RESET 2

// STATUS bits
`define CSR_STATUS_BUSY   0
`define CSR_STATUS_DONE   1
`define CSR_STATUS_FETCH  2
`define CSR_STATUS_STORE  3

`endif
