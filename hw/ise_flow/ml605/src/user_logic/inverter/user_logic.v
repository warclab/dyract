//--------------------------------------------------------------------------------
// Project    : SWITCH
// File       : user_logic.v
// Version    : 0.1
// Author     : Vipin.K
//
// Description: A dummy user logic for testing purpose
//--------------------------------------------------------------------------------

module user_logic(
    input              i_user_clk,
    input              i_rst,
    //reg i/f 
    input    [31:0]    i_user_data,
    input    [19:0]    i_user_addr,
    input              i_user_wr_req,
    output   [31:0]    o_user_data,
    output  reg        o_user_rd_ack,
    input              i_user_rd_req, 
    //stream i/f 1
    input              i_pcie_str1_data_valid,
    output             o_pcie_str1_ack,
    input    [63:0]    i_pcie_str1_data,
    output   reg       o_pcie_str1_data_valid,
    input              i_pcie_str1_ack,
    output   reg [63:0]o_pcie_str1_data,
    //stream i/f 2       
    input              i_pcie_str2_data_valid,
    output             o_pcie_str2_ack,
    input    [63:0]    i_pcie_str2_data,
    output   reg       o_pcie_str2_data_valid,
    input              i_pcie_str2_ack,
    output   reg [63:0]o_pcie_str2_data,
    //stream i/f 3
    input              i_pcie_str3_data_valid,
    output             o_pcie_str3_ack,
    input    [63:0]    i_pcie_str3_data,
    output   reg       o_pcie_str3_data_valid,
    input              i_pcie_str3_ack,
    output   reg [63:0]o_pcie_str3_data,
    //stream i/f 4
    input              i_pcie_str4_data_valid,
    output             o_pcie_str4_ack,
    input    [63:0]    i_pcie_str4_data,
    output   reg       o_pcie_str4_data_valid,
    input              i_pcie_str4_ack,
    output   reg [63:0]o_pcie_str4_data,
    //interrupt if
    output             o_intr_req,
    input              i_intr_ack
);

reg [31:0] user_control;
assign o_intr_req             = 1'b0;
assign o_pcie_str1_ack        = 1'b1;
assign o_pcie_str2_ack        = 1'b1;
assign o_pcie_str3_ack        = 1'b1;
assign o_pcie_str4_ack        = 1'b1;

always @(posedge i_user_clk)
begin
   o_pcie_str1_data_valid  <= i_pcie_str1_data_valid;
   o_pcie_str2_data_valid  <= i_pcie_str2_data_valid;
   o_pcie_str3_data_valid  <= i_pcie_str3_data_valid;
   o_pcie_str4_data_valid  <= i_pcie_str4_data_valid;
   o_pcie_str1_data[7:0]   <= 255-i_pcie_str1_data[7:0];
   o_pcie_str1_data[15:8]  <= 255-i_pcie_str1_data[15:8];
   o_pcie_str1_data[23:16] <= 255-i_pcie_str1_data[23:16];
   o_pcie_str1_data[31:24] <= 255-i_pcie_str1_data[31:24];
   o_pcie_str1_data[39:32] <= 255-i_pcie_str1_data[39:32];
   o_pcie_str1_data[47:40] <= 255-i_pcie_str1_data[47:40];
   o_pcie_str1_data[55:48] <= 255-i_pcie_str1_data[55:48];
   o_pcie_str1_data[63:56] <= 255-i_pcie_str1_data[63:56];
   o_pcie_str2_data[7:0]   <= 255-i_pcie_str2_data[7:0];
   o_pcie_str2_data[15:8]  <= 255-i_pcie_str2_data[15:8];
   o_pcie_str2_data[23:16] <= 255-i_pcie_str2_data[23:16];
   o_pcie_str2_data[31:24] <= 255-i_pcie_str2_data[31:24];
   o_pcie_str2_data[39:32] <= 255-i_pcie_str2_data[39:32];
   o_pcie_str2_data[47:40] <= 255-i_pcie_str2_data[47:40];
   o_pcie_str2_data[55:48] <= 255-i_pcie_str2_data[55:48];
   o_pcie_str2_data[63:56] <= 255-i_pcie_str2_data[63:56];
   o_pcie_str3_data[7:0]   <= 255-i_pcie_str3_data[7:0];
   o_pcie_str3_data[15:8]  <= 255-i_pcie_str3_data[15:8];
   o_pcie_str3_data[23:16] <= 255-i_pcie_str3_data[23:16];
   o_pcie_str3_data[31:24] <= 255-i_pcie_str3_data[31:24];
   o_pcie_str3_data[39:32] <= 255-i_pcie_str3_data[39:32];
   o_pcie_str3_data[47:40] <= 255-i_pcie_str3_data[47:40];
   o_pcie_str3_data[55:48] <= 255-i_pcie_str3_data[55:48];
   o_pcie_str3_data[63:56] <= 255-i_pcie_str3_data[63:56];
   o_pcie_str4_data[7:0]   <= 255-i_pcie_str4_data[7:0];
   o_pcie_str4_data[15:8]  <= 255-i_pcie_str4_data[15:8];
   o_pcie_str4_data[23:16] <= 255-i_pcie_str4_data[23:16];
   o_pcie_str4_data[31:24] <= 255-i_pcie_str4_data[31:24];
   o_pcie_str4_data[39:32] <= 255-i_pcie_str4_data[39:32];
   o_pcie_str4_data[47:40] <= 255-i_pcie_str4_data[47:40];
   o_pcie_str4_data[55:48] <= 255-i_pcie_str4_data[55:48];
   o_pcie_str4_data[63:56] <= 255-i_pcie_str4_data[63:56];
end

//User register read
always @(posedge i_user_clk)
begin
   o_user_rd_ack  <= i_user_rd_req;
end
   
assign o_user_data = 'h12345678;
     
endmodule