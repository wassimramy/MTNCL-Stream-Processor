source base.do
vcom -reportprogress 300 -work work $control_unit_testbench/tb_MTNCL_CU_HEQ_64_by_64_image_store_load.vhd

vsim -voptargs=+acc=lr work.tb_MTNCL_CU_HEQ_64_by_64_image_store_load -t ps -novopt
add wave -position end  sim:/tb_MTNCL_CU_HEQ_64_by_64_image_store_load/*
add wave -position end  sim:/tb_MTNCL_CU_HEQ_64_by_64_image_store_load/UUT/*
add wave -position end  sim:/tb_MTNCL_CU_HEQ_64_by_64_image_store_load/UUT/image_store_load_instance/*
add wave -position end  sim:/tb_MTNCL_CU_HEQ_64_by_64_image_store_load/UUT/control_unit_instance/*
add wave -position end  sim:/tb_MTNCL_CU_HEQ_64_by_64_image_store_load/UUT/control_unit_instance/mtncl_heq_instance/*
run 1840 us
