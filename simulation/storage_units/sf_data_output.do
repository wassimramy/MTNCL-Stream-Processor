source base.do
vcom -reportprogress 300 -work work $storage_units_testbench/tb_sf_data_output.vhd

vsim -voptargs=+acc work.tb_sf_data_output -t ps -novopt
add wave -position end  sim:/tb_sf_data_output/*
run 400 us
