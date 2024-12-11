module e203_dma (

    output reg                          dma_icb_cmd_valid,
    input wire                           dma_icb_cmd_ready,
    output reg  [`E203_ADDR_SIZE-1:0]   dma_icb_cmd_addr,
    output reg                          dma_icb_cmd_read,
    output reg  [`E203_XLEN-1:0]        dma_icb_cmd_wdata,
    output reg  [`E203_XLEN/8-1:0]        dma_icb_cmd_wmask,
    //
    input wire                         dma_icb_rsp_valid,
    output reg                        dma_icb_rsp_ready,
    input wire                         dma_icb_rsp_err,
    input wire [`E203_XLEN-1:0]        dma_icb_rsp_rdata,
    output reg                        dma_irq,
  
    input wire                          dma_cfg_icb_cmd_valid,
    output reg                         dma_cfg_icb_cmd_ready,
    input wire  [`E203_ADDR_SIZE-1:0]   dma_cfg_icb_cmd_addr,
    input wire                          dma_cfg_icb_cmd_read,
    input wire  [`E203_XLEN-1:0]        dma_cfg_icb_cmd_wdata,
    input wire  [`E203_XLEN/8-1:0]        dma_cfg_icb_cmd_wmask,
    //
    output reg                         dma_cfg_icb_rsp_valid,
    input wire                          dma_cfg_icb_rsp_ready,
    output reg                         dma_cfg_icb_rsp_err,
    output reg [`E203_XLEN-1:0]        dma_cfg_icb_rsp_rdata,
   
    input wire			      clk,
    input wire                        rst_n
);



  parameter ADDR_SRC = 32'h10000000;
  parameter ADDR_DST = 32'h10000004;
  parameter ADDR_LEN = 32'h10000008;
  parameter ADDR_STA = 32'h1000000C;

  reg [31:0] src_addr;
  reg [31:0] dst_addr;
  reg [31:0] length;
  reg [7:0] state;
   
  reg [31:0] cnt;
  //reg [31:0] buffer;

  //below cpu<->dma

always @ (posedge clk or negedge rst_n) 
begin
    if (!rst_n)
      dma_cfg_icb_cmd_ready <= 1'b0;
    else if (dma_cfg_icb_cmd_valid)
      dma_cfg_icb_cmd_ready <= 1'b1;
    else
      dma_cfg_icb_cmd_ready <= 1'b0;
end


always @ (posedge clk or negedge rst_n)
begin
    if (!rst_n)
      dma_cfg_icb_rsp_valid <= 1'b0;
    else if (dma_cfg_icb_cmd_valid)
      dma_cfg_icb_rsp_valid <= 1'b1;
    else
      dma_cfg_icb_rsp_valid <= 1'b0;
end

always @ (posedge clk or negedge rst_n) 
begin
  if (!rst_n)
      dma_cfg_icb_rsp_rdata <= 32'h0;
    else if (dma_cfg_icb_cmd_addr == ADDR_SRC && dma_cfg_icb_cmd_valid && (dma_cfg_icb_cmd_read))
      dma_cfg_icb_rsp_rdata <= src_addr;
    else if (dma_cfg_icb_cmd_addr == ADDR_DST && dma_cfg_icb_cmd_valid && (dma_cfg_icb_cmd_read))
      dma_cfg_icb_rsp_rdata <= dst_addr;
    else if (dma_cfg_icb_cmd_addr == ADDR_LEN && dma_cfg_icb_cmd_valid && (dma_cfg_icb_cmd_read))
      dma_cfg_icb_rsp_rdata <= length;
    else if (dma_cfg_icb_cmd_addr == ADDR_STA && dma_cfg_icb_cmd_valid && (dma_cfg_icb_cmd_read))
      dma_cfg_icb_rsp_rdata <= state;
    else
      dma_cfg_icb_rsp_rdata <= 32'h0;
end

always @ (posedge clk or negedge rst_n) 
begin
  if (!rst_n)
      dma_cfg_icb_rsp_err <= 1'b0;
    else if (dma_cfg_icb_rsp_rdata == 32'h0 || dma_cfg_icb_rsp_rdata == src_addr || dma_cfg_icb_rsp_rdata == dst_addr || dma_cfg_icb_rsp_rdata == length || dma_cfg_icb_rsp_rdata == state)
      dma_cfg_icb_rsp_err <= 1'b0;
    else
      dma_cfg_icb_rsp_err <= 1'b1;
end

always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) src_addr <= 32'h20000c6c;
  else if(dma_cfg_icb_cmd_addr == ADDR_SRC && dma_cfg_icb_cmd_valid && (!dma_cfg_icb_cmd_read))
  begin
    src_addr <= dma_cfg_icb_cmd_wdata;
  end
  else src_addr <= src_addr;
end

always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) dst_addr <= 32'h30000000; 
  else if(dma_cfg_icb_cmd_addr == ADDR_DST && dma_cfg_icb_cmd_valid && (!dma_cfg_icb_cmd_read))
  begin
    dst_addr <= dma_cfg_icb_cmd_wdata;
  end
  else dst_addr <= dst_addr;
end


always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) length <= 0;
  else if(dma_cfg_icb_cmd_addr == ADDR_LEN && dma_cfg_icb_cmd_valid && (!dma_cfg_icb_cmd_read))
  begin
   length <= dma_cfg_icb_cmd_wdata;
  end
  else length <= length;
end

always @ (posedge clk or negedge rst_n)//0:enable;  1:read;  2:wirte;  3:once transport 
begin
  if(!rst_n) state <= 0;
  else if(dma_cfg_icb_cmd_addr == ADDR_STA && dma_cfg_icb_cmd_valid && (!dma_cfg_icb_cmd_read))
  begin
   state[0] <= dma_cfg_icb_cmd_wdata[0];
   state[3] <= 1;//for loop the state
  end
  else if(state[0] == 1 && state[3] == 1 && cnt != length + 1)
       begin
         state[3] <= 0;
         state[1] <= 1;
       end
  else if(dma_icb_cmd_ready && dma_icb_rsp_valid && state[1] == 1 && cnt != length + 1)
       begin 
         state[1] <= 0;
         state[2] <= 1;
       end
  else if(dma_icb_cmd_ready && dma_icb_rsp_valid && state[2] == 1 && cnt != length + 1)
       begin
         state[2] <= 0;
         state[3] <= 1;
       end
  else if(cnt == length + 1) state <= 0;
  else state <= state;

end

always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) cnt <= -1;
  else if(state[3] == 1 && cnt != length + 1) cnt <= cnt + 1;//one more time bcuz initial state3 == 1
  else if(cnt == length + 1) cnt <= 0;
  else cnt <= cnt;

end

  // below dma<->mem
always @ (posedge clk or negedge rst_n) 
begin
  if (!rst_n)
    dma_icb_cmd_wmask <= 4'b0;
  else if (state[2] == 1)
    dma_icb_cmd_wmask <= 4'b1111;
  else
    dma_icb_cmd_wmask <= 4'b0;
end

always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) dma_icb_cmd_valid <= 0;
  else if(state[1] == 1 || state[2] == 1) dma_icb_cmd_valid <= 1;
  else dma_icb_cmd_valid <= 0;
end

always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) dma_icb_rsp_ready <= 0;
  else if(dma_icb_rsp_valid) dma_icb_rsp_ready <= 1;
  else dma_icb_rsp_ready <= 0;
end

always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) dma_icb_cmd_addr <= 0;
  else if(state[1] == 1) dma_icb_cmd_addr <= src_addr + (cnt - 1) * 4;
  else if(state[2] == 1) dma_icb_cmd_addr <= dst_addr + (cnt - 1) * 4;
  else dma_icb_cmd_addr <= dma_icb_cmd_addr;
end

always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) dma_icb_cmd_read <= 0;//dont know what default state for this signal
  else if(state[1] == 1) dma_icb_cmd_read <= 1;
  else if(state[2] == 1) dma_icb_cmd_read <= 0;
  else dma_icb_cmd_read <= dma_icb_cmd_read;
end

/*
always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) buffer <= 0;
  else if(dma_icb_rsp_valid) buffer <= dma_icb_rsp_rdata;
  else buffer <= buffer;
end
*/

always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) dma_icb_cmd_wdata <= 0;
  else if(dma_icb_rsp_valid && state[2] == 1) dma_icb_cmd_wdata <= dma_icb_rsp_rdata;
  else dma_icb_cmd_wdata <= dma_icb_cmd_wdata;
end

always @ (posedge clk or negedge rst_n)
begin
  if(!rst_n) dma_irq <= 0;
  else if(cnt == length + 1 || dma_icb_rsp_err) dma_irq <= 1;
  else dma_irq <= 0;
end

endmodule
