// This file is included by fifo_pkg.sv, after fifo_item.sv.
//
// A sequence says WHAT to do, cycle by cycle. It contains NO expected values:
// the checking (D0 comes out, count stays 16, AA comes out last) belongs to the
// scoreboard. That is the main difference from the directed testbenches.

// ---------------------------------------------------------------------------
// Base sequence: two helper tasks that every test sequence reuses
// ---------------------------------------------------------------------------
class fifo_base_seq extends uvm_sequence #(fifo_item);
  `uvm_object_utils(fifo_base_seq)

  function new(string name = "fifo_base_seq");
    super.new(name);
  endfunction

  // Send ONE clock cycle of inputs
  task send_cycle(bit wr, bit rd, bit [7:0] data);
    fifo_item it;
    it = fifo_item::type_id::create("it");
    start_item(it);                                   // ask the sequencer for the driver
    if (!it.randomize() with { kind == CYCLE_OP;
                               wr_en == wr;
                               rd_en == rd;
                               wr_data == data; })
      `uvm_fatal("RAND", "randomize failed in send_cycle()")
    finish_item(it);                                  // hand the item to the driver and wait
  endtask

  // Send ONE reset event: hold reset for n clocks, with chosen values on the inputs
  task send_reset(int unsigned n, bit wr = 0, bit rd = 0, bit [7:0] data = 8'h00, bit is_async = 0);
    fifo_item it;
    it = fifo_item::type_id::create("rst_it");
    start_item(it);
    if (!it.randomize() with { kind == RESET_OP;
                               reset_cycles == n;
                               wr_en == wr;
                               rd_en == rd;
                               wr_data == data;
                               async_assert == is_async; })
      `uvm_fatal("RAND", "randomize failed in send_reset()")
    finish_item(it);
  endtask
endclass


// ---------------------------------------------------------------------------
// Reset sequence = directed tests T1, T2, T3, T4
// ---------------------------------------------------------------------------
class fifo_reset_seq extends fifo_base_seq;
  `uvm_object_utils(fifo_reset_seq)

  function new(string name = "fifo_reset_seq");
    super.new(name);
  endfunction

  task body();
    `uvm_info("RESET_SEQ", "T1: reset held 4 clocks while wr_en = 1", UVM_LOW)
    send_reset(4, 1, 0, 8'hAA);

    `uvm_info("RESET_SEQ", "T2: reset held 4 clocks while wr_en = 1 and rd_en = 1", UVM_LOW)
    send_reset(4, 1, 1, 8'hAA);

    `uvm_info("RESET_SEQ", "T3: write 5 items, then assert reset between clock edges", UVM_LOW)
    for (int i = 0; i < 5; i++)
      send_cycle(1, 0, 8'(8'h10 + i));
    send_reset(3, 1, 0, 8'hAA, 1);                      // async = 1

    `uvm_info("RESET_SEQ", "T4: after reset, write one item and read it back", UVM_LOW)
    send_cycle(1, 0, 8'h5A);
    send_cycle(0, 1, 8'h00);
    send_cycle(0, 0, 8'h00);                               // one idle cycle to see the result
  endtask
endclass


// ---------------------------------------------------------------------------
// Full write+read sequence = directed test T5
// ---------------------------------------------------------------------------
class fifo_full_wr_rd_seq extends fifo_base_seq;
  `uvm_object_utils(fifo_full_wr_rd_seq)

  function new(string name = "fifo_full_wr_rd_seq");
    super.new(name);
  endfunction

  task body();
    send_reset(2);                                      // known starting state

    `uvm_info("T5_SEQ", "Step 1: fill with 16 distinct values (10..1F)", UVM_LOW)
    for (int i = 0; i < 16; i++)
      send_cycle(1, 0, 8'(8'h10 + i));

    `uvm_info("T5_SEQ", "Step 2: FULL, write AA and read in the same cycle", UVM_LOW)
    send_cycle(1, 1, 8'hAA);

    `uvm_info("T5_SEQ", "Step 3: two idle cycles (junk on wr_data)", UVM_LOW)
    repeat (2) send_cycle(0, 0, 8'h55);

    `uvm_info("T5_SEQ", "Step 4: drain 16 reads", UVM_LOW)
    repeat (16) send_cycle(0, 1, 8'h55);

    send_cycle(0, 0, 8'h55);                               // final idle to see the end state
  endtask
endclass
