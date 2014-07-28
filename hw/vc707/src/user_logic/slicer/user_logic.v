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


reg [7:0]  lower;
reg [7:0]  upper;
reg        user_wr_req_p;
reg [7:0]  user_data_p;
reg [7:0]  user_addr_p;



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
		if((i_pcie_str1_data[7:0] > lower) & (i_pcie_str1_data[7:0] < upper))
			o_pcie_str1_data[7:0]   <= i_pcie_str1_data[7:0];
		else
			o_pcie_str1_data[7:0]   <= 8'h00;
		if((i_pcie_str1_data[15:8] > lower) & (i_pcie_str1_data[15:8] < upper))
			o_pcie_str1_data[15:8]   <= i_pcie_str1_data[15:8];
		else
			o_pcie_str1_data[15:8]   <= 8'h00;
		if((i_pcie_str1_data[23:16] > lower) & (i_pcie_str1_data[23:16] < upper))
			o_pcie_str1_data[23:16]   <= i_pcie_str1_data[23:16];
		else
			o_pcie_str1_data[23:16]   <= 8'h00;
		if((i_pcie_str1_data[31:24] > lower) & (i_pcie_str1_data[31:24] < upper))
			o_pcie_str1_data[31:24]   <= i_pcie_str1_data[31:24];
		else
			o_pcie_str1_data[31:24]   <= 8'h00;
		if((i_pcie_str1_data[39:32] > lower) & (i_pcie_str1_data[39:32] < upper))
			o_pcie_str1_data[39:32]   <= i_pcie_str1_data[39:32];
		else
			o_pcie_str1_data[39:32]   <= 8'h00;
		if((i_pcie_str1_data[47:40] > lower) & (i_pcie_str1_data[47:40] < upper))
			o_pcie_str1_data[47:40]   <= i_pcie_str1_data[47:40];
		else
			o_pcie_str1_data[47:40]   <= 8'h00;
		if((i_pcie_str1_data[55:48] > lower) & (i_pcie_str1_data[55:48] < upper))
			o_pcie_str1_data[55:48]   <= i_pcie_str1_data[55:48];
		else
			o_pcie_str1_data[55:48]   <= 8'h00;
		if((i_pcie_str1_data[63:56] > lower) & (i_pcie_str1_data[63:56] < upper))
			o_pcie_str1_data[63:56]   <= i_pcie_str1_data[63:56];
		else
			o_pcie_str1_data[63:56]   <= 8'h00;		 	
		o_pcie_str2_data[7:0]   <= 0;
		o_pcie_str3_data[7:0]   <= 0;   
		o_pcie_str4_data[7:0]   <= 0; 
end	

//User register read
always @(posedge i_user_clk)
begin
   o_user_rd_ack  <= i_user_rd_req;
end


always @(posedge i_user_clk)
begin
   if(~i_rst)
	begin
	   lower <= 'd64;
	   upper <= 'd192;
	end
	else
	begin
		if(user_wr_req_p)
		begin
			if(user_addr_p == 'h00)
				lower   <=  user_data_p[7:0];
			else
				upper   <=  user_data_p[7:0];	 
		end		  
	end
end	

always @(posedge i_user_clk)
begin
    user_wr_req_p    <=  i_user_wr_req;
	 user_data_p      <=  i_user_data[7:0];
	 user_addr_p      <=  i_user_addr[7:0];
end
   
assign o_user_data = 'h12345678;
     
endmodule