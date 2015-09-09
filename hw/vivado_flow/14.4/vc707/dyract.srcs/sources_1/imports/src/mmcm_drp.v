///////////////////////////////////////////////////////////////////////////////
//    
//    Company:          Xilinx
//    Engineer:         Karl Kurbjun
//    Date:             12/7/2009
//    Design Name:      MMCM DRP
//    Module Name:      mmcm_drp.v
//    Version:          1.2
//    Target Devices:   Virtex 6 Family
//    Tool versions:    L.50 (lin)
//    Description:      This calls the DRP register calculation functions and
//                      provides a state machine to perform MMCM reconfiguration
//                      based on the calulated values stored in a initialized 
//                      ROM.
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
//                 (c) Copyright 2009-2010 Xilinx, Inc.
//                 All rights reserved.
//
///////////////////////////////////////////////////////////////////////////////
//   Revision  :  1.0
//   Author    :  Vipin K
//   Change    :  Updated the design to support 4 reconfigurations for clock0
//////////////////////////////////////////////////////////////////////////////

`timescale 1ps/1ps

module mmcm_drp
   #(
      //***********************************************************************
      // State 1 Parameters - These are for the first reconfiguration state.
      //***********************************************************************
      parameter S1_CLKFBOUT_MULT          = 5,
      parameter S1_CLKFBOUT_PHASE         = 0,
      parameter S1_BANDWIDTH              = "LOW",
      parameter S1_DIVCLK_DIVIDE          = 1,      
      parameter S1_CLKOUT0_DIVIDE         = 1,
      parameter S1_CLKOUT0_PHASE          = 0,
      parameter S1_CLKOUT0_DUTY           = 50000,
      
      //***********************************************************************
      // State 2 Parameters - These are for the second reconfiguration state.
      //***********************************************************************
      parameter S2_CLKFBOUT_MULT          = 5,
      parameter S2_CLKFBOUT_PHASE         = 0,
      parameter S2_BANDWIDTH              = "LOW",
      parameter S2_DIVCLK_DIVIDE          = 1,      
      parameter S2_CLKOUT0_DIVIDE         = 1,
      parameter S2_CLKOUT0_PHASE          = 0,
      parameter S2_CLKOUT0_DUTY           = 50000,

      //***********************************************************************
      // State 3 Parameters - These are for the second reconfiguration state.
      //***********************************************************************
      parameter S3_CLKFBOUT_MULT          = 5,
      parameter S3_CLKFBOUT_PHASE         = 0,
      parameter S3_BANDWIDTH              = "LOW",
      parameter S3_DIVCLK_DIVIDE          = 1,
      parameter S3_CLKOUT0_DIVIDE         = 1,
      parameter S3_CLKOUT0_PHASE          = 0,
      parameter S3_CLKOUT0_DUTY           = 50000,

      //***********************************************************************
      // State 4 Parameters - These are for the second reconfiguration state.
      //***********************************************************************
      parameter S4_CLKFBOUT_MULT          = 5,
      parameter S4_CLKFBOUT_PHASE         = 0,
      parameter S4_BANDWIDTH              = "LOW",
      parameter S4_DIVCLK_DIVIDE          = 1,      
      parameter S4_CLKOUT0_DIVIDE         = 1,
      parameter S4_CLKOUT0_PHASE          = 0,
      parameter S4_CLKOUT0_DUTY           = 50000
      

    ) 
   (
      // These signals are controlled by user logic interface and are covered
      // in more detail within the XAPP.
      input       [1:0] SADDR,
      input             SEN,
      input             SCLK,
      input             RST,
      output reg        SRDY,
      
      // These signals are to be connected to the MMCM_ADV by port name.
      // Their use matches the MMCM port description in the Device User Guide.
      input      [15:0] DO,
      input             DRDY,
      input             LOCKED,
      output reg        DWE,
      output reg        DEN,
      output reg [6:0]  DADDR,
      output reg [15:0] DI,
      output            DCLK,
      output reg        RST_MMCM
   );

   // 100 ps delay for behavioral simulations
   localparam  TCQ = 100;

   // Make sure the memory is implemented as distributed
   (* rom_style = "distributed" *)
   reg [38:0]  rom [63:0];  // 39 bit word 64 words deep
   reg [5:0]   rom_addr;
   reg [38:0]  rom_do;  
   reg         next_srdy;
   reg [5:0]   next_rom_addr;
   reg [6:0]   next_daddr;
   reg         next_dwe;
   reg         next_den;
   reg         next_rst_mmcm;
   reg [15:0]  next_di;
   
   // Integer used to initialize remainder of unused ROM
   integer     ii;
   
   // Pass SCLK to DCLK for the MMCM
   assign DCLK = SCLK;

   // Include the MMCM reconfiguration functions.  This contains the constant
   // functions that are used in the calculations below.  This file is 
   // required.
   `include "mmcm_drp_func.h"
   
   //**************************************************************************
   // State 1 Calculations
   //**************************************************************************
   // Please see header for infor
   localparam [37:0] S1_CLKFBOUT       =
      mmcm_count_calc(S1_CLKFBOUT_MULT, S1_CLKFBOUT_PHASE, 50000);
      
   localparam [9:0]  S1_DIGITAL_FILT   = 
      mmcm_filter_lookup(S1_CLKFBOUT_MULT, S1_BANDWIDTH);
      
   localparam [39:0] S1_LOCK           =
      mmcm_lock_lookup(S1_CLKFBOUT_MULT);
      
   localparam [37:0] S1_DIVCLK         = 
      mmcm_count_calc(S1_DIVCLK_DIVIDE, 0, 50000); 
      
   localparam [37:0] S1_CLKOUT0        =
      mmcm_count_calc(S1_CLKOUT0_DIVIDE, S1_CLKOUT0_PHASE, S1_CLKOUT0_DUTY);  
   
   //**************************************************************************
   // State 2 Calculations
   //**************************************************************************
   localparam [37:0] S2_CLKFBOUT       = 
      mmcm_count_calc(S2_CLKFBOUT_MULT, S2_CLKFBOUT_PHASE, 50000);
      
   localparam [9:0] S2_DIGITAL_FILT    = 
      mmcm_filter_lookup(S2_CLKFBOUT_MULT, S2_BANDWIDTH);
   
   localparam [39:0] S2_LOCK           = 
      mmcm_lock_lookup(S2_CLKFBOUT_MULT);
   
   localparam [37:0] S2_DIVCLK         = 
      mmcm_count_calc(S2_DIVCLK_DIVIDE, 0, 50000); 
   
   localparam [37:0] S2_CLKOUT0        = 
      mmcm_count_calc(S2_CLKOUT0_DIVIDE, S2_CLKOUT0_PHASE, S2_CLKOUT0_DUTY);

   //**************************************************************************
   // State 3 Calculations
   //**************************************************************************
   localparam [37:0] S3_CLKFBOUT       = 
      mmcm_count_calc(S3_CLKFBOUT_MULT, S3_CLKFBOUT_PHASE, 50000);
      
   localparam [9:0] S3_DIGITAL_FILT    = 
      mmcm_filter_lookup(S3_CLKFBOUT_MULT, S3_BANDWIDTH);
   
   localparam [39:0] S3_LOCK           = 
      mmcm_lock_lookup(S3_CLKFBOUT_MULT);
   
   localparam [37:0] S3_DIVCLK         = 
      mmcm_count_calc(S3_DIVCLK_DIVIDE, 0, 50000); 
   
   localparam [37:0] S3_CLKOUT0        = 
      mmcm_count_calc(S3_CLKOUT0_DIVIDE, S3_CLKOUT0_PHASE, S3_CLKOUT0_DUTY);

   //**************************************************************************
   // State 4 Calculations
   //**************************************************************************
   localparam [37:0] S4_CLKFBOUT       = 
      mmcm_count_calc(S4_CLKFBOUT_MULT, S4_CLKFBOUT_PHASE, 50000);
      
   localparam [9:0] S4_DIGITAL_FILT    = 
      mmcm_filter_lookup(S4_CLKFBOUT_MULT, S4_BANDWIDTH);
   
   localparam [39:0] S4_LOCK           = 
      mmcm_lock_lookup(S4_CLKFBOUT_MULT);
   
   localparam [37:0] S4_DIVCLK         = 
      mmcm_count_calc(S4_DIVCLK_DIVIDE, 0, 50000); 
   
   localparam [37:0] S4_CLKOUT0        = 
      mmcm_count_calc(S4_CLKOUT0_DIVIDE, S4_CLKOUT0_PHASE, S4_CLKOUT0_DUTY);
         
   
   initial begin
      // rom entries contain (in order) the address, a bitmask, and a bitset
      //***********************************************************************
      // State 1 Initialization
      //***********************************************************************
      
      // Store the power bits
      rom[0] = {7'h28, 16'h0000, 16'hFFFF};
      
      // Store CLKOUT0 divide and phase
      rom[1]  = {7'h08, 16'h1000, S1_CLKOUT0[15:0]};
      rom[2]  = {7'h09, 16'hFC00, S1_CLKOUT0[31:16]};
      
      // Store the input divider
      rom[3] = {7'h16, 16'hC000, {2'h0, S1_DIVCLK[23:22], S1_DIVCLK[11:0]} };
      
      // Store the feedback divide and phase
      rom[4] = {7'h14, 16'h1000, S1_CLKFBOUT[15:0]};
      rom[5] = {7'h15, 16'hFC00, S1_CLKFBOUT[31:16]};
      
      // Store the lock settings
      rom[6] = {7'h18, 16'hFC00, {6'h00, S1_LOCK[29:20]} };
      rom[7] = {7'h19, 16'h8000, {1'b0 , S1_LOCK[34:30], S1_LOCK[9:0]} };
      rom[8] = {7'h1A, 16'h8000, {1'b0 , S1_LOCK[39:35], S1_LOCK[19:10]} };
      
      // Store the filter settings
      rom[9] = {7'h4E, 16'h66FF, 
         S1_DIGITAL_FILT[9], 2'h0, S1_DIGITAL_FILT[8:7], 2'h0, 
         S1_DIGITAL_FILT[6], 8'h00 };
      rom[10] = {7'h4F, 16'h666F, 
         S1_DIGITAL_FILT[5], 2'h0, S1_DIGITAL_FILT[4:3], 2'h0,
         S1_DIGITAL_FILT[2:1], 2'h0, S1_DIGITAL_FILT[0], 4'h0 };

      //***********************************************************************
      // State 2 Initialization
      //***********************************************************************
      
      // Store the power bits
      rom[11] = {7'h28, 16'h0000, 16'hFFFF};
      
      // Store CLKOUT0 divide and phase
      rom[12] = {7'h08, 16'h1000, S2_CLKOUT0[15:0]};
      rom[13] = {7'h09, 16'hFC00, S2_CLKOUT0[31:16]};
            
      // Store the input divider
      rom[14] = {7'h16, 16'hC000, {2'h0, S2_DIVCLK[23:22], S2_DIVCLK[11:0]} };
      
      // Store the feedback divide and phase
      rom[15] = {7'h14, 16'h1000, S2_CLKFBOUT[15:0]};
      rom[16] = {7'h15, 16'hFC00, S2_CLKFBOUT[31:16]};
      
      // Store the lock settings
      rom[17] = {7'h18, 16'hFC00, {6'h00, S2_LOCK[29:20]} };
      rom[18] = {7'h19, 16'h8000, {1'b0 , S2_LOCK[34:30], S2_LOCK[9:0]} };
      rom[19] = {7'h1A, 16'h8000, {1'b0 , S2_LOCK[39:35], S2_LOCK[19:10]} };
      
      // Store the filter settings
      rom[20] = {7'h4E, 16'h66FF, 
         S2_DIGITAL_FILT[9], 2'h0, S2_DIGITAL_FILT[8:7], 2'h0, 
         S2_DIGITAL_FILT[6], 8'h00 };
      rom[21] = {7'h4F, 16'h666F, 
         S2_DIGITAL_FILT[5], 2'h0, S2_DIGITAL_FILT[4:3], 2'h0,
         S2_DIGITAL_FILT[2:1], 2'h0, S2_DIGITAL_FILT[0], 4'h0 };

      //***********************************************************************
      // State 3 Initialization
      //***********************************************************************
      
      // Store the power bits
      rom[22] = {7'h28, 16'h0000, 16'hFFFF};
      
      // Store CLKOUT0 divide and phase
      rom[23] = {7'h08, 16'h1000, S3_CLKOUT0[15:0]};
      rom[24] = {7'h09, 16'hFC00, S3_CLKOUT0[31:16]};
            
      // Store the input divider
      rom[25] = {7'h16, 16'hC000, {2'h0, S3_DIVCLK[23:22], S3_DIVCLK[11:0]} };
      
      // Store the feedback divide and phase
      rom[26] = {7'h14, 16'h1000, S3_CLKFBOUT[15:0]};
      rom[27] = {7'h15, 16'hFC00, S3_CLKFBOUT[31:16]};
      
      // Store the lock settings
      rom[28] = {7'h18, 16'hFC00, {6'h00, S3_LOCK[29:20]} };
      rom[29] = {7'h19, 16'h8000, {1'b0 , S3_LOCK[34:30], S3_LOCK[9:0]} };
      rom[30] = {7'h1A, 16'h8000, {1'b0 , S3_LOCK[39:35], S3_LOCK[19:10]} };
      
      // Store the filter settings
      rom[31] = {7'h4E, 16'h66FF, 
         S3_DIGITAL_FILT[9], 2'h0, S3_DIGITAL_FILT[8:7], 2'h0, 
         S3_DIGITAL_FILT[6], 8'h00 };
      rom[32] = {7'h4F, 16'h666F, 
         S3_DIGITAL_FILT[5], 2'h0, S3_DIGITAL_FILT[4:3], 2'h0,
         S3_DIGITAL_FILT[2:1], 2'h0, S3_DIGITAL_FILT[0], 4'h0 };

      //***********************************************************************
      // State 4 Initialization
      //***********************************************************************
      
      // Store the power bits
      rom[33] = {7'h28, 16'h0000, 16'hFFFF};
      
      // Store CLKOUT0 divide and phase
      rom[34] = {7'h08, 16'h1000, S4_CLKOUT0[15:0]};
      rom[35] = {7'h09, 16'hFC00, S4_CLKOUT0[31:16]};
            
      // Store the input divider
      rom[36] = {7'h16, 16'hC000, {2'h0, S4_DIVCLK[23:22], S4_DIVCLK[11:0]} };
      
      // Store the feedback divide and phase
      rom[37] = {7'h14, 16'h1000, S4_CLKFBOUT[15:0]};
      rom[38] = {7'h15, 16'hFC00, S4_CLKFBOUT[31:16]};
      
      // Store the lock settings
      rom[39] = {7'h18, 16'hFC00, {6'h00, S4_LOCK[29:20]} };
      rom[40] = {7'h19, 16'h8000, {1'b0 , S4_LOCK[34:30], S3_LOCK[9:0]} };
      rom[41] = {7'h1A, 16'h8000, {1'b0 , S4_LOCK[39:35], S3_LOCK[19:10]} };
      
      // Store the filter settings
      rom[42] = {7'h4E, 16'h66FF, 
         S4_DIGITAL_FILT[9], 2'h0, S4_DIGITAL_FILT[8:7], 2'h0, 
         S4_DIGITAL_FILT[6], 8'h00 };
      rom[43] = {7'h4F, 16'h666F, 
         S4_DIGITAL_FILT[5], 2'h0, S4_DIGITAL_FILT[4:3], 2'h0,
         S4_DIGITAL_FILT[2:1], 2'h0, S4_DIGITAL_FILT[0], 4'h0 };


      
      // Initialize the rest of the ROM
      for(ii = 44; ii < 64; ii = ii +1) begin
         rom[ii] = 0;
      end
   end

   // Output the initialized rom value based on rom_addr each clock cycle
   always @(posedge SCLK) begin
      rom_do<= #TCQ rom[rom_addr];
   end
   
   //**************************************************************************
   // Everything below is associated whith the state machine that is used to
   // Read/Modify/Write to the MMCM.
   //**************************************************************************
   
   // State Definitions
   localparam RESTART      = 4'h1;
   localparam WAIT_LOCK    = 4'h2;
   localparam WAIT_SEN     = 4'h3;
   localparam ADDRESS      = 4'h4;
   localparam WAIT_A_DRDY  = 4'h5;
   localparam BITMASK      = 4'h6;
   localparam BITSET       = 4'h7;
   localparam WRITE        = 4'h8;
   localparam WAIT_DRDY    = 4'h9;
   
   // State sync
   reg [3:0]  current_state   = RESTART;
   reg [3:0]  next_state      = RESTART;
   
   // These variables are used to keep track of the number of iterations that 
   //    each state takes to reconfigure.
   // STATE_COUNT_CONST is used to reset the counters and should match the
   //    number of registers necessary to reconfigure each state.
   localparam STATE_COUNT_CONST  = 11;
   reg [4:0] state_count         = STATE_COUNT_CONST; 
   reg [4:0] next_state_count    = STATE_COUNT_CONST;
	
	reg LOCKED_P;
	reg LOCKED_P2;
	
   
   // This block assigns the next register value from the state machine below
   always @(posedge SCLK) begin
      DADDR       <= #TCQ next_daddr;
      DWE         <= #TCQ next_dwe;
      DEN         <= #TCQ next_den;
      RST_MMCM    <= #TCQ next_rst_mmcm;
      DI          <= #TCQ next_di;
      
      SRDY        <= #TCQ next_srdy;
      
      rom_addr    <= #TCQ next_rom_addr;
      state_count <= #TCQ next_state_count;
   end
   
   // This block assigns the next state, reset is syncronous.
   always @(posedge SCLK or posedge RST) begin
      if(RST) begin
         current_state <= #TCQ RESTART;
      end else begin
         current_state <= #TCQ next_state;
			LOCKED_P <= LOCKED;
			LOCKED_P2 <= LOCKED_P;
      end
   end
   
   always @* begin
      // Setup the default values
      next_srdy         = 1'b0;
      next_daddr        = DADDR;
      next_dwe          = 1'b0;
      next_den          = 1'b0;
      next_rst_mmcm     = RST_MMCM;
      next_di           = DI;
      next_rom_addr     = rom_addr;
      next_state_count  = state_count;
   
      case (current_state)
         // If RST is asserted reset the machine
         RESTART: begin
            next_daddr     = 7'h00;
            next_di        = 16'h0000;
            next_rom_addr  = 6'h00;
            next_rst_mmcm  = 1'b1;
            next_state     = WAIT_LOCK;
         end
         
         // Waits for the MMCM to assert LOCKED - once it does asserts SRDY
         WAIT_LOCK: begin
            // Make sure reset is de-asserted
            next_rst_mmcm   = 1'b0;
            // Reset the number of registers left to write for the next 
            // reconfiguration event.
            next_state_count = STATE_COUNT_CONST;
            
            if(LOCKED_P2) begin
               // MMCM is locked, go on to wait for the SEN signal
               next_state  = WAIT_SEN;
               // Assert SRDY to indicate that the reconfiguration module is
               // ready
               next_srdy   = 1'b1;
            end else begin
               // Keep waiting, locked has not asserted yet
               next_state  = WAIT_LOCK;
            end
         end
         
         // Wait for the next SEN pulse and set the ROM addr appropriately 
         //    based on SADDR
         WAIT_SEN: begin
            if (SADDR == 2'b00)
               next_rom_addr = 8'h00;
            else if(SADDR == 2'b01)
               next_rom_addr = STATE_COUNT_CONST;
            else if(SADDR == 2'b10)
               next_rom_addr = 2*STATE_COUNT_CONST;
            else
               next_rom_addr = 3*STATE_COUNT_CONST;
            
            if (SEN) begin
               // SEN was asserted
               
               // Go on to address the MMCM
               next_state = ADDRESS;
            end else begin
               // Keep waiting for SEN to be asserted
               next_state = WAIT_SEN;
            end
         end
         
         // Set the address on the MMCM and assert DEN to read the value
         ADDRESS: begin
            // Reset the DCM through the reconfiguration
            next_rst_mmcm  = 1'b1;
            // Enable a read from the MMCM and set the MMCM address
            next_den       = 1'b1;
            next_daddr     = rom_do[38:32];
            
            // Wait for the data to be ready
            next_state     = WAIT_A_DRDY;
         end
         
         // Wait for DRDY to assert after addressing the MMCM
         WAIT_A_DRDY: begin
            if (DRDY) begin
               // Data is ready, mask out the bits to save
               next_state = BITMASK;
            end else begin
               // Keep waiting till data is ready
               next_state = WAIT_A_DRDY;
            end
         end
         
         // Zero out the bits that are not set in the mask stored in rom
         BITMASK: begin
            // Do the mask
            next_di     = rom_do[31:16] & DO;
            // Go on to set the bits
            next_state  = BITSET;
         end
         
         // After the input is masked, OR the bits with calculated value in rom
         BITSET: begin
            // Set the bits that need to be assigned
            next_di           = rom_do[15:0] | DI;
            // Set the next address to read from ROM
            next_rom_addr     = rom_addr + 1'b1;
            // Go on to write the data to the MMCM
            next_state        = WRITE;
         end
         
         // DI is setup so assert DWE, DEN, and RST_MMCM.  Subtract one from the
         //    state count and go to wait for DRDY.
         WRITE: begin
            // Set WE and EN on MMCM
            next_dwe          = 1'b1;
            next_den          = 1'b1;
            
            // Decrement the number of registers left to write
            next_state_count  = state_count - 1'b1;
            // Wait for the write to complete
            next_state        = WAIT_DRDY;
         end
         
         // Wait for DRDY to assert from the MMCM.  If the state count is not 0
         //    jump to ADDRESS (continue reconfiguration).  If state count is
         //    0 wait for lock.
         WAIT_DRDY: begin
            if(DRDY) begin
               // Write is complete
               if(state_count > 0) begin
                  // If there are more registers to write keep going
                  next_state  = ADDRESS;
               end else begin
                  // There are no more registers to write so wait for the MMCM
                  // to lock
                  next_state  = WAIT_LOCK;
               end
            end else begin
               // Keep waiting for write to complete
               next_state     = WAIT_DRDY;
            end
         end
         
         // If in an unknown state reset the machine
         default: begin
            next_state = RESTART;
         end
      endcase
   end
endmodule
