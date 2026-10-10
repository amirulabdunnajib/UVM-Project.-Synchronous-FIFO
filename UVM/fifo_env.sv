// ENV: holds the agent and the checkers, and wires them together.
class fifo_env extends uvm_env;
  `uvm_component_utils(fifo_env)

  fifo_agent      agt;
  fifo_scoreboard sb;
  // TODO (yours): fifo_coverage cov;   // coverage subscriber, written in the coverage step

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agt = fifo_agent     ::type_id::create("agt", this);
    sb  = fifo_scoreboard::type_id::create("sb",  this);
    // TODO (yours): cov = fifo_coverage::type_id::create("cov", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agt.mon.ap.connect(sb.item_export);               // monitor -> scoreboard
    // TODO (yours): agt.mon.ap.connect(cov.analysis_export);   // monitor -> coverage
  endfunction
endclass
