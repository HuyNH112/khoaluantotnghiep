quit -sim
project compileall
vsim -voptargs="+acc" -suppress 3009 -suppress 13174 work.tb_hpdcache_prefetch  
do wave_dcache.do
run -all
wave zoom full