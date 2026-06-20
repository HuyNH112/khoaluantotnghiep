# =============================================================================
# dcache.do - Kiem tra bien dich IP Core (Pure RTL Compilation)
# =============================================================================

# 1. Dinh nghia bien moi truong de ModelSim doc duoc duong dan trong file Flist
set env(HPDCACHE_DIR) "D:/HCMUS/THESIS/cv-hpdcache-master"

# 2. Xoa sach thu vien cu va tao thu vien work moi
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

puts ""
puts "================================================================"
puts "  BAT DAU BIEN DICH IP CORE (RTL GOC CUA HANG)"
puts "================================================================"

# 3. Bien dich toan bo IP Core chi bang 1 dong lenh duy nhat thong qua Flist
# Voi lenh nay, ModelSim se tu dong chui vao Flist, doc include va sap xep 
# dung thu tu: Package -> Common -> Utils -> Core Modules.
vlog -reportprogress 300 -sv -work work -f $env(HPDCACHE_DIR)/rtl/hpdcache.Flist

puts "================================================================"
puts "  BIEN DICH HOAN TAT!"
puts "  Neu khong co dong thong bao loi mau do (Error) nao o tren,"
puts "  IP cua ban da duoc hop nhat hoan hao tren muc RTL."
puts "================================================================"