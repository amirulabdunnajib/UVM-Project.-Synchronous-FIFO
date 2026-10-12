# UVM Development Archive

The uploaded `FIFO_UVM.zip` contained a nested `archive/files.zip` plus standalone snapshots from before functional coverage was complete. I inspected the nested ZIP: it contains earlier copies of `testbench.sv`, `design.sv`, driver, monitor, scoreboard, agent, env, tests, package, top and interface.

Rather than duplicating the nested ZIP binary, this folder preserves the meaningful source evolution:

- `coverage_initial_draft.sv` — first covergroup draft.
- `coverage_with_reset_reporting.sv` — improved reset-state coverage and coverage report.
- `testbench_before_latest_coverage.sv` — the earlier monolithic UVM snapshot already present in the GitHub history.

The canonical current environment is one directory up.
