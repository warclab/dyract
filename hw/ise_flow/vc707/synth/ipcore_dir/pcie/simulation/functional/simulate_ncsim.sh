#!/bin/sh

#
# PCI Express Endpoint NC Verilog Run Script
# 
##################################################################################################################
#
# NOTE: To run the simulations using this script please follow the steps below
# These should be performed before executing the script 
#
# 1. Copy the cds.lib file into the simulation/functional directory. This should be available in IUS installation area 
# 2. Copy the hdl.var file into the simulation/functional directory. This should be available in IUS installation area 
# 3. Add the following 2 lines in the cds.lib file
#    UNDEFINE work 
#    DEFINE work ./work
#
##################################################################################################################

rm -rf INCA* work

mkdir work


ncvlog    -work work -define NCV \
          -define SIMULATION \
	  $XILINX/verilog/src/glbl.v \
	  -f $XILINX/secureip/ncsim/ncsim_secureip_cell.list.f \
          -y ${XILINX}/verilog/src/unisims  \
          -y ${XILINX}/verilog/src/simprims \
          -y ${XILINX}/verilog/src/unimacro \
          -file board.f \
          -incdir ../ -incdir ../tests -incdir ../dsport

ncelab -access +rwc -timescale 1ns/1ps \
work.board work.glbl
ncsim work.board
