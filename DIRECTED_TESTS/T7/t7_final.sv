`timescale 1ns/1ns
// T7: read when empty (ignored read), hold value, back-to-back reads, read-back after
module tb_t7;
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
    if (actual !== expected) begin $display("FAIL [%0s] %0s = %h, expected %h", step, what, actual, expected); errors++; end
  endtask
  initial begin
    rst_n=0; wr_en=0; rd_en=0; wr_data=0;
    repeat(2) @(posedge clk); @(negedge clk) rst_n=1;
    @(negedge clk); wr_en=1; wr_data=8'h5A;
    @(posedge clk); #1; expect_eq("Write 5A","count",dut.count,1); expect_eq("Write 5A","rptr",dut.rptr,0);
    @(negedge clk); rd_en=1; wr_en=0;
    @(posedge clk); #1; expect_eq("Read 5A","rd_data",rd_data,8'h5A); expect_eq("Read 5A","rd_valid",rd_valid,1); expect_eq("Read 5A","rptr",dut.rptr,1);
    @(negedge clk); rd_en=1;
    @(posedge clk); #1;
    expect_eq("Empty read #1","count",dut.count,0); expect_eq("Empty read #1","empty",empty,1); expect_eq("Empty read #1","rd_data",rd_data,8'h5A); expect_eq("Empty read #1","rd_valid",rd_valid,0); expect_eq("Empty read #1","underflow",underflow,1); expect_eq("Empty read #1","rptr",dut.rptr,1);
    @(negedge clk); @(posedge clk); #1;
    expect_eq("Empty read #2","rd_data",rd_data,8'h5A); expect_eq("Empty read #2","underflow",underflow,1); expect_eq("Empty read #2","rptr",dut.rptr,1);
    @(negedge clk); rd_en=0; @(posedge clk); #1; expect_eq("Idle","underflow",underflow,0); expect_eq("Idle","rd_data",rd_data,8'h5A);
    @(negedge clk); wr_en=1; wr_data=8'hA5; @(posedge clk); #1; expect_eq("Write A5","count",dut.count,1); expect_eq("Write A5","rd_data",rd_data,8'h5A);
    @(negedge clk); wr_en=0; rd_en=1; @(posedge clk); #1; expect_eq("Read A5","rd_valid",rd_valid,1); expect_eq("Read A5","count",dut.count,0); expect_eq("Read A5","rd_data",rd_data,8'hA5); expect_eq("Read A5","rptr",dut.rptr,2);
    if (errors==0) $display("T7 PASSED"); else $display("T7 FAILED: %0d error(s)", errors);
    $finish;
  end
endmodule
