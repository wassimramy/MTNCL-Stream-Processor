source base.do
vcom -reportprogress 300 -work work $control_unit_testbench/MTNCL_Control_Unit_HEQ_64_by_64_TB.vhd

vsim -voptargs=+acc=lr work.MTNCL_Control_Unit_HEQ_64_by_64_TB -t ps -novopt
add wave -position end  sim:/MTNCL_Control_Unit_HEQ_64_by_64_TB/*
add wave -position end  sim:/MTNCL_Control_Unit_HEQ_64_by_64_TB/UUT/*
add wave -position end  sim:/MTNCL_Control_Unit_HEQ_64_by_64_TB/UUT/mtncl_heq_instance/*
run 550 us
