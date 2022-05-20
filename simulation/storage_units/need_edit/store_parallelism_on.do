source base.do
vcom -reportprogress 300 -work work $storage_units_testbench/tb_image_store_parallelism_on.vhd

vsim -voptargs=+acc work.tb_image_store -t ps -novopt
add wave -position end  sim:/tb_image_store/*
add wave -position end  sim:/tb_image_store/UUT/*
run 220 us
