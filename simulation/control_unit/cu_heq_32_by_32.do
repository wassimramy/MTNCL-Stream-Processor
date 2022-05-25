source base.do
vcom -reportprogress 300 -work work $control_unit_testbench/MTNCL_Control_Unit_HEQ_32_by_32_TB.vhd

vsim -voptargs=+acc=lr work.MTNCL_Control_Unit_HEQ_32_by_32_TB -t ps -novopt
add wave -position end  sim:/MTNCL_Control_Unit_HEQ_32_by_32_TB/*
add wave -position end  sim:/MTNCL_Control_Unit_HEQ_32_by_32_TB/UUT/*
add wave -position end  sim:/MTNCL_Control_Unit_HEQ_32_by_32_TB/UUT/mtncl_heq_instance/*
run 200 us
