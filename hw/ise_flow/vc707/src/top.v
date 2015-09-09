module top(
  input   [3:0]        pci_exp_rxp,
  input   [3:0]        pci_exp_rxn, 
  output  [3:0]        pci_exp_txp,
  output  [3:0]        pci_exp_txn,  
  input                sys_clk_p,
  input                sys_clk_n,
  input                sys_reset_n,
  output               pcie_link_status,
  output               heartbeat
);

wire [31:0]  user_wr_data;
wire [19:0]  user_addr;
wire [31:0]  user_rd_data;
wire [63:0]  user_str1_wr_data;
wire [63:0]  user_str1_rd_data;
wire [63:0]  user_str2_wr_data;
wire [63:0]  user_str2_rd_data;
wire [63:0]  user_str3_wr_data;
wire [63:0]  user_str3_rd_data;
wire [63:0]  user_str4_wr_data;
wire [63:0]  user_str4_rd_data;


// Instantiate the module
(*KEEP_HIERARCHY = "SOFT"*)
pcie_top pcie (
    .pci_exp_txp(pci_exp_txp), 
    .pci_exp_txn(pci_exp_txn), 
    .pci_exp_rxp(pci_exp_rxp), 
    .pci_exp_rxn(pci_exp_rxn), 
    .sys_clk_p(sys_clk_p), 
    .sys_clk_n(sys_clk_n), 
    .sys_reset_n(sys_reset_n), 
    .user_clk_o(user_clk), 
	 .pcie_clk_o(pcie_clk),
    .user_reset_o(user_reset), 
    .user_data_o(user_wr_data), 
    .user_addr_o(user_addr), 
    .user_wr_req_o(user_wr_req), 
    .user_data_i(user_rd_data), 
    .user_rd_ack_i(user_data_valid), 
    .user_rd_req_o(user_rd_req), 
    .user_intr_req_i(user_intr_req), 
    .user_intr_ack_o(user_intr_ack), 
    .user_str1_data_valid_o(user_str1_data_wr_valid),
    .user_str1_ack_i(user_str1_wr_ack),
    .user_str1_data_o(user_str1_wr_data),
    .user_str1_data_valid_i(user_str1_data_rd_valid),
    .user_str1_ack_o(user_str1_rd_ack),
    .user_str1_data_i(user_str1_rd_data),
    .user_str2_data_valid_o(user_str2_data_wr_valid),
    .user_str2_ack_i(user_str2_wr_ack),
    .user_str2_data_o(user_str2_wr_data),
    .user_str2_data_valid_i(user_str2_data_rd_valid),
    .user_str2_ack_o(user_str2_rd_ack),
    .user_str2_data_i(user_str2_rd_data),
	 .user_str3_data_valid_o(user_str3_data_wr_valid),
    .user_str3_ack_i(user_str3_wr_ack),
    .user_str3_data_o(user_str3_wr_data),
    .user_str3_data_valid_i(user_str3_data_rd_valid),
    .user_str3_ack_o(user_str3_rd_ack),
    .user_str3_data_i(user_str3_rd_data),
    .user_str4_data_valid_o(user_str4_data_wr_valid),
    .user_str4_ack_i(user_str4_wr_ack),
    .user_str4_data_o(user_str4_wr_data),
    .user_str4_data_valid_i(user_str4_data_rd_valid),
    .user_str4_ack_o(user_str4_rd_ack),
    .user_str4_data_i(user_str4_rd_data),
    .pcie_link_status(pcie_link_status)
    );
	 
	 // Instantiate the module
	 

(*KEEP_HIERARCHY = "SOFT"*)
user_logic_top ult(
	 .i_user_clk(user_clk),
	 .i_pcie_clk(pcie_clk),
    //.i_slow_clk(), //100Mhz  
    .i_rst(user_reset),
     //reg i/f 
    .i_user_data(user_wr_data),
    .i_user_addr(user_addr),
    .i_user_wr_req(user_wr_req),
    .o_user_data(user_rd_data),
    .o_user_rd_ack(user_data_valid),
    .i_user_rd_req(user_rd_req), 
	 //pcie strm 1
    .i_pcie_str1_data_valid(user_str1_data_wr_valid),
    .o_pcie_str1_ack(user_str1_wr_ack),
	 .i_pcie_str1_data(user_str1_wr_data),
    .o_pcie_str1_data_valid(user_str1_data_rd_valid),
    .i_pcie_str1_ack(user_str1_rd_ack),
    .o_pcie_str1_data(user_str1_rd_data),
	 //pcie strm 2
    .i_pcie_str2_data_valid(user_str2_data_wr_valid),
    .o_pcie_str2_ack(user_str2_wr_ack),
    .i_pcie_str2_data(user_str2_wr_data),
    .o_pcie_str2_data_valid(user_str2_data_rd_valid),
    .i_pcie_str2_ack(user_str2_rd_ack),
    .o_pcie_str2_data(user_str2_rd_data),
	 //pcie strm 3
    .i_pcie_str3_data_valid(user_str3_data_wr_valid),
    .o_pcie_str3_ack(user_str3_wr_ack),
	 .i_pcie_str3_data(user_str3_wr_data),
    .o_pcie_str3_data_valid(user_str3_data_rd_valid),
    .i_pcie_str3_ack(user_str3_rd_ack),
    .o_pcie_str3_data(user_str3_rd_data),	 
	 //pcie strm 4
    .i_pcie_str4_data_valid(user_str4_data_wr_valid),
    .o_pcie_str4_ack(user_str4_wr_ack),
	 .i_pcie_str4_data(user_str4_wr_data),
    .o_pcie_str4_data_valid(user_str4_data_rd_valid),
    .i_pcie_str4_ack(user_str4_rd_ack),
    .o_pcie_str4_data(user_str4_rd_data),	 	 
	 //intr
    .o_intr_req(user_intr_req),
    .i_intr_ack(user_intr_ack)
);


reg   [28:0] led_counter;

always @( posedge user_clk)
begin
    led_counter <= led_counter + 1;
end

assign heartbeat = led_counter[27];
	 
endmodule
	 