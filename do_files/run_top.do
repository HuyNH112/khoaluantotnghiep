quit -sim
project compileall
# Chạy Testbench Top-Level của CVA6
vsim -voptargs="+acc" -suppress 3009 -suppress 13174 work.tb_cva6 
# Nạp file sóng
do wave_top.do
# Cấu hình testbench nạp file hex (Tùy thuộc vào thiết lập tb_cva6 của bạn)
# run -all
run 50000 ns
wave zoom full