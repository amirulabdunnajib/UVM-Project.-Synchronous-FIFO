# BUG3 — `rd_data` changes on a rejected read at EMPTY

**RTL transition:** v3 → v4  
**Rule:** R10

The v3 DUT updates read data whenever a read is requested:

```systemverilog
if (rd_en) rd_data <= mem[rptr];
```

At EMPTY, the read is rejected, so R10 requires `rd_data` to hold its previous value. Instead, v3 can load stale/invalid memory. The v4 fix gates the update with the accepted operation:

```systemverilog
if (read_accepted) rd_data <= mem[rptr];
```

## Directed verification evolution

The uploaded project contains both an early T7 draft and the corrected T7. The final T7:

1. writes and reads `5A`, establishing a known non-zero held value;
2. performs two back-to-back reads while EMPTY;
3. checks `rd_data` remains `5A`, `rd_valid=0`, `underflow=1`, `count=0`, and `rptr` does not move;
4. writes/reads `A5` afterward to prove normal operation still works.

The saved T7 run passes on the corrected RTL.

## UVM follow-up

`fifo_read_empty_seq` reproduces the read-empty behaviour. The scoreboard's `exp_rd_data` only changes on `rd_acc`, so it naturally detects a DUT that modifies data on a rejected read.
