
@echo off
ECHO
ECHO Compile all of the files
vlogcomp -work work -d SIMULATION -i ..\ -i ..\tests -i ..\dsport --incremental -f board.f
vlogcomp -work work %XILINX%\verilog\src\glbl.v

ECHO
ECHO
ECHO Compile and link source files
fuse.exe work.board work.glbl -d SIMULATION -L unisims_ver -L unimacro_ver -L unisim -L unimacro -L secureip -o demo_tb.exe

ECHO set BATCH_MODE=0 to run simulation in GUI mode
ECHO
set BATCH_MODE=1

if "%BATCH_MODE%" == "1" (

ECHO Running batch mode . . .
demo_tb.exe -wdb wave_isim -tclbatch isim_cmd.tcl -testplusarg TESTNAME=pio_writeReadBack_test0

) else (

ECHO Starting simulation GUI . . .
demo_tb.exe -gui -view wave.wcfg -wdb wave_isim -tclbatch isim_cmd.tcl -testplusarg TESTNAME=pio_writeReadBack_test0

)

