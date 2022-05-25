source base.do
vcom -reportprogress 300 -work work $storage_units_testbench/tb_weightMemory4096x8.vhd

vsim -voptargs=+acc work.tb_weightMemory_4096x8 -t ps -novopt
add wave -position end  sim:/tb_weightMemory_4096x8/bitwidth
add wave -position end  sim:/tb_weightMemory_4096x8/addresswidth
add wave -position end  sim:/tb_weightMemory_4096x8/wordCount
add wave -position end  sim:/tb_weightMemory_4096x8/clock_delay
add wave -position end  sim:/tb_weightMemory_4096x8/mem_delay
add wave -position end  sim:/tb_weightMemory_4096x8/reset
add wave -position end  sim:/tb_weightMemory_4096x8/ki_sig
add wave -position end  sim:/tb_weightMemory_4096x8/ko_sig
add wave -position end  sim:/tb_weightMemory_4096x8/sleep_in
add wave -position end  sim:/tb_weightMemory_4096x8/sleep_out
add wave -position end  sim:/tb_weightMemory_4096x8/address
add wave -position end  sim:/tb_weightMemory_4096x8/mem_data
add wave -position end  sim:/tb_weightMemory_4096x8/z
add wave -position end  sim:/tb_weightMemory_4096x8/write_en
add wave -position end  sim:/tb_weightMemory_4096x8/UUT/*
run 290 us
