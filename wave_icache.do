onerror {resume}
quietly WaveActivateNextPane {} 0

# Xóa các sóng cũ để tránh rác tín hiệu từ top-level
catch {delete wave *}

add wave -noupdate -divider "CLOCK & RESET"
add wave -noupdate -color Orange /tb_plru/clk_i
add wave -noupdate -color Orange /tb_plru/rst_ni
add wave -noupdate -color Red    /tb_plru/flush_i

add wave -noupdate -divider "PLRU INTERFACE (DUT)"
add wave -noupdate /tb_plru/update_i
add wave -noupdate -radix unsigned /tb_plru/access_way_i
add wave -noupdate -color Yellow -radix unsigned /tb_plru/replace_way_o

add wave -noupdate -divider "INTERNAL TREE NODES"
# Catch để tránh báo lỗi nếu đường dẫn RTL tới plru_tree_q thay đổi
catch {add wave -noupdate -color Cyan -radix binary /tb_plru/i_plru/plru_tree_q}

TreeUpdate [SetDefaultTree]

# Đồng bộ UI width theo đúng chuẩn của top-level
configure wave -namecolwidth 350
configure wave -valuecolwidth 150
configure wave -justifyvalue left

# Thiết lập zoom phù hợp với thời gian ngắn của Block-Level Testbench
WaveRestoreZoom {0 ns} {50 ns}