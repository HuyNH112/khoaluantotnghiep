# ============================================================
# create_cva6_clean.do
# Target: cv32a6_imac_sv32 + ICache (PLRU)
# Loai bo: CVXIF, AES, Tracer, RVFI, Triggers, Accel,
#           std_cache_pkg, zcmt, lfsr (da thay bang PLRU),
#           std_dcache (cache_ctrl/axi_adapter/tag_cmp)
# HPDcache: da compile rieng -> khong them vao day
# ============================================================

set BASE_DIR  "D:/HCMUS/THESIS"
set CVA6_DIR  "D:/HCMUS/THESIS/cva6-master"
set ICACHE_DIR "D:/HCMUS/THESIS/icache-master"

quit -sim
catch {project close}
project new $BASE_DIR full_core work

# .svh headers - them bang tay order 0,1,2 trong GUI
# cvxif_types.svh, rvfi_types.svh, registers.svh

set file_list [list \
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
\
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
    $CVA6_DIR/core/lsu_bypass.sv \
    $CVA6_DIR/core/load_unit.sv \
    $CVA6_DIR/core/load_store_unit.sv \
\
    $CVA6_DIR/core/commit_stage.sv \
    $CVA6_DIR/core/controller.sv \
    $CVA6_DIR/core/csr_regfile.sv \
    $CVA6_DIR/core/axi_shim.sv \
    $CVA6_DIR/core/cva6_fifo_v3.sv \
    $CVA6_DIR/core/cva6.sv \
]

foreach f $file_list {
    project addfile $f systemverilog
}

echo "=== CVA6 IMAC+ICache file list loaded: [llength $file_list] files ==="
