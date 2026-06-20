quit -sim
project compileall
vsim -voptargs="+acc" -suppress 3009 work.tb_cva6   
do wave.do
run -all
wave zoom full