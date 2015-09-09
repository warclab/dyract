module user_logic_adapter(
    input              i_user_clk,
	 input              i_pcie_clk,
	 input              i_rst,
    //From PCIe section
    //stream i/f 1
    input              i_pcie_str1_data_valid,
    output             o_pcie_str1_ack,
    input    [63:0]    i_pcie_str1_data,
    output             o_pcie_str1_data_valid,
    input              i_pcie_str1_ack,
    output   [63:0]    o_pcie_str1_data,
    //stream i/f 2       
    input              i_pcie_str2_data_valid,
    output             o_pcie_str2_ack,
    input    [63:0]    i_pcie_str2_data,
    output             o_pcie_str2_data_valid,
    input              i_pcie_str2_ack,
    output   [63:0]    o_pcie_str2_data,
    //stream i/f 3
    input              i_pcie_str3_data_valid,
    output             o_pcie_str3_ack,
    input    [63:0]    i_pcie_str3_data,
    output             o_pcie_str3_data_valid,
    input              i_pcie_str3_ack,
    output       [63:0]o_pcie_str3_data,
    //stream i/f 4
    input              i_pcie_str4_data_valid,
    output             o_pcie_str4_ack,
    input    [63:0]    i_pcie_str4_data,
    output             o_pcie_str4_data_valid,
    input              i_pcie_str4_ack,
    output       [63:0]o_pcie_str4_data,
    //From User logic
    input              i_pcie_adpt_str1_data_valid,
    output             o_pcie_adpt_str1_ack,
    input    [63:0]    i_pcie_adpt_str1_data,
    output             o_pcie_adpt_str1_data_valid,
    input              i_pcie_adpt_str1_ack,
    output       [63:0]o_pcie_adpt_str1_data,
    //stream i/f 2       
    input              i_pcie_adpt_str2_data_valid,
    output             o_pcie_adpt_str2_ack,
    input    [63:0]    i_pcie_adpt_str2_data,
    output             o_pcie_adpt_str2_data_valid,
    input              i_pcie_adpt_str2_ack,
    output       [63:0]o_pcie_adpt_str2_data,
    //stream i/f 3
    input              i_pcie_adpt_str3_data_valid,
    output             o_pcie_adpt_str3_ack,
    input    [63:0]    i_pcie_adpt_str3_data,
    output             o_pcie_adpt_str3_data_valid,
    input              i_pcie_adpt_str3_ack,
    output       [63:0]o_pcie_adpt_str3_data,
    //stream i/f 4
    input              i_pcie_adpt_str4_data_valid,
    output             o_pcie_adpt_str4_ack,
    input    [63:0]    i_pcie_adpt_str4_data,
    output             o_pcie_adpt_str4_data_valid,
    input              i_pcie_adpt_str4_ack,
    output       [63:0]o_pcie_adpt_str4_data
);



user_adpt_fifo adpt_wr_fifo_1 (
  .s_aclk(i_pcie_clk), // input s_aclk
  .s_aresetn(i_rst), // input s_aresetn
  .s_axis_tvalid(i_pcie_str1_data_valid), // input s_axis_tvalid
  .s_axis_tready(o_pcie_str1_ack), // output s_axis_tready
  .s_axis_tdata(i_pcie_str1_data), // input [63 : 0] s_axis_tdata
  .m_aclk(i_user_clk),
  .m_axis_tvalid(o_pcie_adpt_str1_data_valid), // output m_axis_tvalid
  .m_axis_tready(i_pcie_adpt_str1_ack), // input m_axis_tready
  .m_axis_tdata(o_pcie_adpt_str1_data)  // output [63 : 0] m_axis_tdata
);

user_adpt_fifo adpt_wr_fifo_2 (
  .s_aclk(i_pcie_clk), // input s_aclk
  .s_aresetn(i_rst), // input s_aresetn
  .s_axis_tvalid(i_pcie_str2_data_valid), // input s_axis_tvalid
  .s_axis_tready(o_pcie_str2_ack), // output s_axis_tready
  .s_axis_tdata(i_pcie_str2_data), // input [63 : 0] s_axis_tdata
  .m_aclk(i_user_clk),
  .m_axis_tvalid(o_pcie_adpt_str2_data_valid), // output m_axis_tvalid
  .m_axis_tready(i_pcie_adpt_str2_ack), // input m_axis_tready
  .m_axis_tdata(o_pcie_adpt_str2_data)  // output [63 : 0] m_axis_tdata
);

user_adpt_fifo adpt_wr_fifo_3 (
  .s_aclk(i_pcie_clk), // input s_aclk
  .s_aresetn(i_rst), // input s_aresetn
  .s_axis_tvalid(i_pcie_str3_data_valid), // input s_axis_tvalid
  .s_axis_tready(o_pcie_str3_ack), // output s_axis_tready
  .s_axis_tdata(i_pcie_str3_data), // input [63 : 0] s_axis_tdata
  .m_aclk(i_user_clk),
  .m_axis_tvalid(o_pcie_adpt_str3_data_valid), // output m_axis_tvalid
  .m_axis_tready(i_pcie_adpt_str3_ack), // input m_axis_tready
  .m_axis_tdata(o_pcie_adpt_str3_data)  // output [63 : 0] m_axis_tdata
);

user_adpt_fifo adpt_wr_fifo_4 (
  .s_aclk(i_pcie_clk), // input s_aclk
  .s_aresetn(i_rst), // input s_aresetn
  .s_axis_tvalid(i_pcie_str4_data_valid), // input s_axis_tvalid
  .s_axis_tready(o_pcie_str4_ack), // output s_axis_tready
  .s_axis_tdata(i_pcie_str4_data), // input [63 : 0] s_axis_tdata
  .m_aclk(i_user_clk),
  .m_axis_tvalid(o_pcie_adpt_str4_data_valid), // output m_axis_tvalid
  .m_axis_tready(i_pcie_adpt_str4_ack), // input m_axis_tready
  .m_axis_tdata(o_pcie_adpt_str4_data)  // output [63 : 0] m_axis_tdata
);



user_adpt_fifo adpt_rd_fifo_1 (
  .s_aclk(i_user_clk), // input s_aclk
  .s_aresetn(i_rst), // input s_aresetn
  .s_axis_tvalid(i_pcie_adpt_str1_data_valid), // input s_axis_tvalid
  .s_axis_tready(o_pcie_adpt_str1_ack), // output s_axis_tready
  .s_axis_tdata(i_pcie_adpt_str1_data), // input [63 : 0] s_axis_tdata
  .m_aclk(i_pcie_clk),
  .m_axis_tvalid(o_pcie_str1_data_valid), // output m_axis_tvalid
  .m_axis_tready(i_pcie_str1_ack), // input m_axis_tready
  .m_axis_tdata(o_pcie_str1_data)  // output [63 : 0] m_axis_tdata
);

user_adpt_fifo adpt_rd_fifo_2 (
  .s_aclk(i_user_clk), // input s_aclk
  .s_aresetn(i_rst), // input s_aresetn
  .s_axis_tvalid(i_pcie_adpt_str2_data_valid), // input s_axis_tvalid
  .s_axis_tready(o_pcie_adpt_str2_ack), // output s_axis_tready
  .s_axis_tdata(i_pcie_adpt_str2_data), // input [63 : 0] s_axis_tdata
  .m_aclk(i_pcie_clk),
  .m_axis_tvalid(o_pcie_str2_data_valid), // output m_axis_tvalid
  .m_axis_tready(i_pcie_str2_ack), // input m_axis_tready
  .m_axis_tdata(o_pcie_str2_data)  // output [63 : 0] m_axis_tdata
);

user_adpt_fifo adpt_rd_fifo_3 (
  .s_aclk(i_user_clk), // input s_aclk
  .s_aresetn(i_rst), // input s_aresetn
  .s_axis_tvalid(i_pcie_adpt_str3_data_valid), // input s_axis_tvalid
  .s_axis_tready(o_pcie_adpt_str3_ack), // output s_axis_tready
  .s_axis_tdata(i_pcie_adpt_str3_data), // input [63 : 0] s_axis_tdata
  .m_aclk(i_pcie_clk),
  .m_axis_tvalid(o_pcie_str3_data_valid), // output m_axis_tvalid
  .m_axis_tready(i_pcie_str3_ack), // input m_axis_tready
  .m_axis_tdata(o_pcie_str3_data)  // output [63 : 0] m_axis_tdata
);

user_adpt_fifo adpt_rd_fifo_4 (
  .s_aclk(i_user_clk), // input s_aclk
  .s_aresetn(i_rst), // input s_aresetn
  .s_axis_tvalid(i_pcie_adpt_str4_data_valid), // input s_axis_tvalid
  .s_axis_tready(o_pcie_adpt_str4_ack), // output s_axis_tready
  .s_axis_tdata(i_pcie_adpt_str4_data), // input [63 : 0] s_axis_tdata
  .m_aclk(i_pcie_clk),
  .m_axis_tvalid(o_pcie_str4_data_valid), // output m_axis_tvalid
  .m_axis_tready(i_pcie_str4_ack), // input m_axis_tready
  .m_axis_tdata(o_pcie_str4_data)  // output [63 : 0] m_axis_tdata
);

endmodule