`timescale 1ns/1ns
module tb_5;
  reg clk = 0;
  reg rst_n;
  reg wr_en, rd_en;
  reg [7:0] wr_data;
  wire [7:0] rd_data;
  wire rd_valid, full, empty, overflow, underflow;
  integer errors = 0;
  fifo dut (.clk(clk), .rst_n(rst_n), .wr_en(wr_en), .rd_en(rd_en), .wr_data(wr_data), .rd_data(rd_data), .rd_valid(rd_valid), .full(full), .empty(empty), .overflow(overflow), .underflow(underflow));
  always #5 clk = ~clk;
  // Preserved first draft from the uploaded project. It was later replaced by the self-checking T5.
  // Original draft contained syntax mistakes and assumed fixed memory indices; keep as learning history, not as the runnable test.
endmodule
