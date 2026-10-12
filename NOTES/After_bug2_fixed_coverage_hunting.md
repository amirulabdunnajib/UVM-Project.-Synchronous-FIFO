**The reset test ran, and it passed.** Evidence in the log: `Running test fifo_reset_test...`, the four `[RESET_SEQ]` lines T1 to T4, `TEST PASSED: 26 cycles checked, 0 mismatches`, and no `[ASYNC_RESET]` errors.

The other file (`T_WrRdFull`) is the T5 run again: 43 cycles, 0 mismatches, 51.7% coverage. Both tests now pass on your fixed DUT.

## Reset test trace

|Cycles|What the log shows|Check|
|---|---|---|
|1 to 2|`rst_n=0`, `wr=0`|power-on reset, outputs at reset values|
|3 to 6|`rst_n=0`, `wr=1`, `wdata=aa`|**T1:** reset held 4 clocks with `wr_en` active. Model size stays 0 and `empty=1`.|
|7|`rst_n=1`, idle|hidden idle cycle after reset release|
|8 to 11|`rst_n=0`, `wr=1`, `rd=1`|**T2:** same with `rd_en` too. No `underflow` and no `rd_valid`.|
|13 to 17|five writes, `10` to `14`|**T3:** model size climbs to 5|
|18 to 20|`rst_n=0`, `wr=1`, size drops to 0, `empty=1`|**T3:** reset cleared the FIFO|
|22 to 23|write `5a`, read: `rd_data=5a`, `rd_valid=1`|**T4:** FIFO works after reset|
|24 to 26|`rd_data` holds `5a`, `rd_valid=0`|R10 hold behavior|

## One point to understand

The scoreboard can't tell a synchronous reset from an asynchronous one. It samples 1 ns after the rising edge, and by then either kind of reset has finished. The only check that proves async is the `a_async_reset` assertion, which looks 1 ns after `rst_n` falls. It printed nothing, so the DUT cleared at once. This assertion did fire in your first run, so it's active, and its silence now means a pass.

## What these two tests don't prove

Coverage is 48.3% and 51.7%, from two separate runs, so the two numbers aren't added together. More important, the log shows what was **never exercised**:

- read when empty (`underflow`)
- write when full with no read (`overflow`)
- write + read together at empty (R6) and at mid-level (R7)
- reset while the FIFO is full
- many mixed operations, and pointer wrap-around

A pass on the tests you ran says nothing about these. Which rule would you test next, and what wrong implementation would it target? That's your next plan row, and it becomes your next sequence.
