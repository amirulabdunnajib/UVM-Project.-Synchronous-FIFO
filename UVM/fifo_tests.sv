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

class fifo_reset_test extends fifo_base_test;
  `uvm_component_utils(fifo_reset_test)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_phase(uvm_phase phase);
    fifo_reset_seq seq;
    phase.raise_objection(this);
    seq = fifo_reset_seq::type_id::create("seq");
    seq.start(env.agt.sqr);
    #30ns;
    phase.drop_objection(this);
  endtask
endclass

class fifo_full_rw_test extends fifo_base_test;
  `uvm_component_utils(fifo_full_rw_test)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_phase(uvm_phase phase);
    fifo_full_wr_rd_seq seq;
    phase.raise_objection(this);
    seq = fifo_full_wr_rd_seq::type_id::create("seq");
    seq.start(env.agt.sqr);
    #30ns;
    phase.drop_objection(this);
  endtask
endclass

class fifo_corner_test extends fifo_base_test;
  `uvm_component_utils(fifo_corner_test)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_phase(uvm_phase phase);
    fifo_corner_seq seq;
    phase.raise_objection(this);
    seq = fifo_corner_seq::type_id::create("seq");
    seq.start(env.agt.sqr);
    #30ns;
    phase.drop_objection(this);
  endtask
endclass

class fifo_all_test extends fifo_base_test;
  `uvm_component_utils(fifo_all_test)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_phase(uvm_phase phase);
    fifo_reset_seq      rst_seq;
    fifo_full_wr_rd_seq full_seq;
    fifo_read_empty_seq empty_seq;
    fifo_corner_seq     corner_seq;
    phase.raise_objection(this);
    rst_seq    = fifo_reset_seq     ::type_id::create("rst_seq");
    full_seq   = fifo_full_wr_rd_seq::type_id::create("full_seq");
    empty_seq  = fifo_read_empty_seq::type_id::create("empty_seq");
    corner_seq = fifo_corner_seq    ::type_id::create("corner_seq");
    rst_seq.start(env.agt.sqr);
    full_seq.start(env.agt.sqr);
    empty_seq.start(env.agt.sqr);
    corner_seq.start(env.agt.sqr);
    #30ns;
    phase.drop_objection(this);
  endtask
endclass
