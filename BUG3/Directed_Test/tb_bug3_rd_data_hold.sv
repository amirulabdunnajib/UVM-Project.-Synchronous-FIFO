`timescale 1ns/1ns
module tb_bug3_rd_data_hold;
  reg clk = 0;
  reg rst_n, wr_en, rd_en;
  reg [7:0] wr_data;
  wire [7:0] rd_data;
  wire rd_valid, full, empty, overflow, underflow;
  integer errors = 0;
  integer i;
  fifo dut(.*);
  always #5 clk = ~clk;

  initial begin
    rst_n=0; wr_en=0; rd_en=0; wr_data=0;
    repeat(2) @(posedge clk);
    @(negedge clk) rst_n=1;

    // Fill known values 10..1F.
    for (i=0; i<16; i=i+1) begin
      wr_en=1; rd_en=0; wr_data=8'h10+i;
      @(posedge clk); #1;
    end

    // Drain all 16. Final accepted read must leave rd_data=1F.
    wr_en=0; rd_en=1;
    repeat(16) @(posedge clk);
    #1;
    if (rd_data !== 8'h1F) begin
      $display("FAIL setup: rd_data=%h expected 1F", rd_data); errors++;
    end

    // Rejected read while empty. Correct behavior: hold 1F.
    @(posedge clk); #1;
    if (rd_valid !== 1'b0) begin $display("FAIL rd_valid=%b expected 0", rd_valid); errors++; end
    if (underflow !== 1'b1) begin $display("FAIL underflow=%b expected 1", underflow); errors++; end
    if (rd_data !== 8'h1F) begin
      $display("FAIL BUG3: rd_data=%h expected hold value 1F", rd_data); errors++;
    end

    if (errors==0) $display("BUG3 RD_DATA HOLD TEST PASSED");
    else           $display("BUG3 RD_DATA HOLD TEST FAILED: %0d error(s)", errors);
    $finish;
  end
endmodule
