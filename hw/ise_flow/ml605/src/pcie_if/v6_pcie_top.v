//--------------------------------------------------------------------------------
// Project    : SWITCH
// File       : pcie_top.v
// Version    : 0.1
// Author     : Vipin.K
//
// Description: Instantiates the Xilinx PCIe endpoint and the PCIe interface logic
//              
//--------------------------------------------------------------------------------

module pcie_top # (
  parameter PL_FAST_TRAIN    = "FALSE",
  parameter C_DATA_WIDTH     = 64,            // RX/TX interface data width
  parameter KEEP_WIDTH       = C_DATA_WIDTH / 8,               // KEEP width
  parameter NUM_PCIE_STRM    = 4,
  parameter RECONFIG_ENABLE  = 1,
  parameter RCM_ENABLE       = 1
)
(
  output  [3:0]        pci_exp_txp,
  output  [3:0]        pci_exp_txn,
  input   [3:0]        pci_exp_rxp,
  input   [3:0]        pci_exp_rxn,     
  input                sys_clk_p,
  input                sys_clk_n,
  input                sys_reset_n,
  output               user_clk_o,
  output               pcie_clk_o,
  output               user_reset_o,
  output  [31:0]       user_data_o,
  output  [19:0]       user_addr_o,
  output               user_wr_req_o,
  input  [31:0]        user_data_i,
  input                user_rd_ack_i,
  output               user_rd_req_o,
  input                user_intr_req_i,
  output               user_intr_ack_o,
  //user stream interface
  output               user_str1_data_valid_o,
  input                user_str1_ack_i,
  output [63:0]        user_str1_data_o,
  input                user_str1_data_valid_i,
  output               user_str1_ack_o,
  input  [63:0]        user_str1_data_i,
  output               user_str2_data_valid_o,
  input                user_str2_ack_i,
  output [63:0]        user_str2_data_o,
  input                user_str2_data_valid_i,
  output               user_str2_ack_o,
  input  [63:0]        user_str2_data_i,
  output               user_str3_data_valid_o,
  input                user_str3_ack_i,
  output [63:0]        user_str3_data_o,
  input                user_str3_data_valid_i,
  output               user_str3_ack_o,
  input  [63:0]        user_str3_data_i,
  output               user_str4_data_valid_o,
  input                user_str4_ack_i,
  output [63:0]        user_str4_data_o,
  input                user_str4_data_valid_i,
  output               user_str4_ack_o,
  input  [63:0]        user_str4_data_i,
  output               pcie_link_status
  );


  // Tx
  wire [5:0]                                  tx_buf_av;
  wire [3:0]                                  s_axis_tx_tuser;
  wire [C_DATA_WIDTH-1:0]                     s_axis_tx_tdata;
  wire [KEEP_WIDTH-1:0]                       s_axis_tx_tkeep;
  // Rx
  wire [C_DATA_WIDTH-1:0]                     m_axis_rx_tdata;
  wire [KEEP_WIDTH-1:0]                       m_axis_rx_tkeep;
  wire  [21:0]                                m_axis_rx_tuser;

  // Flow Control
  wire [11:0]                                 fc_cpld;
  wire [7:0]                                  fc_cplh;
  wire [11:0]                                 fc_npd;
  wire [7:0]                                  fc_nph;
  wire [11:0]                                 fc_pd;
  wire [7:0]                                  fc_ph;
  wire [2:0]                                  fc_sel;


  //-------------------------------------------------------
  // 3. Configuration (CFG) Interface
  //-------------------------------------------------------

  wire  [31:0]                                cfg_do;
  wire  [31:0]                                cfg_di;
  wire  [3:0]                                 cfg_byte_en;
  wire  [9:0]                                 cfg_dwaddr;
  wire  [47:0]                                cfg_err_tlp_cpl_header;
  wire  [7:0]                                 cfg_interrupt_di;
  wire  [7:0]                                 cfg_interrupt_do;
  wire  [2:0]                                 cfg_interrupt_mmenable;
  wire  [7:0]                                 cfg_bus_number;
  wire  [4:0]                                 cfg_device_number;
  wire  [2:0]                                 cfg_function_number;
  wire  [15:0]                                cfg_status;
  wire  [15:0]                                cfg_command;
  wire  [15:0]                                cfg_dstatus;
  wire  [15:0]                                cfg_dcommand;
  wire  [15:0]                                cfg_lstatus;
  wire  [15:0]                                cfg_lcommand;
  wire  [15:0]                                cfg_dcommand2;
  wire  [2:0]                                 cfg_pcie_link_state;
  wire  [63:0]                                cfg_dsn;

  //-------------------------------------------------------
  // 4. Physical Layer Control and Status (PL) Interface
  //-------------------------------------------------------

  wire [2:0]                                  pl_initial_link_width;
  wire [1:0]                                  pl_lane_reversal_mode;
  wire [5:0]                                  pl_ltssm_state;
  wire [1:0]                                  pl_sel_link_width;
  wire [1:0]                                  pl_directed_link_change;
  wire [1:0]                                  pl_directed_link_width;

  //-------------------------------------------------------

IBUFDS_GTXE1 refclk_ibuf (.O(sys_clk_c), .ODIV2(), .I(sys_clk_p), .IB(sys_clk_n), .CEB(1'b0));

assign pcie_link_status = user_lnk_up_int1;
assign pcie_clk_o = user_clk;


v6_pcie_v2_5 #(
  .PL_FAST_TRAIN    ( PL_FAST_TRAIN )
) core (

  //-------------------------------------------------------
  // 1. PCI Express (pci_exp) Interface
  //-------------------------------------------------------

  // Tx
  .pci_exp_txp( pci_exp_txp ),
  .pci_exp_txn( pci_exp_txn ),

  // Rx
  .pci_exp_rxp( pci_exp_rxp ),
  .pci_exp_rxn( pci_exp_rxn ),

  //-------------------------------------------------------
  // 2. AXI-S Interface
  //-------------------------------------------------------

  // Common
  .user_clk_out( user_clk ),
  .user_reset_out( user_reset_int1 ),
  .user_lnk_up( user_lnk_up_int1 ),
  .icap_clk(icap_clk),

  // Tx
  .s_axis_tx_tready( s_axis_tx_tready ),
  .s_axis_tx_tdata( s_axis_tx_tdata ),
  .s_axis_tx_tkeep( s_axis_tx_tkeep ),
  .s_axis_tx_tuser( s_axis_tx_tuser ),
  .s_axis_tx_tlast( s_axis_tx_tlast ),
  .s_axis_tx_tvalid( s_axis_tx_tvalid ),
  .tx_cfg_gnt( tx_cfg_gnt ),
  .tx_cfg_req( tx_cfg_req ),
  .tx_buf_av( tx_buf_av ),
  .tx_err_drop( tx_err_drop ),

  // Rx
  .m_axis_rx_tdata( m_axis_rx_tdata ),
  .m_axis_rx_tkeep( m_axis_rx_tkeep ),
  .m_axis_rx_tlast( m_axis_rx_tlast ),
  .m_axis_rx_tvalid( m_axis_rx_tvalid ),
  .m_axis_rx_tready( m_axis_rx_tready ),
  .m_axis_rx_tuser ( m_axis_rx_tuser ),
  .rx_np_ok( rx_np_ok ),

  // Flow Control
  .fc_cpld( fc_cpld ),
  .fc_cplh( fc_cplh ),
  .fc_npd( fc_npd ),
  .fc_nph( fc_nph ),
  .fc_pd( fc_pd ),
  .fc_ph( fc_ph ),
  .fc_sel( fc_sel ),


  //-------------------------------------------------------
  // 3. Configuration (CFG) Interface
  //-------------------------------------------------------

  .cfg_do( cfg_do ),
  .cfg_rd_wr_done( cfg_rd_wr_done),
  .cfg_di( cfg_di ),
  .cfg_byte_en( cfg_byte_en ),
  .cfg_dwaddr( cfg_dwaddr ),
  .cfg_wr_en( cfg_wr_en ),
  .cfg_rd_en( cfg_rd_en ),

  .cfg_err_cor( cfg_err_cor ),
  .cfg_err_ur( cfg_err_ur ),
  .cfg_err_ecrc( cfg_err_ecrc ),
  .cfg_err_cpl_timeout( cfg_err_cpl_timeout ),
  .cfg_err_cpl_abort( cfg_err_cpl_abort ),
  .cfg_err_cpl_unexpect( cfg_err_cpl_unexpect ),
  .cfg_err_posted( cfg_err_posted ),
  .cfg_err_locked( cfg_err_locked ),
  .cfg_err_tlp_cpl_header( cfg_err_tlp_cpl_header ),
  .cfg_err_cpl_rdy( cfg_err_cpl_rdy ),
  .cfg_interrupt( cfg_interrupt ),
  .cfg_interrupt_rdy( cfg_interrupt_rdy ),
  .cfg_interrupt_assert( cfg_interrupt_assert ),
  .cfg_interrupt_di( cfg_interrupt_di ),
  .cfg_interrupt_do( cfg_interrupt_do ),
  .cfg_interrupt_mmenable( cfg_interrupt_mmenable ),
  .cfg_interrupt_msienable( cfg_interrupt_msienable ),
  .cfg_interrupt_msixenable( cfg_interrupt_msixenable ),
  .cfg_interrupt_msixfm( cfg_interrupt_msixfm ),
  .cfg_turnoff_ok( cfg_turnoff_ok ),
  .cfg_to_turnoff( cfg_to_turnoff ),
  .cfg_trn_pending( cfg_trn_pending ),
  .cfg_pm_wake( cfg_pm_wake ),
  .cfg_bus_number( cfg_bus_number ),
  .cfg_device_number( cfg_device_number ),
  .cfg_function_number( cfg_function_number ),
  .cfg_status( cfg_status ),
  .cfg_command( cfg_command ),
  .cfg_dstatus( cfg_dstatus ),
  .cfg_dcommand( cfg_dcommand ),
  .cfg_lstatus( cfg_lstatus ),
  .cfg_lcommand( cfg_lcommand ),
  .cfg_dcommand2( cfg_dcommand2 ),
  .cfg_pcie_link_state( cfg_pcie_link_state ),
  .cfg_dsn( cfg_dsn ),
  .cfg_pmcsr_pme_en( ),
  .cfg_pmcsr_pme_status( ),
  .cfg_pmcsr_powerstate( ),

  //-------------------------------------------------------
  // 4. Physical Layer Control and Status (PL) Interface
  //-------------------------------------------------------

  .pl_initial_link_width( pl_initial_link_width ),
  .pl_lane_reversal_mode( pl_lane_reversal_mode ),
  .pl_link_gen2_capable( pl_link_gen2_capable ),
  .pl_link_partner_gen2_supported( pl_link_partner_gen2_supported ),
  .pl_link_upcfg_capable( pl_link_upcfg_capable ),
  .pl_ltssm_state( pl_ltssm_state ),
  .pl_received_hot_rst( pl_received_hot_rst ),
  .pl_sel_link_rate( pl_sel_link_rate ),
  .pl_sel_link_width( pl_sel_link_width ),
  .pl_directed_link_auton( pl_directed_link_auton ),
  .pl_directed_link_change( pl_directed_link_change ),
  .pl_directed_link_speed( pl_directed_link_speed ),
  .pl_directed_link_width( pl_directed_link_width ),
  .pl_upstream_prefer_deemph( pl_upstream_prefer_deemph ),

  //-------------------------------------------------------
  // 5. System  (SYS) Interface
  //-------------------------------------------------------

  .sys_clk( sys_clk_c ),
  .sys_reset( !sys_reset_n )
);


pcie_app  #(
   .C_DATA_WIDTH( C_DATA_WIDTH ),
   .KEEP_WIDTH( KEEP_WIDTH ),
   .NUM_PCIE_STRM(NUM_PCIE_STRM),
   .RECONFIG_ENABLE(RECONFIG_ENABLE),
   .RCM_ENABLE(RCM_ENABLE)
    )app (

    //-------------------------------------------------------
    // 1. AXI-S Interface
    //-------------------------------------------------------

    // Common
    .pcie_core_clk( user_clk ),
    .user_reset( user_reset_int1 ),
    .user_lnk_up( user_lnk_up_int1 ),

    // Tx

    .s_axis_tx_tready( s_axis_tx_tready ),
    .s_axis_tx_tdata( s_axis_tx_tdata ),
    .s_axis_tx_tkeep( s_axis_tx_tkeep ),
    .s_axis_tx_tuser( s_axis_tx_tuser ),
    .s_axis_tx_tlast( s_axis_tx_tlast ),
    .s_axis_tx_tvalid( s_axis_tx_tvalid ),
    .tx_cfg_gnt( tx_cfg_gnt ),

    // Rx
    .m_axis_rx_tdata( m_axis_rx_tdata ),
    .m_axis_rx_tlast( m_axis_rx_tlast ),
    .m_axis_rx_tvalid( m_axis_rx_tvalid ),
    .m_axis_rx_tready( m_axis_rx_tready ),
    .rx_np_ok( rx_np_ok ),
    .fc_sel( fc_sel ),
    //-------------------------------------------------------
    // 2. Configuration (CFG) Interface
    //-------------------------------------------------------
    .cfg_di( cfg_di ),
    .cfg_byte_en( cfg_byte_en ),
    .cfg_dwaddr( cfg_dwaddr ),
    .cfg_wr_en( cfg_wr_en ),
    .cfg_rd_en( cfg_rd_en ),
    .cfg_err_cor( cfg_err_cor ),
    .cfg_err_ur( cfg_err_ur ),
    .cfg_err_ecrc( cfg_err_ecrc ),
    .cfg_err_cpl_timeout( cfg_err_cpl_timeout ),
    .cfg_err_cpl_abort( cfg_err_cpl_abort ),
    .cfg_err_cpl_unexpect( cfg_err_cpl_unexpect ),
    .cfg_err_posted( cfg_err_posted ),
    .cfg_err_locked( cfg_err_locked ),
    .cfg_err_tlp_cpl_header( cfg_err_tlp_cpl_header ),
    .cfg_interrupt( cfg_interrupt ),
    .cfg_interrupt_rdy( cfg_interrupt_rdy ),
    .cfg_interrupt_assert( cfg_interrupt_assert ),
    .cfg_interrupt_di( cfg_interrupt_di ),
    .cfg_turnoff_ok( cfg_turnoff_ok ),
    .cfg_trn_pending( cfg_trn_pending ),
    .cfg_pm_wake( cfg_pm_wake ),
    .cfg_bus_number( cfg_bus_number ),
    .cfg_device_number( cfg_device_number ),
    .cfg_function_number( cfg_function_number ),
    .cfg_dsn( cfg_dsn ),

    //-------------------------------------------------------
    // 3. Physical Layer Control and Status (PL) Interface
    //-------------------------------------------------------
    .pl_directed_link_auton( pl_directed_link_auton ),
    .pl_directed_link_change( pl_directed_link_change ),
    .pl_directed_link_speed( pl_directed_link_speed ),
    .pl_directed_link_width( pl_directed_link_width ),
    .pl_upstream_prefer_deemph( pl_upstream_prefer_deemph ),
    .user_clk_o(user_clk_o),
    .user_reset_o(user_reset_o),
    .user_data_o(user_data_o),
    .user_addr_o(user_addr_o),
    .user_wr_req_o(user_wr_req_o),
    .user_data_i(user_data_i),
    .user_rd_ack_i(user_rd_ack_i),
    .user_rd_req_o(user_rd_req_o),
    .user_intr_req_i(user_intr_req_i),
    .user_intr_ack_o(user_intr_ack_o),
    .user_str1_data_valid_o(user_str1_data_valid_o),
    .user_str1_ack_i(user_str1_ack_i),
    .user_str1_data_o(user_str1_data_o),
    .user_str1_data_valid_i(user_str1_data_valid_i),
    .user_str1_ack_o(user_str1_ack_o),
    .user_str1_data_i(user_str1_data_i),
    .user_str2_data_valid_o(user_str2_data_valid_o),
    .user_str2_ack_i(user_str2_ack_i),
    .user_str2_data_o(user_str2_data_o),
    .user_str2_data_valid_i(user_str2_data_valid_i),
    .user_str2_ack_o(user_str2_ack_o),
    .user_str2_data_i(user_str2_data_i),
    .user_str3_data_valid_o(user_str3_data_valid_o),
    .user_str3_ack_i(user_str3_ack_i),
    .user_str3_data_o(user_str3_data_o),
    .user_str3_data_valid_i(user_str3_data_valid_i),
    .user_str3_ack_o(user_str3_ack_o),
    .user_str3_data_i(user_str3_data_i),
    .user_str4_data_valid_o(user_str4_data_valid_o),
    .user_str4_ack_i(user_str4_ack_i),
    .user_str4_data_o(user_str4_data_o),
    .user_str4_data_valid_i(user_str4_data_valid_i),
    .user_str4_ack_o(user_str4_ack_o),
    .user_str4_data_i(user_str4_data_i),
    .icap_clk_i(icap_clk)	 
);


endmodule
