# BUG4 — Underflow suppressed for EMPTY + simultaneous write/read

**RTL transition:** v4 → v5  
**Rules:** R6, R13

At EMPTY, a simultaneous write and read accepts the write but rejects the read because the decision uses the pre-edge empty state. Therefore `underflow` must assert.

The v4 expression incorrectly depended on `!wr_en`:

```systemverilog
underflow <= rd_en && empty && !wr_en;
```

That suppresses underflow when both requests are high. The final v5 fix is:

```systemverilog
underflow <= rd_en && empty;
```

## Coverage-driven discovery

The expanded corner sequence deliberately targets the 12 **level × operation** cells. The critical BUG4 stimulus is **EMPTY × write+read**. The preserved pre-fix regression reports a single scoreboard mismatch for `underflow` at that cell.

After the v5 correction, the final regression records:

- 12 / 12 grid cells hit
- reset from empty, mid and full
- overflow and underflow pulses observed
- 100.0% functional coverage
- 140 cycles checked, 0 mismatches
- 0 UVM errors

The final corrected RTL is `RTL/after_fix.sv` and also `../RTL_HISTORY/fifo_dut_v5.sv`.
