module config_controller(
input    wire         i_pcie_clk,
input    wire         i_icap_clk,
input    wire         i_rst,
input    wire [63:0]  i_config_data,
input    wire         i_config_data_valid,
output   reg          config_rd_req_o,
output   reg          config_done_o,
output   reg  [31:0]  config_rd_req_addr_o,
input         [31:0]  config_len_i,
input                 config_strm_en_i,
output   reg   [11:0] config_rd_req_len_o,
input          [7:0]  dma_tag_i,
output         [7:0]  dma_tag_o,
input                 config_rd_req_ack_i,
input                 config_done_ack_i,
input          [31:0] config_src_addr_i

);

wire [31:0] config_data;
reg         icap_en;
reg         icap_wr;
wire [31:0] dout;
wire        empty;
reg         rd_en;
reg         conf_state;
parameter   idle    = 1'b0,
            rd_buff = 1'b1;

assign config_data = {dout[24],dout[25],dout[26],dout[27],dout[28],dout[29],dout[30],dout[31],dout[16],dout[17],dout[18],dout[19],dout[20],dout[21],dout[22],dout[23],dout[8],dout[9],dout[10],dout[11],dout[12],dout[13],dout[14],dout[15],dout[0],dout[1],dout[2],dout[3],dout[4],dout[5],dout[6],dout[7]};

assign dma_tag_o = 0;

localparam IDLE          = 'd0,
           WAIT_ACK      = 'd1,
           START         = 'd2,
           WAIT_DEASSRT  = 'd3;
          

reg [1:0]  state;
reg [1:0]  wr_state;
reg        last_flag;
reg [31:0] rd_len;
reg [31:0] wr_len;
reg [31:0] rcvd_data_cnt;
reg [31:0] expected_data_cnt;
wire[9:0]  rd_data_count;
reg        clr_rcv_data_cntr;
reg [31:0] dma_wr_addr;
reg [63:0] dma_data_p;


wire       config_buff_full;
reg        fifo_wr_en;
wire       fifo_ready;

always @(posedge i_pcie_clk)
begin
  if(i_config_data_valid & (dma_tag_i == 0))
    fifo_wr_en  <=  1'b1;
  else
    fifo_wr_en    <=  1'b0;
    dma_data_p    <=  i_config_data;
end

assign fifo_ready = !config_buff_full;

initial
begin
    state                 <= IDLE;
    config_rd_req_o       <= 1'b0;
    config_done_o         <= 1'b0;
    last_flag             <= 1'b0; 
end

always @(posedge i_pcie_clk)
begin
    case(state)
        IDLE:begin
            config_done_o     <= 1'b0;
            last_flag         <= 1'b0; 
            clr_rcv_data_cntr <= 1'b1;
            config_rd_req_addr_o   <= config_src_addr_i;
            rd_len              <= config_len_i;
            expected_data_cnt   <= 0;
            if(config_strm_en_i)                      //If system to user dma is enabled
            begin
                state               <= START;
            end
        end
        START:begin    
            clr_rcv_data_cntr <= 1'b0;
            if(fifo_ready)                              //If there is space in receive fifo make a request
            begin
                state            <= WAIT_ACK;
                config_rd_req_o  <= 1'b1;
                if(rd_len <= 'd4096)
                begin
                    config_rd_req_len_o       <= rd_len[11:0];
                    expected_data_cnt         <= expected_data_cnt + rd_len;  
                    last_flag                 <= 1'b1;                     
                end
                else
                begin
                    config_rd_req_len_o      <= 0;
                    expected_data_cnt        <= expected_data_cnt + 4096;
                end
            end
        end
        WAIT_ACK:begin
            if(config_rd_req_ack_i)
            begin
                config_rd_req_o <= 1'b0;
            end
            if(rcvd_data_cnt >= expected_data_cnt[31:3])
            begin
                rd_len               <= rd_len - 'd4096;
                config_rd_req_addr_o <= config_rd_req_addr_o + 'd4096;
                if(config_done_ack_i & ~config_strm_en_i)
                begin
                    state             <= IDLE; 
                end       
                else if(last_flag)
                begin 
                    config_done_o <= 1'b1;
                    state        <=  WAIT_ACK;
                end
                else
                    state      <=  START;     
            end
        end
    endcase
end

initial
begin
    rcvd_data_cnt    <=  0;
    rd_en   <= 1'b0;
	icap_en <= 1'b1;
	icap_wr <= 1'b1;
	conf_state   <= idle;
end


always @(posedge i_pcie_clk)
begin
    if(clr_rcv_data_cntr)
        rcvd_data_cnt   <=    0;
    else if(fifo_wr_en)
        rcvd_data_cnt   <=    rcvd_data_cnt + 1; 
end




always @(posedge i_icap_clk)
begin
	case(conf_state)
	    idle:begin
		    if(~empty)
			begin
			   rd_en  <= 1'b1;
				conf_state  <= rd_buff;
			end
		end
		rd_buff:begin
		    icap_en <= 1'b0;
         icap_wr <= 1'b0;	
         if(empty)	
            begin
			    rd_en   <= 1'b0;   
                icap_en <= 1'b1;                    
				icap_wr <= 1'b1;
				conf_state   <= idle;
            end				
		end
	endcase
end


config_buffer config_buffer (
  .rst(1'b0), // input rst
  .wr_clk(i_pcie_clk), // input wr_clk
  .rd_clk(i_icap_clk), // input rd_clk
  .din(dma_data_p), // input [63 : 0] din
  .wr_en(fifo_wr_en), // input wr_en
  .rd_en(rd_en), // input rd_en
  .dout(dout), // output [31 : 0] dout
  .full(), // output full
  .empty(empty), // output empty
  .prog_full(config_buff_full) // output prog_full
);

ICAP_VIRTEX6 #(
   .DEVICE_ID('h4244093),     // Specifies the pre-programmed Device ID value
   .ICAP_WIDTH("X32"),          // Specifies the input and output data width to be used with the
                               // ICAP_VIRTEX6.
   .SIM_CFG_FILE_NAME("NONE")  // Specifies the Raw Bitstream (RBT) file to be parsed by the simulation
                               // model
)
ICAP_VIRTEX6_inst (
   .BUSY(),   // 1-bit output: Busy/Ready output
   .O(),         // 32-bit output: Configuration data output bus
   .CLK(i_icap_clk), // 1-bit input: Clock Input
   .CSB(icap_en),     // 1-bit input: Active-Low ICAP input Enable
   .I(config_data),         // 32-bit input: Configuration data input bus
   .RDWRB(icap_wr)  // 1-bit input: Read/Write Select input
);

endmodule
