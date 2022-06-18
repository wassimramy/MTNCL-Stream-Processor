#!/bin/bash

echo
echo "===========> Running $DESIGN_NAME"

#Create a directory named after the design name where all the files will be output
echo "======> Setting up the synthesis directory"
mkdir -p $SUB_DIR$DESIGN_NAME
cd $SUB_DIR$DESIGN_NAME
currentPath=$(pwd)
echo $currentPath

#Design Flattening
source /home/chsherri/Synopsys/newsynopsys.sh > /dev/null 2>&1 l
echo "======> Flattening"
#Don't forget to edit the read.tcl file according to your design
dc_shell -f ../${DESIGN_NAME}_read.tcl > design_compiler.log

echo "======> Running SingleLinesOnly.py"
python /home/chsherri/bin/From_Brent/SingleLinesOnly/SingleLinesOnly.py $DESIGN_NAME.v

echo "======> Running Clean.jar"
java -jar /home/chsherri/bin/Clean/Clean.jar ${DESIGN_NAME}_lines.v

echo "======> Running Buffering using $BUFFERING_CSV"
java -jar /home/chsherri/bin/Buffering/V1.0.5/Buffering.jar $BUFFERING_CSV ${DESIGN_NAME}_lines_BE.v
mv Buffered.v ${DESIGN_NAME}_lines_BE_buffered.v   

echo "======> Preparing Netlist for Cadence"
java -jar /home/chsherri/bin/PrepareNetlistForCadence/V2.0.5/PrepareNetlistForCadence.jar ${DESIGN_NAME}_lines_BE_buffered.v

echo "======> Setting up the place and route directory"
mkdir -p ../../place_and_route/$DESIGN_NAME
mkdir -p ../../place_and_route/$DESIGN_NAME/innovus
cp ${DESIGN_NAME}_lines_BE_buffered_Ready_For_Cadence.v ../../../place_and_route/${DESIGN_NAME}/${DESIGN_NAME}_lines_BE_buffered_Ready_For_Cadence.v 


echo "===========> $DESIGN_NAME is completed"
echo
