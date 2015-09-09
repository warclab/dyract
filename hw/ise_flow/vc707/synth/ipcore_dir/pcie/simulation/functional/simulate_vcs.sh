#!/bin/sh

#
# PCI Express Endpoint VCS Run Script
#

/bin/rm *.dat
/bin/rm *.log
/bin/rm vcs.key
/bin/rm -rf simv*
/bin/rm -rf csrc


vcs   +alwaystrigger +v2k +cli \
      -PP \
      -lca \
      +libext+.v   \
      +define+VCS \
      +define+SIMULATION \
      +incdir+../+../tests+../dsport \
      -f xilinx_lib_vcs.f \
      -f board.f \
      -l vcs_log.log
if (test -e ./simv); then
#  ./simv +TESTNAME=sample_smoke_test0 +dump_all
  ./simv +TESTNAME=pio_writeReadBack_test0 +dump_all
fi
