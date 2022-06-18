##############################################################################
#                                                                            #
#                               READ DESIGN RTL                              #
#                                                                            #
##############################################################################

#Cleanup the directory to avoid using old files
file delete -force -- WORK
foreach filepath [glob -nocomplain *.v] {file delete $filepath}
foreach filepath [glob -nocomplain *.ddc] {file delete $filepath}

set verilogout_single_bit true

#Setting the design name
set DESIGN_NAME      "MTNCL_SF_Core_Address_Gen_w_MUX" ;#change here for future designs

#Setting the design paths
source ../../gpu_read_var.tcl

#Sourcing the vhdl files
#Sourcing the basic vhdl files
set RTL_SOURCE_FILES "$ASYNC_PATH"
append RTL_SOURCE_FILES "NCL_signals.vhd"
set RTL_SOURCE_FILES "$RTL_SOURCE_FILES $ASYNC_PATH"
append RTL_SOURCE_FILES "MTNCL_package.vhd"
set RTL_SOURCE_FILES "$RTL_SOURCE_FILES $HDL_PATH"
append RTL_SOURCE_FILES "MTNCL_treecomps.vhd"
set RTL_SOURCE_FILES "$RTL_SOURCE_FILES $ASYNC_PATH"
append RTL_SOURCE_FILES "MTNCL_completion.vhd"
#Sourcing the project's basic files
set RTL_SOURCE_FILES "$RTL_SOURCE_FILES $HDL_PATH"
append RTL_SOURCE_FILES "mux_nto1_gen.vhd"
set RTL_SOURCE_FILES "$RTL_SOURCE_FILES $HDL_PATH"
append RTL_SOURCE_FILES "MUX21_A_GATEIMPLEMENTATION.vhd"
#Sourcing OAAT designs
set RTL_SOURCE_FILES "$RTL_SOURCE_FILES $OAAT_PATH"
append RTL_SOURCE_FILES "OAAT_reg_gen.vhd"
set RTL_SOURCE_FILES "$RTL_SOURCE_FILES $CORES_PATH"
append RTL_SOURCE_FILES "MTNCL_SF_Core_Address_Gen_w_MUX.vhd"

set_svf ./results/$DESIGN_NAME.svf
define_design_lib WORK -path ./WORK
read_file -format VHDL $RTL_SOURCE_FILES
#elaborate $DESIGN_NAME
#link

# Check design structure after reading verilog
current_design $DESIGN_NAME
redirect ./results/report.check {check_design}

#VIP:Flatten the design
ungroup -all -flatten

#Output the netlist to a verilog file
write -format verilog -hierarchy

#Output important reports that describe the design
#Output information about the cells used and where they were used
report_cell	 	> report_cell
#Output information about all the nets in the design
report_net	 	> report_net
#Output information about the ports like input/output (Good to know the signal direction instead of going back to the original vhdl files)
report_port		> report_port
#Output information about the total number of ports/nets/cells/references (Good to estimate the total area of the design)
report_area		> report_area
#Output information about the cells used in the entire design along with the count (Good to check the naming of each of the cell if they don't match with our cell library)
report_reference	> report_reference

#ADVICE: Comment out the exit command when testing to avoid exiting out Design Vision/Compiler 
exit
