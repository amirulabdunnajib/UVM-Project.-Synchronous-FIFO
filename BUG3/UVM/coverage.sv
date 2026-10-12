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