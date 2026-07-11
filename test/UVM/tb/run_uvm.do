vdel -all -lib work
vlib work

# Biên dịch Top module
vlog -sv +incdir+hpdcache_agent tb/tb_top.sv

# Chạy mô phỏng (gọi đích danh tên test)
vsim -voptargs="+acc" -L mtiUvm work.tb_top +UVM_TESTNAME=hpdcache_base_test

run -all