# BUG1 — Write dropped during simultaneous write/read at FULL

## Failure

With the FIFO full and both `wr_en` and `rd_en` asserted, the read succeeds but the write is rejected. `count` falls from 16 to 15 and the new item is lost.

## Specification

- **R2:** write acceptance is `wr_en && (!full || rd_en)`.
- **R5:** at FULL with both requests, both operations are accepted and `count` remains 16.
- **R8/R9:** occupancy and `full` must remain consistent with the accepted operations.

## Root cause

Faulty RTL:

```systemverilog
wire write_accepted = wr_en && !full;
```

Fixed RTL:

```systemverilog
wire write_accepted = wr_en && (!full || rd_en);
```

## Directed verification

`Directed_Test/tb_bug1_full_write_read.sv` fills the FIFO with 16 distinct values, performs a simultaneous write/read while full, and then drains the FIFO. The preserved failure log is `Directed_Test/before_fix.log`.

## UVM verification

`UVM/bug1_sequence.sv` reproduces the same boundary condition without embedding expected values in the sequence. The scoreboard is responsible for predicting queue contents and occupancy. Existing functional coverage contains the `FULL x write_read` cross cell.

A passing post-fix UVM run is preserved as `UVM/after_fix.log`.

## Fix result

The accepted write now replaces the item removed in the same cycle. Both pointers advance and `count` remains 16.
