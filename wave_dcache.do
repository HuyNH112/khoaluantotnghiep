# File: wave_dcache.do
# Mô tả: Định nghĩa cấu trúc sóng nạp chính xác theo scope tb_hpdcache_prefetch
onerror {resume}
quietly WaveActivateNextPane {} 0
catch {delete wave *}

# --- 1. CLOCK & RESET ---
add wave -noupdate -divider "CLOCK & RESET"
add wave -noupdate /tb_hpdcache_prefetch/clk
add wave -noupdate /tb_hpdcache_prefetch/rst_n

# --- 2. CORE <-> CACHE INTERFACE ---
add wave -noupdate -divider "CORE <-> CACHE INTERFACE"
add wave -noupdate /tb_hpdcache_prefetch/core_req_valid
add wave -noupdate /tb_hpdcache_prefetch/core_req_ready
add wave -noupdate -radix hexadecimal /tb_hpdcache_prefetch/core_req
add wave -noupdate -radix hexadecimal /tb_hpdcache_prefetch/core_req_tag
add wave -noupdate /tb_hpdcache_prefetch/core_rsp_valid
add wave -noupdate -radix hexadecimal /tb_hpdcache_prefetch/core_rsp

# --- 3. CACHE <-> MEMORY READ ---
add wave -noupdate -divider "CACHE <-> MEMORY READ"
add wave -noupdate /tb_hpdcache_prefetch/mem_req_read_valid
add wave -noupdate /tb_hpdcache_prefetch/mem_req_read_ready
add wave -noupdate -radix hexadecimal /tb_hpdcache_prefetch/mem_req_read
add wave -noupdate /tb_hpdcache_prefetch/mem_resp_read_valid
add wave -noupdate -radix hexadecimal /tb_hpdcache_prefetch/mem_resp_read

# --- 4. CACHE <-> MEMORY WRITE ---
add wave -noupdate -divider "CACHE <-> MEMORY WRITE"
add wave -noupdate /tb_hpdcache_prefetch/mem_req_write_valid
add wave -noupdate /tb_hpdcache_prefetch/mem_req_write_ready
add wave -noupdate -radix hexadecimal /tb_hpdcache_prefetch/mem_req_write
add wave -noupdate /tb_hpdcache_prefetch/mem_req_write_data_valid
add wave -noupdate -radix hexadecimal /tb_hpdcache_prefetch/mem_req_write_data

TreeUpdate [SetDefaultTree]
configure wave -namecolwidth 280
configure wave -valuecolwidth 140
configure wave -signalnamewidth 1
configure wave -justifyvalue left
WaveRestoreZoom {0 ns} {1000 ns}