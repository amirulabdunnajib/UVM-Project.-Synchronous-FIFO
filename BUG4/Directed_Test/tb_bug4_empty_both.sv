`timescale 1ns/1ns
module tb_bug4_empty_both;
  reg clk = 0;
  reg rst_n, wr_en, rd_en;
  reg [7:0] wr_data;
  wire [7:0] rd_data;
  wire rd_valid, full, empty, overflow, underflow;
  integer errors = 0;
  fifo dut(.*);
  always #5 clk = ~clk;

  initial begin
    rst_n=0; wr_en=0; rd_en=0; wr_data=0;
    repeat(2) @(posedge clk);
    @(negedge clk) rst_n=1;

    // EMPTY + write/read: write accepted, read rejected, underflow must pulse.
    wr_en=1; rd_en=1; wr_data=8'h5A;
    @(posedge clk); #1;
    if (dut.count !== 5'd1) begin $display("FAIL count=%0d expected 1", dut.count); errors++; end
    if (rd_valid !== 1'b0) begin $display("FAIL rd_valid=%b expected 0", rd_valid); errors++; end
    if (underflow !== 1'b1) begin $display("FAIL BUG4 underflow=%b expected 1", underflow); errors++; end

    // Item written in the simultaneous cycle must still be present.
    wr_en=0; rd_en=1; wr_data=0;
    @(posedge clk); #1;
    if (rd_valid !== 1'b1 || rd_data !== 8'h5A) begin
      $display("FAIL readback rd_valid=%b rd_data=%h expected 1/5A", rd_valid, rd_data); errors++;
    end

    if (errors==0) $display("BUG4 EMPTY+BOTH TEST PASSED");
    else           $display("BUG4 EMPTY+BOTH TEST FAILED: %0d error(s)", errors);
    $finish;
  end
endmodule
