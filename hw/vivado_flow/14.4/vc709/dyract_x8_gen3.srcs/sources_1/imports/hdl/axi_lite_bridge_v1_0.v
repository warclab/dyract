	module axi_lite_bridge_v1_0 #
(
// Parameters of Axi Master Bus Interface M_LITE_AXI
parameter integer C_M_LITE_AXI_ADDR_WIDTH    = 32,
parameter integer C_M_LITE_AXI_DATA_WIDTH    = 32
)
(
input wire         pcie_clk,
input wire         init_wr,
output wire        wr_ack,
input wire [31:0]  wr_addr,
input wire [31:0]  wr_data,
input wire         init_rd,
input wire [31:0]  rd_addr,
output wire [31:0] rd_data,
output wire        rd_data_valid,
// Ports of Axi Master Bus Interface M_LITE_AXI
input wire  m_lite_axi_aclk,
input wire  m_lite_axi_aresetn,
output wire [C_M_LITE_AXI_ADDR_WIDTH-1 : 0] m_lite_axi_awaddr,
output wire [2 : 0] m_lite_axi_awprot,
output wire  m_lite_axi_awvalid,
input wire  m_lite_axi_awready,
output wire [C_M_LITE_AXI_DATA_WIDTH-1 : 0] m_lite_axi_wdata,
output wire [C_M_LITE_AXI_DATA_WIDTH/8-1 : 0] m_lite_axi_wstrb,
output wire  m_lite_axi_wvalid,
input wire  m_lite_axi_wready,
input wire [1 : 0] m_lite_axi_bresp,
input wire  m_lite_axi_bvalid,
output wire  m_lite_axi_bready,
output wire [C_M_LITE_AXI_ADDR_WIDTH-1 : 0] m_lite_axi_araddr,
output wire [2 : 0] m_lite_axi_arprot,
output wire  m_lite_axi_arvalid,
input wire  m_lite_axi_arready,
input wire [C_M_LITE_AXI_DATA_WIDTH-1 : 0] m_lite_axi_rdata,
input wire [1 : 0] m_lite_axi_rresp,
input wire  m_lite_axi_rvalid,
output wire  m_lite_axi_rready
);

wire [31:0] cmd_wr_addr;
wire [31:0] cmd_wr_data;
wire [31:0] cmd_rd_addr;
wire [31:0] cmd_rd_data;
reg         rd_data_ready;


command_fifo wr_cmd_fifo (
.s_axis_aresetn(m_lite_axi_aresetn), 
.m_axis_aresetn(m_lite_axi_aresetn),
.s_axis_aclk(pcie_clk),                
.s_axis_tvalid(init_wr),            
.s_axis_tready(wr_ack),           
.s_axis_tdata({wr_addr,wr_data}),              
.m_axis_aclk(m_lite_axi_aclk),                
.m_axis_tvalid(cmd_init_wr),           
.m_axis_tready(cmd_wr_done),           
.m_axis_tdata({cmd_wr_addr,cmd_wr_data}),              
.axis_data_count(),        
.axis_wr_data_count(),  
.axis_rd_data_count()  
);

rd_fifo rd_cmd_fifo (
.s_axis_aresetn(m_lite_axi_aresetn),    
.m_axis_aresetn(m_lite_axi_aresetn),    
.s_axis_aclk(pcie_clk),                
.s_axis_tvalid(init_rd),            
.s_axis_tready(),           
.s_axis_tdata(rd_addr),             
.m_axis_aclk(m_lite_axi_aclk),          
.m_axis_tvalid(cmd_init_rd),            
.m_axis_tready(cmd_rd_done),            
.m_axis_tdata(cmd_rd_addr),             
.axis_data_count(),       
.axis_wr_data_count(), 
.axis_rd_data_count() 
);

rd_fifo rd_data_fifo (
.s_axis_aresetn(m_lite_axi_aresetn),    
.m_axis_aresetn(m_lite_axi_aresetn),    
.s_axis_aclk(m_lite_axi_aclk),                
.s_axis_tvalid(cmd_rd_data_valid),            
.s_axis_tready(),           
.s_axis_tdata(cmd_rd_data),             
.m_axis_aclk(pcie_clk),          
.m_axis_tvalid(rd_data_valid),            
.m_axis_tready(rd_data_ready),            
.m_axis_tdata(rd_data),             
.axis_data_count(),       
.axis_wr_data_count(), 
.axis_rd_data_count() 
);


always @(posedge pcie_clk)
begin
rd_data_ready  <= rd_data_valid;
end


// Instantiation of Axi Bus Interface M_LITE_AXI
axi_lite_bridge_v1_0_M_LITE_AXI # ( 
.C_M_AXI_ADDR_WIDTH(C_M_LITE_AXI_ADDR_WIDTH),
.C_M_AXI_DATA_WIDTH(C_M_LITE_AXI_DATA_WIDTH)
) axi_lite_bridge_v1_0_M_LITE_AXI_inst (
.init_wr(cmd_init_wr),
.wr_addr(cmd_wr_addr),
.wr_data(cmd_wr_data),
.wr_done(cmd_wr_done),
.init_rd(cmd_init_rd),
.rd_addr(cmd_rd_addr),
.rd_data(cmd_rd_data),
.rd_done(cmd_rd_done),
.rd_data_valid(cmd_rd_data_valid),
.M_AXI_ACLK(m_lite_axi_aclk),
.M_AXI_ARESETN(m_lite_axi_aresetn),
.M_AXI_AWADDR(m_lite_axi_awaddr),
.M_AXI_AWPROT(m_lite_axi_awprot),
.M_AXI_AWVALID(m_lite_axi_awvalid),
.M_AXI_AWREADY(m_lite_axi_awready),
.M_AXI_WDATA(m_lite_axi_wdata),
.M_AXI_WSTRB(m_lite_axi_wstrb),
.M_AXI_WVALID(m_lite_axi_wvalid),
.M_AXI_WREADY(m_lite_axi_wready),
.M_AXI_BRESP(m_lite_axi_bresp),
.M_AXI_BVALID(m_lite_axi_bvalid),
.M_AXI_BREADY(m_lite_axi_bready),
.M_AXI_ARADDR(m_lite_axi_araddr),
.M_AXI_ARPROT(m_lite_axi_arprot),
.M_AXI_ARVALID(m_lite_axi_arvalid),
.M_AXI_ARREADY(m_lite_axi_arready),
.M_AXI_RDATA(m_lite_axi_rdata),
.M_AXI_RRESP(m_lite_axi_rresp),
.M_AXI_RVALID(m_lite_axi_rvalid),
.M_AXI_RREADY(m_lite_axi_rready)
);

// Add user logic here

// User logic ends

endmodule
