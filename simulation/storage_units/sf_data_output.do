source base.do
vcom -reportprogress 300 -work work $storage_units_testbench/tb_sf_data_output.vhd

vsim -voptargs=+acc work.tb_sf_data_output -t ps -novopt
add wave -position end  sim:/tb_sf_data_output/*
add wave -position end  sim:/tb_sf_data_output/uut/*
add wave -position end  sim:/tb_sf_data_output/uut/image_store_load_instance_b/*
run 400 us
