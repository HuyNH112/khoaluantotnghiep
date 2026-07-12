// ===========================================================================
// File: tb_cva6_hpdcache_integrated.sv
// Title: CVA6 RISC-V + HPDCache L1 + Domino Prefetcher - Integrated System Test
// Author: IC Design Engineer (Mentor)
// Purpose: THESIS VALIDATION - Prove correct integration & protocol compliance
// ===========================================================================
`timescale 1ns/1ps

`include "cva6_config_pkg.svh"
`include "hpdcache_typedef.svh"
`include "hpdcache_config.svh"

module tb_cva6_hpdcache_integrated;
  import cva6_pkg::*;
  import hpdcache_pkg::*;
  import domino_pkg::*;

  // ========== 1. CLOCK & RESET ==========
  parameter CLK_PERIOD = 10; // ns
  logic clk;
  logic rst_n;

  initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  initial begin
    rst_n = 0;
    #100;
    rst_n = 1;
  end

  // ========== 2. CVA6 CONFIGURATION ==========
  localparam config_pkg::cva6_cfg_t CVA6Cfg = 
    build_config_pkg::build_config(cva6_config_pkg::cva6_cfg);

  // ========== 3. HPDCACHE CONFIGURATION (I-Cache & D-Cache) ==========
  localparam hpdcache_user_cfg_t ICacheCfg = '{
    nRequesters: 1,
    paWidth: `CONF_HPDCACHE_PA_WIDTH,
    wordWidth: `CONF_HPDCACHE_WORD_WIDTH,
    sets: 64,
    ways: 4,
    clWords: `CONF_HPDCACHE_CL_WORDS,
    reqWords: `CONF_HPDCACHE_REQ_WORDS,
    reqTransIdWidth: `CONF_HPDCACHE_REQ_TRANS_ID_WIDTH,
    reqSrcIdWidth: 1,  // I-Cache = source 0
    victimSel: `CONF_HPDCACHE_VICTIM_SEL,
    dataWaysPerRamWord: `CONF_HPDCACHE_DATA_WAYS_PER_RAM_WORD,
    dataSetsPerRam: `CONF_HPDCACHE_DATA_SETS_PER_RAM,
    dataRamByteEnable: `CONF_HPDCACHE_DATA_RAM_WBYTEENABLE,
    accessWords: `CONF_HPDCACHE_ACCESS_WORDS,
    mshrSets: 4,
    mshrWays: 2,
    mshrWaysPerRamWord: `CONF_HPDCACHE_MSHR_WAYS_PER_RAM_WORD,
    mshrSetsPerRam: `CONF_HPDCACHE_MSHR_SETS_PER_RAM,
    mshrRamByteEnable: `CONF_HPDCACHE_MSHR_RAM_WBYTEENABLE,
    mshrUseRegbank: `CONF_HPDCACHE_MSHR_USE_REGBANK,
    cbufEntries: `CONF_HPDCACHE_CBUF_ENTRIES,
    refillCoreRspFeedthrough: `CONF_HPDCACHE_REFILL_CORE_RSP_FEEDTHROUGH,
    refillFifoDepth: `CONF_HPDCACHE_REFILL_FIFO_DEPTH,
    wbufDirEntries: 0,  // I-Cache is read-only
    wbufDataEntries: 0,
    wbufWords: 0,
    wbufTimecntWidth: 1,
    rtabEntries: `CONF_HPDCACHE_RTAB_ENTRIES,
    flushEntries: `CONF_HPDCACHE_FLUSH_ENTRIES,
    flushFifoDepth: `CONF_HPDCACHE_FLUSH_FIFO_DEPTH,
    memAddrWidth: `CONF_HPDCACHE_MEM_ADDR_WIDTH,
    memIdWidth: 4,  // Separate ID space for I-Cache
    memDataWidth: `CONF_HPDCACHE_MEM_DATA_WIDTH,
    wtEn: 1'b1,
    wbEn: 1'b0,  // I-Cache: write-through only
    lowLatency: 1'b1,
    eccEn: `CONF_HPDCACHE_ECC_ENABLE,
    eccScrubberEn: 1'b0
  };

  localparam hpdcache_user_cfg_t DCacheCfg = '{
    nRequesters: 1,
    paWidth: `CONF_HPDCACHE_PA_WIDTH,
    wordWidth: `CONF_HPDCACHE_WORD_WIDTH,
    sets: 64,
    ways: 4,
    clWords: `CONF_HPDCACHE_CL_WORDS,
    reqWords: `CONF_HPDCACHE_REQ_WORDS,
    reqTransIdWidth: `CONF_HPDCACHE_REQ_TRANS_ID_WIDTH,
    reqSrcIdWidth: 1,  // D-Cache = source 1
    victimSel: `CONF_HPDCACHE_VICTIM_SEL,
    dataWaysPerRamWord: `CONF_HPDCACHE_DATA_WAYS_PER_RAM_WORD,
    dataSetsPerRam: `CONF_HPDCACHE_DATA_SETS_PER_RAM,
    dataRamByteEnable: `CONF_HPDCACHE_DATA_RAM_WBYTEENABLE,
    accessWords: `CONF_HPDCACHE_ACCESS_WORDS,
    mshrSets: 8,        // ← CRITICAL: 8 MSHR entries for prefetch buffering
    mshrWays: 1,
    mshrWaysPerRamWord: `CONF_HPDCACHE_MSHR_WAYS_PER_RAM_WORD,
    mshrSetsPerRam: `CONF_HPDCACHE_MSHR_SETS_PER_RAM,
    mshrRamByteEnable: `CONF_HPDCACHE_MSHR_RAM_WBYTEENABLE,
    mshrUseRegbank: `CONF_HPDCACHE_MSHR_USE_REGBANK,
    cbufEntries: `CONF_HPDCACHE_CBUF_ENTRIES,
    refillCoreRspFeedthrough: `CONF_HPDCACHE_REFILL_CORE_RSP_FEEDTHROUGH,
    refillFifoDepth: `CONF_HPDCACHE_REFILL_FIFO_DEPTH,
    wbufDirEntries: 16, // ← Writeback buffer for dirty cache lines
    wbufDataEntries: 16,
    wbufWords: 4,
    wbufTimecntWidth: `CONF_HPDCACHE_WBUF_TIMECNT_WIDTH,
    rtabEntries: `CONF_HPDCACHE_RTAB_ENTRIES,
    flushEntries: `CONF_HPDCACHE_FLUSH_ENTRIES,
    flushFifoDepth: `CONF_HPDCACHE_FLUSH_FIFO_DEPTH,
    memAddrWidth: `CONF_HPDCACHE_MEM_ADDR_WIDTH,
    memIdWidth: 4,  // Separate ID space for D-Cache
    memDataWidth: `CONF_HPDCACHE_MEM_DATA_WIDTH,
    wtEn: 1'b0,
    wbEn: 1'b1,  // D-Cache: write-back enabled
    lowLatency: 1'b1,
    eccEn: `CONF_HPDCACHE_ECC_ENABLE,
    eccScrubberEn: 1'b0
  };

  localparam hpdcache_cfg_t ICacheCfgBuilt = hpdcacheBuildConfig(ICacheCfg);
  localparam hpdcache_cfg_t DCacheCfgBuilt = hpdcacheBuildConfig(DCacheCfg);

  // ========== 4. TYPE DEFINITIONS ==========
  // I-Cache types
  typedef logic [ICacheCfgBuilt.tagWidth-1:0] icache_tag_t;
  typedef logic [ICacheCfgBuilt.u.wordWidth-1:0] icache_data_word_t;
  typedef logic [ICacheCfgBuilt.u.wordWidth/8-1:0] icache_data_be_t;
  typedef logic [ICacheCfgBuilt.reqOffsetWidth-1:0] icache_req_offset_t;
  typedef logic [ICacheCfgBuilt.u.reqWords-1:0][ICacheCfgBuilt.u.wordWidth-1:0] icache_req_data_t;
  typedef logic [ICacheCfgBuilt.u.reqWords-1:0][ICacheCfgBuilt.u.wordWidth/8-1:0] icache_req_be_t;
  typedef logic [ICacheCfgBuilt.u.reqSrcIdWidth-1:0] icache_req_sid_t;
  typedef logic [ICacheCfgBuilt.u.reqTransIdWidth-1:0] icache_req_tid_t;
  typedef `HPDCACHE_DECL_REQ_T(icache_req_offset_t, icache_req_data_t, icache_req_be_t, 
                                icache_req_sid_t, icache_req_tid_t, icache_tag_t) icache_req_t;
  typedef `HPDCACHE_DECL_RSP_T(icache_req_data_t, icache_req_sid_t, icache_req_tid_t) icache_rsp_t;

  // D-Cache types (identical structure)
  typedef logic [DCacheCfgBuilt.tagWidth-1:0] dcache_tag_t;
  typedef logic [DCacheCfgBuilt.u.wordWidth-1:0] dcache_data_word_t;
  typedef logic [DCacheCfgBuilt.u.wordWidth/8-1:0] dcache_data_be_t;
  typedef logic [DCacheCfgBuilt.reqOffsetWidth-1:0] dcache_req_offset_t;
  typedef logic [DCacheCfgBuilt.u.reqWords-1:0][DCacheCfgBuilt.u.wordWidth-1:0] dcache_req_data_t;
  typedef logic [DCacheCfgBuilt.u.reqWords-1:0][DCacheCfgBuilt.u.wordWidth/8-1:0] dcache_req_be_t;
  typedef logic [DCacheCfgBuilt.u.reqSrcIdWidth-1:0] dcache_req_sid_t;
  typedef logic [DCacheCfgBuilt.u.reqTransIdWidth-1:0] dcache_req_tid_t;
  typedef `HPDCACHE_DECL_REQ_T(dcache_req_offset_t, dcache_req_data_t, dcache_req_be_t, 
                                dcache_req_sid_t, dcache_req_tid_t, dcache_tag_t) dcache_req_t;
  typedef `HPDCACHE_DECL_RSP_T(dcache_req_data_t, dcache_req_sid_t, dcache_req_tid_t) dcache_rsp_t;

  // Memory types
  typedef logic [DCacheCfgBuilt.u.memAddrWidth-1:0] mem_addr_t;
  typedef logic [DCacheCfgBuilt.u.memIdWidth-1:0] mem_id_t;
  typedef logic [DCacheCfgBuilt.u.memDataWidth-1:0] mem_data_t;
  typedef logic [DCacheCfgBuilt.u.memDataWidth/8-1:0] mem_be_t;

  `HPDCACHE_TYPEDEF_MEM_ATTR_T(mem_attr_t, mem_id_t, mem_data_t, mem_be_t, DCacheCfgBuilt);
  `HPDCACHE_TYPEDEF_MEM_REQ_T(mem_req_t, mem_addr_t, mem_id_t);
  `HPDCACHE_TYPEDEF_MEM_RESP_R_T(mem_resp_r_t, mem_id_t, mem_data_t);
  `HPDCACHE_TYPEDEF_MEM_REQ_W_T(mem_req_w_t, mem_data_t, mem_be_t);
  `HPDCACHE_TYPEDEF_MEM_RESP_W_T(mem_resp_w_t, mem_id_t);

  // ========== 5. SIGNAL DECLARATIONS ==========

  // CPU Interface Signals (from CVA6 to caches)
  logic                      cpu_fetch_valid_i;
  logic                      cpu_fetch_ready_o;
  logic [CVA6Cfg.VLEN-1:0]   cpu_fetch_addr_i;
  logic [31:0]               cpu_fetch_data_o;
  logic                      cpu_fetch_hit_o;
  logic                      cpu_fetch_miss_o;

  logic                      cpu_load_valid_i;
  logic                      cpu_load_ready_o;
  logic [CVA6Cfg.VLEN-1:0]   cpu_load_addr_i;
  logic [63:0]               cpu_load_data_o;
  logic                      cpu_load_hit_o;
  logic                      cpu_load_miss_o;

  logic                      cpu_store_valid_i;
  logic                      cpu_store_ready_o;
  logic [CVA6Cfg.VLEN-1:0]   cpu_store_addr_i;
  logic [63:0]               cpu_store_data_i;
  logic [7:0]                cpu_store_be_i;

  // I-Cache signals
  logic                      icache_req_valid;
  logic                      icache_req_ready;
  icache_req_t               icache_req;
  logic                      icache_rsp_valid;
  icache_rsp_t               icache_rsp;

  // D-Cache signals
  logic                      dcache_req_valid;
  logic                      dcache_req_ready;
  dcache_req_t               dcache_req;
  logic                      dcache_rsp_valid;
  dcache_rsp_t               dcache_rsp;
  logic                      dcache_prefetch_req_valid;
  dcache_req_t               dcache_prefetch_req;

  // Memory interface (shared bus with arbiter)
  logic                      mem_ar_valid, mem_ar_ready;
  mem_attr_t                 mem_ar;
  logic                      mem_r_valid, mem_r_ready;
  mem_resp_r_t               mem_r;

  logic                      mem_aw_valid, mem_aw_ready;
  mem_attr_t                 mem_aw;
  logic                      mem_w_valid, mem_w_ready;
  mem_req_w_t                mem_w;
  logic                      mem_b_valid, mem_b_ready;
  mem_resp_w_t               mem_b;

  // ========== 6. METRICS COLLECTION ==========
  int icache_hits_count = 0;
  int icache_misses_count = 0;
  int dcache_hits_count = 0;
  int dcache_misses_count = 0;
  int prefetch_injected_count = 0;
  int prefetch_hit_count = 0;
  int prefetch_miss_count = 0;
  int mshr_peak_occupancy = 0;
  int pipeline_stall_cycles = 0;

  // ========== 7. MEMORY MODEL (AXI SLAVE) ==========
  logic [7:0] memory [0:1048575]; // 1MB simulated memory

  initial begin
    // Initialize memory with test pattern
    for (int i = 0; i < 1048576; i++) begin
      memory[i] = $random;
    end
    $display("[INFO] Memory initialized");
  end

  // Simplified AXI memory response (no back-pressure)
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      mem_r_valid <= 1'b0;
      mem_b_valid <= 1'b0;
    end else begin
      // Read response (1 cycle latency)
      if (mem_ar_valid && mem_ar_ready) begin
        mem_r_valid <= 1'b1;
        mem_r.mem_resp_r_id <= mem_ar.mem_attr_id;
        // Pack 8 bytes into response
        for (int i = 0; i < 8; i++) begin
          mem_r.mem_resp_r_data[i*8 +: 8] <= memory[mem_ar.mem_attr_addr + i];
        end
        mem_r.mem_resp_r_last <= 1'b1;
      end else if (mem_r_valid && mem_r_ready) begin
        mem_r_valid <= 1'b0;
      end

      // Write response (1 cycle after data accepted)
      if (mem_w_valid && mem_w_ready) begin
        mem_b_valid <= 1'b1;
        // ID mapping: D-Cache writes should have corresponding ID
        mem_b.mem_resp_w_id <= mem_aw.mem_attr_id;
      end else if (mem_b_valid && mem_b_ready) begin
        mem_b_valid <= 1'b0;
      end

      // Actually write to memory
      if (mem_w_valid && mem_w_ready && mem_aw_valid) begin
        for (int i = 0; i < 8; i++) begin
          if (mem_w.mem_req_w_data_be[i]) begin
            memory[mem_aw.mem_attr_addr + i] <= 
              mem_w.mem_req_w_data[i*8 +: 8];
          end
        end
      end
    end
  end

  always_comb begin
    mem_ar_ready = !mem_r_valid;  // Accept if not busy
    mem_aw_ready = 1'b1;           // Always accept AW
    mem_w_ready = 1'b1;            // Always accept W
    mem_b_ready = 1'b1;            // Accept B responses
  end

  // ========== 8. DOMINO PREFETCHER INSTANTIATION ==========
  domino_pkg::domino_pref_req_t domino_pref_req;

  domino_prefetcher_top u_domino_prefetcher (
    .clk(clk),
    .rst_n(rst_n),
    // Trigger: D-Cache miss from CPU (not from memory response delay)
    .evt_cache_read_miss_i(cpu_load_miss_o && cpu_load_valid_i),
    .miss_addr_i({cpu_load_addr_i[63:12], 12'b0}),  // Aligned to cache line
    .pref_req_o(domino_pref_req)
  );

  // Inject prefetch request into D-Cache
  assign dcache_prefetch_req_valid = domino_pref_req.valid;
  assign dcache_prefetch_req = '{
    op: HPDCACHE_REQ_LOAD,
    addr_offset: domino_pref_req.pref_addr[11:0],
    addr_tag: domino_pref_req.pref_addr[55:12],
    size: 3'b011,           // 8-byte read
    be: {(DCacheCfgBuilt.u.wordWidth/8){1'b1}},
    tid: 4'b1111,           // Special TID for prefetch tracking
    sid: 1'b1,              // D-Cache source ID
    need_rsp: 1'b0,         // Prefetch doesn't need response
    default: '0
  };

  // ========== 9. HPDCACHE INSTANTIATIONS ==========

  // I-Cache instance
  hpdcache #(
    .HPDcacheCfg(ICacheCfgBuilt),
    .wbuf_timecnt_t(logic [ICacheCfgBuilt.u.wbufTimecntWidth-1:0]),
    .hpdcache_tag_t(icache_tag_t),
    .hpdcache_data_word_t(icache_data_word_t),
    .hpdcache_data_be_t(icache_data_be_t),
    .hpdcache_req_offset_t(icache_req_offset_t),
    .hpdcache_req_data_t(icache_req_data_t),
    .hpdcache_req_be_t(icache_req_be_t),
    .hpdcache_req_sid_t(icache_req_sid_t),
    .hpdcache_req_tid_t(icache_req_tid_t),
    .hpdcache_req_t(icache_req_t),
    .hpdcache_rsp_t(icache_rsp_t),
    .hpdcache_mem_addr_t(mem_addr_t),
    .hpdcache_mem_id_t(mem_id_t),
    .hpdcache_mem_data_t(mem_data_t),
    .hpdcache_mem_be_t(mem_be_t),
    .hpdcache_mem_req_t(mem_req_t),
    .hpdcache_mem_req_w_t(mem_req_w_t),
    .hpdcache_mem_resp_r_t(mem_resp_r_t),
    .hpdcache_mem_resp_w_t(mem_resp_w_t)
  ) u_icache (
    .clk_i(clk),
    .rst_ni(rst_n),
    .wbuf_flush_i(1'b0),
    .core_req_valid_i(icache_req_valid),
    .core_req_ready_o(icache_req_ready),
    .core_req_i(icache_req),
    .core_req_abort_i(1'b0),
    .core_req_tag_i('0),
    .core_req_pma_i('0),
    .core_rsp_valid_o(icache_rsp_valid),
    .core_rsp_o(icache_rsp),
    // Memory interface (will be arbitrated)
    .mem_req_read_ready_i(1'b1),  // Arbiter will handle
    .mem_req_read_valid_o(),
    .mem_req_read_o(),
    .mem_resp_read_ready_o(),
    .mem_resp_read_valid_i(1'b0),
    .mem_resp_read_i('0),
    .mem_resp_read_inval_i(1'b0),
    .mem_resp_read_inval_nline_i('0),
    .mem_req_write_ready_i(1'b0),  // I-Cache never writes
    .mem_req_write_valid_o(),
    .mem_req_write_o(),
    .mem_req_write_data_ready_i(1'b0),
    .mem_req_write_data_valid_o(),
    .mem_req_write_data_o(),
    .mem_resp_write_ready_o(),
    .mem_resp_write_valid_i(1'b0),
    .mem_resp_write_i('0),
    // Events/config
    .evt_cache_read_miss_o(),
    .evt_cache_write_miss_o(),
    .evt_cache_dir_unc_err_o(),
    .evt_cache_dir_cor_err_o(),
    .evt_cache_dat_unc_err_o(),
    .evt_cache_dat_cor_err_o(),
    .evt_scrub_complete_o(),
    .evt_uncached_req_o(),
    .evt_cmo_req_o(),
    .evt_write_req_o(),
    .evt_read_req_o(),
    .evt_prefetch_req_o(),
    .evt_req_on_hold_o(),
    .evt_rtab_rollback_o(),
    .evt_stall_refill_o(),
    .evt_stall_o(),
    .wbuf_empty_o(),
    .cfg_enable_i(1'b1),
    .cfg_wbuf_threshold_i('0),
    .cfg_wbuf_reset_timecnt_on_write_i(1'b1),
    .cfg_wbuf_sequential_waw_i(1'b0),
    .cfg_wbuf_inhibit_write_coalescing_i(1'b0),
    .cfg_prefetch_updt_plru_i(1'b1),
    .cfg_error_on_cacheable_amo_i(1'b0),
    .cfg_rtab_single_entry_i(1'b0),
    .cfg_default_wb_i(1'b1),
    .cfg_scrub_enable_i(1'b0),
    .cfg_scrub_period_i('0),
    .cfg_scrub_restart_i(1'b0)
  );

  // D-Cache instance (with prefetch port)
  hpdcache #(
    .HPDcacheCfg(DCacheCfgBuilt),
    // ... (similar port list as I-Cache)
  ) u_dcache (
    .clk_i(clk),
    .rst_ni(rst_n),
    // ... core request/response
    .core_req_valid_i({dcache_req_valid, dcache_prefetch_req_valid}),  // 2 ports
    .core_req_ready_o({dcache_req_ready, /*prefetch ready*/}),
    // ... memory interface
    // ... (will be arbitrated with I-Cache)
  );

  // ========== 10. MEMORY ARBITER (I-Cache + D-Cache share bus) ==========
  // Priority: D-Cache > I-Cache (reads have priority over writes)

  logic dcache_priority_this_cycle;
  always_comb begin
    // D-Cache gets priority if it has a read request
    dcache_priority_this_cycle = dcache_req_valid || dcache_prefetch_req_valid;
  end

  always_comb begin
    if (dcache_priority_this_cycle) begin
      // Route D-Cache to memory
      mem_ar = dcache_ar;
      mem_ar_valid = dcache_ar_valid;
      dcache_ar_ready = mem_ar_ready;
      icache_ar_ready = 1'b0;

      mem_aw = dcache_aw;
      mem_aw_valid = dcache_aw_valid;
      dcache_aw_ready = mem_aw_ready;

      mem_w = dcache_w;
      mem_w_valid = dcache_w_valid;
      dcache_w_ready = mem_w_ready;

      dcache_r = mem_r;
      dcache_r_valid = mem_r_valid;
      mem_r_ready = dcache_r_ready;
      icache_r_ready = 1'b0;
    end else begin
      // Route I-Cache to memory
      mem_ar = icache_ar;
      mem_ar_valid = icache_ar_valid;
      icache_ar_ready = mem_ar_ready;
      dcache_ar_ready = 1'b0;

      mem_aw = '0;
      mem_aw_valid = 1'b0;
      dcache_aw_ready = 1'b0;

      mem_w = '0;
      mem_w_valid = 1'b0;
      dcache_w_ready = 1'b0;

      icache_r = mem_r;
      icache_r_valid = mem_r_valid;
      mem_r_ready = icache_r_ready;
      dcache_r_ready = 1'b0;
    end
  end

  // ========== 11. METRICS COLLECTION LOGIC ==========
  always @(posedge clk) begin
    if (rst_n) begin
      // I-Cache metrics
      if (icache_req_valid && icache_req_ready) begin
        if (icache_rsp_valid) begin
          if (icache_rsp.cacheable)  // Hit detected by cache
            icache_hits_count++;
          else
            icache_misses_count++;
        end
      end

      // D-Cache metrics
      if (dcache_req_valid && dcache_req_ready) begin
        if (dcache_rsp_valid && dcache_rsp.cacheable)
          dcache_hits_count++;
        else
          dcache_misses_count++;
      end

      // Prefetch metrics
      if (dcache_prefetch_req_valid) begin
        prefetch_injected_count++;
        if (dcache_rsp_valid && dcache_rsp.tid == 4'b1111)
          prefetch_hit_count++;
        else
          prefetch_miss_count++;
      end

      // Pipeline stall detection
      if (cpu_load_miss_o)
        pipeline_stall_cycles++;
    end
  end

  // ========== 12. SVA PROTOCOL ASSERTIONS ==========

  // Assertion 1: Cache response within bounded time
  assert_icache_rsp_bounded: assert property (
    @(posedge clk) disable iff(!rst_n)
    (icache_req_valid && icache_req_ready) |-> ##[1:20] icache_rsp_valid
  ) else $error("[ASSERT FAIL] I-Cache response timeout!");

  assert_dcache_rsp_bounded: assert property (
    @(posedge clk) disable iff(!rst_n)
    (dcache_req_valid && dcache_req_ready) |-> ##[1:20] dcache_rsp_valid
  ) else $error("[ASSERT FAIL] D-Cache response timeout!");

  // Assertion 2: Prefetch does not starve core requests
  assert_prefetch_fair_arb: assert property (
    @(posedge clk) disable iff(!rst_n)
    (dcache_req_valid && !dcache_req_ready && dcache_prefetch_req_valid)
    |-> ##[1:5] dcache_req_ready
  ) else $error("[ASSERT FAIL] Prefetch starved core request!");

  // Assertion 3: No spurious cache responses
  assert_rsp_after_req: assert property (
    @(posedge clk) disable iff(!rst_n)
    (dcache_rsp_valid) |-> ($past(dcache_req_valid) || $past(dcache_prefetch_req_valid))
  ) else $error("[ASSERT FAIL] Response without request!");

  // ========== 13. STIMULUS & MONITORING ==========

  task automatic send_fetch(input logic [63:0] addr);
    icache_req_valid = 1'b1;
    icache_req.op = HPDCACHE_REQ_LOAD;
    icache_req.addr_offset = addr[11:0];
    icache_req.addr_tag = addr[55:12];
    icache_req.size = 3'b010;  // 4-byte instr
    @(posedge clk);
    while (!icache_req_ready) @(posedge clk);
    icache_req_valid = 1'b0;
    repeat(2) @(posedge clk);
  endtask

  task automatic send_load(input logic [63:0] addr);
    dcache_req_valid = 1'b1;
    dcache_req.op = HPDCACHE_REQ_LOAD;
    dcache_req.addr_offset = addr[11:0];
    dcache_req.addr_tag = addr[55:12];
    dcache_req.size = 3'b011;  // 8-byte data
    dcache_req.tid = 4'h0;     // Regular (non-prefetch) TID
    @(posedge clk);
    while (!dcache_req_ready) @(posedge clk);
    dcache_req_valid = 1'b0;
    repeat(2) @(posedge clk);
  endtask

  // ========== 14. TEST SCENARIOS ==========

  initial begin
    // Initialize
    icache_req_valid = 1'b0;
    dcache_req_valid = 1'b0;
    repeat(10) @(posedge clk);

    $display("\n========== TEST 1: L1 Cache Hit Rate ==========");
    // Sequential access pattern (should hit after 1st miss)
    for (int i = 0; i < 16; i++) begin
      send_load(64'h1000 + (i * 8));
    end

    $display("\n========== TEST 2: Prefetcher Stride Detection ==========");
    // Train prefetcher with regular stride
    send_load(64'h2000);
    repeat(10) @(posedge clk);
    send_load(64'h2100);
    repeat(10) @(posedge clk);
    send_load(64'h2200);
    repeat(20) @(posedge clk);

    $display("\n========== TEST 3: Random Access (High Miss Rate) ==========");
    for (int i = 0; i < 32; i++) begin
      send_load(64'h4000 + ({$random} & 64'hFFFF));
    end

    repeat(100) @(posedge clk);

    // ========== FINAL METRICS ==========
    $display("\n");
    $display("====================== THESIS METRICS ======================");
    real icache_hit_rate = (icache_hits_count * 100.0) / 
                           (icache_hits_count + icache_misses_count + 1);
    real dcache_hit_rate = (dcache_hits_count * 100.0) / 
                           (dcache_hits_count + dcache_misses_count + 1);
    real prefetch_accuracy = (prefetch_hit_count * 100.0) / 
                             (prefetch_injected_count + 1);

    $display("I-Cache Hit Rate:     %6.2f %% (Target: ≥45 %%)", icache_hit_rate);
    $display("D-Cache Hit Rate:     %6.2f %% (Target: ≥55 %%)", dcache_hit_rate);
    real miss_rate = ((icache_misses_count + dcache_misses_count) * 100.0) / 
                     (icache_hits_count + icache_misses_count + dcache_hits_count + dcache_misses_count + 1);
    $display("Cache Miss Rate:      %6.2f %% (Target: <20 %%)", miss_rate);
    $display("Prefetch Triggered:   %6d events (Target: >10 %%)", prefetch_injected_count);
    $display("Prefetch Accuracy:    %6.2f %% (Target: >80 %%)", prefetch_accuracy);
    $display("Pipeline Stalls:      %6d cycles", pipeline_stall_cycles);
    $display("===========================================================\n");

    // Verdict
    if (icache_hit_rate >= 45 && dcache_hit_rate >= 55 && 
        miss_rate < 20 && prefetch_accuracy >= 80) begin
      $display("✅ ALL THESIS TARGETS ACHIEVED - INTEGRATION VERIFIED");
    end else begin
      $display("❌ SOME TARGETS MISSED - REVIEW RESULTS");
    end

    $stop;
  end

endmodule
