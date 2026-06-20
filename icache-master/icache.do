# =============================================================================
# icache.do - ModelSim simulation script cho khoi I-Cache + PLRU
# Project   : CVA6 RISC-V Core - Instruction Cache voi Tree-PLRU
# Testbench : tb_icache
# =============================================================================
# Cau truc thu muc:
#   D:\HCMUS\THESIS\cva6-master   - source RTL goc cua CVA6
#   D:\HCMUS\THESIS\icache-master\      - tb_icache.sv, plru.sv, cva6_icache.sv
# =============================================================================

# -----------------------------------------------------------------------------
# 0. Bien duong dan - chinh tai day neu can
# -----------------------------------------------------------------------------
set CVA6_DIR  "D:/HCMUS/THESIS/cva6-master"
set LOCAL_DIR "D:/HCMUS/THESIS/icache-master"

# -----------------------------------------------------------------------------
# 1. Tao va mo thu vien lam viec
# -----------------------------------------------------------------------------
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

# -----------------------------------------------------------------------------
# 2. Compile - thu tu BAT BUOC: packages truoc, modules sau, tb cuoi
# -----------------------------------------------------------------------------

# --- 2.1 Packages co so tu Vendor (PULP Platform) ---
vlog -sv -work work \
    "$CVA6_DIR/vendor/pulp-platform/common_cells/src/cf_math_pkg.sv"

# --- 2.2 Các Package cau hinh cua CVA6 ---
vlog -sv -work work \
    "$CVA6_DIR/core/include/config_pkg.sv"

vlog -sv -work work \
    "$CVA6_DIR/core/include/cv32a6_imac_sv32_config_pkg.sv"

# --- 2.3 Package RISC-V co ban ---
vlog -sv -work work \
    "$CVA6_DIR/core/include/riscv_pkg.sv"

# --- 2.4 Package kien truc Ariane ---
vlog -sv -work work \
    "$CVA6_DIR/core/include/ariane_pkg.sv"

# --- 2.5 Package Cache Subsystem ---
vlog -sv -work work \
    "$CVA6_DIR/core/include/wt_cache_pkg.sv"

# --- 2.6 Modules ha tang (lay tu Vendor thay vi Local) ---
vlog -sv -work work \
    "$CVA6_DIR/vendor/pulp-platform/common_cells/src/lzc.sv"

vlog -sv -work work \
    "$CVA6_DIR/common/local/util/sram_cache.sv"

# --- 2.7 Module PLRU (thiet ke moi) ---
vlog -sv -work work \
    "$LOCAL_DIR/plru.sv"

# --- 2.8 DUT: cva6_icache ---
vlog -sv -work work \
    "$CVA6_DIR/core/cache_subsystem/cva6_icache.sv"

# --- 2.9 Testbench ---
vlog -sv -work work \
    "$LOCAL_DIR/tb_icache.sv"
	
vlog -sv -work work \
    "$CVA6_DIR/vendor/pulp-platform/common_cells/src/deprecated/sram.sv"

# -----------------------------------------------------------------------------
# 3 & 4. Khoi dong Elaboration và Simulation
# -----------------------------------------------------------------------------
# Chạy vsim thẳng vào top module tb_icache
# Bỏ qua bước 'find instances' gây lỗi vish-4000
vsim -t 1ps -novopt work.tb_icache

# (Tùy chọn) Kiểm tra xem vsim có nạp thiết kế thành công không
if {[runStatus] == "loading"} {
    puts "LOI ELABORATION - Khong the nap tb_icache. Kiem tra lai cac warnings."
    return
}

# -----------------------------------------------------------------------------
# 5. Thiet lap cua so Wave - nhom theo chuc nang
# -----------------------------------------------------------------------------
add wave -divider "=== CLOCK & RESET ==="
add wave -radix bin  /tb_icache/clk_i
add wave -radix bin  /tb_icache/rst_ni

add wave -divider "=== CONTROL ==="
add wave -radix bin  /tb_icache/flush_i
add wave -radix bin  /tb_icache/en_i
add wave -radix bin  /tb_icache/miss_o

add wave -divider "=== CPU DREQ (fetch request) ==="
add wave -radix bin  /tb_icache/dreq_i.req
add wave -radix bin  /tb_icache/dreq_i.spec
add wave -radix hex  /tb_icache/dreq_i.vaddr
add wave -radix bin  /tb_icache/dreq_i.kill_s1
add wave -radix bin  /tb_icache/dreq_i.kill_s2
add wave -radix bin  /tb_icache/dreq_o.ready
add wave -radix bin  /tb_icache/dreq_o.valid
add wave -radix hex  /tb_icache/dreq_o.data

add wave -divider "=== ADDRESS TRANSLATION (AREQ) ==="
add wave -radix bin  /tb_icache/areq_i.fetch_valid
add wave -radix hex  /tb_icache/areq_i.fetch_paddr
add wave -radix bin  /tb_icache/areq_o.fetch_req
add wave -radix hex  /tb_icache/areq_o.fetch_vaddr

add wave -divider "=== MEMORY REFILL INTERFACE ==="
add wave -radix bin  /tb_icache/mem_data_req_o
add wave -radix bin  /tb_icache/mem_data_ack_i
add wave -radix hex  /tb_icache/mem_data_o.paddr
add wave -radix unsigned /tb_icache/mem_data_o.way
add wave -radix bin  /tb_icache/mem_rtrn_vld_i
add wave -radix hex  /tb_icache/mem_rtrn_i.rtype
add wave -radix hex  /tb_icache/mem_rtrn_i.data

add wave -divider "=== FSM STATE (DUT internal) ==="
add wave -radix symbolic /tb_icache/dut/state_q
add wave -radix symbolic /tb_icache/dut/state_d
add wave -radix bin      /tb_icache/dut/cache_rden
add wave -radix bin      /tb_icache/dut/cache_wren
add wave -radix bin      /tb_icache/dut/cmp_en_q

add wave -divider "=== TAG & HIT ==="
add wave -radix hex      /tb_icache/dut/cl_tag_d
add wave -radix hex      /tb_icache/dut/cl_tag_q
add wave -radix bin      /tb_icache/dut/cl_hit
add wave -radix unsigned /tb_icache/dut/hit_idx
add wave -radix bin      /tb_icache/dut/vld_rdata

add wave -divider "=== PLRU - Tree-PLRU module ==="
add wave -radix bin      /tb_icache/dut/i_plru/plru_tree_q
add wave -radix bin      /tb_icache/dut/i_plru/plru_tree_d
add wave -radix bin      /tb_icache/dut/i_plru/update_i
add wave -radix unsigned /tb_icache/dut/i_plru/access_way_i
add wave -radix unsigned /tb_icache/dut/i_plru/replace_way_o

add wave -divider "=== REPLACEMENT STRATEGY ==="
add wave -radix unsigned /tb_icache/dut/plru_access_way
add wave -radix unsigned /tb_icache/dut/plru_replace_way
add wave -radix unsigned /tb_icache/dut/inv_way
add wave -radix unsigned /tb_icache/dut/repl_way
add wave -radix bin      /tb_icache/dut/all_ways_valid
add wave -radix bin      /tb_icache/dut/repl_way_oh_q

add wave -divider "=== LATENCY COUNTER (TB) ==="
add wave -radix unsigned /tb_icache/latency_counter
add wave -radix bin      /tb_icache/is_measuring

# -----------------------------------------------------------------------------
# 6. Dinh dang cua so Wave
# -----------------------------------------------------------------------------
configure wave -namecolwidth  220
configure wave -valuecolwidth 120
configure wave -justifyvalue  left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 10
configure wave -griddelta 40
configure wave -timeline 1
configure wave -timelineunits ns

# -----------------------------------------------------------------------------
# 7. Chay simulation
# -----------------------------------------------------------------------------
run -all

# -----------------------------------------------------------------------------
# 8. Phong to toan bo waveform
# -----------------------------------------------------------------------------
wave zoom full

puts ""
puts "================================================================"
puts "  Simulation hoan tat. Waveform san sang de trace."
puts "  Dung  run 1us  hoac  run -all  neu muon chay them."
puts "================================================================"
