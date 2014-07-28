//--------------------------------------------------------------------------------
// Project    : SWITCH
// File       : user_pcie_stream_generator.v
// Version    : 0.1
// Author     : Vipin.K
//
// Description: PCIe user stream i/f controller
//
//--------------------------------------------------------------------------------


module user_pcie_stream_generator
#(
  parameter TAG1 = 8'd0,
  parameter TAG2 = 8'd1
)
(
input              clk_i,
input              rst_n,
//Register Set I/f
input              sys_user_strm_en_i,
input              user_sys_strm_en_i,
output  reg        dma_done_o,
input              dma_done_ack_i,
input       [31:0] dma_src_addr_i,
input       [31:0] dma_len_i,
input       [31:0] stream_len_i,
output reg         user_sys_strm_done_o,
input              user_sys_strm_done_ack,
input      [31:0]  dma_wr_start_addr_i,
//To pcie arbitrator
output  reg        dma_rd_req_o,
input              dma_req_ack_i,
//Rx engine
input       [7:0]  dma_tag_i,
input              dma_data_valid_i,
input       [63:0] dma_data_i,
//User stream output
output  reg        stream_data_valid_o,
input              stream_data_ready_i,
output  reg [63:0] stream_data_o,
//User stream input
input              stream_data_valid_i,
output             stream_data_ready_o,
input       [63:0] stream_data_i, 
//To Tx engine  
output  reg [11:0] dma_rd_req_len_o,
output  reg [7:0]  dma_tag_o,
output  reg [31:0] dma_rd_req_addr_o,
output  reg        user_stream_data_avail_o, 
input              user_stream_data_rd_i,
output      [63:0] user_stream_data_o,
output  reg [4:0]  user_stream_data_len_o,
output      [31:0] user_stream_wr_addr_o,
input              user_stream_wr_ack_i
);

localparam IDLE          = 'd0,
           WAIT_ACK      = 'd1,
           START         = 'd2,
           WAIT_DEASSRT  = 'd3;
           
parameter REQ_BUF1        = 'd1,
          WAIT_BUF1_ACK   = 'd2,
          REQ_BUF2        = 'd3,
          WAIT_BUF2_ACK   = 'd4,
          REQ_BUF3        = 'd5,
          WAIT_BUF3_ACK   = 'd6,
          REQ_BUF4        = 'd7,
          WAIT_BUF4_ACK   = 'd8,
          INT_RESET       = 'd9,
          CLR_CNTR        = 'd10;           
          
reg [3:0]  state;
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
wire [63:0] fifo1_rd_data;
wire [63:0] fifo2_rd_data;
reg [9:0]  fifo_1_expt_cnt;
reg [9:0]  fifo_2_expt_cnt;
reg [9:0]  fifo_1_rcv_cnt;
reg [9:0]  fifo_2_rcv_cnt;
reg [8:0]  fifo_rd_cnt;
reg        current_read_fifo;
reg        clr_fifo1_data_cntr;
reg        clr_fifo2_data_cntr;

wire       fifo_full_i;
reg        fifo1_wr_en;
reg        fifo2_wr_en;
wire       all_fifos_empty;
wire       rd_data_transfer;
reg        fifo1_rdy;
reg        fifo2_rdy;

always @(posedge clk_i)
begin
    if(dma_data_valid_i & (dma_tag_i == TAG1))
        fifo1_wr_en <= 1'b1;
    else  
        fifo1_wr_en <= 1'b0;
  
    if(dma_data_valid_i & (dma_tag_i == TAG2)) 
       fifo2_wr_en <= 1'b1;
    else
       fifo2_wr_en <= 1'b0;
      
    dma_data_p  <= dma_data_i;
end

assign all_fifos_empty        = !(fifo1_valid|fifo2_valid);
assign user_stream_wr_addr_o  = dma_wr_addr;
assign rd_data_transfer       = stream_data_valid_o & stream_data_ready_i;

always @(*)
begin
    case(current_read_fifo)
        1'b0:begin
            stream_data_o          <=    fifo1_rd_data;
            fifo1_rdy              <=    stream_data_ready_i;
            fifo2_rdy              <=    1'b0;
            stream_data_valid_o    <=    fifo1_valid;
      end
        1'b1:begin
            stream_data_o          <=    fifo2_rd_data;
            fifo1_rdy              <=    1'b0;
            fifo2_rdy              <=    stream_data_ready_i;
            stream_data_valid_o    <=    fifo2_valid;
      end
    endcase
end

initial
begin
      wr_state                   <=  IDLE;
      user_stream_data_avail_o   <=  1'b0;
      user_sys_strm_done_o       <=  1'b0;
      current_read_fifo          <=  1'b0;
      fifo_rd_cnt                <=  9'd0;
end

always@(posedge clk_i)
begin
    if(clr_rcv_data_cntr)
       current_read_fifo  <=  1'b0;
    else if((fifo_rd_cnt == 'd511) & rd_data_transfer)
       current_read_fifo  <=  current_read_fifo + 1'b1;
end

always @(posedge clk_i)
begin
    if(clr_rcv_data_cntr)
        fifo_rd_cnt   <=  9'd0;
    else if(rd_data_transfer)
        fifo_rd_cnt   <=  fifo_rd_cnt + 1'b1;    
end

//State machine for user logic to system data transfer
always @(posedge clk_i)
begin
    if(~rst_n)
	 begin
	     wr_state    <=    IDLE;
	 end
	 else
	 begin
		case(wr_state)
         IDLE:begin
             user_sys_strm_done_o    <=    1'b0;
             if(user_sys_strm_en_i)                       //If the controller is enabled
             begin
                 dma_wr_addr    <=  dma_wr_start_addr_i;  //Latch the destination address and transfer size
                 wr_len         <=  stream_len_i[31:3];
                 if(stream_len_i > 0)                     //If forgot to set the transfer size, do not hang!!
                     wr_state  <=  START;
                 else
                     wr_state  <=  WAIT_DEASSRT;                     
             end
         end
         START:begin
            if((rd_data_count >= 'd16) & (wr_len >= 16 )) //For efficient transfer, if more than 64 bytes to data is still remaining, wait.
            begin
                user_stream_data_avail_o   <=  1'b1;    //Once data is available, request to the arbitrator.
                user_stream_data_len_o     <=  5'd16;
                wr_state                   <=  WAIT_ACK;
                wr_len                     <=  wr_len - 5'd16;
            end
            else if(rd_data_count >= wr_len)
            begin
                wr_state                   <=  WAIT_ACK;
                wr_len                     <=  0;
                user_stream_data_avail_o   <=  1'b1;                  //Once data is in the FIFO, request the arbitrator    
                user_stream_data_len_o     <=  wr_len;     
            end
         end
         WAIT_ACK:begin
            if(user_stream_wr_ack_i)                                  //Once the arbitrator acks, remove the request and increment sys mem address
            begin
                user_stream_data_avail_o   <=  1'b0;
                dma_wr_addr          <=  dma_wr_addr + 8'd128;
                if(wr_len == 0)
                    wr_state                   <=  WAIT_DEASSRT;      //If all data is transferred, wait until it is updated in the status reg.
                else if((rd_data_count >= 'd16) & (wr_len >= 16 ))
                begin
                   user_stream_data_avail_o   <=  1'b1;    //Once data is available, request to the arbitrator.
                   user_stream_data_len_o     <=  5'd16;
                   wr_state                   <=  WAIT_ACK;
                   wr_len                     <=  wr_len - 5'd16;
                end
                else
                    wr_state             <=  START;    
            end
         end
         WAIT_DEASSRT:begin
             user_sys_strm_done_o    <=    1'b1;
             if(~user_sys_strm_en_i & user_sys_strm_done_ack)
                 wr_state    <=    IDLE;
         end
		endcase
	end	
end 


initial
begin
    state                 <= IDLE;
    dma_rd_req_o          <= 1'b0;
    dma_done_o            <= 1'b0;
    last_flag             <= 1'b0; 
    clr_fifo1_data_cntr   <= 1'b0;
    clr_fifo2_data_cntr   <= 1'b0;
    rcvd_data_cnt         <=  0;
    fifo_1_rcv_cnt        <=  0;
    fifo_2_rcv_cnt        <=  0;
end

always @(posedge clk_i)
begin
    if(~rst_n)
	 begin
	   state  <=  IDLE;
	 end
	 else
	 begin
		case(state)
        IDLE:begin
            dma_done_o          <= 1'b0;
            last_flag           <= 1'b0; 
            clr_fifo1_data_cntr <= 1'b0;
            clr_fifo2_data_cntr <= 1'b0;
            clr_rcv_data_cntr   <= 1'b1;
            dma_rd_req_addr_o   <= dma_src_addr_i;
            rd_len              <= dma_len_i;
            expected_data_cnt   <= dma_len_i;
            fifo_1_expt_cnt     <= 10'd0;
            fifo_2_expt_cnt     <= 10'd0;
            dma_rd_req_o        <= 1'b0;
            if(sys_user_strm_en_i)                      //If system to user dma is enabled
            begin
                state           <= REQ_BUF1;
            end
        end
        REQ_BUF1:begin    
            clr_rcv_data_cntr <= 1'b0;
            if((fifo_1_rcv_cnt >= fifo_1_expt_cnt) & !fifo1_valid) //If there is space in receive fifo make a request
            begin
                state         <= WAIT_BUF1_ACK;
                dma_rd_req_o  <= 1'b1;
                dma_tag_o     <= TAG1;
                clr_fifo1_data_cntr <= 1'b1;//Clear received cntr for FIFO1 since new request starting
                if(rd_len <= 'd4096)
                begin
                    dma_rd_req_len_o          <= rd_len[11:0];  
                    last_flag                 <= 1'b1;                     
                end
                else
                begin
                    dma_rd_req_len_o         <= 0;
                    fifo_1_expt_cnt          <= 10'd512;
                end
            end
        end
        WAIT_BUF1_ACK:begin
            clr_fifo1_data_cntr <= 1'b0;
            if(dma_req_ack_i)
            begin
                dma_rd_req_o <= 1'b0;
                if(last_flag)    //If all data is read, wait until complete data is received
                begin
                    state             <= INT_RESET;      
                end
                else
                begin
                    state               <= REQ_BUF2;
                    rd_len              <= rd_len - 'd4096;
                    dma_rd_req_addr_o   <= dma_rd_req_addr_o + 'd4096;
                end
				end	 
        end
        REQ_BUF2:begin
            if((fifo_2_rcv_cnt >= fifo_2_expt_cnt) & !fifo2_valid)  //If all data for the FIFO has arrived and written into DDR
            begin
                state           <= WAIT_BUF2_ACK;
                dma_rd_req_o    <= 1'b1;
                dma_tag_o       <= TAG2;
                clr_fifo2_data_cntr <= 1'b1;                          //Clear received cntr for FIFO1 since new request starting
                if(rd_len <= 'd4096)
                begin
                    dma_rd_req_len_o          <= rd_len[11:0];
                    last_flag                 <= 1'b1;                     
                end
                else
                begin
                    dma_rd_req_len_o         <= 0;
                    fifo_2_expt_cnt          <= 10'd512;
                end
            end
        end
        WAIT_BUF2_ACK:begin
            clr_fifo2_data_cntr <= 1'b0;
            if(dma_req_ack_i)
            begin
                dma_rd_req_o <= 1'b0;
                if(last_flag)    //If all data is read, wait until complete data is received
                begin
                    state             <= INT_RESET;     
                end
                else
                begin
                    state               <= REQ_BUF1;//REQ_BUF3;
                    rd_len              <= rd_len - 'd4096;
                    dma_rd_req_addr_o   <= dma_rd_req_addr_o + 'd4096;
                end
           end
        end 
        INT_RESET:begin
            if(rcvd_data_cnt >= expected_data_cnt[31:3])    //When both FIFOs are empty, go to idle
            begin
               dma_done_o        <= 1'b1;
            end
            if(~sys_user_strm_en_i & dma_done_ack_i)
            begin
                state               <= CLR_CNTR;
                dma_done_o          <= 1'b0;
            end 
        end
        CLR_CNTR:begin
            if(all_fifos_empty)
            begin
                clr_rcv_data_cntr   <= 1'b1;
                clr_fifo1_data_cntr <= 1'b1;
                clr_fifo2_data_cntr <= 1'b1;
                state               <= IDLE;
            end
        end
		endcase
	end	
end


always @(posedge clk_i)
begin
    if(clr_rcv_data_cntr)
        rcvd_data_cnt   <=    0;
    else if(fifo1_wr_en|fifo2_wr_en)
        rcvd_data_cnt   <=    rcvd_data_cnt + 1'd1; 
end

always @(posedge clk_i)
begin
   if(clr_fifo1_data_cntr)
       fifo_1_rcv_cnt   <=    0;
   else if(fifo1_wr_en)
       fifo_1_rcv_cnt   <=    fifo_1_rcv_cnt + 1'd1; 
end
always @(posedge clk_i)
begin
   if(clr_fifo2_data_cntr)
       fifo_2_rcv_cnt   <=    0;
   else if(fifo2_wr_en)
       fifo_2_rcv_cnt   <=    fifo_2_rcv_cnt + 1'd1; 
end


//user_logic_stream_wr_fifo
user_fifo user_wr_fifo_1 (
  .s_aclk(clk_i), 
  .s_aresetn(rst_n), 
  .s_axis_tvalid(fifo1_wr_en), //
  .s_axis_tready(),
  .s_axis_tdata(dma_data_p),
  .m_axis_tvalid(fifo1_valid),
  .m_axis_tready(fifo1_rdy), 
  .m_axis_tdata(fifo1_rd_data)
);

//user_logic_stream_wr_fifo
user_fifo user_wr_fifo_2 (
  .s_aclk(clk_i), 
  .s_aresetn(rst_n), 
  .s_axis_tvalid(fifo2_wr_en), //
  .s_axis_tready(),
  .s_axis_tdata(dma_data_p),
  .m_axis_tvalid(fifo2_valid),
  .m_axis_tready(fifo2_rdy), 
  .m_axis_tdata(fifo2_rd_data)
);

  //user_logic_stream_rd_fifo
user_strm_fifo user_rd_fifo (
  .s_aclk(clk_i), // input s_aclk
  .s_aresetn(rst_n), // input s_aresetn
  .s_axis_tvalid(stream_data_valid_i), // input s_axis_tvalid
  .s_axis_tready(stream_data_ready_o), // output s_axis_tready
  .s_axis_tdata(stream_data_i), // input [63 : 0] s_axis_tdata
  //.m_aclk(clk_i),
  .m_axis_tvalid(), // output m_axis_tvalid
  .m_axis_tready(user_stream_data_rd_i), // input m_axis_tready
  .m_axis_tdata(user_stream_data_o), // output [63 : 0] m_axis_tdata
  .axis_data_count(rd_data_count)
);

endmodule
