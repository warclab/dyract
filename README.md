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

Hardware Implementation
-----------------------

The custom accelerator (or any hardware) implemented by the user will be implemented as a reconfigurable module.
This custom hardware will be called *user logic* for easer reference.
The FPGA is pre-partitioned to enable implementing user logic in a reconfigurable region (PRR).
This enables swapping in and out different user logic at system run-time using partial reconfiguration (PR).
The user logic may have a single AXI-Lite interface and up to 4 AXI4-Stream interfaces.
The port naming for it should follow the naming conventions given in the wrapper module located at hw\ml605\src\user_logic_if\user_logic_bb.v.
Users can integrate user logic with the DyRACT hardware platform by following Xilinx PlanAhead PR implementation flow or by simply running the scripts provided in the hw\"board"\script directory.
While using the scripts, the netlist corresponding the user logic should be in the (user_logic.ngc) script directory.
Presently an example netlist is provided in the directory.
It should be replaced by the specific netlist required by the user.
The netlist can be generated using Xilinx XST based on the user logic HDL written in Verilog or VHDL.
If XST is used, the IO buffers should be disabled when generating the netlist.