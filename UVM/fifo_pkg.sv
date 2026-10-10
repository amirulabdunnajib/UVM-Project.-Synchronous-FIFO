`timescale 1ns/1ns
`include "uvm_macros.svh"

package fifo_pkg;
  import uvm_pkg::*;

  `include "fifo_item.sv"
  `include "fifo_seqs.sv"
  `include "fifo_driver.sv"
  `include "fifo_monitor.sv"
  `include "fifo_scoreboard.sv"
  `include "fifo_agent.sv"
  `include "fifo_env.sv"
  `include "fifo_tests.sv"
endpackage
