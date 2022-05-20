source base.do
vcom -reportprogress 300 -work work $individual_cores_testbench/MTNCL_SF_Node_W_Registers_64_by_64_TB.vhd

vsim -voptargs=+acc work.MTNCL_SF_Node_W_Registers_TB -t ps -novopt
add wave -position end  sim:/MTNCL_SF_Node_W_Registers_TB/*
run 1840 us
