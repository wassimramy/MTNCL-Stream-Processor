source base.do
vcom -reportprogress 300 -work work $control_unit_testbench/MTNCL_Control_Unit_Top_Level_Parallelism_On_SF_64_by_64_TB.vhd

vsim -voptargs=+acc work.MTNCL_Control_Unit_Top_Level_parallelism_on_sf_64_by_64_TB -t ps -novopt
add wave -position end  sim:/MTNCL_Control_Unit_Top_Level_parallelism_on_sf_64_by_64_TB/*
add wave -position end  sim:/MTNCL_Control_Unit_Top_Level_parallelism_on_sf_64_by_64_TB/UUT/*
run 1100 us
