# BUG4 — Underflow suppressed for write+read at EMPTY

## Failure

When the FIFO is empty and `wr_en=1` and `rd_en=1`, the write is accepted but the read is rejected. The faulty RTL suppresses `underflow` because it additionally requires `!wr_en`.

## Specification

- **R6:** at EMPTY with both requests, write is accepted and read is rejected; no bypass occurs.
- **R13:** `underflow` asserts after any rejected read request.

Therefore EMPTY + write/read must produce `underflow = 1`.

## Root cause

Faulty:

```systemverilog
underflow <= rd_en && empty && !wr_en;
```

Correct, directly from the acceptance rule:

```systemverilog
underflow <= rd_en && !read_accepted;
```

## UVM evidence

The expanded corner sequence hit the previously missing `EMPTY x write_read` cell. The preserved pre-fix regression contains exactly one UVM mismatch: underflow was 0 but expected 1. The final preserved regression contains zero UVM errors.

This is a useful example of coverage-driven verification: filling a coverage hole exposed a real RTL bug.
