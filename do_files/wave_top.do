onerror {resume}
quietly WaveActivateNextPane {} 0
catch {delete wave *}

add wave -noupdate -divider "CLOCK & RESET"
add wave -noupdate /tb_cva6/clk
add wave -noupdate /tb_cva6/rst_n

add wave -noupdate -divider "DOMINO PREFETCHER IP"
# [ĐÃ SỬA]: Xóa phần "u_domino/" vì biến pref_req nằm ở scope của Subsystem
add wave -noupdate -color Gold /tb_cva6/u_cva6/gen_cache_hpd/i_cache_subsystem/pref_req
add wave -noupdate -color Gold -radix hexadecimal /tb_cva6/u_cva6/gen_cache_hpd/i_cache_subsystem/pref_req.pref_addr

add wave -noupdate /tb_cva6/u_cva6/gen_cache_hpd/i_cache_subsystem/is_prefetching
add wave -noupdate -radix hexadecimal /tb_cva6/u_cva6/gen_cache_hpd/i_cache_subsystem/core_load_addr
add wave -noupdate /tb_cva6/u_cva6/gen_cache_hpd/i_cache_subsystem/core_load_valid

add wave -noupdate -divider "CACHE PORT 2 (INJECTION)"
add wave -noupdate /tb_cva6/u_cva6/gen_cache_hpd/i_cache_subsystem/dcache_req_ports_i_mod[2].data_req
add wave -noupdate /tb_cva6/u_cva6/gen_cache_hpd/i_cache_subsystem/dcache_req_ports_i_mod[2].data_we
add wave -noupdate -radix hexadecimal /tb_cva6/u_cva6/gen_cache_hpd/i_cache_subsystem/dcache_req_ports_i_mod[2].address_tag

TreeUpdate [SetDefaultTree]
configure wave -namecolwidth 350
configure wave -valuecolwidth 150
configure wave -justifyvalue left
WaveRestoreZoom {0 ns} {5000 ns}