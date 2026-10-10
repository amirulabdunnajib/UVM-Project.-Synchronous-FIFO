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
