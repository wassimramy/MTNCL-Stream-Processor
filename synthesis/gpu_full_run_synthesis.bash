#!/bin/bash

SUB_DIR=""
BUFFERING_CSV="../../buffering_sram.csv"
DESIGN_NAME=""

export SUB_DIR
export BUFFERING_CSV
export DESIGN_NAME

#SU Synthesis
#SUB_DIR="storage_units/"
#DESIGN_NAME="sram_4096w_8b_8m"
#./run_memory_synthesis.bash
#DESIGN_NAME="sram_4096w_8b_8m_wrapper"
#./run_synthesis.bash
#DESIGN_NAME="image_store"
#./run_synthesis.bash
#DESIGN_NAME="image_store_load"
#./run_synthesis.bash

#HEQ Core Synthesis
SUB_DIR="individual_cores/"
#DESIGN_NAME="MTNCL_Shade_Counter"
#./run_synthesis.bash
#DESIGN_NAME="MTNCL_Shade_Calculator"
#./run_synthesis.bash
#DESIGN_NAME="MTNCL_Image_Reconstructor"
#./run_synthesis.bash
#DESIGN_NAME="MTNCL_Histogram_Equalization"
#./run_synthesis.bash

#SF Core Synthesis
SUB_DIR="individual_cores/"
#DESIGN_NAME="MTNCL_SF_Core_Data_Loader"
#./run_synthesis.bash
#DESIGN_NAME="MTNCL_SF_Core_Address_Gen_w_MUX"
#./run_synthesis.bash
#DESIGN_NAME="sf_address_generator"
#./run_synthesis.bash
#DESIGN_NAME="MTNCL_SF_Node_W_Registers"
#./run_synthesis.bash
#DESIGN_NAME="MTNCL_SF_Core_Top_Level"
#./run_synthesis.bash

#SF Core Synthesis
SUB_DIR="control_unit/"
#DESIGN_NAME="MTNCL_Control_Unit"
#./run_synthesis.bash
DESIGN_NAME="MTNCL_Control_Unit_Top_Level"
./run_synthesis.bash
