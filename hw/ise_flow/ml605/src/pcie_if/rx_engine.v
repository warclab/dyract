//--------------------------------------------------------------------------------
// Project    : SWITCH
// File       : rx_engine.v
// Version    : 0.1
// Author     : Vipin.K
//
// Description: 64 bit PCIe transaction layer receive unit
//
//--------------------------------------------------------------------------------

`timescale 1ns/1ns

module rx_engine  #(
  parameter C_DATA_WIDTH = 64,                                    // RX interface data width
  parameter FPGA_ADDR_MAX = 'h400
) (
  input                         clk_i,                           // 250Mhz clock from PCIe core
  input                         rst_n,                           // Active low reset
  // AXI-S
  input  [C_DATA_WIDTH-1:0]     m_axis_rx_tdata,
  input                         m_axis_rx_tlast,
  input                         m_axis_rx_tvalid,
  output reg                    m_axis_rx_tready,
  //Tx engine
  input                         compl_done_i,                    // Tx engine indicating completion packet is sent
  output reg                    req_compl_wd_o,                  // Request Tx engine for completion packet transmission 
  output reg [31:0]             tx_reg_data_o,                   // Data for completion packet              
  output reg [2:0]              req_tc_o,                        // Memory Read TC
  output reg                    req_td_o,                        // Memory Read TD
  output reg                    req_ep_o,                        // Memory Read EP
  output reg [1:0]              req_attr_o,                      // Memory Read Attribute
  output reg [9:0]              req_len_o,                       // Memory Read Length (1DW)
  output reg [15:0]             req_rid_o,                       // Memory Read Requestor ID
  output reg [7:0]              req_tag_o,                       // Memory Read Tag
  output reg [6:0]              req_addr_o,                      // Memory Read Address
  //Register file
  output reg [31:0]             reg_data_o,                      // Write data to register
  output reg                    reg_data_valid_o,                // Register write data is valid
  output reg [9:0]              reg_addr_o,                      // Register address
  input                         fpga_reg_wr_ack_i,               // Register write acknowledge
  output reg                    fpga_reg_rd_o,                   // Register read enable
  input      [31:0]             reg_data_i,                      // Register read data
  input                         fpga_reg_rd_ack_i,               // Register read acknowledge
  output reg [7:0]              cpld_tag_o,
  //User interface
  output reg [31:0]             user_data_o,                     // User write data
  output reg [19:0]             user_addr_o,                     // User address
  output reg                    user_wr_req_o,                   // User write request
  //input                       user_wr_ack_i,                   // User write acknowledge
  input      [31:0]             user_data_i,                     // User read data
  input                         user_rd_ack_i,                   // User read acknowledge 
  output reg                    user_rd_req_o,                   // User read request
  //DDR interface
  output reg [63:0]             rcvd_data_o,                     // Memory ready completion data after DMA read request
  output reg                    rcvd_data_valid_o                // Completion data is valid
);

    // Local Registers
    wire               sop;
    reg [2:0]          state;
	 reg                in_packet_q;
    reg [31:0]         rx_tdata_p;
    reg                rcv_data;
	 reg                lock_tag;
	 reg                user_wr_ack;
	 
    // State Machine state declaration
	localparam  IDLE           = 'd0,
	            SEND_DATA      = 'd1,
               WAIT_FPGA_DATA = 'd2,
               WAIT_USR_DATA  = 'd3,
               WAIT_TX_ACK    = 'd4,
               WR_DATA        = 'd5,
               RX_DATA        = 'd6;
					
    // TLP packet type encoding
	localparam MEM_RD = 7'b0000000,
               MEM_WR = 7'b1000000,
               CPLD   = 7'b1001010;
					
    assign sop            = !in_packet_q && m_axis_rx_tvalid; //start of a new packet

    // Generate a signal that indicates if we are currently receiving a packet.
    // This value is one clock cycle delayed from what is actually on the AXIS
    // data bus.
    always@(posedge clk_i)
    begin
      if (m_axis_rx_tvalid && m_axis_rx_tready && m_axis_rx_tlast)
        in_packet_q <= 1'b0;
      else if (sop && m_axis_rx_tready)
        in_packet_q <= 1'b1;
    end
	 
	 initial
	 begin
	    m_axis_rx_tready <=  1'b0;
       req_compl_wd_o   <=  1'b0;
       state            <=  IDLE;
       user_rd_req_o    <=  1'b0;
       user_wr_req_o    <=  1'b0;
       rcv_data         <=  1'b0;
       fpga_reg_rd_o    <=  1'b0;
       reg_data_valid_o <=  1'b0;
       in_packet_q <= 1'b0;
	 end

   					
    //The receive state machine
    always @ ( posedge clk_i ) 
    begin
            case (state)
                IDLE : begin
                    m_axis_rx_tready <=  1'b1;                  // Indicate ready to accept TLPs
                    reg_data_valid_o <=  1'b0;
						  user_wr_req_o    <=  1'b0;
						  req_len_o        <=  m_axis_rx_tdata[9:0];  // Place the packet info on the bus for Tx engine
                    req_attr_o       <=  m_axis_rx_tdata[13:12];
                    req_ep_o         <=  m_axis_rx_tdata[14];
                    req_td_o         <=  m_axis_rx_tdata[15];
                    req_tc_o         <=  m_axis_rx_tdata[22:20];
                    req_rid_o        <=  m_axis_rx_tdata[63:48];
                    req_tag_o        <=  m_axis_rx_tdata[47:40];
                    if (sop) 
                    begin                                       // Valid data on the bus
						      if(m_axis_rx_tdata[30:24] == MEM_RD)      // If memory ready request
                           state    <=  SEND_DATA;
						      else if(m_axis_rx_tdata[30:24] == MEM_WR) // If memory write request	 
							      state    <=  WR_DATA; 
                        else if(m_axis_rx_tdata[30:24] == CPLD)   // If completion packet
								begin
                           state    <=  RX_DATA;
									lock_tag <=  1'b1;
								end	
                    end
                end
                SEND_DATA: begin
                    if (m_axis_rx_tvalid && m_axis_rx_tlast)
                    begin
                        req_addr_o         <=  m_axis_rx_tdata[6:0];
                        m_axis_rx_tready   <=  1'b0;              // Block further TLPs until the requested data is sent by Tx engine
                        user_addr_o        <=  m_axis_rx_tdata[19:0];
                        reg_addr_o         <=  m_axis_rx_tdata[9:0];
                        if(m_axis_rx_tdata[21:0] < FPGA_ADDR_MAX) //Check 22 bits since PCIe bar0 is for 4M
                        begin
                            state         <=  WAIT_FPGA_DATA; 
                            fpga_reg_rd_o <=  1'b1;   
                        end
                        else
                        begin
                           state         <=  WAIT_USR_DATA;
                           user_rd_req_o <=  1'b1;
                        end
                    end
                end
                WAIT_FPGA_DATA:begin
					     fpga_reg_rd_o    <=  1'b0; 
                    if(fpga_reg_rd_ack_i)
                    begin 
                        req_compl_wd_o   <=  1'b1;        //Request Tx engine to send data
                        tx_reg_data_o    <=  reg_data_i;
                        state            <=  WAIT_TX_ACK; //Wait for ack from Tx engine for data sent
                    end
                end
                WAIT_USR_DATA:begin
                    if(user_rd_ack_i)
                    begin
                        user_rd_req_o  <=  1'b0;
                        req_compl_wd_o <=  1'b1;
                        tx_reg_data_o  <=  user_data_i;
                        state          <=  WAIT_TX_ACK;
                    end
                end
                WAIT_TX_ACK: begin
                    if(compl_done_i)
                    begin
                       state            <=  IDLE;
                       req_compl_wd_o   <=  1'b0;
							  m_axis_rx_tready <=  1'b1;
                    end
                end
				WR_DATA:begin
                    reg_data_valid_o <=   1'b0;
                    user_wr_req_o    <=   1'b0;
                    if (m_axis_rx_tvalid && m_axis_rx_tlast)
                    begin
						      m_axis_rx_tready <=  1'b0;
                        reg_data_o       <=   m_axis_rx_tdata[63:32];
                        reg_addr_o       <=   m_axis_rx_tdata[9:0];
                        user_data_o      <=   m_axis_rx_tdata[63:32];
                        user_addr_o      <=   m_axis_rx_tdata[19:0];
                        if(m_axis_rx_tdata[21:0] < FPGA_ADDR_MAX)  // If the data is intended for global registers
                        begin  
                            reg_data_valid_o <=   1'b1;    
                        end
                        else
                        begin
                            user_wr_req_o    <=   1'b1;
                        end
                    end
                    if (fpga_reg_wr_ack_i | user_wr_ack)
                    begin
                        state            <=   IDLE;   
                        m_axis_rx_tready <=   1'b1;								
                    end
				end
            RX_DATA:begin
				    lock_tag <= 1'b0;
                if(m_axis_rx_tvalid && m_axis_rx_tlast)
                begin
                    rcv_data  <=  1'b0;
                    state     <=  IDLE;
					m_axis_rx_tready <=  1'b1;
                end
                else
                    rcv_data  <=  1'b1;
            end
            endcase
    end

    //Packing data from the received completion packet. Required since the TLP header is 3 DWORDs.
    always @(posedge clk_i)
    begin
        rx_tdata_p <= m_axis_rx_tdata[63:32];
		  user_wr_ack <= user_wr_req_o;
        if(rcv_data & m_axis_rx_tvalid)
        begin
            rcvd_data_valid_o <= 1'b1;   
            rcvd_data_o       <= {rx_tdata_p,m_axis_rx_tdata[31:0]};
        end
        else
            rcvd_data_valid_o <= 1'b0;
    end
	 
	 always @(posedge clk_i)
	 begin
	     if(lock_tag)
	       cpld_tag_o <= m_axis_rx_tdata[15:8];
	 end

endmodule 

