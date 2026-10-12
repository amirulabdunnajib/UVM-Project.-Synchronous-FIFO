`timescale 1ns/1ns
// Preserved user draft. It contains syntax/helper-name mistakes that were corrected in t7_final.sv.
module tb_t7;
  reg clk = 0; reg rst_n; reg wr_en, rd_en; reg [7:0] wr_data;
  wire [7:0] rd_data; wire rd_valid, full, empty, overflow, underflow;
  fifo dut (.clk(clk), .rst_n(rst_n), .wr_en(wr_en), .rd_en(rd_en), .wr_data(wr_data), .rd_data(rd_data), .rd_valid(rd_valid), .full(full), .empty(empty), .overflow(overflow), .underflow(underflow));
  integer errors = 0;
  always #5 clk = ~clk;
  initial begin
    rst_n=0; wr_en=0; rd_en=0; wr_data=0;
    repeat(2) @(posedge clk);
    @(negedge clk) rst_n=1;
    @(negedge clk); wr_en=1; wr_data=8'h5A;
    @(posedge clk); #1;
    @(negedge clk); rd_en=1; wr_en=0;
    @(posedge clk); #1;
    @(negedge clk); rd_en=1;
    @(posedge clk); #1;
    // Draft intent: verify empty read holds 5A, deasserts rd_valid, asserts underflow and leaves pointer/count unchanged.
  end
endmodule
