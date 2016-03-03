CHANGE LOG for 7 Series Integrated Block for PCI Express V1.10

Release Date: June 19, 2013
--------------------------------------------------------------------------------

Table of Contents

1. INTRODUCTION
2. DEVICE SUPPORT
3. NEW FEATURE HISTORY
4. RESOLVED ISSUES
5. KNOWN ISSUES & LIMITATIONS
6. TECHNICAL SUPPORT & FEEDBACK
7. CORE RELEASE HISTORY
8. LEGAL DISCLAIMER

--------------------------------------------------------------------------------


1. INTRODUCTION

For installation instructions for this release, please go to:

  http://www.xilinx.com/ipcenter/coregen/ip_update_install_instructions.htm

For system requirements:

   http://www.xilinx.com/ipcenter/coregen/ip_update_system_requirements.htm

This file contains release notes for the 7 Series Integrated Block for
PCI Express v2.0 solution. For the latest core updates, see the product page at:

  http://www.xilinx.com/products/intellectual-property/7_SERIES_PCI_Express_Block.htm


2. DEVICE SUPPORT

   The following device families are supported by the core for this release.
  
   Virtex-7
   Kintext-7
   Artix-7
   Zynq-7000
  
   SSIT devices are not supported.  Customers wishing to target SSIT devices (2000T) must
   use Vivado development environment.
  

3. NEW FEATURE HISTORY

  - None -

4. RESOLVED ISSUES

  - For x8g1, 128-bit interface width configuration, Removed the optional 250MHz. Updated the Auto-upgrade script
  - Added PCIE_EXT_CLK and AER_CAP_ECRC_GEN_CAPABLE user parameters to GUI 
  - Marked Artix7 (fgg484 and fbg484) and Zynq devices as production. Added GES_and_Production option for Silicon_Rev parameter.
  - Added support for Artix7 and Kintex7 Lowvoltage family
  - Fixed CDC issues with GT wrappers
  - Fixed the issue with the Legacy End point device (CR # 692331)

  The following are known issues for v1.10 of this core at time of release:

5. KNOWN ISSUES & LIMITATIONS

  - (Xilinx Answer 47626) - (ISE 14.1/Vivado 2012.1) -VHDL Simulation Support in Endpoint Configuration 
  - (Xilinx Answer 50835) - (ISE 14.2/Vivado 2012.2) - VHDL simulation support for Root Port Configuration
  - (Xilinx Answer 47628) - (ISE 14.1 / Vivado 2012.1 - Timing Violations in Certain IP Configurations  
  - (Xilinx Answer 44681) - Is Synplify supported (supported only for Verilog version)                                 
  - (Xilinx Answer 44682) - VHDL Flow Does Not Produce VHDL for MGT Wrapper Files
  - (Xilinx Answer 52441) - (ISE 14.3) Tandem PROM support for Kintex 410T is removed

The most recent information, including known issues, workarounds, and
resolutions for this version is provided in the IP Release Notes Guide
located at

  http://www.xilinx.com/support/documentation/user_guides/xtp025.pdf


6. TECHNICAL SUPPORT & FEEDBACK

To obtain technical support, create a WebCase at www.xilinx.com/support.
Questions are routed to a team with expertise using this product.

Xilinx provides technical support for use of this product when used
according to the guidelines described in the core documentation, and
cannot guarantee timing, functionality, or support of this product for
designs that do not follow specified guidelines.

OTHER INFORMATION

  -ID Initial Values
    ID Initial Values have been changed from attributes to pins.
    Setting the ID initial values from the CORE Generator GUI will now drive
    corresponding values to pins on the PCIe Hardblock.  Users may change the
    values driven on these pins after a core has been generated.

    Pin Names:
      cfg_vend_id[15:0]
      cfg_dev_id[15:0]
      cfg_rev_id[7:0]
      cfg_subsys_vend_id[15:0]
      cfg_subsys_id[15:0]

  - Receive Non-Posted Request (Non-Posted Flow Control)
    To prevent the user application from having to buffer Non-Posted TLPs a
    new signal rx_np_req has been added. When asserted, requests one
    Non-Posted TLP from the Block. This signal cannot be used in conjunction
    with rx_np_ok. The difference between rx_np_req and rx_np_ok is that with
    rx_np_req each assertion will result in one TLP being presented on the
    receive interface. While with rx_np_ok, the user application will need to
    buffer up to 2 additional Non Posted TLPs when this signal is deasserted.

  - Device Capability 2 Register (PCIe spec 2.1)
    Support for PCIe spec 2.1 specific Device Capability 2 Register settings is
    available via the Configuration Register Settings section in the Core
    Customization GUI. These settings are related to Atomic TLP support. The
    customizable settings are:
       - UR Atomic
       - 32-bit and 64-bit AtomicOp Completer Support
       - 128-bit CAS Completer Support
       - TPH Completer Support

  - Link Capabilities Register (PCIe spec 2.1 ASPM Optionality ECN)
    The following PCIe spec 2.1 ASPM Optionality ECN settings are now
    customizable via the Configuration Register Settings section .

    ASPM Optionality
    Surprise Down Error Capable

  - Extended Cap Structure: Advanced Error Reporting(AER)
    The customizable features for this PCI Express Extended Capability
    Structure are:
  - ECRC Check Capable : Indicates the core is capable of checking ECRC
  - AER Multiheader : Will cause core to buffer several headers for AER
    header log field
  - Permit Root Error Update : If TRUE, permits the AER Root Status and
    Error Source ID reg to be updated. If FALSE, these registers are
    forced to 0.
  - Optional Error Support : Indicates which optional error conditions in the
    Uncorrectable and Correctable Error Mask/Severity registers are
    supported. If an error is unsupported, then the corresponding bit in
    the Mask/Severity register is hardwired to 0. The following options
    are customizable:
  - Correctable Internal Error
  - Completion Timeout
  - Uncorrectable Internal Error
  - Header Log Overflow
  - Completer Abort
  - MC Blocked TLP
  - Receiver Error
  - Receiver Overflow
  - AtomicOp Egress Blocked
  - Surprise Down
  - ECRC Error
  - TLP Prefix Blocked
  - Flow Control Protocol Error
  - ACS Violation
  - Extended Cap Structure: Re-sizable BAR (RBAR)
    The customizable features for this PCI Express Extended Capability
    Structure are:
  - Number of Re-sizable BARs in the Cap Structure, which depends on the
    number of BARs enabled.
  - RBAR Size Supported vector for RBAR Capability Register (0 - 5)
  - RBAR Index Value : Sets the Index of the Re-sizable BAR from among the
    enabled BARs.
  - RBAR Initial Value for RBAR Control BAR Size field.
  - New checks
  - Receive ECRC Check: Enables ECRC check on received TLPs.
    0 = do not check, 1 = always check, 3 = check if enabled by ECRC check
    enable bit of AER Capability Structure.
  - Received ECRC Check Trim : Enables TD bit clear and ECRC trim on
    received TLPs.
  - Disable RX Poisoned Resp : Disable message and status bit response due
    to receiving a Poisoned TLP.


7. CORE RELEASE HISTORY

Date        By            Version      Description
==================================================================================
04/03/2013  Xilinx, Inc.  1.10         ISE 14.6 software support

04/03/2013  Xilinx, Inc.  1.9          ISE 14.5 software support

12/18/2012  Xilinx, Inc.  1.8          ISE 14.4 software support and Vivado 2012.4

10/16/2012  Xilinx, Inc.  1.7          ISE 14.3 software support and Vivado 2012.3

07/25/2012  Xilinx, Inc.  1.6          ISE 14.2 software support and Vivado 2012.2

04/24/2012  Xilinx, Inc.  1.4          ISE 14.1 software support. Artix-7 Support

01/18/2012  Xilinx, Inc.  1.3          ISE 13.4 software support. Root Port Support

10/19/2011  Xilinx, Inc.  1.2          ISE 13.3 software support

06/22/2011  Xilinx, Inc.  1.1 Rev1     ISE 13.2 software support

03/01/2011  Xilinx, Inc.  1.1          ISE 13.1 software support

12/10/2010  Xilinx, Inc.  1.1          ISE 7 Series Monthly Snapshot - (O.34)

11/08/2010  Xilinx, Inc.  1.1          ISE 7 Series Monthly Snapshot - (O.28)

10/29/2010  Xilinx, Inc.  1.1          ISE 7 Series Monthly Snapshot - (O.28)

08/20/2010  Xilinx, Inc.  1.1          Initial release 13.01 (BETA)
==================================================================================


8. LEGAL DISCLAIMER

(c) Copyright 2004 - 2012 Xilinx, Inc. All rights reserved.

This file contains confidential and proprietary information
of Xilinx, Inc. and is protected under U.S. and
international copyright and other intellectual property
laws.

DISCLAIMER
This disclaimer is not a license and does not grant any
rights to the materials distributed herewith. Except as
otherwise provided in a valid license issued to you by
Xilinx, and to the maximum extent permitted by applicable
law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
(2) Xilinx shall not be liable (whether in contract or tort,
including negligence, or under any other theory of
liability) for any loss or damage of any kind or nature
related to, arising under or in connection with these
materials, including for any direct, or any indirect,
special, incidental, or consequential loss or damage
(including loss of data, profits, goodwill, or any type of
loss or damage suffered as a result of any action brought
by a third party) even if such damage or loss was
reasonably foreseeable or Xilinx had been advised of the
possibility of the same.
 
CRITICAL APPLICATIONS
Xilinx products are not designed or intended to be fail-
safe, or for use in any application requiring fail-safe
performance, such as life-support or safety devices or
systems, Class III medical devices, nuclear facilities,
applications related to the deployment of airbags, or any
other applications that could lead to death, personal
injury, or severe property or environmental damage
(individually and collectively, "Critical
Applications"). Customer assumes the sole risk and 
liability of any use of Xilinx products in Critical
Applications, subject only to applicable laws and
regulations governing limitations on product liability.
 
THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
PART OF THIS FILE AT ALL TIMES.
