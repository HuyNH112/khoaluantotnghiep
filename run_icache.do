# Thoát phiên mô phỏng hiện tại (tránh lỗi file bị lock khi re-compile)
quit -sim

# Dựa vào GUI Project để tự động tìm và biên dịch các file có thay đổi
project compileall

# Khởi chạy Testbench Block-Level PLRU
# Kế thừa các tham số suppress 3009/13174 và bật access (+acc) như top-level
vsim -voptargs="+acc" -suppress 3009 -suppress 13174 work.tb_plru 

# Nạp file sóng
do wave_icache.do

# Chạy toàn bộ cho đến khi gặp $finish trong khối initial của tb_plru
run -all

# Zoom full cửa sổ sóng
wave zoom full