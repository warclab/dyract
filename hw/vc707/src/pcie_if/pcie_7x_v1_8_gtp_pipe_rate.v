//-----------------------------------------------------------------------------
//
// (c) Copyright 2010-2011 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
// Project    : Series-7 Integrated Block for PCI Express
// File       : pcie_7x_v1_8_gtp_pipe_rate.v
// Version    : 1.7
//------------------------------------------------------------------------------
//  Filename     :  gtp_pipe_rate.v
//  Description  :  PIPE Rate Module for 7 Series Transceiver
//  Version      :  0.1
//------------------------------------------------------------------------------



`timescale 1ns / 1ps



//---------- PIPE Rate Module --------------------------------------------------
module pcie_7x_v1_8_gtp_pipe_rate #
(

    parameter TXDATA_WAIT_MAX   = 4'd15                     // TXDATA wait max

)

(

    //---------- Input -------------------------------------
    input               RATE_CLK,
    input               RATE_RST_N,
    input               RATE_RST_IDLE,
    input       [ 1:0]  RATE_RATE_IN,
    input               RATE_TXRATEDONE,
    input               RATE_RXRATEDONE,
    input               RATE_TXSYNC_DONE,
    input               RATE_PHYSTATUS,
    
    //---------- Output ------------------------------------
    output              RATE_PCLK_SEL,
    output      [ 2:0]  RATE_RATE_OUT,
    output              RATE_TXSYNC_START,
    output              RATE_DONE,
    output              RATE_IDLE,
    output      [23:0]  RATE_FSM

);

    //---------- Input FF or Buffer ------------------------
    reg                 rst_idle_reg1;
    reg         [ 1:0]  rate_in_reg1;
    reg                 txratedone_reg1;
    reg                 rxratedone_reg1;
    reg                 phystatus_reg1;
    reg                 txsync_done_reg1;
    
    reg                 rst_idle_reg2;
    reg         [ 1:0]  rate_in_reg2;
    reg                 txratedone_reg2;
    reg                 rxratedone_reg2;
    reg                 phystatus_reg2;
    reg                 txsync_done_reg2;
    
    //---------- Internal Signals --------------------------
    wire                pll_lock;
    wire        [ 2:0]  rate;
    reg         [ 3:0]  txdata_wait_cnt = 4'd0;
    reg                 txratedone      = 1'd0;
    reg                 rxratedone      = 1'd0;
    reg                 phystatus       = 1'd0;
    reg                 ratedone        = 1'd0;
    
    //---------- Output FF or Buffer -----------------------
    reg                 pclk_sel   =  1'd0; 
    reg         [ 2:0]  rate_out   =  3'd0; 
    reg         [7:0]   fsm        =  8'd0;                 
   
    //---------- FSM ---------------------------------------                                         
    
    localparam          FSM_IDLE             = 8'b00000001; 
    localparam          FSM_TXDATA_WAIT      = 8'b00000010;           
    localparam          FSM_PCLK_SEL         = 8'b00000100;   
    localparam          FSM_RATE_SEL         = 8'b00001000;
    localparam          FSM_RATE_DONE        = 8'b00010000;
    localparam          FSM_TXSYNC_START     = 8'b00100000;
    localparam          FSM_TXSYNC_DONE      = 8'b01000000;             
    localparam          FSM_DONE             = 8'b10000000; // Must sync value to pipe_user.v
    
//---------- Input FF ----------------------------------------------------------
always @ (posedge RATE_CLK)
begin

    if (!RATE_RST_N)
        begin    
        //---------- 1st Stage FF -------------------------- 
        rst_idle_reg1       <= 1'd0;   
        rate_in_reg1        <= 2'd0;
        txratedone_reg1     <= 1'd0;
        rxratedone_reg1     <= 1'd0;
        phystatus_reg1      <= 1'd0;
        txsync_done_reg1    <= 1'd0;
        //---------- 2nd Stage FF --------------------------
        rst_idle_reg2       <= 1'd0;
        rate_in_reg2        <= 2'd0;
        txratedone_reg2     <= 1'd0;
        rxratedone_reg2     <= 1'd0;
        phystatus_reg2      <= 1'd0;
        txsync_done_reg2    <= 1'd0;
        end
    else
        begin  
        //---------- 1st Stage FF --------------------------
        rst_idle_reg1       <= RATE_RST_IDLE;
        rate_in_reg1        <= RATE_RATE_IN;
        txratedone_reg1     <= RATE_TXRATEDONE;
        rxratedone_reg1     <= RATE_RXRATEDONE;
        phystatus_reg1      <= RATE_PHYSTATUS;
        txsync_done_reg1    <= RATE_TXSYNC_DONE;
        //---------- 2nd Stage FF --------------------------
        rst_idle_reg2       <= rst_idle_reg1;
        rate_in_reg2        <= rate_in_reg1;
        txratedone_reg2     <= txratedone_reg1;
        rxratedone_reg2     <= rxratedone_reg1;
        phystatus_reg2      <= phystatus_reg1;
        txsync_done_reg2    <= txsync_done_reg1;   
        end
        
end    






//---------- Select Rate -------------------------------------------------------
//  Gen1 :  div 2 using [TX/RX]OUT_DIV = 2
//  Gen2 :  div 1 using [TX/RX]RATE = 3'd1
//------------------------------------------------------------------------------
assign rate = (rate_in_reg2 == 2'd1) ? 3'd1 : 3'd0;



//---------- TXDATA Wait Counter -----------------------------------------------
always @ (posedge RATE_CLK)
begin

    if (!RATE_RST_N)
        txdata_wait_cnt <= 4'd0;
    else
    
        //---------- Increment Wait Counter ----------------
        if ((fsm == FSM_TXDATA_WAIT) && (txdata_wait_cnt < TXDATA_WAIT_MAX))
            txdata_wait_cnt <= txdata_wait_cnt + 4'd1;
            
        //---------- Hold Wait Counter ---------------------
        else if ((fsm == FSM_TXDATA_WAIT) && (txdata_wait_cnt == TXDATA_WAIT_MAX))
            txdata_wait_cnt <= txdata_wait_cnt;
            
        //---------- Reset Wait Counter --------------------
        else
            txdata_wait_cnt <= 4'd0;
        
end 



//---------- Latch TXRATEDONE, RXRATEDONE, and PHYSTATUS -----------------------
always @ (posedge RATE_CLK)
begin

    if (!RATE_RST_N)
        begin   
        txratedone <= 1'd0;
        rxratedone <= 1'd0; 
        phystatus  <= 1'd0;
        ratedone   <= 1'd0;
        end
    else
        begin  

        if (fsm == FSM_RATE_DONE)
        
            begin
            
            //---------- Latch TXRATEDONE ------------------
            if (txratedone_reg2)
                txratedone <= 1'd1; 
            else
                txratedone <= txratedone;
 
            //---------- Latch RXRATEDONE ------------------
            if (rxratedone_reg2)
                rxratedone <= 1'd1; 
            else
                rxratedone <= rxratedone;
  
            //---------- Latch PHYSTATUS -------------------
            if (phystatus_reg2)
                phystatus <= 1'd1; 
            else
                phystatus <= phystatus;
  
            //---------- Latch Rate Done -------------------
            if (rxratedone && txratedone && phystatus)
                ratedone <= 1'd1; 
            else
                ratedone <= ratedone;
  
            end
  
        else 
        
            begin
            txratedone <= 1'd0;
            rxratedone <= 1'd0;
            phystatus  <= 1'd0;
            ratedone   <= 1'd0;
            end
        
        end
        
end    



//---------- PIPE Rate FSM -----------------------------------------------------
always @ (posedge RATE_CLK)
begin

    if (!RATE_RST_N)
        begin
        fsm        <= FSM_IDLE;
        pclk_sel   <= 1'd0; 
        rate_out   <= 3'd0;                              
        end
    else
        begin
        
        case (fsm)
            
        //---------- Idle State ----------------------------
        FSM_IDLE :
        
            begin
            //---------- Detect Rate Change ----------------
            if (rate_in_reg2 != rate_in_reg1)
                begin
                fsm        <=  FSM_TXDATA_WAIT;
                pclk_sel   <= pclk_sel;
                rate_out   <= rate_out;
                end
            else
                begin
                fsm        <= FSM_IDLE;
                pclk_sel   <= pclk_sel;
                rate_out   <= rate_out;
                end
            end 
        FSM_TXDATA_WAIT :
        
            begin
            fsm        <= (txdata_wait_cnt == TXDATA_WAIT_MAX) ? FSM_PCLK_SEL : FSM_TXDATA_WAIT;
            pclk_sel   <= pclk_sel;
            rate_out   <= rate_out;
            end 

        //---------- Select PCLK Frequency -----------------
        //  Gen1 : PCLK = 125 MHz
        //  Gen2 : PCLK = 250 MHz
        //--------------------------------------------------
        FSM_PCLK_SEL :
        
            begin
            fsm        <= FSM_RATE_SEL;    
            pclk_sel   <= (rate_in_reg2 == 2'd1);
            rate_out   <= rate_out;
            end

        //---------- Select Rate ---------------------------
        FSM_RATE_SEL :
        
            begin
            fsm        <= FSM_RATE_DONE;
            pclk_sel   <= pclk_sel;
            rate_out   <= rate;                             // Update [TX/RX]RATE
            end    
            
        //---------- Wait for Rate Change Done ------------- 
        FSM_RATE_DONE :
        
            begin
            if (ratedone ) 
                    fsm <= FSM_TXSYNC_START;
            else      
                    fsm <= FSM_RATE_DONE;
            
            pclk_sel   <= pclk_sel;
            rate_out   <= rate_out;
            end      
            
        //---------- Start TX Sync -------------------------
        FSM_TXSYNC_START:
        
            begin
            fsm        <= (!txsync_done_reg2 ? FSM_TXSYNC_DONE : FSM_TXSYNC_START);
            pclk_sel   <= pclk_sel;
            rate_out   <= rate_out;
            end
            
        //---------- Wait for TX Sync Done -----------------
        FSM_TXSYNC_DONE:
        
            begin
            fsm        <= (txsync_done_reg2 ? FSM_DONE : FSM_TXSYNC_DONE);
            pclk_sel   <= pclk_sel;
            rate_out   <= rate_out;
            end        

        //---------- Rate Change Done ----------------------
        FSM_DONE :  
          
            begin  
            fsm        <= FSM_IDLE;
            pclk_sel   <= pclk_sel;
            rate_out   <= rate_out;
            end
               
        //---------- Default State -------------------------
        default :
        
            begin
            fsm        <= FSM_IDLE;
            pclk_sel   <= 1'd0; 
            rate_out   <= 3'd0;  
            end

        endcase
        
        end
        
end 



//---------- PIPE Rate Output --------------------------------------------------
assign RATE_PCLK_SEL        = pclk_sel;
assign RATE_RATE_OUT        = rate_out;
assign RATE_TXSYNC_START    = (fsm == FSM_TXSYNC_START);
assign RATE_DONE            = (fsm == FSM_DONE);
assign RATE_IDLE            = (fsm == FSM_IDLE);
assign RATE_FSM             = fsm;   



endmodule
