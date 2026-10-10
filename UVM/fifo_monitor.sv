// MONITOR: watches the pins and reports what happened, once per clock cycle.
// It never drives anything. Same job as the "@(posedge clk); #1; show(...)" in the directed tests.
class fifo_monitor extends uvm_monitor;
  `uvm_component_utils(fifo_monitor)

  virtual fifo_if vif;
  uvm_analysis_port #(fifo_item) ap;        // broadcasts every observed cycle to scoreboard / coverage

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db #(virtual fifo_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "monitor: virtual interface 'vif' not found in config_db")
  endfunction

  task run_phase(uvm_phase phase);
    fifo_item it;
    forever begin
      @(posedge vif.clk);
      #1;                                   // look 1 ns after the rising edge (outputs have updated)
      it = fifo_item::type_id::create("mon_item");
      it.kind       = CYCLE_OP;
      it.rst_n_seen = vif.rst_n;            // inputs: what the DUT saw at this edge
      it.wr_en      = vif.wr_en;
      it.rd_en      = vif.rd_en;
      it.wr_data    = vif.wr_data;
      it.rd_data    = vif.rd_data;          // outputs: what the DUT produced after this edge
      it.rd_valid   = vif.rd_valid;
      it.full       = vif.full;
      it.empty      = vif.empty;
      it.overflow   = vif.overflow;
      it.underflow  = vif.underflow;
      ap.write(it);
    end
  endtask
endclass
