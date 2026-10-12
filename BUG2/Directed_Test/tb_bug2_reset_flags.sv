`timescale 1ns/1ns
module tb_bug2_reset_flags;
  reg clk = 0;
  reg rst_n, wr_en, rd_en;
  reg [7:0] wr_data;
  wire [7:0] rd_data;
  wire rd_valid, full, empty, overflow, underflow;
  integer errors = 0;

  fifo dut(.*);
  always #5 clk = ~clk;

  task check_flags(input [255:0] label);
    begin
      if (overflow !== 1'b0) begin
        $display("FAIL [%0s] overflow=%b expected 0", label, overflow); errors++;
      end
      if (underflow !== 1'b0) begin
        $display("FAIL [%0s] underflow=%b expected 0", label, underflow); errors++;
      end
    end
  endtask

  initial begin
    rst_n = 1; wr_en = 0; rd_en = 0; wr_data = 0;
    #2 rst_n = 0; // asynchronous assertion away from a clock edge
    #1 check_flags("async reset");

    wr_en = 1; rd_en = 1; wr_data = 8'hAA;
    repeat (2) begin @(posedge clk); #1; check_flags("reset held with requests high"); end

    if (errors == 0) $display("BUG2 RESET-FLAG TEST PASSED");
    else             $display("BUG2 RESET-FLAG TEST FAILED: %0d error(s)", errors);
    $finish;
  end
endmodule
