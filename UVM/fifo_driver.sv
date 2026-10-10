// DRIVER: turns a transaction (fifo_item) into pin wiggles on the interface.
// It decides HOW and WHEN. The sequence decides WHAT.
class fifo_driver extends uvm_driver #(fifo_item);
  `uvm_component_utils(fifo_driver)

  virtual fifo_if vif;                      // handle to the interface (set in top via config_db)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual fifo_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "driver: virtual interface 'vif' not found in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    // Power-on reset: rst_n starts at 0 (interface default). Hold it for
    // 2 rising edges, then release it on a falling edge.
    vif.rst_n = 1'b0;
    repeat (2) @(posedge vif.clk);
    @(negedge vif.clk);
    vif.rst_n = 1'b1;

    // Main loop: take the next item from the sequencer, drive it, report done
    forever begin
      seq_item_port.get_next_item(req);
      if (req.kind == RESET_OP) drive_reset(req);
      else                      drive_cycle(req);
      seq_item_port.item_done();
    end
  endtask

  // One clock cycle: set the inputs on the next falling edge.
  // The DUT samples them on the rising edge that follows.
  task drive_cycle(fifo_item item);
    @(vif.drv_cb);                          // wait for the next falling edge
    vif.drv_cb.wr_en   <= item.wr_en;
    vif.drv_cb.rd_en   <= item.rd_en;
    vif.drv_cb.wr_data <= item.wr_data;
  endtask

  // One reset event: assert rst_n, hold it for reset_cycles rising edges,
  // then release it on a falling edge.
  task drive_reset(fifo_item item);
    @(vif.drv_cb);                          // falling edge
    vif.drv_cb.wr_en   <= item.wr_en;       // inputs held during reset (tests T1, T2)
    vif.drv_cb.rd_en   <= item.rd_en;
    vif.drv_cb.wr_data <= item.wr_data;
    if (item.async_assert) #3;              // 3 ns after the falling edge = between clock edges (test T3)
    vif.rst_n = 1'b0;
    repeat (item.reset_cycles) @(vif.drv_cb);
    vif.rst_n = 1'b1;                       // release on a falling edge
    vif.drv_cb.wr_en   <= 1'b0;
    vif.drv_cb.rd_en   <= 1'b0;
    vif.drv_cb.wr_data <= 8'h00;
  endtask
endclass
