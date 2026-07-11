# ============================================================
# create_cva6_full.do
# Target: cv32a6_imac_sv32 + ICache + HPDcache
# ============================================================

set BASE_DIR  "D:/HCMUS/THESIS"
set CVA6_DIR  "D:/HCMUS/THESIS/cva6-master"
set ICACHE_DIR "D:/HCMUS/THESIS/icache-master"
set HPDCACHE_DIR "D:/HCMUS/THESIS/cv-hpdcache-master"

quit -sim
catch {project close}
project new $BASE_DIR cva6 work



# ====================== ADD FILES ======================
set file_list [list \
	$CVA6_DIR/core/include/rvfi_types.svh \
    $CVA6_DIR/core/include/cvxif_types.svh \
    $CVA6_DIR/vendor/pulp-platform/common_cells/include/common_cells/registers.svh \
\
    $HPDCACHE_DIR/rtl/include/hpdcache_typedef.svh \
	$HPDCACHE_DIR/hpdcache_config.svh \
\
    $CVA6_DIR/core/include/config_pkg.sv \
    $CVA6_DIR/core/include/cv32a6_imac_sv32_config_pkg.sv \
    $CVA6_DIR/core/include/riscv_pkg.sv \
    $CVA6_DIR/core/include/ariane_pkg.sv \
    $CVA6_DIR/vendor/pulp-platform/axi/src/axi_pkg.sv \
    $CVA6_DIR/core/include/wt_cache_pkg.sv \
    $CVA6_DIR/core/include/build_config_pkg.sv \
    $CVA6_DIR/core/include/dummy_l15_pkg.sv \
\
    $CVA6_DIR/vendor/pulp-platform/common_cells/src/cf_math_pkg.sv \
\
    $CVA6_DIR/vendor/pulp-platform/common_cells/src/fifo_v3.sv \
    $CVA6_DIR/vendor/pulp-platform/common_cells/src/stream_arbiter.sv \
    $CVA6_DIR/vendor/pulp-platform/common_cells/src/stream_arbiter_flushable.sv \
    $CVA6_DIR/vendor/pulp-platform/common_cells/src/stream_mux.sv \
    $CVA6_DIR/vendor/pulp-platform/common_cells/src/stream_demux.sv \
    $CVA6_DIR/vendor/pulp-platform/common_cells/src/lzc.sv \
    $CVA6_DIR/vendor/pulp-platform/common_cells/src/rr_arb_tree.sv \
    $CVA6_DIR/vendor/pulp-platform/common_cells/src/shift_reg.sv \
    $CVA6_DIR/vendor/pulp-platform/common_cells/src/unread.sv \
    $CVA6_DIR/vendor/pulp-platform/common_cells/src/popcount.sv \
    $CVA6_DIR/vendor/pulp-platform/common_cells/src/exp_backoff.sv \
    $CVA6_DIR/vendor/pulp-platform/common_cells/src/counter.sv \
    $CVA6_DIR/vendor/pulp-platform/common_cells/src/delta_counter.sv \
\
    $CVA6_DIR/vendor/pulp-platform/tech_cells_generic/src/rtl/tc_sram.sv \
    $CVA6_DIR/common/local/util/tc_sram_wrapper.sv \
    $CVA6_DIR/common/local/util/tc_sram_wrapper_cache_techno.sv \
    $CVA6_DIR/common/local/util/sram.sv \
    $CVA6_DIR/common/local/util/sram_cache.sv \
\
    $CVA6_DIR/core/frontend/bht.sv \
    $CVA6_DIR/core/frontend/bht2lvl.sv \
    $CVA6_DIR/core/frontend/ras.sv \
    $CVA6_DIR/core/frontend/instr_scan.sv \
    $CVA6_DIR/core/frontend/instr_queue.sv \
    $CVA6_DIR/core/frontend/frontend.sv \
    $CVA6_DIR/vendor/pulp-platform/common_cells/src/plru_tree.sv \
    $ICACHE_DIR/plru.sv \
    $CVA6_DIR/core/cache_subsystem/cva6_icache.sv \
    $CVA6_DIR/core/cache_subsystem/cva6_icache_axi_wrapper.sv \
\
    $CVA6_DIR/core/cva6_mmu/cva6_tlb.sv \
    $CVA6_DIR/core/cva6_mmu/cva6_shared_tlb.sv \
    $CVA6_DIR/core/cva6_mmu/cva6_ptw.sv \
    $CVA6_DIR/core/cva6_mmu/cva6_mmu.sv \
\
    $CVA6_DIR/core/pmp/src/pmp_entry.sv \
    $CVA6_DIR/core/pmp/src/pmp.sv \
    $CVA6_DIR/core/pmp/src/pmp_data_if.sv \
\
    $CVA6_DIR/core/decoder.sv \
    $CVA6_DIR/core/compressed_decoder.sv \
    $CVA6_DIR/core/macro_decoder.sv \
    $CVA6_DIR/core/instr_realign.sv \
    $CVA6_DIR/core/id_stage.sv \
\
    $CVA6_DIR/core/ariane_regfile_ff.sv \
    $CVA6_DIR/core/scoreboard.sv \
    $CVA6_DIR/core/issue_read_operands.sv \
    $CVA6_DIR/core/issue_stage.sv \
\
    $CVA6_DIR/core/alu.sv \
    $CVA6_DIR/core/alu_wrapper.sv \
    $CVA6_DIR/core/branch_unit.sv \
    $CVA6_DIR/core/mult.sv \
    $CVA6_DIR/core/multiplier.sv \
    $CVA6_DIR/core/serdiv.sv \
    $CVA6_DIR/core/csr_buffer.sv \
    $CVA6_DIR/core/raw_checker.sv \
    $CVA6_DIR/core/perf_counters.sv \
    $CVA6_DIR/core/ex_stage.sv \
\
    $CVA6_DIR/core/amo_buffer.sv \
    $CVA6_DIR/core/store_buffer.sv \
    $CVA6_DIR/core/store_unit.sv \
    $CVA6_DIR/core/load_unit.sv \
    $CVA6_DIR/core/load_store_unit.sv \
\
    $CVA6_DIR/core/lsu_bypass.sv \
    $CVA6_DIR/core/commit_stage.sv \
    $CVA6_DIR/core/controller.sv \
    $CVA6_DIR/core/csr_regfile.sv \
    $CVA6_DIR/core/axi_shim.sv \
    $CVA6_DIR/core/cva6_fifo_v3.sv \
\
    $HPDCACHE_DIR/rtl/src/hpdcache_pkg.sv \
    $HPDCACHE_DIR/rtl/src/utils/hpdcache_mem_req_read_arbiter.sv \
    $HPDCACHE_DIR/rtl/src/utils/hpdcache_mem_req_write_arbiter.sv \
    $HPDCACHE_DIR/rtl/src/common/hpdcache_demux.sv \
    $HPDCACHE_DIR/rtl/src/common/hpdcache_lfsr.sv \
    $HPDCACHE_DIR/rtl/src/common/hpdcache_sync_buffer.sv \
    $HPDCACHE_DIR/rtl/src/common/hpdcache_fifo_reg.sv \
    $HPDCACHE_DIR/rtl/src/common/hpdcache_fifo_reg_initialized.sv \
    $HPDCACHE_DIR/rtl/src/common/hpdcache_fxarb.sv \
    $HPDCACHE_DIR/rtl/src/common/hpdcache_rrarb.sv \
    $HPDCACHE_DIR/rtl/src/common/hpdcache_mux.sv \
    $HPDCACHE_DIR/rtl/src/common/hpdcache_decoder.sv \
    $HPDCACHE_DIR/rtl/src/common/hpdcache_1hot_to_binary.sv \
    $HPDCACHE_DIR/rtl/src/common/hpdcache_prio_1hot_encoder.sv \
    $HPDCACHE_DIR/rtl/src/common/hpdcache_prio_bin_encoder.sv \
    $HPDCACHE_DIR/rtl/src/common/hpdcache_sram.sv \
    $HPDCACHE_DIR/rtl/src/common/hpdcache_sram_wbyteenable.sv \
    $HPDCACHE_DIR/rtl/src/common/hpdcache_sram_wmask.sv \
    $HPDCACHE_DIR/rtl/src/common/hpdcache_regbank_wbyteenable_1rw.sv \
    $HPDCACHE_DIR/rtl/src/common/hpdcache_regbank_wmask_1rw.sv \
    $HPDCACHE_DIR/rtl/src/common/hpdcache_data_downsize.sv \
    $HPDCACHE_DIR/rtl/src/common/hpdcache_data_upsize.sv \
    $HPDCACHE_DIR/rtl/src/common/hpdcache_data_resize.sv \
    $HPDCACHE_DIR/rtl/src/hwpf_stride/hwpf_stride_pkg.sv \
    $HPDCACHE_DIR/rtl/src/hwpf_stride/hwpf_stride.sv \
    $HPDCACHE_DIR/rtl/src/hwpf_stride/hwpf_stride_arb.sv \
    $HPDCACHE_DIR/rtl/src/hwpf_stride/hwpf_stride_wrapper.sv \
	$CVA6_DIR/core/cache_subsystem/cva6_hpdcache_if_adapter.sv \
	$HPDCACHE_DIR/rtl/src/target/cva6/cva6_hpdcache_cmo_if_adapter.sv \
    $HPDCACHE_DIR/rtl/src/hpdcache.sv \
	$CVA6_DIR/core/cache_subsystem/cva6_hpdcache_wrapper.sv \
    $HPDCACHE_DIR/rtl/src/hpdcache_amo.sv \
    $HPDCACHE_DIR/rtl/src/hpdcache_cmo.sv \
    $HPDCACHE_DIR/rtl/src/hpdcache_core_arbiter.sv \
    $HPDCACHE_DIR/rtl/src/hpdcache_ctrl.sv \
    $HPDCACHE_DIR/rtl/src/hpdcache_ctrl_pe.sv \
    $HPDCACHE_DIR/rtl/src/hpdcache_memctrl.sv \
    $HPDCACHE_DIR/rtl/src/hpdcache_cbuf.sv \
    $HPDCACHE_DIR/rtl/src/hpdcache_miss_handler.sv \
    $HPDCACHE_DIR/rtl/src/hpdcache_mshr.sv \
    $HPDCACHE_DIR/rtl/src/hpdcache_rtab.sv \
    $HPDCACHE_DIR/rtl/src/hpdcache_uncached.sv \
    $HPDCACHE_DIR/rtl/src/hpdcache_victim_plru.sv \
    $HPDCACHE_DIR/rtl/src/hpdcache_victim_random.sv \
    $HPDCACHE_DIR/rtl/src/hpdcache_victim_sel.sv \
    $HPDCACHE_DIR/rtl/src/hpdcache_wbuf.sv \
    $HPDCACHE_DIR/rtl/src/hpdcache_flush.sv \
    $HPDCACHE_DIR/hpdcache_wrapper.sv \
    $HPDCACHE_DIR/rtl/src/common/macros/behav/hpdcache_sram_1rw.sv \
    $HPDCACHE_DIR/rtl/src/common/macros/behav/hpdcache_sram_wbyteenable_1rw.sv \
    $HPDCACHE_DIR/rtl/src/common/macros/behav/hpdcache_sram_wmask_1rw.sv \
\
	$HPDCACHE_DIR/rtl/src/utils/hpdcache_mem_resp_demux.sv \
	$HPDCACHE_DIR/rtl/src/utils/hpdcache_mem_to_axi_write.sv \
	$HPDCACHE_DIR/rtl/src/utils/hpdcache_mem_to_axi_read.sv \
	$CVA6_DIR/core/cache_subsystem/cva6_hpdcache_subsystem.sv \
    $CVA6_DIR/core/cva6.sv \
	$BASE_DIR/tb_cva6.sv \
]

foreach f $file_list {
    project addfile $f systemverilog
}

echo "=== Full CVA6 + ICache + HPDcache loaded: [llength $file_list] files ==="
