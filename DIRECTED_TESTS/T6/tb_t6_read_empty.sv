`timescale 1ns/1ns
module tb_t6;
  reg clk = 0;
  reg rst_n;
  reg wr_en, rd_en;
  reg [7:0] wr_data;
  wire [7:0] rd_data;
  wire rd_valid, full, empty, overflow, underflow;
  integer errors = 0;
  always #5 clk = ~clk;
  fifo dut (.clk(clk), .rst_n(rst_n), .wr_en(wr_en), .rd_en(rd_en), .wr_data(wr_data), .rd_data(rd_data), .rd_valid(rd_valid), .full(full), .empty(empty), .overflow(overflow), .underflow(underflow));
  task expect_eq(input [255:0] step, input [255:0] what, input [7:0] actual, input [7:0] expected);
    if (actual !== expected) begin
      $display("FAIL [%0s] %0s = %h, expected %h", step, what, actual, expected);
      errors++;
    end
  endtask
  initial begin
    rst_n=0; wr_en=0; rd_en=0; wr_data=0;
    repeat(2) @(posedge clk);
    @(negedge clk) rst_n=1;
    @(negedge clk) rd_en=1;
    @(posedge clk); #1;
    expect_eq("Read at empty", "underflow", underflow, 1'b1);
    if (errors==0) $display("T6 PASSED"); else $display("T6 FAILED: %0d error(s)", errors);
    $finish;
  end
endmodule
