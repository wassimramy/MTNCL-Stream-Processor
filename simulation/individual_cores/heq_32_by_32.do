source base.do
vcom -reportprogress 300 -work work $individual_cores_testbench/MTNCL_Histogram_Equalization_32_by_32_TB.vhd

vsim -voptargs=+acc work.MTNCL_Histogram_Equalization_32_by_32_TB -t ps -novopt
add wave -position end  sim:/MTNCL_Histogram_Equalization_32_by_32_TB/*
run 190 us
