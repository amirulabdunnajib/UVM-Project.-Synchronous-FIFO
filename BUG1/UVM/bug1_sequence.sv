// Targeted UVM sequence for BUG1.
// Requires fifo_base_seq with send_reset() and send_cycle().
class bug1_full_both_seq extends fifo_base_seq;
  `uvm_object_utils(bug1_full_both_seq)

  function new(string name = "bug1_full_both_seq");
    super.new(name);
  endfunction

  task body();
    send_reset(2);
    for (int i = 0; i < 16; i++)
      send_cycle(1, 0, 8'(8'h10 + i));

    // Critical BUG1 stimulus: FULL + simultaneous write/read.
    send_cycle(1, 1, 8'hAA);

    // Drain so the scoreboard also proves AA was stored.
    repeat (16) send_cycle(0, 1, 8'h55);
    send_cycle(0, 0, 8'h55);
  endtask
endclass
