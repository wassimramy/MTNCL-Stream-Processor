source base.do
vcom -reportprogress 300 -work work $individual_cores_testbench/MTNCL_Smoothing_Filter_64_by_64_TB.vhd

vsim -voptargs=+acc work.MTNCL_Smoothing_Filter_TB -t ps -novopt
add wave -position end  sim:/MTNCL_Smoothing_Filter_TB/*
add wave -position end  sim:/MTNCL_Smoothing_Filter_TB/uut/*
add wave -position end  sim:/MTNCL_Smoothing_Filter_TB/uut/sf_data_loader_instance/*
add wave -position end 	sim:/mtncl_smoothing_filter_tb/uut/sf_data_loader_instance/sf_address_gen_w_mux_instance/*
add wave -position end  sim:/MTNCL_Smoothing_Filter_TB/uut/sf_core_w_reg_instance_a/*
add wave -position end  sim:/MTNCL_Smoothing_Filter_TB/uut/sf_core_w_reg_instance_b/*
add wave -position end  sim:/MTNCL_Smoothing_Filter_TB/uut/sf_core_data_output/*
add wave -position end 	sim:/mtncl_smoothing_filter_tb/uut/sf_core_data_output/image_store_load_instance_a/*
add wave -position end 	sim:/mtncl_smoothing_filter_tb/uut/sf_core_data_output/image_store_load_instance_a/image_load_instance/*
add wave -position end 	sim:/mtncl_smoothing_filter_tb/uut/sf_core_data_output/image_store_load_instance_a/image_store_instance/*
add wave -position end 	sim:/mtncl_smoothing_filter_tb/uut/sf_core_data_output/image_store_load_instance_b/*
add wave -position end 	sim:/mtncl_smoothing_filter_tb/uut/sf_core_data_output/image_store_load_instance_b/image_load_instance/*
add wave -position end 	sim:/mtncl_smoothing_filter_tb/uut/sf_core_data_output/image_store_load_instance_b/image_store_instance/*
run 1.500 ms
