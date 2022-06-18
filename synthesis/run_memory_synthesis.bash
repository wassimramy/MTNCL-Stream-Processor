#!/bin/bash

echo
now=$(date +"%T")
echo "===========> Running $DESIGN_NAME at $now"

#Create a directory named after the design name where all the files will be output
echo "======> Setting up the synthesis directory"
mkdir -p $SUB_DIR$DESIGN_NAME
cd $SUB_DIR$DESIGN_NAME
currentPath=$(pwd)
echo $currentPath

echo "======> Creating CDL Netlist"
/home/wrkhalil/Projects/Memory_Compiler/GP/arm/tsmc/cln65gplus/sram_sp_hdc_svt_rvt_hvt/r0p0-00eac0/bin/sram_sp_hdc_svt_rvt_hvt lvs -instname "$DESIGN_NAME" -words 4096 -bits 8 -frequency 1 -mux 8 -pipeline off -write_mask off -wp_size 8 -write_thru on -top_layer "m5-m9" -power_type otc -redundancy off -rcols 2 -rrows 2 -bmux off -ser none -back_biasing off -power_gating off -retention on -ema on -atf off -cust_comment "" -bus_notation off -left_bus_delim "<" -right_bus_delim ">" -pwr_gnd_rename "VDDPE:VDDPE,VDDCE:VDDCE,VSSE:VSSE" -prefix "" -name_case upper -check_instname off -diodes on -drive 6 -dnw off -asvm on -corners ff_1p10v_1p10v_m40c,ff_1p10v_1p10v_0c,ff_1p10v_1p10v_125c,tt_1p00v_1p00v_25c,ss_0p90v_0p90v_m40c,ss_0p90v_0p90v_125c

echo "======> SYK Netlist Edit"
python /home/wrkhalil/Programs_and_Scripts/LVSsram.py $DESIGN_NAME.cdl

echo "======> Remove SR Devices"
python /home/wrkhalil/Programs_and_Scripts/remove_sram_weird_devices_cdl.py netlist

echo "======> Importing to Cadence"
cd ../../../cadence
virtuoso -replay import_$DESIGN_NAME.il > Trash.log

#/home/wrkhalil/Projects/Memory_Compiler/GP/arm/tsmc/cln65gplus/sram_sp_hdc_svt_rvt_hvt/r0p0-00eac0/bin/sram_sp_hdc_svt_rvt_hvt gds2 -instname "sram_4096w_8b_8m" -words 4096 -bits 8 -frequency 1 -mux 8 -pipeline off -write_mask off -wp_size 8 -write_thru on -top_layer "m5-m9" -power_type otc -redundancy off -rcols 2 -rrows 2 -bmux off -ser none -back_biasing off -power_gating off -retention on -ema on -atf off -cust_comment "" -bus_notation on -left_bus_delim "[" -right_bus_delim "]" -pwr_gnd_rename "VDDPE:VDDPE,VDDCE:VDDCE,VSSE:VSSE" -prefix "" -name_case upper -check_instname off -diodes on -drive 6 -dnw off -asvm on -corners ff_1p10v_1p10v_m40c,ff_1p10v_1p10v_0c,ff_1p10v_1p10v_125c,tt_1p00v_1p00v_25c,ss_0p90v_0p90v_m40c,ss_0p90v_0p90v_125c

#echo "======> Setting up the place and route directory"
#mkdir -p ../../../place_and_route/$SUB_DIR$DESIGN_NAME
#mkdir -p ../../../place_and_route/$SUB_DIR$DESIGN_NAME/innovus
#cp ${DESIGN_NAME}_lines_BE_buffered_Ready_For_Cadence.v ../../../place_and_route/$SUB_DIR${DESIGN_NAME}/${DESIGN_NAME}_lines_BE_buffered_Ready_For_Cadence.v 

now=$(date +"%T")
echo "===========> $DESIGN_NAME is completed at $now"
echo
