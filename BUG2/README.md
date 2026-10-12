# BUG2 — Error flags are undefined during reset

**RTL transition:** v2 → v3  
**Rule:** R11

In v2, reset initializes the pointers, occupancy, `rd_data` and `rd_valid`, but leaves `overflow` and `underflow` unassigned. They therefore appear as `X` during reset.

The v3 fix adds:

```systemverilog
overflow  <= 1'b0;
underflow <= 1'b0;
```

inside the reset branch.

## Why the original directed reset test missed it

The preserved T1–T4 directed reset test checks pointers, count, full/empty and `rd_data`, but it does **not** check `overflow` or `underflow`. Its saved log therefore passes even while BUG2 is present. This is a useful verification-plan lesson: a passing test is only evidence for the outputs it actually checks.

## UVM detection

The UVM scoreboard compares both flags and the interface contains an asynchronous-reset assertion. The pre-fix run records **8 UVM mismatches** plus assertion failures because both flags are `X`. After v3, the reset regression records **0 UVM errors**.
