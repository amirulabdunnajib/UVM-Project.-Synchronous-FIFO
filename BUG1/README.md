# BUG1 — Write dropped on FULL + simultaneous write/read

**RTL transition:** v1 → v2  
**Rules:** R2, R5, R8, R9

When the FIFO is full and both `wr_en` and `rd_en` are asserted, the original DUT used:

```systemverilog
wire write_accepted = wr_en && !full;
```

The read was accepted but the write was rejected, so occupancy fell from 16 to 15 and the new item was silently lost. The fix is:

```systemverilog
wire write_accepted = wr_en && (!full || rd_en);
```

## Evidence

The directed T5 test fills the FIFO with 16 distinct values, performs `wr_en=1`, `rd_en=1`, `wr_data=AA`, and then drains the FIFO. The first failure occurs immediately: `count=15` and `full=0` instead of 16/1. The stored `AA` is also missing from the drain.

Files in `Directed_Test/` preserve the original draft, final directed test, simulation log, debugging notes and formal bug report.

## UVM follow-up

`fifo_full_wr_rd_seq` recreates the same case without embedding expected values in the sequence; the queue-based scoreboard predicts the result from the spec. The relevant coverage target is **level=full × operation=write+read**.

The preserved UVM run after the BUG1 RTL fix still reports reset-related errors from BUG2. That is useful evidence: the R5 behaviour is fixed while verification continues to expose the next independent defect.
