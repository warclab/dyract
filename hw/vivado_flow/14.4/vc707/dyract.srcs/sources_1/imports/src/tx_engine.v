//--------------------------------------------------------------------------------
// Project    : SWITCH
// File       : tx_engine.v
// Version    : 0.1
// Author     : Vipin.K
//
// Description: 64 bit PCIe transaction layer transmit unit
//
//--------------------------------------------------------------------------------

`timescale 1ns/1ns

module tx_engine    #(
  // TX interface data width
  parameter C_DATA_WIDTH = 128,
  parameter KEEP_WIDTH = C_DATA_WIDTH / 8
)(

  input                           clk_i,
  input                           rst_n,

  // AXIS
  input                           s_axis_tx_tready,
  output  reg [C_DATA_WIDTH-1:0]  s_axis_tx_tdata,
  output  reg [KEEP_WIDTH-1:0]    s_axis_tx_tkeep,
  output  reg                     s_axis_tx_tlast,
  output  reg                     s_axis_tx_tvalid,
  output                          tx_src_dsc,
  //Rx engine
  input                           req_compl_wd_i,
  output reg                      compl_done_o,
  input [2:0]                     req_tc_i,
  input                           req_td_i,
  input                           req_ep_i,
  input [1:0]                     req_attr_i,
  input [9:0]                     req_len_i,
  input [15:0]                    req_rid_i,
  input [7:0]                     req_tag_i,
  input [6:0]                     req_addr_i,
  input [15:0]                    completer_id_i,
  //Register set
  input [31:0]                    reg_data_i,
  input                           config_dma_req_i,
  input [31:0]                    config_dma_rd_addr_i,
  input [11:0]                    config_dma_req_len_i,
  output reg                      config_dma_req_done_o,
  input [7:0]                     config_dma_req_tag_i, 
  input                           sys_user_dma_req_i,
  output reg                      sys_user_dma_req_done_o,
  input [11:0]                    sys_user_dma_req_len_i,
  input [31:0]                    sys_user_dma_rd_addr_i,
  input [7:0]                     sys_user_dma_tag_i,
  //User stream i/f
  input                           user_str_data_avail_i,
  output reg                      user_str_dma_done_o,
  input [31:0]                    user_sys_dma_wr_addr_i,
  output reg                      user_str_data_rd_o,
  input [C_DATA_WIDTH-1:0]        user_str_data_i,
  input [4:0]                     user_str_len_i,
  //interrupt
  input                           intr_req_i,
  output reg                      intr_req_done_o,
  output reg                      cfg_interrupt_o,
  input                           cfg_interrupt_rdy_i
);

   // State Machine state declaration
    localparam IDLE         = 'd0,
               SEND_ACK_CPLD= 'd1,
               REQ_INTR     = 'd2,
               WR_USR_HDR   = 'd3,
               WR_USR_DATA  = 'd4,
               WAIT_CORE    = 'd5,
               SEND_ACK_DMA = 'd6;


    // TLP packet type encoding
    localparam  MEM_RD = 7'b0000000,
                MEM_WR = 7'b1000000,
                CPLD   = 7'b1001010;

    reg [2:0]      state;
    reg [31:0]     rd_data_p;
    reg [127:0]    user_rd_data_p;
    reg [95:0]     user_rd_data_p1;
    reg [4:0]      wr_cntr;
    wire [6:0]     user_wr_len;

    // Unused discontinue
    assign tx_src_dsc = 1'b0;
    assign user_wr_len = user_str_len_i*4;

    //Delay the data read from the transmit fifo for 64byte packing.
    always@(posedge clk_i)
    begin
        if(user_str_data_rd_o)
            user_rd_data_p    <= user_str_data_i;
    end
    
    always@(posedge clk_i)
    begin
        if(user_str_data_rd_o)
            user_rd_data_p1    <= user_rd_data_p[127:32];
    end
    
    
    initial 
    begin
        s_axis_tx_tlast        <= 1'b0;
        s_axis_tx_tvalid       <= 1'b0;
        s_axis_tx_tkeep        <= {KEEP_WIDTH{1'b0}};
        compl_done_o           <= 1'b0;
        config_dma_req_done_o  <= 1'b0;
        wr_cntr                <= 0;
        intr_req_done_o        <= 1'b0;
        user_str_data_rd_o     <= 1'b0;
        state                  <= IDLE;
        user_str_dma_done_o    <= 1'b0;
    end

    //The transmit state machine
    always @ ( posedge clk_i ) 
    begin 
        case (state)
            IDLE : begin
                s_axis_tx_tlast  <= 1'b0;
                s_axis_tx_tvalid <= 1'b0;
                intr_req_done_o  <=  1'b0;
                wr_cntr <= 0;
                if (req_compl_wd_i)                                //If completion request from Rx engine
                begin
                    s_axis_tx_tlast  <= 1'b1;
                    s_axis_tx_tvalid <= 1'b1;
                    // Swap DWORDS for AXI
                                                                   // Bits\
                    s_axis_tx_tdata  <= {
                                          reg_data_i,               // 32                            
                                          req_rid_i,                // 16                          
                                          req_tag_i,                //  8                           
                                          {1'b0},                   //  1                          
                                          req_addr_i,               //  7                          
                                          completer_id_i,           // 16
                                          {3'b0},                   // 3
                                          {1'b0},                   // 1
                                          {12'd4},                  // 12
                                          {1'b0},                   // 1
                                          CPLD,                     // 7
                                          {1'b0},                   // 1
                                          req_tc_i,                 // 3
                                          {4'b0},                   // 4
                                          req_td_i,                 // 1
                                          req_ep_i,                 // 1
                                          req_attr_i,               // 2
                                          {2'b0},                   // 2
                                          req_len_i                 // 10
                                          };
                    s_axis_tx_tkeep   <=  16'hFFFF;
                    state             <=  SEND_ACK_CPLD;
                end   
                
                else if(config_dma_req_i)                           //If system memory DMA read request from control register
                begin
                  s_axis_tx_tlast  <= 1'b1;
                  s_axis_tx_tvalid <= 1'b1;
                  s_axis_tx_tdata  <= {                         // Bits
                                        32'h00000000,
                                        config_dma_rd_addr_i,
                                        completer_id_i,           // 16
                                        config_dma_req_tag_i,    // 8 tag
                                        {4'b1111},                // 4
                                        {4'b1111},                // 4
                                        {1'b0},                   // 1
                                        MEM_RD,                   // 7
                                        {1'b0},                   // 1
                                        {3'b0},                   // 3
                                        {4'b0},                   // 4
                                        1'b0,                     // 1
                                        1'b0,                     // 1
                                        {2'b0},                   // 2
                                        {2'b0},                   // 2
                                        config_dma_req_len_i[11:2]        // 10
                                        };
                    s_axis_tx_tkeep   <=  16'h0FFF;
                    state             <= SEND_ACK_DMA;
                    config_dma_req_done_o <= 1'b1;
                end  
                
                else if(sys_user_dma_req_i)                                 //If system memory DMA read request from control register
                begin
                    s_axis_tx_tlast  <= 1'b1;
                    s_axis_tx_tvalid <= 1'b1;
                    s_axis_tx_tdata  <= {                         // Bits
                                        32'h00000000,
                                        sys_user_dma_rd_addr_i,
                                        completer_id_i,           // 16
                                        sys_user_dma_tag_i,       // 8 tag
                                        {4'b1111},                // 4
                                        {4'b1111},                // 4
                                        {1'b0},                   // 1
                                        MEM_RD,                   // 7
                                        {1'b0},                   // 1
                                        {3'b0},                   // 3
                                        {4'b0},                   // 4
                                        1'b0,                     // 1
                                        1'b0,                     // 1
                                        {2'b0},                   // 2
                                        {2'b0},                   // 2
                                        sys_user_dma_req_len_i[11:2] // 10
                                        };
                    s_axis_tx_tkeep   <=  16'h0FFF;
                    sys_user_dma_req_done_o <= 1'b1;
                    state             <= SEND_ACK_DMA;
                end 
                
                else if(user_str_data_avail_i & s_axis_tx_tready)
                begin
                    state                <=  WR_USR_HDR;
                    user_str_data_rd_o   <=  1'b1;
                    wr_cntr              <=  user_str_len_i;
                end
                
                else if(intr_req_i & ~intr_req_done_o) //If there is interrupt request and no data in the transmit fifo
                begin
                    state       <=  REQ_INTR;
                    cfg_interrupt_o <= 1'b1;
                end
                else 
                begin
                    s_axis_tx_tlast   <= 1'b0;
                    s_axis_tx_tvalid  <= 1'b0;
                    s_axis_tx_tkeep   <= 16'h00;
                    compl_done_o      <= 1'b0;
                end
            end 
            
            WR_USR_HDR:begin
                state              <=  WR_USR_DATA;
                s_axis_tx_tvalid   <=  1'b1;
                s_axis_tx_tdata    <=  {
                                            user_str_data_i[31:0],
                                            user_sys_dma_wr_addr_i,
                                            completer_id_i,//req id
                                            8'h00,   //tag
                                            8'hFF,   //BE
                                            1'b0,    //res
                                            MEM_WR,  //type
                                            1'b0,    //r
                                            3'b000,  //tc
                                            4'b0000, //res
                                            1'b0,    //td
                                            1'b0,    //ep
                                            2'b00,   //attr
                                            2'b00,   //res
                                            {3'h0,user_wr_len}//len. 128 bytes
                                        };
                s_axis_tx_tkeep         <=  16'hFFFF;
                if(wr_cntr == 1)
                    user_str_data_rd_o   <=  1'b0;
            end           
            
            SEND_ACK_CPLD:begin
                if(~req_compl_wd_i)
                begin
                    compl_done_o   <= 1'b0;
                    state          <= IDLE;
                end
                if (s_axis_tx_tready) 
                begin
                    compl_done_o           <= req_compl_wd_i;
                    s_axis_tx_tlast        <= 1'b0;
                    s_axis_tx_tvalid       <= 1'b0;
                end
            end
             
            SEND_ACK_DMA:begin
                config_dma_req_done_o   <= 1'b0;
                sys_user_dma_req_done_o <= 1'b0;
                if (s_axis_tx_tready) 
                begin
                    s_axis_tx_tlast        <= 1'b0;
                    s_axis_tx_tvalid       <= 1'b0;
                    state                  <= IDLE;
                end
            end
            
            WR_USR_DATA:begin
                user_str_dma_done_o <= 1'b0;
                if(s_axis_tx_tready)
                begin
                    if(wr_cntr == 2)
                        user_str_data_rd_o  <=    1'b0;
                    else if(wr_cntr == 1)
                    begin
                        user_str_data_rd_o  <= 1'b0;
                        s_axis_tx_tlast     <= 1'b1;
                        s_axis_tx_tkeep     <= 16'h0FFF; 
                        user_str_dma_done_o <= 1'b1;
                    end  
                    else if(wr_cntr == 0) //simply wait for tready to change status.
                    begin
                       state            <=    IDLE;
                       s_axis_tx_tlast  <=    1'b0;
                       s_axis_tx_tvalid <=    1'b0;
                    end
                    wr_cntr             <=    wr_cntr - 1'b1;
                    s_axis_tx_tdata     <=    {user_str_data_i[31:0],user_rd_data_p[127:32]};
                end
                else
                begin
                    user_str_data_rd_o  <=    1'b0;
                    state               <=    WAIT_CORE;
                end 
            end
            
            WAIT_CORE:begin
                if(s_axis_tx_tready)
                begin
                    s_axis_tx_tdata     <=     {user_rd_data_p[31:0],user_rd_data_p1};
                    wr_cntr             <=     wr_cntr - 1'b1;
                    if(wr_cntr == 2)
                    begin
                        user_str_data_rd_o  <= 1'b0;
                        state               <= WR_USR_DATA;
                    end    
                    else if(wr_cntr == 1)
                    begin
                        user_str_data_rd_o  <= 1'b0;
                        s_axis_tx_tlast     <= 1'b1;
                        s_axis_tx_tvalid    <= 1'b1;
                        s_axis_tx_tkeep     <= 16'h0FFF; 
                        user_str_dma_done_o <= 1'b1;
                        state               <= WR_USR_DATA;
                    end                    
                    else if(wr_cntr == 0) //simply wait for tready to change status.
                    begin
                        state            <=    IDLE;
                        s_axis_tx_tlast  <=    1'b0;
                        s_axis_tx_tvalid <=    1'b0;
                    end
                    else
                    begin                        
                        s_axis_tx_tlast     <=    1'b0;
                        s_axis_tx_tvalid    <=    1'b0;
                        state               <=    WR_USR_DATA;
                        user_str_data_rd_o  <=    1'b1;
                    end
                end
            end
            
            REQ_INTR:begin        //Send interrupt through PCIe interrupt port
                if(cfg_interrupt_rdy_i)
                begin
                    cfg_interrupt_o <= 1'b0;
                    state           <= IDLE;
                    intr_req_done_o <= 1'b1;
                end
            end
        endcase
    end

endmodule
