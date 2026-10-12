# UVM Environment

This directory is the canonical verification environment assembled from the latest files in the uploaded `FIFO_UVM.zip` plus the final corrected DUT.

## Main components

- `fifo_item.sv` — transaction carrying stimulus and observed DUT outputs.
- `fifo_seqs.sv` — reset, full+read/write, read-empty and coverage-closing corner sequences.
- `fifo_driver.sv` — drives normal cycles and asynchronous reset events.
- `fifo_monitor.sv` — samples one cycle after each rising clock edge.
- `fifo_scoreboard.sv` — queue-based reference model derived from the specification.
- `coverage.sv` — level × operation coverage, reset-state coverage and flow-control pulse coverage.
- `fifo_agent.sv` / `fifo_env.sv` — UVM hierarchy and analysis connections.
- `fifo_tests.sv` — focused tests plus `fifo_all_test` regression.
- `fifo_if.sv` — DUT interface and asynchronous-reset assertion.
- `top.sv` — clock, DUT instance, interface and UVM startup.
- `design.sv` — final v5 DUT.
- `testbench.sv` — preserved one-file EDA Playground version of the environment.

## Integration fixes

The modular files in the ZIP represented an in-progress split of the working one-file testbench. Two mechanical fixes were required to make the modular layout internally consistent:

1. `fifo_env.sv` now explicitly declares and stores the `fifo_coverage cov` handle.
2. `fifo_pkg.sv` now includes `coverage.sv` before `fifo_env.sv`.

No verification behaviour was changed by those two edits.

## Regression evidence

`Results/final_regression_100pct.log` is the preserved final run: 140 cycles, 0 mismatches, all 12 level×operation cells hit and 100% functional coverage.
