# ========================================================
# TC-INT-01 SIMULATION SCRIPT
# Purpose: Boot + ALU execution, 32/32 commits
# ========================================================

# 1. CLEAN SLATE
quit -sim
project compileall

# ========================================================
# 2. COMPILE PHASE - Explicit testbench compilation AFTER RTL
# ========================================================
# Critical: Ensures testbench compiles after all RTL dependencies
vlog -work work -sv D:/khoaluantotnghiep/testbench/tb_integrated.sv

# ========================================================
# 3. ELABORATION PHASE - Optimize for simulation
# ========================================================
# CRITICAL FLAGS:
#   +acc=npr:  Preserve all signals (prevent dead-code elimination of NOC ports)
vopt +acc=npr -o my_opt work.tb_l1_cache_integration_logic

# ========================================================
# 4. SIMULATION PHASE - Load optimized design
# ========================================================
# Warning suppression:
#   3009: always_comb found in simulation
#   13174: Port connection issues
#   7033: Deprecated constructs
#   8386: Extended range warnings
vsim -suppress 3009 \
     -suppress 13174 \
     -suppress 7033 \
     -suppress 8386 \
     -quiet \
     -nologo \
     -t 1ns \
     -ieee_nowarn \
     my_opt

# ========================================================
# 5. LOGGING & TRANSCRIPT
# ========================================================
# Enable full logging for verification
transcript on
log -r /*

# ========================================================
# 6. RUN SIMULATION
# ========================================================
# 10000ns = 100us = 1000 cycles @ 10MHz
# Timeline:
#   0-100ns:    Reset sequence (10 cycles)
#   100-150ns:  First fetch request
#   150-3350ns: 32 commits @ 100ns/cycle
#   3350-10000ns: Monitor + margin
run 10000 ns

# ========================================================
# 7. RESULTS VERIFICATION
# ========================================================
puts "\n========================================================"
puts "Simulation Complete - Verification Checklist:"
puts "========================================================"
puts ""
puts "✅ CHECK 1: Compilation Success"
puts "   Expected: '155 compiles, 0 failed with no errors'"
puts ""
puts "✅ CHECK 2: Elaboration Success"
puts "   Expected: 'Optimized design name is my_opt'"
puts "   NOT Expected: 'vopt-7063' error"
puts ""
puts "✅ CHECK 3: Pre-load Verification"
puts "   Expected: '[INIT] I-Cache SRAM pre-loaded with 32 NOPs'"
puts ""
puts "✅ CHECK 4: Boot Sequence"
puts "   Expected: '[BOOT] Reset released'"
puts ""
puts "✅ CHECK 5: Instruction Execution"
puts "   Expected: '[PASS] TC-INT-01: 32/32 commits'"
puts "   (Should see PC trace: 0x80000000 → 0x8000007C)"
puts ""
puts "========================================================"
puts "If ALL 5 checks pass: ✅ TEST SUCCESSFUL"
puts "========================================================"
puts ""

quit -sim
