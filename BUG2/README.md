# BUG2 — Error flags undefined during reset

## Failure

During reset, `overflow` and `underflow` remain `X` because the reset branch does not assign them. The UVM reset test and asynchronous-reset assertion detect this immediately.

## Specification

**R11** requires `overflow = 0` and `underflow = 0` during reset.

## Root cause

The original reset branch resets pointers, count, `rd_data`, and `rd_valid`, but omits the two registered error flags.

## Fix

Add:

```systemverilog
overflow  <= 1'b0;
underflow <= 1'b0;
```

to the asynchronous reset branch.

## Verification story

The original directed reset test is preserved because it is an important verification lesson: it checked pointers/count/data but did **not** check the two error flags, so the defect escaped that directed test. The UVM scoreboard/assertion did check them and produced eight mismatches in the preserved pre-fix run.

`UVM/before_fix.log` shows the failure; `UVM/after_fix.log` shows the reset regression after the correction.
