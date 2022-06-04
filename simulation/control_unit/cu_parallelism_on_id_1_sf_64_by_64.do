source base.do
vcom -reportprogress 300 -work work $control_unit_testbench/MTNCL_Control_Unit_Parallelism_On_ID_1_SF_64_by_64_TB.vhd

vsim -voptargs=+acc work.MTNCL_Control_Unit_Parallelism_On_ID_1_SF_64_by_64_TB -t ps -novopt
add wave -position end  sim:/MTNCL_Control_Unit_Parallelism_On_ID_1_SF_64_by_64_TB/*
add wave -position end  sim:/MTNCL_Control_Unit_Parallelism_On_ID_1_SF_64_by_64_TB/UUT/mtncl_sf_core_instance/*
add wave -position end  sim:/MTNCL_Control_Unit_Parallelism_On_ID_1_SF_64_by_64_TB/UUT/mtncl_sf_core_instance/sf_data_loader_instance/*
add wave -position end  sim:/MTNCL_Control_Unit_Parallelism_On_ID_1_SF_64_by_64_TB/UUT/mtncl_sf_core_instance/sf_data_loader_instance/sf_address_gen_w_mux_instance/*
add wave -position end  sim:/MTNCL_Control_Unit_Parallelism_On_ID_1_SF_64_by_64_TB/UUT/mtncl_sf_core_instance/sf_data_loader_instance/sf_address_gen_w_mux_instance/input_mux_b
add wave -position end  sim:/MTNCL_Control_Unit_Parallelism_On_ID_1_SF_64_by_64_TB/UUT/mtncl_sf_core_instance/sf_core_w_reg_instance_a/*
add wave -position end  sim:/MTNCL_Control_Unit_Parallelism_On_ID_1_SF_64_by_64_TB/UUT/mtncl_sf_core_instance/sf_core_w_reg_instance_b/*
add wave -position end  sim:/MTNCL_Control_Unit_Parallelism_On_ID_1_SF_64_by_64_TB/UUT/mtncl_sf_core_instance/sf_core_data_output/*
run 850 us
