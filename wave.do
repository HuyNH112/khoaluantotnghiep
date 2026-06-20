# =============================================================================
# wave.do - CVA6 Top-level CPU Testbench
# =============================================================================
onerror {resume}
quietly WaveActivateNextPane {} 0

catch {delete wave *}

# --- 1. CLOCK & RESET ---
add wave -noupdate -divider "CLOCK & RESET"
add wave -noupdate /tb_cva6/clk
add wave -noupdate /tb_cva6/rst_n

# --- 2. CPU CONFIGURATION ---
add wave -noupdate -divider "CPU CONFIGURATION"
add wave -noupdate -radix hexadecimal /tb_cva6/boot_addr_i
add wave -noupdate -radix hexadecimal /tb_cva6/hart_id_i

# --- 3. MEMORY AXI READ CHANNEL (AR & R) ---
add wave -noupdate -divider "AXI READ (AR & R)"
add wave -noupdate /tb_cva6/noc_req.ar_valid
add wave -noupdate /tb_cva6/noc_resp.ar_ready
add wave -noupdate -radix hexadecimal /tb_cva6/noc_req.ar.addr
add wave -noupdate /tb_cva6/noc_resp.r_valid
add wave -noupdate /tb_cva6/noc_req.r_ready
add wave -noupdate -radix hexadecimal /tb_cva6/noc_resp.r.data

# --- 4. MEMORY AXI WRITE CHANNEL (AW, W & B) ---
add wave -noupdate -divider "AXI WRITE (AW, W & B)"
add wave -noupdate /tb_cva6/noc_req.aw_valid
add wave -noupdate /tb_cva6/noc_resp.aw_ready
add wave -noupdate -radix hexadecimal /tb_cva6/noc_req.aw.addr
add wave -noupdate /tb_cva6/noc_req.w_valid
add wave -noupdate /tb_cva6/noc_resp.w_ready
add wave -noupdate -radix hexadecimal /tb_cva6/noc_req.w.data
add wave -noupdate /tb_cva6/noc_resp.b_valid
add wave -noupdate /tb_cva6/noc_req.b_ready

# --- 5. TEST STATUS ---
add wave -noupdate -divider "TEST STATUS"
add wave -noupdate -radix unsigned /tb_cva6/expected_result

TreeUpdate [SetDefaultTree]
configure wave -namecolwidth 300
configure wave -valuecolwidth 120
configure wave -signalnamewidth 1
configure wave -justifyvalue left
WaveRestoreZoom {0 ns} {5000 ns}