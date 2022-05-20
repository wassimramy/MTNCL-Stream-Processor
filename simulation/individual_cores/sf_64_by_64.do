source base.do
vcom -reportprogress 300 -work work $individual_cores_testbench/MTNCL_Smoothing_Filter_64_by_64_TB.vhd

vsim -voptargs=+acc work.MTNCL_Smoothing_Filter_TB -t ps -novopt
add wave -position end  sim:/MTNCL_Smoothing_Filter_TB/*
add wave -position end  sim:/MTNCL_Smoothing_Filter_TB/uut/*
run 1840 us
