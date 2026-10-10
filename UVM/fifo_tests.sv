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
