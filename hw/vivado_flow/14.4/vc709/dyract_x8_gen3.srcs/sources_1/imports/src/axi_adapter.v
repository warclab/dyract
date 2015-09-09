module axi_adapter(
    input                 i_pcie_clk,
    input                 i_rst_n,
    //stream i/f 1
    input                 i_pcie_str_data_valid,
    output                o_pcie_str_ack,
    input  [255:0]        i_pcie_str_data,
    output                o_pcie_str_data_valid,
    input                 i_pcie_str_ack,
    output [255:0]        o_pcie_str_data,
    input  [31:0]         sys_user_dma_addr_i,
    input  [31:0]         user_sys_dma_addr_i,
    input  [31:0]         sys_user_dma_len_i, 
    input  [31:0]         user_sys_dma_len_i, 
    input                 user_sys_dma_en_i,
    input                 sys_user_dma_en_i,
    //AXI4 write interface
    input                 m_axi_aclk,
    input                 m_axi_aresetn,
    output  [31 : 0]      m_axi_awaddr,
    output  [7 : 0]       m_axi_awlen,
    output  [2 : 0]       m_axi_awsize,
    output  [1 : 0]       m_axi_awburst,
    output  [0 : 0]       m_axi_awlock,
    output  [3 : 0]       m_axi_awcache,
    output  [2 : 0]       m_axi_awprot,
    output  [3 : 0]       m_axi_awregion,
    output  [3 : 0]       m_axi_awqos,
    output                m_axi_awvalid,
    input                 m_axi_awready,
    output  [511 : 0]     m_axi_wdata,
    output  [63 : 0]      m_axi_wstrb,
    output                m_axi_wlast,
    output                m_axi_wvalid,
    input                 m_axi_wready,
    input  [1 : 0]        m_axi_bresp,
    input                 m_axi_bvalid,
    output                m_axi_bready,
    output  [31 : 0]      m_axi_araddr,
    output  [7 : 0]       m_axi_arlen,
    output  [2 : 0]       m_axi_arsize,
    output  [1 : 0]       m_axi_arburst,
    output  [0 : 0]       m_axi_arlock,
    output  [3 : 0]       m_axi_arcache,
    output  [2 : 0]       m_axi_arprot,
    output  [3 : 0]       m_axi_arregion,
    output  [3 : 0]       m_axi_arqos,
    output                m_axi_arvalid,
    input                 m_axi_arready,
    input  [511 : 0]      m_axi_rdata,
    input  [1 : 0]        m_axi_rresp,
    input                 m_axi_rlast,
    input                 m_axi_rvalid,
    output                m_axi_rready,
    //AXI-Lite master interface
    input                 m_lite_axi_aclk,
    input                 m_lite_axi_aresetn,
    output [31 : 0]       m_lite_axi_awaddr,
    output [2 : 0]        m_lite_axi_awprot,
    output                m_lite_axi_awvalid,
    input                 m_lite_axi_awready,
    output [31 : 0]       m_lite_axi_wdata,
    output [3 : 0]        m_lite_axi_wstrb,
    output                m_lite_axi_wvalid,
    input                 m_lite_axi_wready,
    input  [1 : 0]        m_lite_axi_bresp,
    input                 m_lite_axi_bvalid,
    output                m_lite_axi_bready,
    output [31 : 0]       m_lite_axi_araddr,
    output [2 : 0]        m_lite_axi_arprot,
    output                m_lite_axi_arvalid,
    input                 m_lite_axi_arready,
    input  [31 : 0]       m_lite_axi_rdata,
    input  [1 : 0]        m_lite_axi_rresp,
    input                 m_lite_axi_rvalid,
    output                m_lite_axi_rready,
    //
    input                 init_wr,
    output                wr_ack,
    input  [31:0]         wr_addr,
    input  [31:0]         wr_data,
    input                 init_rd,
    input  [31:0]         rd_addr,
    output [31:0]         rd_data,
    output                rd_data_valid
    
);


reg [31:0]       sys_user_dma_len;
reg [31:0]       sys_user_dma_addr;
reg [31:0]       user_sys_dma_len;
reg [31:0]       user_sys_dma_addr;
reg [71:0]       s_axis_s2mm_cmd_tdata;
reg [71:0]       s_axis_mm2s_cmd_tdata;
reg              s_axis_s2mm_cmd_tvalid;
wire             s_axis_s2mm_cmd_tready;
reg              s_axis_mm2s_cmd_tvalid;


wire [3 : 0]     m_axi_s2mm_awid_dm;
wire [31 : 0]    m_axi_s2mm_awaddr_dm;
wire [7 : 0]     m_axi_s2mm_awlen_dm;
wire [2 : 0]     m_axi_s2mm_awsize_dm;
wire [1 : 0]     m_axi_s2mm_awburst_dm;
wire [2 : 0]     m_axi_s2mm_awprot_dm;
wire  [3 : 0]    m_axi_s2mm_awcache_dm;
wire [3 : 0]     m_axi_s2mm_awuser_dm;
wire             m_axi_s2mm_awvalid_dm;
wire             m_axi_s2mm_awready_dm;
wire [255 : 0]   m_axi_s2mm_wdata_dm;
wire [31 : 0]    m_axi_s2mm_wstrb_dm;
wire             m_axi_s2mm_wlast_dm;
wire             m_axi_s2mm_wvalid_dm;
wire             m_axi_s2mm_wready_dm;
wire [1 : 0]     m_axi_s2mm_bresp_dm;
wire             m_axi_s2mm_bvalid_dm;
wire             m_axi_s2mm_bready_dm;
wire             m_axi_s2mm_aclk_dm;
wire [3 : 0]     m_axi_mm2s_arid_dm;
wire [31 : 0]    m_axi_mm2s_araddr_dm;
wire [7 : 0]     m_axi_mm2s_arlen_dm;
wire [2 : 0]     m_axi_mm2s_arsize_dm;
wire [1 : 0]     m_axi_mm2s_arburst_dm;
wire [2 : 0]     m_axi_mm2s_arprot_dm;
wire [3 : 0]     m_axi_mm2s_arcache_dm;
wire [3 : 0]     m_axi_mm2s_aruser_dm;
wire             m_axi_mm2s_arvalid_dm;
wire             m_axi_mm2s_arready_dm;
wire [255 : 0]   m_axi_mm2s_rdata_dm;
wire [1 : 0]     m_axi_mm2s_rresp_dm;
wire             m_axi_mm2s_rlast_dm;
wire             m_axi_mm2s_rvalid_dm;
wire             m_axi_mm2s_rready_dm;

reg [1:0]  wr_state;
reg [1:0]  rd_state;

localparam WR_IDLE        = 'd0,
           WR_WAIT        = 'd1,
		   WR_NEXT        = 'd2,
		   WR_WAIT_FINISH = 'd3;
			  
localparam RD_IDLE        = 'd0,
           RD_WAIT        = 'd1,
           RD_NEXT        = 'd2,
	   RD_WAIT_FINISH = 'd3;

initial
begin
    wr_state  <=   WR_IDLE;
	rd_state  <=   RD_IDLE;
end

//Write state machine
always @(posedge i_pcie_clk)
begin
   case(wr_state)
	    WR_IDLE:begin
		     s_axis_s2mm_cmd_tvalid <=  1'b0;
		     if(sys_user_dma_en_i)
			 begin
			      sys_user_dma_addr <= sys_user_dma_addr_i;
				  sys_user_dma_len  <= sys_user_dma_len_i;
				  s_axis_s2mm_cmd_tvalid <= 1'b1;
                  wr_state               <= WR_WAIT;	
			      if(sys_user_dma_len_i > 'd32768) //Maximum length supported by data mover
				  begin
					    s_axis_s2mm_cmd_tdata <= {
						                          4'h0,          //reserved
						                          4'h0,          //command tag
						                          sys_user_dma_addr_i, //Start address
						                          1'b0,          //DRE request
						                          1'b0,          //EOF
						                          6'd0,          //DRE
						                          1'b1,          //INCR
						                          23'd32768    //BTT
						                          };				 
				   end
				   else
				   begin
					    s_axis_s2mm_cmd_tdata <= {
						                          4'h0,          //reserved
						                          4'h0,          //command tag
						                          sys_user_dma_addr_i, //Start address
						                          1'b0,          //DRE request
						                          1'b0,          //EOF
						                          6'd0,          //DRE
						                          1'b1,          //INCR
						                          sys_user_dma_len_i[22:0]  //BTT
						                          };
				   end
			  end
		 end
		 WR_WAIT:begin
		      if(s_axis_s2mm_cmd_tready)
			  begin
			        s_axis_s2mm_cmd_tvalid <= 1'b0;
					sys_user_dma_addr <= sys_user_dma_addr + 23'd32768;
					sys_user_dma_len  <= sys_user_dma_len - 23'd32768;
					if(sys_user_dma_len > 23'd32768)
					begin
					   wr_state     <=   WR_NEXT;
					end
					else
					    wr_state    <=   WR_WAIT_FINISH;
			  end
		 end
		 WR_NEXT:begin
		        wr_state               <= WR_WAIT;
		        if(sys_user_dma_len > 'd32768) //Maximum length supported by data mover
			    begin
				    s_axis_s2mm_cmd_tdata <= {
					                          4'h0,          //reserved
					                          4'h0,          //command tag
					                          sys_user_dma_addr, //Start address
					                          1'b0,          //DRE request
					                          1'b0,          //EOF
					                          6'd0,          //DRE
					                          1'b1,          //INCR
					                          23'd32768      //BTT
					                          };
					s_axis_s2mm_cmd_tvalid <= 1'b1;						 
				end
				else
				begin
				    s_axis_s2mm_cmd_tdata <= {
					                          4'h0,          //reserved
					                          4'h0,          //command tag
					                          sys_user_dma_addr, //Start address
					                          1'b0,          //DRE request
					                          1'b0,          //EOF
					                          6'd0,          //DRE
					                          1'b1,          //INCR
					                          sys_user_dma_len[22:0]  //BTT
					                          };
					s_axis_s2mm_cmd_tvalid <= 1'b1;					
				end
		 end
		 WR_WAIT_FINISH:begin
		     if(!sys_user_dma_en_i)
			  begin
			      wr_state <= WR_IDLE;
			  end
		 end
	endcase
end



//Write state machine
always @(posedge i_pcie_clk)
begin
   case(rd_state)
	    RD_IDLE:begin
		     s_axis_mm2s_cmd_tvalid <=  1'b0;
		     if(user_sys_dma_en_i)
			  begin
			      user_sys_dma_addr <= user_sys_dma_addr_i;
				  user_sys_dma_len  <= user_sys_dma_len_i;
				  s_axis_mm2s_cmd_tvalid <= 1'b1;
                  rd_state               <= RD_WAIT;	
			      if(user_sys_dma_len_i > 'd32768) //Maximum length supported by data mover
				  begin
					    s_axis_mm2s_cmd_tdata <= {
						                          4'h0,          //reserved
						                          4'h0,          //command tag
						                          user_sys_dma_addr_i, //Start address
						                          1'b0,          //DRE request
						                          1'b0,          //EOF
						                          6'd0,          //DRE
						                          1'b1,          //INCR
						                          23'd32768      //BTT
						                          };				 
				  end
				  else
				  begin
					    s_axis_mm2s_cmd_tdata <= {
						                          4'h0,          //reserved
						                          4'h0,          //command tag
						                          user_sys_dma_addr_i, //Start address
						                          1'b0,          //DRE request
						                          1'b1,          //EOF
						                          6'd0,          //DRE
						                          1'b1,          //INCR
						                          user_sys_dma_len_i[22:0]  //BTT
						                          };
				  end
			  end
		 end
		 RD_WAIT:begin
		      if(s_axis_mm2s_cmd_tready_dm)
			  begin
			        s_axis_mm2s_cmd_tvalid <= 1'b0;
					user_sys_dma_addr <= user_sys_dma_addr + 23'd32768;
					user_sys_dma_len  <= user_sys_dma_len - 23'd32768;
					if(user_sys_dma_len > 23'd32768)
					begin
					    rd_state     <=   RD_NEXT;
					end
					else
					    rd_state     <=   RD_WAIT_FINISH;
			  end
		 end
		 RD_NEXT:begin
		      rd_state               <= RD_WAIT;
			  s_axis_mm2s_cmd_tvalid <= 1'b1;	
		      if(user_sys_dma_len > 'd32768) //Maximum length supported by data mover
			  begin
			  	    s_axis_mm2s_cmd_tdata <= {
					                          4'h0,          //reserved
					                          4'h0,          //command tag
					                          user_sys_dma_addr, //Start address
					                          1'b0,          //DRE request
					                          1'b0,          //EOF
					                          6'd0,          //DRE
					                          1'b1,          //INCR
					                          23'd32768    //BTT
					                          };
			  end
			  else
			  begin
				    s_axis_mm2s_cmd_tdata <= {
					                          4'h0,          //reserved
					                          4'h0,          //command tag
					                          user_sys_dma_addr, //Start address
					                          1'b0,          //DRE request
					                          1'b1,          //EOF
					                          6'd0,          //DRE
					                          1'b1,          //INCR
					                          user_sys_dma_len[22:0]  //BTT
					                          };				
			  end
		 end
		 RD_WAIT_FINISH:begin
		     if(!user_sys_dma_en_i)
			  begin
			      rd_state <= RD_IDLE;
			  end
		 end
	endcase
end



axi_lite_bridge_v1_0 #
	(
		// Parameters of Axi Master Bus Interface M_LITE_AXI
		.C_M_LITE_AXI_ADDR_WIDTH(32),
		.C_M_LITE_AXI_DATA_WIDTH(32)
	)
	axi_lite_bridge
	(
	    .pcie_clk(i_pcie_clk),
		.init_wr(init_wr),
		.wr_ack(wr_ack),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .init_rd(init_rd),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .rd_data_valid(rd_data_valid),
		// Ports of Axi Master Bus Interface M_LITE_AXI
		.m_lite_axi_aclk(m_lite_axi_aclk),
		.m_lite_axi_aresetn(m_lite_axi_aresetn),
		.m_lite_axi_awaddr(m_lite_axi_awaddr),
		.m_lite_axi_awprot(m_lite_axi_awprot),
		.m_lite_axi_awvalid(m_lite_axi_awvalid),
		.m_lite_axi_awready(m_lite_axi_awready),
		.m_lite_axi_wdata(m_lite_axi_wdata),
		.m_lite_axi_wstrb(m_lite_axi_wstrb),
		.m_lite_axi_wvalid(m_lite_axi_wvalid),
		.m_lite_axi_wready(m_lite_axi_wready),
		.m_lite_axi_bresp(m_lite_axi_bresp),
		.m_lite_axi_bvalid(m_lite_axi_bvalid),
		.m_lite_axi_bready(m_lite_axi_bready),
		.m_lite_axi_araddr(m_lite_axi_araddr),
		.m_lite_axi_arprot(m_lite_axi_arprot),
		.m_lite_axi_arvalid(m_lite_axi_arvalid),
		.m_lite_axi_arready(m_lite_axi_arready),
		.m_lite_axi_rdata(m_lite_axi_rdata),
		.m_lite_axi_rresp(m_lite_axi_rresp),
		.m_lite_axi_rvalid(m_lite_axi_rvalid),
		.m_lite_axi_rready(m_lite_axi_rready)
);




axi_datamover_0 dm (
  .m_axi_mm2s_aclk(i_pcie_clk), 
  .m_axi_mm2s_aresetn(i_rst_n), // input m_axi_mm2s_aresetn
  .mm2s_err(), // output mm2s_err
  .m_axis_mm2s_cmdsts_aclk(i_pcie_clk), 
  .m_axis_mm2s_cmdsts_aresetn(i_rst_n), 
  .s_axis_mm2s_cmd_tvalid(s_axis_mm2s_cmd_tvalid), 
  .s_axis_mm2s_cmd_tready(s_axis_mm2s_cmd_tready_dm), 
  .s_axis_mm2s_cmd_tdata(s_axis_mm2s_cmd_tdata), 
  .m_axis_mm2s_sts_tvalid(), // output m_axis_mm2s_sts_tvalid
  .m_axis_mm2s_sts_tready(1'b1), // input m_axis_mm2s_sts_tready
  .m_axis_mm2s_sts_tdata(), // output [7 : 0] m_axis_mm2s_sts_tdata
  .m_axis_mm2s_sts_tkeep(), // output [0 : 0] m_axis_mm2s_sts_tkeep
  .m_axis_mm2s_sts_tlast(), // output m_axis_mm2s_sts_tlast
  //AXI4 to stream (read)
  .m_axi_mm2s_arid(m_axi_mm2s_arid_dm), 
  .m_axi_mm2s_araddr(m_axi_mm2s_araddr_dm), 
  .m_axi_mm2s_arlen(m_axi_mm2s_arlen_dm),
  .m_axi_mm2s_arsize(m_axi_mm2s_arsize_dm), 
  .m_axi_mm2s_arburst(m_axi_mm2s_arburst_dm), 
  .m_axi_mm2s_arprot(m_axi_mm2s_arprot_dm), 
  .m_axi_mm2s_arcache(m_axi_mm2s_arcache_dm),
  .m_axi_mm2s_aruser(m_axi_mm2s_aruser_dm),
  .m_axi_mm2s_arvalid(m_axi_mm2s_arvalid_dm), 
  .m_axi_mm2s_arready(m_axi_mm2s_arready_dm),
  .m_axi_mm2s_rdata(m_axi_mm2s_rdata_dm),
  .m_axi_mm2s_rresp(m_axi_mm2s_rresp_dm), 
  .m_axi_mm2s_rlast(m_axi_mm2s_rlast_dm),
  .m_axi_mm2s_rvalid(m_axi_mm2s_rvalid_dm),
  .m_axi_mm2s_rready(m_axi_mm2s_rready_dm),
  //AXI stream out
  .m_axis_mm2s_tdata(o_pcie_str_data), 
  .m_axis_mm2s_tkeep(), 
  .m_axis_mm2s_tlast(),
  .m_axis_mm2s_tvalid(o_pcie_str_data_valid),
  .m_axis_mm2s_tready(i_pcie_str_ack), 
  //Stream to AXI4 (write)
  .m_axi_s2mm_aclk(i_pcie_clk),
  .m_axi_s2mm_aresetn(i_rst_n), 
  .s2mm_err(), // output s2mm_err
  .m_axis_s2mm_cmdsts_awclk(i_pcie_clk), 
  .m_axis_s2mm_cmdsts_aresetn(i_rst_n), 
  .s_axis_s2mm_cmd_tvalid(s_axis_s2mm_cmd_tvalid), 
  .s_axis_s2mm_cmd_tready(s_axis_s2mm_cmd_tready), 
  .s_axis_s2mm_cmd_tdata(s_axis_s2mm_cmd_tdata), 
  .m_axis_s2mm_sts_tvalid(), // output m_axis_s2mm_sts_tvalid
  .m_axis_s2mm_sts_tready(1'b1), // input m_axis_s2mm_sts_tready
  .m_axis_s2mm_sts_tdata(), // output [7 : 0] m_axis_s2mm_sts_tdata
  .m_axis_s2mm_sts_tkeep(), // output [0 : 0] m_axis_s2mm_sts_tkeep
  .m_axis_s2mm_sts_tlast(), // output m_axis_s2mm_sts_tlast
  //axi 4 write
  .m_axi_s2mm_awid(m_axi_s2mm_awid_dm), 
  .m_axi_s2mm_awaddr(m_axi_s2mm_awaddr_dm),
  .m_axi_s2mm_awlen(m_axi_s2mm_awlen_dm),
  .m_axi_s2mm_awsize(m_axi_s2mm_awsize_dm), 
  .m_axi_s2mm_awburst(m_axi_s2mm_awburst_dm), 
  .m_axi_s2mm_awprot(m_axi_s2mm_awprot_dm),
  .m_axi_s2mm_awcache(m_axi_s2mm_awcache_dm),
  .m_axi_s2mm_awuser(m_axi_s2mm_awuser_dm),
  .m_axi_s2mm_awvalid(m_axi_s2mm_awvalid_dm), 
  .m_axi_s2mm_awready(m_axi_s2mm_awready_dm),
  .m_axi_s2mm_wdata(m_axi_s2mm_wdata_dm),
  .m_axi_s2mm_wstrb(m_axi_s2mm_wstrb_dm), 
  .m_axi_s2mm_wlast(m_axi_s2mm_wlast_dm), 
  .m_axi_s2mm_wvalid(m_axi_s2mm_wvalid_dm), 
  .m_axi_s2mm_wready(m_axi_s2mm_wready_dm),
  .m_axi_s2mm_bresp(m_axi_s2mm_bresp_dm),
  .m_axi_s2mm_bvalid(m_axi_s2mm_bvalid_dm),
  .m_axi_s2mm_bready(m_axi_s2mm_bready_dm), 
  //axi stream input
  .s_axis_s2mm_tdata(i_pcie_str_data),
  .s_axis_s2mm_tkeep(16'hFFFF),
  .s_axis_s2mm_tlast(1'b0), // input s_axis_s2mm_tlast
  .s_axis_s2mm_tvalid(i_pcie_str_data_valid),
  .s_axis_s2mm_tready(o_pcie_str_ack)
);

axi_dwidth_converter_0 width_convert (
  .s_axi_aclk(i_pcie_clk),          
  .s_axi_aresetn(i_rst_n),          
  .s_axi_awaddr(m_axi_s2mm_awaddr_dm),      
  .s_axi_awlen(m_axi_s2mm_awlen_dm),        
  .s_axi_awsize(m_axi_s2mm_awsize_dm),      
  .s_axi_awburst(m_axi_s2mm_awburst_dm),    
  .s_axi_awlock(1'b0),      
  .s_axi_awcache(m_axi_s2mm_awcache_dm),  
  .s_axi_awprot(m_axi_s2mm_awprot_dm),     
  .s_axi_awregion(4'h0), 
  .s_axi_awqos(4'h0),       
  .s_axi_awvalid(m_axi_s2mm_awvalid_dm),    
  .s_axi_awready(m_axi_s2mm_awready_dm),   
  .s_axi_wdata(m_axi_s2mm_wdata_dm),      
  .s_axi_wstrb(m_axi_s2mm_wstrb_dm),     
  .s_axi_wlast(m_axi_s2mm_wlast_dm),     
  .s_axi_wvalid(m_axi_s2mm_wvalid_dm),   
  .s_axi_wready(m_axi_s2mm_wready_dm), 
  .s_axi_bresp(m_axi_s2mm_bresp_dm),   
  .s_axi_bvalid(m_axi_s2mm_bvalid_dm),
  .s_axi_bready(m_axi_s2mm_bready_dm),
  .s_axi_araddr(m_axi_mm2s_araddr_dm),
  .s_axi_arlen(m_axi_mm2s_arlen_dm),
  .s_axi_arsize(m_axi_mm2s_arsize_dm),
  .s_axi_arburst(m_axi_mm2s_arburst_dm),
  .s_axi_arlock(1'b0),
  .s_axi_arcache(m_axi_mm2s_arcache_dm),
  .s_axi_arprot(m_axi_mm2s_arprot_dm),
  .s_axi_arregion(4'h0),
  .s_axi_arqos(4'h0),
  .s_axi_arvalid(m_axi_mm2s_arvalid_dm),
  .s_axi_arready(m_axi_mm2s_arready_dm),
  .s_axi_rdata(m_axi_mm2s_rdata_dm),
  .s_axi_rresp(m_axi_mm2s_rresp_dm),
  .s_axi_rlast(m_axi_mm2s_rlast_dm), 
  .s_axi_rvalid(m_axi_mm2s_rvalid_dm),
  .s_axi_rready(m_axi_mm2s_rready_dm),
  .m_axi_aclk(m_axi_aclk),
  .m_axi_aresetn(m_axi_aresetn),
  .m_axi_awaddr(m_axi_awaddr),
  .m_axi_awlen(m_axi_awlen),
  .m_axi_awsize(m_axi_awsize),
  .m_axi_awburst(m_axi_awburst),
  .m_axi_awlock(m_axi_awlock), 
  .m_axi_awcache(m_axi_awcache), 
  .m_axi_awprot(m_axi_awprot), 
  .m_axi_awregion(m_axi_awregion), 
  .m_axi_awqos(m_axi_awqos),
  .m_axi_awvalid(m_axi_awvalid),
  .m_axi_awready(m_axi_awready),
  .m_axi_wdata(m_axi_wdata),
  .m_axi_wstrb(m_axi_wstrb),
  .m_axi_wlast(m_axi_wlast), 
  .m_axi_wvalid(m_axi_wvalid), 
  .m_axi_wready(m_axi_wready),  
  .m_axi_bresp(m_axi_bresp), 
  .m_axi_bvalid(m_axi_bvalid),
  .m_axi_bready(m_axi_bready), 
  .m_axi_araddr(m_axi_araddr), 
  .m_axi_arlen(m_axi_arlen), 
  .m_axi_arsize(m_axi_arsize),
  .m_axi_arburst(m_axi_arburst), 
  .m_axi_arlock(m_axi_arlock),
  .m_axi_arcache(m_axi_arcache), 
  .m_axi_arprot(m_axi_arprot),
  .m_axi_arregion(m_axi_arregion),
  .m_axi_arqos(m_axi_arqos),
  .m_axi_arvalid(m_axi_arvalid),
  .m_axi_arready(m_axi_arready),
  .m_axi_rdata(m_axi_rdata),
  .m_axi_rresp(m_axi_rresp),
  .m_axi_rlast(m_axi_rlast),
  .m_axi_rvalid(m_axi_rvalid),
  .m_axi_rready(m_axi_rready)
);

endmodule
