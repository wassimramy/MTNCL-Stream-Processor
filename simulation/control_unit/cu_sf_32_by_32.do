source base.do
vcom -reportprogress 300 -work work $control_unit_testbench/MTNCL_Control_Unit_SF_32_by_32_TB.vhd

vsim -voptargs=+acc work.MTNCL_Control_Unit_sf_32_by_32_TB -t ps -novopt
add wave -position end  sim:/MTNCL_Control_Unit_sf_32_by_32_TB/*
run 460 us
