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
    output          o_pcie_str1_data_valid,
    input              i_pcie_str1_ack,
    output    [63:0]o_pcie_str1_data,
    //stream i/f 2       
    input              i_pcie_str2_data_valid,
    output             o_pcie_str2_ack,
    input    [63:0]    i_pcie_str2_data,
    output          o_pcie_str2_data_valid,
    input              i_pcie_str2_ack,
    output    [63:0]o_pcie_str2_data,
    //stream i/f 3
    input              i_pcie_str3_data_valid,
    output             o_pcie_str3_ack,
    input    [63:0]    i_pcie_str3_data,
    output          o_pcie_str3_data_valid,
    input              i_pcie_str3_ack,
    output    [63:0]o_pcie_str3_data,
    //stream i/f 4
    input              i_pcie_str4_data_valid,
    output             o_pcie_str4_ack,
    input    [63:0]    i_pcie_str4_data,
    output          o_pcie_str4_data_valid,
    input              i_pcie_str4_ack,
    output    [63:0]o_pcie_str4_data,
    //interrupt if
    output             o_intr_req,
    input              i_intr_ack
);

reg [31:0] user_control;


assign o_intr_req      = 1'b0;
assign o_pcie_str4_ack      = 1'b1;
assign o_pcie_str4_data_valid = 1'b0;
assign o_pcie_str3_data_valid = 1'b0;
assign o_pcie_str2_data_valid = 1'b0;
assign o_pcie_str2_data = 64'd0;
assign o_pcie_str3_data = 64'd0;
assign o_pcie_str4_data = 64'd0;


//User register read
always @(posedge i_user_clk)
begin
   o_user_rd_ack  <= i_user_rd_req;
end

always @(posedge i_user_clk)
begin
    if(i_user_wr_req)
	    user_control  <=  i_user_data;
end
   
assign o_user_data = user_control;


emboss_top gt (
    .i_clk(i_user_clk), 
	 .i_rst(i_rst),
    .i_line1_data_valid(i_pcie_str1_data_valid), 
    .i_line1_data(i_pcie_str1_data), 
    .o_line1_data_ack(o_pcie_str1_ack), 
    .i_line2_data_valid(i_pcie_str2_data_valid), 
    .i_line2_data(i_pcie_str2_data), 
    .o_line2_data_ack(o_pcie_str2_ack), 
    .i_line3_data_valid(i_pcie_str3_data_valid), 
    .i_line3_data(i_pcie_str3_data), 
    .o_line3_data_ack(o_pcie_str3_ack), 
    .o_sobel_data_valid(o_pcie_str1_data_valid), 
    .o_sobel_data(o_pcie_str1_data), 
    .i_sobel_data_ack(i_pcie_str1_ack), 
    .i_filter(user_control[0])
);

    
endmodule