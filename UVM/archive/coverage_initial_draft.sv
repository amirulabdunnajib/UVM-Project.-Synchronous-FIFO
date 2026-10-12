class fifo_coverage extends uvm_subscriber #(fifo_item);
  `uvm_component_utils(fifo_coverage)
  fifo_item tr;
  bit prev_full  = 0;
  bit prev_empty = 1;
  covergroup cg;
    option.comment = "Coverage for FIFO";
    cp_level: coverpoint {prev_full, prev_empty} iff (tr.rst_n_seen) {
      bins empty={2'b01}; bins mid={2'b00}; bins full={2'b10}; illegal_bins both={2'b11};
    }
    cp_op: coverpoint {tr.wr_en, tr.rd_en} iff (tr.rst_n_seen) {
      bins idle={2'b00}; bins read_only={2'b01}; bins write_only={2'b10}; bins write_read={2'b11};
    }
    cp_flow: coverpoint {tr.overflow,tr.underflow} { bins overflow={2'b10}; bins underflow={2'b01}; }
    x_level_op: cross cp_level, cp_op;
  endgroup
  function new(string name, uvm_component parent); super.new(name,parent); cg=new(); endfunction
  function void write(fifo_item t); tr=t; cg.sample(); prev_full=t.full; prev_empty=t.empty; endfunction
endclass
