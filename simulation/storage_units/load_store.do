source base.do
vcom -reportprogress 300 -work work $storage_units_testbench/tb_image_load_store.vhd

vsim -voptargs=+acc work.tb_image_load_store -t ps -novopt
add wave -position end  sim:/tb_image_load_store/*
add wave -position end  sim:/tb_image_load_store/UUT/*
run 500 us
