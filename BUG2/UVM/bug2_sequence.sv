// Targeted UVM reset stimulus for BUG2.
class bug2_reset_flags_seq extends fifo_base_seq;
  `uvm_object_utils(bug2_reset_flags_seq)

  function new(string name = "bug2_reset_flags_seq");
    super.new(name);
  endfunction

  task body();
    // Reset while both requests are high. Reset must dominate and both
    // registered error flags must be 0.
    send_reset(4, 1, 1, 8'hAA);

    // Also exercise asynchronous reset after normal activity.
    repeat (5) send_cycle(1, 0, 8'h55);
    send_reset(3, 1, 0, 8'hAA, 1);
  endtask
endclass
