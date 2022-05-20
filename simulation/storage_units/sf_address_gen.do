source base.do
vcom -reportprogress 300 -work work $storage_units_testbench/tb_sf_address_generator.vhd

vsim -voptargs=+acc work.tb_sf_address_generator -t ps -novopt
add wave -position end  sim:/tb_sf_address_generator/*
add wave -position end  sim:/tb_sf_address_generator/UUT/*
run 1.5 ms
