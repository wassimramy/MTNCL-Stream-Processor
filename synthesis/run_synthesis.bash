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

#Design Flattening
echo "======> Flattening"
/mscad/apps/Linux/synopsys/syn/S-2021.06-SP2/bin/dc_shell -f ../${DESIGN_NAME}_read.tcl

echo "======> Remove WORK Directory"
rm -r WORK

echo "======> Running SingleLinesOnly.py"
python /home/chsherri/bin/From_Brent/SingleLinesOnly/SingleLinesOnly.py $DESIGN_NAME.v

echo "======> Running Clean.jar"
java -jar /home/chsherri/bin/Clean/Clean.jar ${DESIGN_NAME}_lines.v

echo "======> Running Buffering using $BUFFERING_CSV"
java -jar /home/chsherri/bin/Buffering/V1.1.1/Buffering.jar $BUFFERING_CSV ${DESIGN_NAME}_lines_BE.v
mv Buffered.v ${DESIGN_NAME}_lines_BE_buffered.v   

echo "======> Preparing Netlist for Cadence"
java -jar /home/chsherri/bin/PrepareNetlistForCadence/V2.0.5/PrepareNetlistForCadence.jar ${DESIGN_NAME}_lines_BE_buffered.v
#java -jar /home/chsherri/bin/PrepareNetlistForCadence/V2.0.5/PrepareNetlistForCadence.jar ${DESIGN_NAME}_lines_BE.v

#echo "======> Generate Final Netlist"
#python /home/wrkhalil/Programs_and_Scripts/generate_final_netlist.py ${DESIGN_NAME}_lines_BE_buffered_Ready_For_Cadence.v
#python /home/wrkhalil/Programs_and_Scripts/generate_final_netlist.py ${DESIGN_NAME}_lines_BE_Ready_For_Cadence.v
#python /home/wrkhalil/Programs_and_Scripts/generate_final_netlist.py netlist.v

echo "======> Edit the SRAM Sensitivity List"
python /home/wrkhalil/Programs_and_Scripts/memory_sensitivity_list.py ${DESIGN_NAME}_lines_BE_buffered_Ready_For_Cadence.v

#echo "======> Importing to Cadence"
#cd ../../../cadence
#virtuoso -replay import_$DESIGN_NAME.il > Trash.log

#echo "======> Setting up the place and route directory"
#mkdir -p ../../../place_and_route/$SUB_DIR$DESIGN_NAME
#mkdir -p ../../../place_and_route/$SUB_DIR$DESIGN_NAME/innovus
#cp ${DESIGN_NAME}_lines_BE_buffered_Ready_For_Cadence.v ../../../place_and_route/$SUB_DIR${DESIGN_NAME}/${DESIGN_NAME}_lines_BE_buffered_Ready_For_Cadence.v 

now=$(date +"%T")
echo "===========> $DESIGN_NAME is completed at $now"
echo
