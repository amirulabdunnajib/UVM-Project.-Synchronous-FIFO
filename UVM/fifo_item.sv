// This file is included by fifo_pkg.sv, after
// `include "uvm_macros.svh" and `import uvm_pkg::*;

typedef enum bit {CYCLE_OP = 1'b0, RESET_OP = 1'b1} fifo_kind_e;

// One transaction = ONE CLOCK CYCLE of inputs (or one reset event).
// The same class is used for stimulus (sequence -> driver)
// and for observation (monitor -> scoreboard).
class fifo_item extends uvm_sequence_item;
  `uvm_object_utils(fifo_item)

  // ---------- Stimulus: filled in by sequences ----------
  rand fifo_kind_e  kind;           // CYCLE_OP = normal cycle, RESET_OP = reset event
  rand bit          wr_en;
  rand bit          rd_en;
  rand bit [7:0]    wr_data;
  rand int unsigned reset_cycles;   // RESET_OP only: how many clocks to hold reset
  rand bit          async_assert;   // RESET_OP only: assert reset between clock edges

  // ---------- Observation: filled in by the monitor ----------
  bit               rst_n_seen;
  logic [7:0]       rd_data;       // logic (not bit), so an X from the DUT is not hidden
  logic             rd_valid;
  logic             full;
  logic             empty;
  logic             overflow;
  logic             underflow;

  // A normal cycle has no reset fields; a reset event holds reset 1 to 4 clocks.
  constraint c_cycle { kind == CYCLE_OP -> (reset_cycles == 0 && async_assert == 0); }
  constraint c_reset { kind == RESET_OP -> (reset_cycles inside {[1:4]}); }

  function new(string name = "fifo_item");
    super.new(name);
  endfunction

  // One-line text used in log messages
  function string convert2string();
    return $sformatf("kind=%s wr=%0b rd=%0b wdata=%02h rst_cyc=%0d async=%0b | rst_n=%0b rd_data=%02h rd_valid=%0b full=%0b empty=%0b ovf=%0b unf=%0b",
                     kind.name(), wr_en, rd_en, wr_data, reset_cycles, async_assert,
                     rst_n_seen, rd_data, rd_valid, full, empty, overflow, underflow);
  endfunction
endclass
