source base.do
vcom -reportprogress 300 -work work $individual_cores_testbench/MTNCL_Histogram_Equalization_8_by_8_TB.vhd

vsim -voptargs=+acc work.MTNCL_Histogram_Equalization_8_by_8_TB -t ps -novopt
add wave -position end  sim:/MTNCL_Histogram_Equalization_8_by_8_TB/*
run 50 us
