dyract
======

DyRACT enables easier integration of FPGA based accelerators with computers.
This enables using FPGAs in software application flow as well as faster prototyping of FPGA design.
One of the major attractions of DyRACT is its ability to partially reconfigure FPGAs over the PCIe interface.
This enables lower reconfiguration time and removes the requirement of rebooting the system after reconfiguration.
DyRACT open source repository provides the hardware infrastructure integrating the user specific accelerator and the software driver to manage communication as well as reconfiguration.
The hardware platform is presently supported and verified on ML605, VC707 and AC701.
For detailed discussion of its operation, please refer to the document provided in the doc folder.

Installation
------------

DyRACT requires a software driver to manage the PCIe interface which links the FPGA with the computer.
The present driver is supported on Linux kernel version 2.6.
To install the driver, go to the sw/driver directory and use the make file.
Use the following commands for installation.

sudo make setup
make
sudo make install

Implementing hardware
---------------------