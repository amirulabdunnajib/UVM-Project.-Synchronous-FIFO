// Reset test: rst_n held low while wr_en / rd_en are HIGH.
// Expected: wptr, rptr, count stay 0, empty = 1, full = 0, rd_data = 0.
`timescale 1ns/1ns

module tb_reset_test;

  reg        clk = 0;
  reg        rst_n;
  reg        wr_en, rd_en;
  reg  [7:0] wr_data;
  wire [7:0] rd_data;
  wire       rd_valid, full, empty, overflow, underflow;

  integer errors = 0;

  fifo dut (
    .clk(clk), .rst_n(rst_n),
    .wr_en(wr_en), .rd_en(rd_en), .wr_data(wr_data),
    .rd_data(rd_data), .rd_valid(rd_valid),
    .full(full), .empty(empty),
    .overflow(overflow), .underflow(underflow)
  );

  always #5 clk = ~clk;   // 10 ns period

  // Check the reset state. Called right after a clock edge.
  task check_reset_state(input [255:0] label);
    begin
      if (dut.wptr  !== 4'd0) begin $display("FAIL [%0s] t=%0t wptr  = %0d (expected 0)", label, $time, dut.wptr);  errors = errors + 1; end
      if (dut.rptr  !== 4'd0) begin $display("FAIL [%0s] t=%0t rptr  = %0d (expected 0)", label, $time, dut.rptr);  errors = errors + 1; end
      if (dut.count !== 5'd0) begin $display("FAIL [%0s] t=%0t count = %0d (expected 0)", label, $time, dut.count); errors = errors + 1; end
      if (empty     !== 1'b1) begin $display("FAIL [%0s] t=%0t empty = %b (expected 1)",  label, $time, empty);     errors = errors + 1; end
      if (full      !== 1'b0) begin $display("FAIL [%0s] t=%0t full  = %b (expected 0)",  label, $time, full);      errors = errors + 1; end
      if (rd_data   !== 8'd0) begin $display("FAIL [%0s] t=%0t rd_data = %0h (expected 0)", label, $time, rd_data); errors = errors + 1; end
    end
  endtask

  integer i;

  initial begin
    // ---------------- Test 1: reset from power-up, with wr_en = 1 ----------------
    rst_n = 0; wr_en = 1; rd_en = 0; wr_data = 8'hAA;

    for (i = 0; i < 4; i = i + 1) begin
      @(posedge clk); #1;
      check_reset_state("T1 reset, wr_en=1");
    end

    // ---------------- Test 2: reset with wr_en = 1 AND rd_en = 1 ----------------
    rd_en = 1;
    for (i = 0; i < 4; i = i + 1) begin
      @(posedge clk); #1;
      check_reset_state("T2 reset, wr_en=1 rd_en=1");
    end

    // ---------------- Test 3: reset in the middle of operation -------------------
    rst_n = 1; wr_en = 1; rd_en = 0;
    for (i = 0; i < 5; i = i + 1) begin
      wr_data = 8'h10 + i;
      @(posedge clk); #1;
    end
    if (dut.count !== 5'd5) begin
      $display("FAIL [T3 setup] count = %0d (expected 5 before reset)", dut.count);
      errors = errors + 1;
    end

    #2 rst_n = 0;            // asynchronous assert, away from a clock edge
    #1;
    check_reset_state("T3 async reset, wr_en=1");   // async reset should clear immediately
    for (i = 0; i < 3; i = i + 1) begin
      @(posedge clk); #1;
      check_reset_state("T3 reset held, wr_en=1");
    end

    // ---------------- Test 4: release reset, FIFO should work normally -----------
    rst_n = 1; wr_en = 1; rd_en = 0; wr_data = 8'h5A;
    @(posedge clk); #1;
    if (dut.count !== 5'd1) begin
      $display("FAIL [T4] after release, count = %0d (expected 1)", dut.count);
      errors = errors + 1;
    end
    wr_en = 0; rd_en = 1;
    @(posedge clk); #1;
    if (rd_data !== 8'h5A) begin
      $display("FAIL [T4] rd_data = %0h (expected 5A)", rd_data);
      errors = errors + 1;
    end

    // ---------------- Summary ----------------------------------------------------
    if (errors == 0) $display("RESET TEST PASSED");
    else             $display("RESET TEST FAILED: %0d error(s)", errors);
    $finish;
  end

endmodule
