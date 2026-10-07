# FIFO v2.0 — Changes and Lessons Learned

I updated my synchronous FIFO from v1.0 after reviewing the RTL against the specification. The design has 16 locations, each storing 8 bits. This version records my progress; it still needs fixes before it meets all the requirements.

## Changes from v1.0

| Area | Change in v2.0 | Reason |
| --- | --- | --- |
| Internal state | Changed `wptr`, `rptr`, and `count` from `wire` to `reg`. | These signals are assigned inside clocked `always` blocks. |
| Occupancy width | Increased `count` to 5 bits. | A 16-entry FIFO must represent every occupancy from 0 to 16. |
| Data width | Changed `wr_data` and `rd_data` to `[7:0]`. | The ports must match the specified 8-bit memory width. |
| Status flags | Derived `full` and `empty` only from `count`, using continuous assignments. | R9 requires `full` at 16 items and `empty` at 0, without additional procedural drivers. |
| Reset | Added `negedge rst_n` to the clocked blocks and a reset assignment for `rd_data`. | The specification requires an active-low asynchronous reset. |
| Read-valid reset | Added a reset assignment for `rd_valid`. | This is only a partial fix: its declaration and normal-operation logic still need correction. |
| Readability | Corrected the memory-size comments and renamed the memory to `mem_fifo`. | The code should clearly describe the intended hardware. |
| Port syntax | Added the missing comma after `output empty`. | The port declarations must be separated correctly. |

These changes were checked against the uploaded v1.0 and v2.0 source files. In the uploaded v1.0, `rd_valid` was undriven; v2.0 adds both a reset assignment and a continuous memory comparison. This remains unfinished and is covered under B.4 below.

## Main lesson: one register, one clocked owner

The most important lesson for me is that **each register in this synthesizable FIFO should be assigned by one clocked `always` block**. Changing a signal from `wire` to `reg` does not solve multiple procedural drivers.

In my current v2.0, the write block increments `count`, while the read block decrements it. Both blocks run on the same rising edge. Their assignments do not combine into an increment followed by a decrement, so this cannot reliably implement simultaneous read and write.

R8 requires one decision for the next occupancy:

| Accepted write | Accepted read | Required `count` update |
| --- | --- | --- |
| 0 | 0 | Hold |
| 1 | 0 | Increment |
| 0 | 1 | Decrement |
| 1 | 1 | Hold |

I will give `count` one clocked owner and implement this table using `case ({wr_accept, rd_accept})`. Separate clocked blocks are fine for different registers; the problem is assigning the same register from multiple blocks.

## Remaining work

- **Acceptance signals:** Define `wr_accept = wr_en && (!full || rd_en)` and `rd_accept = rd_en && !empty` once, then reuse them consistently.
- **B.1 — Occupancy:** Remove the multiple drivers on `count` and implement the update table above to satisfy R5, R7, and R8.
- **B.4 — Read validity:** Declare `rd_valid` as a registered output, remove its continuous assignment, and update it with `rd_valid <= rd_accept` on each non-reset clock edge. Its current comparison against memory does not indicate an accepted read, and its procedural reset conflicts with its current net declaration and continuous driver.
- **C.4 — Error reporting:** Implement mandatory registered outputs for R13: `overflow <= wr_en && !wr_accept` and `underflow <= rd_en && !rd_accept`, clearing both during reset. Consecutive rejected requests may keep the corresponding output high across consecutive cycles.

## What this taught me about specifications

Writing RTL means translating each requirement into precise state updates and observable outputs. For example, simultaneous requests behave differently when the FIFO is empty and when it is full. The acceptance conditions must capture those differences, and the occupancy logic must use the accepted operations rather than the requests alone.

This review helped me connect register widths, reset behavior, signal ownership, and corner cases to specific requirements. v2.0 is an intermediate revision, not a claim of successful compilation or completed verification.
