# =============================================================================
# wave.do - Waveform cho 5 Testcases HPDcache
# =============================================================================
onerror {resume}
quietly WaveActivateNextPane {} 0

# Xóa waveform cũ nếu có
if {[info exists tb]} {
    delete wave *
}

# --- 1. CLOCK & RESET ---
add wave -noupdate -divider "CLOCK & RESET"
add wave -noupdate -color Yellow /tb_hpdcache/clk_i
add wave -noupdate -color Red    /tb_hpdcache/rst_ni

# --- 2. CORE REQUEST (Front-end) ---
# Quan sát Testcase 1, 2, 5 (Gửi lệnh LOAD/STORE, Tag, Offset)
add wave -noupdate -divider "CORE REQUEST"
add wave -noupdate -color Cyan /tb_hpdcache/core_req_valid_i
add wave -noupdate -color Cyan /tb_hpdcache/core_req_ready_o
add wave -noupdate -color Orange /tb_hpdcache/core_req_i.op
add wave -noupdate -radix hex /tb_hpdcache/core_req_tag_i
add wave -noupdate -radix hex /tb_hpdcache/core_req_i.addr_offset
add wave -noupdate -radix hex /tb_hpdcache/core_req_i.wdata

# --- 3. CORE RESPONSE ---
# Quan sát Testcase 1, 5 (Hit/Miss trả data về lõi)
add wave -noupdate -divider "CORE RESPONSE"
add wave -noupdate -color Green /tb_hpdcache/core_rsp_valid_o
add wave -noupdate -radix hex /tb_hpdcache/core_rsp_o.rdata

# --- 4. MEMORY READ CHANNEL (Refill) ---
# Quan sát Testcase 1 (MSHR cấp phát, lấy data từ RAM)
add wave -noupdate -divider "MEM READ (REFILL)"
add wave -noupdate -color default /tb_hpdcache/mem_req_read_valid_o
add wave -noupdate -color default /tb_hpdcache/mem_req_read_ready_i
add wave -noupdate -radix hex /tb_hpdcache/mem_req_read_addr_o
add wave -noupdate -color default /tb_hpdcache/mem_resp_read_valid_i
add wave -noupdate -radix hex /tb_hpdcache/mem_resp_read_data_i

# --- 5. MEMORY WRITE CHANNEL (Write-back & Flush) ---
# Quan sát Testcase 2, 4 (Coalescing, Write-back do Eviction)
add wave -noupdate -divider "MEM WRITE (WRITE-BACK)"
add wave -noupdate -color Magenta /tb_hpdcache/mem_req_write_valid_o
add wave -noupdate -color Magenta /tb_hpdcache/mem_req_write_ready_i
add wave -noupdate -radix hex /tb_hpdcache/mem_req_write_addr_o
add wave -noupdate -color default /tb_hpdcache/mem_req_write_data_valid_o
add wave -noupdate -radix hex /tb_hpdcache/mem_req_write_data_o
add wave -noupdate -color default /tb_hpdcache/mem_resp_write_valid_i

# --- 6. WBUF CONTROL ---
# Quan sát Testcase 3 (Xả Write Buffer)
add wave -noupdate -divider "WRITE BUFFER (WBUF)"
add wave -noupdate -color Yellow /tb_hpdcache/wbuf_flush_i
add wave -noupdate -color default /tb_hpdcache/wbuf_empty_o

# --- 7. PERFORMANCE EVENTS (Miss, Hit, Evict) ---
# Quan sát toàn diện các Testcases để xem phản ứng của Controller
add wave -noupdate -divider "EVENTS (MISS/HIT/STALL)"
add wave -noupdate -color Red /tb_hpdcache/evt_cache_read_miss_o
add wave -noupdate -color Red /tb_hpdcache/evt_cache_write_miss_o
add wave -noupdate -color Orange /tb_hpdcache/evt_stall_o
add wave -noupdate -color Orange /tb_hpdcache/evt_req_on_hold_o

# --- Cấu hình hiển thị ---
TreeUpdate [SetDefaultTree]
configure wave -namecolwidth 250
configure wave -valuecolwidth 100
configure wave -signalnamewidth 1
configure wave -justifyvalue left
WaveRestoreZoom {0 ns} {150 ns}