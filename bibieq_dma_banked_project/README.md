# BiBiEQ-inspired Verilog project (banked FIFO + DMA version)

이 프로젝트는 논문 **“BiBiEQ: Bivariate Bicycle Codes on Erasure Qubits”**를 바탕으로, 이전의 단일 스트림 제어 예제를 **even/odd 인덱스 분리 FIFO**와 **DMA 기반 descriptor/result 이동** 구조로 확장한 버전입니다.

논문 원문은 BB 코드의 **7-phase memory circuit**, **4-bundle schedule-aware segment decomposition**, 그리고 **BiBiEQ-Exact / BiBiEQ-Approx dual engine**을 정의합니다. 구체적으로, 논문은 seven-phase BB CNOT schedule을 사용하고, 7개 phase를 4개의 CNOT bundle로 압축한 뒤 checkpoint `{A,B,C,D}`를 배치하며, `S4EC = SABCD`, `S2EC = SBD`를 사용합니다. 또한 reset/EC record를 기준으로 segment를 나누고, 각 segment에 대해 posterior를 계산한 다음 Exact / Approx 엔진으로 변환합니다. citeturn3view1turn3view0turn3view2

이 프로젝트는 그 논문 구조 위에 **하드웨어 최적화 레이어**를 추가한 것입니다.

## 이번 버전에서 추가한 핵심 아이디어

### 1) even / odd FIFO banking

입력 descriptor를 `seg_idx[0]` parity로 분기합니다.

- `seg_idx`가 짝수면 **even bank FIFO**
- `seg_idx`가 홀수면 **odd bank FIFO**

이렇게 하면 두 bank를 **독립적으로 dequeue**할 수 있어서,
단일 FIFO처럼 head-of-line blocking이 생기지 않고,
**짝수 lane / 홀수 lane**에서 동시에 segment를 처리할 수 있습니다.

### 2) DMA 기반 descriptor fetch / result writeback

- `dma_desc_fetch.v`가 descriptor memory에서 **burst read**
- `dual_bank_fifo.v`가 banked buffering
- `segment_worker.v` 두 개가 병렬 처리
- `result_arbiter.v`가 결과를 merge
- `dma_result_writeback.v`가 결과를 연속 주소에 **streaming writeback**

즉,
**메모리 이동(DMA)** 과 **segment 연산(worker)** 을 겹쳐서,
단순 polling/CPU-fed 구조보다 효율을 높이도록 구성했습니다.

## 논문과의 연결점

아래 부분은 논문에서 직접 가져온 구조입니다.

- `bb_phase_router.v`
  - 논문의 Table II seven-phase BB CNOT schedule 기반 라우터
- `ec_schedule_ctrl.v`
  - 논문의 4-bundle checkpoint 구조를 하드웨어 phase boundary로 매핑
  - `4EC = A/B/C/D`, `2EC = B/D`
- `posterior_calc.v`
  - segment 안의 canonical fault site posterior 계산
- `engine_exact.v`
  - first-hit + suffix correlation을 단순화한 exact-style mask 엔진
- `engine_approx.v`
  - independent approximation 기반 approx-style mask 엔진

아래 부분은 **논문에 없는 hardware optimization** 입니다.

- `dual_bank_fifo.v`
- `dma_desc_fetch.v`
- `dma_result_writeback.v`
- `result_arbiter.v`
- `segment_worker.v`
- `bibieq_dma_banked_top.v`

즉, 이 설계는 **논문 내용을 그대로 Verilog로 번역한 것**이 아니라,
논문의 schedule/segment/engine 구조를 유지하면서,
**FPGA/ASIC에서 처리량을 높이기 위한 banked streaming accelerator** 형태로 다시 구성한 것입니다. 논문 자체는 Stim 기반 시뮬레이션/컴파일 프레임워크이고, Exact/Approx의 정확도 차이도 schedule에 따라 달라지며, 특히 4EC에서 Approx와 Exact 간의 간격이 훨씬 줄어든다고 보고합니다. citeturn3view3turn3view2

## 디렉터리 구조

### 기존 핵심 모듈

- `rtl/bb_phase_router.v`
- `rtl/ec_schedule_ctrl.v`
- `rtl/posterior_calc.v`
- `rtl/engine_exact.v`
- `rtl/engine_approx.v`
- `rtl/segment_processor.v`
- `rtl/lfsr16.v`

### 이번에 추가된 모듈

- `rtl/dual_bank_fifo.v`
  - 짝수/홀수 bank 분리 FIFO
- `rtl/segment_worker.v`
  - descriptor 1개를 받아 router + schedule + posterior + engine 결과를 64-bit result로 패킹
- `rtl/dma_desc_fetch.v`
  - descriptor burst read DMA
- `rtl/result_arbiter.v`
  - even/odd worker 결과 병합
- `rtl/dma_result_writeback.v`
  - 결과 streaming writeback DMA
- `rtl/bibieq_dma_banked_top.v`
  - DMA + banked FIFO + dual worker 통합 top

### 테스트벤치

- `tb/tb_dual_bank_fifo.v`
- `tb/tb_bibieq_dma_banked_top.v`

## 데이터 포맷

### Descriptor format (`64-bit`)

- `[63:56]` : `seg_idx`
- `[55]`    : `use_4ec`
- `[54:52]` : `phase`
- `[51:49]` : `r`
- `[48]`    : `ds`
- `[47:32]` : `e_q` (Q0.16)
- `[31:16]` : `q_q` (Q0.16)
- `[15:12]` : `u`
- `[11:8]`  : `v`
- `[7:0]`   : reserved

### Result format (`64-bit`)

- `[63:56]` : `seg_idx`
- `[55]`    : `checkpoint_valid`
- `[54:53]` : `checkpoint_id`
- `[52:48]` : `exact_mask`
- `[47:43]` : `approx_mask`
- `[42]`    : `exact_first_hit_valid`
- `[41:39]` : `exact_first_hit_idx`
- `[38:23]` : `p_flag_q`
- `[22]`    : `x_valid`
- `[21]`    : `x_target_is_l`
- `[20]`    : `x_target_is_r`
- `[19:16]` : `x_u`
- `[15:12]` : `x_v`
- `[11]`    : `z_valid`
- `[10]`    : `z_source_is_l`
- `[9]`     : `z_source_is_r`
- `[8:5]`   : `z_u`
- `[4:1]`   : `z_v`
- `[0]`     : reserved

## 처리 파이프라인

1. `dma_desc_fetch`가 메모리에서 descriptor를 burst로 읽음
2. `dual_bank_fifo`가 `seg_idx[0]` 기준으로 even/odd bank에 저장
3. even worker와 odd worker가 각 bank에서 동시에 descriptor를 소비
4. 각 worker는 schedule/router/posterior/exact/approx를 계산해 64-bit result 생성
5. `result_arbiter`가 결과를 round-robin으로 병합
6. `dma_result_writeback`이 결과를 연속 주소에 기록

## 대역폭 관점에서의 의미

단일 FIFO에서는 producer가 빠르더라도 consumer가 한 줄만 dequeue하므로,
실질 처리량이 **1 descriptor / cycle 근처**로 묶이기 쉽습니다.

이번 구조는
- **2-bank buffering**
- **2-lane worker**
- **DMA prefetch + writeback overlap**

을 사용하므로, bank 충돌이 적은 입력 패턴에서는 소비 측 처리량이 **최대 2 descriptor / cycle**까지 올라갈 수 있습니다.
물론 실제 sustained throughput은
- even/odd 분포
- worker latency
- writeback backpressure
- memory burst efficiency
에 따라 달라집니다.

## 한계와 정직한 설명

- 이 프로젝트는 **논문 전체를 decoder-ready로 구현한 것은 아닙니다.**
- 특히 Stim circuit lowering, full stabilizer-circuit emission, BP+OSD decoder 자체는 포함하지 않습니다.
- DMA 인터페이스는 **generic burst/streaming memory interface** 형태로 단순화했습니다.
  - 실제 SoC 연결 시에는 AXI4/AXI4-Stream wrapper를 추가하는 것이 자연스럽습니다.
- 이 실행 환경에는 `iverilog` / `verilator`가 없어서 **실제 컴파일/시뮬레이션 검증은 수행하지 못했습니다.**

## 연구/졸업프로젝트 수준으로 확장하려면

1. `dma_desc_fetch`를 AXI4 master read로 교체
2. `dma_result_writeback`을 AXI4 master write burst로 교체
3. descriptor를 `128/256-bit`로 widen 해서 한 beat에 여러 segment를 싣기
4. even/odd를 넘어 `mod-4` bank까지 확장
5. Approx / Exact lane을 분리해 throughput-vs-accuracy 모드 지원
6. Python/Stim golden model과 descriptor/result co-simulation 구축
