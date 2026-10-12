// Fixed size: 16 locations, 8-bit data width.
module fifo (
    input clk, input rst_n, input wr_en, input rd_en,
    input [7:0] wr_data, output reg [7:0] rd_data,
    output rd_valid, output full, output empty, output overflow, output underflow
);
reg [3:0] wptr; reg [3:0] rptr; reg [4:0] count;
wire write_accepted; wire read_accepted;
assign write_accepted = wr_en && (!full || rd_en);
assign read_accepted  = rd_en && !empty;
reg [7:0] mem_fifo[15:0];
always @(posedge clk) begin if (write_accepted) mem_fifo[wptr] <= wr_data; end
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin wptr <= 0; count <= 0; rptr <= 0; rd_data <= 0; end
  else begin
    if (read_accepted) begin rptr <= rptr + 1; rd_data <= mem_fifo[rptr]; end
    if (write_accepted) wptr <= wptr + 1;
    case ({write_accepted, read_accepted})
      2'b10: count <= count + 1;
      2'b01: count <= count - 1;
      2'b11: count <= count;
      default: ;
    endcase
  end
end
assign rd_valid = (rd_data == mem_fifo[rptr]);
assign full  = (count == 5'b10000);
assign empty = (count == 5'b00000);
endmodule
