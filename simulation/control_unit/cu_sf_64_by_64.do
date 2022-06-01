source base.do
vcom -reportprogress 300 -work work $control_unit_testbench/MTNCL_Control_Unit_SF_64_by_64_TB.vhd

vsim -voptargs=+acc work.MTNCL_Control_Unit_SF_64_by_64_TB -t ps -novopt
add wave -position end  sim:/MTNCL_Control_Unit_SF_64_by_64_TB/*
add wave -position end  sim:/MTNCL_Control_Unit_SF_64_by_64_TB/UUT/mtncl_sf_core_instance/*
run 1840 us
