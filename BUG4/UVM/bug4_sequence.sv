// Targeted UVM sequence for BUG4.
class bug4_empty_both_seq extends fifo_base_seq;
  `uvm_object_utils(bug4_empty_both_seq)

  function new(string name = "bug4_empty_both_seq");
    super.new(name);
  endfunction

  task body();
    send_reset(2);

    // Critical missing cell: EMPTY x write_read.
    // The write is accepted, the read is rejected, and underflow must pulse.
    send_cycle(1, 1, 8'h5A);

    // Prove there was no bypass and that 5A was stored.
    send_cycle(0, 1, 8'h00);
    send_cycle(0, 0, 8'h00);
  endtask
endclass
