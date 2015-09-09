//--------------------------------------------------------------------------------
// Project    : SWITCH
// File       : user_logic.v
// Version    : 0.1
// Author     : Vipin.K
//
// Description: A dummy user logic for testing purpose
//--------------------------------------------------------------------------------

module user_logic_top(
    input              i_user_clk,
	 input              i_pcie_clk,
    input              i_rst,
    //reg i/f 
    input    [31:0]    i_user_data,
    input    [19:0]    i_user_addr,
    input              i_user_wr_req,
    output  [31:0]     o_user_data,
    output             o_user_rd_ack,
    input              i_user_rd_req, 
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
    output   [63:0]    o_pcie_str3_data,
    //stream i/f 4
    input              i_pcie_str4_data_valid,
    output             o_pcie_str4_ack,
    input    [63:0]    i_pcie_str4_data,
    output             o_pcie_str4_data_valid,
    input              i_pcie_str4_ack,
    output   [63:0]    o_pcie_str4_data,
    //interrupt if
    output             o_intr_req,
    input              i_intr_ack
);

wire [63:0] adpt_user_str1_data;
wire [63:0] user_adpt_str1_data;
wire [63:0] adpt_user_str2_data;
wire [63:0] user_adpt_str2_data;
wire [63:0] adpt_user_str3_data;
wire [63:0] user_adpt_str3_data;
wire [63:0] adpt_user_str4_data;
wire [63:0] user_adpt_str4_data;

// Instantiate the module
user_logic_adapter ula (
    .i_user_clk(i_user_clk), 
	 .i_pcie_clk(i_pcie_clk),
    .i_rst(i_rst),
    .i_pcie_str1_data_valid(i_pcie_str1_data_valid), 
    .o_pcie_str1_ack(o_pcie_str1_ack), 
    .i_pcie_str1_data(i_pcie_str1_data), 
    .o_pcie_str1_data_valid(o_pcie_str1_data_valid), 
    .i_pcie_str1_ack(i_pcie_str1_ack), 
    .o_pcie_str1_data(o_pcie_str1_data), 
    .i_pcie_str2_data_valid(i_pcie_str2_data_valid), 
    .o_pcie_str2_ack(o_pcie_str2_ack), 
    .i_pcie_str2_data(i_pcie_str2_data), 
    .o_pcie_str2_data_valid(o_pcie_str2_data_valid), 
    .i_pcie_str2_ack(i_pcie_str2_ack), 
    .o_pcie_str2_data(o_pcie_str2_data), 
    .i_pcie_str3_data_valid(i_pcie_str3_data_valid), 
    .o_pcie_str3_ack(o_pcie_str3_ack), 
    .i_pcie_str3_data(i_pcie_str3_data), 
    .o_pcie_str3_data_valid(o_pcie_str3_data_valid), 
    .i_pcie_str3_ack(i_pcie_str3_ack), 
    .o_pcie_str3_data(o_pcie_str3_data), 
    .i_pcie_str4_data_valid(i_pcie_str4_data_valid), 
    .o_pcie_str4_ack(o_pcie_str4_ack), 
    .i_pcie_str4_data(i_pcie_str4_data), 
    .o_pcie_str4_data_valid(o_pcie_str4_data_valid), 
    .i_pcie_str4_ack(i_pcie_str4_ack), 
    .o_pcie_str4_data(o_pcie_str4_data), 
    //to user logic
    .i_pcie_adpt_str1_data_valid(user_adpt_str1_data_valid), 
    .o_pcie_adpt_str1_ack(user_adpt_str1_ack), 
    .i_pcie_adpt_str1_data(user_adpt_str1_data), 
    .o_pcie_adpt_str1_data_valid(adpt_user_str1_data_valid), 
    .i_pcie_adpt_str1_ack(adpt_user_adpt_str1_ack), 
    .o_pcie_adpt_str1_data(adpt_user_str1_data), 
    .i_pcie_adpt_str2_data_valid(user_adpt_str2_data_valid), 
    .o_pcie_adpt_str2_ack(user_adpt_str2_ack), 
    .i_pcie_adpt_str2_data(user_adpt_str2_data), 
    .o_pcie_adpt_str2_data_valid(adpt_user_str2_data_valid), 
    .i_pcie_adpt_str2_ack(adpt_user_adpt_str2_ack), 
    .o_pcie_adpt_str2_data(adpt_user_str2_data),
    .i_pcie_adpt_str3_data_valid(user_adpt_str3_data_valid), 
    .o_pcie_adpt_str3_ack(user_adpt_str3_ack), 
    .i_pcie_adpt_str3_data(user_adpt_str3_data), 
    .o_pcie_adpt_str3_data_valid(adpt_user_str3_data_valid), 
    .i_pcie_adpt_str3_ack(adpt_user_adpt_str3_ack), 
    .o_pcie_adpt_str3_data(adpt_user_str3_data),
    .i_pcie_adpt_str4_data_valid(user_adpt_str4_data_valid), 
    .o_pcie_adpt_str4_ack(user_adpt_str4_ack), 
    .i_pcie_adpt_str4_data(user_adpt_str4_data), 
    .o_pcie_adpt_str4_data_valid(adpt_user_str4_data_valid), 
    .i_pcie_adpt_str4_ack(adpt_user_adpt_str4_ack), 
    .o_pcie_adpt_str4_data(adpt_user_str4_data)
    );

// Instantiate the module
user_logic ul (
    .i_user_clk(i_user_clk), 
    .i_rst(i_rst), 
    .i_user_data(i_user_data), 
    .i_user_addr(i_user_addr), 
    .i_user_wr_req(i_user_wr_req), 
    .o_user_data(o_user_data), 
    .o_user_rd_ack(o_user_rd_ack), 
    .i_user_rd_req(i_user_rd_req), 
    .i_pcie_str1_data_valid(adpt_user_str1_data_valid), 
    .o_pcie_str1_ack(adpt_user_adpt_str1_ack), 
    .i_pcie_str1_data(adpt_user_str1_data), 
    .o_pcie_str1_data_valid(user_adpt_str1_data_valid), 
    .i_pcie_str1_ack(user_adpt_str1_ack), 
    .o_pcie_str1_data(user_adpt_str1_data), 
    .i_pcie_str2_data_valid(adpt_user_str2_data_valid), 
    .o_pcie_str2_ack(adpt_user_adpt_str2_ack), 
    .i_pcie_str2_data(adpt_user_str2_data), 
    .o_pcie_str2_data_valid(user_adpt_str2_data_valid), 
    .i_pcie_str2_ack(user_adpt_str2_ack), 
    .o_pcie_str2_data(user_adpt_str2_data), 
    .i_pcie_str3_data_valid(adpt_user_str3_data_valid), 
    .o_pcie_str3_ack(adpt_user_adpt_str3_ack), 
    .i_pcie_str3_data(adpt_user_str3_data), 
    .o_pcie_str3_data_valid(user_adpt_str3_data_valid), 
    .i_pcie_str3_ack(user_adpt_str3_ack), 
    .o_pcie_str3_data(user_adpt_str3_data), 
    .i_pcie_str4_data_valid(adpt_user_str4_data_valid), 
    .o_pcie_str4_ack(adpt_user_adpt_str4_ack), 
    .i_pcie_str4_data(adpt_user_str4_data), 
    .o_pcie_str4_data_valid(user_adpt_str4_data_valid), 
    .i_pcie_str4_ack(user_adpt_str4_ack), 
    .o_pcie_str4_data(user_adpt_str4_data),     
    .o_intr_req(o_intr_req), 
    .i_intr_ack(i_intr_ack)
    );

endmodule