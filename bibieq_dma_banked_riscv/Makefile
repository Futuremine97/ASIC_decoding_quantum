RTL := rtl/lfsr16.v \
       rtl/posterior_calc.v \
       rtl/engine_exact.v \
       rtl/engine_approx.v \
       rtl/segment_processor.v \
       rtl/ec_schedule_ctrl.v \
       rtl/bb_phase_router.v \
       rtl/async_fifo.v \
       rtl/dual_bank_async_fifo.v \
       rtl/dual_bank_fifo.v \
       rtl/segment_worker.v \
       rtl/dma_desc_fetch.v \
       rtl/result_arbiter.v \
       rtl/dma_result_writeback.v \
       rtl/bibieq_dma_banked_top.v \
       rtl/axi_lite_regs.v \
       rtl/apb_regs.v \
       rtl/ahb_lite_regs.v \
       rtl/sync_2ff.v \
       rtl/reset_sync.v \
       rtl/axi_read_master.v \
       rtl/axi_write_master.v \
       rtl/bibieq_dma_banked_riscv_top.v \
       rtl/bibieq_dma_banked_riscv_fast_top.v \
       rtl/bibieq_dma_banked_riscv_apb_top.v \
       rtl/bibieq_dma_banked_riscv_ahb_top.v

all:
	@echo "Targets: tb_fifo tb_top tb_riscv_axi tb_riscv_axi_fast"

tb_fifo:
	iverilog -g2005 -o sim_fifo $(RTL) tb/tb_dual_bank_fifo.v
	vvp sim_fifo

tb_top:
	iverilog -g2005 -o sim_top $(RTL) tb/tb_bibieq_dma_banked_top.v
	vvp sim_top

tb_riscv_axi:
	iverilog -g2005 -o sim_riscv_axi $(RTL) tb/tb_bibieq_dma_banked_riscv_axi.v
	vvp sim_riscv_axi

tb_riscv_axi_fast:
	iverilog -g2005 -o sim_riscv_axi_fast $(RTL) -P tb_bibieq_dma_banked_riscv_axi.FAST_MODE=1 tb/tb_bibieq_dma_banked_riscv_axi.v
	vvp sim_riscv_axi_fast

clean:
	rm -f sim_fifo sim_top sim_riscv_axi sim_riscv_axi_fast
