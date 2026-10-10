`timescale 1ns/1ns

// The interface bundles all DUT pins into one object.
// The driver and monitor receive a "virtual interface" handle to it.
interface fifo_if (input logic clk);

  // Inputs to the DUT
  logic       rst_n   = 1'b0;   // starts in reset; the driver controls it directly
  logic       wr_en   = 1'b0;
  logic       rd_en   = 1'b0;
  logic [7:0] wr_data = 8'h00;

  // Outputs from the DUT
  logic [7:0] rd_data;
  logic       rd_valid;
  logic       full;
  logic       empty;
  logic       overflow;
  logic       underflow;

  // The driver changes wr_en / rd_en / wr_data on the falling clock edge,
  // exactly like our directed testbenches (@(negedge clk)).
  clocking drv_cb @(negedge clk);
    output wr_en, rd_en, wr_data;
  endclocking

  // rst_n is NOT in the clocking block on purpose: test T3 needs reset to be
  // asserted between clock edges (asynchronous reset), so the driver drives
  // it directly with its own timing.

  // ---------------------------------------------------------------------
  // Assertion for the asynchronous reset (the "T3 check").
  // 1 ns after rst_n falls, WITHOUT waiting for a clock edge, every output
  // must already be at its reset value (spec R11). The scoreboard cannot see
  // this, because it only looks at the outputs once per clock cycle.
  // ---------------------------------------------------------------------
  always @(negedge rst_n) begin
    #1;
    a_async_reset: assert (rd_data === 8'h00 && rd_valid === 1'b0 &&
                           full === 1'b0 && empty === 1'b1 &&
                           overflow === 1'b0 && underflow === 1'b0)
      else $error("[ASYNC_RESET] outputs not at reset values 1 ns after rst_n fell: rd_data=%h rd_valid=%b full=%b empty=%b ovf=%b unf=%b",
                  rd_data, rd_valid, full, empty, overflow, underflow);
  end

endinterface
