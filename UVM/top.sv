`timescale 1ns/1ns

// TOP: clock, interface, DUT, and the call that starts UVM.
module top;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import fifo_pkg::*;

  logic clk = 1'b0;
  always #5 clk = ~clk;                      // 10 ns period, rising edges at 5, 15, 25, ...

  fifo_if fif (.clk(clk));

  fifo dut (
    .clk      (clk),
    .rst_n    (fif.rst_n),
    .wr_en    (fif.wr_en),
    .rd_en    (fif.rd_en),
    .wr_data  (fif.wr_data),
    .rd_data  (fif.rd_data),
    .rd_valid (fif.rd_valid),
    .full     (fif.full),
    .empty    (fif.empty),
    .overflow (fif.overflow),
    .underflow(fif.underflow)
  );

  initial begin
    uvm_config_db #(virtual fifo_if)::set(null, "*", "vif", fif);   // give the interface to driver and monitor
    run_test("fifo_full_rw_test");           // default test; +UVM_TESTNAME=... overrides it
  end

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, top);
  end
endmodule
