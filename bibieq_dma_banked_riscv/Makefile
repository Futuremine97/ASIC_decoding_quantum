RTL := rtl/lfsr16.v \
       rtl/posterior_calc.v \
       rtl/engine_exact.v \
       rtl/engine_approx.v \
       rtl/segment_processor.v \
       rtl/ec_schedule_ctrl.v \
       rtl/bb_phase_router.v \
       rtl/dual_bank_fifo.v \
       rtl/segment_worker.v \
       rtl/dma_desc_fetch.v \
       rtl/result_arbiter.v \
       rtl/dma_result_writeback.v \
       rtl/bibieq_dma_banked_top.v \
       rtl/axi_lite_regs.v \
       rtl/axi_read_master.v \
       rtl/axi_write_master.v \
       rtl/bibieq_dma_banked_riscv_top.v \
       rtl/bibieq_dma_banked_riscv_fast_top.v

all:
	@echo "Targets: tb_fifo tb_top"

tb_fifo:
	iverilog -g2005 -o sim_fifo $(RTL) tb/tb_dual_bank_fifo.v
	vvp sim_fifo

tb_top:
	iverilog -g2005 -o sim_top $(RTL) tb/tb_bibieq_dma_banked_top.v
	vvp sim_top

clean:
	rm -f sim_fifo sim_top
