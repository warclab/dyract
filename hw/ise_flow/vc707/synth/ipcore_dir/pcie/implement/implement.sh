#!/bin/sh

# Clean up the results directory
rm -rf results
mkdir results

#Synthesize the Wrapper Files
echo 'Synthesizing example design with XST';
xst -ifn xilinx_pcie_2_1_ep_7x.xst -ofn xilinx_pcie_2_1_ep_7x.log

cp xilinx_pcie_2_1_ep_7x.ngc ./results/

cp xilinx_pcie_2_1_ep_7x.log xst.srp

rm -rf *.mgo xlnx_auto_0_xdb xlnx_auto_0.ise netlist.lst smart

cd results

echo 'Running ngdbuild'
ngdbuild -verbose -uc ../../example_design/xilinx_pcie_2_1_ep_7x_08_lane_gen2_xc7vx485t-ffg1761-2-PCIE_X1Y0.ucf xilinx_pcie_2_1_ep_7x.ngc -sd .


echo 'Running map'
map -w \
  -register_duplication on \
  -ol high \
  -o mapped.ncd \
  xilinx_pcie_2_1_ep_7x.ngd \
  mapped.pcf

echo 'Running par'
par \
  -ol high \
  -w mapped.ncd \
  routed.ncd \
  mapped.pcf

echo 'Running trce'
trce -u -e 100 \
  routed.ncd \
  mapped.pcf

echo 'Running design through netgen'
netgen -sim -ofmt verilog -ne -w -tm xilinx_pcie_2_1_ep_7x -sdf_path . routed.ncd

# Uncomment to enable Bitgen.  To generate a bitfile, all I/O must be LOC'd to pin.
# Refer to AR 41615 for more information
#echo 'Running design through bitgen'
#bitgen -w routed.ncd

 
