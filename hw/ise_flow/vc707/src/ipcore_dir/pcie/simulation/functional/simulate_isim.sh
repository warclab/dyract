#!/bin/sh

# compile all of the files
vlogcomp -work work -d SIMULATION -i ../ -i ../tests -i ../dsport --incremental -f board.f
vlogcomp -work work $XILINX/verilog/src/glbl.v

# compile and link source files
fuse work.board work.glbl -d SIMULATION -L unisims_ver -L unimacro_ver -L unisim -L unimacro -L secureip -o demo_tb

# set BATCH_MODE=0 to run simulation in GUI mode
BATCH_MODE=1

if [ $BATCH_MODE == 1 ]; then

  # run the simulation in batch mode
  ./demo_tb -wdb wave_isim -tclbatch isim_cmd.tcl -testplusarg TESTNAME=pio_writeReadBack_test0

else

  # run the simulation in gui mode
  ./demo_tb -gui -view wave.wcfg -wdb wave_isim -tclbatch isim_cmd.tcl -testplusarg TESTNAME=pio_writeReadBack_test0

fi
