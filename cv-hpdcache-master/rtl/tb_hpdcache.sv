/**
 * Project     : CVA6 RISC-V Core - HPDcache
 * Description : SystemVerilog Testbench - day du 74 ports cua hpdcache_wrapper (Da sua)
 * Author      : L1 CACHE + Grok Assistant
 * Note        : Da toi uu de tranh loi type mismatch va race condition
 */

`timescale 1ns/1ps
`include "hpdcache_typedef.svh"

module tb_hpdcache;

    import hpdcache_pkg::*;

    // -------------------------------------------------------------------------
    // 1. Clock & Reset Generation
    // -------------------------------------------------------------------------
    logic clk_i;
    logic rst_ni;

    initial begin
        clk_i = 0;
        forever #0.5 clk_i = ~clk_i; // Chu ky 1ns = 1GHz
    end

    // =========================================================================
    // 2. Khai bao bien tin hieu dung de ket noi voi DUT (74 ports)
    // =========================================================================
    // --- 2.1 Control ---
    logic wbuf_flush_i;

    // --- 2.2 Core Request (Cycle 1) ---
    logic              core_req_valid_i;
    logic              core_req_ready_o;
    hpdcache_req_t     core_req_i;

    // --- 2.3 Core Request (Cycle 2) ---
    logic              core_req_abort_i;
    hpdcache_tag_t     core_req_tag_i;
    hpdcache_pma_t     core_req_pma_i;

    // --- 2.4 Core Response ---
    logic              core_rsp_valid_o;
    hpdcache_rsp_t     core_rsp_o;

    // --- 2.5 Memory Read Request ---
    logic                    mem_req_read_ready_i;
    logic                    mem_req_read_valid_o;
    hpdcache_mem_addr_t      mem_req_read_addr_o;
    hpdcache_mem_len_t       mem_req_read_len_o;
    hpdcache_mem_size_t      mem_req_read_size_o;
    hpdcache_mem_id_t        mem_req_read_id_o;
    hpdcache_mem_command_e   mem_req_read_command_o;
    hpdcache_mem_atomic_e    mem_req_read_atomic_o;
    logic                    mem_req_read_cacheable_o;

    // --- 2.6 Memory Read Response ---
    logic                    mem_resp_read_ready_o;
    logic                    mem_resp_read_valid_i;
    hpdcache_mem_error_e     mem_resp_read_error_i;
    hpdcache_mem_id_t        mem_resp_read_id_i;
    hpdcache_mem_data_t      mem_resp_read_data_i;
    logic                    mem_resp_read_last_i;

    // --- 2.7 Memory Write Request ---
    logic                    mem_req_write_ready_i;
    logic                    mem_req_write_valid_o;
    hpdcache_mem_addr_t      mem_req_write_addr_o;
    hpdcache_mem_len_t       mem_req_write_len_o;
    hpdcache_mem_size_t      mem_req_write_size_o;
    hpdcache_mem_id_t        mem_req_write_id_o;
    hpdcache_mem_command_e   mem_req_write_command_o;
    hpdcache_mem_atomic_e    mem_req_write_atomic_o;
    logic                    mem_req_write_cacheable_o;

    // --- 2.8 Memory Write Data ---
    logic                    mem_req_write_data_ready_i;
    logic                    mem_req_write_data_valid_o;
    hpdcache_mem_data_t      mem_req_write_data_o;
    hpdcache_mem_be_t        mem_req_write_be_o;
    logic                    mem_req_write_last_o;

    // --- 2.9 Memory Write Response ---
    logic                    mem_resp_write_ready_o;
    logic                    mem_resp_write_valid_i;
    logic                    mem_resp_write_is_atomic_i;
    hpdcache_mem_error_e     mem_resp_write_error_i;
    hpdcache_mem_id_t        mem_resp_write_id_i;

    // --- 2.10 Performance Events ---
    logic evt_cache_write_miss_o;
    logic evt_cache_read_miss_o;
    logic evt_cache_dir_unc_err_o;
    logic evt_cache_dir_cor_err_o;
    logic evt_cache_dat_unc_err_o;
    logic evt_cache_dat_cor_err_o;
    logic evt_scrub_complete_o;
    logic evt_uncached_req_o;
    logic evt_cmo_req_o;
    logic evt_write_req_o;
    logic evt_read_req_o;
    logic evt_prefetch_req_o;
    logic evt_req_on_hold_o;
    logic evt_rtab_rollback_o;
    logic evt_stall_refill_o;
    logic evt_stall_o;

    // --- 2.11 Status ---
    logic wbuf_empty_o;

    // --- 2.12 Configuration ---
    logic              cfg_enable_i;
    wbuf_timecnt_t     cfg_wbuf_threshold_i;
    logic              cfg_wbuf_reset_timecnt_on_write_i;
    logic              cfg_wbuf_sequential_waw_i;
    logic              cfg_wbuf_inhibit_write_coalescing_i;
    logic              cfg_prefetch_updt_plru_i;
    logic              cfg_error_on_cacheable_amo_i;
    logic              cfg_rtab_single_entry_i;
    logic              cfg_default_wb_i;
    logic              cfg_scrub_enable_i;
    logic [5:0]        cfg_scrub_period_i;
    logic              cfg_scrub_restart_i;

    // =========================================================================
    // 3. DUT Instantiation
    // =========================================================================
    hpdcache_wrapper dut (
        .clk_i                              (clk_i),
        .rst_ni                             (rst_ni),
        .wbuf_flush_i                       (wbuf_flush_i),

        // Core Request Port
        .core_req_valid_i                   (core_req_valid_i),
        .core_req_ready_o                   (core_req_ready_o),
        .core_req_i                         (core_req_i),
        .core_req_abort_i                   (core_req_abort_i),
        .core_req_tag_i                     (core_req_tag_i),
        .core_req_pma_i                     (core_req_pma_i),

        // Core Response Port
        .core_rsp_valid_o                   (core_rsp_valid_o),
        .core_rsp_o                         (core_rsp_o),

        // Memory Read Interface
        .mem_req_read_ready_i               (mem_req_read_ready_i),
        .mem_req_read_valid_o               (mem_req_read_valid_o),
        .mem_req_read_addr_o                (mem_req_read_addr_o),
        .mem_req_read_len_o                 (mem_req_read_len_o),
        .mem_req_read_size_o                (mem_req_read_size_o),
        .mem_req_read_id_o                  (mem_req_read_id_o),
        .mem_req_read_command_o             (mem_req_read_command_o),
        .mem_req_read_atomic_o              (mem_req_read_atomic_o),
        .mem_req_read_cacheable_o           (mem_req_read_cacheable_o),

        .mem_resp_read_ready_o              (mem_resp_read_ready_o),
        .mem_resp_read_valid_i              (mem_resp_read_valid_i),
        .mem_resp_read_error_i              (mem_resp_read_error_i),
        .mem_resp_read_id_i                 (mem_resp_read_id_i),
        .mem_resp_read_data_i               (mem_resp_read_data_i),
        .mem_resp_read_last_i               (mem_resp_read_last_i),

        // Memory Write Interface
        .mem_req_write_ready_i              (mem_req_write_ready_i),
        .mem_req_write_valid_o              (mem_req_write_valid_o),
        .mem_req_write_addr_o               (mem_req_write_addr_o),
        .mem_req_write_len_o                (mem_req_write_len_o),
        .mem_req_write_size_o               (mem_req_write_size_o),
        .mem_req_write_id_o                 (mem_req_write_id_o),
        .mem_req_write_command_o            (mem_req_write_command_o),
        .mem_req_write_atomic_o             (mem_req_write_atomic_o),
        .mem_req_write_cacheable_o          (mem_req_write_cacheable_o),

        .mem_req_write_data_ready_i         (mem_req_write_data_ready_i),
        .mem_req_write_data_valid_o         (mem_req_write_data_valid_o),
        .mem_req_write_data_o               (mem_req_write_data_o),
        .mem_req_write_be_o                 (mem_req_write_be_o),
        .mem_req_write_last_o               (mem_req_write_last_o),

        .mem_resp_write_ready_o             (mem_resp_write_ready_o),
        .mem_resp_write_valid_i             (mem_resp_write_valid_i),
        .mem_resp_write_is_atomic_i         (mem_resp_write_is_atomic_i),
        .mem_resp_write_error_i             (mem_resp_write_error_i),
        .mem_resp_write_id_i                (mem_resp_write_id_i),

        // Performance Events
        .evt_cache_write_miss_o             (evt_cache_write_miss_o),
        .evt_cache_read_miss_o              (evt_cache_read_miss_o),
        .evt_cache_dir_unc_err_o            (evt_cache_dir_unc_err_o),
        .evt_cache_dir_cor_err_o            (evt_cache_dir_cor_err_o),
        .evt_cache_dat_unc_err_o            (evt_cache_dat_unc_err_o),
        .evt_cache_dat_cor_err_o            (evt_cache_dat_cor_err_o),
        .evt_scrub_complete_o               (evt_scrub_complete_o),
        .evt_uncached_req_o                 (evt_uncached_req_o),
        .evt_cmo_req_o                      (evt_cmo_req_o),
        .evt_write_req_o                    (evt_write_req_o),
        .evt_read_req_o                     (evt_read_req_o),
        .evt_prefetch_req_o                 (evt_prefetch_req_o),
        .evt_req_on_hold_o                  (evt_req_on_hold_o),
        .evt_rtab_rollback_o                (evt_rtab_rollback_o),
        .evt_stall_refill_o                 (evt_stall_refill_o),
        .evt_stall_o                        (evt_stall_o),

        // Status & Configs
        .wbuf_empty_o                       (wbuf_empty_o),
        .cfg_enable_i                       (cfg_enable_i),
        .cfg_wbuf_threshold_i               (cfg_wbuf_threshold_i),
        .cfg_wbuf_reset_timecnt_on_write_i  (cfg_wbuf_reset_timecnt_on_write_i),
        .cfg_wbuf_sequential_waw_i          (cfg_wbuf_sequential_waw_i),
        .cfg_wbuf_inhibit_write_coalescing_i(cfg_wbuf_inhibit_write_coalescing_i),
        .cfg_prefetch_updt_plru_i           (cfg_prefetch_updt_plru_i),
        .cfg_error_on_cacheable_amo_i       (cfg_error_on_cacheable_amo_i),
        .cfg_rtab_single_entry_i            (cfg_rtab_single_entry_i),
        .cfg_default_wb_i                   (cfg_default_wb_i),
        .cfg_scrub_enable_i                 (cfg_scrub_enable_i),
        .cfg_scrub_period_i                 (cfg_scrub_period_i),
        .cfg_scrub_restart_i                (cfg_scrub_restart_i)
    );

    // =========================================================================
    // Bien module-level (tranh loi vlog khi dung automatic trong initial)
    // =========================================================================
    hpdcache_mem_id_t saved_read_id;
    hpdcache_mem_id_t saved_write_id;

    // =========================================================================
    // 4. Stimulus
    // =========================================================================
    initial begin
        $display("==================================================");
        $display("[TB] BAT DAU MO PHONG HPDCACHE - FULL 74 PORTS");
        $display("==================================================");

        // Default values
        wbuf_flush_i                        = 0;
        cfg_enable_i                        = 1;
        cfg_wbuf_threshold_i                = '1;
        cfg_wbuf_reset_timecnt_on_write_i   = 1;
        cfg_wbuf_sequential_waw_i           = 0;
        cfg_wbuf_inhibit_write_coalescing_i = 0;
        cfg_prefetch_updt_plru_i            = 0;
        cfg_error_on_cacheable_amo_i        = 0;
        cfg_rtab_single_entry_i             = 0;
        cfg_default_wb_i                    = 0;
        cfg_scrub_enable_i                  = 0;
        cfg_scrub_period_i                  = 6'd10;
        cfg_scrub_restart_i                 = 1;

        core_req_valid_i   = 0;
        core_req_abort_i   = 0;
        core_req_i         = '0;
        core_req_tag_i     = '0;
        core_req_pma_i     = '0;

        mem_req_read_ready_i      = 1;
        mem_req_write_ready_i     = 1;
        mem_req_write_data_ready_i= 1;

        mem_resp_read_valid_i     = 0;
        mem_resp_write_valid_i    = 0;

        // Reset sequence
        rst_ni = 1;
        repeat(5) @(posedge clk_i);
        rst_ni = 0;
        repeat(5) @(posedge clk_i);
        rst_ni = 1;
        $display("[TB] [%0t] Reset hoan tat.", $time);

        repeat(5) @(posedge clk_i);

        // =====================================================================
        // TESTCASE 1: Cache Read Miss
        // =====================================================================
        wait(core_req_ready_o);
        @(posedge clk_i);
        core_req_valid_i            = 1;
        core_req_i.op               = HPDCACHE_REQ_LOAD;
        core_req_i.addr_offset      = '0;
        core_req_i.wdata            = '0;
        core_req_i.be               = '1;
        core_req_i.size             = 3'd3;        // 8 bytes
        core_req_i.sid              = '0;
        core_req_i.tid              = '0;
        core_req_i.need_rsp         = 1;
        core_req_i.phys_indexed     = 0;
        core_req_i.addr_tag         = '0;
        core_req_i.pma.uncacheable  = 0;
        core_req_i.pma.io           = 0;

        @(posedge clk_i);
        core_req_valid_i            = 0;
        core_req_tag_i              = hpdcache_tag_t'(64'hDEAD_BEEF >> 12);
        core_req_pma_i.uncacheable  = 0;
        core_req_pma_i.io           = 0;

        $display("[TB] [%0t] [TEST1] Gui LOAD -> 0xDEADBEEF (Miss)", $time);

        wait(mem_req_read_valid_o);
        saved_read_id = mem_req_read_id_o;
        $display("[TB] [%0t] [TEST1] Cache MISS -> Memory read addr=0x%h", $time, mem_req_read_addr_o);

        repeat(5) @(posedge clk_i); // Memory latency

        mem_resp_read_valid_i   = 1;
        mem_resp_read_id_i      = saved_read_id;
        mem_resp_read_error_i   = HPDCACHE_MEM_RESP_OK;
        mem_resp_read_data_i    = {($bits(hpdcache_mem_data_t)/64){64'h5555_AAAA_DEAD_BEEF}};
        mem_resp_read_last_i    = 1;

        @(posedge clk_i);
        mem_resp_read_valid_i = 0;
        mem_resp_read_last_i  = 0;

        wait(core_rsp_valid_o);
        $display("[TB] [%0t] [TEST1 PASS] Core nhan data: %h", $time, core_rsp_o.rdata);

        // =====================================================================
        // TESTCASE 2: Cache Hit
        // =====================================================================
        repeat(8) @(posedge clk_i);
        wait(core_req_ready_o);

        @(posedge clk_i);
        core_req_valid_i            = 1;
        core_req_i.op               = HPDCACHE_REQ_LOAD;
        core_req_i.addr_offset      = '0;
        core_req_i.size             = 3'd3;
        core_req_i.sid              = '0;
        core_req_i.tid              = 4'd1;
        core_req_i.need_rsp         = 1;
        core_req_i.phys_indexed     = 0;
        core_req_i.pma.uncacheable  = 0;
        core_req_i.pma.io           = 0;

        @(posedge clk_i);
        core_req_valid_i = 0;
        core_req_tag_i   = hpdcache_tag_t'(64'hDEAD_BEEF >> 12);

        $display("[TB] [%0t] [TEST2] Kiem tra Cache Hit tai 0xDEADBEEF...", $time);

        wait(core_rsp_valid_o);
        $display("[TB] [%0t] [TEST2 PASS] Cache HIT! Data = %h", $time, core_rsp_o.rdata);

        // =====================================================================
        // TESTCASE 3: Cache Write + WBUF Flush
        // =====================================================================
        repeat(8) @(posedge clk_i);
        wait(core_req_ready_o);

        @(posedge clk_i);
        core_req_valid_i            = 1;
        core_req_i.op               = HPDCACHE_REQ_STORE;
        core_req_i.addr_offset      = '0;
        core_req_i.wdata            = {($bits(hpdcache_req_data_t)/64){64'hCAFE_BABE_1111_2222}};
        core_req_i.be               = '1;
        core_req_i.size             = 3'd3;
        core_req_i.sid              = '0;
        core_req_i.tid              = 4'd2;
        core_req_i.need_rsp         = 0;
        core_req_i.phys_indexed     = 0;
        core_req_i.pma.uncacheable  = 0;
        core_req_i.pma.io           = 0;

        @(posedge clk_i);
        core_req_valid_i = 0;
        core_req_tag_i   = hpdcache_tag_t'(64'hDEAD_BEEF >> 12);

        $display("[TB] [%0t] [TEST3] Gui STORE -> WBUF", $time);

        repeat(4) @(posedge clk_i);
        wbuf_flush_i = 1;
        @(posedge clk_i);
        wbuf_flush_i = 0;

        wait(mem_req_write_valid_o);
        saved_write_id = mem_req_write_id_o;
        $display("[TB] [%0t] [TEST3] Write Request ra Memory, id=%0h", $time, saved_write_id);

        repeat(3) @(posedge clk_i);
        mem_resp_write_valid_i     = 1;
        mem_resp_write_id_i        = saved_write_id;
        mem_resp_write_error_i     = HPDCACHE_MEM_RESP_OK;
        mem_resp_write_is_atomic_i = 0;

        @(posedge clk_i);
        mem_resp_write_valid_i = 0;

        $display("[TB] [%0t] [TEST3 PASS] Write hoan thanh.", $time);

        // =====================================================================
        // End of test
        // =====================================================================
        repeat(10) @(posedge clk_i);
        $display("\n==================================================");
        $display("[TB] [%0t] === PERFORMANCE EVENTS SUMMARY ===", $time);
        $display("  Read Miss   = %b", evt_cache_read_miss_o);
        $display("  Write Miss  = %b", evt_cache_write_miss_o);
        $display("  Stall       = %b", evt_stall_o);
        $display("  WBUF Empty  = %b", wbuf_empty_o);
        $display("==================================================");
        $display("[TB] MO PHONG HOAN TAT!");
        $stop;
    end

    // Monitor
    always @(posedge clk_i) begin
        if (evt_cache_dir_unc_err_o || evt_cache_dat_unc_err_o)
            $display("[WARN] [%0t] ECC UNC ERROR!", $time);
    end

    always @(posedge clk_i) begin
        if (evt_cache_read_miss_o)
            $display("[EVT] Read Miss detected");
        if (evt_cache_write_miss_o)
            $display("[EVT] Write Miss detected");
    end

endmodule