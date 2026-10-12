`timescale 1ns/1ns

// T5: write when full, with a read in the same cycle (R5)
module tb_t5;

  reg        clk = 0;
  reg        rst_n;
  reg        wr_en, rd_en;
  reg  [7:0] wr_data;
  wire [7:0] rd_data;
  wire       rd_valid, full, empty, overflow, underflow;

  fifo dut (
    .clk(clk), .rst_n(rst_n),
    .wr_en(wr_en), .rd_en(rd_en), .wr_data(wr_data),
    .rd_data(rd_data), .rd_valid(rd_valid),
    .full(full), .empty(empty),
    .overflow(overflow), .underflow(underflow)
  );

integer errors = 0;
always #5 clk = ~clk;   // 10 ns period, rising edges at 5, 15, 25, ...


  // One log line per clock: inputs that were applied, outputs after the edge
  task show(input [255:0] step);
    begin
      $display("t=%4t | %-12s | in: wr=%b rd=%b wdata=%h | out: count=%2d full=%b empty=%b rd_valid=%b rd_data=%h ovf=%b unf=%b",
               $time, step, wr_en, rd_en, wr_data,
               dut.count, full, empty, rd_valid, rd_data, overflow, underflow);
    end
  endtask

  // Compare one value; print details only when it is wrong
  task expect_eq(input [255:0] step, input [255:0] what,
                 input [7:0] actual, input [7:0] expected);
    begin
      if (actual !== expected) begin
        $display("      FAIL [%0s] %0s = %h, expected %h  (t=%0t)",
                 step, what, actual, expected, $time);
        errors = errors + 1;
      end
    end
  endtask


  initial begin
    rst_n = 0; wr_en = 0; rd_en = 0; wr_data = 8'h00;
    repeat (2) @(posedge clk);
    @(negedge clk) rst_n = 1;                 // release reset away from a clock edge

    rd_en = 1; 
    @(posedge clk) #1 show( "Read enable, trigger underflow");
    expect_eq("trigger","underflow", underflow, 1'b1 );

     $display("\n=================================================");
    if (errors == 0) $display("T5 PASSED");
    else             $display("T5 FAILED: %0d error(s)", errors);
    $display("=================================================");
    $finish;
  end

endmodule



