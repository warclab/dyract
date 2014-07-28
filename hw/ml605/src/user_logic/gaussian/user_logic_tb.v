`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   15:40:07 01/15/2014
// Design Name:   user_logic_top
// Module Name:   F:/RESEARCH/2.my_git/pr_fpgadriver/golden/src/user_logic/laplace/user_logic_tb.v
// Project Name:  laplace
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: user_logic_top
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module user_logic_tb;

	// Inputs
	reg i_user_clk;
	reg i_rst;
	reg [31:0] i_user_data;
	reg [19:0] i_user_addr;
	reg i_user_wr_req;
	reg i_user_rd_req;
	reg i_pcie_str1_data_valid;
	reg [63:0] i_pcie_str1_data;
	reg i_pcie_str1_ack;
	reg i_pcie_str2_data_valid;
	reg [63:0] i_pcie_str2_data;
	reg i_pcie_str2_ack;
	reg i_pcie_str3_data_valid;
	reg [63:0] i_pcie_str3_data;
	reg i_pcie_str3_ack;
	reg i_pcie_str4_data_valid;
	reg [63:0] i_pcie_str4_data;
	reg i_pcie_str4_ack;
	reg i_intr_ack;

	// Outputs
	wire [31:0] o_user_data;
	wire o_user_rd_ack;
	wire o_pcie_str1_ack;
	wire o_pcie_str1_data_valid;
	wire [63:0] o_pcie_str1_data;
	wire o_pcie_str2_ack;
	wire o_pcie_str2_data_valid;
	wire [63:0] o_pcie_str2_data;
	wire o_pcie_str3_ack;
	wire o_pcie_str3_data_valid;
	wire [63:0] o_pcie_str3_data;
	wire o_pcie_str4_ack;
	wire o_pcie_str4_data_valid;
	wire [63:0] o_pcie_str4_data;
	wire o_intr_req;
   integer fptr1;
   integer fptr2;
   integer fptr3;
   integer dummy;
	reg [63:0] data;
	// Instantiate the Unit Under Test (UUT)
	user_logic_top uut (
		.i_user_clk(i_user_clk), 
		.i_rst(i_rst), 
		.i_user_data(i_user_data), 
		.i_user_addr(i_user_addr), 
		.i_user_wr_req(i_user_wr_req), 
		.o_user_data(o_user_data), 
		.o_user_rd_ack(o_user_rd_ack), 
		.i_user_rd_req(i_user_rd_req), 
		.i_pcie_str1_data_valid(i_pcie_str1_data_valid), 
		.o_pcie_str1_ack(o_pcie_str1_ack), 
		.i_pcie_str1_data(i_pcie_str1_data), 
		.o_pcie_str1_data_valid(o_pcie_str1_data_valid), 
		.i_pcie_str1_ack(1'b1), 
		.o_pcie_str1_data(o_pcie_str1_data), 
		.i_pcie_str2_data_valid(i_pcie_str2_data_valid), 
		.o_pcie_str2_ack(o_pcie_str2_ack), 
		.i_pcie_str2_data(i_pcie_str2_data), 
		.o_pcie_str2_data_valid(o_pcie_str2_data_valid), 
		.i_pcie_str2_ack(1'b1), 
		.o_pcie_str2_data(o_pcie_str2_data), 
		.i_pcie_str3_data_valid(i_pcie_str3_data_valid), 
		.o_pcie_str3_ack(o_pcie_str3_ack), 
		.i_pcie_str3_data(i_pcie_str3_data), 
		.o_pcie_str3_data_valid(o_pcie_str3_data_valid), 
		.i_pcie_str3_ack(1'b1), 
		.o_pcie_str3_data(o_pcie_str3_data), 
		.i_pcie_str4_data_valid(1'b0), 
		.o_pcie_str4_ack(), 
		.i_pcie_str4_data(0), 
		.o_pcie_str4_data_valid(), 
		.i_pcie_str4_ack(1'b0), 
		.o_pcie_str4_data(), 
		.o_intr_req(), 
		.i_intr_ack(1'b0)
	);

	always #5 i_user_clk = ~i_user_clk;


	initial 
	begin
		// Initialize Inputs
		i_user_clk = 0;
		i_rst = 1'b0;
		i_user_data = 0;
		i_user_addr = 0;
		i_user_wr_req = 0;
		i_user_rd_req = 0;
		i_pcie_str1_data_valid = 0;
		i_pcie_str1_data = 0;
		i_pcie_str1_ack = 0;
		i_pcie_str2_data_valid = 0;
		i_pcie_str2_data = 0;
		i_pcie_str2_ack = 0;
		i_pcie_str3_data_valid = 0;
		i_pcie_str3_data = 0;
		i_pcie_str3_ack = 0;
		i_pcie_str4_data_valid = 0;
		i_pcie_str4_data = 0;
		i_pcie_str4_ack = 0;
		i_intr_ack = 0;
      fptr1 = $fopen("line1.dat","r");
      fptr2 = $fopen("line2.dat","r");
      fptr3 = $fopen("line3.dat","r");
		// Wait 100 ns for global reset to finish
		#100;
      i_rst = 1'b1;  
		#100;
		@(posedge i_user_clk);
		repeat(64)
      begin
         dummy = $fscanf(fptr1,"%h",i_pcie_str1_data);
			i_pcie_str1_data_valid = 1'b1;
			@(posedge i_user_clk);
      end
		i_pcie_str1_data_valid = 1'b0;
		@(posedge i_user_clk);
		repeat(64)
      begin
         dummy = $fscanf(fptr2,"%h",i_pcie_str2_data);
			i_pcie_str2_data_valid = 1'b1;
			@(posedge i_user_clk);
      end
		i_pcie_str2_data_valid = 1'b0;
		@(posedge i_user_clk);
		repeat(64)
      begin
         dummy = $fscanf(fptr3,"%h",i_pcie_str3_data);
			i_pcie_str3_data_valid = 1'b1;
			@(posedge i_user_clk);
      end
		i_pcie_str3_data_valid = 1'b0;
		#100;
		@(posedge i_user_clk);
		i_user_wr_req  <=   1'b1;
		i_user_data <= 32'h1;
      @(posedge i_user_clk);
		i_user_wr_req  <=   1'b0;
		#1000;
		$stop;
  end


endmodule

