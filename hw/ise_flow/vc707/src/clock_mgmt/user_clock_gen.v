///////////////////////////////////////////////////////////////////////////////
//    
//    Company:          Xilinx
//    Engineer:         Karl Kurbjun
//    Date:             12/7/2009
//    Design Name:      MMCM DRP
//    Module Name:      user_clock_gen.v
//    Version:          2.0
//    Target Devices:   Virtex 6 Family
//    Tool versions:    L.50 (lin)
//    Description:      This is a basic demonstration of the MMCM_DRP 
//                      connectivity to the MMCM_ADV.
//
//    Revision          Updated to support upto 4 frequencies. K. Vipin
// 
//    Disclaimer:  XILINX IS PROVIDING THIS DESIGN, CODE, OR
//                 INFORMATION "AS IS" SOLELY FOR USE IN DEVELOPING
//                 PROGRAMS AND SOLUTIONS FOR XILINX DEVICES.  BY
//                 PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
//                 ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,
//                 APPLICATION OR STANDARD, XILINX IS MAKING NO
//                 REPRESENTATION THAT THIS IMPLEMENTATION IS FREE
//                 FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE
//                 RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY
//                 REQUIRE FOR YOUR IMPLEMENTATION.  XILINX
//                 EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH
//                 RESPECT TO THE ADEQUACY OF THE IMPLEMENTATION,
//                 INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR
//                 REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE
//                 FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES
//                 OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
//                 PURPOSE.
// 
//                 (c) Copyright 2009-1010 Xilinx, Inc.
//                 All rights reserved.
// 
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
//   Revision  :  1.0
//   Author    :  Vipin K
//   Change    :  Updated the design to support 4 reconfigurations for clock0
//////////////////////////////////////////////////////////////////////////////

`timescale 1ps/1ps

module user_clock_gen 
   (
	   input       DRP_CLK,
      // SSTEP is the input to start a reconfiguration.  It should only be
      // pulsed for one clock cycle.
      input       SSTEP,
      // STATE determines which state the MMCM_ADV will be reconfigured to.  A 
      // value of 0 correlates to state 1, and a value of 1 correlates to state 
      // 2.
      input [1:0] STATE,

      // RST will reset the entire reference design including the MMCM_ADV
      input       RST,
      // CLKIN is the input clock that feeds the MMCM_ADV CLKIN as well as the
      // clock for the MMCM_DRP module
      input       CLKIN,

      // SRDY pulses for one clock cycle after the MMCM_ADV is locked and the 
      // MMCM_DRP module is ready to start another re-configuration
      output      SRDY,
      
      // These are the clock outputs from the MMCM_ADV.
      output      CLK0OUT
   );
   
   // These signals are used as direct connections between the MMCM_ADV and the
   // MMCM_DRP.
   wire [15:0]    di;
   wire [6:0]     daddr;
   wire [15:0]    dout;
   wire           den;
   wire           dwe;
   wire           dclk;
   wire           rst_mmcm;
   wire           drdy;
   wire           locked;
   
   // These signals are used for the BUFG's necessary for the design.
   wire           clkin_bufgout;
   
   wire           clkfb_bufgout;
   wire           clkfb_bufgin;
   
   wire           clk0_bufgin;
   wire           clk0_bufgout;
   
   BUFG BUFG_FB (
      .O(clkfb_bufgout),
      .I(clkfb_bufgin) 
   );
   
   BUFG BUFG_CLK0 (
      .O(CLK0OUT),
      .I(clk0_bufgin) 
   );
      
   
   // MMCM_ADV that reconfiguration will take place on
   MMCM_ADV #(
    .BANDWIDTH            ("OPTIMIZED"),
    .CLKOUT4_CASCADE      ("FALSE"),
    .CLOCK_HOLD           ("FALSE"),
    .COMPENSATION         ("ZHOLD"),
    .STARTUP_WAIT         ("FALSE"),
    .DIVCLK_DIVIDE        (2),
    .CLKFBOUT_MULT_F      (8.000),
    .CLKFBOUT_PHASE       (0.000),
    .CLKFBOUT_USE_FINE_PS ("FALSE"),
    .CLKOUT0_DIVIDE_F     (4.000),
    .CLKOUT0_PHASE        (0.000),
    .CLKOUT0_DUTY_CYCLE   (0.500),
    .CLKOUT0_USE_FINE_PS  ("FALSE"),
    .CLKOUT1_DIVIDE       (5),
    .CLKOUT1_PHASE        (0.000),
    .CLKOUT1_DUTY_CYCLE   (0.500),
    .CLKOUT1_USE_FINE_PS  ("FALSE"),
    .CLKOUT2_DIVIDE       (7),
    .CLKOUT2_PHASE        (0.000),
    .CLKOUT2_DUTY_CYCLE   (0.500),
    .CLKOUT2_USE_FINE_PS  ("FALSE"),
    .CLKOUT3_DIVIDE       (10),
    .CLKOUT3_PHASE        (0.000),
    .CLKOUT3_DUTY_CYCLE   (0.500),
    .CLKOUT3_USE_FINE_PS  ("FALSE"),
    .CLKIN1_PERIOD        (4.000),
    .REF_JITTER1          (0.010)
   ) mmcm_inst (
      .CLKFBOUT(clkfb_bufgin),
      .CLKFBOUTB(),     
      .CLKFBSTOPPED(),
      .CLKINSTOPPED(),
      // Clock outputs
      .CLKOUT0(clk0_bufgin), 
      .CLKOUT0B(),
      .CLKOUT1(),
      .CLKOUT1B(),
      // DRP Ports
      .DO(dout), // (16-bits)
      .DRDY(drdy), 
      .DADDR(daddr), // 5 bits
      .DCLK(dclk), 
      .DEN(den), 
      .DI(di), // 16 bits
      .DWE(dwe), 
      .LOCKED(locked), 
      .CLKFBIN(clkfb_bufgout), 
      // Clock inputs
      .CLKIN1(CLKIN),
      .CLKIN2(),
      .CLKINSEL(1'b1),
      // Fine phase shifting
      .PSDONE(),
      .PSCLK(1'b0),
      .PSEN(1'b0),
      .PSINCDEC(1'b0), 
      .PWRDWN(1'b0),
      .RST(rst_mmcm)
   );
   // MMCM_DRP instance that will perform the reconfiguration operations
   mmcm_drp #(
      //***********************************************************************
      // State 1 Parameters - These are for the first reconfiguration state.
      //***********************************************************************
      // Set the multiply to 5 with 0 deg phase offset, low bandwidth, input
      // divide of 1
      .S1_CLKFBOUT_MULT(8),
      .S1_CLKFBOUT_PHASE(0),
      .S1_BANDWIDTH("LOW"),
      .S1_DIVCLK_DIVIDE(2),
      
      // Set clock out 0 to a divide of 5, 0deg phase offset, 50/50 duty cycle
      .S1_CLKOUT0_DIVIDE(4),
      .S1_CLKOUT0_PHASE(00000),
      .S1_CLKOUT0_DUTY(50000),
      
      //***********************************************************************
      // State 2 Parameters - These are for the second reconfiguration state.
      //***********************************************************************

      .S2_CLKFBOUT_MULT(8),
      .S2_CLKFBOUT_PHASE(0),
      .S2_BANDWIDTH("LOW"),
      .S2_DIVCLK_DIVIDE(2),

      .S2_CLKOUT0_DIVIDE(5),
      .S2_CLKOUT0_PHASE(0),
      .S2_CLKOUT0_DUTY(50000),

      //***********************************************************************
      // State 3 Parameters - These are for the second reconfiguration state.
      //***********************************************************************

      .S3_CLKFBOUT_MULT(8),
      .S3_CLKFBOUT_PHASE(0),
      .S3_BANDWIDTH("LOW"),
      .S3_DIVCLK_DIVIDE(2),

      .S3_CLKOUT0_DIVIDE(7),
      .S3_CLKOUT0_PHASE(0),
      .S3_CLKOUT0_DUTY(50000),

      //***********************************************************************
      // State 4 Parameters - These are for the second reconfiguration state.
      //***********************************************************************


      .S4_CLKFBOUT_MULT(8),
      .S4_CLKFBOUT_PHASE(0),
      .S4_BANDWIDTH("LOW"),
      .S4_DIVCLK_DIVIDE(2),

      .S4_CLKOUT0_DIVIDE(10),
      .S4_CLKOUT0_PHASE(0),
      .S4_CLKOUT0_DUTY(50000)

   ) mmcm_drp_inst (
      // Top port connections
      .SADDR(STATE),
      .SEN(SSTEP),
      .RST(RST),
      .SRDY(SRDY), 
      // Input from IBUFG
      .SCLK(DRP_CLK),
      // Direct connections to the MMCM_ADV
      .DO(dout),
      .DRDY(drdy),
      .LOCKED(locked),
      .DWE(dwe),
      .DEN(den),
      .DADDR(daddr),
      .DI(di),
      .DCLK(dclk),
      .RST_MMCM(rst_mmcm)
   );
endmodule
