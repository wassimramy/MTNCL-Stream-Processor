set storage_units_testbench "../test/storage_units"
set individual_cores_testbench "../test/individual_cores"
set control_unit_testbench "../test/control_unit"
set oaat_testbench "../test/oaat"

vcom -reportprogress 300 -work work ../hdl/async/NCL_signals.vhd
vcom -reportprogress 300 -work work ../hdl/async/NCL_random.vhd
vcom -reportprogress 300 -work work ../hdl/async/NCL_functions.vhd
vcom -reportprogress 300 -work work ../hdl/async/NCL_gates.vhd
vcom -reportprogress 300 -work work ../hdl/async/NCL_components.vhd
vcom -reportprogress 300 -work work ../hdl/async/MTNCL_package.vhd
vcom -reportprogress 300 -work work ../hdl/async/MTNCL_gates.vhd
vcom -reportprogress 300 -work work ../hdl/async/MTNCL_register.vhd
vcom -reportprogress 300 -work work ../hdl/async/MTNCL_completion.vhd

vcom -reportprogress 300 -work work ../hdl/MTNCL_treecomps.vhd

vcom -reportprogress 300 -work work ../hdl/mux_nto1_gen.vhd
vcom -reportprogress 300 -work work ../hdl/MUX21_A_GATEIMPLEMENTATION.vhd
vcom -reportprogress 300 -work work ../hdl/MTNCL_adders.vhd
vcom -reportprogress 300 -work work ../hdl/th22d_tree_gen.vhd
vcom -reportprogress 300 -work work ../hdl/SDC_w_EN.vhd
vcom -reportprogress 300 -work work ../hdl/th22m_en_gen.vhd

vcom -reportprogress 300 -work work ../hdl/OAAT/OAAT_MTNCL_tree_functs.vhd
vcom -reportprogress 300 -work work ../hdl/OAAT/OAAT_Extra_Gates.vhd
vcom -reportprogress 300 -work work ../hdl/OAAT/OAAT_register.vhd
vcom -reportprogress 300 -work work ../hdl/OAAT/OAAT_reg_gen.vhd
vcom -reportprogress 300 -work work ../hdl/OAAT/OAAT_decoder_gen.vhd
vcom -reportprogress 300 -work work ../hdl/OAAT/OAAT_adding_units.vhd
vcom -reportprogress 300 -work work ../hdl/OAAT/OAAT_adder_gen.vhd
vcom -reportprogress 300 -work work ../hdl/OAAT/OAAT_counter_selfReset.vhd
vcom -reportprogress 300 -work work ../hdl/OAAT/OAAT_counter_selfReset_mod_inc.vhd
vcom -reportprogress 300 -work work ../hdl/OAAT/OAAT_in_all_out.vhd
vcom -reportprogress 300 -work work ../hdl/OAAT/OAAT_in_all_out_2047.vhd
vcom -reportprogress 300 -work work ../hdl/OAAT/OAAT_out_all_in.vhd

vcom -reportprogress 300 -work work ../hdl/MTNCL_treecomps.vhd
vcom -reportprogress 300 -work work ../hdl/MUX21_A_GATEIMPLEMENTATION.vhd

vlog -reportprogress 300 -work work ../hdl/storage_units/sram_4096w_8b_8m.v
vcom -reportprogress 300 -work work ../hdl/storage_units/sram_4096w_8b_8m_wrapper.vhd
vcom -reportprogress 300 -work work ../hdl/storage_units/standard_address_generator.vhd
vcom -reportprogress 300 -work work ../hdl/storage_units/sf_address_generator.vhd
vcom -reportprogress 300 -work work ../hdl/storage_units/image_store.vhd
vcom -reportprogress 300 -work work ../hdl/storage_units/image_store_load.vhd

vcom -reportprogress 300 -work work ../hdl/individual_cores/MTNCL_RCA_GEN.vhd
vcom -reportprogress 300 -work work ../hdl/individual_cores/MTNCL_RCA_TREE_GEN.vhd
vcom -reportprogress 300 -work work ../hdl/individual_cores/MTNCL_Rounding_Checker.vhd
vcom -reportprogress 300 -work work ../hdl/individual_cores/MTNCL_SF_Node.vhd
vcom -reportprogress 300 -work work ../hdl/individual_cores/MTNCL_SF_Node_W_Registers.vhd
vcom -reportprogress 300 -work work ../hdl/individual_cores/MTNCL_SF_Core_Address_Gen_w_MUX.vhd
vcom -reportprogress 300 -work work ../hdl/individual_cores/MTNCL_SF_Core_Data_Loader.vhd
vcom -reportprogress 300 -work work ../hdl/individual_cores/MTNCL_SF_Core_Logic.vhd
vcom -reportprogress 300 -work work ../hdl/individual_cores/MTNCL_SF_Core_Data_Output.vhd
vcom -reportprogress 300 -work work ../hdl/individual_cores/MTNCL_SF_Core_w_reg_sram.vhd
vcom -reportprogress 300 -work work ../hdl/individual_cores/MTNCL_SF_Core_Top_Level.vhd
vcom -reportprogress 300 -work work ../hdl/individual_cores/MTNCL_SF_Core_Top_Level_wo_sram.vhd

vcom -reportprogress 300 -work work ../hdl/individual_cores/MTNCL_Shade_Counter.vhd
vcom -reportprogress 300 -work work ../hdl/individual_cores/MTNCL_Shade_Calculator.vhd
vcom -reportprogress 300 -work work ../hdl/individual_cores/MTNCL_Image_Reconstructor.vhd
vcom -reportprogress 300 -work work ../hdl/individual_cores/MTNCL_Histogram_Equalization.vhd
vcom -reportprogress 300 -work work ../hdl/individual_cores/MTNCL_Histogram_Equalization_wo_sram.vhd

vcom -reportprogress 300 -work work ../hdl/control_unit/MTNCL_Control_Unit.vhd
vcom -reportprogress 300 -work work ../hdl/control_unit/MTNCL_CU_Data_Output.vhd
vcom -reportprogress 300 -work work ../hdl/control_unit/MTNCL_Control_Unit_Top_Level.vhd
