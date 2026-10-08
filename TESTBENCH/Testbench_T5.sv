`timescale 1ns/1ns

// T5: write when full, with a read in the same cycle (R5)
module tb_t5;

  reg        clk = 0;
  reg        rst_n;
  reg        wr_en, rd_en;
  reg  [7:0] wr_data;
  wire [7:0] rd_data;
  wire       rd_valid, full, empty, overflow, underflow;

  integer errors = 0;
  integer i, k;

  fifo dut (
    .clk(clk), .rst_n(rst_n),
    .wr_en(wr_en), .rd_en(rd_en), .wr_data(wr_data),
    .rd_data(rd_data), .rd_valid(rd_valid),
    .full(full), .empty(empty),
    .overflow(overflow), .underflow(underflow)
  );

  always #5 clk = ~clk;   // 10 ns period, rising edges at 5, 15, 25, ...

  // Waveform dump (open dump.vcd in EPWave / GTKWave)
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_t5);
  end

  // ---------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------

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

  // ---------------------------------------------------------------
  // Test
  // D0..D15 = 10..1F (distinct), the extra write is AA
  // ---------------------------------------------------------------
  initial begin
    rst_n = 0; wr_en = 0; rd_en = 0; wr_data = 8'h00;
    repeat (2) @(posedge clk);
    @(negedge clk) rst_n = 1;                 // release reset away from a clock edge

    $display("\n--- Step 1: fill the FIFO with 16 distinct values ---");
    for (i = 0; i < 16; i = i + 1) begin
      @(negedge clk);                         // drive inputs on the falling edge
      wr_en = 1; rd_en = 0; wr_data = 8'h10 + i;
      @(posedge clk); #1;                     // look 1 ns after the rising edge
      show("fill");
    end
    expect_eq("fill done", "count", dut.count, 8'd16);
    expect_eq("fill done", "full",  full,      8'd1);
    expect_eq("fill done", "empty", empty,     8'd0);

    $display("\n--- Step 2: FULL, write AA and read in the same cycle ---");
    @(negedge clk);
    wr_en = 1; rd_en = 1; wr_data = 8'hAA;
    @(posedge clk); #1;
    show("full+wr+rd");
    expect_eq("full+wr+rd", "count",     dut.count, 8'd16);  // stays 16
    expect_eq("full+wr+rd", "full",      full,      8'd1);
    expect_eq("full+wr+rd", "empty",     empty,     8'd0);
    expect_eq("full+wr+rd", "rd_data",   rd_data,   8'h10);  // oldest item, D0 (not AA)
    expect_eq("full+wr+rd", "rd_valid",  rd_valid,  8'd1);
    expect_eq("full+wr+rd", "overflow",  overflow,  8'd0);   // write was accepted
    expect_eq("full+wr+rd", "underflow", underflow, 8'd0);

    $display("\n--- Step 3: two idle cycles (state must be stable) ---");
    for (k = 0; k < 2; k = k + 1) begin
      @(negedge clk);
      wr_en = 0; rd_en = 0; wr_data = 8'h55;   // junk data, must be ignored
      @(posedge clk); #1;
      show("idle");
      expect_eq("idle", "count",    dut.count, 8'd16);
      expect_eq("idle", "full",     full,      8'd1);
      expect_eq("idle", "rd_data",  rd_data,   8'h10);        // holds D0
      expect_eq("idle", "rd_valid", rd_valid,  8'd0);         // pulse is over
      expect_eq("idle", "overflow", overflow,  8'd0);
    end

    $display("\n--- Step 4: drain, expect D1..D15 then AA ---");
    for (i = 1; i <= 16; i = i + 1) begin
      @(negedge clk);
      wr_en = 0; rd_en = 1;
      @(posedge clk); #1;
      show("drain");
      if (i < 16) expect_eq("drain", "rd_data", rd_data, 8'h10 + i);
      else        expect_eq("drain", "rd_data (last = AA)", rd_data, 8'hAA);
      expect_eq("drain", "rd_valid", rd_valid,  8'd1);
      expect_eq("drain", "count",    dut.count, 8'd16 - i);
    end

    @(negedge clk);
    wr_en = 0; rd_en = 0;
    @(posedge clk); #1;
    show("after drain");
    expect_eq("after drain", "empty",    empty,     8'd1);
    expect_eq("after drain", "count",    dut.count, 8'd0);
    expect_eq("after drain", "underflow", underflow, 8'd0);

    $display("\n=================================================");
    if (errors == 0) $display("T5 PASSED");
    else             $display("T5 FAILED: %0d error(s)", errors);
    $display("=================================================");
    $finish;
  end

endmodule
