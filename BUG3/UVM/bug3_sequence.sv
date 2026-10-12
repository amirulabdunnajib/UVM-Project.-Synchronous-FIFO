// Targeted UVM sequence for BUG3: prove rd_data holds on a rejected read.
class bug3_rd_data_hold_seq extends fifo_base_seq;
  `uvm_object_utils(bug3_rd_data_hold_seq)

  function new(string name = "bug3_rd_data_hold_seq");
    super.new(name);
  endfunction

  task body();
    send_reset(2);
    for (int i = 0; i < 16; i++)
      send_cycle(1, 0, 8'(8'h10 + i));

    repeat (16) send_cycle(0, 1, 8'h00);

    // One extra read at EMPTY: rejected. Scoreboard must expect rd_data to hold.
    send_cycle(0, 1, 8'h00);
    send_cycle(0, 0, 8'h00);
  endtask
endclass
