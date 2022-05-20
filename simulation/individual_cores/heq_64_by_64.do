source base.do
vcom -reportprogress 300 -work work $individual_cores_testbench/MTNCL_Histogram_Equalization_64_by_64_TB.vhd

vsim -voptargs=+acc work.MTNCL_Histogram_Equalization_TB -t ps -novopt
add wave -position end  sim:/MTNCL_Histogram_Equalization_TB/*
add wave -position end  sim:/MTNCL_Histogram_Equalization_TB/UUT/*
run 750 us
