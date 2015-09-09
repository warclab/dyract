//--------------------------------------------------------------------------------
// Project    : SWITCH
// File       : pcie_app.v
// Version    : 0.1
// Author     : Vipin.K
//
// Description: PCI Express application top. Instantiates Rx, Tx engines, register set
//              the user PCIe stream controllers.
//--------------------------------------------------------------------------------

`timescale 1ps / 1ps

`define PCI_EXP_EP_OUI                           24'h000A35
`define PCI_EXP_EP_DSN_1                         {{8'h1},`PCI_EXP_EP_OUI}
`define PCI_EXP_EP_DSN_2                         32'h00000001

module  pcie_app#(
  parameter C_DATA_WIDTH     = 128,            // RX/TX interface data width
  parameter NUM_PCIE_STRM    = 4,
  parameter RECONFIG_ENABLE  = 1,
  // Do not override parameters below this line
  parameter KEEP_WIDTH = C_DATA_WIDTH / 8               // KEEP width
)(

 input                         pcie_core_clk,           // 250 MHz core clock
 input                         user_reset,              // Active high reset from the PCIe core
 input                         user_lnk_up,             // PCIe link status
 // Tx
 output                        tx_cfg_gnt,
 input                         s_axis_tx_tready,
 output  [C_DATA_WIDTH-1:0]    s_axis_tx_tdata,
 output  [KEEP_WIDTH-1:0]      s_axis_tx_tkeep,
 output  [3:0]                 s_axis_tx_tuser,
 output                        s_axis_tx_tlast,
 output                        s_axis_tx_tvalid,
 // Rx
 output                        rx_np_ok,
 input  [C_DATA_WIDTH-1:0]     m_axis_rx_tdata,
 input  [21:0]                 m_axis_rx_tuser,
 input                         m_axis_rx_tlast,
 input                         m_axis_rx_tvalid,
 output                        m_axis_rx_tready,
 //other pcie core signals
 output [2:0]                  fc_sel,
 output [31:0]                 cfg_di,
 output [3:0]                  cfg_byte_en,
 output [9:0]                  cfg_dwaddr,
 output                        cfg_wr_en,
 output                        cfg_rd_en,
 output                        cfg_err_cor,
 output                        cfg_err_ur,
 output                        cfg_err_ecrc,
 output                        cfg_err_cpl_timeout,
 output                        cfg_err_cpl_abort,
 output                        cfg_err_cpl_unexpect,
 output                        cfg_err_posted,
 output                        cfg_err_locked,
 output [47:0]                 cfg_err_tlp_cpl_header,
 output                        cfg_interrupt,
 input                         cfg_interrupt_rdy,
 output                        cfg_interrupt_assert,
 output [7:0]                  cfg_interrupt_di,
 output                        cfg_turnoff_ok,
 output                        cfg_trn_pending,
 output                        cfg_pm_wake,
 input   [7:0]                 cfg_bus_number,
 input   [4:0]                 cfg_device_number,
 input   [2:0]                 cfg_function_number,
 output [1:0]                  pl_directed_link_change,
 output [1:0]                  pl_directed_link_width,
 output                        pl_directed_link_speed,
 output                        pl_directed_link_auton,
 output                        pl_upstream_prefer_deemph,
 output [63:0]                 cfg_dsn,
 //user
 output                        user_clk_o,
 output                        user_reset_o,
 input                         user_intr_req_i,
 output                        user_intr_ack_o,
 output                        user_str_data_valid_o,
 input                         user_str_ack_i,
 output [C_DATA_WIDTH-1:0]     user_str_data_o,
 input                         user_str_data_valid_i,
 output                        user_str_ack_o,
 input  [C_DATA_WIDTH-1:0]     user_str_data_i,
 output  [31:0]                sys_user_dma_addr_o,
 output  [31:0]                user_sys_dma_addr_o,
 output  [31:0]                sys_user_dma_len_o, 
 output  [31:0]                user_sys_dma_len_o, 
 output                        user_sys_dma_en_o,
 output                        sys_user_dma_en_o,
 
 output [31:0]                 user_data_o,   
 output [31:0]                 user_addr_o,   
 output                        user_wr_req_o, 
 input                         user_wr_ack_i,
 input  [31:0]                 user_data_i,   
 input                         user_rd_ack_i, 
 output                        user_rd_req_o, 
 
//icap 100MHz clock from PCIe clock generator
 input                         icap_clk_i
);

wire [15:0]       cfg_completer_id  = {cfg_bus_number, cfg_device_number, cfg_function_number};
wire  [2:0]       req_tc;
wire  [1:0]       req_attr;
wire  [9:0]       req_len;
wire  [15:0]      req_rid;
wire  [7:0]       req_tag;
wire  [6:0]       req_addr;
wire  [7:0]       tlp_type;
wire  [31:0]      sys_user_dma_rd_addr;
wire  [11:0]      sys_user_dma_req_len;
wire  [31:0]      dma_len;
wire              engine_reset_n;
wire [31:0]       reg_data;
wire [31:0]       fpga_reg_data;
wire [31:0]       fpga_reg_value;
wire [9:0]        fpga_reg_addr;
wire [C_DATA_WIDTH-1:0]  rcvd_data;
wire [C_DATA_WIDTH-1:0]  dma_rd_data;
wire [10:0]       rd_fifo_data_cnt;
wire [C_DATA_WIDTH-1:0]     user_str_data;
wire [7:0]        cpld_tag;
wire [31:0]       user1_sys_dma_wr_addr;
wire [31:0]       user1_sys_dma_addr;
wire [31:0]       user_str1_dma_len;
wire [31:0]       user_str1_dma_addr;
wire [31:0]       user1_sys_wr_addr;
wire [C_DATA_WIDTH-1:0]       user1_sys_data;
wire [4:0]        user1_sys_data_len;
wire [31:0]       user1_str_wr_addr;
wire [31:0]       user_sys_wr_addr;
wire [31:0]       sys_user1_dma_addr;
wire [31:0]       user_str1_wr_addr;
wire [4:0]        user1_str_data_len;
wire              user1_str_data_rd;
wire              user1_str_wr_ack;
wire              user1_str_data_avail;
wire       [1:0]  user1_clk_sel;
wire              user1_sys_data_avail;
wire              user1_sys_data_rd;
wire              user1_sys_sream_done;


wire [7:0]        sys_user1_dma_tag;

wire [7:0]        dma_rd_tag;
wire [31:0]       user1_sys_stream_len;
wire [31:0]       sys_user1_dma_rd_addr;
wire              sys_user1_dma_req_done;

wire              sys_user1_dma_req;

wire              config_rd_req;
wire       [31:0] config_rd_req_addr;
wire       [11:0] config_rd_req_len; 
wire              config_rd_req_ack;
wire       [7:0]  config_req_tag;
wire       [31:0] config_src_addr;
wire       [31:0] config_len;
wire              config_strm_en;
wire              config_done;
wire              config_done_ack;
wire              user_clk_swch;
wire              tx_src_dsc;
wire      [C_DATA_WIDTH-1:0]  user_sys_data;
wire      [C_DATA_WIDTH-1:0]  user_str1_data;
wire      [1:0]   user_clk_sel;
wire      [7:0]   sys_user_dma_tag;
wire      [4:0]   user_sys_data_len;
wire      [4:0]   user_str1_data_len;
wire      [11:0]  sys_user1_dma_req_len;



//
// Core input tie-offs
//
assign fc_sel = 3'b100;
assign rx_np_ok = 1'b1;
assign s_axis_tx_tuser[0] = 1'b0; // Unused for V6
assign s_axis_tx_tuser[1] = 1'b0; // Error forward packet
assign s_axis_tx_tuser[2] = 1'b0; // Stream packet
assign tx_cfg_gnt = 1'b1;
assign cfg_err_cor = 1'b0;
assign cfg_err_ur = 1'b0;
assign cfg_err_ecrc = 1'b0;
assign cfg_err_cpl_timeout = 1'b0;
assign cfg_err_cpl_abort = 1'b0;
assign cfg_err_cpl_unexpect = 1'b0;
assign cfg_err_posted = 1'b0;
assign cfg_err_locked = 1'b0;
assign cfg_pm_wake = 1'b0;
assign cfg_trn_pending = 1'b0;
assign cfg_interrupt_assert = 1'b0;
assign cfg_dwaddr = 0;
assign cfg_rd_en = 0;
assign cfg_turnoff_ok = 1'b0;
assign pl_directed_link_change = 0;
assign pl_directed_link_width = 0;
assign pl_directed_link_speed = 0;
assign pl_directed_link_auton = 0;
assign pl_upstream_prefer_deemph = 1'b1;
assign cfg_interrupt_di = 8'b0;
assign cfg_err_tlp_cpl_header = 48'h0;
assign cfg_di = 0;
assign cfg_byte_en = 4'h0;
assign cfg_wr_en = 0;
assign cfg_dsn = {`PCI_EXP_EP_DSN_2, `PCI_EXP_EP_DSN_1};
assign s_axis_tx_tuser[3]  = tx_src_dsc;
assign engine_reset_n = user_lnk_up && !user_reset;


assign user_sys_dma_en_o  = user1_sys_strm_en;
assign sys_user_dma_en_o  = user_str1_en;

assign user_reset_o = system_soft_reset;
  //
  //Receive Controller
  //

  rx_engine #(
    .C_DATA_WIDTH( C_DATA_WIDTH )
  ) rx_engine (
    .clk_i(pcie_core_clk),                              
    .rst_n(engine_reset_n),                          
    //AXIS RX
    .m_axis_rx_tdata( m_axis_rx_tdata ),    
    .m_axis_rx_tlast( m_axis_rx_tlast ),    
    .m_axis_rx_tvalid( m_axis_rx_tvalid ),  
    .m_axis_rx_tready( m_axis_rx_tready ), 
    .m_axis_rx_tuser (m_axis_rx_tuser), 
    //Tx engine
    .compl_done_i(compl_done),
    .req_compl_wd_o(req_compl_wd),          
    .tx_reg_data_o(reg_data),
    .req_tc_o(req_tc),
    .req_td_o(req_td),
    .req_ep_o(req_ep),
    .req_attr_o(req_attr),
    .req_len_o(req_len),
    .req_rid_o(req_rid),
    .req_tag_o(req_tag),                 
    .req_addr_o(req_addr),   
    //Register file
    .reg_data_o({fpga_reg_data[7:0],fpga_reg_data[15:8],fpga_reg_data[23:16],fpga_reg_data[31:24]}),
    .reg_data_valid_o(fpga_reg_data_valid),
    .reg_addr_o(fpga_reg_addr),
    .fpga_reg_wr_ack_i(fpga_reg_wr_ack),   
    .fpga_reg_rd_o(fpga_reg_rd),
    .reg_data_i(fpga_reg_value),
    .fpga_reg_rd_ack_i(fpga_reg_rd_ack),
    .cpld_tag_o(cpld_tag),
    //user /if
    .user_data_o({user_data_o[7:0],user_data_o[15:8],user_data_o[23:16],user_data_o[31:24]}), 
    .user_wr_req_o(user_wr_req_o),
    .user_wr_ack_i(user_wr_ack_i),
    .user_data_i(user_data_i),
    .user_rd_ack_i(user_rd_ack_i), 
    .user_rd_req_o(user_rd_req_o),	
    //Stream
    .rcvd_data_o({rcvd_data[103:96],rcvd_data[111:104],rcvd_data[119:112],rcvd_data[127:120],rcvd_data[71:64],rcvd_data[79:72],rcvd_data[87:80],rcvd_data[95:88],rcvd_data[39:32],rcvd_data[47:40],rcvd_data[55:48],rcvd_data[63:56],rcvd_data[7:0],rcvd_data[15:8],rcvd_data[23:16],rcvd_data[31:24]}),
    .rcvd_data_valid_o(rcvd_data_valid)
  );

  //
  // Register file
  //

  reg_file reg_file (
    .clk_i(pcie_core_clk),
    .rst_n(engine_reset_n), 
    .system_soft_reset_o(system_soft_reset),
    //Rx engine
    .addr_i(fpga_reg_addr), 
    .data_i(fpga_reg_data), 
    .data_valid_i(fpga_reg_data_valid), 
    .fpga_reg_wr_ack_o(fpga_reg_wr_ack),
    .fpga_reg_rd_i(fpga_reg_rd),
    .fpga_reg_rd_ack_o(fpga_reg_rd_ack),
    .data_o(fpga_reg_value),
    //User stream controllers
    //1 
    .o_user_str1_en(user_str1_en),
    .i_user_str1_done(user_str1_done),
    .o_user_str1_done_ack(user_str1_done_ack),
    .o_user_str1_dma_addr(user_str1_dma_addr),
    .o_user_str1_dma_len(user_str1_dma_len), 
    .user1_sys_strm_en_o(user1_sys_strm_en),
    .user1_sys_dma_wr_addr_o(user1_sys_dma_wr_addr), 
    .user1_sys_stream_len_o(user1_sys_stream_len), 
    .user1_sys_strm_done_i(user1_sys_strm_done),
    .user1_sys_strm_done_ack_o(user1_sys_strm_done_ack), 
    .o_sys_user1_dma_addr(sys_user1_dma_addr),
    .o_user1_sys_dma_addr(user1_sys_dma_addr), 
    //reconfig
    .i_icap_clk(icap_clk_i),
    .o_conf_addr(config_src_addr),
    .o_conf_len(config_len),
    .o_conf_req(config_strm_en),
    .i_config_done(config_done),
    .o_conf_done_ack(config_done_ack),
     //clock
    .user_clk_swch_o(user_clk_swch),
    .user_clk_sel_o(user_clk_sel),
    //interrupt
    .intr_req_o(intr_req),
    .intr_req_done_i(intr_done),
    .user_intr_req_i(user_intr_req_i),
    .user_intr_ack_o(user_intr_ack_o),
    //Misc
    .user_reset_o(),///////////////
    .user_addr_o(user_addr_o),
    //Link status
    .i_pcie_link_stat(user_lnk_up)
  );  
  
   
  //
  //Transmit Controller
  //

  tx_engine #(
    .C_DATA_WIDTH( C_DATA_WIDTH ),
    .KEEP_WIDTH( KEEP_WIDTH )
  )tx_engine(
    .clk_i(pcie_core_clk),                         
    .rst_n(engine_reset_n),                   
    // AXIS Tx
    .s_axis_tx_tready( s_axis_tx_tready ),    
    .s_axis_tx_tdata( s_axis_tx_tdata ),      
    .s_axis_tx_tkeep( s_axis_tx_tkeep ),      
    .s_axis_tx_tlast( s_axis_tx_tlast ),      
    .s_axis_tx_tvalid( s_axis_tx_tvalid ),    
    .tx_src_dsc(tx_src_dsc),  
    //Rx engine
    .req_compl_wd_i(req_compl_wd),
    .compl_done_o(compl_done), 
    .req_tc_i(req_tc),             
    .req_td_i(req_td),             
    .req_ep_i(req_ep),             
    .req_attr_i(req_attr),         
    .req_len_i(req_len),           
    .req_rid_i(req_rid),           
    .req_tag_i(req_tag),           
    .req_addr_i(req_addr), 
    .completer_id_i(cfg_completer_id),              
    //Register set
    .reg_data_i({reg_data[7:0],reg_data[15:8],reg_data[23:16],reg_data[31:24]}), 
    //config control
    .config_dma_req_i(config_rd_req),
    .config_dma_rd_addr_i(config_rd_req_addr),
    .config_dma_req_len_i(config_rd_req_len),
    .config_dma_req_done_o(config_rd_req_ack),
    .config_dma_req_tag_i(config_req_tag), 
    //DRA 
    .sys_user_dma_req_i(sys_user_dma_req),
    .sys_user_dma_req_done_o(sys_user_dma_req_done),
    .sys_user_dma_req_len_i(sys_user_dma_req_len),
    .sys_user_dma_rd_addr_i(sys_user_dma_rd_addr),
    .sys_user_dma_tag_i(sys_user_dma_tag),
    //User stream interface
    .user_str_data_avail_i(user_sys_data_avail),
    .user_sys_dma_wr_addr_i(user_sys_wr_addr),
    .user_str_data_rd_o(user_sys_data_rd),
    .user_str_data_i({user_sys_data[103:96],user_sys_data[111:104],user_sys_data[119:112],user_sys_data[127:120],user_sys_data[71:64],user_sys_data[79:72],user_sys_data[87:80],user_sys_data[95:88],user_sys_data[39:32],user_sys_data[47:40],user_sys_data[55:48],user_sys_data[63:56],user_sys_data[7:0],user_sys_data[15:8],user_sys_data[23:16],user_sys_data[31:24]}),
    .user_str_len_i(user_sys_data_len),
    .user_str_dma_done_o(user_sys_sream_done),
    //Interrupt
    .intr_req_i(intr_req),
    .intr_req_done_o(intr_done),
    .cfg_interrupt_o(cfg_interrupt),
    .cfg_interrupt_rdy_i(cfg_interrupt_rdy)
);
  
  user_pcie_stream_generator
  #(
  .TAG1(8'd1),
  .TAG2(8'd2)
  )
  psg1
  (
    .clk_i(pcie_core_clk),
    .rst_n(system_soft_reset),
    .sys_user_strm_en_i(user_str1_en),
    .user_sys_strm_en_i(user1_sys_strm_en),
    .dma_done_o(user_str1_done),
    .dma_done_ack_i(user_str1_done_ack),
    .dma_rd_req_o(sys_user1_dma_req),
    .dma_req_ack_i(sys_user1_dma_req_done),
    .dma_rd_req_len_o(sys_user1_dma_req_len),
    .dma_rd_req_addr_o(sys_user1_dma_rd_addr),
    .dma_src_addr_i(user_str1_dma_addr),
    .dma_len_i(user_str1_dma_len),
    .sys_user_dma_addr_i(sys_user1_dma_addr),
    .user_sys_dma_addr_i(user1_sys_dma_addr),
    .dma_tag_i(cpld_tag),
    .dma_data_valid_i(rcvd_data_valid),
    .dma_data_i(rcvd_data),
    .dma_tag_o(sys_user1_dma_tag),
    .stream_len_i(user1_sys_stream_len), 
    .user_sys_strm_done_o(user1_sys_strm_done), 
    .user_sys_strm_done_ack(user1_sys_strm_done_ack),
    .dma_wr_start_addr_i(user1_sys_dma_wr_addr),
	 
    .stream_data_valid_o(user_str_data_valid_o),
    .stream_data_ready_i(user_str_ack_i),
    .stream_data_o(user_str_data_o),
    .sys_user_dma_addr_o(sys_user_dma_addr_o),
    .sys_user_dma_len_o(sys_user_dma_len_o),
	 
    .stream_data_valid_i(user_str_data_valid_i),
    .stream_data_ready_o(user_str_ack_o),
    .stream_data_i(user_str_data_i), 
    .user_sys_dma_addr_o(user_sys_dma_addr_o),
    .user_sys_dma_len_o(user_sys_dma_len_o),
	 
    .user_stream_data_avail_o(user_str1_data_avail), 
    .user_stream_data_rd_i(user_str1_data_rd),
    .user_stream_data_o(user_str1_data),
    .user_stream_data_len_o(user_str1_data_len),
    .user_stream_wr_addr_o(user_str1_wr_addr),
    .user_stream_wr_ack_i(user_str1_wr_ack)
  );
  
   user_dma_req_arbitrator #(
    .NUM_SLAVES(NUM_PCIE_STRM)
    )
   dra
   (
    .i_clk(pcie_core_clk),
    .i_rst_n(system_soft_reset),
    //To PSG slaves
    .i_slave_dma_req(sys_user1_dma_req),
    .i_slave_dma_addr(sys_user1_dma_rd_addr),
    .i_slave_dma_len(sys_user1_dma_req_len),
    .i_slave_dma_tag(sys_user1_dma_tag),
    .o_slave_dma_ack(sys_user1_dma_req_done), 
    .i_slave_dma_data_avail(user_str1_data_avail),
    .i_slave_dma_wr_addr(user_str1_wr_addr),
    .o_slave_dma_data_rd(user_str1_data_rd),
    .i_slave_dma_data(user_str1_data),
    .i_slave_dma_wr_len(user_str1_data_len),
    .o_slave_dma_done(user_str1_wr_ack),
    //To PCIe Tx engine
    .o_dma_req(sys_user_dma_req),
    .i_dma_ack(sys_user_dma_req_done),
    .o_dma_req_addr(sys_user_dma_rd_addr),
    .o_dma_req_len(sys_user_dma_req_len),
    .o_dma_req_tag(sys_user_dma_tag),
    //
    .o_dma_data_avail(user_sys_data_avail),
    .o_dma_wr_addr(user_sys_wr_addr),
    .i_dma_data_rd(user_sys_data_rd),
    .o_dma_data(user_sys_data),
    .o_dma_len(user_sys_data_len),
    .i_dma_done(user_sys_sream_done)
    );

assign user_clk_o = pcie_core_clk;

generate
    if(RECONFIG_ENABLE == 1)
    begin:gen1
// Instantiate the module
    config_controller config_ctrl (
        .i_pcie_clk(pcie_core_clk), 
        .i_rst_n(system_soft_reset),
        .i_icap_clk(icap_clk_i), 
        .i_config_data({rcvd_data[31:0],rcvd_data[63:32],rcvd_data[95:64],rcvd_data[127:96]}),
        .i_config_data_valid(rcvd_data_valid), 
        .config_rd_req_o(config_rd_req), 
        .config_done_o(config_done), 
        .config_rd_req_addr_o(config_rd_req_addr), 
        .config_len_i(config_len), 
        .config_strm_en_i(config_strm_en), 
        .config_rd_req_len_o(config_rd_req_len), 
        .dma_tag_i(cpld_tag), 
        .config_rd_req_ack_i(config_rd_req_ack), 
        .dma_tag_o(config_req_tag),
        .config_done_ack_i(config_done_ack), 
        .config_src_addr_i(config_src_addr)
    );
    end
endgenerate
  

endmodule
