source base.do
vcom -reportprogress 300 -work work $storage_units_testbench/tb_image_store_load_parallelism_off.vhd

vsim -voptargs=+acc work.tb_image_store_load -t ps -novopt
add wave -position end  sim:/tb_image_store_load/*
add wave -position end  sim:/tb_image_store_load/UUT/*
run 450 us
