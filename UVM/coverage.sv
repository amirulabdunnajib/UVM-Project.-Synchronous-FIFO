class fifo_coverage extends uvm_subscriber #(fifo_item);
  `uvm_component_utils(fifo_coverage)

  fifo_item tr;
  bit prev_full  = 0;
  bit prev_empty = 1;                    // the FIFO starts empty
  bit prev_rst_n = 0;                    // the system starts in reset

  // Hit counters for the log (the same 12 cells as x_level_op)
  int unsigned grid   [3][4];            // [level: 0 empty, 1 mid, 2 full][op: 0 idle, 1 read, 2 write, 3 wr+rd]
  int unsigned rst_at [3];               // reset started while the FIFO was empty / mid / full
  int unsigned ovf_pulses = 0;
  int unsigned unf_pulses = 0;

  covergroup cg;
    option.comment = "Coverage for FIFO";

    cp_level: coverpoint {prev_full, prev_empty} iff (tr.rst_n_seen) {
      bins empty = {2'b01};
      bins mid   = {2'b00};
      bins full  = {2'b10};
      illegal_bins both = {2'b11};
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
    int lv;
    tr = t;
    cg.sample();

    // Level BEFORE this cycle (saved from the previous cycle)
    if (prev_full)       lv = 2;
    else if (prev_empty) lv = 0;
    else                 lv = 1;

    if (t.rst_n_seen)
      grid[lv][{t.wr_en, t.rd_en}]++;    // normal cycle: count the cell
    else if (prev_rst_n)
      rst_at[lv]++;                      // first cycle of a reset

    if (t.overflow  === 1'b1) ovf_pulses++;
    if (t.underflow === 1'b1) unf_pulses++;

    prev_full  = t.full;
    prev_empty = t.empty;
    prev_rst_n = t.rst_n_seen;
  endfunction

  function void report_phase(uvm_phase phase);
    string lvn [3];
    string opn [4];
    string holes;
    string tail;
    int    total_hit;

    lvn[0] = "empty"; lvn[1] = "mid  "; lvn[2] = "full ";
    opn[0] = "idle";  opn[1] = "read";  opn[2] = "write"; opn[3] = "wr+rd";
    total_hit = 0;

    `uvm_info("COV", "---- level x operation grid (hit counts) ----", UVM_NONE)
    `uvm_info("COV", "level |  idle  read write wr+rd", UVM_NONE)
    for (int l = 0; l < 3; l++) begin
      holes = "";
      for (int o = 0; o < 4; o++) begin
        if (grid[l][o] == 0) holes = {holes, " ", opn[o]};
        else                 total_hit++;
      end
      tail = (holes == "") ? "" : {"  HOLES:", holes};
      `uvm_info("COV", $sformatf("%s | %5d %5d %5d %5d%s", lvn[l], grid[l][0], grid[l][1], grid[l][2], grid[l][3], tail), UVM_NONE)
    end
    `uvm_info("COV", $sformatf("grid cells hit: %0d / 12", total_hit), UVM_NONE)
    `uvm_info("COV", $sformatf("reset started at: empty=%0d mid=%0d full=%0d", rst_at[0], rst_at[1], rst_at[2]), UVM_NONE)
    `uvm_info("COV", $sformatf("overflow pulses=%0d underflow pulses=%0d", ovf_pulses, unf_pulses), UVM_NONE)
    `uvm_info("COV", $sformatf("Functional coverage = %0.1f%%", cg.get_coverage()), UVM_NONE)
  endfunction
endclass
