
vlib work
vmap work


vlog -work work +incdir+../.+../../example_design \
        +define+SIMULATION \
	+incdir+.+../dsport+../tests \
	$env(XILINX)/verilog/src/glbl.v \
      -f board.f

# Load and run simulation
vsim -voptargs="+acc" +notimingchecks +TESTNAME=pio_writeReadBack_test0 -L work -L secureip -L unisims_ver -L unimacro_ver \
     work.board glbl +dump_all


#add log -r /*
run -all
