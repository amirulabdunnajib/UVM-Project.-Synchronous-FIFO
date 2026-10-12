// EDA Playground testbench.sv: interface + UVM package + top, all in one file.
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

`timescale 1ns/1ns
`include "uvm_macros.svh"

package fifo_pkg;
  import uvm_pkg::*;

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

  // This file is included by fifo_pkg.sv, after fifo_item.sv.
//
// A sequence says WHAT to do, cycle by cycle. It contains NO expected values:
// the checking (D0 comes out, count stays 16, AA comes out last) belongs to the
// scoreboard. That is the main difference from the directed testbenches.

// ---------------------------------------------------------------------------
// Base sequence: two helper tasks that every test sequence reuses
// ---------------------------------------------------------------------------
class fifo_base_seq extends uvm_sequence #(fifo_item);
  `uvm_object_utils(fifo_base_seq)

  function new(string name = "fifo_base_seq");
    super.new(name);
  endfunction

  // Send ONE clock cycle of inputs
  task send_cycle(bit wr, bit rd, bit [7:0] data);
    fifo_item it;
    it = fifo_item::type_id::create("it");
    start_item(it);                                   // ask the sequencer for the driver
    if (!it.randomize() with { kind == CYCLE_OP;
                               wr_en == wr;
                               rd_en == rd;
                               wr_data == data; })
      `uvm_fatal("RAND", "randomize failed in send_cycle()")
    finish_item(it);                                  // hand the item to the driver and wait
  endtask

  // Send ONE reset event: hold reset for n clocks, with chosen values on the inputs
  task send_reset(int unsigned n, bit wr = 0, bit rd = 0, bit [7:0] data = 8'h00, bit is_async = 0);
    fifo_item it;
    it = fifo_item::type_id::create("rst_it");
    start_item(it);
    if (!it.randomize() with { kind == RESET_OP;
                               reset_cycles == n;
                               wr_en == wr;
                               rd_en == rd;
                               wr_data == data;
                               async_assert == is_async; })
      `uvm_fatal("RAND", "randomize failed in send_reset()")
    finish_item(it);
  endtask
endclass


// ---------------------------------------------------------------------------
// Reset sequence = directed tests T1, T2, T3, T4
// ---------------------------------------------------------------------------
class fifo_reset_seq extends fifo_base_seq;
  `uvm_object_utils(fifo_reset_seq)

  function new(string name = "fifo_reset_seq");
    super.new(name);
  endfunction

  task body();
    `uvm_info("RESET_SEQ", "T1: reset held 4 clocks while wr_en = 1", UVM_LOW)
    send_reset(4, 1, 0, 8'hAA);

    `uvm_info("RESET_SEQ", "T2: reset held 4 clocks while wr_en = 1 and rd_en = 1", UVM_LOW)
    send_reset(4, 1, 1, 8'hAA);

    `uvm_info("RESET_SEQ", "T3: write 5 items, then assert reset between clock edges", UVM_LOW)
    for (int i = 0; i < 5; i++)
      send_cycle(1, 0, 8'(8'h10 + i));
    send_reset(3, 1, 0, 8'hAA, 1);                      // async = 1

    `uvm_info("RESET_SEQ", "T4: after reset, write one item and read it back", UVM_LOW)
    send_cycle(1, 0, 8'h5A);
    send_cycle(0, 1, 8'h00);
    send_cycle(0, 0, 8'h00);                               // one idle cycle to see the result
  endtask
endclass


// ---------------------------------------------------------------------------
// Full write+read sequence = directed test T5
// ---------------------------------------------------------------------------
class fifo_full_wr_rd_seq extends fifo_base_seq;
  `uvm_object_utils(fifo_full_wr_rd_seq)

  function new(string name = "fifo_full_wr_rd_seq");
    super.new(name);
  endfunction

  task body();
    send_reset(2);                                      // known starting state

    `uvm_info("T5_SEQ", "Step 1: fill with 16 distinct values (10..1F)", UVM_LOW)
    for (int i = 0; i < 16; i++)
      send_cycle(1, 0, 8'(8'h10 + i));

    `uvm_info("T5_SEQ", "Step 2: FULL, write AA and read in the same cycle", UVM_LOW)
    send_cycle(1, 1, 8'hAA);

    `uvm_info("T5_SEQ", "Step 3: two idle cycles (junk on wr_data)", UVM_LOW)
    repeat (2) send_cycle(0, 0, 8'h55);

    `uvm_info("T5_SEQ", "Step 4: drain 16 reads", UVM_LOW)
    repeat (16) send_cycle(0, 1, 8'h55);

    send_cycle(0, 0, 8'h55);                               // final idle to see the end state
  endtask
endclass

  // DRIVER: turns a transaction (fifo_item) into pin wiggles on the interface.
// It decides HOW and WHEN. The sequence decides WHAT.
class fifo_driver extends uvm_driver #(fifo_item);
  `uvm_component_utils(fifo_driver)

  virtual fifo_if vif;                      // handle to the interface (set in top via config_db)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual fifo_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "driver: virtual interface 'vif' not found in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    // Power-on reset: rst_n starts at 0 (interface default). Hold it for
    // 2 rising edges, then release it on a falling edge.
    vif.rst_n = 1'b0;
    repeat (2) @(posedge vif.clk);
    @(negedge vif.clk);
    vif.rst_n = 1'b1;

    // Main loop: take the next item from the sequencer, drive it, report done
    forever begin
      seq_item_port.get_next_item(req);
      if (req.kind == RESET_OP) drive_reset(req);
      else                      drive_cycle(req);
      seq_item_port.item_done();
    end
  endtask

  // One clock cycle: set the inputs on the next falling edge.
  // The DUT samples them on the rising edge that follows.
  task drive_cycle(fifo_item item);
    @(vif.drv_cb);                          // wait for the next falling edge
    vif.drv_cb.wr_en   <= item.wr_en;
    vif.drv_cb.rd_en   <= item.rd_en;
    vif.drv_cb.wr_data <= item.wr_data;
  endtask

  // One reset event: assert rst_n, hold it for reset_cycles rising edges,
  // then release it on a falling edge.
  task drive_reset(fifo_item item);
    @(vif.drv_cb);                          // falling edge
    vif.drv_cb.wr_en   <= item.wr_en;       // inputs held during reset (tests T1, T2)
    vif.drv_cb.rd_en   <= item.rd_en;
    vif.drv_cb.wr_data <= item.wr_data;
    if (item.async_assert) #3;              // 3 ns after the falling edge = between clock edges (test T3)
    vif.rst_n = 1'b0;
    repeat (item.reset_cycles) @(vif.drv_cb);
    vif.rst_n = 1'b1;                       // release on a falling edge
    vif.drv_cb.wr_en   <= 1'b0;
    vif.drv_cb.rd_en   <= 1'b0;
    vif.drv_cb.wr_data <= 8'h00;
  endtask
endclass

  // MONITOR: watches the pins and reports what happened, once per clock cycle.
// It never drives anything. Same job as the "@(posedge clk); #1; show(...)" in the directed tests.
class fifo_monitor extends uvm_monitor;
  `uvm_component_utils(fifo_monitor)

  virtual fifo_if vif;
  uvm_analysis_port #(fifo_item) ap;        // broadcasts every observed cycle to scoreboard / coverage

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db #(virtual fifo_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "monitor: virtual interface 'vif' not found in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    fifo_item it;
    forever begin
      @(posedge vif.clk);
      #1;                                   // look 1 ns after the rising edge (outputs have updated)
      it = fifo_item::type_id::create("mon_item");
      it.kind       = CYCLE_OP;
      it.rst_n_seen = vif.rst_n;            // inputs: what the DUT saw at this edge
      it.wr_en      = vif.wr_en;
      it.rd_en      = vif.rd_en;
      it.wr_data    = vif.wr_data;
      it.rd_data    = vif.rd_data;          // outputs: what the DUT produced after this edge
      it.rd_valid   = vif.rd_valid;
      it.full       = vif.full;
      it.empty      = vif.empty;
      it.overflow   = vif.overflow;
      it.underflow  = vif.underflow;
      ap.write(it);
    end
  endtask
endclass

  // SCOREBOARD: decides whether the DUT behaved correctly.
// It keeps a software model of the FIFO (a queue) and, for every observed clock
// cycle, predicts what the outputs should be from the SPEC (R1 to R13) alone.
// All the "expected" values from the directed tests now live here, in one place.
class fifo_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(fifo_scoreboard)

  uvm_analysis_imp #(fifo_item, fifo_scoreboard) item_export;   // receives items from the monitor

  localparam int DEPTH = 16;

  // ---- reference model state ----
  bit [7:0] model_q [$];                    // the items currently "inside" the FIFO
  bit [7:0] exp_rd_data;                    // rd_data holds its value between reads (R10)
  bit       exp_rd_valid;
  bit       exp_ovf;
  bit       exp_unf;

  int cycles = 0;
  int errors = 0;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    item_export = new("item_export", this);
  endfunction

  // Called by the monitor once per clock cycle
  function void write(fifo_item t);
    bit full_before, empty_before, wr_acc, rd_acc;
    cycles++;

    if (!t.rst_n_seen) begin
      // R11: reset clears everything
      model_q.delete();
      exp_rd_data  = 8'h00;
      exp_rd_valid = 1'b0;
      exp_ovf      = 1'b0;
      exp_unf      = 1'b0;
    end
    else begin
      // The decision uses the state BEFORE this clock edge
      full_before  = (model_q.size() == DEPTH);
      empty_before = (model_q.size() == 0);
      wr_acc = t.wr_en && (!full_before || t.rd_en);   // R2
      rd_acc = t.rd_en && !empty_before;                // R3

      exp_rd_valid = rd_acc;                            // R12
      exp_ovf      = t.wr_en && full_before && !t.rd_en;   // R13
      exp_unf      = t.rd_en && empty_before;               // R13

      // Pop BEFORE push: at "full + write + read" the oldest item leaves first (R5)
      if (rd_acc) exp_rd_data = model_q.pop_front();
      if (wr_acc) model_q.push_back(t.wr_data);
    end

    // One log line per cycle: what went in, what came out, what the model expects
    `uvm_info("SB", $sformatf("cyc %3d | in: rst_n=%0b wr=%0b rd=%0b wdata=%02h | out: rd_data=%02h rd_valid=%0b full=%0b empty=%0b ovf=%0b unf=%0b | model size=%0d",
              cycles, t.rst_n_seen, t.wr_en, t.rd_en, t.wr_data,
              t.rd_data, t.rd_valid, t.full, t.empty, t.overflow, t.underflow,
              model_q.size()), UVM_MEDIUM)

    // Compare every output with the prediction (R9: full/empty come from the fill level)
    chk("rd_data",   t.rd_data,   exp_rd_data);
    chk("rd_valid",  t.rd_valid,  exp_rd_valid);
    chk("full",      t.full,      (model_q.size() == DEPTH));
    chk("empty",     t.empty,     (model_q.size() == 0));
    chk("overflow",  t.overflow,  exp_ovf);
    chk("underflow", t.underflow, exp_unf);
  endfunction

  function void chk(string what, logic [7:0] actual, logic [7:0] expected);
    if (actual !== expected) begin
      errors++;
      `uvm_error("MISMATCH", $sformatf("cyc %0d: %s = %02h, expected %02h (model size=%0d)",
                 cycles, what, actual, expected, model_q.size()))
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    if (errors == 0)
      `uvm_info("SB", $sformatf("*** TEST PASSED: %0d cycles checked, 0 mismatches ***", cycles), UVM_NONE)
    else
      `uvm_info("SB", $sformatf("*** TEST FAILED: %0d mismatches in %0d cycles ***", errors, cycles), UVM_NONE)
  endfunction
endclass

  // AGENT: bundles sequencer + driver + monitor for one interface.
class fifo_agent extends uvm_agent;
  `uvm_component_utils(fifo_agent)

  uvm_sequencer #(fifo_item) sqr;
  fifo_driver                drv;
  fifo_monitor               mon;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sqr = uvm_sequencer #(fifo_item)::type_id::create("sqr", this);
    drv = fifo_driver ::type_id::create("drv", this);
    mon = fifo_monitor::type_id::create("mon", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(sqr.seq_item_export);   // driver pulls items from the sequencer
  endfunction
endclass


class fifo_coverage extends uvm_subscriber #(fifo_item);
  `uvm_component_utils(fifo_coverage)

  fifo_item tr;
  bit prev_full   = 0;
  bit prev_empty  = 1;                   // the FIFO starts empty
  bit prev_rst_n  = 0;                   // the system starts in reset

  covergroup cg;
    option.comment = "Coverage for FIFO";

    cp_level: coverpoint {prev_full, prev_empty} iff (tr.rst_n_seen) {
      bins empty = {2'b01};
      bins mid   = {2'b00};
      bins full  = {2'b10};
      illegal_bins both = {2'b11};       // full and empty together can never happen
    }

    cp_op: coverpoint {tr.wr_en, tr.rd_en} iff (tr.rst_n_seen) {
      bins idle       = {2'b00};
      bins read_only  = {2'b01};
      bins write_only = {2'b10};
      bins write_read = {2'b11};
    }

    cp_flow: coverpoint {tr.overflow, tr.underflow} {
      bins ovf_pulse = {2'b10};
      bins unf_pulse = {2'b01};
      illegal_bins both = {2'b11};
    }

    // Level at the first cycle of a reset (reset asserted at empty / mid / full)
    cp_reset_at: coverpoint {prev_full, prev_empty} iff (!tr.rst_n_seen && prev_rst_n) {
      bins at_empty = {2'b01};
      bins at_mid   = {2'b00};
      bins at_full  = {2'b10};
    }

    x_level_op: cross cp_level, cp_op;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg = new();
  endfunction

  function void write(fifo_item t);
    tr = t;
    cg.sample();
    prev_full  = t.full;
    prev_empty = t.empty;
    prev_rst_n = t.rst_n_seen;
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("COV", $sformatf("Functional coverage = %0.1f%%", cg.get_coverage()), UVM_NONE)
  endfunction
endclass


  // ENV: holds the agent and the checkers, and wires them together.
class fifo_env extends uvm_env;
  `uvm_component_utils(fifo_env)

  fifo_agent      agt;
  fifo_scoreboard sb;
  fifo_coverage   cov;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agt = fifo_agent     ::type_id::create("agt", this);
    sb  = fifo_scoreboard::type_id::create("sb",  this);
    cov = fifo_coverage::type_id::create("cov", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agt.mon.ap.connect(sb.item_export);               // monitor -> scoreboard
    agt.mon.ap.connect(cov.analysis_export);   // monitor -> coverage
  endfunction
endclass


  // TESTS: a test builds the env and decides which sequence to run.
// Pick one at run time with +UVM_TESTNAME=<name>.

class fifo_base_test extends uvm_test;
  `uvm_component_utils(fifo_base_test)

  fifo_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = fifo_env::type_id::create("env", this);
  endfunction
endclass


// Directed tests T1 to T4
class fifo_reset_test extends fifo_base_test;
  `uvm_component_utils(fifo_reset_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    fifo_reset_seq seq;
    phase.raise_objection(this);              // "do not end the simulation yet"
    seq = fifo_reset_seq::type_id::create("seq");
    seq.start(env.agt.sqr);                   // run the sequence on the agent's sequencer
    #30ns;                                    // let the monitor and scoreboard see the last cycles
    phase.drop_objection(this);
  endtask
endclass


// Directed test T5
class fifo_full_rw_test extends fifo_base_test;
  `uvm_component_utils(fifo_full_rw_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    fifo_full_wr_rd_seq seq;
    phase.raise_objection(this);
    seq = fifo_full_wr_rd_seq::type_id::create("seq");
    seq.start(env.agt.sqr);
    #30ns;
    phase.drop_objection(this);
  endtask
endclass

endpackage

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
