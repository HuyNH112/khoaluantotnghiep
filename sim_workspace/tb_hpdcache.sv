`timescale 1ns/1ps
`include "hpdcache_config.svh"
`include "hpdcache_typedef.svh"

module tb_hpdcache;
    import hpdcache_pkg::*;

    localparam hpdcache_user_cfg_t UserCfg = '{
        nRequesters:                    (4'b1 << `CONF_HPDCACHE_REQ_SRC_ID_WIDTH),
        paWidth:                        `CONF_HPDCACHE_PA_WIDTH,
        wordWidth:                      `CONF_HPDCACHE_WORD_WIDTH,
        sets:                           `CONF_HPDCACHE_SETS,
        ways:                           `CONF_HPDCACHE_WAYS,
        clWords:                        `CONF_HPDCACHE_CL_WORDS,
        reqWords:                       `CONF_HPDCACHE_REQ_WORDS,
        reqTransIdWidth:                `CONF_HPDCACHE_REQ_TRANS_ID_WIDTH,
        reqSrcIdWidth:                  `CONF_HPDCACHE_REQ_SRC_ID_WIDTH,
        victimSel:                      `CONF_HPDCACHE_VICTIM_SEL,
        dataWaysPerRamWord:             `CONF_HPDCACHE_DATA_WAYS_PER_RAM_WORD,
        dataSetsPerRam:                 `CONF_HPDCACHE_DATA_SETS_PER_RAM,
        dataRamByteEnable:              `CONF_HPDCACHE_DATA_RAM_WBYTEENABLE,
        accessWords:                    `CONF_HPDCACHE_ACCESS_WORDS,
        mshrSets:                       `CONF_HPDCACHE_MSHR_SETS,
        mshrWays:                       `CONF_HPDCACHE_MSHR_WAYS,
        mshrWaysPerRamWord:             `CONF_HPDCACHE_MSHR_WAYS_PER_RAM_WORD,
        mshrSetsPerRam:                 `CONF_HPDCACHE_MSHR_SETS_PER_RAM,
        mshrRamByteEnable:              `CONF_HPDCACHE_MSHR_RAM_WBYTEENABLE,
        mshrUseRegbank:                 `CONF_HPDCACHE_MSHR_USE_REGBANK,
        cbufEntries:                    `CONF_HPDCACHE_CBUF_ENTRIES,
        refillCoreRspFeedthrough:       `CONF_HPDCACHE_REFILL_CORE_RSP_FEEDTHROUGH,
        refillFifoDepth:                `CONF_HPDCACHE_REFILL_FIFO_DEPTH,
        wbufDirEntries:                 `CONF_HPDCACHE_WBUF_DIR_ENTRIES,
        wbufDataEntries:                `CONF_HPDCACHE_WBUF_DATA_ENTRIES,
        wbufWords:                      `CONF_HPDCACHE_WBUF_WORDS,
        wbufTimecntWidth:               `CONF_HPDCACHE_WBUF_TIMECNT_WIDTH,
        rtabEntries:                    `CONF_HPDCACHE_RTAB_ENTRIES,
        flushEntries:                   `CONF_HPDCACHE_FLUSH_ENTRIES,
        flushFifoDepth:                 `CONF_HPDCACHE_FLUSH_FIFO_DEPTH,
        memAddrWidth:                   `CONF_HPDCACHE_MEM_ADDR_WIDTH,
        memIdWidth:                     `CONF_HPDCACHE_MEM_ID_WIDTH,
        memDataWidth:                   `CONF_HPDCACHE_MEM_DATA_WIDTH,
        wtEn:                           `CONF_HPDCACHE_WT_ENABLE,
        wbEn:                           `CONF_HPDCACHE_WB_ENABLE,
        lowLatency:                     `CONF_HPDCACHE_LOW_LATENCY,
        eccEn:                          `CONF_HPDCACHE_ECC_ENABLE,
        eccScrubberEn:                  `CONF_HPDCACHE_ECC_SCRUBBER_ENABLE
    };

    localparam hpdcache_cfg_t Cfg = hpdcacheBuildConfig(UserCfg);

    localparam int unsigned CL_WORDS    = `CONF_HPDCACHE_CL_WORDS;
    localparam int unsigned TIMEOUT_CYC = 2000;

    typedef logic unsigned [Cfg.u.wbufTimecntWidth-1:0] wbuf_timecnt_t;
    typedef logic [Cfg.tagWidth-1:0]                    hpdcache_tag_t;
    typedef logic [Cfg.u.wordWidth-1:0]                 hpdcache_data_word_t;
    typedef logic [Cfg.u.wordWidth/8-1:0]               hpdcache_data_be_t;
    typedef logic [Cfg.reqOffsetWidth-1:0]              hpdcache_req_offset_t;
    typedef logic [Cfg.u.reqWords-1:0][Cfg.u.wordWidth-1:0]     hpdcache_req_data_t;
    typedef logic [Cfg.u.reqWords-1:0][Cfg.u.wordWidth/8-1:0]   hpdcache_req_be_t;
    typedef logic [Cfg.u.reqSrcIdWidth-1:0]             hpdcache_req_sid_t;
    typedef logic [Cfg.u.reqTransIdWidth-1:0]           hpdcache_req_tid_t;

    typedef `HPDCACHE_DECL_REQ_T(
        hpdcache_req_offset_t,
        hpdcache_req_data_t,
        hpdcache_req_be_t,
        hpdcache_req_sid_t,
        hpdcache_req_tid_t,
        hpdcache_tag_t
    ) hpdcache_req_t;

    typedef `HPDCACHE_DECL_RSP_T(
        hpdcache_req_data_t,
        hpdcache_req_sid_t,
        hpdcache_req_tid_t
    ) hpdcache_rsp_t;

    typedef logic [Cfg.u.memAddrWidth-1:0]   hpdcache_mem_addr_t;
    typedef logic [Cfg.u.memIdWidth-1:0]     hpdcache_mem_id_t;
    typedef logic [Cfg.u.memDataWidth-1:0]   hpdcache_mem_data_t;
    typedef logic [Cfg.u.memDataWidth/8-1:0] hpdcache_mem_be_t;
    typedef logic [Cfg.nlineWidth-1:0]       hpdcache_nline_t;

    logic clk_i;
    logic rst_ni;

    initial begin
        clk_i = 0;
        forever #0.5 clk_i = ~clk_i;
    end

    logic              wbuf_flush_i;
    logic              core_req_valid_i;
    logic              core_req_ready_o;
    hpdcache_req_t     core_req_i;
    logic              core_req_abort_i;
    hpdcache_tag_t     core_req_tag_i;
    hpdcache_pma_t     core_req_pma_i;
    logic              core_rsp_valid_o;
    hpdcache_rsp_t     core_rsp_o;

    logic                    mem_req_read_ready_i;
    logic                    mem_req_read_valid_o;
    hpdcache_mem_addr_t      mem_req_read_addr_o;
    hpdcache_mem_len_t       mem_req_read_len_o;
    hpdcache_mem_size_t      mem_req_read_size_o;
    hpdcache_mem_id_t        mem_req_read_id_o;
    hpdcache_mem_command_e   mem_req_read_command_o;
    hpdcache_mem_atomic_e    mem_req_read_atomic_o;
    logic                    mem_req_read_cacheable_o;

    logic                    mem_resp_read_ready_o;
    logic                    mem_resp_read_valid_i;
    hpdcache_mem_error_e     mem_resp_read_error_i;
    hpdcache_mem_id_t        mem_resp_read_id_i;
    hpdcache_mem_data_t      mem_resp_read_data_i;
    logic                    mem_resp_read_last_i;

    logic                    mem_req_write_ready_i;
    logic                    mem_req_write_valid_o;
    hpdcache_mem_addr_t      mem_req_write_addr_o;
    hpdcache_mem_len_t       mem_req_write_len_o;
    hpdcache_mem_size_t      mem_req_write_size_o;
    hpdcache_mem_id_t        mem_req_write_id_o;
    hpdcache_mem_command_e   mem_req_write_command_o;
    hpdcache_mem_atomic_e    mem_req_write_atomic_o;
    logic                    mem_req_write_cacheable_o;

    logic                    mem_req_write_data_ready_i;
    logic                    mem_req_write_data_valid_o;
    hpdcache_mem_data_t      mem_req_write_data_o;
    hpdcache_mem_be_t        mem_req_write_be_o;
    logic                    mem_req_write_last_o;

    logic                    mem_resp_write_ready_o;
    logic                    mem_resp_write_valid_i;
    logic                    mem_resp_write_is_atomic_i;
    hpdcache_mem_error_e     mem_resp_write_error_i;
    hpdcache_mem_id_t        mem_resp_write_id_i;

    logic evt_cache_write_miss_o, evt_cache_read_miss_o;
    logic evt_cache_dir_unc_err_o, evt_cache_dir_cor_err_o;
    logic evt_cache_dat_unc_err_o, evt_cache_dat_cor_err_o;
    logic evt_scrub_complete_o, evt_uncached_req_o, evt_cmo_req_o;
    logic evt_write_req_o, evt_read_req_o, evt_prefetch_req_o;
    logic evt_req_on_hold_o, evt_rtab_rollback_o, evt_stall_refill_o, evt_stall_o;
    logic wbuf_empty_o;

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

    hpdcache_wrapper dut (.*);

    hpdcache_mem_id_t saved_read_id;
    hpdcache_mem_id_t saved_write_id;

    int unsigned timeout_cnt;

    task automatic reset_signals();
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

        core_req_valid_i    = 0;
        core_req_abort_i    = 0;
        core_req_i          = '0;
        core_req_tag_i      = '0;
        core_req_pma_i      = '0;

        mem_req_read_ready_i        = 1;
        mem_req_write_ready_i       = 1;
        mem_req_write_data_ready_i  = 1;
        mem_resp_read_valid_i       = 0;
        mem_resp_read_error_i       = HPDCACHE_MEM_RESP_OK;
        mem_resp_read_id_i          = '0;
        mem_resp_read_data_i        = '0;
        mem_resp_read_last_i        = 0;
        mem_resp_write_valid_i      = 0;
        mem_resp_write_is_atomic_i  = 0;
        mem_resp_write_error_i      = HPDCACHE_MEM_RESP_OK;
        mem_resp_write_id_i         = '0;
    endtask

    task automatic do_reset();
        rst_ni = 0;
        repeat(10) @(posedge clk_i);
        rst_ni = 1;
        repeat(5)  @(posedge clk_i);
    endtask

    task automatic send_req(
        input hpdcache_req_op_t   op,
        input hpdcache_req_offset_t addr_offset,
        input hpdcache_tag_t      tag,
        input hpdcache_req_data_t wdata,
        input hpdcache_req_be_t   be,
        input logic [2:0]         size,
        input logic               need_rsp,
        input logic               phys_indexed,
        input logic               uncacheable,
        input hpdcache_req_sid_t  sid,
        input hpdcache_req_tid_t  tid
    );
        @(posedge clk_i);
        core_req_valid_i            = 1;
        core_req_i.op               = op;
        core_req_i.addr_offset      = addr_offset;
        core_req_i.wdata            = wdata;
        core_req_i.be               = be;
        core_req_i.size             = size;
        core_req_i.need_rsp         = need_rsp;
        core_req_i.phys_indexed     = phys_indexed;
        core_req_i.pma.uncacheable  = uncacheable;
        core_req_i.sid              = sid;
        core_req_i.tid              = tid;
        core_req_pma_i.uncacheable  = uncacheable;

        timeout_cnt = 0;
        while (!core_req_ready_o) begin
            @(posedge clk_i);
            timeout_cnt++;
            if (timeout_cnt >= TIMEOUT_CYC)
                $fatal(1, "[TIMEOUT] core_req_ready_o khong len sau %0d cycle", TIMEOUT_CYC);
        end
        @(posedge clk_i);
        core_req_valid_i    = 0;
        core_req_tag_i      = tag;
        core_req_pma_i      = '0;
        core_req_i          = '0;
    endtask

    task automatic do_read_refill(input int unsigned n_beats);
        timeout_cnt = 0;
        while (!mem_req_read_valid_o) begin
            @(posedge clk_i);
            timeout_cnt++;
            if (timeout_cnt >= TIMEOUT_CYC)
                $fatal(1, "[TIMEOUT] mem_req_read_valid_o khong len");
        end
        saved_read_id = mem_req_read_id_o;
        repeat(3) @(posedge clk_i);

        for (int i = 0; i < n_beats; i++) begin
            mem_resp_read_valid_i   = 1;
            mem_resp_read_id_i      = saved_read_id;
            mem_resp_read_error_i   = HPDCACHE_MEM_RESP_OK;
            mem_resp_read_data_i    = {($bits(hpdcache_mem_data_t)/64){64'h5555_AAAA_0000_0000 + 64'(i)}};
            mem_resp_read_last_i    = (i == n_beats - 1) ? 1'b1 : 1'b0;
            @(posedge clk_i);
        end
        mem_resp_read_valid_i   = 0;
        mem_resp_read_last_i    = 0;
    endtask

    task automatic do_write_resp();
        timeout_cnt = 0;
        while (!mem_req_write_valid_o) begin
            @(posedge clk_i);
            timeout_cnt++;
            if (timeout_cnt >= TIMEOUT_CYC)
                $fatal(1, "[TIMEOUT] mem_req_write_valid_o khong len");
        end
        saved_write_id = mem_req_write_id_o;
        repeat(3) @(posedge clk_i);
        mem_resp_write_valid_i      = 1;
        mem_resp_write_id_i         = saved_write_id;
        mem_resp_write_error_i      = HPDCACHE_MEM_RESP_OK;
        mem_resp_write_is_atomic_i  = 0;
        @(posedge clk_i);
        mem_resp_write_valid_i = 0;
    endtask

    task automatic wait_rsp(input string test_name);
        timeout_cnt = 0;
        while (!core_rsp_valid_o) begin
            @(posedge clk_i);
            timeout_cnt++;
            if (timeout_cnt >= TIMEOUT_CYC)
                $fatal(1, "[TIMEOUT] %s: core_rsp_valid_o khong len", test_name);
        end
    endtask

    task automatic wait_wbuf_empty();
        timeout_cnt = 0;
        while (!wbuf_empty_o) begin
            @(posedge clk_i);
            timeout_cnt++;
            if (timeout_cnt >= TIMEOUT_CYC)
                $fatal(1, "[TIMEOUT] wbuf_empty_o khong len");
        end
    endtask

    initial begin
        $display("==================================================");
        $display("[TB] BAT DAU MO PHONG HPDCACHE");
        $display("==================================================");

        reset_signals();
        do_reset();

        // =========================================================
        // TEST 1: Read Miss + Burst Refill
        // =========================================================
        send_req(
            HPDCACHE_REQ_LOAD,
            hpdcache_req_offset_t'('h000),
            hpdcache_tag_t'(64'hDEAD_BEEF >> 12),
            '0, '1, 3'd3, 1, 0, 0,
            hpdcache_req_sid_t'(0),
            hpdcache_req_tid_t'(0)
        );
        do_read_refill(CL_WORDS);
        wait_rsp("TEST1");
        $display("[TEST1 PASS] Read Miss + Burst Refill (%0d beats) OK - rdata=%h",
                 CL_WORDS, core_rsp_o.rdata);
        repeat(5) @(posedge clk_i);

        // =========================================================
        // TEST 2: Cache Hit (same addr as TEST1)
        // =========================================================
        send_req(
            HPDCACHE_REQ_LOAD,
            hpdcache_req_offset_t'('h000),
            hpdcache_tag_t'(64'hDEAD_BEEF >> 12),
            '0, '1, 3'd3, 1, 0, 0,
            hpdcache_req_sid_t'(0),
            hpdcache_req_tid_t'(1)
        );
        wait_rsp("TEST2");
        $display("[TEST2 PASS] Cache Hit OK - rdata=%h", core_rsp_o.rdata);
        repeat(5) @(posedge clk_i);

        // =========================================================
        // TEST 3: Write + WBUF Flush + wait wbuf_empty
        // =========================================================
        send_req(
            HPDCACHE_REQ_STORE,
            hpdcache_req_offset_t'('h000),
            hpdcache_tag_t'(64'hDEAD_BEEF >> 12),
            {($bits(hpdcache_req_data_t)/64){64'hCAFE_BABE_1111_2222}},
            '1, 3'd3, 0, 0, 0,
            hpdcache_req_sid_t'(0),
            hpdcache_req_tid_t'(2)
        );
        repeat(4) @(posedge clk_i);
        wbuf_flush_i = 1;
        @(posedge clk_i);
        wbuf_flush_i = 0;
        do_write_resp();
        wait_wbuf_empty();
        $display("[TEST3 PASS] Write + WBUF Flush + wbuf_empty OK");
        repeat(5) @(posedge clk_i);

        // =========================================================
        // TEST 4: Uncacheable (NC) Load
        // =========================================================
        send_req(
            HPDCACHE_REQ_LOAD,
            hpdcache_req_offset_t'('h100),
            hpdcache_tag_t'(64'hFF00_0000 >> 12),
            '0, '1, 3'd3, 1, 0, 1,
            hpdcache_req_sid_t'(0),
            hpdcache_req_tid_t'(3)
        );
        do_read_refill(1);
        wait_rsp("TEST4");
        $display("[TEST4 PASS] Uncacheable Load OK - rdata=%h", core_rsp_o.rdata);
        repeat(5) @(posedge clk_i);

        // =========================================================
        // TEST 5: AMO - AMOSWAP
        // =========================================================
        send_req(
            HPDCACHE_REQ_AMO_SWAP,
            hpdcache_req_offset_t'('h040),
            hpdcache_tag_t'(64'hDEAD_BEEF >> 12),
            {($bits(hpdcache_req_data_t)/64){64'hABCD_1234_5678_9ABC}},
            '1, 3'd3, 1, 0, 0,
            hpdcache_req_sid_t'(0),
            hpdcache_req_tid_t'(4)
        );
        timeout_cnt = 0;
        fork
            do_read_refill(CL_WORDS);
            begin
                wait_rsp("TEST5");
            end
        join
        $display("[TEST5 PASS] AMO SWAP OK - rdata=%h", core_rsp_o.rdata);
        repeat(5) @(posedge clk_i);

        // =========================================================
        // TEST 6: LR/SC sequence
        // =========================================================
        send_req(
            HPDCACHE_REQ_AMO_LR,
            hpdcache_req_offset_t'('h080),
            hpdcache_tag_t'(64'hDEAD_BEEF >> 12),
            '0, '1, 3'd2, 1, 0, 0,
            hpdcache_req_sid_t'(0),
            hpdcache_req_tid_t'(5)
        );
        fork
            do_read_refill(CL_WORDS);
            wait_rsp("TEST6-LR");
        join
        $display("[TEST6a PASS] LR OK - rdata=%h", core_rsp_o.rdata);
        repeat(3) @(posedge clk_i);

        send_req(
            HPDCACHE_REQ_AMO_SC,
            hpdcache_req_offset_t'('h080),
            hpdcache_tag_t'(64'hDEAD_BEEF >> 12),
            {($bits(hpdcache_req_data_t)/64){64'hDEAD_1234_DEAD_5678}},
            '1, 3'd2, 1, 0, 0,
            hpdcache_req_sid_t'(0),
            hpdcache_req_tid_t'(6)
        );
        wait_rsp("TEST6-SC");
        $display("[TEST6b PASS] SC OK - rdata=%h (0=success)", core_rsp_o.rdata);
        repeat(5) @(posedge clk_i);

        // =========================================================
        // TEST 7: core_req_abort_i
        // =========================================================
        @(posedge clk_i);
        core_req_valid_i            = 1;
        core_req_i.op               = HPDCACHE_REQ_LOAD;
        core_req_i.addr_offset      = hpdcache_req_offset_t'('h0C0);
        core_req_i.be               = '1;
        core_req_i.size             = 3'd3;
        core_req_i.need_rsp         = 1;
        core_req_i.phys_indexed     = 0;
        core_req_i.pma.uncacheable  = 0;
        core_req_i.sid              = hpdcache_req_sid_t'(0);
        core_req_i.tid              = hpdcache_req_tid_t'(7);
        core_req_abort_i            = 1;
        @(posedge clk_i);
        core_req_valid_i    = 0;
        core_req_abort_i    = 0;
        core_req_tag_i      = hpdcache_tag_t'(64'hBEEF_0000 >> 12);
        core_req_i          = '0;
        repeat(10) @(posedge clk_i);
        $display("[TEST7 PASS] Abort request OK (no rsp expected)");

        // =========================================================
        // TEST 8: RTAB rollback - fill MSHR then send extra req
        // =========================================================
        cfg_rtab_single_entry_i = 1;
        @(posedge clk_i);

        send_req(
            HPDCACHE_REQ_LOAD,
            hpdcache_req_offset_t'('h200),
            hpdcache_tag_t'(64'hAAAA_0000 >> 12),
            '0, '1, 3'd3, 1, 0, 0,
            hpdcache_req_sid_t'(0),
            hpdcache_req_tid_t'(8)
        );

        send_req(
            HPDCACHE_REQ_LOAD,
            hpdcache_req_offset_t'('h300),
            hpdcache_tag_t'(64'hBBBB_0000 >> 12),
            '0, '1, 3'd3, 1, 0, 0,
            hpdcache_req_sid_t'(0),
            hpdcache_req_tid_t'(9)
        );

        repeat(5) @(posedge clk_i);
        do_read_refill(CL_WORDS);
        repeat(3) @(posedge clk_i);
        do_read_refill(CL_WORDS);

        timeout_cnt = 0;
        repeat(2) begin
            wait_rsp("TEST8");
            @(posedge clk_i);
        end
        cfg_rtab_single_entry_i = 0;
        $display("[TEST8 PASS] RTAB rollback + evt_req_on_hold=%b evt_rtab_rollback=%b",
                 evt_req_on_hold_o, evt_rtab_rollback_o);
        repeat(5) @(posedge clk_i);

        // =========================================================
        // FIN
        // =========================================================
        $display("==================================================");
        $display("[TB] TAT CA TEST PASS - MO PHONG HOAN TAT");
        $display("==================================================");
        $stop;
    end

    always @(posedge clk_i) begin
        if (evt_cache_read_miss_o)  $display("[EVT @%0t] Read Miss",     $time);
        if (evt_cache_write_miss_o) $display("[EVT @%0t] Write Miss",    $time);
        if (evt_uncached_req_o)     $display("[EVT @%0t] Uncached Req",  $time);
        if (evt_req_on_hold_o)      $display("[EVT @%0t] Req On Hold",   $time);
        if (evt_rtab_rollback_o)    $display("[EVT @%0t] RTAB Rollback", $time);
        if (evt_stall_o)            $display("[EVT @%0t] Stall",         $time);
    end

endmodule
