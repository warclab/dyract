module gaussian_top(
input        i_clk,
input        i_rst,
input        i_line1_data_valid,
input [63:0] i_line1_data,
output       o_line1_data_ack,
input        i_line2_data_valid,
input [63:0] i_line2_data,
output       o_line2_data_ack,
input        i_line3_data_valid,
input [63:0] i_line3_data,
output       o_line3_data_ack,
output       o_sobel_data_valid,
output [63:0]o_sobel_data,
input        i_sobel_data_ack,
input        i_filter
);

reg [5:0]  line1_wr_addr;
reg [5:0]  line2_wr_addr;
reg [5:0]  line3_wr_addr;
reg [8:0]  line_rd_addr;
wire [7:0] line1_data;
wire [7:0] line2_data;
wire [7:0] line3_data;
wire [7:0] filt_out_pixel;
wire [7:0] x_filt_out_pixel;
reg        line_data_valid;

localparam IDLE    = 'b0,
           RD_LINE = 'b1;
			  
reg    rd_state;

assign o_line1_data_ack =  filter_rdy;
assign o_line2_data_ack =  filter_rdy;
assign o_line3_data_ack =  filter_rdy;
assign o_sobel_data_valid =  !out_fifo_empty;
assign filt_out_pixel   =  x_filt_out_pixel;

initial
begin
    line1_wr_addr <=  0;
    line2_wr_addr <=  0;
    line3_wr_addr <=  0;
	line_rd_addr  <=  0;
	rd_state      <=  IDLE;
	line_data_valid <=   1'b0;
end

always @(posedge i_clk)
begin
    if(!i_rst)
	     rd_state    <=    IDLE;
	 else
    begin	 
		case(rd_state)
			IDLE:begin
					line_rd_addr  <=  0;
					line_data_valid <=   1'b0;
					if(i_filter)
					begin
						line_data_valid <=   1'b1;
						line_rd_addr    <=   line_rd_addr + 1'b1;
						rd_state        <=   RD_LINE;
					end
			end
			RD_LINE:begin
					if((line_rd_addr != 0) & filter_rdy)
						line_rd_addr    <=   line_rd_addr + 1'b1;
					if(line_rd_addr == 0)
					begin
						line_data_valid <=   1'b0;
						if(!i_filter)
							rd_state    <=   IDLE;
					end	 
			end
		endcase
	end
end

always @(posedge i_clk)
begin
   if(!i_rst)
	begin
	  line1_wr_addr <=  0;
      line2_wr_addr <=  0;
      line3_wr_addr <=  0;
	end
	else
	begin
		if(i_line1_data_valid)
			line1_wr_addr <= line1_wr_addr + 1'b1;
		if(i_line2_data_valid)
			line2_wr_addr <= line2_wr_addr + 1'b1;	 
		if(i_line3_data_valid)
			line3_wr_addr <= line3_wr_addr + 1'b1;	 
	end
end	

line_buffer lb1 (
  .clka(i_clk), // input clka
  .wea(i_line1_data_valid), // input [0 : 0] wea
  .addra(line1_wr_addr), // input [5 : 0] addra
  .dina({i_line1_data[31:24],i_line1_data[23:16],i_line1_data[15:8],i_line1_data[7:0],i_line1_data[63:56],i_line1_data[55:48],i_line1_data[47:40],i_line1_data[39:32]}), // input [63 : 0] dina
  .clkb(i_clk), // input clkb
  .addrb(line_rd_addr), // input [8 : 0] addrb
  .doutb(line1_data) // output [7 : 0] doutb
);

line_buffer lb2 (
  .clka(i_clk), // input clka
  .wea(i_line2_data_valid), // input [0 : 0] wea
  .addra(line2_wr_addr), // input [5 : 0] addra
  .dina({i_line2_data[31:24],i_line2_data[23:16],i_line2_data[15:8],i_line2_data[7:0],i_line2_data[63:56],i_line2_data[55:48],i_line2_data[47:40],i_line2_data[39:32]}), // input [63 : 0] dina
  .clkb(i_clk), // input clkb
  .addrb(line_rd_addr), // input [8 : 0] addrb
  .doutb(line2_data) // output [7 : 0] doutb
);

line_buffer lb3 (
  .clka(i_clk), // input clka
  .wea(i_line3_data_valid), // input [0 : 0] wea
  .addra(line3_wr_addr), // input [5 : 0] addra
  .dina({i_line3_data[31:24],i_line3_data[23:16],i_line3_data[15:8],i_line3_data[7:0],i_line3_data[63:56],i_line3_data[55:48],i_line3_data[47:40],i_line3_data[39:32]}), // input [63 : 0] dina
  .clkb(i_clk), // input clkb
  .addrb(line_rd_addr), // input [8 : 0] addrb
  .doutb(line3_data) // output [7 : 0] doutb
);


// Instantiate the module
filter_x filtx (
    .i_clk(i_clk), 
    .i_pixel_1(line1_data), 
    .i_pixel_2(line2_data), 
    .i_pixel_3(line3_data), 
    .i_pixel_valid(line_data_valid), 
    .o_pixel_ack(filter_rdy), 
    .o_pixel_valid(filt_pixel_valid), 
    .i_pixel_ack(~out_fifo_full), 
    .o_pixel(x_filt_out_pixel)
    );
	 
output_fifo op_fifo (
  .wr_clk(i_clk), // input wr_clk
  .rd_clk(i_clk), // input rd_clk
  .rst(~i_rst),
  .din(filt_out_pixel), // input [7 : 0] din
  .wr_en(filt_pixel_valid), // input wr_en
  .rd_en(i_sobel_data_ack), // input rd_en
  .dout({o_sobel_data[39:32],o_sobel_data[47:40],o_sobel_data[55:48],o_sobel_data[63:56],o_sobel_data[7:0],o_sobel_data[15:8],o_sobel_data[23:16],o_sobel_data[31:24]}), // output [63 : 0] dout
  .full(out_fifo_full), // output full
  .empty(out_fifo_empty) // output empty
);	 

endmodule
